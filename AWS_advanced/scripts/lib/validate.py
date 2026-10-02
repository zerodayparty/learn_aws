import ipaddress  # IPv4 네트워크 범위를 계산한다.
import os  # 환경 설정만 읽고 파일의 비밀정보를 출력하지 않는다.
import re  # 이미지 ID의 형식을 확인한다.
import sys  # 실패 종료 코드를 전달한다.
try:  # 잘못된 입력은 안내로 변환한다.
    vpc = ipaddress.IPv4Network(os.environ['VPC_CIDR'], strict=True)  # VPC 주소를 검사한다.
    subnet = ipaddress.IPv4Network(os.environ['SUBNET_CIDR'], strict=True)  # Subnet 주소를 검사한다.
    ssh = ipaddress.IPv4Network(os.environ['SSH_ALLOWED_CIDR'], strict=True)  # SSH 허용 범위를 검사한다.
    assert 16 <= vpc.prefixlen <= 28 and 16 <= subnet.prefixlen <= 28  # AWS 네트워크 크기를 제한한다.
    assert subnet.subnet_of(vpc) and ssh.prefixlen == 32  # Subnet 포함 관계와 개인 IP 제한을 확인한다.
    assert not ssh.network_address.is_unspecified and not ssh.network_address.is_multicast  # 전체·멀티캐스트 주소를 막는다.
    assert os.environ['INSTANCE_TYPE'] in ('t2.micro', 't3.micro', 't4g.micro')  # 실습 서버의 크기를 제한한다.
    assert re.fullmatch(r'ami-[0-9a-f]{8,17}', os.environ['AMI_ID'])  # AMI ID 형식을 확인한다.
except (ValueError, KeyError, AssertionError):  # 입력 오류를 한 곳에서 처리한다.
    print('❌ [ERROR] CIDR·SSH /32·micro 인스턴스·AMI 설정 확인 필요', file=sys.stderr)  # 민감한 입력값은 출력하지 않는다.
    sys.exit(2)  # AWS 호출 전에 실패한다.
