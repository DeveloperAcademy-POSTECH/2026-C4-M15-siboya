#!/bin/zsh

set -euo pipefail

readonly REPOSITORY_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

cd "$REPOSITORY_ROOT"

if ! command -v swiftlint >/dev/null 2>&1; then
    echo "error: SwiftLint가 설치되어 있지 않습니다. 'brew bundle'을 실행해 주세요."
    exit 1
fi

if [[ -z "$(find Siboya SiboyaTests SiboyaUITests -type f -name '*.swift' -print -quit)" ]]; then
    echo "Swift 파일이 없어 lint를 건너뜁니다."
    exit 0
fi

swiftlint lint --config "$REPOSITORY_ROOT/.swiftlint.yml" "$@"
