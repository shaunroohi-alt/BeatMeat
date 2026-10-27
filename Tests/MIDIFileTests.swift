import Foundation
import XCTest
#if canImport(BeatMeatCore)
@testable import BeatMeatCore
#elseif canImport(BeatMeat)
@testable import BeatMeat
#endif

final class MIDIFileTests: XCTestCase {
    private func file(_ tracks: [[UInt8]], format: UInt16 = 0, ppq: UInt16 = 480) -> Data {
        var bytes: [UInt8] = Array("MThd".utf8) + [0,0,0,6,UInt8(format >> 8),UInt8(format & 255),UInt8(tracks.count >> 8),UInt8(tracks.count & 255),UInt8(ppq >> 8),UInt8(ppq & 255)]
        for track in tracks {
            bytes += Array("MTrk".utf8)
            let count = UInt32(track.count)
            bytes += [UInt8((count >> 24) & 255),UInt8((count >> 16) & 255),UInt8((count >> 8) & 255),UInt8(count & 255)]
            bytes += track
        }
        return Data(bytes)
    }
    func testRoundTripPreservesMusicalPositionAndQuantizedVelocity() throws {
        let source = [BeatNote(pitch: 60, velocity: 0.7, startBeat: 0, duration: 1),
                      BeatNote(pitch: 127, velocity: 1, startBeat: 3.25, duration: 0.125)]
        let notes = try MIDIFile.read(MIDIFile.write(source, bpm: 123))
        XCTAssertEqual(notes.count, 2)
        for (a,b) in zip(source,notes) {
            XCTAssertEqual(a.pitch,b.pitch)
            XCTAssertEqual(a.startBeat,b.startBeat,accuracy: 1.0/480)
            XCTAssertEqual(a.duration,b.duration,accuracy: 1.0/480)
            XCTAssertEqual(a.velocity,b.velocity,accuracy: 1.0/127)
        }
    }
    func testRunningStatusAndZeroVelocityNoteOff() throws {
        let bytes: [UInt8] = [0,0x90,60,100, 0x83,0x60,60,0, 0,0xff,0x2f,0]
        let notes = try MIDIFile.read(file([bytes]))
        XCTAssertEqual(notes.count,1)
        XCTAssertEqual(notes[0].duration,1,accuracy: 0.000001)
    }
    func testFormatOneMergesTracksWithoutApplyingTempoMap() throws {
        let tempo: [UInt8] = [0,0xff,0x51,3,0x0f,0x42,0x40, 0,0xff,0x2f,0]
        let a: [UInt8] = [0,0x90,64,64, 0x81,0x70,0x80,64,0, 0,0xff,0x2f,0]
        let b: [UInt8] = [0x81,0x70,0x91,60,127, 0x81,0x70,0x81,60,0, 0,0xff,0x2f,0]
        let notes = try MIDIFile.read(file([tempo,a,b],format: 1))
        XCTAssertEqual(notes.map(\.pitch),[64,60])
        XCTAssertEqual(notes[1].startBeat,0.5,accuracy: 0.000001)
        XCTAssertEqual(notes[1].duration,0.5,accuracy: 0.000001)
    }
    func testSamePitchChannelsAndOverlapsAreIndependentFIFO() throws {
        let track: [UInt8] = [0,0x90,60,20, 120,0x90,60,40, 0,0x91,60,100,
                             120,0x80,60,0, 120,0x81,60,0, 120,0x80,60,0,
                             0,0xff,0x2f,0]
        let notes = try MIDIFile.read(file([track]))
        XCTAssertEqual(notes.count,3)
        XCTAssertEqual(notes[0].duration,0.5,accuracy: 0.000001)
        XCTAssertEqual(notes[1].duration,0.5,accuracy: 0.000001)
        XCTAssertEqual(notes[2].duration,0.75,accuracy: 0.000001)
    }
    func testTruncatedChunksAndUnboundedVariableValuesFail() {
        XCTAssertThrowsError(try MIDIFile.read(Data([0x4d,0x54])))
        var truncated = [UInt8](file([[0,0xff,0x2f,0]]));truncated.removeLast()
        XCTAssertThrowsError(try MIDIFile.read(Data(truncated)))
        XCTAssertThrowsError(try MIDIFile.read(file([[0x81,0x81,0x81,0x81,0,0xff,0x2f,0]])))
        XCTAssertThrowsError(try MIDIFile.read(file([[0,60,127,0,0xff,0x2f,0]])))
    }
    func testSMPTEAndTypeTwoAreRejectedExplicitly() {
        XCTAssertThrowsError(try MIDIFile.read(file([[0,0xff,0x2f,0]],ppq: 0xe728))) { error in
            XCTAssertTrue(error.localizedDescription.contains("SMPTE"))
        }
        XCTAssertThrowsError(try MIDIFile.read(file([[0,0xff,0x2f,0]],format: 2)))
    }
    func testMetaPayloadLengthAndEndOfTrackAreValidated() {
        XCTAssertThrowsError(try MIDIFile.read(file([[0,0xff,1,100,65]])))
        XCTAssertThrowsError(try MIDIFile.read(file([[0,0x90,60,100]])))
        XCTAssertThrowsError(try MIDIFile.read(file([[0,0xff,0x2f,1,0]])))
        XCTAssertThrowsError(try MIDIFile.read(file([[0,0x90,0x80,100,0,0xff,0x2f,0]])))
    }
    func testWriterHandlesSilentInvalidAndSubTickNotes() throws {
        let notes = [BeatNote(pitch: 60, velocity: 0, startBeat: 0, duration: 1),
                     BeatNote(pitch: 60, velocity: 1, startBeat: .nan, duration: 1),
                     BeatNote(pitch: 60, velocity: 1, startBeat: 0, duration: 0.00001)]
        let decoded = try MIDIFile.read(MIDIFile.write(notes,bpm: .nan))
        XCTAssertEqual(decoded.count,1)
        XCTAssertEqual(decoded[0].duration,1.0/480,accuracy: 0.000001)
    }
    func testAdjacentRetriggerRemainsTwoDistinctNotes() throws {
        let notes = [BeatNote(pitch: 60, startBeat: 0, duration: 1),BeatNote(pitch: 60, startBeat: 1, duration: 1)]
        let decoded = try MIDIFile.read(MIDIFile.write(notes,bpm: 120))
        XCTAssertEqual(decoded.count,2)
        XCTAssertEqual(decoded[0].duration,1,accuracy: 0.000001)
        XCTAssertEqual(decoded[1].startBeat,1,accuracy: 0.000001)
    }
}
