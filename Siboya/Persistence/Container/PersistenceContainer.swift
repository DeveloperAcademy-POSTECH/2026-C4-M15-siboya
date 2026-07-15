//
//  PersistenceContainer.swift
//  Siboya
//
//  Created by 노을 on 7/15/26.
//

import SwiftData

enum PersistenceContainer {
    static let shared: ModelContainer = makeContainer()

    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([TaedamRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
