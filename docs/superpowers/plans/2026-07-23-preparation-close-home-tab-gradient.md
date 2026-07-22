# 준비자세 닫기 버튼·Home 탭바 Gradient 수정 계획

**목표:** Figma 기준대로 준비자세 모달의 닫기 버튼을 원형 Liquid Glass와 16pt inset으로 고정하고, Home 탭바 배경을 단색이 아닌 투명→시스템 배경 gradient로 수정한다.

**원인:** 준비자세 닫기 버튼은 `.glass`의 기본 border shape와 외부 frame에 의존해 원형 외곽과 실제 위치가 명시되지 않았다. Home 탭바는 16pt gradient 아래뿐 아니라 전체 컨테이너에도 불투명 `systemBackground`를 적용해 투명 stop에서도 흰색만 노출됐다.

**구현 방식:** 닫기 버튼은 `TaedamPreparationView`의 top-trailing overlay로 분리하고 `.buttonBorderShape(.circle)`를 적용한다. Home 탭바는 전체 배경을 담당하는 하나의 `LinearGradient`만 사용하고 safe area까지 확장한다. 기존 callback, 권한 흐름, 탭 선택 상태와 Dynamic Type 동작은 변경하지 않는다.

## Task 1: 실패 테스트 추가

**수정 파일**

- `SiboyaTests/Home/ScriptPreviewViewTests.swift`
- `SiboyaTests/Home/HomeComponentsTests.swift`

1. 닫기 버튼의 외곽 `44pt`, 상·우 inset `16pt`, symbol container `36pt` 계약을 추가한다.
2. 대비색 위에 탭바를 렌더링해 상단에는 뒤 콘텐츠가 비치고 하단에는 system background가 섞이는지 픽셀로 검증한다.
3. 기존 구현에서 두 테스트가 실패하는지 확인한다.

## Task 2: 닫기 버튼 수정

**수정 파일**

- `Siboya/Features/Home/View/TaedamPreparationView.swift`

1. 기존 HStack 내부의 닫기 버튼을 View 전체의 top-trailing overlay로 이동한다.
2. `xmark`는 17pt medium, symbol container는 36pt로 사용한다.
3. `44×44pt` 버튼 영역에 `.glassEffect(.regular.interactive(), in: Circle())`를 직접 적용해 시스템 button style의 가변 inset을 피한다.
4. 버튼 외곽은 `44×44pt`, sheet 상단·우측 inset은 각각 `16pt`로 유지한다.
5. 기존 이미지·안내·시작 버튼 배치와 닫기 callback을 보존한다.

## Task 3: Home 탭바 배경 수정

**수정 파일**

- `Siboya/Features/Home/Component/HomeBottomTabBar.swift`

1. 별도 16pt gradient와 전체 불투명 `systemBackground` 조합을 제거한다.
2. 탭바 전체 영역에 투명→`Color(.systemBackground)` 세로 gradient를 적용한다.
3. gradient를 하단 safe area까지 확장한다.
4. glass capsule, 선택 상태, callback과 접근성 최소 높이는 유지한다.

## Task 4: 검증

1. 두 집중 단위 테스트를 통과시킨다.
2. 실제 Home과 Home→Preview→Preparation UI 경로를 실행해 탭바 fade와 원형 닫기 버튼 위치를 스크린샷으로 비교한다.
3. 전체 `SiboyaTests`, lint, Debug simulator build를 실행한다.
4. 사용자 소유 `project.pbxproj`와 staged `img_profile.imageset` 변경은 수정하거나 커밋하지 않는다.
