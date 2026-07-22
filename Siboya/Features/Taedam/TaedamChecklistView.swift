//
//  TaedamChecklistView.swift
//  Siboya
//
//  실제 BucketListItem /
//

import SwiftUI

// MARK: - Mock Model (실제 계약 확정 전 임시 타입)

struct MockChecklistItem: Identifiable {
    let id = UUID()
    var title: String
    var date: String
    var tag: String
}

// MARK: - Mock Data

private let mockItems: [MockChecklistItem] = [
    MockChecklistItem(title: "메론빵 만들어주기", date: "Apr 8", tag: "멀리멀리 대모험"),
    MockChecklistItem(title: "돗자리를 깔고 누워 하늘을 같이 보며 가장 반짝이는 별 하나를 찾아내고 싶어", date: "Apr 7", tag: "멀리멀리 대모험"),
    MockChecklistItem(title: "놀이터 벤치에 나란히 앉아서 시원한 아이스크림 먹기", date: "Apr 6", tag: "멀리멀리 대모험"),
    MockChecklistItem(title: "무릎에 너를 앉히고 나직한 목소리로 재미있는 모험 이야기 들려주기", date: "Apr 5", tag: "멀리멀리 대모험"),
    MockChecklistItem(title: "사랑한다고 말하기", date: "Apr 8", tag: "일상공유")
]

// MARK: - Main View

struct TaedamChecklistView: View {

    @State private var items: [MockChecklistItem] = mockItems
    @State private var expandedItemID: MockChecklistItem.ID?
    @State private var selectedTab: Tab = .promise

    enum Tab {
        case taedam
        case promise
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            List {
                ForEach(items) { item in
                    ChecklistRow(
                        item: item,
                        isExpanded: expandedItemID == item.id,
                        onTap: { toggleExpand(item.id) },
                        onDelete: { delete(item.id) }
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                }
            }
            .listStyle(.plain)

            bottomTabBar
        }
        .background(Color(.systemBackground))
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("꾹꾹이")
                    .font(.system(size: 28, weight: .bold))
                Spacer()
                Menu {
                    Button {
                        // TODO: 태명 변경 — 데이터 계약 확정 후 구현
                    } label: {
                        Label("태명 변경", systemImage: "pencil")
                    }
                    Button {
                        // TODO: 주차 수정 — 데이터 계약 확정 후 구현
                    } label: {
                        Label("주차 수정", systemImage: "calendar")
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(.primary)
                }
            }

            Text("임신 28주차")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.orange)

            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [.orange.opacity(0.5), .pink.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 180)
                .padding(.top, 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: Bottom Tab Bar

    private var bottomTabBar: some View {
        HStack(alignment: .top, spacing: 0) {
            Spacer()
            tabBarContent
            Spacer()
        }
        .padding(.horizontal, 25)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var tabBarContent: some View {
        let buttons = HStack(spacing: 12) {
            tabButton(title: "태담", systemImage: "heart.fill", tab: .taedam)
            tabButton(title: "약속", systemImage: "lightbulb.fill", tab: .promise)
        }
        .padding(8)

        if #available(iOS 26.0, *) {
            buttons.glassEffect(.regular, in: Capsule())
        } else {
            buttons.background(Capsule().fill(Color(.secondarySystemBackground)))
        }
    }

    private func tabButton(title: String, systemImage: String, tab: Tab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.caption2)
            }
            .foregroundStyle(isSelected ? .orange : .secondary)
            .frame(maxWidth: 85)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(isSelected ? Color.orange.opacity(0.15) : .clear)
            )
        }
    }

    // MARK: Actions (\)

    private func toggleExpand(_ id: MockChecklistItem.ID) {
        withAnimation(.easeInOut(duration: 0.2)) {
            expandedItemID = (expandedItemID == id) ? nil : id
        }
    }

    private func delete(_ id: MockChecklistItem.ID) {
        items.removeAll { $0.id == id }
    }
}

// MARK: - Row

private struct ChecklistRow: View {
    let item: MockChecklistItem
    let isExpanded: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var showMenu = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Text(item.title)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(isExpanded ? nil : 1)
                    .onTapGesture(perform: onTap)
                
                Spacer()
                
                Menu {
                    Button {
                        // TODO: 내용 수정
                    } label: {
                        Label("내용 수정", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: onDelete) {
                        Label("삭제", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                Label(item.date, systemImage: "calendar")
                Label(item.tag, systemImage: "tag")
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
}

//#Preview {
//    TaedamChecklistView()
//}
