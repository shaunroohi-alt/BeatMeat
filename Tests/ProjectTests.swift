import Foundation
import XCTest
@testable import BeatMeatCore

final class ProjectTests: XCTestCase {
    private func fixture() -> BeatProject {
        var project = BeatProject.demo()
        project.name = "Project IO fixture"
        project.tracks[2].clips = [BeatClip(slot: 0, name: "Recorded texture", waveform: [0, 0.25, -0.5, 1])]
        return project
    }

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("BeatMeatProjectTests-" + UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func assertInvalid(
        _ mutate: (inout BeatProject) -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var project = fixture()
        mutate(&project)
        XCTAssertThrowsError(try project.validate(), file: file, line: line) { error in
            guard let projectError = error as? ProjectError, case .invalid = projectError else {
                XCTFail("Expected invalid project data, got \(error)", file: file, line: line)
                return
            }
        }
    }

    private func assertUnsafeMedia(
        _ expression: @autoclosure () throws -> URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try expression(), file: file, line: line) { error in
            guard let projectError = error as? ProjectError, case .unsafeMedia = projectError else {
                XCTFail("Expected unsafe media rejection, got \(error)", file: file, line: line)
                return
            }
        }
    }

    private func writeMetadata(_ project: BeatProject, into directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(project).write(to: directory.appendingPathComponent("Project.json"))
    }

    func testDemoAndValidParameterBoundaries() throws {
        try fixture().validate()
        var project = fixture()
        project.bpm = 20
        project.master = 0
        project.loopStart = 0
        project.loopEnd = 100_000
        project.tracks[0].gain = 0
        project.tracks[0].pan = -1
        project.tracks[0].send = 0
        project.tracks[0].clips[0].startBeat = 100_000
        project.tracks[0].clips[0].lengthBeats = 0.0625
        project.tracks[0].clips[0].notes[0].pitch = 0
        project.tracks[0].clips[0].notes[0].velocity = 0
        try project.validate()
        project.bpm = 300
        project.master = 1
        project.tracks[0].gain = 2
        project.tracks[0].pan = 1
        project.tracks[0].send = 1
        project.tracks[0].clips[0].lengthBeats = 4096
        project.tracks[0].clips[0].notes[0].pitch = 127
        project.tracks[0].clips[0].notes[0].velocity = 1
        try project.validate()
    }

    func testRejectsNonfiniteAndOutOfRangeTransport() {
        assertInvalid { $0.tracks = [] }
        for value in [Double.nan, .infinity, -.infinity, 19.99, 300.01] {
            assertInvalid { $0.bpm = value }
        }
        for value in [Double.nan, .infinity, -.infinity, -0.01] {
            assertInvalid { $0.loopStart = value }
        }
        for value in [Double.nan, .infinity, -.infinity, 0, 100_000.01] {
            assertInvalid { $0.loopEnd = value }
        }
        assertInvalid { $0.loopStart = 16; $0.loopEnd = 16 }
        assertInvalid { $0.loopStart = 17; $0.loopEnd = 16 }
    }

    func testRejectsNonfiniteAndOutOfRangeMixerValues() {
        for value in [Double.nan, .infinity, -.infinity, -0.01, 1.01] {
            assertInvalid { $0.master = value }
        }
        for value in [Double.nan, .infinity, -.infinity, -0.01, 2.01] {
            assertInvalid { $0.tracks[0].gain = value }
        }
        for value in [Double.nan, .infinity, -.infinity, -1.01, 1.01] {
            assertInvalid { $0.tracks[0].pan = value }
        }
        for value in [Double.nan, .infinity, -.infinity, -0.01, 1.01] {
            assertInvalid { $0.tracks[0].send = value }
        }
    }

    func testRejectsInvalidClipTimelineAndSlots() {
        for value in [Double.nan, .infinity, -.infinity, -0.01, 100_000.01] {
            assertInvalid { $0.tracks[0].clips[0].startBeat = value }
        }
        for value in [Double.nan, .infinity, -.infinity, 0, 0.0624, 4096.01] {
            assertInvalid { $0.tracks[0].clips[0].lengthBeats = value }
        }
        assertInvalid { $0.tracks[0].clips[0].slot = -1 }
        assertInvalid { $0.tracks[0].clips[0].slot = 8 }
        assertInvalid { project in
            project.tracks[0].clips.append(BeatClip(slot: 0, name: "Duplicate occupied slot"))
        }
    }

    func testRejectsInvalidNotes() {
        for value in [-1, 128] {
            assertInvalid { $0.tracks[0].clips[0].notes[0].pitch = value }
        }
        for value in [Double.nan, .infinity, -.infinity, -0.01, 1.01] {
            assertInvalid { $0.tracks[0].clips[0].notes[0].velocity = value }
        }
        for value in [Double.nan, .infinity, -.infinity, -0.01] {
            assertInvalid { $0.tracks[0].clips[0].notes[0].startBeat = value }
        }
        for value in [Double.nan, .infinity, -.infinity, -1, 0] {
            assertInvalid { $0.tracks[0].clips[0].notes[0].duration = value }
        }
    }

    func testTrackClipNoteAndWaveformCapacityLimits() throws {
        var project = BeatProject()
        project.tracks = (0..<16).map { BeatTrack(name: "Track \($0)", kind: .midi) }
        project.tracks[0].clips = (0..<8).map { BeatClip(slot: $0, name: "Slot \($0)") }
        project.tracks[0].clips[0].notes = (0..<64).map { BeatNote(pitch: 60, startBeat: Double($0) / 16) }
        project.tracks[0].clips[0].waveform = Array(repeating: 0.25, count: 4096)
        try project.validate()

        var tooManyTracks = project
        tooManyTracks.tracks.append(BeatTrack(name: "Seventeenth", kind: .audio))
        XCTAssertThrowsError(try tooManyTracks.validate())
        var tooManyNotes = project
        tooManyNotes.tracks[0].clips[0].notes.append(BeatNote(pitch: 64, startBeat: 0))
        XCTAssertThrowsError(try tooManyNotes.validate())
        var tooManyClips = project
        tooManyClips.tracks[0].clips.append(BeatClip(slot: 8, name: "Ninth"))
        XCTAssertThrowsError(try tooManyClips.validate())
        var tooMuchWaveform = project
        tooMuchWaveform.tracks[0].clips[0].waveform.append(0)
        XCTAssertThrowsError(try tooMuchWaveform.validate())
        assertInvalid { $0.tracks[2].clips[0].waveform = [.nan] }
        assertInvalid { $0.tracks[2].clips[0].waveform = [.infinity] }
    }

    func testMissingLegacyMasterDefaultsWithoutChangingOtherState() throws {
        XCTAssertEqual(BeatProject.demo().master, 0.8)
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        var project = fixture()
        project.master = 0.31
        project.bpm = 97
        let encoded = try JSONEncoder().encode(project)
        var metadata = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        metadata.removeValue(forKey: "master")
        try JSONSerialization.data(withJSONObject: metadata).write(to: root.appendingPathComponent("Project.json"))
        let restored = try ProjectIO.read(root)
        XCTAssertEqual(restored.master, 0.8)
        XCTAssertEqual(restored.bpm, 97)
        XCTAssertEqual(restored.tracks.map(\.id), project.tracks.map(\.id))
    }

    func testUnsupportedSchemaVersionRejectedByValidationAndRead() throws {
        assertInvalid { $0.version = 0 }
        assertInvalid { $0.version = 2 }
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        var unsupported = fixture()
        unsupported.version = 2
        try writeMetadata(unsupported, into: root)
        XCTAssertThrowsError(try ProjectIO.read(root))
    }

    func testReadRejectsCorruptAndIncompleteJSON() throws {
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        for text in ["{not json", "{}", "[]", "null", "{\"version\":1,\"bpm\":\"fast\"}"] {
            try Data(text.utf8).write(to: root.appendingPathComponent("Project.json"))
            XCTAssertThrowsError(try ProjectIO.read(root), "Accepted invalid metadata: \(text)")
        }
    }

    func testReadRejectsOversizedMetadata() throws {
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try Data(repeating: 32, count: 8_000_001).write(to: root.appendingPathComponent("Project.json"))
        XCTAssertThrowsError(try ProjectIO.read(root)) { error in
            guard let projectError = error as? ProjectError, case .invalid = projectError else {
                XCTFail("Oversized metadata should be rejected before decoding")
                return
            }
        }
    }

    func testSaveCollectsMediaAndRoundTripsWithoutOriginalFile() throws {
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let imported = root.appendingPathComponent("imported.wav")
        let bytes = Data([0x52, 0x49, 0x46, 0x46, 0, 1, 2, 3, 4, 5])
        try bytes.write(to: imported)
        var project = fixture()
        project.bpm = 137.5
        project.master = 0.37
        project.loopEnabled = false
        project.tracks[2].clips[0].audioPath = imported.path
        project.tracks[2].clips[0].startBeat = 8
        project.tracks[2].clips[0].lengthBeats = 6
        let package = root.appendingPathComponent("Song.beatmeat", isDirectory: true)
        let saved = try ProjectIO.write(project, to: package, base: nil)
        let relative = try XCTUnwrap(saved.tracks[2].clips[0].audioPath)
        XCTAssertTrue(relative.hasPrefix("Media/"))
        XCTAssertFalse(relative.hasPrefix("/"))
        XCTAssertEqual(project.tracks[2].clips[0].audioPath, imported.path, "Saving should not mutate the in-memory input")
        try FileManager.default.removeItem(at: imported)

        let opened = try ProjectIO.read(package)
        XCTAssertEqual(opened.name, project.name)
        XCTAssertEqual(opened.bpm, 137.5)
        XCTAssertEqual(opened.master, 0.37)
        XCTAssertFalse(opened.loopEnabled)
        XCTAssertEqual(opened.tracks.map(\.id), project.tracks.map(\.id))
        XCTAssertEqual(opened.tracks[0].clips[0].notes.map(\.id), project.tracks[0].clips[0].notes.map(\.id))
        XCTAssertEqual(opened.tracks[0].clips[0].notes.map(\.pitch), project.tracks[0].clips[0].notes.map(\.pitch))
        XCTAssertEqual(opened.tracks[2].clips[0].startBeat, 8)
        XCTAssertEqual(opened.tracks[2].clips[0].lengthBeats, 6)
        XCTAssertEqual(opened.tracks[2].clips[0].waveform, [0, 0.25, -0.5, 1])
        XCTAssertEqual(try Data(contentsOf: ProjectIO.mediaURL(relative, base: package)), bytes)
    }

    func testOverwriteAndSaveAsRetainRelativeMediaAndLatestEdits() throws {
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("take.wav")
        let bytes = Data([4, 8, 15, 16, 23, 42])
        try bytes.write(to: source)
        var project = fixture()
        project.tracks[2].clips[0].audioPath = source.path
        let package = root.appendingPathComponent("Original.beatmeat", isDirectory: true)
        var saved = try ProjectIO.write(project, to: package, base: nil)
        let originalRelative = try XCTUnwrap(saved.tracks[2].clips[0].audioPath)
        try FileManager.default.removeItem(at: source)
        saved.name = "Edited song"
        saved.bpm = 98
        saved.master = 0.24
        saved.tracks[0].pan = 0.6
        saved = try ProjectIO.write(saved, to: package, base: package)
        let reopened = try ProjectIO.read(package)
        XCTAssertEqual(reopened.name, "Edited song")
        XCTAssertEqual(reopened.bpm, 98)
        XCTAssertEqual(reopened.master, 0.24)
        XCTAssertEqual(reopened.tracks[0].pan, 0.6)
        XCTAssertEqual(reopened.tracks[2].clips[0].audioPath, originalRelative)
        XCTAssertEqual(try Data(contentsOf: ProjectIO.mediaURL(originalRelative, base: package)), bytes)

        let movedPackage = root.appendingPathComponent("Copy.beatmeat", isDirectory: true)
        let copied = try ProjectIO.write(saved, to: movedPackage, base: package)
        try FileManager.default.removeItem(at: package)
        let reopenedCopy = try ProjectIO.read(movedPackage)
        XCTAssertEqual(reopenedCopy.name, "Edited song")
        XCTAssertEqual(reopenedCopy.master, 0.24)
        XCTAssertEqual(copied.tracks[2].clips[0].audioPath, originalRelative)
        XCTAssertEqual(try Data(contentsOf: ProjectIO.mediaURL(originalRelative, base: movedPackage)), bytes)
    }

    func testFailedMediaCollectionPreservesExistingPackage() throws {
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let package = root.appendingPathComponent("Keep.beatmeat", isDirectory: true)
        let original = fixture()
        _ = try ProjectIO.write(original, to: package, base: nil)
        let metadata = package.appendingPathComponent("Project.json")
        let originalBytes = try Data(contentsOf: metadata)
        var bad = original
        bad.name = "Must not replace original"
        bad.tracks[2].clips[0].audioPath = root.appendingPathComponent("missing.wav").path
        XCTAssertThrowsError(try ProjectIO.write(bad, to: package, base: nil))
        XCTAssertEqual(try Data(contentsOf: metadata), originalBytes)
        XCTAssertEqual(try ProjectIO.read(package).name, original.name)
        let leftovers = try FileManager.default.contentsOfDirectory(atPath: root.path)
            .filter { $0.hasPrefix(".beatmeat-save-") }
        XCTAssertTrue(leftovers.isEmpty, "A failed save should clean up its staging folder")
    }

    func testRelativeMediaRequiresPackageAndRejectsTraversal() throws {
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root.appendingPathComponent("Media"), withIntermediateDirectories: true)
        assertUnsafeMedia(try ProjectIO.mediaURL("Media/take.wav", base: nil))
        for path in ["../outside.wav", "Media/../../outside.wav", "Media/../Project.json", "MediaSibling/take.wav", "Other/take.wav"] {
            assertUnsafeMedia(try ProjectIO.mediaURL(path, base: root))
        }
        let safe = try ProjectIO.mediaURL("Media/take.wav", base: root)
        XCTAssertEqual(safe.lastPathComponent, "take.wav")
        XCTAssertEqual(safe.deletingLastPathComponent().lastPathComponent, "Media")
    }

    func testReadRejectsAbsoluteAndTraversalMediaReferences() throws {
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        for path in [root.appendingPathComponent("external.wav").path, "../external.wav", "Media/../../external.wav"] {
            var project = fixture()
            project.tracks[2].clips[0].audioPath = path
            try writeMetadata(project, into: root)
            XCTAssertThrowsError(try ProjectIO.read(root), "Accepted unsafe stored media reference: \(path)")
        }
    }

    func testRejectsSymlinkFileEscapingMediaFolder() throws {
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let package = root.appendingPathComponent("Song.beatmeat", isDirectory: true)
        let media = package.appendingPathComponent("Media", isDirectory: true)
        try FileManager.default.createDirectory(at: media, withIntermediateDirectories: true)
        let outside = root.appendingPathComponent("outside.wav")
        try Data([1, 2, 3]).write(to: outside)
        try FileManager.default.createSymbolicLink(at: media.appendingPathComponent("link.wav"), withDestinationURL: outside)
        assertUnsafeMedia(try ProjectIO.mediaURL("Media/link.wav", base: package))
        var project = fixture()
        project.tracks[2].clips[0].audioPath = "Media/link.wav"
        try writeMetadata(project, into: package)
        XCTAssertThrowsError(try ProjectIO.read(package))
    }

    func testRejectsMediaFolderSymlinkEscapingPackage() throws {
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let package = root.appendingPathComponent("Song.beatmeat", isDirectory: true)
        let outside = root.appendingPathComponent("Song.beatmeat-sibling", isDirectory: true)
        try FileManager.default.createDirectory(at: package, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
        try Data([7, 8, 9]).write(to: outside.appendingPathComponent("take.wav"))
        try FileManager.default.createSymbolicLink(at: package.appendingPathComponent("Media"), withDestinationURL: outside)
        assertUnsafeMedia(try ProjectIO.mediaURL("Media/take.wav", base: package))
        var project = fixture()
        project.tracks[2].clips[0].audioPath = "Media/take.wav"
        try writeMetadata(project, into: package)
        XCTAssertThrowsError(try ProjectIO.read(package))
    }
}
