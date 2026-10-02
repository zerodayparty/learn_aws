#!/usr/bin/env bash
command_down() { # 확인된 삭제 목록에 사용자 동의를 받는다.
    local answer # 확인 입력을 보관한다.
    [[ -t 0 ]] || { error 'down은 대화형 DELETE 확인만 지원'; return 2; } # 파이프로 자동 승인하지 않는다.
    acquire_lock || return $? # 생성 작업과 겹치지 않게 한다.
    inventory && assert_topology && show_inventory || return $? # 실제 삭제 대상과 연결을 보여준다.
    warn "Project=$PROJECT, Lab=$LAB_ID, Region=$AWS_REGION의 표시된 관리 대상을 삭제함" # 소유 범위를 안내한다.
    printf '계속하려면 DELETE 입력: ' >&2 # 삭제 확인 질문을 표시한다.
    IFS= read -r answer || return 2 # 입력이 없으면 실패한다.
    [[ "$answer" == DELETE ]] || { warn '삭제 취소'; return 2; } # 정확한 확인 입력만 허용한다.
    source "$APP_ROOT/scripts/steps/10_cleanup.sh" # 공통 정리 단계를 읽는다.
    run_step 'AWS 리소스 정리' cleanup_resources # 정리 성공 근거를 확인한다.
} # 삭제 명령을 끝낸다.
