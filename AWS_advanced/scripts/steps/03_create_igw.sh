#!/usr/bin/env bash
ensure_igw() { # 인터넷 연결 통로를 준비한다.
    assert_existing "$IGW_JSON" || return $? # 기존 설정을 확인한다.
    if [[ -z "$IGW_ID" ]]; then create_resource IGW create-internet-gateway "$(with_tags internet-gateway '{}')" || return $?; inventory || return $?; fi # 통로를 생성하고 조회한다.
    [[ -n "$IGW_ID" ]] || { error 'IGW 생성 후 조회 실패'; return 3; } # ID 없이는 진행하지 않는다.
    assert_topology || return $? # 다른 VPC에 연결된 통로는 변경하지 않는다.
    if [[ "$(jq '.[0].Attachments | length' <<<"$IGW_JSON")" == 0 ]]; then # 아직 연결이 없는 경우다.
        aws_api ec2 attach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" >/dev/null || return $? # 통로를 실습 VPC에 연결한다.
    fi # 연결 분기를 끝낸다.
} # 통로 준비를 끝낸다.
