# Siboya


[![Swift](https://img.shields.io/badge/Swift-5-orange.svg)]()
[![Xcode](https://img.shields.io/badge/Xcode-26.6-blue.svg)]()
[![iOS](https://img.shields.io/badge/iOS-26.5-black.svg)]()
[![SwiftLint](https://img.shields.io/badge/SwiftLint-0.63.3-purple.svg)]()

---

## 🗂 목차

- [소개](#-소개)
- [프로젝트 기간](#-프로젝트-기간)
- [기술 스택](#-기술-스택)
- [주요 기능](#-주요-기능)
- [폴더 구조](#-폴더-구조)
- [구조 원칙](#-구조-원칙)
- [팀 소개](#-팀-소개)
- [브랜치 전략](#-브랜치-전략)
- [커밋 메시지 컨벤션](#-커밋-메시지-컨벤션)
- [SwiftLint](#-swiftlint)
- [실행 및 테스트 방법](#-실행-및-테스트-방법)

---

## 📱 소개

> 직장인 예비 아빠가 퇴근 후 태담 요청 앞에서 매일 무슨 말을 해야 할지 막막함을 느낄 때,
> 현재 임신 주차에 맞는 아기의 성장과 아내의 변화를 바탕으로 제공되는 짧은 태담 대본을 따라 말하며
> 아빠가 되어가는 과정을 부담 없이 쌓아가도록 돕는 앱입니다.

Siboya는 예비 아빠가 태담을 시작할 때 느끼는 부담을 줄이고, 매일의 태담 기록과 피드백을 통해 아기와 교감하는 습관을 만들어 갈 수 있도록 돕습니다.

## 📆 프로젝트 기간

- 전체 기간: `2026.06.22 - 2026.07.24`

## 🛠 기술 스택

- Language: Swift 5
- UI: SwiftUI
- Architecture: 경량 MVVM
- Persistence: SwiftData
- Audio: AVFoundation
- Speech Recognition: Speech
- Code Quality: SwiftLint, GitHub Actions
- Collaboration: Git, GitHub, Figma
- Development Environment: Xcode 26.6
- Deployment Target: iOS 26.5

## 🌟 주요 기능

- 현재 상황에 맞는 태담 대본과 생각선 미리보기
- 마이크 권한 확인 후 카운트다운을 통한 태담 시작
- 대본을 확인하며 태담 녹음
- 녹음 결과 분석 및 간단한 피드백 제공
- 사용자 말하기 속도 그래프와 상세 리포트 제공
- 과거 태담 기록을 SwiftData로 보관하고 조회

## 🧱 폴더 구조

```text
Siboya/
├── App/                         # 앱 진입점·탭·내비게이션
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

## 🧭 구조 원칙

- 화면·화면 상태·화면 전용 컴포넌트는 해당 `Feature` 폴더에 평평하게 둡니다.
- `View`, `ViewModel`, `Components` 같은 하위 폴더는 실제 파일이 많아져 탐색이 불편해질 때 만듭니다.
- 준비·녹음·결과처럼 하나의 사용자 흐름에 속하는 페이지는 별도 Feature로 쪼개지 않습니다.
- 두 개 이상의 Feature에서 실제로 재사용되는 코드가 생겼을 때만 공용 위치를 만듭니다.
- `Core/Services`는 마이크, 오디오, 분석처럼 플랫폼 기능을 담당하며 특정 화면을 import하지 않습니다.
- 영속 데이터는 SwiftData를 사용하고 `Persistence`에서 관리합니다.
- 네트워크 계층은 만들지 않습니다.
- 단위 테스트 디렉터리는 앱 소스 구조를 가능한 한 동일하게 따릅니다.

## 🧑‍💻 팀 소개

| 이름 | 역할 | GitHub |
|---|---|---|
| 고산 | Developer |  |
| 바라 | Developer · Designer |  |
| 제이 | Developer |  |
| 에린 | Developer |  |
| 노을 | Developer |  |
| 예티 | Developer |  |

## 🔖 브랜치 전략

모든 기능 및 버그 수정은 프로젝트 이슈를 생성한 뒤 해당 이슈 키를 브랜치 이름에 포함합니다.

- `main`: 배포 가능한 안정 버전
- `develop`: 통합 개발 브랜치
- `feature/{이슈키}-{기능명}`: 새로운 기능 개발
- `bugfix/{이슈키}-{기능명}`: 버그 수정
- `hotfix/{이슈키}-{기능명}`: 긴급 수정

### 예시

```text
feature/SCRUM-15-taedam-record
feature/SCRUM-18-home-ui
bugfix/SCRUM-22-audio-session
hotfix/SCRUM-31-crash-on-launch
```

## 🌀 커밋 메시지 컨벤션

[Conventional Commits](https://www.conventionalcommits.org)을 따릅니다.

### 예시

- `feat: 태담 녹음 화면 추가`
- `fix: 녹음 종료 시 크래시 수정`
- `chore: SwiftLint 설정 추가`
- `docs: README 프로젝트 정보 보강`

## 🧹 SwiftLint

SwiftLint 설정은 저장소 루트의 [`.swiftlint.yml`](.swiftlint.yml)을 사용합니다.

```bash
# 최초 1회 또는 Brewfile 변경 후
brew bundle

# 로컬 검사
./Scripts/lint.sh

# 필요할 때만 warning까지 실패 처리하는 엄격 검사
./Scripts/lint.sh --strict
```

현재 설정은 SwiftLint `0.63.3`에서 검증합니다. GitHub Actions는 warning을 표시하되 error만 실패로 처리합니다. 현재는 로컬 스크립트와 GitHub Actions가 검사를 담당하며, 필요해지면 앱·단위 테스트·UI 테스트 타깃에 `SwiftLintBuildToolPlugin`을 연결합니다.

## ✅ 실행 및 테스트 방법

1. 저장소를 클론합니다.

   ```bash
   git clone https://github.com/DeveloperAcademy-POSTECH/2026-C4-M15-siboya.git
   cd 2026-C4-M15-siboya
   ```

2. 개발 도구와 SwiftLint를 준비합니다.

   ```bash
   brew bundle
   ```

3. Xcode 26.6에서 `Siboya.xcodeproj`를 엽니다.
4. iOS 26.5 이상의 시뮬레이터 또는 실기기를 선택합니다.
5. `Cmd + R`로 앱을 실행합니다.
6. `Cmd + U`로 테스트를 실행합니다.
7. PR을 열기 전에 SwiftLint를 실행합니다.

   ```bash
   ./Scripts/lint.sh
   ```
