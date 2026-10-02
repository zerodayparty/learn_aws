#!/usr/bin/env bash
command_up() { # 생성 단계를 순서대로 조합한다.
    local file # 학습 단계 파일 이름이다.
    [[ -t 0 ]] || { error "up은 최초 SSH 확인을 위해 대화형 터미널이 필요함"; return 2; } # 생성 전에 입력 가능 여부부터 확인한다.
    acquire_lock || return $? # 생성과 삭제 중복 실행을 막는다.
    for file in "$APP_ROOT"/scripts/steps/[0-9][0-9]_*.sh; do source "$file"; done # 단계 함수 정의를 읽는다.
    run_step '생성 환경 확인' check_environment || return $? # 기존 상태와 AMI를 확인한다.
    run_step 'VPC 생성' ensure_vpc || return $? # 네트워크를 준비한다.
    run_step 'Public Subnet 생성' ensure_subnet || return $? # 서브넷을 준비한다.
    run_step 'Internet Gateway 생성' ensure_igw || return $? # 인터넷 통로를 준비한다.
    run_step 'Route Table 생성' ensure_route || return $? # 경로를 준비한다.
    run_step 'Security Group 생성' ensure_security_group || return $? # 접근 규칙을 준비한다.
    run_step 'Key Pair 생성' ensure_key_pair || return $? # 접속 키를 준비한다.
    run_step 'EC2 생성' ensure_ec2 || return $? # 서버를 준비한다.
    run_step 'Nginx 설치' install_nginx || return $? # 호스트 키 확인 후 웹 서버를 준비한다.
    run_step 'Health Check' check_health # 내부와 외부 정상 응답을 확인한다.
} # 생성 조합을 끝낸다.
