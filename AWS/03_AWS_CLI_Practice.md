# 🟩 AWS CLI로 과제 전체 수행하기 3  

#### ⚫️ 들어가기 전 이해하기  






<br><br>

## 🟢 9단계: 현재 내 Public IP 확인  

> ⚠️ 이 명령어는 컴퓨터가 달라지면 다시 해야한다.  

<br>

### 🟡 여러 줄 명령  

```bash
# AWS IP 확인 서비스에서 현재 Mac의 Public IPv4를 받아 /32 형식으로 저장한다.  
# https://checkip.amazonaws.com  =  단순히 IP 확인 서비스를 제공하는 서버의 위치다.  
# 실행한 컴퓨터의 외부 Public IP를 가져온다.  
# Mac → 공유기 → 인터넷 통신사(ISP) → AWS의 checkip.amazonaws.com  
# "이 요청은 123.123.123.123에서 왔네" 라고 알게되는 것이다.  
MY_IP="$(  
    curl --fail --silent --show-error https://checkip.amazonaws.com \  
        | tr -d '\n'  
)/32"  


# SSH 규칙에 사용할 주소를 확인한다.  
printf 'MY_IP=%s\n' "$MY_IP"  
```



<br>

### 🟡 한 줄 명령  

```bash
# AWS IP 확인 서비스에서 현재 Mac의 Public IPv4를 받아 /32 형식으로 저장한다.  
MY_IP="$(curl --fail --silent --show-error https://checkip.amazonaws.com | tr -d '\n')/32"  

# SSH 규칙에 사용할 주소를 확인한다.  
printf 'MY_IP=%s\n' "$MY_IP"  
```

<br>

### 🟡 명령 의미  

| 명령·옵션 | 의미 |  
| :--- | :--- |
| `curl` | Client URL, URL에 HTTP 요청 전송 |  
| `--fail` | HTTP 오류를 성공으로 처리하지 않음 |  
| `--silent` | 진행률 숨김 |  
| `--show-error` | 실패 이유 표시 |  
| `tr -d '\n'` | 결과 끝의 줄바꿈 제거 |  
| `/32` | IPv4 주소 하나만 허용하는 CIDR 범위 |  

결과가 `/32`뿐이거나 이상한 주소면 다음 단계로 넘어가지 않는다.  









<br><br><br>

## 🟢 10단계: Security Group과 최소 포트 생성  


<br>

### 🟡 여러 줄 명령  

```bash
# 프로젝트 VPC에 Security Group을 만들고 ID를 저장한다.  
SG_ID="$(  
    aws ec2 create-security-group \  
        --group-name "${PROJECT}-sg" \  
        --description "HTTP from internet and SSH from my IP" \  
        --vpc-id "$VPC_ID" \  
        --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${PROJECT}-sg},{Key=Project,Value=${PROJECT}}]" \  
        --query 'GroupId' \  
        --output text \  
        --profile "$PROFILE" \  
        --region "$REGION"  
)"  

# SSH 22번 Port를 현재 내 Public IP 하나에만 허용한다.  
aws ec2 authorize-security-group-ingress \  
    --group-id "$SG_ID" \  
    --protocol tcp \  
    --port 22 \  
    --cidr "$MY_IP" \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# HTTP 80번 Port를 모든 IPv4 사용자에게 허용한다.  
aws ec2 authorize-security-group-ingress \  
    --group-id "$SG_ID" \  
    --protocol tcp \  
    --port 80 \  
    --cidr 0.0.0.0/0 \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# 실제 Inbound 규칙을 확인한다.  
aws ec2 describe-security-group-rules \  
    --filters "Name=group-id,Values=$SG_ID" \  
    --query 'SecurityGroupRules[?IsEgress==`false`].[IpProtocol,FromPort,ToPort,CidrIpv4]' \  
    --output table \  
    --profile "$PROFILE" \  
    --region "$REGION"  
```

<br>

### 🟡 한 줄 명령  

```bash
# 프로젝트 VPC에 Security Group을 만들고 ID를 저장한다.  
SG_ID="$(aws ec2 create-security-group --group-name "${PROJECT}-sg" --description "HTTP from internet and SSH from my IP" --vpc-id "$VPC_ID" --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${PROJECT}-sg},{Key=Project,Value=${PROJECT}}]" --query 'GroupId' --output text --profile "$PROFILE" --region "$REGION")"  


# IP 재확인  
printf 'MY_IP=%s\n' "$MY_IP"  


# SSH 22번 Port를 현재 내 Public IP 하나에만 허용한다.  
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 22 --cidr "$MY_IP" --profile "$PROFILE" --region "$REGION"  


# IP 재확인  
printf 'MY_IP=%s\n' "$MY_IP"  



# HTTP 80번 Port를 모든 IPv4 사용자에게 허용한다.  
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0 --profile "$PROFILE" --region "$REGION"  

# 실제 Inbound 규칙을 확인한다.  
aws ec2 describe-security-group-rules --filters "Name=group-id,Values=$SG_ID" --query 'SecurityGroupRules[?IsEgress==`false`].[IpProtocol,FromPort,ToPort,CidrIpv4]' --output table --profile "$PROFILE" --region "$REGION"  
```

<br>

### 🟡 명령 의미  

| 명령·옵션 | 의미 |  
| :--- | :--- |
| `create-security-group` | EC2 앞의 가상 방화벽 생성 |  
| `authorize-security-group-ingress` | 외부에서 들어오는 통신 허용 |  
| `--protocol tcp` | TCP 통신 지정 |  
| `--port 22` | SSH Port 지정 |  
| `--port 80` | HTTP Port 지정 |  
| `--cidr` | 허용할 출발지 IPv4 범위 지정 |  
| `IsEgress==false` | 나가는 규칙이 아닌 들어오는 규칙만 선택 |  

- 표에는 `22 → 내 IP/32`, `80 → 0.0.0.0/0`만 있어야 한다.  

- CIDR: Classless Inter-Domain Routing  
    - 쉽게 말하면 IP 주소 범위를 /숫자 형태로 표현하는 방식이다.  
        - 0.0.0.0/0  
            - `/0` 이 부분이다.  







<br><br><br>

## 🟢 11단계: SSH Key Pair 안전하게 생성  

Private Key는 프로젝트 폴더가 아니라 `$HOME/.ssh/learn-aws`에 저장한다.  


<br>

### 🟡 여러 줄 명령  

```bash
#  
echo $KEY_DIR  

# Private Key 전용 폴더를 만든다.  
mkdir -p "$KEY_DIR"  

# 같은 경로에 기존 파일이 없는지 검사한다.  
test ! -e "$KEY_FILE"  

# 앞으로 생성할 파일을 현재 사용자만 읽고 쓰도록 기본 권한을 제한한다.  
# 현재 셸에만 적용되는 것임  
umask 077  

# AWS Key Pair를 만들고 Private Key를 파일에 저장한다.  
aws ec2 create-key-pair \  
    --key-name "$KEY_NAME" \  
    --key-type ed25519 \  
    --key-format pem \  
    --tag-specifications "ResourceType=key-pair,Tags=[{Key=Name,Value=${KEY_NAME}},{Key=Project,Value=${PROJECT}}]" \  
    --query 'KeyMaterial' \  
    --output text \  
    --profile "$PROFILE" \  
    --region "$REGION" \  
    > "$KEY_FILE"  

# SSH가 허용하는 수준으로 Private Key 권한을 고정한다.  
chmod 400 "$KEY_FILE"  

# 파일 내용은 출력하지 않고 존재, 크기, 권한만 확인한다.  
ls -l "$KEY_FILE"  
```

<br>

### 🟡 한 줄 명령  

```bash
#  
echo $KEY_DIR  

# Private Key 전용 폴더를 만든다.  
mkdir -p "$KEY_DIR"  

# 같은 경로에 기존 파일이 없는지 검사한다.  
test ! -e "$KEY_FILE"  

# 앞으로 생성할 파일을 현재 사용자만 읽고 쓰도록 기본 권한을 제한한다.  
# 현재 셸에만 적용되는 것임  
umask 077  

# AWS Key Pair를 만들고 Private Key를 파일에 저장한다.  
aws ec2 create-key-pair --key-name "$KEY_NAME" --key-type ed25519 --key-format pem --tag-specifications "ResourceType=key-pair,Tags=[{Key=Name,Value=${KEY_NAME}},{Key=Project,Value=${PROJECT}}]" --query 'KeyMaterial' --output text --profile "$PROFILE" --region "$REGION" > "$KEY_FILE" && chmod 400 "$KEY_FILE" && ls -l "$KEY_FILE"  
```

<br>

### 🟡 명령 의미  

| 명령·기호 | 의미 |  
| :--- | :--- |
| `mkdir -p` | 필요한 상위 폴더까지 생성 |  
| `test ! -e` | 같은 파일이 존재하지 않는지 검사 |  
| `umask 077` | 새 파일의 기본 권한 제한 |  
| `create-key-pair` | AWS에 Public Key를 등록하고 Private Key를 한 번 반환 |  
| `--key-type ed25519` | Ed25519 SSH Key 생성 |  
| `--key-format pem` | PEM 형식으로 반환 |  
| `>` | 명령 출력을 파일에 저장 |  
| `chmod 400` | 소유자에게 읽기 권한만 부여 |  
| `&&` | 앞 명령이 성공해야 다음 명령 실행 |  

- `cat "$KEY_FILE"`은 절대 실행하지 않는다.  
- `ls -l`에서 파일 크기가 0이면 생성 실패이므로 EC2를 만들기 전에 멈춘다.  









<br><br><br>

## 🟢 12단계: Ubuntu AMI와 Instance Type 확인  

#### ⚫️ Ubuntu AMI  
- **EC2에 설치할 운영체제 이미지**  
- 쉽게 말하면 **“Ubuntu가 미리 설치된 서버용 설치본”**  
- EC2를 만들 때 어떤 OS로 시작할지 정하는 것  
- 예:  
    - Ubuntu 22.04  
    - Ubuntu 24.04  
    - Amazon Linux  


#### ⚫️ Instance Type  
- **EC2 서버의 하드웨어 성능 크기**  
- CPU, 메모리, 네트워크 성능 등을 결정  
- 쉽게 말하면 **“서버 사양”**  
- 예:  
    - `t3.micro`  
    - `t3.small`  
    - `m7i.large`  

<br>

> AMI ID는 시점과 Region에 따라 달라지므로 고정값을 복사하지 않는다.  


<br>

### 🟡 여러 줄 명령  

```bash
# Canonical 공식 계정의 최신 Ubuntu 24.04 LTS x86_64 AMI ID를 저장한다.  
AMI_ID="$(  
    aws ec2 describe-images \  
        --owners 099720109477 \  
        --filters \  
            'Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*' \  
            'Name=state,Values=available' \  
            'Name=architecture,Values=x86_64' \  
            'Name=root-device-type,Values=ebs' \  
        --query 'reverse(sort_by(Images,&CreationDate))[0].ImageId' \  
        --output text \  
        --profile "$PROFILE" \  
        --region "$REGION"  
)"  

# AMI의 실제 이름, 생성일, Architecture, Root Device를 확인한다.  
aws ec2 describe-images \  
    --image-ids "$AMI_ID" \  
    --query 'Images[0].[ImageId,Name,CreationDate,Architecture,RootDeviceName]' \  
    --output table \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# 선택한 AZ에서 t3.micro를 제공하는지 확인한다.  
aws ec2 describe-instance-type-offerings \  
    --location-type availability-zone \  
    --filters "Name=location,Values=$AZ" "Name=instance-type,Values=$INSTANCE_TYPE" \  
    --query 'InstanceTypeOfferings[].[Location,InstanceType]' \  
    --output table \  
    --profile "$PROFILE" \  
    --region "$REGION"  
```

<br>

### 🟡 한 줄 명령  

```bash
# Canonical 공식 계정의 최신 Ubuntu 24.04 LTS x86_64 AMI ID를 저장한다.  
AMI_ID="$(aws ec2 describe-images --owners 099720109477 --filters 'Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*' 'Name=state,Values=available' 'Name=architecture,Values=x86_64' 'Name=root-device-type,Values=ebs' --query 'reverse(sort_by(Images,&CreationDate))[0].ImageId' --output text --profile "$PROFILE" --region "$REGION")"  

# AMI의 실제 이름, 생성일, Architecture, Root Device를 확인한다.  
aws ec2 describe-images --image-ids "$AMI_ID" --query 'Images[0].[ImageId,Name,CreationDate,Architecture,RootDeviceName]' --output table --profile "$PROFILE" --region "$REGION"  

# 선택한 AZ에서 t3.micro를 제공하는지 확인한다.  
aws ec2 describe-instance-type-offerings --location-type availability-zone --filters "Name=location,Values=$AZ" "Name=instance-type,Values=$INSTANCE_TYPE" --query 'InstanceTypeOfferings[].[Location,InstanceType]' --output table --profile "$PROFILE" --region "$REGION"  
```

<br>

### 🟡 명령 의미  

| 명령·표현 | 의미 |  
| :--- | :--- |
| `describe-images` | AMI 조회 |  
| `--owners 099720109477` | Canonical 공식 AWS 계정의 Image만 선택 |  
| `sort_by` | 생성일 기준 정렬 |  
| `reverse(...)[0]` | 가장 최신 항목 선택 |  
| `describe-instance-type-offerings` | 특정 AZ의 Instance Type 제공 여부 확인 |  

Instance Type 제공 여부와 무료 사용 여부는 다르다. 본인 계정의 Free Tier와 Credit 조건을 별도로 확인한다.  









<br><br><br>

## 🟢 13단계: EC2 한 대 생성  

<br>

### 🟡 여러 줄 명령  

```bash
# Ubuntu AMI의 Root Device 이름을 저장한다.  
ROOT_DEVICE_NAME="$(  
    aws ec2 describe-images \  
        --image-ids "$AMI_ID" \  
        --query 'Images[0].RootDeviceName' \  
        --output text \  
        --profile "$PROFILE" \  
        --region "$REGION"  
)"  

# Public Subnet에 Ubuntu EC2 한 대를 만들고 Instance ID를 저장한다.  
INSTANCE_ID="$(  
    aws ec2 run-instances \  
        --image-id "$AMI_ID" \  
        --instance-type "$INSTANCE_TYPE" \  
        --count 1 \  
        --subnet-id "$SUBNET_ID" \  
        --security-group-ids "$SG_ID" \  
        --key-name "$KEY_NAME" \  
        --associate-public-ip-address \  
        --credit-specification CpuCredits=standard \  
        --metadata-options HttpTokens=required,HttpEndpoint=enabled \  
        --block-device-mappings "DeviceName=${ROOT_DEVICE_NAME},Ebs={VolumeSize=8,VolumeType=gp3,DeleteOnTermination=true,Encrypted=true}" \  
        --tag-specifications \  
            "ResourceType=instance,Tags=[{Key=Name,Value=${PROJECT}-ec2},{Key=Project,Value=${PROJECT}}]" \  
            "ResourceType=volume,Tags=[{Key=Name,Value=${PROJECT}-ebs},{Key=Project,Value=${PROJECT}}]" \  
        --query 'Instances[0].InstanceId' \  
        --output text \  
        --profile "$PROFILE" \  
        --region "$REGION"  
)"  

# EC2가 running 상태가 될 때까지 기다린다.  
aws ec2 wait instance-running \  
    --instance-ids "$INSTANCE_ID" \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# AWS 상태 검사 두 개가 통과할 때까지 기다린다.  
aws ec2 wait instance-status-ok \  
    --instance-ids "$INSTANCE_ID" \  
    --profile "$PROFILE" \  
    --region "$REGION"  
```

<br>

### 🟡 한 줄 명령  

```bash
# Ubuntu AMI의 Root Device 이름을 저장한다.  
ROOT_DEVICE_NAME="$(aws ec2 describe-images --image-ids "$AMI_ID" --query 'Images[0].RootDeviceName' --output text --profile "$PROFILE" --region "$REGION")"  

# Public Subnet에 Ubuntu EC2 한 대를 만들고 Instance ID를 저장한다.  
INSTANCE_ID="$(aws ec2 run-instances --image-id "$AMI_ID" --instance-type "$INSTANCE_TYPE" --count 1 --subnet-id "$SUBNET_ID" --security-group-ids "$SG_ID" --key-name "$KEY_NAME" --associate-public-ip-address --credit-specification CpuCredits=standard --metadata-options HttpTokens=required,HttpEndpoint=enabled --block-device-mappings "DeviceName=${ROOT_DEVICE_NAME},Ebs={VolumeSize=8,VolumeType=gp3,DeleteOnTermination=true,Encrypted=true}" --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${PROJECT}-ec2},{Key=Project,Value=${PROJECT}}]" "ResourceType=volume,Tags=[{Key=Name,Value=${PROJECT}-ebs},{Key=Project,Value=${PROJECT}}]" --query 'Instances[0].InstanceId' --output text --profile "$PROFILE" --region "$REGION")"  

# EC2가 running 상태가 될 때까지 기다린다.  
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --profile "$PROFILE" --region "$REGION"  

# AWS 상태 검사 두 개가 통과할 때까지 기다린다.  
aws ec2 wait instance-status-ok --instance-ids "$INSTANCE_ID" --profile "$PROFILE" --region "$REGION"  
```

<br>

### 🟡 명령 의미  

| 명령·옵션 | 의미 |  
| :--- | :--- |
| `run-instances` | 새 EC2 실행 |  
| `--count 1` | 정확히 한 대 생성 |  
| `--associate-public-ip-address` | Public IPv4 요청 |  
| `CpuCredits=standard` | T3 CPU Credit 추가 과금 위험 제한 |  
| `HttpTokens=required` | IMDSv2 Token 필수 설정 |  
| `--block-device-mappings` | Root EBS 크기·종류·암호화·삭제 설정 |  
| `DeleteOnTermination=true` | EC2 종료 시 Root EBS도 삭제 |  
| `wait instance-running` | running 상태까지 대기 |  
| `wait instance-status-ok` | AWS 상태 검사 통과까지 대기 |  


<br>

### 🟡 ec2를 지금 만들고 run 시킨 상태이면 돈이 계속 나가니???  

| EC2 상태 | 인스턴스 사용료 |  
|---|---:|
| `running` | ✅ 과금 |  
| `stopped` | ❌ EC2 사용료 없음 |  
| `terminated` | ❌ EC2 사용료 없음 |  

#### ⚫️ (예시) 중지하기  
aws ec2 describe-instances \  
  --query "Reservations[].Instances[].{ID:InstanceId,State:State.Name,Name:Tags[?Key=='Name']|[0].Value}" \  
  --output table \  
  --region ap-northeast-2  


#### ⚫️ (예시) 중단 확인하기  
aws ec2 describe-instances \  
  --instance-ids i-0123456789abcdef0 \  
  --query "Reservations[0].Instances[0].State.Name" \  
  --output text \  
  --region ap-northeast-2  








<br><br><br>

## 🟢 14단계: EC2, Public IP, EBS 확인  

<br>

### 🟡 여러 줄 명령  

```bash
# EC2의 상태와 주소를 확인한다.  
aws ec2 describe-instances \  
    --instance-ids "$INSTANCE_ID" \  
    --query 'Reservations[0].Instances[0].[InstanceId,State.Name,InstanceType,PrivateIpAddress,PublicIpAddress,SubnetId,VpcId]' \  
    --output table \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# EC2 Public IPv4를 저장한다.  
PUBLIC_IP="$(  
    aws ec2 describe-instances \  
        --instance-ids "$INSTANCE_ID" \  
        --query 'Reservations[0].Instances[0].PublicIpAddress' \  
        --output text \  
        --profile "$PROFILE" \  
        --region "$REGION"  
)"  

# Root EBS Volume ID를 저장한다.  
VOLUME_ID="$(  
    aws ec2 describe-instances \  
        --instance-ids "$INSTANCE_ID" \  
        --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId' \  
        --output text \  
        --profile "$PROFILE" \  
        --region "$REGION"  
)"  

# EBS의 상태, 크기, 종류, 암호화를 확인한다.  
aws ec2 describe-volumes \  
    --volume-ids "$VOLUME_ID" \  
    --query 'Volumes[0].[VolumeId,State,Size,VolumeType,Encrypted]' \  
    --output table \  
    --profile "$PROFILE" \  
    --region "$REGION"  
```

<br>

### 🟡 한 줄 명령  

```bash
# EC2의 상태와 주소를 확인한다.  
aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].[InstanceId,State.Name,InstanceType,PrivateIpAddress,PublicIpAddress,SubnetId,VpcId]' --output table --profile "$PROFILE" --region "$REGION"  

# EC2 Public IPv4를 저장한다.  
PUBLIC_IP="$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text --profile "$PROFILE" --region "$REGION")"  

# Root EBS Volume ID를 저장한다.  
VOLUME_ID="$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId' --output text --profile "$PROFILE" --region "$REGION")"  

# EBS의 상태, 크기, 종류, 암호화를 확인한다.  
aws ec2 describe-volumes --volume-ids "$VOLUME_ID" --query 'Volumes[0].[VolumeId,State,Size,VolumeType,Encrypted]' --output table --profile "$PROFILE" --region "$REGION"  
```

<br>

### 🟡 명령 의미  

| 명령·필드 | 의미 |  
| :--- | :--- |
| `describe-instances` | EC2 설정과 상태 조회 |  
| `PublicIpAddress` | 외부에서 접근할 Public IPv4 |  
| `PrivateIpAddress` | VPC 내부 사설 IPv4 |  
| `BlockDeviceMappings` | EC2와 연결된 저장장치 정보 |  
| `describe-volumes` | EBS 정보 조회 |  

`PUBLIC_IP`가 `None`이면 SSH를 시도하지 않는다.  













