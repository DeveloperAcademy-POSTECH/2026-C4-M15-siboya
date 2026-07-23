//
//  TaedamChecklistView.swift
//  Siboya
//
//  SCRUM-26 태담 체크박스 리스트
//  화면 렌더링만 담당. Repository 호출·에러 처리는 TaedamChecklistViewModel로 분리.
//  BucketListItem 표시용 서브뷰는 ChecklistRow.swift 참고.
//

import SwiftUI
import SwiftData

struct TaedamChecklistView: View {
    
    @Query private var babyProfiles: [BabyProfile]
    @Query(
        sort: \BucketListItem.createdAt,
        order: .reverse
    )
    private var bucketListItems: [BucketListItem]
    
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TaedamChecklistViewModel()
    
    @State private var expandedItemID: UUID?
    
    @State private var isEditingNickname = false
    @State private var draftNickname = ""
    @FocusState private var isNicknameFieldFocused: Bool
    
    @State private var isEditingWeek = false
    @State private var draftWeek = 1
    
    private let weekRange = Array(1...42)
    
    private var babyProfile: BabyProfile? { babyProfiles.first }
    
    private var repository: TaedamRepository {
        SwiftDataTaedamRepository(modelContext: modelContext)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            List {
                ForEach(bucketListItems, id: \.id) { item in
                    ChecklistRow(
                        item: item,
                        isExpanded: expandedItemID == item.id,
                        onTap: { toggleExpand(item.id) },
                        onDelete: { delete(item.id) },
                        onCommitEdit: { newContent in updateContent(item.id, newContent) }
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                }
            }
            .listStyle(.plain)
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $isEditingWeek) {
            weekPickerSheet
                .presentationDetents([.height(360)])
        }
        .alert(
            "오류",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("확인") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: Header
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if isEditingNickname {
                    TextField("태명", text: $draftNickname)
                        .font(.system(size: 28, weight: .bold))
                        .focused($isNicknameFieldFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            commitNicknameChange()
                        }
                } else {
                    Text(babyProfile?.nickname ?? "태명 미설정")
                        .font(.system(size: 28, weight: .bold))
                }
                
                Spacer()
                
                Menu {
                    Button {
                        startEditingNickname()
                    } label: {
                        Label("태명 변경", systemImage: "pencil")
                    }
                    Button {
                        startEditingWeek()
                    } label: {
                        Label("주차 수정", systemImage: "calendar")
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(Color(red: 0.45, green: 0.45, blue: 0.45))
                }
                .tint(Color(red: 0.45, green: 0.45, blue: 0.45))
            }
            
            // Title3/Regular
            if let week = babyProfile?.gestationalWeek {
                Text("임신 \(week)주차")
                    .font(Font.custom("SF Pro", size: 20))
                    .foregroundColor(Color("PrimaryRed"))
            }
            
            Image("TaedamCharacter")
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
    
    // MARK: 주차 수정 시트
    
    private var weekPickerSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Button("취소") {
                    isEditingWeek = false
                }
                .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("현재 주수")
                    .font(.system(size: 17, weight: .semibold))
                
                Spacer()
                
                Button("완료") {
                    commitWeekChange()
                }
                .fontWeight(.semibold)
                .foregroundColor(Color("PrimaryRed"))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)
            
            Picker("주차", selection: $draftWeek) {
                ForEach(weekRange, id: \.self) { week in
                    Text(week == draftWeek ? "\(week) 주차" : "\(week)")
                        .tag(week)
                }
            }
            .pickerStyle(.wheel)
        }
    }
    
    // MARK: Actions — 태명 변경
    
    private func startEditingNickname() {
        draftNickname = babyProfile?.nickname ?? ""
        isEditingNickname = true
        DispatchQueue.main.async {
            isNicknameFieldFocused = true
        }
    }
    
    private func commitNicknameChange() {
        let nickname = draftNickname
        isEditingNickname = false
        Task {
            await viewModel.updateNickname(nickname, using: repository)
        }
    }
    
    // MARK: Actions — 주차 수정
    
    private func startEditingWeek() {
        draftWeek = babyProfile?.gestationalWeek ?? 1
        isEditingWeek = true
    }
    
    private func commitWeekChange() {
        let week = draftWeek
        isEditingWeek = false
        Task {
            await viewModel.updateGestationalWeek(week, using: repository)
        }
    }
    
    // MARK: Actions — 리스트
    
    private func toggleExpand(_ id: UUID) {
        withAnimation(.easeInOut(duration: 0.2)) {
            expandedItemID = (expandedItemID == id) ? nil : id
        }
    }
    
    private func delete(_ id: UUID) {
        Task {
            await viewModel.delete(bucketListItemID: id, using: repository)
        }
    }
    
    private func updateContent(_ id: UUID, _ content: String) {
        Task {
            await viewModel.updateContent(bucketListItemID: id, content: content, using: repository)
        }
    }
}

// MARK: - Preview

#Preview {
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(
        for: BabyProfile.self, BucketListItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext
    context.insert(BabyProfile(nickname: "꾹꾹이", gestationalWeek: 28))
    context.insert(BucketListItem(category: "멀리멀리 대모험", content: "메론빵 만들어주기"))
    context.insert(BucketListItem(
        category: "멀리멀리 대모험",
        content: "돗자리를 깔고 누워 하늘을 같이 보며 가장 반짝이는 별 하나를 찾아내고 싶어"
    ))
    context.insert(BucketListItem(category: "일상공유", content: "사랑한다고 말하기"))
    
    return TaedamChecklistView()
        .modelContainer(container)
}
