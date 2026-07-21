//
//  TaedamScreen.swift
//  Siboya
//
//  Created by Codex on 7/21/26.
//

import SwiftUI

@MainActor
struct TaedamScreen: View {
    @State private var model: TaedamScreenModel
    @State private var bucketListInputModel: TaedamBucketListInputModel
    @FocusState private var isBucketListEditorFocused: Bool

    private let onBack: () -> Void
    private let onFinish: () -> Void
    private let onBucketListReached: () -> Void
    private let onReplayScriptFromBucketList: () -> Void

    init(
        input: TaedamSessionInputDTO,
        transcriber: (any BucketListTranscribing)? = nil,
        onBack: @escaping () -> Void = {},
        onFinish: @escaping () -> Void = {},
        onBucketListReached: @escaping () -> Void = {},
        onReplayScriptFromBucketList: @escaping () -> Void = {}
    ) {
        _model = State(initialValue: TaedamScreenModel(input: input))
        _bucketListInputModel = State(
            initialValue: TaedamBucketListInputModel(
                transcriber: transcriber ?? SpeechBucketListTranscriber()
            )
        )
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

            transcriptionControl

            if let countdownValue = model.countdownValue {
                countdownOverlay(value: countdownValue)
            }
        }
        .task {
            model.start()
        }
        .onDisappear {
            model.cancel()
            Task {
                await bucketListInputModel.cancel()
            }
        }
        .onChange(of: model.phase) { oldPhase, newPhase in
            guard oldPhase != .bucketList,
                  newPhase == .bucketList else {
                return
            }

            onBucketListReached()
            Task {
                await bucketListInputModel.start(duration: .seconds(20))
            }
        }
        .onChange(of: bucketListInputModel.phase) { _, newPhase in
            if newPhase != .editing {
                isBucketListEditorFocused = false
            }
        }
    }

    private var toolbar: some View {
        HStack {
            Button {
                closeScreen(action: onBack)
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
                closeScreen(action: onFinish)
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
                                bucketListText: bucketListDisplayText(for: line),
                                editedBucketListText: Binding(
                                    get: { bucketListInputModel.editedText },
                                    set: { bucketListInputModel.editedText = $0 }
                                ),
                                isBucketListEditing: line.kind == .bucketList &&
                                    bucketListInputModel.phase == .editing,
                                bucketListEditorFocus: $isBucketListEditorFocused,
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
                .scrollDismissesKeyboard(.immediately)
                .background {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isBucketListEditorFocused = false
                        }
                }
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
        isBucketListEditorFocused = false

        if model.phase == .bucketList {
            onReplayScriptFromBucketList()

            if bucketListInputModel.phase == .editing {
                model.selectLine(at: index)
                return
            }

            Task {
                await bucketListInputModel.cancel()
                model.selectLine(at: index)
            }
            return
        }

        model.selectLine(at: index)
    }

    @ViewBuilder
    private var transcriptionControl: some View {
        if bucketListInputModel.phase == .transcribing {
            VStack {
                Spacer()

                Button {
                    Task {
                        await bucketListInputModel.finish()
                    }
                } label: {
                    Label("말하기 완료", systemImage: "stop.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .frame(height: 48)
                        .background(.black, in: Capsule())
                        .shadow(color: .black.opacity(0.14), radius: 14, y: 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("버킷리스트 말하기 완료")
                .padding(.bottom, 32)
            }
        } else if bucketListInputModel.phase == .finalizing {
            VStack {
                Spacer()

                ProgressView("음성을 정리하고 있어요")
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 18)
                    .frame(height: 44)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 32)
            }
        }
    }

    private func bucketListDisplayText(for line: TaedamLineDTO) -> String {
        guard line.kind == .bucketList else { return line.text }

        let transcript = bucketListInputModel.liveTranscript.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return transcript.isEmpty ? line.text : transcript
    }

    private func closeScreen(action: @escaping () -> Void) {
        isBucketListEditorFocused = false
        model.cancel()
        Task {
            await bucketListInputModel.cancel()
            action()
        }
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
