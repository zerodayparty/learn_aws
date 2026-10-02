#!/usr/bin/env bash
check_health() { # EC2 내부와 사용자 쪽에서 health 응답을 각각 검사한다.
    local result body code # 응답과 HTTP 상태를 나누어 읽는다.
    prepare_ssh yes || return $? # 이미 신뢰한 호스트 키만 사용한다.
    result=$(ssh_command "curl --silent --show-error --connect-timeout 5 --max-time 15 --write-out '\n%{http_code}' http://localhost/health") || { error '내부 health 또는 SSH 실패'; return 1; } # 내부 localhost에서 검사한다.
    code="${result##*$'\n'}"; body="${result%$'\n'*}" # HTTP 상태와 본문을 분리한다.
    while [[ "$body" == *$'\n' ]]; do body="${body%$'\n'}"; done # 끝 LF만 제거한다.
    [[ "$code" == 200 && "$body" == OK ]] || { error '내부 health 상태 또는 본문 불일치'; return 1; } # Redirect나 다른 본문을 성공으로 처리하지 않는다.
    success '내부 HTTP 200 / OK' # 내부 검사 성공을 안내한다.
    result=$(curl --silent --show-error --connect-timeout 5 --max-time 15 --write-out '\n%{http_code}' "http://$PUBLIC_IP/health") || { error '외부 health 요청 실패'; return 1; } # 컨테이너에서 Public IP로 검사한다.
    code="${result##*$'\n'}"; body="${result%$'\n'*}" # 외부 응답도 상태와 본문을 분리한다.
    while [[ "$body" == *$'\n' ]]; do body="${body%$'\n'}"; done # 끝 LF만 제거한다.
    [[ "$code" == 200 && "$body" == OK ]] || { error '외부 health 상태 또는 본문 불일치'; return 1; } # 두 조건을 모두 만족해야 성공한다.
    success '외부 HTTP 200 / OK' # 사용자 네트워크에서 확인한 결과다.
} # 웹 응답 검사를 끝낸다.
