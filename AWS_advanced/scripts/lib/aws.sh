#!/usr/bin/env bash
aws_api() { # AWS 호출을 한 곳에서 통제한다.
    local rc errfile # 결과와 비공개 오류 파일을 준비한다.
    errfile=$(mktemp) || return 1 # 인증 오류 원문을 화면에 남기지 않는다.
    aws --profile "$AWS_PROFILE" --region "$AWS_REGION" --no-cli-pager --cli-connect-timeout 5 --cli-read-timeout 30 "$@" 2>"$errfile"; rc=$? # 지정 계정 설정만 사용한다.
    if (( rc != 0 )); then error "AWS $1 ${2:-} 실패 (exit=$rc). 권한·인증·네트워크를 확인해"; fi # 원문 대신 작업과 코드를 안내한다.
    rm -f "$errfile" # 오류 원문을 즉시 지운다.
    return "$rc" # AWS 실패를 그대로 전달한다.
} # AWS 호출 함수를 끝낸다.
authenticate() { # 프로필과 실제 계정을 검증한다.
    local identity # 인증 응답을 잠시 보관한다.
    [[ -r "${AWS_CONFIG_FILE:-}" && -r "${AWS_SHARED_CREDENTIALS_FILE:-}" ]] || { error '실습 전용 config/credentials 파일 준비 필요'; return 2; } # 호스트 인증에 우연히 의존하지 않는다.
    python3 "$APP_ROOT/scripts/lib/profile.py" || return 2 # 외부 프로세스·Role 인증을 차단한다.
    unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_SECURITY_TOKEN AWS_WEB_IDENTITY_TOKEN_FILE AWS_ROLE_ARN AWS_ENDPOINT_URL AWS_ENDPOINT_URL_EC2 AWS_ENDPOINT_URL_STS # 다른 인증과 외부 endpoint의 개입을 막는다.
    export AWS_EC2_METADATA_DISABLED=true AWS_PAGER='' AWS_MAX_ATTEMPTS=1 AWS_IGNORE_CONFIGURED_ENDPOINT_URLS=true # 인증 fallback과 불명확한 자동 재시도를 막는다.
    identity=$(aws_api sts get-caller-identity --output json) || return $? # 읽기 전용으로 현재 인증 대상을 확인한다.
    [[ "$(jq -r '.Account' <<<"$identity")" == "$EXPECTED_ACCOUNT_ID" ]] || { error '예상 AWS 계정과 인증 계정이 다름'; return 2; } # 잘못된 계정 변경을 막는다.
    [[ "$(jq -r '.Arn' <<<"$identity")" != *:root ]] || { error '루트 계정 사용 금지'; return 2; } # 과제의 IAM 기준을 지킨다.
    info "인증 계정 ********${EXPECTED_ACCOUNT_ID: -4}, Region=$AWS_REGION, Project=$PROJECT, Lab=$LAB_ID" # 인증값은 표시하지 않는다.
} # 인증 확인을 끝낸다.
wait_ec2() { # AWS waiter의 종료 코드와 제한된 대기를 사용한다.
    aws_api ec2 wait "$1" --instance-ids "$INSTANCE_ID" # instance-running/status-ok/terminated를 기다린다.
} # 대기를 끝낸다.
