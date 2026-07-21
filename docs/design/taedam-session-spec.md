# 태담 시작·진행 기능 스펙

- **상태**: approved
- **작성일**: 2026-07-21
- **최종 수정일**: 2026-07-21
- **적용 범위**: 대본·생각힌트 미리보기, 준비자세 모달, 권한 확인, 3초 카운트다운, 대본 자동 진행, 버킷리스트 STT, 키보드 수정·저장, 태담 요약
- **공통 계약**: [태담 공통 데이터 계약](./taedam-common-contracts.md)
- **디자인 기준**: [Figma 미리보기](https://www.figma.com/design/20KajaVVEkuuENa1HdSXux/C4---%EC%B1%8C%EB%A6%B0%EC%A7%80-%EC%8B%AD%EC%98%A4%EC%95%BC?node-id=1009-11964), [Figma 준비자세](https://www.figma.com/design/20KajaVVEkuuENa1HdSXux/C4---%EC%B1%8C%EB%A6%B0%EC%A7%80-%EC%8B%AD%EC%98%A4%EC%95%BC?node-id=1009-12106), [Figma 마이크 권한 허용](https://www.figma.com/design/20KajaVVEkuuENa1HdSXux/C4---%EC%B1%8C%EB%A6%B0%EC%A7%80-%EC%8B%AD%EC%98%A4%EC%95%BC?node-id=1009-12161)

## 1. 목적

사용자가 대본과 생각힌트를 한 화면에서 미리 확인하고, 준비자세 모달에서 신체적 준비와 권한 확인을 마친 뒤 대본을 자연스럽게 따라 읽게 한다. 마지막에는 아기와 함께하고 싶은 일을 말한 뒤 키보드로 최종 문장을 확정한다. 완료된 태담 하나당 버킷리스트 하나만 저장하고 요약 화면에도 해당 항목 하나만 보여준다.

## 현재 코드 기준과 View 담당 경계

- `TaedamScreen`, `TaedamScreenModel`, 번들 JSON 로더와 대본 DTO는 PR #8을 통해 `develop`에 병합되어 있다.
- Home, 대본·생각힌트 미리보기, 준비자세 모달, 권한 요청 화면은 원격 코드에 아직 없다.
- 미리보기 View는 `ScriptPreviewDTO`의 표시와 `준비하기` callback만 담당한다. JSON 조회와 `BabyProfile` 조회·치환은 ViewModel 또는 상위 조정자가 담당한다.
- 준비자세 View는 `babyNickname`, 시작 중 상태와 `닫기`·`시작하기` callback을 받는다. 마이크·Speech 권한 API를 View 내부에서 직접 호출하지 않는다.
- 두 View는 `ModelContext`, `@Query`, `SwiftDataTaedamRepository`를 직접 알 필요가 없다. SwiftData는 Home에 표시할 프로필을 상위 계층이 읽거나, 세션 후 저장을 담당할 때만 연결된다.
- 현재 구현된 범위는 JSON 로드·태명 치환·3초 카운트다운·대본 자동 진행·일반 문장 재선택·버킷리스트 도달 callback이다. 음성 반응, STT, 키보드 수정과 저장 연결은 아직 구현되지 않았다.

## 2. 화면 구성과 책임

| 단계 | 입력 | 주요 동작 | 다음 단계 |
|---|---|---|---|
| 대본·생각힌트 미리보기 | `ScriptSelectionDTO` | 대본, 생각힌트와 소요 시간 표시 | 준비자세 모달 |
| 준비자세 모달 | `TaedamSessionInputDTO` | 자세 안내, 마이크·Speech 권한 확인 | 카운트다운·대본 진행 |
| 카운트다운·대본 진행 | `TaedamSessionInputDTO` | 3초 카운트다운, 문장 채우기, 음성 반응 모션 | 버킷리스트 STT 자동 전환 |
| 버킷리스트 STT | `.bucketList` 줄 | 최대 20초 전사, 수동 정지 | `BucketListDraftDTO` |
| 버킷리스트 텍스트 수정 | `BucketListDraftDTO` | 키보드 수정·확정 | `SaveBucketListCommandDTO` |
| 태담 요약 | `SavedBucketListDTO` | 방금 저장한 `BucketListItem` 하나 표시 | `onComplete: () -> Void` |

## 3. 대본·생각힌트 미리보기

### 입력과 표시

- 목표 통합 흐름에서는 Home의 `ScriptSelectionDTO`로 선택한 대본을 조회한다. 다만 현재 `ScriptRepository`와 `ScriptSelectionDTO`는 구현 전이므로 미리보기 View가 직접 이 API를 호출하지 않는다.
- 상위 ViewModel·Coordinator가 현재의 `TaedamScriptContent`를 `ScriptPreviewDTO` 또는 `TaedamSessionInputDTO`로 변환해 미리보기 View에 전달한다.
- `BabyProfile.nickname`으로 `sentences`, `bucketListPrompt`와 `bucketListGuide`의 `{{babyNickname}}`을 한 번 치환해 `TaedamSessionInputDTO`를 만든다.
- 화면 상단에는 뒤로가기 버튼, 대본 대상 임신 주차, 제목, 대표 이미지와 예상 소요 시간을 표시한다.
- 예상 소요 시간은 `estimatedDurationSeconds`를 분 단위로 올림해 `약 N분` 형식으로 표시한다. 값이 없으면 소요 시간 행을 숨긴다.
- 본문 영역에는 `sentences`, `bucketListPrompt`, `bucketListGuide` 순서로 표시한다.
- `bucketListPrompt`는 일반 본문 스타일의 마지막 빈칸 문장으로 표시한다.
- `bucketListGuide`는 Figma처럼 `💡`로 구분한 생각힌트 스타일로 표시하며 별도 대본 문장으로 취급하지 않는다.
- 본문은 세로로 스크롤하고 하단 `준비하기` 버튼은 화면 하단에 고정한다.

### 표시 상태

- **loading**: 선택한 대본과 아기 프로필을 조회한다.
- **loaded**: 대본, 생각힌트와 `준비하기` 버튼을 표시한다.
- **unavailable**: 대본이나 프로필이 없거나 로드에 실패하면 `데이터를 불러오지 못했어요.` 텍스트와 `새로고침` 버튼 하나만 표시한다.

`새로고침`은 선택한 대본과 아기 프로필 조회를 다시 실행한다. 재로딩 중에는 버튼을 비활성화하고 중복 요청을 만들지 않으며 별도 오류 팝업은 표시하지 않는다.

### 사용자 행동

1. 뒤로가기를 선택하면 Home으로 돌아간다.
2. `준비하기`를 선택하면 준비자세 모달을 한 번만 표시한다.
3. `준비하기`는 권한을 요청하거나 카운트다운을 직접 시작하지 않는다.
4. 준비자세 모달을 닫으면 같은 미리보기의 스크롤 위치와 `TaedamSessionInputDTO`를 유지한다.
5. `unavailable`에서 `새로고침`을 선택하면 View는 `onRefresh` callback을 한 번 전달한다.

### Figma와 현재 대본 데이터 차이

| 항목 | Figma 미리보기 | 현재 JSON의 `일요일 아침 냄새` | 구현 원칙 |
|---|---|---|---|
| 대상 주차 | `22주차` | `20주차` | JSON 값을 표시하므로 현재는 `20주차`를 표시한다 |
| 소요 시간 | `약 2분` | `estimatedDurationSeconds == 35`이므로 분 올림 시 `약 1분` | JSON 값을 변환해 현재는 `약 1분`을 표시한다 |
| 마무리 대본 | 빈칸 문장 뒤에 `맛있게 먹어줄 거지? … 사랑해.` 표시 | 해당 종료 문장 없음. 테스트도 종료 인사를 제외하도록 확인 | JSON에 없는 Figma 전용 문장은 표시하지 않는다 |
| 생각힌트 | 전구 아이콘 뒤 요리·식사 주제 안내 | 같은 문구가 `bucketListGuide`에 존재 | `bucketListGuide`를 표시한다 |
| 대표 이미지 | 이미지와 배경 존재 | `artworkAssetName`은 있으나 해당 imageset은 브랜치에 없음 | 이미지가 없으면 공통 `script_artwork_placeholder`를 표시하고 데이터 로딩 실패로 처리하지 않는다 |

화면 모양은 Figma를 따르고 문구·주차·소요 시간은 JSON에서 만든 DTO를 우선한다. View는 값에 따라 길이와 줄 수가 달라져도 레이아웃이 유지되게 한다.

## 4. 준비자세 모달·권한 확인

### 모달 표시

- 준비자세는 미리보기 위에 dim 배경과 함께 표시하는 bottom sheet다.
- sheet는 화면 상단 일부를 남기고 올라오며 grabber와 닫기 버튼을 표시한다.
- 중앙에 준비 자세를 설명하는 이미지, `태담 준비하기` 제목과 아래 안내를 표시한다.

```text
아내의 배에 손을 얹고
{{babyNickname}}와 교감할 준비가 되면
시작 버튼을 눌러주세요
```

- 하단에는 `시작하기` 버튼을 고정한다.
- 닫기 버튼을 선택하면 권한 요청과 세션 시작 없이 미리보기로 돌아간다.
- grabber를 아래로 드래그하면 sheet를 닫을 수 있다.
- grabber 드래그와 닫기 버튼은 동일한 dismiss 동작을 사용한다. 둘 다 권한 요청이나 세션 시작 없이 같은 미리보기의 스크롤 위치와 `TaedamSessionInputDTO`를 유지한다.

### 시작하기·권한 확인

- 준비자세 모달에서 사용자가 `시작하기`를 선택할 때마다 마이크와 Speech 인식 권한을 확인한다.
- `.notDetermined`이면 시스템 권한 요청을 표시한다.
- 권한 요청 중에는 `시작하기`를 다시 선택할 수 없게 한다.
- 필요한 권한이 모두 허용된 뒤에만 모달을 닫고 태담 대본 화면으로 진입한다.
- 마이크 권한이 `.denied` 또는 `.restricted`이면 Figma의 `마이크권한 허용` Alert를 표시한다.

```text
음성기능을 사용하시려면 [설정
> 개인정보보호 > 마이크]에서
태담앱의 접근을 허용해 주세요.
```

- Alert에는 `닫기`와 `설정` 버튼을 표시한다.
- `설정`은 `UIApplication.openSettingsURLString`으로 앱별 설정 화면을 연다. iOS 공개 API로 마이크 토글의 세부 화면을 직접 열지는 않는다.
- `닫기`는 Alert만 닫고 준비자세 모달을 유지한다. 이후 사용자가 `시작하기`를 다시 누르면 권한을 다시 확인하고, 여전히 거부 상태이면 같은 Alert를 다시 표시한다.
- 설정 앱에서 앱으로 돌아와도 세션을 자동 시작하지 않는다. 사용자가 `시작하기`를 다시 눌렀을 때 권한을 재확인한다.
- Speech 인식 권한이 `.denied` 또는 `.restricted`인 경우에도 같은 `닫기`·`설정` 구조를 사용하고 본문은 `음성 인식 기능을 사용하시려면 설정에서 태담앱의 음성 인식 접근을 허용해 주세요.`로 표시한다.
- 권한이 확정되기 전에는 3초 카운트다운을 시작하지 않는다.
- 모달이 화면에 남아 있거나 사라지는 애니메이션 중에는 카운트다운을 시작하지 않는다.

## 5. 카운트다운·대본 자동 진행

- 권한이 모두 허용되고 준비자세 모달이 닫힌 뒤 태담 화면에서 `3`, `2`, `1`을 표시하는 3초 카운트다운을 한 번만 자동 시작한다.
- 카운트다운이 끝나면 첫 번째 일반 문장의 `currentLineProgress`를 `0`으로 두고 대본 스트림을 시작한다.
- 문장 진행 시간은 치환된 표시 텍스트의 공백을 제외한 `Character` 수로 계산한다.

```text
durationSeconds = clamp(characterCount / 4.0, 2.5, 10.0)
```

`4.0`, `2.5`, `10.0`은 UI 테스트 후 조정할 수 있는 타이밍 정책값이다.

- 전체 문장을 기본 색으로 미리 배치하고, `currentLineProgress`에 따라 각 글자의 전경색을 선형 보간해 노래방 가사처럼 채운다.
- 현재 코드는 글자 채움 애니메이션 0.08초, 비활성 글자 opacity 0.15를 사용한다.
- 대본 본문과 STT 플레이스홀더는 SF Pro 28pt Bold, line height 42pt, letter spacing 0.38pt를 사용한다.
- `KaraokeText`의 채움 표현과 일반 대본문장의 흐림·투명도 표현은 서로 독립적으로 유지한다.
- 텍스트 레이아웃은 진행 중 바뀌지 않는다.
- 진행률이 `1`이 되면 다음 문장을 자동으로 시작한다.
- 대본은 세로 `ScrollView`로 감싸 사용자가 이전·다음 문장을 둘러볼 수 있게 한다. 문장 단위 페이지 이동용 스와이프 제스처는 제공하지 않는다.
- 대본 진행 중이거나 `.bucketList` 상태일 때 사용자가 이전·현재·다음 일반 대본 문장을 탭하면 현재 진행 Task를 취소하고, 선택한 문장의 진행률을 `0`으로 초기화한 뒤 그 문장부터 즉시 재개한다.
- 문장을 다시 선택할 때 3초 카운트다운은 반복하지 않는다.
- `.bucketList` 줄은 수동으로 선택하지 않는다.
- 자동 진행 Task는 한 번에 하나만 유지하고, 문장 재선택·화면 종료·STT 전환 시 취소한다.

## 6. 실시간 음성 반응

음성 반응 모션은 사용자가 현재 말하고 있음을 즉시 피드백하는 보조 UI이며 발화 품질을 평가하지 않는다.

1. 마이크 버퍼의 RMS를 dB로 변환한다.
2. `target = clamp((rmsDB + 55) / 40, 0, 1)`로 정규화한다.
3. `smoothed = previous + alpha * (target - previous)`로 smoothing한다.
4. `target > previous`이면 `alpha = 0.35`, 그 외에는 `alpha = 0.12`를 초기값으로 사용한다.
5. `target >= 0.15`이면 음성 활성, `target <= 0.08`이 250밀리초 유지되면 비활성으로 판정한다.
6. `eased = smoothed * smoothed * (3 - 2 * smoothed)`를 계산한다.
7. 배경 View에 `scale = 1 + 0.08 * eased`, `shapeDeformation = 0.12 * eased`를 적용한다.

`-55 dB`, `-15 dB`, smoothing 계수와 모션 크기는 실기기 UI 테스트 후 조정할 수 있다. 입력 버퍼와 분석값은 화면 반영 직후 폐기한다.

## 7. 버킷리스트 STT·텍스트 수정

- 마지막 일반 문장의 진행률이 `1`이 되면 `bucketListGuide` 안내 카드와 `bucketListPrompt` STT 플레이스홀더로 자동 전환한다.
- `bucketListGuide`는 플레이스홀더 직전에 보조 텍스트로 표시하며 예시 답변은 표시하지 않는다.
- 음성 반응 모니터의 `stopMonitoring()`을 완료해 기존 input tap을 제거한 뒤 STT용 input tap을 설치한다.
- STT는 별도의 스와이프, 탭 또는 시작 버튼 없이 자동 시작한다.
- 한 번의 STT 최대 입력 시간은 20초다.
- STT 진행 중 정지 버튼을 항상 표시한다. 정지 버튼은 `finish()`로 현재 전사 결과를 확정한다.
- 20초가 경과하면 자동으로 `finish()`한다.
- 부분 전사문은 화면 표시용으로만 사용하고 저장하지 않는다.
- 첫 부분 전사문이 들어오면 `bucketListPrompt` 플레이스홀더를 제거하고 전사문으로 대체한다.
- `.bucketList` 상태에서 일반 대본문장을 선택하면 진행 중인 STT를 중단하고 선택한 문장부터 대본을 재개한다.
- 재개한 대본이 끝나 다시 `.bucketList`에 도달하면 `onBucketListReached` 이벤트를 다시 전달한다.
- 최종 전사문을 `BucketListDraftDTO`로 만든 뒤 `.reviewingBucketListDraft`로 전환한다.
- 전사 결과 수정 수단은 **키보드 텍스트 수정 하나만** 제공한다.
- **다시 말하기, STT 재시도, 재발화 버튼은 제공하지 않는다.**
- 전사문이 비어 있거나 인식에 실패해도 빈 편집 화면에서 키보드로 직접 입력할 수 있다.
- 키보드 편집 화면은 `rawTranscript`를 초기 `editedText`로 사용하고, 사용자가 최종 확정한 `editedText`만 저장 명령에 넣는다.
- STT가 끝나면 마이크 입력과 인식 Task를 모두 종료한다.

### 무음 기반 자동 종료

이 기능은 팀 합의 전까지 구현하지 않는다. 현재는 20초 타임아웃과 사용자의 정지 입력만 사용한다.

후보 정책은 발화를 한 번 탐지한 뒤 `최소 2초 입력 + 1.5초 연속 무음`을 만족하면 종료하는 방식이다. 적용하더라도 20초 제한과 정지 버튼은 유지한다.

## 8. 저장·태담 요약

> **코드 확인 사항**: `develop`의 `SavedBucketListDTO`는 `bucketListItemID`만 가진다. 미병합 PR #6의 결과 화면은 주차·주제·이미지·요약까지 포함한 별도 표시 데이터를 기대하고 있어 통합 계약 정리가 필요하다. 이 연결은 Home·미리보기·준비자세 View의 담당 범위가 아니다.

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

## 9. 런타임 시퀀스

```mermaid
sequenceDiagram
    actor User as 사용자
    participant Home as Home
    participant Preview as 대본 미리보기
    participant Preparation as 준비자세 모달
    participant Permission as 마이크·Speech 권한
    participant Settings as 설정 앱
    participant Screen as 태담 화면
    participant Progress as 대본 진행
    participant Motion as 음성 반응
    participant Speech as Speech STT
    participant Keyboard as 키보드 수정
    participant Repository as TaedamRepository
    participant Data as SwiftData
    participant Summary as 태담 요약

    User->>Home: 추천 카드 또는 대본 선택
    Home->>Preview: ScriptSelectionDTO
    Preview->>Preview: ScriptPreviewDTO + BabyProfile 조회
    User->>Preview: 준비하기
    Preview->>Preparation: 준비자세 모달 표시
    alt 사용자가 모달 닫기
        User->>Preparation: 닫기
        Preparation-->>Preview: 미리보기 상태 유지
    else 사용자가 시작하기
        User->>Preparation: 시작하기
        Preparation->>Permission: 권한 상태 확인·요청
        alt 필요한 권한 모두 허용
            Permission-->>Preparation: granted
            Preparation->>Screen: 모달 닫기 + TaedamSessionInputDTO
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
            alt 사용자가 20초 전 정지
                User->>Screen: 정지
                Screen->>Speech: finish()
            else 20초 경과
                Speech-->>Screen: 자동 finish()
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
            Permission-->>Preparation: denied or restricted
            Preparation-->>User: Figma 권한 Alert 표시
            alt 설정 선택
                User->>Preparation: 설정
                Preparation->>Settings: openSettingsURLString
                Settings-->>Preparation: 앱 복귀
                Preparation-->>User: 준비자세 유지·자동 시작 안 함
            else 닫기 선택
                User->>Preparation: 닫기
                Preparation-->>User: Alert만 닫고 준비자세 유지
            end
        end
    end
```

## 10. 핵심 불변 조건

1. 미리보기의 `준비하기`는 준비자세 모달만 열며 권한 요청이나 카운트다운을 시작하지 않는다.
2. 닫기 버튼 또는 grabber 드래그로 준비자세 모달을 닫으면 미리보기 상태를 유지하고 권한 요청, 오디오 입력과 진행 Task를 시작하지 않는다.
3. 권한이 모두 허용되고 준비자세 모달이 닫힌 뒤에만 3초 카운트다운을 한 번 시작한다.
4. 중복 탭이나 화면 전환 애니메이션으로 모달, 세션 또는 카운트다운이 중복 생성되지 않는다.
5. 미리보기와 태담 진행 모두 `bucketListPrompt`는 빈칸 문장·STT 플레이스홀더로, `bucketListGuide`는 생각힌트·발화 주제 안내로 구분해 사용한다.
6. STT는 하나의 태담 세션에서 한 번만 시작하며 재발화 수정 경로를 제공하지 않는다.
7. STT 결과는 키보드 수정 후에만 저장할 수 있다.
8. 하나의 세션은 `BucketListItem`을 하나만 생성한다.
9. 태담 요약 화면은 해당 세션이 만든 `BucketListItem` 하나만 표시한다.
10. 녹음 파일, 전사 이력, 모션 샘플과 태담 평가 데이터는 저장하지 않는다.
