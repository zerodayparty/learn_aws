#!/usr/bin/env bash
ensure_route() { # 인터넷 방향 경로와 서브넷 연결을 준비한다.
    local route association # 기존 경로와 연결 상태를 확인한다.
    assert_existing "$ROUTE_JSON" || return $? # 재사용 설정을 확인한다.
    if [[ -z "$ROUTE_ID" ]]; then create_resource ROUTE create-route-table "$(with_tags route-table "$(jq -cn --arg v "$VPC_ID" '{VpcId:$v}')")" || return $?; inventory || return $?; fi # 전용 경로표를 준비한다.
    [[ -n "$ROUTE_ID" ]] || { error 'Route Table 생성 후 조회 실패'; return 3; } # 없는 대상으로 호출하지 않는다.
    assert_topology || return $? # VPC와 기본 경로표 보호를 확인한다.
    route=$(jq -r '.[0].Routes[] | select(.DestinationCidrBlock=="0.0.0.0/0") | .GatewayId' <<<"$ROUTE_JSON") # 인터넷 기본 경로를 찾는다.
    if [[ -z "$route" ]]; then # 아직 인터넷 경로가 없다.
        aws_api ec2 create-route --route-table-id "$ROUTE_ID" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID" >/dev/null || return $? # 인터넷 방향을 연결한다.
    elif [[ "$route" != "$IGW_ID" ]]; then error '기존 기본 경로 대상 불일치'; return 3; fi # 다른 경로를 자동 교체하지 않는다.
    jq -e --arg s "$SUBNET_ID" 'all(.[0].Associations[]?; .SubnetId==$s)' <<<"$ROUTE_JSON" >/dev/null || { error '경로표에 다른 Subnet 연결 발견'; return 3; } # 무관한 연결을 보호한다.
    association=$(jq -r --arg s "$SUBNET_ID" '.[0].Associations[]? | select(.SubnetId==$s) | .RouteTableAssociationId' <<<"$ROUTE_JSON") # 실습 연결 존재를 확인한다.
    if [[ -z "$association" ]]; then aws_api ec2 associate-route-table --route-table-id "$ROUTE_ID" --subnet-id "$SUBNET_ID" >/dev/null || return $?; fi # 연결이 없을 때만 추가한다.
} # 인터넷 경로 준비를 끝낸다.
