#!/usr/bin/env bash
check_environment() { # 도구와 생성 대상의 호환성을 확인한다.
    local image types arch # 이미지와 CPU 종류를 준비한다.
    inventory || return $? # 생성 전에 현재 상태를 조회한다.
    if compgen -G "$STATE_DIR/*.pending" >/dev/null; then error "불명확한 생성 기록 존재. README 복구 절차 확인 필요"; return 3; fi # 미해결 요청이 있으면 변경을 시작하지 않는다.
    configuration_hash # 재실행 비교용 설정 지문을 만든다.
    assert_topology || return $? # 현재 리소스 연결을 확인한다.
    image=$(aws_api ec2 describe-images --image-ids "$AMI_ID" --output json) || return $? # 서버 운영체제를 확인한다.
    jq -e '.Images | length==1 and .[0].State=="available" and .[0].OwnerId=="099720109477" and (.[0].Name | startswith("ubuntu/images/")) and .[0].RootDeviceType=="ebs"' <<<"$image" >/dev/null || { error 'Canonical Ubuntu EBS AMI 확인 실패'; return 2; } # Ubuntu 발행자와 이미지 종류를 제한한다.
    ROOT_DEVICE=$(jq -r '.Images[0].RootDeviceName' <<<"$image") # 루트 디스크 연결 이름을 읽는다.
    jq -e 'all(.Images[0].BlockDeviceMappings[]; .Ebs == null or .Ebs.VolumeSize<=10)' <<<"$image" >/dev/null || { error 'AMI 디스크가 과제 크기 10GiB를 초과함'; return 2; } # 자동 디스크 증설을 방지한다.
    arch=$(jq -r '.Images[0].Architecture' <<<"$image") # EC2 이미지 CPU 종류를 읽는다.
    types=$(aws_api ec2 describe-instance-types --instance-types "$INSTANCE_TYPE" --output json) || return $? # 인스턴스 CPU 종류를 조회한다.
    jq -e --arg a "$arch" '.InstanceTypes[0].ProcessorInfo.SupportedArchitectures | index($a)!=null' <<<"$types" >/dev/null || { error 'AMI와 인스턴스 CPU 아키텍처 불일치'; return 2; } # 호스트 CPU와 EC2 CPU를 혼동하지 않는다.
} # 생성 사전 확인을 끝낸다.
