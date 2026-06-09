// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MP2Engine",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "MP2Core", targets: ["MP2Core"]),
        .library(name: "MP2Runtime", targets: ["MP2Runtime"]),
        .library(name: "MP2Assets", targets: ["MP2Assets"]),
        .library(name: "MP2Graphics", targets: ["MP2Graphics"]),
        .library(name: "MP2Audio", targets: ["MP2Audio"]),
        .library(name: "MP2Platform", targets: ["MP2Platform"]),
        .library(name: "MP2Overlays", targets: ["MP2Overlays"]),
        .library(name: "MP2MinigameKit", targets: ["MP2MinigameKit"]),
        .executable(name: "MP2App", targets: ["MP2App"]),
    ],
    targets: [
        .target(name: "MP2Core"),
        .target(
            name: "MP2Platform",
            dependencies: ["MP2Core"]
        ),
        .target(
            name: "MP2Assets",
            dependencies: ["MP2Core"]
        ),
        .target(
            name: "MP2Graphics",
            dependencies: ["MP2Core", "MP2Assets"],
            resources: [.process("Shaders")]
        ),
        .target(
            name: "MP2Audio",
            dependencies: ["MP2Core", "MP2Assets"]
        ),
        .target(
            name: "MP2Overlays",
            dependencies: ["MP2Core", "MP2Assets", "MP2MinigameKit"]
        ),
        .target(
            name: "MP2MinigameKit",
            dependencies: ["MP2Core"]
        ),
        .target(
            name: "MP2Runtime",
            dependencies: [
                "MP2Core",
                "MP2Platform",
                "MP2Assets",
                "MP2Graphics",
                "MP2Audio",
            ]
        ),
        .executableTarget(
            name: "MP2App",
            dependencies: [
                "MP2Runtime",
                "MP2Graphics",
                "MP2Platform",
                "MP2Overlays",
                "MP2MinigameKit",
            ]
        ),
        .testTarget(
            name: "MP2EngineTests",
            dependencies: [
                "MP2Core",
                "MP2Runtime",
                "MP2Assets",
                "MP2Overlays",
                "MP2MinigameKit",
            ]
        ),
    ]
)
