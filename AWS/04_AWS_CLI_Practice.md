# 🟩 AWS CLI로 과제 전체 수행하기 4  

#### ⚫️ 들어가기 전 이해하기  






<br><br>

## 🟢 15단계: Mac에서 SSH 접속  

```bash
# Netcat: EC2의 SSH 22번 Port까지 TCP 연결이 가능한지 확인한다.  
nc -vz "$PUBLIC_IP" 22  

# Secure Shell: Private Key를 사용해 Ubuntu EC2에 접속한다.  
ssh -i "$KEY_FILE" ubuntu@"$PUBLIC_IP"  
```

<br>

### 🟡 명령 의미  

| 명령·옵션 | 풀네임 | 의미 |  
| :--- | :--- | :--- |
| `nc` | Netcat | TCP·UDP 연결 확인 |  
| `-v` | Verbose | 자세한 결과 표시 |  
| `-z` | Zero-I/O Mode | 데이터를 보내지 않고 Port만 검사 |  
| `ssh` | Secure Shell | 암호화된 원격 Terminal 접속 |  
| `-i` | Identity File | 사용할 Private Key 지정 |  
| `ubuntu@IP` | User at Host | Ubuntu 사용자로 해당 IP에 접속 |  

프롬프트가 `ubuntu@ip-...` 형태로 바뀐 뒤에는 EC2 내부 명령을 실행한다.  














<br><br><br>

## 🟢 16단계: EC2 내부에서 Nginx 설치  

아래 명령은 AWS CLI가 아니라 SSH로 접속한 Ubuntu EC2 내부의 Linux 명령이다.  

```bash
# Who Am I: 현재 사용자가 ubuntu인지 확인한다.  
whoami  

# Host Name: 현재 컴퓨터가 EC2인지 확인한다.  
hostname  

# Client URL: EC2에서 외부 HTTPS 통신이 가능한지 확인한다.  
curl -I https://example.com  

# Advanced Package Tool: Ubuntu Package 목록을 갱신한다.  
sudo apt update  

# Advanced Package Tool: 질문에 자동 동의하고 Nginx를 설치한다.  
sudo apt install -y nginx  

# System Control: Nginx를 지금 시작하고 재부팅 후에도 자동 시작하게 한다.  
sudo systemctl enable --now nginx  

# System Control: Nginx 실행 상태를 Pager 없이 확인한다.  
sudo systemctl status nginx --no-pager  

# Socket Statistics: TCP 80번 Port를 듣는 Process를 확인한다.  
sudo ss -lntp | grep ':80'  

# Tee: /health 경로에서 제공할 고정 문자열 파일을 만든다.  
printf 'OK\n' | sudo tee /var/www/html/health >/dev/null  

# Client URL: EC2 내부에서 /health의 Header와 Body를 확인한다.  
curl -i http://localhost/health  
```

<br>

### 🟡 명령 의미  

| 명령·옵션 | 의미 |  
| :--- | :--- |
| `sudo` | Superuser Do, 한 명령을 관리자 권한으로 실행 |  
| `apt update` | 설치 가능한 Package 목록 갱신 |  
| `apt install -y` | Package 설치 질문에 자동 동의 |  
| `systemctl enable --now` | 자동 시작을 등록하고 지금 시작 |  
| `ss -lntp` | Listening TCP Port와 Process를 숫자로 표시 |  
| `grep ':80'` | 80번 Port가 있는 줄만 선택 |  
| `tee` | 입력 내용을 파일에 기록 |  
| `>/dev/null` | 필요 없는 정상 출력 숨김 |  
| `curl -I` | Response Header만 조회 |  
| `curl -i` | Response Header와 Body를 함께 조회 |  

내부 `curl`에서 `200 OK`와 `OK`가 모두 나와야 한다.  









<br><br><br>

## 🟢 17단계: Mac에서 외부 접속 검증  

```bash
# Exit: SSH Session을 종료하고 Mac Terminal로 돌아간다.  
exit  

# Netcat: 외부에서 EC2 HTTP 80번 Port에 연결되는지 확인한다.  
nc -vz "$PUBLIC_IP" 80  

# Client URL: Mac에서 EC2 /health를 호출한다.  
curl --connect-timeout 5 -i "http://${PUBLIC_IP}/health"  
```

<br>

### 🟡 명령 의미  

| 명령·옵션 | 의미 |  
| :--- | :--- |
| `exit` | SSH Session 종료 |  
| `--connect-timeout 5` | 연결을 최대 5초만 기다림 |  
| `${PUBLIC_IP}` | Public IP 변수값을 URL 안에 사용 |  

외부 `curl`의 `200 OK`와 `OK` 결과가 외부 접속 검증 방식 B의 증빙이다.  









<br><br><br>

## 🟢 18단계: AWS 구성 증빙 조회  

<br>

### 🟡 여러 줄 명령  

```bash
# VPC, Subnet CIDR과 Public IP 설정을 확인한다.  
aws ec2 describe-subnets \  
    --subnet-ids "$SUBNET_ID" \  
    --query 'Subnets[0].[VpcId,SubnetId,CidrBlock,AvailabilityZone,MapPublicIpOnLaunch]' \  
    --output table \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# Route와 Subnet Association을 확인한다.  
aws ec2 describe-route-tables \  
    --route-table-ids "$RT_ID" \  
    --query 'RouteTables[0].[Routes,Associations]' \  
    --output json \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# Security Group Inbound 규칙을 확인한다.  
aws ec2 describe-security-group-rules \  
    --filters "Name=group-id,Values=$SG_ID" \  
    --query 'SecurityGroupRules[?IsEgress==`false`].[IpProtocol,FromPort,ToPort,CidrIpv4]' \  
    --output table \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# EC2의 상태와 네트워크 연결 관계를 확인한다.  
aws ec2 describe-instances \  
    --instance-ids "$INSTANCE_ID" \  
    --query 'Reservations[0].Instances[0].[InstanceId,State.Name,PublicIpAddress,VpcId,SubnetId]' \  
    --output table \  
    --profile "$PROFILE" \  
    --region "$REGION"  
```

<br>

### 🟡 한 줄 명령  

```bash
# VPC, Subnet CIDR과 Public IP 설정을 확인한다.  
aws ec2 describe-subnets --subnet-ids "$SUBNET_ID" --query 'Subnets[0].[VpcId,SubnetId,CidrBlock,AvailabilityZone,MapPublicIpOnLaunch]' --output table --profile "$PROFILE" --region "$REGION"  

# Route와 Subnet Association을 확인한다.  
aws ec2 describe-route-tables --route-table-ids "$RT_ID" --query 'RouteTables[0].[Routes,Associations]' --output json --profile "$PROFILE" --region "$REGION"  

# Security Group Inbound 규칙을 확인한다.  
aws ec2 describe-security-group-rules --filters "Name=group-id,Values=$SG_ID" --query 'SecurityGroupRules[?IsEgress==`false`].[IpProtocol,FromPort,ToPort,CidrIpv4]' --output table --profile "$PROFILE" --region "$REGION"  

# EC2의 상태와 네트워크 연결 관계를 확인한다.  
aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].[InstanceId,State.Name,PublicIpAddress,VpcId,SubnetId]' --output table --profile "$PROFILE" --region "$REGION"  
```

<br>

### 🟡 증빙 조회 명령 의미  

| 명령 | 증명하는 내용 |  
| :--- | :--- |
| `describe-subnets` | Subnet이 올바른 VPC, CIDR, AZ에 있고 Public IPv4 자동 할당이 켜졌는지 |  
| `describe-route-tables` | `local` 경로, `0.0.0.0/0 → IGW`, Subnet Association이 있는지 |  
| `describe-security-group-rules` | SSH 22와 HTTP 80의 Source가 올바른지 |  
| `describe-instances` | EC2가 running이며 올바른 VPC와 Subnet에 있고 Public IPv4가 있는지 |  

<br>

### 🟡 증빙 보안 규칙  

- Access Key, Secret Access Key, `.pem` 내용은 절대 포함하지 않는다.  
- Account ID와 IAM 사용자 이름은 공유 전 가린다.  
- Public IP는 증빙에 꼭 필요할 때만 표시하고 실습 후 EC2를 삭제한다.  
- 예시 값이 아닌 실제 명령 결과만 사용한다.  











<br><br><br>

## 🟢 19단계: 안전한 트러블슈팅 실습  

위험한 Security Group 규칙을 만들지 않는다. Nginx만 잠시 중지해 실제 장애를 재현한다.  

```bash
# Secure Shell: Ubuntu EC2에 다시 접속한다.  
ssh -i "$KEY_FILE" ubuntu@"$PUBLIC_IP"  

# System Control: Nginx만 잠시 중지한다.  
sudo systemctl stop nginx  

# System Control: Nginx가 inactive 상태인지 확인한다.  
sudo systemctl status nginx --no-pager  

# Client URL: localhost 요청이 실패하는지 확인한다.  
curl --connect-timeout 5 -i http://localhost/health  

# System Control: Nginx를 다시 시작한다.  
sudo systemctl start nginx  

# Client URL: 같은 요청이 다시 성공하는지 확인한다.  
curl --connect-timeout 5 -i http://localhost/health  

# Journal Control: 중지와 시작 기록을 최근 30줄에서 확인한다.  
sudo journalctl -u nginx -n 30 --no-pager  

# Exit: SSH Session을 종료한다.  
exit  

# Client URL: Mac 외부에서도 복구됐는지 확인한다.  
curl --connect-timeout 5 -i "http://${PUBLIC_IP}/health"  
```

<br>

### 🟡 명령 의미  

| 명령 | 의미 |  
| :--- | :--- |
| `systemctl stop nginx` | Nginx Process 중지 |  
| `systemctl start nginx` | Nginx Process 시작 |  
| `journalctl -u nginx` | Nginx Service Log 조회 |  
| `-n 30` | 최근 30줄만 표시 |  
| `--no-pager` | 별도 Pager를 열지 않고 바로 출력 |  

<br>

### 🟡 보고서에 기록할 내용  

| 항목 | 기록 |  
| :--- | :--- |
| 증상 | `/health` 연결 실패 |  
| 가설 | Nginx Process가 중지됨 |  
| 검증 | `systemctl status`, 내부 `curl`, `journalctl` |  
| 조치 | `sudo systemctl start nginx` |  
| 결과 | 내부·외부 모두 `200 OK`, `OK` |  
| 재발 방지 | 배포 후 Process 상태와 Health Check를 함께 검사 |  















<br><br><br>

## 🟢 20단계: Terminal을 닫았을 때 ID 복구  

2단계 공통 변수를 다시 설정한 뒤 Tag로 ID를 찾는다. 다음 명령은 이미 한 줄이므로 별도 한 줄 버전이 같다.  

```bash
# Project Tag로 VPC ID를 복구한다.  
VPC_ID="$(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=$PROJECT" --query 'Vpcs[0].VpcId' --output text --profile "$PROFILE" --region "$REGION")"  

# Project Tag로 Subnet ID를 복구한다.  
SUBNET_ID="$(aws ec2 describe-subnets --filters "Name=tag:Project,Values=$PROJECT" --query 'Subnets[0].SubnetId' --output text --profile "$PROFILE" --region "$REGION")"  

# Project Tag로 Internet Gateway ID를 복구한다.  
IGW_ID="$(aws ec2 describe-internet-gateways --filters "Name=tag:Project,Values=$PROJECT" --query 'InternetGateways[0].InternetGatewayId' --output text --profile "$PROFILE" --region "$REGION")"  

# Project Tag로 Route Table ID를 복구한다.  
RT_ID="$(aws ec2 describe-route-tables --filters "Name=tag:Project,Values=$PROJECT" --query 'RouteTables[0].RouteTableId' --output text --profile "$PROFILE" --region "$REGION")"  

# Main이 아닌 Route Table Association ID를 복구한다.  
RT_ASSOC_ID="$(aws ec2 describe-route-tables --route-table-ids "$RT_ID" --query 'RouteTables[0].Associations[?Main==`false`].RouteTableAssociationId | [0]' --output text --profile "$PROFILE" --region "$REGION")"  

# Project Tag로 Security Group ID를 복구한다.  
SG_ID="$(aws ec2 describe-security-groups --filters "Name=tag:Project,Values=$PROJECT" --query 'SecurityGroups[0].GroupId' --output text --profile "$PROFILE" --region "$REGION")"  

# Project Tag로 종료되지 않은 EC2 ID를 복구한다.  
INSTANCE_ID="$(aws ec2 describe-instances --filters "Name=tag:Project,Values=$PROJECT" "Name=instance-state-name,Values=pending,running,stopping,stopped" --query 'Reservations[0].Instances[0].InstanceId' --output text --profile "$PROFILE" --region "$REGION")"  

# 복구한 ID를 삭제 전에 확인한다.  
printf 'VPC_ID=%s\nSUBNET_ID=%s\nIGW_ID=%s\nRT_ID=%s\nRT_ASSOC_ID=%s\nSG_ID=%s\nINSTANCE_ID=%s\n' "$VPC_ID" "$SUBNET_ID" "$IGW_ID" "$RT_ID" "$RT_ASSOC_ID" "$SG_ID" "$INSTANCE_ID"  
```

하나라도 `None`이면 삭제 명령을 실행하지 말고 조회 결과부터 다시 확인한다.  

<br>

### 🟡 ID 복구 명령 의미  

| 명령·표현 | 의미 |  
| :--- | :--- |
| `describe-* --filters Name=tag:Project` | Project Tag를 이용해 리소스 다시 찾기 |  
| `Associations[?Main==false]` | Main Route Table 연결이 아닌 사용자 연결만 선택 |  
| `instance-state-name` | 이미 terminated된 EC2를 제외하고 검색 |  
| `printf` | 삭제 전에 찾은 모든 ID를 한 화면에서 검토 |  


