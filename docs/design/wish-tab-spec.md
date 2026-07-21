# 소원 탭 기능 스펙

- **상태**: review
- **작성일**: 2026-07-21
- **적용 범위**: 태담에서 생성한 전체 버킷리스트 조회·문장 수정·완료 상태 변경·삭제
- **공통 계약**: [태담 공통 데이터 계약](./taedam-common-contracts.md)

## 1. 목적

사용자가 여러 태담 세션에서 만든 버킷리스트를 한곳에서 모아 보고 관리하게 한다.

UI에서는 **소원**이라고 표현하지만, 영속 모델과 코드 계약에서는 `BucketListItem`을 사용한다.

## 2. 화면 책임

- 전체 `BucketListItem`을 `@Query`로 관찰한다.
- 기본 표시 순서는 `createdAt` 내림차순이다.
- 각 항목에 대본 카테고리, 버킷리스트 내용, 완료 상태와 생성 시각을 표시한다.
- 문장 수정, 완료 상태 toggle과 삭제는 `TaedamRepository`를 통해 실행한다.
- `category`는 태담 저장 시점의 스냅샷이므로 수정 기능을 제공하지 않는다.

## 3. `@Query` 계약

```swift
@Query(
    sort: \BucketListItem.createdAt,
    order: .reverse
)
private var bucketListItems: [BucketListItem]
```

- 추가·수정·삭제로 `@Query` 결과가 변경되면 화면은 자동으로 다시 렌더링한다.
- 일회성 목록 조회 메서드를 Repository에 추가하지 않는다.
- Repository 변경 작업이 실패하면 `@Query`가 관찰하는 모델을 낙관적으로 가정해 덮어쓰지 않고 오류를 표시한다.

## 4. 사용자 행동

### 문장 수정

1. 사용자가 수정을 선택하면 현재 `content`를 초기값으로 하는 키보드 편집 UI를 보여준다.
2. trim 후 빈 문자열은 저장할 수 없다.
3. 확정한 문장을 `UpdateBucketListContentCommandDTO`로 만들어 `updateContent` 호출에 전달한다.

### 완료 상태 변경

1. 사용자가 완료 상태를 선택하면 `toggleCompletion(bucketListItemID:)`을 호출한다.
2. 화면에서 `isCompleted` 반대값을 계산해 Repository에 보내지 않는다.
3. Repository가 SwiftData에 저장된 최신 값을 뒤집고, `@Query`가 결과를 화면에 반영한다.

### 삭제

1. 삭제 대상의 `bucketListItemID`를 `delete(bucketListItemID:)`에 전달한다.
2. 삭제 확인 UI 여부와 문구는 화면 정책으로 다룬다.
3. 삭제가 성공하면 `@Query`가 해당 항목을 목록에서 제거한다.

## 5. 표시 상태

- **empty**: 저장된 소원이 없음을 안내한다.
- **loaded**: 전체 버킷리스트를 최신순으로 표시한다.
- **editing**: 선택한 항목의 문장을 편집한다.
- **mutating**: 수정·toggle·삭제 중 같은 항목에 중복 요청을 보내지 않는다.
- **failed**: 해당 변경이 반영되지 않았음을 안내하고 재시도할 수 있게 한다.

## 6. 불변 조건

1. 소원 탭은 버킷리스트를 새로 생성하지 않는다.
2. `category` 또는 `createdAt`을 수정하지 않는다.
3. 녹음, STT 원문과 태담 진행 상태를 조회하거나 표시하지 않는다.
4. 한 태담 세션이 만든 하나의 `BucketListItem`은 소원 탭에서 하나의 목록 항목으로 표시된다.
