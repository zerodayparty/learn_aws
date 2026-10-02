#!/usr/bin/env python3
import json  # 가짜 AWS 응답을 만든다.
import os  # 테스트 전용 환경만 읽는다.
from pathlib import Path  # 임시 상태파일에 가짜 리소스를 저장한다.
import sys  # 인자와 종료 코드를 받는다.
args = sys.argv[1:]  # 호출된 AWS CLI 인자를 받는다.
service_index = next(i for i, value in enumerate(args) if value in ('sts', 'ec2'))  # 공통 옵션 뒤 서비스 위치를 찾는다.
service, operation = args[service_index:service_index + 2]  # 실행할 가짜 작업이다.
store = Path(os.environ['FAKE_STORE'])  # 실제 AWS와 분리된 임시 파일이다.
state = json.loads(store.read_text()) if store.exists() else {}  # 이전 가짜 상태를 읽는다.
log = Path(os.environ['FAKE_CALLS'])  # 외부 호출 대신 로컬 기록만 남긴다.
with log.open('a') as stream:  # 테스트 요청 종류를 기록한다.
    stream.write(operation + '\n')  # 비밀 입력은 기록하지 않는다.
scenario = os.environ.get('FAKE_SCENARIO', '')  # 재현할 오류 종류다.
if scenario == 'deny' and service == 'ec2':  # 권한 실패를 재현한다.
    print('DENIED_SECRET_MARKER', file=sys.stderr)  # 원문이 사용자 출력에 노출되지 않아야 한다.
    sys.exit(7)  # 호출 실패를 전달한다.
if service == 'sts':  # 계정 확인 응답이다.
    account = '999999999999' if scenario == 'wrong-account' else os.environ['EXPECTED_ACCOUNT_ID']  # 계정 불일치를 재현한다.
    print(json.dumps({'Account': account, 'Arn': 'arn:aws:iam::' + account + ':user/test'}))  # 테스트 계정만 반환한다.
    sys.exit(0)  # 인증 조회를 끝낸다.
fields = {'describe-vpcs': 'Vpcs', 'describe-subnets': 'Subnets', 'describe-internet-gateways': 'InternetGateways', 'describe-route-tables': 'RouteTables', 'describe-security-groups': 'SecurityGroups', 'describe-key-pairs': 'KeyPairs', 'describe-volumes': 'Volumes', 'describe-addresses': 'Addresses'}  # 리소스 응답 이름이다.
if operation in fields or operation == 'describe-instances':  # 목록 조회를 재현한다.
    field = fields.get(operation, 'Instances')  # 가짜 저장 배열을 찾는다.
    objects = state.get(field, [])  # 현재 리소스 목록이다.
    tags = [{'Key': 'Project', 'Value': os.environ['PROJECT']}, {'Key': 'LabId', 'Value': os.environ['LAB_ID']}, {'Key': 'ManagedBy', 'Value': 'aws-lab'}]  # 테스트 소유 Tag다.
    if scenario == 'duplicates' and field == 'Vpcs':  # 중복 네트워크를 만든다.
        objects = [{'VpcId': 'vpc-a', 'Tags': tags}, {'VpcId': 'vpc-b', 'Tags': tags}]  # 두 개를 임의 선택하면 안 된다.
    if scenario == 'foreign' and field == 'Vpcs':  # 잘못된 소유 범위를 재현한다.
        objects = [{'VpcId': 'vpc-other', 'Tags': []}]  # 다른 소유 대상이다.
    response = {'Reservations': [{'Instances': objects}]} if field == 'Instances' else {field: objects}  # AWS 배열 모양을 맞춘다.
elif operation == 'describe-images':  # Ubuntu 이미지 정보를 반환한다.
    response = {'Images': [{'State': 'available', 'OwnerId': '099720109477', 'Name': 'ubuntu/images/test', 'RootDeviceType': 'ebs', 'RootDeviceName': '/dev/sda1', 'Architecture': 'x86_64', 'BlockDeviceMappings': [{'Ebs': {'VolumeSize': 8}}]}]}  # 네트워크 요청은 없다.
elif operation == 'describe-instance-types':  # 서버 CPU 정보를 반환한다.
    response = {'InstanceTypes': [{'ProcessorInfo': {'SupportedArchitectures': ['x86_64']}}]}  # x86 Ubuntu와 호환된다.
elif '--cli-input-json' in args:  # 생성 요청을 재현한다.
    payload = json.loads(args[args.index('--cli-input-json') + 1])  # 안전한 JSON 인자를 읽는다.
    payloads = Path(os.environ['FAKE_PAYLOADS'])  # 테스트 생성 요청을 보관한다.
    payloads.mkdir(exist_ok=True)  # 가짜 입력 폴더를 만든다.
    (payloads / (operation + '.json')).write_text(json.dumps(payload))  # SDK 검증용 JSON만 남긴다.
    tags = payload['TagSpecifications'][0]['Tags']  # 생성 Tag를 그대로 보관한다.
    types = {'create-vpc': ('Vpcs', 'Vpc', {'VpcId': 'vpc-test', 'CidrBlock': payload.get('CidrBlock'), 'State': 'available'}), 'create-subnet': ('Subnets', 'Subnet', {'SubnetId': 'subnet-test', 'VpcId': payload.get('VpcId'), 'CidrBlock': payload.get('CidrBlock'), 'State': 'available'}), 'create-internet-gateway': ('InternetGateways', 'InternetGateway', {'InternetGatewayId': 'igw-test', 'Attachments': []}), 'create-route-table': ('RouteTables', 'RouteTable', {'RouteTableId': 'rtb-test', 'VpcId': payload.get('VpcId'), 'Routes': [], 'Associations': []}), 'create-security-group': ('SecurityGroups', None, {'GroupId': 'sg-test', 'VpcId': payload.get('VpcId'), 'IpPermissions': []}), 'create-key-pair': ('KeyPairs', None, {'KeyPairId': 'key-test', 'KeyName': payload.get('KeyName')})}  # 가짜 생성 응답이다.
    if operation == 'run-instances':  # 서버 생성 요청이다.
        network = payload['NetworkInterfaces'][0]  # 공개 네트워크 설정이다.
        obj = {'InstanceId': 'i-test', 'VpcId': 'vpc-test', 'SubnetId': network['SubnetId'], 'SecurityGroups': [{'GroupId': network['Groups'][0]}], 'ImageId': payload['ImageId'], 'InstanceType': payload['InstanceType'], 'KeyName': payload['KeyName'], 'MetadataOptions': payload['MetadataOptions'], 'PublicIpAddress': '192.0.2.10', 'State': {'Name': 'running'}, 'Tags': tags}  # 가짜 서버다.
        state['Instances'] = [obj]  # 서버를 저장한다.
        state['Volumes'] = [{'VolumeId': 'vol-test', 'Tags': tags, 'State': 'in-use', 'Attachments': [{'InstanceId': 'i-test'}]}]  # 자동 삭제할 가짜 디스크다.
        response = {'Instances': [obj]}  # 생성 결과를 반환한다.
    else:  # 네트워크 또는 키 생성이다.
        field, wrapper, obj = types[operation]  # 생성 종류를 연결한다.
        obj['Tags'] = tags  # 소유 정보를 저장한다.
        state[field] = [obj]  # 상태에 리소스를 추가한다.
        response = {wrapper: obj} if wrapper else dict(obj)  # AWS 응답 모양을 맞춘다.
        if operation == 'create-key-pair': response['KeyMaterial'] = 'PRIVATE_TEST_MARKER'  # 화면에 노출되면 안 되는 테스트 값이다.
    if scenario == 'timeout':  # 생성 후 응답이 끊기는 상황이다.
        store.write_text(json.dumps(state))  # 실제 생성이 된 상태를 남긴다.
        sys.exit(9)  # 사용자에게 실패 응답만 전달한다.
elif operation == 'attach-internet-gateway':  # VPC 연결을 재현한다.
    state['InternetGateways'][0]['Attachments'] = [{'VpcId': 'vpc-test', 'State': 'available'}]  # 통로 연결이다.
    response = {}  # 연결 완료 응답이다.
elif operation == 'create-route':  # 인터넷 기본 경로를 추가한다.
    state['RouteTables'][0]['Routes'] = [{'DestinationCidrBlock': '0.0.0.0/0', 'GatewayId': 'igw-test', 'State': 'active'}]  # 경로가 준비되었다.
    response = {}  # 등록 완료 응답이다.
elif operation == 'associate-route-table':  # 서브넷 연결을 추가한다.
    state['RouteTables'][0]['Associations'] = [{'RouteTableAssociationId': 'rtbassoc-test', 'SubnetId': 'subnet-test', 'Main': False}]  # 전용 연결이다.
    response = {}  # 연결 완료 응답이다.
elif operation == 'authorize-security-group-ingress':  # 인바운드 규칙을 추가한다.
    state['SecurityGroups'][0]['IpPermissions'] = json.loads(args[args.index('--ip-permissions') + 1])  # 요청된 규칙만 보관한다.
    response = {}  # 규칙 추가 완료다.
elif operation == 'terminate-instances':  # 서버 종료를 재현한다.
    state['Instances'] = []  # 살아 있는 서버가 없다.
    state['Volumes'] = []  # 루트 디스크도 자동 삭제된다.
    response = {}  # 종료 완료 응답이다.
elif operation.startswith('delete-'):  # 개별 리소스 삭제를 재현한다.
    field = {'delete-vpc': 'Vpcs', 'delete-subnet': 'Subnets', 'delete-internet-gateway': 'InternetGateways', 'delete-route-table': 'RouteTables', 'delete-security-group': 'SecurityGroups', 'delete-key-pair': 'KeyPairs', 'delete-volume': 'Volumes'}[operation]  # 삭제 종류다.
    state[field] = []  # 해당 리소스를 정리한다.
    response = {}  # 삭제 완료 응답이다.
elif operation in ('modify-vpc-attribute', 'wait', 'disassociate-route-table', 'detach-internet-gateway', 'release-address'):  # 부수 작업을 재현한다.
    response = {}  # 추가 네트워크 요청 없이 성공한다.
else:  # 구현하지 않은 요청은 성공으로 숨기지 않는다.
    raise RuntimeError('Unsupported fake operation: ' + operation)  # 테스트에서 누락된 API를 드러낸다.
store.write_text(json.dumps(state))  # 가짜 AWS 상태를 저장한다.
print(json.dumps(response))  # 테스트 JSON만 반환한다.
