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
    @Query(sort: \TaedamRecord.date, order: .reverse) private var records: [TaedamRecord]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(records) { record in
                    NavigationLink {
                        Text("\(record.scriptKeyword) — \(record.date, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(record.date, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteRecords)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addRecord) {
                        Label("Add Record", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select a record")
        }
    }

    private func addRecord() {
        withAnimation {
            let newRecord = TaedamRecord(date: Date(), scriptKeyword: "사랑")
            modelContext.insert(newRecord)
        }
    }

    private func deleteRecords(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(records[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PersistenceContainer.makeContainer(inMemory: true))
}
