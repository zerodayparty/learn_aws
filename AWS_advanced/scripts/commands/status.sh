#!/usr/bin/env bash
status_data() { inventory && show_inventory; } # 조회 성공과 데이터 출력을 연결한다.
command_status() { run_step "AWS 상태 조회" status_data; } # 조회 명령에도 공통 단계 간격을 적용한다.
