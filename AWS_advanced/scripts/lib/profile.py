import configparser  # AWS 프로필 파일의 항목을 읽는다.
import os  # 지정된 파일 위치와 프로필을 읽는다.
import sys  # 잘못된 프로필은 실패로 종료한다.
try:  # 비밀정보를 포함하는 예외 원문은 출력하지 않는다.
    config = configparser.RawConfigParser()  # 문자열 변수 치환을 사용하지 않는다.
    config.read(os.environ['AWS_CONFIG_FILE'])  # 지정한 설정 파일만 읽는다.
    credentials = configparser.RawConfigParser()  # 인증 파일도 별도로 읽는다.
    credentials.read(os.environ['AWS_SHARED_CREDENTIALS_FILE'])  # 실습 전용 인증만 사용한다.
    profile = os.environ['AWS_PROFILE']  # 사용할 프로필 이름이다.
    section = 'default' if profile == 'default' else 'profile ' + profile  # AWS 설정의 section 이름이다.
    assert credentials.has_section(profile) and config.has_section(section)  # 두 파일의 프로필 존재를 확인한다.
    assert credentials.get(profile, 'aws_access_key_id') and credentials.get(profile, 'aws_secret_access_key')  # 필요한 인증값의 존재만 확인한다.
    forbidden = {'credential_process', 'role_arn', 'source_profile', 'credential_source', 'web_identity_token_file'}  # 첫 구현에서 지원하지 않는 인증이다.
    assert not forbidden.intersection(config[section])  # 외부 명령과 Role 전환을 막는다.
    assert not any(key.startswith('sso_') for key in config[section])  # SSO는 별도 지원 전까지 중단한다.
except Exception:  # 입력 오류 원문에는 비밀값이 있을 수 있다.
    print('❌ [ERROR] 실습 전용 파일 기반 프로필 설정 확인 필요', file=sys.stderr)  # 비밀값 없이 안내한다.
    sys.exit(2)  # 인증 요청 전에 중단한다.
