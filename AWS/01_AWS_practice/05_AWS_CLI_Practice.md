# 🟩 AWS CLI로 과제 전체 수행하기 5  


<br><br>

## 🟢 21단계: 실습 리소스 삭제  

삭제 전에 증빙을 모두 저장한다. 변수값이 이 프로젝트 리소스인지 다시 확인한다.  

<br>

### 🟡 EC2 종료와 EBS 확인  

#### ⚫️ 여러 줄 명령  

```bash
# EC2를 영구 종료한다.  
aws ec2 terminate-instances \  
    --instance-ids "$INSTANCE_ID" \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# EC2가 terminated 상태가 될 때까지 기다린다.  
aws ec2 wait instance-terminated \  
    --instance-ids "$INSTANCE_ID" \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# Project Tag가 붙은 EBS가 남았는지 확인한다.  
aws ec2 describe-volumes \  
    --filters "Name=tag:Project,Values=$PROJECT" \  
    --query 'Volumes[].[VolumeId,State,Size]' \  
    --output table \  
    --profile "$PROFILE" \  
    --region "$REGION"  
```

#### ⚫️ 한 줄 명령  

```bash
# EC2를 영구 종료한다.  
aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" --profile "$PROFILE" --region "$REGION"  

# EC2가 terminated 상태가 될 때까지 기다린다.  
aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID" --profile "$PROFILE" --region "$REGION"  

# Project Tag가 붙은 EBS가 남았는지 확인한다.  
aws ec2 describe-volumes --filters "Name=tag:Project,Values=$PROJECT" --query 'Volumes[].[VolumeId,State,Size]' --output table --profile "$PROFILE" --region "$REGION"  
```

EBS가 `available`로 남았다면 정확한 ID를 확인한 뒤에만 실행한다.  

```bash
# 남은 프로젝트 EBS 하나를 영구 삭제한다.  
aws ec2 delete-volume --volume-id <확인한_PROJECT_VOLUME_ID> --profile "$PROFILE" --region "$REGION"  
```








<br>

### 🟡 나머지 리소스 삭제  

#### ⚫️ 여러 줄 명령  

```bash
# 종료된 EC2가 사용하던 Security Group을 삭제한다.  
aws ec2 delete-security-group \  
    --group-id "$SG_ID" \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# Public Subnet과 Route Table의 연결을 해제한다.  
aws ec2 disassociate-route-table \  
    --association-id "$RT_ASSOC_ID" \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# Internet Gateway로 향하는 기본 경로를 삭제한다.  
aws ec2 delete-route \  
    --route-table-id "$RT_ID" \  
    --destination-cidr-block 0.0.0.0/0 \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# 사용자 정의 Route Table을 삭제한다.  
aws ec2 delete-route-table \  
    --route-table-id "$RT_ID" \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# Internet Gateway를 VPC에서 분리한다.  
aws ec2 detach-internet-gateway \  
    --internet-gateway-id "$IGW_ID" \  
    --vpc-id "$VPC_ID" \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# 분리된 Internet Gateway를 삭제한다.  
aws ec2 delete-internet-gateway \  
    --internet-gateway-id "$IGW_ID" \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# Public Subnet을 삭제한다.  
aws ec2 delete-subnet \  
    --subnet-id "$SUBNET_ID" \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# AWS에 등록된 Public Key 정보를 삭제한다.  
aws ec2 delete-key-pair \  
    --key-name "$KEY_NAME" \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# 마지막으로 프로젝트 VPC를 삭제한다.  
aws ec2 delete-vpc \  
    --vpc-id "$VPC_ID" \  
    --profile "$PROFILE" \  
    --region "$REGION"  
```

#### ⚫️ 한 줄 명령  

```bash
# 종료된 EC2가 사용하던 Security Group을 삭제한다.  
aws ec2 delete-security-group --group-id "$SG_ID" --profile "$PROFILE" --region "$REGION"  

# Public Subnet과 Route Table의 연결을 해제한다.  
aws ec2 disassociate-route-table --association-id "$RT_ASSOC_ID" --profile "$PROFILE" --region "$REGION"  

# Internet Gateway로 향하는 기본 경로를 삭제한다.  
aws ec2 delete-route --route-table-id "$RT_ID" --destination-cidr-block 0.0.0.0/0 --profile "$PROFILE" --region "$REGION"  

# 사용자 정의 Route Table을 삭제한다.  
aws ec2 delete-route-table --route-table-id "$RT_ID" --profile "$PROFILE" --region "$REGION"  

# Internet Gateway를 VPC에서 분리한다.  
aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" --profile "$PROFILE" --region "$REGION"  

# 분리된 Internet Gateway를 삭제한다.  
aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID" --profile "$PROFILE" --region "$REGION"  

# Public Subnet을 삭제한다.  
aws ec2 delete-subnet --subnet-id "$SUBNET_ID" --profile "$PROFILE" --region "$REGION"  

# AWS에 등록된 Public Key 정보를 삭제한다.  
aws ec2 delete-key-pair --key-name "$KEY_NAME" --profile "$PROFILE" --region "$REGION"  

# 마지막으로 프로젝트 VPC를 삭제한다.  
aws ec2 delete-vpc --vpc-id "$VPC_ID" --profile "$PROFILE" --region "$REGION"  
```

Mac의 Private Key는 AWS 리소스 삭제를 확인한 후 정확한 경로를 보고 삭제한다.  

```bash
# 삭제 대상이 프로젝트 전용 Private Key인지 확인한다.  
ls -l "$KEY_FILE"  

# 확인한 프로젝트 전용 Private Key 파일 하나만 삭제한다.  
rm -- "$KEY_FILE"  
```

<br>

### 🟡 삭제 명령 의미  

| 명령 | 의미 |  
| :--- | :--- |
| `terminate-instances` | EC2 영구 종료 |  
| `wait instance-terminated` | 종료 완료까지 대기 |  
| `delete-volume` | 남은 EBS 영구 삭제 |  
| `delete-security-group` | 사용자 정의 Security Group 삭제 |  
| `disassociate-route-table` | Subnet 연결 해제 |  
| `delete-route` | IGW 기본 경로 삭제 |  
| `delete-route-table` | 사용자 정의 Route Table 삭제 |  
| `detach-internet-gateway` | IGW를 VPC에서 분리 |  
| `delete-internet-gateway` | IGW 삭제 |  
| `delete-subnet` | Subnet 삭제 |  
| `delete-key-pair` | AWS의 Public Key 정보 삭제 |  
| `delete-vpc` | VPC 삭제 |  
| `rm --` | 정확히 지정한 로컬 파일 삭제 |  



















<br><br><br>

## 🟢 22단계: 삭제 최종 검증  

<br>

### 🟡 여러 줄 명령  

```bash
# Project Tag를 가진 VPC가 남았는지 확인한다.  
aws ec2 describe-vpcs \  
    --filters "Name=tag:Project,Values=$PROJECT" \  
    --query 'Vpcs[].[VpcId,State]' \  
    --output table \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# Project Tag를 가진 Subnet이 남았는지 확인한다.  
aws ec2 describe-subnets \  
    --filters "Name=tag:Project,Values=$PROJECT" \  
    --query 'Subnets[].[SubnetId,State]' \  
    --output table \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# Project Tag를 가진 IGW가 남았는지 확인한다.  
aws ec2 describe-internet-gateways \  
    --filters "Name=tag:Project,Values=$PROJECT" \  
    --query 'InternetGateways[].[InternetGatewayId,Attachments]' \  
    --output table \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# Project Tag를 가진 EBS가 남았는지 확인한다.  
aws ec2 describe-volumes \  
    --filters "Name=tag:Project,Values=$PROJECT" \  
    --query 'Volumes[].[VolumeId,State,Size]' \  
    --output table \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# 계정의 Elastic IP를 조회해 이 실습에서 만든 것이 없음을 확인한다.  
aws ec2 describe-addresses \  
    --query 'Addresses[].[AllocationId,AssociationId,PublicIp]' \  
    --output table \  
    --profile "$PROFILE" \  
    --region "$REGION"  
```

<br>

### 🟡 한 줄 명령  

```bash
# Project Tag를 가진 VPC가 남았는지 확인한다.  
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=$PROJECT" --query 'Vpcs[].[VpcId,State]' --output table --profile "$PROFILE" --region "$REGION"  

# Project Tag를 가진 Subnet이 남았는지 확인한다.  
aws ec2 describe-subnets --filters "Name=tag:Project,Values=$PROJECT" --query 'Subnets[].[SubnetId,State]' --output table --profile "$PROFILE" --region "$REGION"  

# Project Tag를 가진 IGW가 남았는지 확인한다.  
aws ec2 describe-internet-gateways --filters "Name=tag:Project,Values=$PROJECT" --query 'InternetGateways[].[InternetGatewayId,Attachments]' --output table --profile "$PROFILE" --region "$REGION"  

# Project Tag를 가진 EBS가 남았는지 확인한다.  
aws ec2 describe-volumes --filters "Name=tag:Project,Values=$PROJECT" --query 'Volumes[].[VolumeId,State,Size]' --output table --profile "$PROFILE" --region "$REGION"  

# 계정의 Elastic IP를 조회해 이 실습에서 만든 것이 없음을 확인한다.  
aws ec2 describe-addresses --query 'Addresses[].[AllocationId,AssociationId,PublicIp]' --output table --profile "$PROFILE" --region "$REGION"  
```

다른 프로젝트의 Elastic IP가 보여도 삭제하면 안 된다. 이 과제에서는 Elastic IP를 만들지 않았으므로 체크리스트에 `미생성`이라고 기록한다.  

<br>

### 🟡 최종 검증 명령 의미  

| 명령 | 빈 결과가 뜻하는 것 |  
| :--- | :--- |
| `describe-vpcs` | Project VPC 삭제 완료 |  
| `describe-subnets` | Project Subnet 삭제 완료 |  
| `describe-internet-gateways` | Project IGW 삭제 완료 |  
| `describe-volumes` | Project EBS 삭제 완료 |  
| `describe-addresses` | 전체 EIP 목록 확인. 다른 프로젝트 주소는 삭제 금지 |  






















<br><br><br>

## 🟢 AWS CLI 공통 문법 사전  

| 문법·옵션 | 의미 |  
| :--- | :--- |
| `\` | 명령이 다음 줄까지 이어진다는 표시. 뒤에 공백 금지 |  
| `"$VARIABLE"` | 변수값을 안전하게 하나의 값으로 사용 |  
| `$(...)` | 안쪽 명령의 출력값을 사용 |  
| `--query` | 필요한 응답 필드만 선택 |  
| `--output text` | 변수 저장에 적합한 문자열 출력 |  
| `--output table` | 사람이 읽기 쉬운 표 출력 |  
| `--output json` | 구조를 보존한 JSON 출력 |  
| `--filters` | 조건에 맞는 리소스 검색 |  
| `create-*` | 새 리소스 생성 |  
| `describe-*` | 리소스 조회 |  
| `modify-*` | 설정 변경 |  
| `associate-*` | 리소스 연결 |  
| `disassociate-*` | 연결 해제 |  
| `attach-*` | 부착 |  
| `detach-*` | 부착 해제 |  
| `delete-*` | 리소스 삭제 |  
| `authorize-*` | 접근 허용 규칙 추가 |  
| `wait` | 원하는 상태까지 반복 확인 |  













<br><br><br>

## 🟢 완료 기준  

- 현재 인증 주체가 Root가 아닌 IAM 사용자 또는 Role이다.  
- 모든 AWS 명령에 Profile과 서울 Region이 명시되어 있다.  
- VPC `10.0.0.0/16` 안에 Subnet `10.0.1.0/24`가 있다.  
- Route Table에 `0.0.0.0/0 → IGW`가 있다.  
- SSH 22는 내 IP `/32`, HTTP 80은 `0.0.0.0/0`만 허용한다.  
- 내부와 외부 `/health`가 모두 `200 OK`, `OK`를 반환한다.  
- 실제 장애의 증상, 가설, 검증, 조치, 결과, 재발 방지를 기록한다.  
- 삭제 후 Project Tag 기준 VPC, Subnet, IGW, EBS가 남지 않는다.  
- Elastic IP는 만들지 않았으므로 `미생성`으로 기록한다.  









<br><br><br>

## 🟢 공식 참고자료  

- [AWS CLI로 VPC 생성](https://docs.aws.amazon.com/vpc/latest/userguide/create-vpc.html)  
- [AWS CLI run-instances](https://docs.aws.amazon.com/cli/latest/reference/ec2/run-instances.html)  
- [EC2 Key Pair 생성](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html)  
- [EC2 종료 주의사항](https://docs.aws.amazon.com/cli/latest/reference/ec2/terminate-instances.html)  
