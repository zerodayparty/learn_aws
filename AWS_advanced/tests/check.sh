#!/usr/bin/env bash
set -euo pipefail # 검증 실패를 성공으로 숨기지 않는다.
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd) # 프로젝트 위치를 찾는다.
export LANG=C.UTF-8 # 한국어 주석을 UTF-8로 읽는다.
while IFS= read -r file; do # 각 Bash 파일을 별도로 확인한다.
    bash -n "$file" # 실행하지 않고 문법만 검사한다.
    shellcheck -S warning -e SC1090,SC1091,SC2034 "$file" # 동적 공통 함수와 외부 설정 변수의 경고만 제외한다.
done < <(find "$ROOT/scripts" -name '*.sh' -type f) # 실행 코드만 검사한다.
shellcheck "$ROOT/aws-lab" # Bash Wrapper도 검사한다.
export AWS_LAB_SCHEMA_CLI="$(command -v aws)" # SDK 입력 검증을 위한 실제 CLI 경로만 전달한다.
python3 "$ROOT/tests/run_tests.py" # 가짜 도구로 실패와 복구 흐름을 검사한다.
