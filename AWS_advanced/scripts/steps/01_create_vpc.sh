#!/usr/bin/env bash
ensure_vpc() { # VPC를 생성하거나 현재 설정을 검사한다.
    assert_existing "$VPC_JSON" || return $? # 기존 설정 지문을 확인한다.
    if [[ -z "$VPC_ID" ]]; then # 없을 때만 생성한다.
        create_resource VPC create-vpc "$(with_tags vpc "$(jq -cn --arg c "$VPC_CIDR" '{CidrBlock:$c}')")" || return $? # 생성 요청에 Tag를 포함한다.
        inventory || return $? # 실제 생성 결과를 다시 조회한다.
    fi # 생성 분기를 끝낸다.
    [[ -n "$VPC_ID" ]] || { error 'VPC 생성 후 조회 실패'; return 3; } # 조회되지 않으면 진행하지 않는다.
    jq -e --arg c "$VPC_CIDR" '.[0].CidrBlock==$c' <<<"$VPC_JSON" >/dev/null || { error '기존 VPC CIDR 불일치'; return 3; } # 실제 설정도 비교한다.
    aws_api ec2 wait vpc-available --vpc-ids "$VPC_ID" || return $? # 네트워크 준비가 완료된 뒤 다음 작업을 진행한다.
    aws_api ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-support '{"Value":true}' >/dev/null || return $? # 서버 DNS 조회를 허용한다.
} # VPC 준비를 끝낸다.
