#!/usr/bin/env bash
install_nginx() { # 원격 Ubuntu에 웹 서비스를 설치한다.
    [[ -t 0 ]] || { error '최초 호스트 키 확인을 위해 대화형 터미널에서 up 실행 필요'; return 2; } # 첫 신뢰 확인을 자동 승인하지 않는다.
    prepare_ssh ask || return $? # 처음에는 Fingerprint 확인 질문을 허용한다.
    info 'SSH Fingerprint를 AWS 콘솔의 서버 호스트 키와 대조한 뒤 승인해' # 최초 신뢰 확인 근거를 안내한다.
    ssh_command 'bash -s' <"$APP_ROOT/scripts/steps/nginx_remote.sh" || { error 'Nginx 설치 또는 SSH 실패'; return 1; } # 설치 Script의 성공만 인정한다.
} # 웹 설치를 끝낸다.
