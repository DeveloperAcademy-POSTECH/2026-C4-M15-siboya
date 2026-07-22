

//
//  ChecklistRow.swift
//  Siboya
//
//  SCRUM-26 태담 체크박스 리스트 — 리스트 카드 서브뷰
//

import SwiftUI

struct ChecklistRow: View {
    let item: BucketListItem
    let isExpanded: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    let onCommitEdit: (String) -> Void

    @State private var isEditingContent = false
    @State private var draftContent = ""
    @FocusState private var isContentFieldFocused: Bool

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                if isEditingContent {
                    TextField("내용", text: $draftContent, axis: .vertical)
                        .font(.system(size: 15, weight: .medium))
                        .focused($isContentFieldFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            commitEdit()
                        }
                } else {
                    Text(item.content)
                        .font(.system(size: 15, weight: .medium))
                        .lineLimit(isExpanded ? nil : 1)
                        .onTapGesture(perform: onTap)
                }

                Spacer()

                Menu {
                    Button {
                        startEditingContent()
                    } label: {
                        Label("내용 수정", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: onDelete) {
                        Label("삭제", systemImage: "trash")
                    }
                } label: {
                                    Image(systemName: "ellipsis")
                                        .foregroundStyle(Color(red: 0.45, green: 0.45, blue: 0.45))
                                }
                                .tint(Color(red: 0.45, green: 0.45, blue: 0.45))
                            }

            HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                Text(Self.dateFormatter.string(from: item.createdAt))
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "tag")
                                Text(item.category)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color(red: 1, green: 1, blue: 1))
        .cornerRadius(16)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("삭제", systemImage: "trash")
            }
        }
    }

    private func startEditingContent() {
        draftContent = item.content
        isEditingContent = true
        DispatchQueue.main.async {
            isContentFieldFocused = true
        }
    }

    private func commitEdit() {
        let trimmed = draftContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            isEditingContent = false
            return
        }
        onCommitEdit(trimmed)
        isEditingContent = false
    }
}
