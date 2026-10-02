#!/usr/bin/env bash
set -uo pipefail # 미정의 변수와 파이프 실패를 확인하고 단계 실패는 직접 처리한다.
umask 077 # 새 키와 상태파일을 다른 사용자에게 공개하지 않는다.
APP_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd) # 실행 파일 위치를 기준으로 공통 코드를 찾는다.
source "$APP_ROOT/scripts/lib/output.sh" # 출력 규칙을 읽는다.
command="${1:-help}" # 명령이 없으면 도움말을 표시한다.
if (( $# > 1 )); then error '추가 인자·옵션은 지원하지 않음'; exit 2; fi # 임의 옵션을 잘못 해석하지 않는다.
case "$command" in # 지원 명령을 확인한다.
    help) printf '%s\n' 'AWS Lab: up | status | health | ssh | down | help' '공식 명령: docker compose run --rm aws-lab <command>' 'down은 AWS 리소스 삭제이며 DELETE 확인이 필요함'; exit 0 ;; # 도움말에는 AWS 접근이 없다.
    up|status|health|ssh|down) ;; # 구현된 명령만 허용한다.
    *) error '알 수 없는 명령. help를 확인해'; exit 2 ;; # 잘못된 명령은 실패한다.
esac # 명령 확인을 끝낸다.
for tool in aws jq python3 ssh ssh-keygen sha256sum; do command -v "$tool" >/dev/null || { error "필수 도구 없음: $tool"; exit 2; }; done # 실행 도구를 확인한다.
for lib in config aws resources lock ssh; do source "$APP_ROOT/scripts/lib/$lib.sh"; done # 공통 함수만 읽는다.
finish() { # 종료 시 현재 실행이 만든 임시파일과 잠금만 정리한다.
    local rc=$? # 원래 명령 결과를 유지한다.
    [[ -z "${SSH_TEMP:-}" ]] || rm -rf "$SSH_TEMP" # 컨테이너 임시 개인키를 지운다.
    release_lock # 획득한 실습 잠금만 해제한다.
    exit "$rc" # 원래 성공·실패 코드를 반환한다.
} # 종료 처리를 끝낸다.
trap finish EXIT # 정상·실패 종료 모두 자원을 정리한다.
trap 'exit 130' INT # Ctrl+C를 실패 종료로 처리한다.
trap 'exit 143' TERM # 종료 신호를 실패 종료로 처리한다.
validate_config "$command" || exit $? # 필요한 설정을 검증한다.
run_step 'AWS 인증 확인' authenticate || exit $? # 실제 인증 계정의 일치를 확인한다.
source "$APP_ROOT/scripts/commands/$command.sh" # 해당 명령의 단계 조합을 읽는다.
"command_$command" # 명령 종료 코드를 프로세스 결과로 반환한다.
