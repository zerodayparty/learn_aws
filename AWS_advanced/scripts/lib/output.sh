#!/usr/bin/env bash
emit() { # 아이콘과 Label을 공통 형식으로 안내한다.
    local color="$1" label="$2" icon="$3" message="$4" # 출력 정보를 구분한다.
    if [[ -t 2 && -z "${NO_COLOR+x}" ]]; then # 실제 안내 터미널에서만 색상을 사용한다.
        printf '\033[%sm%s [%s] %s\033[0m\n' "$color" "$icon" "$label" "$message" >&2 # 색상 안내를 출력한다.
    else # 로그 파일에서는 색상을 빼야 한다.
        printf '%s [%s] %s\n' "$icon" "$label" "$message" >&2 # 일반 안내를 출력한다.
    fi # 색상 분기를 끝낸다.
} # 공통 출력 함수를 끝낸다.
info() { emit 34 INFO 'ℹ️' "$*"; } # 일반 정보를 안내한다.
success() { emit 32 SUCCESS '✅' "$*"; } # 성공을 안내한다.
warn() { emit 33 WARNING '⚠️' "$*"; } # 주의할 내용을 안내한다.
error() { emit 31 ERROR '❌' "$*"; } # 오류를 안내한다.
step_start() { emit 34 STEP '▶' "$1 시작"; } # 논리적 단계의 시작을 안내한다.
step_end() { # 단계의 실제 종료 코드와 간격을 표시한다.
    local title="$1" rc="$2" # 단계 이름과 결과를 받는다.
    if (( rc == 0 )); then success "$title 완료"; else error "$title 실패 (exit=$rc)"; fi # 결과를 표시한다.
    printf '\n\n\n' >&2 # 단계 뒤 간격은 이곳에서만 추가한다.
    return "$rc" # 실패를 성공으로 바꾸지 않는다.
} # 단계 종료 함수를 끝낸다.
run_step() { # 작업 함수를 실행하고 종료 코드를 유지한다.
    local title="$1" rc # 제목과 종료 코드를 준비한다.
    shift # 실행할 함수와 인자만 남긴다.
    step_start "$title" # 시작을 표시한다.
    "$@"; rc=$? # 작업이 실패해도 종료 안내까지 도달한다.
    step_end "$title" "$rc" # 결과와 단계 간격을 출력한다.
} # 단계 실행 함수를 끝낸다.
