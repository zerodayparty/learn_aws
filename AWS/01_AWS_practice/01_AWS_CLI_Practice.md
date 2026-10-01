# 🟩 AWS CLI로 과제 전체 수행하기  

`02_가입_절차.md`, `03_초기_셋팅.md`, `04_AWS_CLI_파악.md`를 완료했고 AWS CLI에 IAM 사용자를 연결한 상태에서 시작한다.  

> 이 문서는 AWS(Amazon Web Services) 리소스를 AWS CLI(Command Line Interface / 명령줄 인터페이스)로 생성하고 검증한 뒤 삭제하는 실제 실행 순서다.  


- 여러 줄 명령과 한 줄 명령은 같은 작업이다. 둘 중 하나만 실행한다.  
- 여러 줄 명령의 역슬래시(`\`) 뒤에는 공백을 넣지 않는다.  
- 짧아서 나눌 수 없는 명령은 한 번만 적는다.  
- AWS 리소스 생성·삭제는 사용자가 명령을 직접 실행할 때만 일어난다.  










<br><br><br>

## 🟢 전체 순서  

```md
# 현재 인증 주체와 Region을 확인한다.  
인증 확인  
    ↓  
# 실습에서 반복 사용할 값을 변수에 저장한다.  
변수 준비  
    ↓  
# 인터넷 연결이 가능한 네트워크를 만든다.  
VPC → Subnet → Internet Gateway → Route Table  
    ↓  
# SSH와 HTTP에 필요한 최소 포트만 허용한다.  
Security Group  
    ↓  
# SSH 비밀키와 Ubuntu EC2를 만든다.  
Key Pair → AMI → EC2  
    ↓  
# 원격 서버에 Nginx와 /health 파일을 만든다.  
SSH → Nginx  
    ↓  
# 내부와 외부에서 실제 HTTP 응답을 확인한다.  
localhost 검증 → Public IP 검증  
    ↓  
# 안전한 장애를 재현하고 복구한다.  
트러블슈팅 기록  
    ↓  
# 과금 방지를 위해 생성의 역순으로 삭제한다.  
전체 리소스 정리  
```









<br><br><br>

## 🟢 0단계: 보안과 실행 규칙  

- Root Access Key를 사용하지 않는다.  
- Access Key와 Secret Access Key를 명령에 직접 적지 않는다.  
- `.env`, `~/.aws/credentials`, `.pem` 내용을 출력하거나 Git에 넣지 않는다.  
- 모든 AWS 명령에 `--profile`과 `--region`을 명시한다.  
- 생성 오류가 나면 같은 명령을 반복하지 말고 실제 생성 여부부터 조회한다.  
- SSH 22는 현재 내 IP `/32`에만 허용한다.  
- HTTP 80만 `0.0.0.0/0`에 허용한다.  
- Elastic IP, NAT Gateway, Load Balancer, RDS는 만들지 않는다.  









<br><br><br>

## 🟢 1단계: AWS CLI 인증 확인  

### 🟡 여러 줄 명령  

```bash
# 설치된 AWS CLI 버전을 확인한다.  
aws --version  

# Mac에 저장된 AWS CLI Profile 목록을 확인한다.  
aws configure list-profiles  

# aws-basic Profile이 연결한 IAM 사용자 또는 Role을 확인한다.  
aws sts get-caller-identity \  
    --profile aws-basic \  
    --region ap-northeast-2 \  
    --output json  

# Profile에 저장된 기본 Region을 확인한다.  
aws configure get region \  
    --profile aws-basic  
```

### 🟡 한 줄 명령  

```bash
# 설치된 AWS CLI 버전을 확인한다.  
aws --version  

# Mac에 저장된 AWS CLI Profile 목록을 확인한다.  
aws configure list-profiles  

# aws-basic Profile이 연결한 IAM 사용자 또는 Role을 확인한다.  
aws sts get-caller-identity --profile aws-basic --region ap-northeast-2 --output json  

# Profile에 저장된 기본 Region을 확인한다.  
aws configure get region --profile aws-basic  
```

### 🟡 명령 의미  

| 명령·옵션 | 풀네임 | 의미 |  
| :--- | :--- | :--- |
| `aws` | Amazon Web Services CLI | AWS API를 Terminal에서 호출 |  
| `sts` | Security Token Service | 현재 인증 주체 정보 확인 |  
| `get-caller-identity` | Get Caller Identity | Account, ARN, User ID 조회 |  
| `configure list-profiles` | Configure List Profiles | 저장된 Profile 목록 조회 |  
| `--profile` | Profile | 사용할 인증 설정 지정 |  
| `--region` | Region | 요청을 보낼 AWS 지역 지정 |  
| `--output json` | JavaScript Object Notation Output | 결과를 JSON 형식으로 출력 |  

`Account`와 `Arn`을 외부에 공유할 때는 계정 ID와 사용자 이름을 가린다.  









<br><br><br>

## 🟢 2단계: 공통 변수 준비  

Profile 이름이 다르면 `PROFILE`의 값만 실제 이름으로 바꾼다.  

### 🟡 여러 줄 명령  

```bash
# 사용할 AWS CLI Profile 이름을 저장한다.  
PROFILE="aws-basic"  

# 모든 리소스를 만들 서울 Region을 저장한다.  
REGION="ap-northeast-2"  

# 리소스를 묶어 찾을 Project 이름을 저장한다.  
PROJECT="aws-basic-lab"  

# VPC의 사설 IPv4 범위를 저장한다.  
VPC_CIDR="10.0.0.0/16"  

# Public Subnet의 사설 IPv4 범위를 저장한다.  
SUBNET_CIDR="10.0.1.0/24"  

# EC2 종류를 저장한다.  
INSTANCE_TYPE="t3.micro"  

# Key Pair 이름을 저장한다.  
KEY_NAME="${PROJECT}-key"  

# Private Key를 프로젝트 밖에 보관할 Directory를 저장한다.  
KEY_DIR="$HOME/.ssh/learn-aws"  

# Private Key의 전체 파일 경로를 저장한다.  
KEY_FILE="${KEY_DIR}/${KEY_NAME}.pem"  
```

### 🟡 한 줄 명령  

```bash
# 위 변수 아홉 개를 현재 Terminal에 한 번에 저장한다.  
PROFILE="aws-basic"; REGION="ap-northeast-2"; PROJECT="aws-basic-lab"; VPC_CIDR="10.0.0.0/16"; SUBNET_CIDR="10.0.1.0/24"; INSTANCE_TYPE="t3.micro"; KEY_NAME="${PROJECT}-key"; KEY_DIR="$HOME/.ssh/learn-aws"; KEY_FILE="${KEY_DIR}/${KEY_NAME}.pem"  
```

### 🟡 변수 확인  

```bash
# 비밀값이 아닌 설정만 출력해 오타를 확인한다.  
printf 'PROFILE=%s\nREGION=%s\nPROJECT=%s\nVPC_CIDR=%s\nSUBNET_CIDR=%s\nINSTANCE_TYPE=%s\nKEY_FILE=%s\n' "$PROFILE" "$REGION" "$PROJECT" "$VPC_CIDR" "$SUBNET_CIDR" "$INSTANCE_TYPE" "$KEY_FILE"  
```

### 🟡 명령 의미  

| 문법·명령 | 의미 |  
| :--- | :--- |
| `이름="값"` | 현재 Terminal에서 사용할 Shell 변수 저장 |  
| `${PROJECT}` | 변수 값을 다른 문자열 안에서 사용 |  
| `$HOME` | 현재 Mac 사용자의 Home Directory |  
| `printf` | 지정한 형식으로 문자열 출력 |  
| `;` | 한 줄에서 다음 명령을 이어 실행 |  

새 Terminal을 열면 변수는 사라진다. 그때는 이 단계를 다시 실행한다.  









<br><br><br>

## 🟢 3단계: 중복 생성 사전 검사  

> 아래 명령어 결과에 기존 프로젝트 리소스가 나오면 새로 만들지 않는다.  

### 🟡 여러 줄 명령  

```bash
# 같은 Project Tag를 가진 VPC가 있는지 확인한다.  
aws ec2 describe-vpcs \  
    --filters "Name=tag:Project,Values=$PROJECT" \  
    --query 'Vpcs[].[VpcId,State,CidrBlock]' \  
    --output table \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# 같은 Project Tag를 가진 종료되지 않은 EC2가 있는지 확인한다.  
aws ec2 describe-instances \  
    --filters "Name=tag:Project,Values=$PROJECT" "Name=instance-state-name,Values=pending,running,stopping,stopped" \  
    --query 'Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress]' \  
    --output table \  
    --profile "$PROFILE" \  
    --region "$REGION"  
```


<br>

### 🟡 한 줄 명령  

```bash
# 같은 Project Tag를 가진 VPC가 있는지 확인한다.  
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=$PROJECT" --query 'Vpcs[].[VpcId,State,CidrBlock]' --output table --profile "$PROFILE" --region "$REGION"  

# 같은 Project Tag를 가진 종료되지 않은 EC2가 있는지 확인한다.  
aws ec2 describe-instances --filters "Name=tag:Project,Values=$PROJECT" "Name=instance-state-name,Values=pending,running,stopping,stopped" --query 'Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress]' --output table --profile "$PROFILE" --region "$REGION"  
```


<br>

### 🟡 명령 의미  

| 명령·옵션 | 의미 |  
| :--- | :--- |
| `describe-vpcs` | VPC 조회 |  
| `describe-instances` | EC2 조회 |  
| `--filters` | 조건과 일치하는 리소스만 검색 |  
| `tag:Project` | Project Tag를 검색 기준으로 사용 |  
| `--query` | 필요한 응답 필드만 선택 |  
| `--output table` | 결과를 표로 표시 |  









<br><br><br>

## 🟢 4단계: Availability Zone 선택  

- Availability Zone(AZ)은 AWS 리전 안에 있는 독립된 데이터센터 묶음  
    AWS 서울 리전  
    ap-northeast-2  
        ├── ap-northeast-2a  
        ├── ap-northeast-2b  
        ├── ap-northeast-2c  
        └── ap-northeast-2d  

- Region = 큰 지역  
- Availability Zone = 그 지역 안의 독립된 데이터센터 구역  

- 왜 여러 AZ로 나누나? = 핵심은 장애 분리다.  
    - 한 곳에 몰아넣지 않게 만들어서 한 곳에서 문제가 되어도 계속 살아있을 수 있도록 설계한 것.  



<br>

### 🟡 여러 줄 명령  

```bash
# Availability Zone 확인  
aws ec2 describe-availability-zones --filters Name=state,Values=available --query 'AvailabilityZones[].ZoneName' --output table --profile "$PROFILE"  

# 서울 Region에서 사용 가능한 첫 번째 Availability Zone을 저장한다.  
AZ="$(  
    aws ec2 describe-availability-zones \  
        --filters Name=state,Values=available \  
        --query 'AvailabilityZones[0].ZoneName' \  
        --output text \  
        --profile "$PROFILE" \  
        --region "$REGION"  
)"  

# 선택 결과를 확인한다.  
printf 'AZ=%s\n' "$AZ"  
```

<br>

### 🟡 한 줄 명령  

```bash
# Availability Zone 확인  
aws ec2 describe-availability-zones --filters Name=state,Values=available --query 'AvailabilityZones[].ZoneName' --output table --profile "$PROFILE"  

# 서울 Region에서 사용 가능한 첫 번째 Availability Zone을 저장한다.  
AZ="$(aws ec2 describe-availability-zones --filters Name=state,Values=available --query 'AvailabilityZones[0].ZoneName' --output text --profile "$PROFILE" --region "$REGION")"  

# 선택 결과를 확인한다.  
printf 'AZ=%s\n' "$AZ"  
```

<br>

### 🟡 명령 의미  

| 문법·명령 | 의미 |  
| :--- | :--- |
| `describe-availability-zones` | 사용할 수 있는 AZ 조회 |  
| `$(명령)` | 명령 출력값을 변수에 저장 |  
| `[0]` | 첫 번째 결과 선택 |  
| `--output text` | 일반 문자열로 출력 |  

결과가 `None` 또는 빈 문자열이면 다음 단계로 넘어가지 않는다.  





