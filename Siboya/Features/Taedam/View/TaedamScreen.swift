//
//  TaedamScreen.swift
//  Siboya
//
//  Created by Codex on 7/21/26.
//

import SwiftUI

struct TaedamScreen: View {
    @State private var model: TaedamScreenModel

    private let onBack: () -> Void
    private let onFinish: () -> Void
    private let onBucketListReached: () -> Void
    private let onReplayScriptFromBucketList: () -> Void

    init(
        input: TaedamSessionInputDTO,
        onBack: @escaping () -> Void = {},
        onFinish: @escaping () -> Void = {},
        onBucketListReached: @escaping () -> Void = {},
        onReplayScriptFromBucketList: @escaping () -> Void = {}
    ) {
        _model = State(initialValue: TaedamScreenModel(input: input))
        self.onBack = onBack
        self.onFinish = onFinish
        self.onBucketListReached = onBucketListReached
        self.onReplayScriptFromBucketList = onReplayScriptFromBucketList
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.white
                .ignoresSafeArea()

            TaedamAmbientBackground()

            scriptScrollView

            TaedamToolbarBackground()

            toolbar

            if let countdownValue = model.countdownValue {
                countdownOverlay(value: countdownValue)
            }
        }
        .task {
            model.start()
        }
        .onDisappear {
            model.cancel()
        }
        .onChange(of: model.phase) { oldPhase, newPhase in
            guard oldPhase != .bucketList,
                  newPhase == .bucketList else {
                return
            }

            onBucketListReached()
        }
    }

    private var toolbar: some View {
        HStack {
            Button {
                model.cancel()
                onBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.94), in: Circle())
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 5)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("뒤로 가기")

            Spacer()

            Button {
                model.cancel()
                onFinish()
            } label: {
                Text("완료")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(red: 0.95, green: 0.29, blue: 0.26))
                    .padding(.horizontal, 15)
                    .frame(height: 40)
                    .background(.white.opacity(0.94), in: Capsule())
                    .shadow(color: .black.opacity(0.07), radius: 12, y: 5)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("태담 완료")
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var scriptScrollView: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 22) {
                        ForEach(model.lines) { line in
                            TaedamScriptLineView(
                                line: line,
                                currentLineIndex: model.currentLineIndex,
                                progress: model.currentLineProgress,
                                bucketListGuide: model.bucketListGuide,
                                isSelectable: model.isLineSelectable(at: line.index)
                            ) {
                                selectLine(at: line.index)
                            }
                            .id(line.id)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 80)
                    .padding(.bottom, geometry.size.height * 0.72)
                }
                .scrollIndicators(.hidden)
                .onChange(of: model.currentLineIndex) { _, newIndex in
                    guard let newIndex else { return }

                    withAnimation(.smooth(duration: 0.8)) {
                        proxy.scrollTo(
                            newIndex,
                            anchor: UnitPoint(x: 0.5, y: 0.08)
                        )
                    }
                }
            }
        }
    }

    private func selectLine(at index: Int) {
        if model.phase == .bucketList {
            onReplayScriptFromBucketList()
        }

        model.selectLine(at: index)
    }

    private func countdownOverlay(value: Int) -> some View {
        ZStack {
            Color.white.opacity(0.78)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)

            VStack(spacing: 14) {
                Text("태담을 시작할게요")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("taedam-countdown-title")

                Text(value, format: .number)
                    .font(.system(size: 76, weight: .bold, design: .rounded))
                    .foregroundStyle(.black)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: value)
                    .accessibilityLabel("태담 시작 (value)초 전")
            }
        }
        .transition(.opacity)
    }
}

#Preview {
    TaedamScreen(input: .mock)
}
