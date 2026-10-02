#!/usr/bin/env bash
ensure_ec2() { # 서버와 10GiB 루트 디스크를 준비한다.
    local payload token # 생성 JSON과 재시도 식별값을 준비한다.
    assert_existing "$INSTANCE_JSON" || return $? # 기존 서버 설정을 확인한다.
    if [[ -z "$INSTANCE_ID" ]]; then # 서버가 없는 경우다.
        [[ ! -e "$STATE_DIR/INSTANCE.pending" ]] || { error 'EC2 생성 결과 불명확. 먼저 복구 필요'; return 3; } # 이전 요청을 무조건 반복하지 않는다.
        token=$(python3 -c 'import uuid; print(uuid.uuid4())') # 이번 서버 생성에 고유한 토큰을 만든다.
        printf '%s\n' "$token" >"$STATE_DIR/client-token" || return 2 # 재시도에 사용할 토큰을 저장한다.
        payload=$(jq -cn --arg ami "$AMI_ID" --arg type "$INSTANCE_TYPE" --arg sub "$SUBNET_ID" --arg sg "$SG_ID" --arg key "$KEY_NAME" --arg token "$token" --arg dev "$ROOT_DEVICE" --argjson tags "$(tags_json)" '{ImageId:$ami,InstanceType:$type,MinCount:1,MaxCount:1,KeyName:$key,ClientToken:$token,NetworkInterfaces:[{DeviceIndex:0,SubnetId:$sub,Groups:[$sg],AssociatePublicIpAddress:true}],BlockDeviceMappings:[{DeviceName:$dev,Ebs:{VolumeSize:10,VolumeType:"gp3",DeleteOnTermination:true,Encrypted:true}}],MetadataOptions:{HttpTokens:"required",HttpEndpoint:"enabled"},TagSpecifications:[{ResourceType:"instance",Tags:$tags},{ResourceType:"volume",Tags:$tags}]}') # SSH·디스크·Tag·IMDSv2 설정을 명시한다.
        create_resource INSTANCE run-instances "$payload" || return $? # 서버 생성 요청을 기록해서 실행한다.
        inventory || return $? # 현재 AWS 서버를 찾는다.
    fi # 생성 분기를 끝낸다.
    jq -e --arg ami "$AMI_ID" --arg type "$INSTANCE_TYPE" --arg sub "$SUBNET_ID" --arg sg "$SG_ID" --arg key "$KEY_NAME" 'length==1 and .[0].ImageId==$ami and .[0].InstanceType==$type and .[0].SubnetId==$sub and .[0].KeyName==$key and (.[0].SecurityGroups | map(.GroupId))==[$sg] and .[0].MetadataOptions.HttpTokens=="required"' <<<"$INSTANCE_JSON" >/dev/null || { error '기존 EC2 설정 불일치'; return 3; } # 실제 서버 설정을 비교한다.
    [[ "$(jq -r '.[0].State.Name' <<<"$INSTANCE_JSON")" != stopped ]] || { error '중지된 EC2는 자동 시작하지 않음. 별도 조치 필요'; return 3; } # 의도하지 않은 재시작을 막는다.
    wait_ec2 instance-running && wait_ec2 instance-status-ok || return $? # 준비 상태를 제한된 waiter로 확인한다.
    inventory # 접속용 Public IP를 다시 조회한다.
} # 서버 준비를 끝낸다.
