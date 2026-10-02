#!/usr/bin/env bash
inventory() { # Tag로 실습에 속한 리소스를 현재 AWS에서 조회한다.
    local kind operation field data # 리소스 종류와 조회 응답을 준비한다.
    for kind in VPC SUBNET IGW ROUTE SG KEY INSTANCE VOLUME ADDRESS; do # 생성과 정리 대상 전체를 확인한다.
        case "$kind" in # 종류별 AWS 조회와 응답 배열을 연결한다.
            VPC) operation=describe-vpcs; field=Vpcs ;; # 네트워크를 조회한다.
            SUBNET) operation=describe-subnets; field=Subnets ;; # 서브넷을 조회한다.
            IGW) operation=describe-internet-gateways; field=InternetGateways ;; # 인터넷 통로를 조회한다.
            ROUTE) operation=describe-route-tables; field=RouteTables ;; # 경로표를 조회한다.
            SG) operation=describe-security-groups; field=SecurityGroups ;; # 접근 규칙을 조회한다.
            KEY) operation=describe-key-pairs; field=KeyPairs ;; # SSH 키 등록을 조회한다.
            INSTANCE) operation=describe-instances; field=Reservations ;; # 서버를 조회한다.
            VOLUME) operation=describe-volumes; field=Volumes ;; # 남은 디스크를 조회한다.
            ADDRESS) operation=describe-addresses; field=Addresses ;; # 고정 IP 잔여분을 조회한다.
        esac # 종류 연결을 끝낸다.
        data=$(aws_api ec2 "$operation" --filters "Name=tag:Project,Values=$PROJECT" "Name=tag:LabId,Values=$LAB_ID" 'Name=tag:ManagedBy,Values=aws-lab' --output json) || return $? # 소유 범위를 제한해서 조회한다.
        if [[ "$kind" == INSTANCE ]]; then data=$(jq -ce '[.Reservations[].Instances[] | select(.State.Name != "terminated")]' <<<"$data") || return 2; else data=$(jq -ce --arg field "$field" '.[$field] | arrays' <<<"$data") || return 2; fi # 현재 대상 배열로 통일한다.
        jq -e --arg p "$PROJECT" --arg l "$LAB_ID" 'all(.[]; any(.Tags[]?; .Key=="Project" and .Value==$p) and any(.Tags[]?; .Key=="LabId" and .Value==$l) and any(.Tags[]?; .Key=="ManagedBy" and .Value=="aws-lab"))' <<<"$data" >/dev/null || { error '조회 응답의 소유 Tag 불일치'; return 2; } # 삭제 전 서버 필터 결과도 다시 검증한다.
        if [[ "$kind" != VOLUME && "$kind" != ADDRESS && "$(jq length <<<"$data")" -gt 1 ]]; then error "$kind 대상 중복. 첫 결과를 임의로 선택하지 않음"; return 3; fi # 핵심 리소스 충돌을 막는다.
        printf -v "${kind}_JSON" '%s' "$data" # 조회 결과를 종류별로 보관한다.
    done # 전체 조회를 끝낸다.
    VPC_ID=$(jq -r '.[0].VpcId // empty' <<<"$VPC_JSON") # VPC ID만 추출한다.
    SUBNET_ID=$(jq -r '.[0].SubnetId // empty' <<<"$SUBNET_JSON") # 서브넷 ID만 추출한다.
    IGW_ID=$(jq -r '.[0].InternetGatewayId // empty' <<<"$IGW_JSON") # 통로 ID만 추출한다.
    ROUTE_ID=$(jq -r '.[0].RouteTableId // empty' <<<"$ROUTE_JSON") # 경로표 ID만 추출한다.
    SG_ID=$(jq -r '.[0].GroupId // empty' <<<"$SG_JSON") # 보안그룹 ID만 추출한다.
    INSTANCE_ID=$(jq -r '.[0].InstanceId // empty' <<<"$INSTANCE_JSON") # 서버 ID만 추출한다.
    PUBLIC_IP=$(jq -r '.[0].PublicIpAddress // empty' <<<"$INSTANCE_JSON") # 접속용 IP만 추출한다.
} # 현재 리소스 조회를 끝낸다.
show_inventory() { # 인증정보 없이 사람이 읽는 상태표를 만든다.
    printf '%-15s %-24s %s\n' RESOURCE ID STATE # 상태표 제목을 표시한다.
    printf '%-15s %-24s %s\n' VPC "${VPC_ID:-미생성}" "$(jq -r '.[0].State // "-"' <<<"$VPC_JSON")" # 네트워크 상태를 표시한다.
    printf '%-15s %-24s %s\n' SUBNET "${SUBNET_ID:-미생성}" "$(jq -r '.[0].State // "-"' <<<"$SUBNET_JSON")" # 서브넷 상태를 표시한다.
    printf '%-15s %-24s %s\n' IGW "${IGW_ID:-미생성}" "$(jq -r '.[0].Attachments[0].State // "-"' <<<"$IGW_JSON")" # 연결 상태를 표시한다.
    printf '%-15s %-24s\n' ROUTE "${ROUTE_ID:-미생성}" # 경로표 식별값을 표시한다.
    printf '%-15s %-24s\n' SECURITY_GROUP "${SG_ID:-미생성}" # 보안그룹 식별값을 표시한다.
    printf '%-15s %-24s %s\n' EC2 "${INSTANCE_ID:-미생성}" "$(jq -r '.[0].State.Name // "-"' <<<"$INSTANCE_JSON")" # 서버 상태를 표시한다.
    printf '%-15s %-24s\n' PUBLIC_IP "${PUBLIC_IP:--}" # 웹·SSH 대상 IP를 표시한다.
    jq -r '.[0].Routes[]? | select(.DestinationCidrBlock=="0.0.0.0/0") | "DEFAULT_ROUTE \(.DestinationCidrBlock) -> \(.GatewayId) \(.State)"' <<<"$ROUTE_JSON" # 인터넷 경로와 실제 상태를 표시한다.
    jq -r '.[0].IpPermissions[]? | "INBOUND \(.IpProtocol) \(.FromPort)-\(.ToPort) \([.IpRanges[]?.CidrIp] | join(","))"' <<<"$SG_JSON" # 실제 SSH·HTTP 소스 범위를 표시한다.
    printf 'EBS=%s, ElasticIP=%s\n' "$(jq length <<<"$VOLUME_JSON")" "$(jq length <<<"$ADDRESS_JSON")" # 과금 잔여 대상을 표시한다.
    info 'Nginx와 HTTP 응답은 health 명령으로 별도 확인' # 조회만으로 웹 성공을 주장하지 않는다.
} # 상태표 출력을 끝낸다.
configuration_hash() { # 재실행 설정이 같은지 비교할 지문을 만든다.
    CONFIG_HASH=$(printf '%s\n' "$VPC_CIDR" "$SUBNET_CIDR" "$SSH_ALLOWED_CIDR" "$INSTANCE_TYPE" "$AMI_ID" | sha256sum | cut -d ' ' -f 1) # 비밀값 없이 생성 설정만 요약한다.
} # 설정 지문 계산을 끝낸다.
tags_json() { # AWS Tag 목록을 안전한 JSON으로 만든다.
    jq -cn --arg p "$PROJECT" --arg l "$LAB_ID" --arg h "$CONFIG_HASH" '[{Key:"Project",Value:$p},{Key:"LabId",Value:$l},{Key:"ManagedBy",Value:"aws-lab"},{Key:"ConfigHash",Value:$h}]' # Shell 문자열을 JSON 값으로 안전하게 변환한다.
} # Tag 생성을 끝낸다.
assert_existing() { # 존재하는 리소스를 재사용하기 전에 설정을 확인한다.
    local data="$1" # 비교할 리소스 배열이다.
    [[ "$(jq length <<<"$data")" == 0 ]] && return 0 # 아직 없는 리소스는 생성할 수 있다.
    jq -e --arg h "$CONFIG_HASH" 'all(.[]; any(.Tags[]?; .Key=="ConfigHash" and .Value==$h))' <<<"$data" >/dev/null || { error '기존 리소스의 생성 설정 지문 불일치. 자동 교체하지 않음'; return 3; } # 다른 설정의 리소스를 덮어쓰지 않는다.
} # 재사용 검사를 끝낸다.
create_resource() { # 생성 요청을 기록하고 AWS에 전달한다.
    local kind="$1" operation="$2" payload="$3" response # 생성 종류와 JSON을 받는다.
    [[ ! -f "$STATE_DIR/$kind.pending" ]] || { error "$kind 생성 결과 불명확. 조회·정리 후 복구 필요"; return 3; } # 불명확한 요청을 반복하지 않는다.
    printf '%s\n' "$operation" >"$STATE_DIR/$kind.pending" || return 2 # 요청 직전 재실행 방지 기록을 남긴다.
    response=$(aws_api ec2 "$operation" --cli-input-json "$payload" --output json) || { warn '생성 성공 여부를 단정할 수 없음. status로 확인하고 README 복구 절차를 따라'; return 1; } # 실패 응답도 무조건 재생성하지 않는다.
    jq '. + {SchemaVersion:1}' <<<"$response" >"$STATE_DIR/$kind.json.tmp" && mv "$STATE_DIR/$kind.json.tmp" "$STATE_DIR/$kind.json" || return 2 # 완성된 상태만 교체한다.
    rm -f "$STATE_DIR/$kind.pending" # 성공 응답을 저장했으므로 잠정 상태를 해제한다.
} # 일반 리소스 생성을 끝낸다.
with_tags() { # 리소스 종류에 맞는 생성 Tag를 붙인다.
    jq -c --arg kind "$1" --argjson tags "$(tags_json)" '. + {TagSpecifications:[{ResourceType:$kind,Tags:$tags}]}' <<<"$2" # 생성 시점에 실습 범위를 표시한다.
} # 생성 Tag 조합을 끝낸다.
assert_topology() { # 다른 VPC의 리소스가 연결되지 않았는지 확인한다.
    local data # VPC를 가진 리소스를 확인한다.
    jq -e 'all(.[]; .IsDefault!=true)' <<<"$VPC_JSON" >/dev/null || { error "기본 VPC 변경·삭제 금지"; return 3; } # 기본 네트워크는 소유 Tag가 있어도 보호한다.
    jq -e 'all(.[]; .DefaultForAz!=true)' <<<"$SUBNET_JSON" >/dev/null || { error "기본 Subnet 변경·삭제 금지"; return 3; } # 기본 서브넷을 보호한다.
    jq -e 'all(.[]; .GroupName!="default")' <<<"$SG_JSON" >/dev/null || { error "기본 Security Group 변경·삭제 금지"; return 3; } # 기본 접근 규칙을 보호한다.
    for data in "$SUBNET_JSON" "$ROUTE_JSON" "$SG_JSON" "$INSTANCE_JSON"; do # 네트워크와 서버를 검사한다.
        jq -e --arg v "$VPC_ID" 'all(.[]; .VpcId==$v)' <<<"$data" >/dev/null || { error '리소스 VPC 연결 불일치'; return 3; } # 다른 네트워크는 변경하지 않는다.
    done # 네트워크 검사를 끝낸다.
    jq -e --arg v "$VPC_ID" 'all(.[].Attachments[]?; .VpcId==$v)' <<<"$IGW_JSON" >/dev/null || { error 'IGW가 다른 VPC에 연결됨'; return 3; } # 타 실습 연결 해제를 막는다.
    jq -e 'all(.[].Associations[]?; .Main != true)' <<<"$ROUTE_JSON" >/dev/null || { error '기본 Route Table 변경·삭제 금지'; return 3; } # 기본 경로표를 보호한다.
    jq -e --arg s "$SUBNET_ID" 'all(.[].Associations[]?; .SubnetId==$s)' <<<"$ROUTE_JSON" >/dev/null || { error "다른 Subnet의 Route Table 연결 발견"; return 3; } # 삭제 전에 다른 실습 연결을 차단한다.
    jq -e --arg s "$SUBNET_ID" --arg g "$SG_ID" 'all(.[]; .SubnetId==$s and (.SecurityGroups | map(.GroupId))==[$g])' <<<"$INSTANCE_JSON" >/dev/null || { error "EC2의 Subnet 또는 Security Group 연결 불일치"; return 3; } # 다른 서버 연결을 변경하지 않는다.
} # 연결 관계 검사를 끝낸다.
