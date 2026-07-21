//
//  ResultArtworkResolverTests.swift
//  SiboyaTests
//
//  Created by Codex on 7/22/26.
//

import Testing
import UIKit
@testable import Siboya

@MainActor
struct ResultArtworkResolverTests {
    @Test func existingArtworkUsesRequestedAsset() {
        let resolvedName = ResultArtworkResolver.resolve("TitleImage")

        #expect(resolvedName == "TitleImage")
        #expect(UIImage(named: resolvedName) != nil)
    }

    @Test func missingArtworkUsesDisplayableFallback() {
        let resolvedName = ResultArtworkResolver.resolve("missing-artwork")

        #expect(resolvedName == ResultArtworkResolver.fallbackAssetName)
        #expect(UIImage(named: resolvedName) != nil)
    }

    @Test func everyBundledScriptResolvesToDisplayableArtwork() throws {
        let document = try BundledTaedamScriptLoader.load()

        for script in document.scripts {
            let resolvedName = ResultArtworkResolver.resolve(
                script.metadata.artworkAssetName
            )
            #expect(UIImage(named: resolvedName) != nil)
        }
    }
}
