#!/usr/bin/env bash
cleanup_resources() { # 확인한 실습 리소스만 의존관계 순서로 정리한다.
    local id association data # 삭제 대상과 연결 관계를 준비한다.
    inventory && assert_topology || return $? # 삭제 직전 실제 상태를 다시 확인한다.
    if [[ -n "$INSTANCE_ID" ]]; then # 남아 있는 서버를 정리한다.
        aws_api ec2 terminate-instances --instance-ids "$INSTANCE_ID" >/dev/null && wait_ec2 instance-terminated || return $? # 종료 완료를 기다린다.
    fi # 서버 종료를 끝낸다.
    inventory || return $? # 자동 삭제된 디스크를 반영한다.
    while IFS= read -r data; do # 실습 Tag가 있는 잔여 디스크만 확인한다.
        [[ -n "$data" ]] || continue # 빈 입력을 건너뛴다.
        jq -e '.State=="available" and (.Attachments | length)==0' <<<"$data" >/dev/null || { error '연결 중이거나 준비되지 않은 잔여 EBS. 자동 삭제 중단'; return 3; } # 타 서버 연결 디스크를 보호한다.
        id=$(jq -r '.VolumeId' <<<"$data") # 안전 검사 후 ID를 추출한다.
        aws_api ec2 delete-volume --volume-id "$id" >/dev/null || return $? # 잔여 디스크를 삭제한다.
    done < <(jq -c '.[]' <<<"$VOLUME_JSON") # 현재 조회한 목록만 사용한다.
    while IFS= read -r data; do # 할당된 실습 고정 IP를 확인한다.
        [[ -n "$data" ]] || continue # 빈 입력을 건너뛴다.
        jq -e '.AssociationId==null and .AllocationId!=null' <<<"$data" >/dev/null || { error '연결된 Elastic IP 발견. 자동 해제하지 않음'; return 3; } # 타 연결을 해제하지 않는다.
        aws_api ec2 release-address --allocation-id "$(jq -r '.AllocationId' <<<"$data")" >/dev/null || return $? # 연결되지 않은 실습 고정 IP를 반환한다.
    done < <(jq -c '.[]' <<<"$ADDRESS_JSON") # 소유 Tag가 확인된 목록이다.
    if [[ "$(jq length <<<"$KEY_JSON")" != 0 ]]; then aws_api ec2 delete-key-pair --key-pair-id "$(jq -r '.[0].KeyPairId' <<<"$KEY_JSON")" >/dev/null || return $?; fi # AWS 등록 키만 삭제하고 로컬 개인키는 보존한다.
    if [[ -n "$SG_ID" ]]; then aws_api ec2 delete-security-group --group-id "$SG_ID" >/dev/null || return $?; fi # 서버가 해제된 뒤 접근 규칙을 삭제한다.
    if [[ -n "$ROUTE_ID" ]]; then # 전용 경로표를 정리한다.
        jq -e --arg s "$SUBNET_ID" 'all(.[0].Associations[]?; .Main!=true and .SubnetId==$s)' <<<"$ROUTE_JSON" >/dev/null || { error '기본 경로표 또는 다른 Subnet 연결. 삭제 중단'; return 3; } # 무관한 경로 연결을 보호한다.
        while IFS= read -r association; do # 실습 Subnet 연결만 해제한다.
            [[ -n "$association" ]] || continue # 빈 입력을 건너뛴다.
            aws_api ec2 disassociate-route-table --association-id "$association" >/dev/null || return $? # 경로표 연결을 해제한다.
        done < <(jq -r '.[0].Associations[]?.RouteTableAssociationId' <<<"$ROUTE_JSON") # 확인한 연결 목록이다.
        aws_api ec2 delete-route-table --route-table-id "$ROUTE_ID" >/dev/null || return $? # 전용 경로표를 삭제한다.
    fi # 경로표 정리를 끝낸다.
    if [[ -n "$IGW_ID" ]]; then # 인터넷 통로를 정리한다.
        if [[ "$(jq '.[0].Attachments | length' <<<"$IGW_JSON")" != 0 ]]; then aws_api ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" >/dev/null || return $?; fi # 실습 VPC 연결만 해제한다.
        aws_api ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID" >/dev/null || return $? # 통로를 삭제한다.
    fi # 통로 정리를 끝낸다.
    if [[ -n "$SUBNET_ID" ]]; then aws_api ec2 delete-subnet --subnet-id "$SUBNET_ID" >/dev/null || return $?; fi # 서브넷을 삭제한다.
    if [[ -n "$VPC_ID" ]]; then aws_api ec2 delete-vpc --vpc-id "$VPC_ID" >/dev/null || return $?; fi # 마지막에 네트워크를 삭제한다.
    inventory || return $? # 정리 후 관리 대상을 다시 확인한다.
    for data in "$VPC_JSON" "$SUBNET_JSON" "$IGW_JSON" "$ROUTE_JSON" "$SG_JSON" "$KEY_JSON" "$INSTANCE_JSON" "$VOLUME_JSON" "$ADDRESS_JSON"; do # 잔여 종류 전체를 검사한다.
        [[ "$(jq length <<<"$data")" == 0 ]] || { error '관리 대상 잔여 리소스 존재'; return 3; } # 남아 있으면 완료라고 하지 않는다.
    done # 잔여 확인을 끝낸다.
    rm -f "$STATE_DIR/"*.pending # 조회로 정리 완료를 확인한 뒤 잠정 생성 기록을 해제한다.
    date -u '+%Y-%m-%dT%H:%M:%SZ' >"$STATE_DIR/cleanup-completed" # 정리 완료 시각을 증거로 기록한다.
    info '관리 대상 AWS 정리 확인 완료. 로컬 키는 보존됨. Billing은 별도 확인 필요' # 비용 반영 시점과 구분한다.
} # 리소스 정리를 끝낸다.
