# Script Preview Hero 하단 간격 설계

## 목표

`ScriptPreviewHero`의 썸네일·주차·제목을 Figma 위치로 내리고, 제목 하단과 `ScriptPreviewDuration` 상단 사이의 간격을 `8pt`로 유지한다.

## 원인

- 현재 Hero의 배경과 전경이 같은 `ZStack`의 레이아웃 높이 `396pt`를 함께 사용한다.
- 전경은 Hero 상단에서 `76pt` 떨어진 곳에 고정되어 제목이 끝난 뒤에도 Hero 레이아웃 내부에 큰 빈 공간이 남는다.
- `ScriptPreviewView`는 Duration에 이미 `8pt` 상단 여백을 주지만, 이 값은 제목이 아니라 Hero의 `396pt` 프레임 끝에서 계산된다.
- Figma 노드 `1009:11964`는 썸네일 상단 `140pt`, 주차 상단 `288pt`, 제목 하단 `344pt`, Duration 상단 `352pt`로 구성되어 제목과 Duration 사이가 `8pt`다.

## 검토한 접근

1. **배경과 전경의 레이아웃 책임 분리 — 채택**
   - 배경 이미지와 그라데이션은 Hero의 장식용 `background`로 옮겨 전경 높이에 영향을 주지 않게 한다.
   - 전경은 Figma의 썸네일 상단 `140pt`, 썸네일-주차 `16pt`, 주차-제목 `6pt`를 사용한다.
   - Hero의 레이아웃 경계가 제목에서 끝나므로 상위 View의 `8pt`가 실제 제목과 Duration 사이에 적용된다.
   - Dynamic Type에서 제목이 커지면 Hero 높이도 자연스럽게 늘어난다.

2. **기존 상단 패딩만 증가 — 제외**
   - 일반 글자 크기에서는 비슷해 보여도 `396pt` 안의 남는 공간이 계속 존재해 제목-Duration 간격을 보장하지 못한다.

3. **Hero 전체 높이 축소 — 제외**
   - 배경과 전경을 계속 같은 레이아웃 높이로 묶으므로 배경 크롭과 접근성 글자 크기 대응이 함께 흔들린다.

## 구현 계약

- `ScriptPreviewHero.foregroundTopSpacing`: `140pt`
- `ScriptPreviewHero.thumbnailToWeekSpacing`: `16pt`
- `ScriptPreviewHero.weekToTitleSpacing`: `6pt`
- `ScriptPreviewView.heroToDurationSpacing`: `8pt`
- 배경 높이 `396pt`, 썸네일 `132×132pt`, 모서리 반경 `32pt`, 상단 safe-area 무시는 유지한다.
- `ScriptPreviewDuration`, 본문, 준비자세·권한·전체 화면 흐름은 수정하지 않는다.

## 테스트

- Hero와 Preview가 승인된 간격 상수를 제공하는지 검증한다.
- 일반 글자 크기에서 Hero의 fitting height가 장식 배경 높이보다 작아, 배경이 전경 레이아웃 경계를 늘리지 않는지 검증한다.
- 접근성 글자 크기에서 Hero 높이가 계속 확장되는 기존 테스트를 유지한다.
- 관련 단위 테스트, 전체 `SiboyaTests`, SwiftLint, Debug Simulator 빌드를 실행한다.
