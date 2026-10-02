#!/usr/bin/env bash
ensure_subnet() { # Public Subnet을 준비한다.
    assert_existing "$SUBNET_JSON" || return $? # 재실행 설정을 확인한다.
    if [[ -z "$SUBNET_ID" ]]; then # 아직 없는 경우다.
        create_resource SUBNET create-subnet "$(with_tags subnet "$(jq -cn --arg v "$VPC_ID" --arg c "$SUBNET_CIDR" '{VpcId:$v,CidrBlock:$c}')")" || return $? # VPC 안에 서브넷을 만든다.
        inventory || return $? # 생성 결과를 다시 확인한다.
    fi # 생성 분기를 끝낸다.
    jq -e --arg v "$VPC_ID" --arg c "$SUBNET_CIDR" 'length==1 and .[0].VpcId==$v and .[0].CidrBlock==$c' <<<"$SUBNET_JSON" >/dev/null || { error 'Subnet 설정 불일치'; return 3; } # 실제 연결과 주소를 확인한다.
    aws_api ec2 wait subnet-available --subnet-ids "$SUBNET_ID" # 서버 배치 전 서브넷 준비를 기다린다.
} # 서브넷 준비를 끝낸다.
