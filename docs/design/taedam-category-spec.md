# 태담 종류 화면 스펙

- **상태**: review
- **작성일**: 2026-07-21
- **적용 범위**: 선택한 태담 카테고리의 대본과 버킷리스트를 보여주는 화면
- **공통 계약**: [태담 공통 데이터 계약](./taedam-common-contracts.md)

> **Figma 확인 사항**: 현재 Home 디자인에서는 추천 카드나 대본 행을 선택하면 대본·생각힌트 미리보기로 직접 이동한다. 이 카테고리 상세 화면으로 들어오는 경로는 확인되지 않았으므로 화면 유지 여부와 진입 경로를 팀에서 재검토해야 한다.

> **코드 확인 사항**: 이 화면과 `TaedamCategorySelectionDTO`, `ScriptRepository`는 현재 원격 코드에 구현되어 있지 않다. 번들 대본은 `develop`에 병합된 `BundledTaedamScriptLoader`가 읽고 있으며, 화면 유지 여부가 확정되기 전에는 별도 View 구현을 시작하지 않는다.

## 1. 목적

사용자가 선택한 카테고리의 태담 대본을 살펴보고, 해당 카테고리의 태담에서 만든 버킷리스트를 함께 확인하게 한다.

## 2. 화면 책임

- `TaedamCategorySelectionDTO.category`와 같은 카테고리의 대본만 표시한다.
- 대본을 선택하면 `ScriptSelectionDTO`를 대본 미리보기에 전달한다.
- `BucketListItem.category`가 선택한 카테고리와 같은 항목을 `@Query`로 관찰한다.
- 버킷리스트는 `createdAt` 내림차순으로 표시한다.
- 이 화면의 버킷리스트는 읽기 전용이다. 문장 수정, 완료 상태 변경과 삭제는 [소원 탭 스펙](./wish-tab-spec.md)에서 다룬다.

## 3. `@Query` 계약

```swift
@Query private var bucketListItems: [BucketListItem]

init(selection: TaedamCategorySelectionDTO) {
    let category = selection.category
    _bucketListItems = Query(
        filter: #Predicate<BucketListItem> { item in
            item.category == category
        },
        sort: [SortDescriptor(\BucketListItem.createdAt, order: .reverse)]
    )
}
```

`@Query`는 같은 `ModelContainer`의 변경을 관찰한다. 해당 카테고리의 버킷리스트가 생성·수정·삭제되면 화면에 자동 반영된다.

## 4. 화면 입출력

| 구분 | 데이터 |
|---|---|
| 입력 | `TaedamCategorySelectionDTO` |
| 대본 조회 | 현재 `BundledTaedamScriptLoader.load().scripts` 결과 중 같은 `category`; 추후 Repository 경계로 교체 가능 |
| 버킷리스트 조회 | 카테고리 필터가 적용된 `@Query` |
| 대본 선택 결과 | `ScriptSelectionDTO` |

## 5. 표시 상태

- **대본 있음**: 선택한 카테고리의 대본 카드를 표시한다.
- **버킷리스트 있음**: 이 카테고리의 태담으로 만든 버킷리스트 목록을 표시한다.
- **버킷리스트 없음**: 해당 카테고리에서 아직 저장한 버킷리스트가 없음을 안내한다.
- **대본 로딩 실패**: 버킷리스트 조회와 분리해 오류를 표시한다.

## 6. 불변 조건

1. 카테고리 필터는 `BucketListItem.category`의 정확한 문자열 일치를 사용한다.
2. `BucketListItem.category`는 저장 시점의 대본 카테고리 스냅샷이며 이 화면에서 수정하지 않는다.
3. 한 태담 세션이 만드는 버킷리스트는 하나이지만, 서로 다른 세션에서 만든 항목은 카테고리 목록에 누적될 수 있다.
