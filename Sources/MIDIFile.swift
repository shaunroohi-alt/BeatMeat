import Foundation

/// Standard MIDI File note interchange. Tempo maps and controller events are not
/// imported: note positions remain in quarter-note beats at the project's tempo.
enum MIDIFile {
    enum Failure: LocalizedError {
        case invalid(String)
        case truncated
        case smpte
        case unsupportedFormat
        case tooLarge
        var errorDescription: String? {
            switch self {
            case .invalid(let reason): return "The MIDI file is invalid: \(reason)."
            case .truncated: return "The MIDI file ends before its declared data is complete."
            case .smpte: return "SMPTE-timed MIDI files are not supported. Export a beat-based MIDI file instead."
            case .unsupportedFormat: return "Only Standard MIDI File format 0 and 1 are supported."
            case .tooLarge: return "The MIDI file exceeds this development build's import limit."
            }
        }
    }

    private struct Cursor {
        let bytes: [UInt8]
        var position: Int
        let end: Int
        var remaining: Int { end - position }
        mutating func byte() throws -> UInt8 {
            guard position < end else { throw Failure.truncated }
            defer { position += 1 }
            return bytes[position]
        }
        mutating func number(_ count: Int) throws -> UInt32 {
            var result: UInt32 = 0
            for _ in 0..<count { result = (result << 8) | UInt32(try byte()) }
            return result
        }
        mutating func skip(_ count: Int) throws {
            guard count >= 0, count <= remaining else { throw Failure.truncated }
            position += count
        }
        mutating func tag() throws -> String {
            guard remaining >= 4 else { throw Failure.truncated }
            let result = String(bytes: bytes[position..<(position + 4)], encoding: .ascii) ?? ""
            position += 4
            return result
        }
        mutating func variable() throws -> UInt32 {
            var result: UInt32 = 0
            for _ in 0..<4 {
                let value = try byte()
                result = (result << 7) | UInt32(value & 0x7f)
                if value & 0x80 == 0 { return result }
            }
            throw Failure.invalid("a variable-length value exceeds four bytes")
        }
        mutating func midiData() throws -> UInt8 {
            let result = try byte()
            guard result < 0x80 else { throw Failure.invalid("a channel data byte contains a status bit") }
            return result
        }
    }
    private struct Pending {
        let tick: UInt64
        let velocity: UInt8
    }
    private struct PendingQueue {
        var notes: [Pending] = []
        var head = 0
        mutating func pop() -> Pending? {
            guard head < notes.count else { return nil }
            let value = notes[head]
            head += 1
            return value
        }
    }

    static func read(_ data: Data) throws -> [BeatNote] {
        guard data.count <= 32 * 1024 * 1024 else { throw Failure.tooLarge }
        let bytes = [UInt8](data)
        var file = Cursor(bytes: bytes, position: 0, end: bytes.count)
        guard try file.tag() == "MThd" else { throw Failure.invalid("missing MThd header") }
        let headerLength = Int(try file.number(4))
        guard headerLength >= 6 else { throw Failure.invalid("the header is shorter than six bytes") }
        guard headerLength <= file.remaining else { throw Failure.truncated }
        let format = try file.number(2)
        let trackCount = Int(try file.number(2))
        let division = try file.number(2)
        guard format <= 1 else { throw Failure.unsupportedFormat }
        guard trackCount > 0, trackCount <= 1024, format != 0 || trackCount == 1 else {
            throw Failure.invalid("the track count does not match the file format")
        }
        guard division & 0x8000 == 0 else { throw Failure.smpte }
        guard division > 0 else { throw Failure.invalid("the beat resolution is zero") }
        try file.skip(headerLength - 6)
        var notes: [BeatNote] = []
        var parsedTracks = 0
        var eventCount = 0
        while file.remaining > 0 {
            let chunkType = try file.tag()
            let chunkLength = Int(try file.number(4))
            guard chunkLength <= file.remaining else { throw Failure.truncated }
            let end = file.position + chunkLength
            if chunkType == "MTrk" {
                guard parsedTracks < trackCount else { throw Failure.invalid("there are more tracks than the header declares") }
                var track = Cursor(bytes: bytes, position: file.position, end: end)
                try readTrack(&track, division: Double(division), into: &notes, eventCount: &eventCount)
                parsedTracks += 1
            }
            file.position = end // Unknown, length-delimited chunks are safely ignored.
        }
        guard parsedTracks == trackCount else { throw Failure.invalid("a declared track chunk is missing") }
        return notes.sorted {
            if $0.startBeat != $1.startBeat { return $0.startBeat < $1.startBeat }
            if $0.pitch != $1.pitch { return $0.pitch < $1.pitch }
            return $0.duration < $1.duration
        }
    }

    private static func readTrack(_ cursor: inout Cursor, division: Double,
                                  into notes: inout [BeatNote], eventCount: inout Int) throws {
        var tick: UInt64 = 0
        var running: UInt8?
        var pending: [Int: PendingQueue] = [:]
        var noteOnCount = 0
        var ended = false
        func append(_ onset: Pending, pitch: Int, end: UInt64, to result: inout [BeatNote]) throws {
            guard end > onset.tick else { return }
            guard result.count < 250_000 else { throw Failure.tooLarge }
            result.append(BeatNote(pitch: pitch, velocity: Double(onset.velocity) / 127,
                                   startBeat: Double(onset.tick) / division,
                                   duration: Double(end - onset.tick) / division))
        }
        while cursor.remaining > 0 {
            eventCount += 1
            guard eventCount <= 2_000_000 else { throw Failure.tooLarge }
            let delta = UInt64(try cursor.variable())
            let (nextTick, overflow) = tick.addingReportingOverflow(delta)
            guard !overflow, nextTick <= 9_007_199_254_740_991 else { throw Failure.invalid("the event timeline is too long") }
            tick = nextTick
            let first = try cursor.byte()
            let status: UInt8
            var firstData: UInt8?
            if first < 0x80 {
                guard let previous = running else { throw Failure.invalid("running status has no preceding channel status") }
                status = previous
                firstData = first
            } else { status = first }
            if status == 0xff {
                // SMF meta events do not replace the preceding channel status.
                let kind = try cursor.byte()
                let length = Int(try cursor.variable())
                guard length <= cursor.remaining else { throw Failure.truncated }
                if kind == 0x2f {
                    guard length == 0 else { throw Failure.invalid("End of Track must have zero payload bytes") }
                    ended = true
                    // Ignore harmless padding after End of Track, but not hidden events.
                    while cursor.remaining > 0 {
                        guard try cursor.byte() == 0 else { throw Failure.invalid("events appear after End of Track") }
                    }
                    break
                }
                try cursor.skip(length)
                continue
            }
            if status == 0xf0 || status == 0xf7 {
                running = nil
                let length = Int(try cursor.variable())
                try cursor.skip(length)
                continue
            }
            guard (0x80...0xef).contains(status) else { throw Failure.invalid("an unsupported system event occurs inside a track") }
            running = status
            let kind = status & 0xf0
            let key: UInt8
            if let initial = firstData { key = initial } else { key = try cursor.midiData() }
            let value: UInt8
            if kind == 0xc0 || kind == 0xd0 { value = 0 } else { value = try cursor.midiData() }
            guard kind == 0x90 || kind == 0x80 else { continue }
            let identity = Int(status & 0x0f) * 128 + Int(key)
            if kind == 0x90 && value > 0 {
                noteOnCount += 1
                guard noteOnCount <= 250_000 else { throw Failure.tooLarge }
                pending[identity, default: PendingQueue()].notes.append(Pending(tick: tick, velocity: value))
            } else if let onset = pending[identity]?.pop() {
                try append(onset, pitch: Int(key), end: tick, to: &notes)
            }
        }
        guard ended else { throw Failure.invalid("a track has no End of Track marker") }
        // EOT implicitly releases notes still held by a permissive source sequencer.
        for (identity, queue) in pending {
            for onset in queue.notes.dropFirst(queue.head) {
                try append(onset, pitch: identity % 128, end: tick, to: &notes)
            }
        }
    }

    /// Writes format 0, one channel, 480 PPQ, with a tempo event. Invalid notes
    /// and silent notes are omitted; integer MIDI cannot represent velocity zero
    /// as a sounding Note On. Event times round to the nearest 1/480 beat.
    static func write(_ notes: [BeatNote], bpm: Double) -> Data {
        struct Event {
            let tick: UInt32
            let status: UInt8
            let pitch: UInt8
            let velocity: UInt8
            let order: Int
        }
        let ppq: Double = 480
        let maxTick: Double = 268_435_455
        var events: [Event] = []
        for (index, note) in notes.prefix(250_000).enumerated() {
            guard (0...127).contains(note.pitch), note.velocity.isFinite, note.velocity > 0,
                  note.startBeat.isFinite, note.startBeat >= 0,
                  note.duration.isFinite, note.duration > 0 else { continue }
            let start = (note.startBeat * ppq).rounded()
            let end = max(start + 1, ((note.startBeat + note.duration) * ppq).rounded())
            guard start.isFinite, end.isFinite, start <= maxTick, end <= maxTick else { continue }
            let velocity = UInt8(max(1, min(127, (note.velocity * 127).rounded())))
            events.append(Event(tick: UInt32(start), status: 0x90, pitch: UInt8(note.pitch), velocity: velocity, order: index))
            events.append(Event(tick: UInt32(end), status: 0x80, pitch: UInt8(note.pitch), velocity: 0, order: index))
        }
        events.sort {
            if $0.tick != $1.tick { return $0.tick < $1.tick }
            if $0.status != $1.status { return $0.status < $1.status } // Off before retrigger.
            if $0.pitch != $1.pitch { return $0.pitch < $1.pitch }
            return $0.order < $1.order
        }
        let tempo = UInt32(max(1, min(16_777_215, (60_000_000 / (bpm.isFinite && bpm > 0 ? bpm : 120)).rounded())))
        var track: [UInt8] = [0, 0xff, 0x51, 3, UInt8((tempo >> 16) & 0xff), UInt8((tempo >> 8) & 0xff), UInt8(tempo & 0xff)]
        var previous: UInt32 = 0
        for event in events {
            track += variable(event.tick - previous)
            track += [event.status, event.pitch, event.velocity]
            previous = event.tick
        }
        track += [0, 0xff, 0x2f, 0]
        var result: [UInt8] = Array("MThd".utf8) + [0, 0, 0, 6, 0, 0, 0, 1, 1, 0xe0]
        result += Array("MTrk".utf8)
        let size = UInt32(track.count)
        result += [UInt8((size >> 24) & 0xff), UInt8((size >> 16) & 0xff), UInt8((size >> 8) & 0xff), UInt8(size & 0xff)]
        result += track
        return Data(result)
    }

    private static func variable(_ value: UInt32) -> [UInt8] {
        var remaining = value
        var result: [UInt8] = [UInt8(remaining & 0x7f)]
        remaining >>= 7
        while remaining > 0 {
            result.insert(UInt8(remaining & 0x7f) | 0x80, at: 0)
            remaining >>= 7
        }
        return result
    }
}
