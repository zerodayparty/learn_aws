#!/usr/bin/env bash
prepare_ssh() { # 컨테이너 내부에 제한된 권한의 임시 개인키를 준비한다.
    local mode="${1:-yes}" source="$KEY_DIR/$KEY_NAME.pem" # 자동 검사 또는 최초 확인 모드다.
    [[ -n "$INSTANCE_ID" && -n "$PUBLIC_IP" && -s "$source" ]] || { error 'EC2·Public IP·개인키가 필요함'; return 3; } # 없는 접속 대상을 차단한다.
    [[ "$(jq -r '.[0].State.Name' <<<"$INSTANCE_JSON")" == running ]] || { error 'EC2가 running 상태가 아님'; return 3; } # 중지·종료 서버에 접속하지 않는다.
    python3 -c 'import ipaddress,sys; ipaddress.IPv4Address(sys.argv[1])' "$PUBLIC_IP" 2>/dev/null || { error 'Public IPv4 형식 오류'; return 2; } # SSH 목적지 주입을 막는다.
    [[ -z "${SSH_TEMP:-}" ]] || rm -rf "$SSH_TEMP" # 이전 단계의 임시 개인키를 먼저 정리한다.
    SSH_TEMP=$(mktemp -d) || return 2 # Windows 호스트 파일 권한에 의존하지 않는다.
    cp "$source" "$SSH_TEMP/key.pem" && chmod 600 "$SSH_TEMP/key.pem" || return 2 # 임시 키 권한을 고정한다.
    ssh-keygen -y -f "$SSH_TEMP/key.pem" >/dev/null 2>&1 || { error '개인키 형식 오류 또는 암호화 키 미지원'; return 2; } # 잘못된 키로 무한 대기하지 않는다.
    touch "$KEY_DIR/known_hosts" && chmod 600 "$KEY_DIR/known_hosts" || return 2 # 호스트 키 신뢰 기록을 영구 저장한다.
    SSH_ARGS=(-i "$SSH_TEMP/key.pem" -o IdentitiesOnly=yes -o IdentityAgent=none -o ForwardAgent=no -o ConnectTimeout=5 -o ConnectionAttempts=1 -o ServerAliveInterval=10 -o ServerAliveCountMax=3 -o "UserKnownHostsFile=$KEY_DIR/known_hosts" -o "StrictHostKeyChecking=$mode") # 호스트 키 확인과 대기 제한을 적용한다.
    if [[ "$mode" == yes ]]; then SSH_ARGS+=(-o BatchMode=yes); fi # 자동 health에서 키 질문 대기를 막는다.
    SSH_TARGET="ubuntu@$PUBLIC_IP" # Ubuntu 사용자로만 접속한다.
} # 접속 준비를 끝낸다.
ssh_command() { # SSH 오류 원문 대신 짧은 안내를 제공한다.
    ssh "${SSH_ARGS[@]}" "$SSH_TARGET" "$@" # 원격 명령의 종료 코드를 유지한다.
} # SSH 실행을 끝낸다.
