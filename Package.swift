// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "BeatMeatCore", platforms: [.macOS(.v14)], products: [.library(name: "BeatMeatCore",targets: ["BeatMeatCore"])], targets: [
    .target(name: "BeatMeatCore",path: "Sources",exclude: ["Audio","UI","App.swift","Studio.swift","SelfTest.swift","BeatMeat-Bridging-Header.h"],sources: ["Project.swift","MIDIFile.swift"]),
    .testTarget(name: "BeatMeatCoreTests",dependencies: ["BeatMeatCore"],path: "Tests",exclude: ["KernelTests.cpp"])
])
