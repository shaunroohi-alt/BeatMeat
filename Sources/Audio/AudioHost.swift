import AVFoundation
import Foundation

private final class KernelBox { var pointer: OpaquePointer; init(_ p: OpaquePointer) { pointer = p } }
final class AudioHost {
    private let engine = AVAudioEngine()
    private let box: KernelBox
    private var source: AVAudioSourceNode!
    private var recordingURL: URL?
    let sampleRate: Double = 44100
    var kernel: OpaquePointer { box.pointer }
    var running: Bool { engine.isRunning }
    init() throws {
        guard let pointer = BMCreate(44100) else { throw ProjectError.allocation }
        box = KernelBox(pointer)
        let renderBox = box
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        source = AVAudioSourceNode(format: format) { _,_,frames,list -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(list)
            guard buffers.count == 2, let l = buffers[0].mData?.assumingMemoryBound(to: Float.self),
                  let r = buffers[1].mData?.assumingMemoryBound(to: Float.self) else { return -50 }
            BMRender(renderBox.pointer,l,r,frames); return noErr
        }
        engine.attach(source); engine.connect(source, to: engine.mainMixerNode, format: format)
    }
    deinit { engine.stop(); BMDestroy(box.pointer) }
    func start() throws { engine.prepare(); try engine.start() }
    func stop() { engine.stop() }
    func setMaster(_ value: Double) { engine.mainMixerNode.outputVolume = Float(value) }
    func replace(_ project: BeatProject, base: URL?) throws {
        let fresh = try Self.makeKernel(project, base: base)
        let resume = engine.isRunning; engine.stop()
        let old = box.pointer; box.pointer = fresh; BMDestroy(old)
        if resume { try start() }
    }
    static func decode(_ url: URL) throws -> AVAudioPCMBuffer {
        let file = try AVAudioFile(forReading: url, commonFormat: .pcmFormatFloat32, interleaved: false)
        guard file.length > 1, file.length <= 16_777_216, file.processingFormat.channelCount <= 2 else { throw ProjectError.audioLimit }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else { throw ProjectError.allocation }
        try file.read(into: buffer); return buffer
    }
    static func makeKernel(_ project: BeatProject, base: URL?) throws -> OpaquePointer {
        try project.validate()
        guard let kernel = BMCreate(44100) else { throw ProjectError.allocation }
        do {
            for (t,track) in project.tracks.enumerated() {
                for clip in track.clips {
                    if let path = clip.audioPath {
                        let decoded = try decode(ProjectIO.mediaURL(path, base: base))
                        guard let channels = decoded.floatChannelData else { throw ProjectError.invalid }
                        let right = decoded.format.channelCount > 1 ? channels[1] : channels[0]
                        guard BMLoadAudio(kernel,Int32(t),Int32(clip.slot),channels[0],right,Int64(decoded.frameLength),decoded.format.sampleRate,clip.startBeat,clip.lengthBeats,clip.loop ? 1 : 0) == 1 else { throw ProjectError.audioLimit }
                    } else if track.kind == .midi {
                        BMSetMIDIClip(kernel,Int32(t),Int32(clip.slot),clip.startBeat,clip.lengthBeats,clip.loop ? 1 : 0)
                        for (i,note) in clip.notes.enumerated() { BMSetNote(kernel,Int32(t),Int32(clip.slot),Int32(i),Int32(note.pitch),note.velocity,note.startBeat,note.duration) }
                    }
                }
                setTrack(kernel,track: track,index: t)
            }
            BMTransport(kernel,project.bpm,0,0,project.loopEnabled ? 1 : 0,project.loopStart,project.loopEnd,4)
            return kernel
        } catch { BMDestroy(kernel); throw error }
    }
    static func setTrack(_ k: OpaquePointer, track: BeatTrack, index: Int) {
        let values: [(BMTrackParameter,Double)] = [(BMGain,track.gain),(BMPan,track.pan),(BMMute,track.mute ? 1 : 0),(BMSolo,track.solo ? 1 : 0),(BMDelaySend,track.send),(BMLowpass,track.cutoff)]
        for (parameter,value) in values {
            BMSetTrack(k,Int32(index),Int32(parameter.rawValue),value)
        }
    }
    func beginRecording() throws -> URL {
        guard recordingURL == nil else { throw ProjectError.invalid }
        let input = engine.inputNode; let format = input.outputFormat(forBus: 0)
        guard format.channelCount > 0, format.channelCount <= 2, format.sampleRate > 0 else { throw ProjectError.invalid }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("BeatMeat-recording-"+UUID().uuidString+".caf")
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer,_ in
            // AVAudioEngine owns this recording callback. Capture is not a realtime disk scheduler.
            do { try file.write(from: buffer) } catch { NSLog("BeatMeat recording write failed: %@",error.localizedDescription) }
        }
        recordingURL = url
        do { if !engine.isRunning { try start() } }
        catch { input.removeTap(onBus: 0); recordingURL = nil; throw error }
        return url
    }
    func endRecording() -> URL? {
        guard let url = recordingURL else { return nil }
        engine.inputNode.removeTap(onBus: 0); recordingURL = nil; return url
    }
    static func export(_ project: BeatProject, base: URL?, to url: URL, master: Double = 1) throws {
        let k = try makeKernel(project, base: base); defer { BMDestroy(k) }
        let end = max(4,project.tracks.flatMap(\.clips).map {$0.startBeat+$0.lengthBeats}.max() ?? 16)
        guard end*60/project.bpm <= 1800 else { throw ProjectError.audioLimit }
        BMTransport(k,project.bpm,1,0,0,0,end,4)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!
        var remaining = Int((end*60/project.bpm + max(2,8*60/project.bpm))*44100)
        while remaining > 0 {
            let count = min(remaining,1024); buffer.frameLength = AVAudioFrameCount(count)
            let channels = buffer.floatChannelData!; BMRender(k,channels[0],channels[1],UInt32(count))
            for c in 0..<2 { for i in 0..<count { channels[c][i] *= Float(master) } }
            try file.write(from: buffer); remaining -= count
        }
    }
}
