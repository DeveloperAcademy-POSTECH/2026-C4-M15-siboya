# 태담 진행 기능 스펙

- **상태**: approved
- **작성일**: 2026-07-21
- **적용 범위**: 대본 미리보기, 권한 확인, 3초 카운트다운, 대본 자동 진행, 버킷리스트 STT, 키보드 수정·저장, 태담 요약
- **공통 계약**: [태담 공통 데이터 계약](./taedam-common-contracts.md)

## 1. 목적

사용자가 준비 시간 후 대본을 자연스럽게 따라 읽고, 마지막에 아기와 함께하고 싶은 일을 말한 뒤 키보드로 최종 문장을 확정하게 한다. 완료된 태담 하나당 버킷리스트 하나만 저장하고 요약 화면에도 해당 항목 하나만 보여준다.

## 2. 화면 구성과 책임

| 단계 | 입력 | 주요 동작 | 다음 단계 |
|---|---|---|---|
| 대본 미리보기 | `ScriptSelectionDTO` | 대본 요약 표시, 권한 확인 | `TaedamSessionInputDTO` |
| 카운트다운·대본 진행 | `TaedamSessionInputDTO` | 3초 카운트다운, 문장 채우기, 음성 반응 모션 | 버킷리스트 STT 자동 전환 |
| 버킷리스트 STT | `.bucketList` 줄 | 발화 후 무음 자동 종료, 최대 20초 전사, 수동 정지 | `BucketListDraftDTO` |
| 버킷리스트 텍스트 수정 | `BucketListDraftDTO` | 키보드 수정·확정 | `SaveBucketListCommandDTO` |
| 태담 요약 | `SavedBucketListDTO` | 방금 저장한 `BucketListItem` 하나 표시 | `onComplete: () -> Void` |

## 3. 권한 확인

- 대본 미리보기에서 사용자가 태담 시작을 선택할 때마다 마이크와 Speech 인식 권한을 확인한다.
- `.notDetermined`이면 시스템 권한 요청을 표시한다.
- 필요한 권한이 모두 허용된 뒤에만 태담 대본 화면으로 진입한다.
- `.denied` 또는 `.restricted`이면 시스템 팝업을 반복 요청하지 않고 설정 이동 안내를 보여준다.
- 권한이 확정되기 전에는 3초 카운트다운을 시작하지 않는다.

## 4. 대본 준비·자동 진행

- `TaedamSessionInputDTO`를 만들 때 대본의 `{{babyNickname}}`을 현재 `BabyProfile.nickname`으로 한 번 치환한다.
- 태담 화면 진입 후 `3`, `2`, `1`을 표시하는 3초 카운트다운을 자동 시작한다.
- 카운트다운이 끝나면 첫 번째 일반 문장의 `currentLineProgress`를 `0`으로 두고 대본 스트림을 시작한다.
- 문장 진행 시간은 치환된 표시 텍스트의 공백을 제외한 `Character` 수로 계산한다.

```text
durationSeconds = clamp(characterCount / 4.0, 2.5, 10.0)
```

`4.0`, `2.5`, `10.0`은 UI 테스트 후 조정할 수 있는 타이밍 정책값이다.

- 전체 문장을 기본 색으로 미리 배치하고, `currentLineProgress`에 따라 각 글자의 전경색을 선형 보간해 노래방 가사처럼 채운다.
- 글자 채움 애니메이션은 기본 0.08초이며, 비활성 글자 opacity는 0.15를 사용한다.
- 대본 본문과 STT 플레이스홀더는 SF Pro 28pt Bold, line height 42pt, letter spacing 0.38pt를 사용한다.
- `bucketListGuide` 안내 문구는 SF Pro 20pt Regular, line height 30pt, letter spacing -1pt와 가운데 정렬을 사용한다.
- `KaraokeText`의 채움 표현과 일반 대본문장의 흐림·투명도 표현은 서로 독립적으로 유지한다.
- 텍스트 레이아웃은 진행 중 바뀌지 않는다.
- 진행률이 `1`이 되면 다음 문장을 자동으로 시작한다.
- 대본은 세로 `ScrollView`로 감싸 사용자가 이전·다음 문장을 자유롭게 탐색할 수 있게 한다.
- 대본 진행 중이거나 `.bucketList` 상태일 때 사용자가 이전·현재·다음 일반 대본 문장을 탭하면 현재 진행 Task를 취소하고, 선택한 문장의 진행률을 `0`으로 초기화한 뒤 그 문장부터 즉시 재개한다.
- 문장을 다시 선택할 때 3초 카운트다운은 반복하지 않는다.
- `.bucketList` 줄은 수동으로 선택하지 않는다.
- 자동 진행 Task는 한 번에 하나만 유지하고, 문장 재선택·화면 종료·STT 전환 시 취소한다.

## 5. 실시간 음성 반응

음성 반응 모션은 사용자가 현재 말하고 있음을 즉시 피드백하는 보조 UI이며 발화 품질을 평가하지 않는다.

1. 마이크 버퍼의 RMS를 dB로 변환한다.
2. `target = clamp((rmsDB + 55) / 40, 0, 1)`로 정규화한다.
3. `smoothed = previous + alpha * (target - previous)`로 smoothing한다.
4. `target > previous`이면 `alpha = 0.35`, 그 외에는 `alpha = 0.12`를 초기값으로 사용한다.
5. `target >= 0.15`이면 음성 활성, `target <= 0.08`이 250밀리초 유지되면 비활성으로 판정한다.
6. `eased = smoothed * smoothed * (3 - 2 * smoothed)`를 계산한다.
7. 화면 표시 단계에서 `visualLevel = clamp(eased * 1.7, 0, 1)`로 반응 폭을 증폭한다.
8. 흰색 표면에 `domeHeight = 118 * visualLevel`을 적용하고, 화면 중앙을 기준으로 하나의 넓고
   둥근 곡면이 아래에서 올라왔다가 내려가도록 그린다.

- 화면 하단의 분홍색·파란색·보라색 그라디언트 중심점은 발화 여부와 관계없이 좌우로 계속 이동한다.
- `visualLevel`이 커질수록 분홍색·파란색 그라디언트의 중심 이동 거리, 반경과 화면 확장률을 함께
  증가시켜 음량에 따라 컬러 영역이 넓게 출렁이도록 한다.
- 분홍색과 파란색 빛 덩어리는 서로 다른 주기로 위아래를 왕복한다. `visualLevel`이 커질수록
  왕복 범위를 최대 62pt까지 늘리고 전체 중심을 최대 34pt 위로 올려 Siri와 같은 상승 반응을 만든다.
- 하단의 흰색 표면은 평상시 화면 아래에 머물고, `eased` 값이 커지면 중앙에서 단일 돔 형태로
  올라온 뒤 음량이 작아질수록 부드럽게 내려간다.
- `VoiceMotionMonitoring`은 대본을 읽는 동안에만 input tap을 유지한다. 버킷리스트 STT로 전환할 때
  `stopMonitoring()`으로 tap과 오디오 세션을 정리한 후 `BucketListTranscribing.start(duration:)`을 호출한다.
- 버킷리스트 발화 중에는 STT가 사용하는 동일한 PCM 버퍼에서 `voiceMotionSamples`를 만들어
  흰색 표면의 음성 반응을 끊김 없이 유지한다.
- 사용자가 버킷리스트에서 이전 대본문장을 선택하면 STT를 정리한 후 음성 모션 모니터를 다시 시작한다.
- 시스템의 동작 줄이기 설정이 활성화되면 컬러 그라디언트의 지속 이동은 멈추되 음량 피드백은 유지한다.

`-55 dB`, `-15 dB`, smoothing 계수와 모션 크기는 실기기 UI 테스트 후 조정할 수 있다. 입력 버퍼와 분석값은 화면 반영 직후 폐기한다.

## 6. 버킷리스트 STT·텍스트 수정

- 마지막 일반 문장의 진행률이 `1`이 되면 `bucketListGuide` 안내 카드와 `bucketListPrompt` STT 플레이스홀더로 자동 전환한다.
- `bucketListGuide`는 STT 플레이스홀더 직전에 보조 텍스트로 표시하며 예시 답변은 표시하지 않는다.
- 음성 반응 모니터의 `stopMonitoring()`을 완료해 기존 input tap을 제거한 뒤 STT용 input tap을 설치한다.
- STT는 별도의 스와이프, 탭 또는 시작 버튼 없이 자동 시작한다.
- 한 번의 STT 최대 입력 시간은 20초다.
- STT 진행 중 정지 버튼을 항상 표시한다. 정지 버튼은 `finish()`로 현재 전사 결과를 확정한다.
- 최초 발화를 감지한 뒤 최소 2초의 입력 시간을 확보하고 1.5초 연속 무음이 이어지면 자동으로 `finish()`한다.
- 최초 발화를 감지하지 못한 상태에서는 무음으로 자동 종료하지 않는다.
- 무음 자동 종료 여부와 관계없이 20초가 경과하면 자동으로 `finish()`한다.
- 부분 전사문은 화면 표시용으로만 사용하고 저장하지 않는다.
- 첫 부분 전사문이 들어오면 `bucketListPrompt` 플레이스홀더를 제거하고 전사문으로 덮어쓴다.
- STT 진행 중 일반 대본문장을 선택하면 진행 중인 STT를 중단하고 선택한 문장부터 대본을 재개한다.
- 편집 상태에서 일반 대본문장을 선택하면 작성 중인 문장을 보존한 채 선택한 문장부터 대본을 재개한다.
- STT 중단 후 재개한 대본이 다시 `.bucketList`에 도달하면 STT 진입 이벤트를 다시 전달한다.
- 편집 상태에서 재개한 대본이 다시 `.bucketList`에 도달하면 STT를 시작하지 않고 기존 텍스트필드와 작성 중인 문장을 복원한다.
- 최종 전사문을 `BucketListDraftDTO`로 만든 뒤 키보드로 수정 가능한 `.editingBucketList`로 전환한다.
- 전사 결과 수정 수단은 **키보드 텍스트 수정 하나만** 제공한다.
- 수정 상태의 입력 영역은 일반 대본과 구분되는 라운드 카드 컨테이너로 표시하고 자동으로 키보드 포커스를 준다.
- 수정 중 다른 대본문장, 안내 카드, 화면의 빈 영역을 선택하거나 스크롤하면 입력 포커스를 해제한다.
- 입력 포커스 해제는 `.editingBucketList` 상태와 작성 중인 문장을 변경하지 않으며, 사용자가 텍스트필드를 다시 선택해 계속 수정할 수 있어야 한다.
- **다시 말하기, STT 재시도, 재발화 버튼은 제공하지 않는다.**
- 전사문이 비어 있거나 인식에 실패해도 빈 편집 화면에서 키보드로 직접 입력할 수 있다.
- 키보드 편집 화면은 `rawTranscript`를 초기 `editedText`로 사용하고, 사용자가 최종 확정한 `editedText`만 저장 명령에 넣는다.
- STT가 끝나면 마이크 입력과 인식 Task를 모두 종료한다.

### 무음 기반 자동 종료

STT용 오디오 tap이 Speech 요청에 전달하는 동일한 PCM 버퍼에서 RMS dB를 계산한다. 무음 감지를 위한
별도의 tap은 설치하지 않는다.

- 음성 비활성 상태에서 `rmsDB >= -40`이면 최초 발화와 음성 활성을 감지한다.
- 음성 활성 상태에서 `rmsDB <= -45`이면 무음 구간을 시작한다.
- `-45 < rmsDB < -40` 구간에서는 직전 활성 상태를 유지해 경계값에서 판정이 반복되는 것을 줄인다.
- 최초 발화 감지 후 `최소 2초 입력 + 1.5초 연속 무음`을 모두 만족하면 마이크 입력을 닫는다.
- 무음 도중 발화가 다시 감지되면 연속 무음 시간을 0으로 초기화한다.
- 무음, 20초 제한 또는 Speech 자체 종료 이벤트를 받으면 세션이 `finish()`를 한 번만 호출한다.
- 주변 소음으로 무음을 판단하지 못하는 경우에도 20초 제한과 정지 버튼은 항상 유지한다.

## 7. 저장·태담 요약

- `SaveBucketListCommandDTO.category`는 현재 `TaedamSessionInputDTO.script.category`의 스냅샷이다.
- `SaveBucketListCommandDTO.content`는 사용자가 키보드로 최종 확정한 문장이다.
- 세션은 `save` 성공 후 즉시 `.completed(bucketListItemID:)`로 전환한다.
- 한 세션에서 저장을 두 번 이상 요청하지 않는다.
- 요약 화면은 `SavedBucketListDTO.bucketListItemID`를 이용해 `@Query`를 구성한다.
- 요약 화면은 쿼리 결과 중 해당 ID의 `BucketListItem` 하나만 표시한다. 목록, 최근 항목 또는 같은 카테고리의 다른 항목을 함께 표시하지 않는다.
- 요약 셀에는 카테고리, 버킷리스트 내용과 수행 상태만 표시한다.
- 태담 점수, 발화 평가, 그래프, 주파수·음량 수치, 녹음 시간과 오디오 재생 UI는 표시하지 않는다.
- `@Query`가 빈 배열을 반환하면 저장된 항목을 찾을 수 없는 상태로 처리한다.
- 상위 화면에는 `onComplete: () -> Void`만 전달한다. 상위 화면은 완료 시 현재 화면을 닫고 별도 항목을 강조하거나 추가 이동하지 않는다.

## 8. 런타임 시퀀스

```mermaid
sequenceDiagram
    actor User as 사용자
    participant Preview as 대본 미리보기
    participant Permission as 마이크·Speech 권한
    participant Screen as 태담 화면
    participant Progress as 대본 진행
    participant Motion as 음성 반응
    participant Speech as Speech STT
    participant Keyboard as 키보드 수정
    participant Repository as TaedamRepository
    participant Data as SwiftData
    participant Summary as 태담 요약

    User->>Preview: 태담 시작
    Preview->>Permission: 권한 상태 확인·요청
    alt 필요한 권한 모두 허용
        Permission-->>Preview: granted
        Preview->>Screen: 태담 화면 진입
        Screen->>Progress: 3초 카운트다운
        Progress-->>Screen: 3, 2, 1
        Screen->>Motion: 음성 반응 시작
        loop 일반 대본
            Progress-->>Screen: currentLineProgress
            Motion-->>Screen: normalizedVoiceMotion
            opt 일반 대본 문장 탭
                User->>Screen: 이전·현재·다음 문장 선택
                Screen->>Progress: 현재 Task 취소 후 선택 문장부터 재개
            end
        end
        Progress-->>Screen: 마지막 문장 완료 + bucketListGuide + STT placeholder
        Screen->>Motion: stopMonitoring()
        Screen->>Speech: 20초 STT 자동 시작
        Speech-->>Screen: 부분 전사문
        alt 사용자가 정지
            User->>Screen: 정지
            Screen->>Speech: finish()
        else 최초 발화 후 1.5초 연속 무음
            Speech-->>Screen: silence 자동 종료 이벤트
            Screen->>Speech: finish()
        else 20초 경과
            Speech-->>Screen: maximumDuration 자동 종료 이벤트
            Screen->>Speech: finish()
        end
        Speech-->>Screen: BucketListDraftDTO
        Screen->>Keyboard: 키보드 텍스트 수정
        User->>Keyboard: 문장 수정·확정
        Keyboard->>Repository: SaveBucketListCommandDTO
        Repository->>Data: BucketListItem 하나 insert
        Repository-->>Keyboard: SavedBucketListDTO
        Keyboard->>Summary: bucketListItemID
        Summary->>Data: @Query by id
        Data-->>Summary: BucketListItem 하나
    else 권한 거부·제한
        Permission-->>Preview: denied or restricted
        Preview-->>User: 권한 설명·설정 이동 안내
    end
```

## 9. 핵심 불변 조건

1. STT는 동시에 하나만 실행하며 다시 말하기나 재발화 수정 경로를 제공하지 않는다.
2. STT 결과는 키보드 수정 후에만 저장할 수 있다.
3. 하나의 세션은 `BucketListItem`을 하나만 생성한다.
4. 태담 요약 화면은 해당 세션이 만든 `BucketListItem` 하나만 표시한다.
5. 녹음 파일, 전사 이력, 모션 샘플과 태담 평가 데이터는 저장하지 않는다.
