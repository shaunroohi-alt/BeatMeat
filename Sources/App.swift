import AppKit
import SwiftUI

@MainActor
final class BeatMeatDelegate: NSObject, NSApplicationDelegate {
    weak var studio: Studio?
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        (studio?.confirmClose() ?? true) ? .terminateNow : .terminateCancel
    }
}

@main
@MainActor
struct BeatMeatApp: App {
    @NSApplicationDelegateAdaptor(BeatMeatDelegate.self) private var delegate
    @StateObject private var studio: Studio
    init() {
        if let index = CommandLine.arguments.firstIndex(of: "--smoke-test") {
            guard CommandLine.arguments.count > index+1 else { fputs("Missing smoke output directory\n",stderr); exit(2) }
            do { try SelfTest.run(URL(fileURLWithPath: CommandLine.arguments[index+1])); print("BeatMeat project/MIDI/export checks passed"); exit(0) }
            catch { fputs("BeatMeat smoke failed: \(error)\n",stderr); exit(1) }
        }
        _studio = StateObject(wrappedValue: Studio())
        NSApplication.shared.setActivationPolicy(.regular)
    }
    var body: some Scene {
        WindowGroup("BeatMeat by MP-Audio") {
            WorkspaceView().environmentObject(studio).preferredColorScheme(.dark)
                .frame(minWidth: 1050,minHeight: 780)
                .onAppear { delegate.studio = studio; NSApp.activate(ignoringOtherApps: true); UIValidation.run(startupError: studio.error) }
                .onOpenURL { studio.openURL($0) }
                .alert("BeatMeat",isPresented: Binding(get: {studio.error != nil},set: {if !$0 {studio.error = nil}})) {
                    Button("OK") {studio.error = nil}
                } message: {Text(studio.error ?? "")}
        }
        .defaultSize(width: 1440,height: 920)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Project") {studio.newProject()}.keyboardShortcut("n")
                Button("Open Project…") {studio.open()}.keyboardShortcut("o")
                Button("Save Project") {studio.save()}.keyboardShortcut("s")
                Divider()
                Button("Import Audio…") {studio.importAudio()}.keyboardShortcut("i")
                Button("Import MIDI…") {studio.importMIDI()}
                Button("Export Arrangement as WAV…") {studio.exportWAV()}.keyboardShortcut("e",modifiers: [.command,.shift])
                Button("Export Selected MIDI Clip…") {studio.exportMIDI()}
            }
            CommandGroup(replacing: .undoRedo) {
                Button("Undo Project Edit") {studio.undo()}.keyboardShortcut("z")
                Button("Redo Project Edit") {studio.redo()}.keyboardShortcut("z",modifiers: [.command,.shift])
            }
            CommandMenu("Transport") {
                Button(studio.playing ? "Pause" : "Play") {studio.play()}
                Button("Stop and Rewind") {studio.stop()}
                Button("Back to Arrangement") {studio.backToArrangement()}
            }
            CommandGroup(replacing: .help) {
                Button("Manual Coverage and Limitations") {
                    let alert = NSAlert(); alert.messageText = "BeatMeat · independent development build"
                    alert.informativeText = "Based on a full text review of the supplied 534-page Ableton Live 8 manual. See Docs/MANUAL_BLUEPRINT.md and FEATURE_COVERAGE.md in the source package. This build implements a limited original audio/MIDI workflow; it is not a feature-complete Live implementation. Advanced warping, plug-in hosting, racks, automation, Max for Live, video and licensed libraries are not supplied."
                    alert.runModal()
                }
            }
        }
    }
}
