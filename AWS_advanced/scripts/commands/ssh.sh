#!/usr/bin/env bash
command_ssh() { # 대화형 SSH 접속을 실행한다.
    inventory && prepare_ssh ask || return $? # 현재 대상과 개인키를 확인한다.
    info '최초 SSH Fingerprint를 확인해. 변경된 호스트 키는 자동 승인하지 않음' # 사용자 확인을 안내한다.
    run_step "SSH 접속" ssh "${SSH_ARGS[@]}" -t "$SSH_TARGET" # 접속 종료 코드를 유지한다.
} # 대화형 접속을 끝낸다.
