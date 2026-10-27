import AppKit
import Foundation

@MainActor
enum UIValidation {
    private static var started = false
    static func run(startupError: String?) {
        guard !started, let index = CommandLine.arguments.firstIndex(of: "--ui-smoke-test"), CommandLine.arguments.count > index+1 else { return }
        started = true
        let directory = URL(fileURLWithPath: CommandLine.arguments[index+1])
        DispatchQueue.main.asyncAfter(deadline: .now()+2) {
            do {
                if let startupError { throw NSError(domain: "BeatMeat.UIValidation",code: 1,userInfo: [NSLocalizedDescriptionKey:startupError]) }
                guard let window = NSApp.windows.first(where: {$0.isVisible && $0.title.contains("BeatMeat") && $0.contentView != nil}),
                      let view = window.contentView, view.bounds.width >= 800,view.bounds.height >= 600,
                      let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { throw ProjectError.invalid }
                view.layoutSubtreeIfNeeded()
                view.cacheDisplay(in: view.bounds,to: bitmap)
                guard let png = bitmap.representation(using: .png,properties: [:]) else { throw ProjectError.invalid }
                try FileManager.default.createDirectory(at: directory,withIntermediateDirectories: true)
                try png.write(to: directory.appendingPathComponent("workspace.png"))
                let result: [String:Any] = ["status":"passed","windowTitle":window.title,"width":view.bounds.width,"height":view.bounds.height,"audioGraphInitialized":true,"audioDevicePlaybackTested":false]
                try JSONSerialization.data(withJSONObject: result,options: [.prettyPrinted,.sortedKeys]).write(to: directory.appendingPathComponent("ui-validation.json"))
                exit(0)
            } catch {
                fputs("BeatMeat UI validation failed: \(error)\n",stderr)
                exit(1)
            }
        }
    }
}
