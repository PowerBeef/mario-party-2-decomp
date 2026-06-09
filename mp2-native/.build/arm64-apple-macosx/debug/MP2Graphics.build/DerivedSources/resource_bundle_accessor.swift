import Foundation

extension Foundation.Bundle {
    static nonisolated let module: Bundle = {
        let mainPath = Bundle.main.bundleURL.appendingPathComponent("MP2Engine_MP2Graphics.bundle").path
        let buildPath = "/Users/patricedery/Coding_Projects/mario_party_2/mp2-native/.build/arm64-apple-macosx/debug/MP2Engine_MP2Graphics.bundle"

        let preferredBundle = Bundle(path: mainPath)

        guard let bundle = preferredBundle ?? Bundle(path: buildPath) else {
            // Users can write a function called fatalError themselves, we should be resilient against that.
            Swift.fatalError("could not load resource bundle: from \(mainPath) or \(buildPath)")
        }

        return bundle
    }()
}