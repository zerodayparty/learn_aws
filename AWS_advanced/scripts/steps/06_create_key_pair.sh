#!/usr/bin/env bash
ensure_key_pair() { # 개인키를 출력하지 않고 발급·보관한다.
    local response keyfile="$KEY_DIR/$KEY_NAME.pem" # 개인키 영구 경로다.
    assert_existing "$KEY_JSON" || return $? # 기존 키 소유 설정을 확인한다.
    if [[ "$(jq length <<<"$KEY_JSON")" != 0 ]]; then # AWS 등록 키가 이미 있다.
        [[ "$(jq -r '.[0].KeyName' <<<"$KEY_JSON")" == "$KEY_NAME" && -s "$keyfile" ]] || { error 'AWS Key Pair 이름 불일치 또는 로컬 개인키 없음'; return 3; } # 복구 불가능한 키를 정상이라고 처리하지 않는다.
        return 0 # 기존 키를 재사용한다.
    fi # 기존 키 확인을 끝낸다.
    [[ ! -e "$keyfile" && ! -e "$STATE_DIR/KEY.pending" ]] || { error '키 파일 또는 불명확한 키 생성 기록 존재. 복구 필요'; return 3; } # 기존 개인키를 덮어쓰지 않는다.
    printf 'create-key-pair\n' >"$STATE_DIR/KEY.pending" || return 2 # 요청 전에 발급 기록을 남긴다.
    response=$(aws_api ec2 create-key-pair --cli-input-json "$(with_tags key-pair "$(jq -cn --arg n "$KEY_NAME" '{KeyName:$n,KeyType:"rsa",KeyFormat:"pem"}')")" --output json) || return $? # 개인키 응답은 변수에만 저장한다.
    jq -er '.KeyMaterial' <<<"$response" >"$keyfile.tmp" || return 2 # 비밀값을 화면에 표시하지 않는다.
    chmod 600 "$keyfile.tmp" && mv "$keyfile.tmp" "$keyfile" || return 2 # 제한된 권한으로 영구 저장한다.
    jq 'del(.KeyMaterial) + {SchemaVersion:1}' <<<"$response" >"$STATE_DIR/KEY.json.tmp" && mv "$STATE_DIR/KEY.json.tmp" "$STATE_DIR/KEY.json" || return 2 # 상태파일에는 개인키를 제거한다.
    rm -f "$STATE_DIR/KEY.pending" # 키 저장이 완료되어 잠정 기록을 해제한다.
    inventory # 현재 키 등록 상태를 다시 확인한다.
} # 키 준비를 끝낸다.
