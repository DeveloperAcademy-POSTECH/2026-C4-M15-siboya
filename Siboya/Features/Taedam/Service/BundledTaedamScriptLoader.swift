//
//  BundledTaedamScriptLoader.swift
//  Siboya
//
//  Created by Codex on 7/21/26.
//

import Foundation

enum BundledTaedamScriptLoader {
    static func load(from bundle: Bundle = .main) throws -> TaedamScriptDocument {
        let resourceURL = bundle.url(
            forResource: "taedam-scripts",
            withExtension: "json",
            subdirectory: "Scripts"
        ) ?? bundle.url(
            forResource: "taedam-scripts",
            withExtension: "json"
        )

        guard let resourceURL else {
            throw TaedamScriptLoadingError.resourceNotFound
        }

        let data = try Data(contentsOf: resourceURL)
        return try JSONDecoder().decode(TaedamScriptDocument.self, from: data)
    }
}

enum TaedamScriptLoadingError: Error {
    case resourceNotFound
}
