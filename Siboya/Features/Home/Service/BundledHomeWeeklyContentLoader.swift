//
//  BundledHomeWeeklyContentLoader.swift
//  Siboya
//
//  Created by Codex on 7/21/26.
//

import Foundation

enum BundledHomeWeeklyContentLoader {
    static func load(from bundle: Bundle = .main) throws -> HomeWeeklyContentDocument {
        let resourceURL = bundle.url(
            forResource: "home-weekly-content",
            withExtension: "json",
            subdirectory: "Home"
        ) ?? bundle.url(
            forResource: "home-weekly-content",
            withExtension: "json"
        )

        guard let resourceURL else {
            throw HomeWeeklyContentLoadingError.resourceNotFound
        }

        let data = try Data(contentsOf: resourceURL)
        return try JSONDecoder().decode(HomeWeeklyContentDocument.self, from: data)
    }
}

enum HomeWeeklyContentLoadingError: Error {
    case resourceNotFound
}
