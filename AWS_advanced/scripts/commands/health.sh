#!/usr/bin/env bash
command_health() { # 단독 health 명령을 준비한다.
    inventory || return $? # 현재 접속 대상을 조회한다.
    source "$APP_ROOT/scripts/steps/09_health_check.sh" # 공통 health 구현을 사용한다.
    run_step 'Health Check' check_health # 검사 결과와 종료 코드를 반환한다.
} # 단독 health를 끝낸다.
