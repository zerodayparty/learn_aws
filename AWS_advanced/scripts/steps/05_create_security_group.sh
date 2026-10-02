#!/usr/bin/env bash
ensure_security_group() { # 최소 접근 규칙을 준비한다.
    local expected actual # 기대 규칙과 실제 규칙을 준비한다.
    assert_existing "$SG_JSON" || return $? # 기존 생성 설정을 확인한다.
    if [[ -z "$SG_ID" ]]; then # 보안그룹이 없는 경우다.
        create_resource SG create-security-group "$(with_tags security-group "$(jq -cn --arg v "$VPC_ID" --arg n "$PROJECT-$LAB_ID" '{VpcId:$v,GroupName:$n,Description:"aws-lab HTTP and restricted SSH"}')")" || return $? # 전용 보안그룹을 생성한다.
        inventory || return $? # 현재 상태를 다시 읽는다.
    fi # 생성 분기를 끝낸다.
    [[ -n "$SG_ID" ]] || { error 'Security Group 조회 실패'; return 3; } # ID 없이는 진행하지 않는다.
    expected=$(jq -cn --arg c "$SSH_ALLOWED_CIDR" '[{IpProtocol:"tcp",FromPort:22,ToPort:22,IpRanges:[{CidrIp:$c}]},{IpProtocol:"tcp",FromPort:80,ToPort:80,IpRanges:[{CidrIp:"0.0.0.0/0"}]}]') # SSH 개인 IP와 HTTP만 허용한다.
    actual=$(jq -c '.[0].IpPermissions' <<<"$SG_JSON") # 실제 인바운드 규칙을 읽는다.
    if [[ "$(jq length <<<"$actual")" == 0 ]]; then # 규칙이 아직 없는 경우다.
        aws_api ec2 authorize-security-group-ingress --group-id "$SG_ID" --ip-permissions "$expected" >/dev/null || return $? # 두 규칙을 등록한다.
    else # 기존 규칙은 안전성을 엄격히 확인한다.
        jq -e --arg c "$SSH_ALLOWED_CIDR" 'length==2 and all(.[]; .IpProtocol=="tcp" and .FromPort==.ToPort and (.FromPort==22 or .FromPort==80) and (.Ipv6Ranges // [] | length)==0 and (.UserIdGroupPairs // [] | length)==0 and (.PrefixListIds // [] | length)==0 and (.IpRanges | length)==1 and .IpRanges[0].CidrIp==(if .FromPort==22 then $c else "0.0.0.0/0" end)) and ([.[].FromPort] | sort)==[22,80]' <<<"$actual" >/dev/null || { error '기존 Security Group 규칙 불일치'; return 3; } # 넓은 규칙을 그대로 재사용하지 않는다.
    fi # 인바운드 설정을 끝낸다.
} # 보안그룹 준비를 끝낸다.
