//
//  ContentView.swift
//  Siboya
//
//  Created by Gosan on 7/13/26.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Text("Siboya")
            .task {
                let repository = SwiftDataTaedamRepository(modelContext: modelContext)
                try? await repository.ensureBabyProfile(nickname: "꾹꾹이", gestationalWeek: 22)
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(PersistenceContainer.makeContainer(inMemory: true))
}
