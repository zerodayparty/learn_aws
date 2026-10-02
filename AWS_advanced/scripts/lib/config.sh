#!/usr/bin/env bash
validate_config() { # 명령별로 필요한 설정만 검사한다.
    local command="$1" name # 명령과 설정 이름을 준비한다.
    for name in PROJECT LAB_ID EXPECTED_ACCOUNT_ID AWS_REGION AWS_PROFILE; do # 모든 AWS 명령의 필수 설정이다.
        [[ -n "${!name:-}" ]] || { error "필수 설정 누락: $name"; return 2; } # 없는 설정은 임의로 채우지 않는다.
    done # 필수 설정 확인을 끝낸다.
    [[ "$PROJECT" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]{0,39}$ && "$LAB_ID" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]{0,39}$ ]] || { error 'PROJECT/LAB_ID는 영문·숫자·밑줄·하이픈, 최대 40자'; return 2; } # 경로와 Tag에 안전한 값만 허용한다.
    [[ "$EXPECTED_ACCOUNT_ID" =~ ^[0-9]{12}$ && "$AWS_REGION" == ap-northeast-2 ]] || { error '계정 형식 또는 서울 리전 설정 오류'; return 2; } # 계정과 리전을 제한한다.
    [[ "$AWS_PROFILE" =~ ^[a-zA-Z0-9_-]+$ ]] || { error '프로필 이름 형식 오류'; return 2; } # 임의의 프로필 해석을 막는다.
    if [[ "$command" == up ]]; then # 생성 명령에만 추가 설정을 요구한다.
        for name in VPC_CIDR SUBNET_CIDR SSH_ALLOWED_CIDR INSTANCE_TYPE AMI_ID; do # 서버와 네트워크 설정을 확인한다.
            [[ -n "${!name:-}" ]] || { error "필수 설정 누락: $name"; return 2; } # 누락 시 AWS 호출 전에 중단한다.
        done # 생성 설정 확인을 끝낸다.
        python3 "$APP_ROOT/scripts/lib/validate.py" || return 2 # CIDR과 인스턴스 선택을 검사한다.
    fi # 생성 전용 검사를 끝낸다.
    RUNTIME_DIR="${RUNTIME_DIR:-/app/runtime}" # 실행 기록 저장 경로를 정한다.
    SCOPE="$EXPECTED_ACCOUNT_ID/$AWS_REGION/$PROJECT/$LAB_ID" # 실습 소유 범위를 경로로 구분한다.
    STATE_DIR="$RUNTIME_DIR/state/$SCOPE" # 같은 실습의 상태와 잠금 경로다.
    KEY_DIR="$RUNTIME_DIR/keys/$SCOPE" # 다른 실습의 키와 섞이지 않게 한다.
    mkdir -p "$STATE_DIR" "$KEY_DIR" || { error 'runtime 폴더 쓰기 권한 확인 필요'; return 2; } # 영구 저장 경로를 준비한다.
    chmod 700 "$STATE_DIR" "$KEY_DIR" || return 2 # 다른 사용자 접근을 제한한다.
    KEY_NAME="$PROJECT-$LAB_ID" # AWS Key Pair 이름을 일정하게 정한다.
} # 설정 검사를 끝낸다.
