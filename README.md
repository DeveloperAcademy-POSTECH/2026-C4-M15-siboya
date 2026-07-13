# Siboya

Siboya iOS 팀 프로젝트입니다.

## 디렉터리 구조

```text
Siboya/
├── App/                         # 앱 진입점과 앱 전역 조립
├── Core/
│   ├── Extensions/              # Foundation·Swift 표준 타입 확장
│   ├── Services/                # 플랫폼 기능 추상화
│   │   ├── Analysis/            # 말하기 속도·태담 결과 분석
│   │   └── Audio/               # 마이크 권한·녹음·재생
│   └── Utilities/               # Feature에 속하지 않는 작은 유틸리티
├── Features/
│   ├── Home/                    # 메인 홈·태담 시작·최근 결과
│   ├── Report/                  # 상세 리포트·말하기 속도 그래프
│   └── Taedam/                  # 준비·녹음·분석 대기·간단 결과
├── Persistence/                 # SwiftData 영속성 계층
│   ├── Container/
│   ├── Models/
│   └── Stores/
├── Resources/
│   ├── Assets.xcassets/
│   └── Fonts/
└── SupportingFiles/             # Info.plist·entitlements·빌드 설정

SiboyaTests/                      # 단위 테스트
└── Fixtures/

SiboyaUITests/                    # UI 테스트
```

## 구조 원칙

- 화면·화면 상태·화면 전용 컴포넌트는 해당 `Feature` 폴더에 평평하게 둡니다.
- `View`, `ViewModel`, `Components` 같은 하위 폴더는 실제 파일이 많아져 탐색이 불편해질 때 만듭니다.
- 준비·녹음·결과처럼 하나의 사용자 흐름에 속하는 페이지는 별도 Feature로 쪼개지 않습니다.
- 두 개 이상의 Feature에서 실제로 재사용되는 코드가 생겼을 때만 공용 위치를 만듭니다.
- `Core/Services`는 마이크, 오디오, 분석처럼 플랫폼 기능을 담당하며 특정 화면을 import하지 않습니다.
- 영속 데이터는 SwiftData를 사용하고 `Persistence`에서 관리합니다.
- 네트워크 계층은 만들지 않습니다.
- 단위 테스트의 디렉터리는 앱 소스 구조를 가능한 한 동일하게 따릅니다.
