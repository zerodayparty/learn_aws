#!/usr/bin/env bash
acquire_lock() { # 같은 실습의 생성과 삭제를 겹치지 않게 한다.
    LOCK_DIR="$STATE_DIR/lock" # 모든 컨테이너가 공유하는 경로다.
    mkdir "$LOCK_DIR" 2>/dev/null || { error '실습 변경 작업 잠금이 존재함. README 복구 절차 확인 필요'; return 3; } # 생성에 성공한 실행 하나만 진행한다.
    LOCK_HELD=1 # 현재 실행이 만든 잠금임을 기억한다.
    printf '%s %s\n' "${HOSTNAME:-local}" "$$" >"$LOCK_DIR/owner" # 잠금 소유 실행을 기록한다.
} # 잠금 획득을 끝낸다.
release_lock() { # 현재 실행이 만든 잠금만 정리한다.
    if [[ "${LOCK_HELD:-0}" == 1 ]]; then rm -f "$LOCK_DIR/owner"; rmdir "$LOCK_DIR"; fi # 타 실행의 잠금을 건드리지 않는다.
} # 잠금 해제를 끝낸다.
