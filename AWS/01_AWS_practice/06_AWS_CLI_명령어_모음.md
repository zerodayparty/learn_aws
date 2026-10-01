# 🟩 이 과제로 인해 사용될 AWS CLI 명령어 모음  


<br>

## 🟢 AWS CLI 명령의 기본 구조  

```text
# AWS CLI 명령이 구성되는 기본 순서다.  
aws + 서비스 + 작업 + 대상·조건 Option + Profile + Region + 출력 형식  

# 실제 구조 예시다.  
aws ec2 describe-vpcs --profile PROFILE --region REGION --output table  
```

| 위치 | 예시 | 의미 |  
| :--- | :--- | :--- |
| CLI Program | `aws` | AWS CLI 실행 |  
| Service | `ec2`, `sts` | 요청을 보낼 AWS Service |  
| Operation | `describe-vpcs` | AWS에 요청할 작업 |  
| Option | `--vpc-ids` | 대상이나 조건 지정 |  
| Profile | `--profile` | 사용할 인증 정보 지정 |  
| Region | `--region` | 작업할 AWS 지역 지정 |  
| Output | `--output` | 결과 표시 형식 지정 |  









<br><br>

## 🟢 1. AWS CLI 설치·인증 확인 명령  

| 명령 | 풀네임·의미 | 실행 위치 | 위험도 |  
| :--- | :--- | :---: | :---: |
| `aws --version` | AWS CLI Version / 설치 버전 확인 | Mac | 조회 |  
| `aws configure list-profiles` | Configure List Profiles / 저장된 Profile 목록 확인 | Mac | 조회 |  
| `aws configure get region` | Configure Get Region / Profile의 기본 Region 확인 | Mac | 조회 |  
| `aws sts get-caller-identity` | Security Token Service Get Caller Identity / 현재 인증 사용자·Role·Account 확인 | Mac | 조회 |  

### 🟡 관련 Option  

| Option | 의미 |  
| :--- | :--- |
| `--profile aws-basic` | `aws-basic` 인증 Profile 사용 |  
| `--region ap-northeast-2` | 서울 Region 사용 |  
| `--output json` | 결과를 JSON(JavaScript Object Notation)으로 출력 |  









<br><br>

## 🟢 2. Shell 변수와 출력 명령  

| 문법·명령 | 풀네임·의미 | 예시 용도 |  
| :--- | :--- | :--- |
| `NAME="value"` | Shell Variable Assignment / 현재 Terminal에 값 저장 | Profile, Region, Resource ID 저장 |  
| `$NAME` | Variable Expansion / 저장된 변수값 사용 | `"$VPC_ID"` |  
| `${NAME}` | Braced Variable Expansion / 문자열 안에서 변수 경계 구분 | `${PROJECT}-vpc` |  
| `$(명령)` | Command Substitution / 명령 결과를 값으로 사용 | 생성된 VPC ID 저장 |  
| `printf` | Print Formatted / 정해진 형식으로 값 출력 | 변수값과 줄바꿈 확인 |  

### 🟡 Shell 연결 기호  

| 기호 | 의미 | 주의점 |  
| :---: | :--- | :--- |
| `\` | 다음 줄도 같은 명령으로 연결 | 역슬래시 뒤에 공백 금지 |  
| `|` | 왼쪽 명령의 출력을 오른쪽 명령에 전달 | Pipe라고 부름 |  
| `>` | 출력을 파일에 저장하며 기존 파일 덮어쓰기 | Private Key 경로 확인 |  
| `>/dev/null` | 필요 없는 정상 출력 버리기 | 오류 출력은 남음 |  
| `&&` | 앞 명령이 성공한 경우에만 다음 명령 실행 | 안전한 순차 실행 |  
| `;` | 앞 명령 성공 여부와 관계없이 다음 명령 실행 | 생성·삭제 명령 연결에는 부적합 |  









<br><br>

## 🟢 3. AWS 리소스 조회 공통 명령  

AWS CLI에서 `describe`는 리소스 정보를 조회한다는 뜻이다.  

| 명령 | 조회 대상 | 주요 확인 내용 |  
| :--- | :--- | :--- |
| `aws ec2 describe-vpcs` | VPC | VPC ID, CIDR, State, Tag |  
| `aws ec2 describe-subnets` | Subnet | VPC ID, CIDR, AZ, Public IP 설정 |  
| `aws ec2 describe-availability-zones` | Availability Zone | 서울 Region에서 사용 가능한 AZ |  
| `aws ec2 describe-internet-gateways` | Internet Gateway | VPC 연결 상태 |  
| `aws ec2 describe-route-tables` | Route Table | Route와 Subnet Association |  
| `aws ec2 describe-security-groups` | Security Group | VPC, 이름, 설명 |  
| `aws ec2 describe-security-group-rules` | Security Group Rule | Protocol, Port, Source CIDR |  
| `aws ec2 describe-images` | AMI | Ubuntu Image ID와 생성일 |  
| `aws ec2 describe-instance-type-offerings` | Instance Type 제공 여부 | AZ에서 `t3.micro` 사용 가능 여부 |  
| `aws ec2 describe-instances` | EC2 | 상태, Public IP, Private IP, VPC, Subnet |  
| `aws ec2 describe-volumes` | EBS | Volume ID, 상태, 크기, 종류, 암호화 |  
| `aws ec2 describe-addresses` | Elastic IP | Allocation ID, 연결 상태, Public IP |  

### 🟡 조회 Option  

| Option | 의미 |  
| :--- | :--- |
| `--vpc-ids` | 특정 VPC ID만 조회 |  
| `--subnet-ids` | 특정 Subnet ID만 조회 |  
| `--instance-ids` | 특정 EC2 ID만 조회 |  
| `--volume-ids` | 특정 EBS Volume ID만 조회 |  
| `--group-ids` | 특정 Security Group ID만 조회 |  
| `--filters` | 이름, Tag, 상태 등 조건으로 검색 |  
| `--query` | JMESPath 문법으로 필요한 응답 필드만 선택 |  
| `--output text` | 결과를 일반 문자열로 출력 |  
| `--output table` | 결과를 표로 출력 |  
| `--output json` | 결과 구조를 JSON으로 출력 |  









<br><br>

## 🟢 4. VPC 생성·설정 명령  

| 명령 | 역할 | 변경 수준 |  
| :--- | :--- | :---: |
| `aws ec2 create-vpc` | 새 VPC 생성 | 생성 |  
| `aws ec2 wait vpc-available` | VPC가 사용 가능한 상태가 될 때까지 대기 | 조회·대기 |  
| `aws ec2 modify-vpc-attribute` | VPC DNS 기능 변경 | 변경 |  

### 🟡 주요 Option  

| Option | 의미 |  
| :--- | :--- |
| `--cidr-block` | VPC가 사용할 IPv4 범위 지정 |  
| `--tag-specifications` | 생성할 때 Name과 Project Tag 지정 |  
| `--enable-dns-support` | VPC 내부 DNS 해석 활성화 |  
| `--enable-dns-hostnames` | Public DNS Hostname 기능 활성화 |  
| `--vpc-ids` | 대기하거나 조회할 VPC 지정 |  









<br><br>

## 🟢 5. Public Subnet 명령  

| 명령 | 역할 | 변경 수준 |  
| :--- | :--- | :---: |
| `aws ec2 create-subnet` | VPC 안에 Subnet 생성 | 생성 |  
| `aws ec2 modify-subnet-attribute` | Public IPv4 자동 할당 설정 | 변경 |  

### 🟡 주요 Option  

| Option | 의미 |  
| :--- | :--- |
| `--vpc-id` | Subnet이 들어갈 VPC 지정 |  
| `--cidr-block` | Subnet IPv4 범위 지정 |  
| `--availability-zone` | Subnet을 만들 AZ 지정 |  
| `--map-public-ip-on-launch` | 새 EC2에 Public IPv4 자동 할당 |  









<br><br>

## 🟢 6. Internet Gateway 명령  

| 명령 | 역할 | 변경 수준 |  
| :--- | :--- | :---: |
| `aws ec2 create-internet-gateway` | Internet Gateway 생성 | 생성 |  
| `aws ec2 attach-internet-gateway` | IGW를 VPC에 연결 | 변경 |  
| `aws ec2 detach-internet-gateway` | IGW를 VPC에서 분리 | 변경 |  
| `aws ec2 delete-internet-gateway` | 분리된 IGW 삭제 | 삭제 |  

### 🟡 주요 Option  

| Option | 의미 |  
| :--- | :--- |
| `--internet-gateway-id` | 작업할 IGW 지정 |  
| `--vpc-id` | 연결하거나 분리할 VPC 지정 |  









<br><br>

## 🟢 7. Route Table 명령  

| 명령 | 역할 | 변경 수준 |  
| :--- | :--- | :---: |
| `aws ec2 create-route-table` | 사용자 정의 Route Table 생성 | 생성 |  
| `aws ec2 create-route` | `0.0.0.0/0 → IGW` 경로 생성 | 생성 |  
| `aws ec2 associate-route-table` | Route Table을 Subnet에 연결 | 변경 |  
| `aws ec2 disassociate-route-table` | Subnet 연결 해제 | 변경 |  
| `aws ec2 delete-route` | 사용자 정의 Route 삭제 | 삭제 |  
| `aws ec2 delete-route-table` | 사용자 정의 Route Table 삭제 | 삭제 |  

### 🟡 주요 Option  

| Option | 의미 |  
| :--- | :--- |
| `--route-table-id` | 작업할 Route Table 지정 |  
| `--destination-cidr-block 0.0.0.0/0` | 모든 외부 IPv4 목적지 지정 |  
| `--gateway-id` | 목적지로 사용할 IGW 지정 |  
| `--subnet-id` | 연결할 Subnet 지정 |  
| `--association-id` | 해제할 Route Table 연결 지정 |  









<br><br>

## 🟢 8. Public IP 확인 명령  

| 명령·Option | 의미 |  
| :--- | :--- |
| `curl https://checkip.amazonaws.com` | 현재 Mac의 Public IPv4 확인 |  
| `--fail` | HTTP 오류를 성공으로 처리하지 않음 |  
| `--silent` | 진행률 숨김 |  
| `--show-error` | 실패 이유는 표시 |  
| `tr -d '\n'` | 응답 끝의 줄바꿈 제거 |  
| `/32` | IPv4 주소 한 개만 허용하는 CIDR 범위 |  









<br><br>

## 🟢 9. Security Group 명령  

| 명령 | 역할 | 변경 수준 |  
| :--- | :--- | :---: |
| `aws ec2 create-security-group` | VPC에 Security Group 생성 | 생성 |  
| `aws ec2 authorize-security-group-ingress` | Inbound 허용 규칙 추가 | 변경 |  
| `aws ec2 delete-security-group` | 사용자 정의 Security Group 삭제 | 삭제 |  

### 🟡 주요 Option  

| Option | 의미 |  
| :--- | :--- |
| `--group-name` | Security Group 이름 지정 |  
| `--description` | Security Group 설명 지정 |  
| `--group-id` | 작업할 Security Group 지정 |  
| `--protocol tcp` | TCP(Transmission Control Protocol) 사용 |  
| `--port 22` | SSH Port 지정 |  
| `--port 80` | HTTP Port 지정 |  
| `--cidr "$MY_IP"` | 현재 내 Public IP `/32`만 허용 |  
| `--cidr 0.0.0.0/0` | 모든 IPv4 주소 허용 |  









<br><br>

## 🟢 10. Key Pair와 로컬 파일 명령  

| 명령 | 풀네임·의미 | 변경 수준 |  
| :--- | :--- | :---: |
| `mkdir -p` | Make Directory / Private Key 저장 Directory 생성 | 로컬 변경 |  
| `test ! -e` | Test Not Exists / 같은 파일이 없는지 확인 | 조회 |  
| `umask 077` | User Mask / 새 파일의 기본 권한 제한 | 현재 Shell 변경 |  
| `aws ec2 create-key-pair` | EC2 Key Pair 생성, Private Key 한 번 반환 | AWS 생성 |  
| `chmod 400` | Change Mode / 소유자 읽기만 허용 | 로컬 변경 |  
| `ls -l` | List Long Format / 파일 크기와 권한 확인 | 조회 |  
| `rm --` | Remove / 확인한 로컬 Private Key 삭제 | 로컬 삭제 |  

### 🟡 Key Pair Option  

| Option | 의미 |  
| :--- | :--- |
| `--key-name` | AWS에 등록할 Key Pair 이름 |  
| `--key-type ed25519` | Ed25519 방식의 SSH Key 사용 |  
| `--key-format pem` | PEM(Privacy-Enhanced Mail) 파일 형식 사용 |  
| `--query KeyMaterial` | 반환값에서 Private Key 내용만 선택 |  

`cat`, `head`, `tail`로 `.pem` 파일 내용을 출력하면 안 된다.  









<br><br>

## 🟢 11. AMI와 EC2 생성 명령  

| 명령 | 역할 | 변경 수준 |  
| :--- | :--- | :---: |
| `aws ec2 describe-images` | Ubuntu AMI 검색 | 조회 |  
| `aws ec2 describe-instance-type-offerings` | AZ의 Instance Type 제공 여부 확인 | 조회 |  
| `aws ec2 run-instances` | EC2 생성 | 생성·과금 가능 |  
| `aws ec2 wait instance-running` | EC2가 running이 될 때까지 대기 | 조회·대기 |  
| `aws ec2 wait instance-status-ok` | AWS 상태 검사 통과까지 대기 | 조회·대기 |  

### 🟡 `run-instances` 주요 Option  

| Option | 의미 |  
| :--- | :--- |
| `--image-id` | 사용할 AMI 지정 |  
| `--instance-type` | EC2 사양 지정 |  
| `--count 1` | EC2 한 대 생성 |  
| `--subnet-id` | EC2를 배치할 Subnet 지정 |  
| `--security-group-ids` | 연결할 Security Group 지정 |  
| `--key-name` | SSH 접속에 사용할 Key Pair 지정 |  
| `--associate-public-ip-address` | Public IPv4 요청 |  
| `CpuCredits=standard` | T3 CPU Credit 추가 비용 위험 제한 |  
| `HttpTokens=required` | IMDSv2(Instance Metadata Service version 2) Token 필수 |  
| `--block-device-mappings` | EBS 크기·종류·암호화·삭제 조건 지정 |  
| `DeleteOnTermination=true` | EC2 종료 시 Root EBS도 삭제 |  
| `Encrypted=true` | EBS 암호화 |  









<br><br>

## 🟢 12. SSH와 Network Port 확인 명령  

| 명령 | 풀네임·의미 | 실행 위치 |  
| :--- | :--- | :---: |
| `nc -vz IP 22` | Netcat Verbose Zero-I/O / SSH Port 연결 확인 | Mac |  
| `nc -vz IP 80` | Netcat Verbose Zero-I/O / HTTP Port 연결 확인 | Mac |  
| `ssh -i KEY ubuntu@IP` | Secure Shell Identity File / Private Key로 Ubuntu 접속 | Mac |  
| `exit` | Exit / SSH Session 종료 | EC2 |  

### 🟡 SSH Option  

| Option | 의미 |  
| :--- | :--- |
| `-i` | Identity File, 사용할 Private Key 지정 |  
| `ubuntu@IP` | Ubuntu 사용자로 지정한 EC2 IP에 접속 |  
| `nc -v` | 연결 결과를 자세히 표시 |  
| `nc -z` | 데이터를 보내지 않고 Port 연결만 검사 |  









<br><br>

## 🟢 13. EC2 내부 Linux 확인 명령  

| 명령 | 풀네임·의미 |  
| :--- | :--- |
| `whoami` | Who Am I / 현재 Linux 사용자 확인 |  
| `hostname` | Host Name / 현재 Server 이름 확인 |  









<br><br>

## 🟢 14. Nginx 설치·관리 명령  

| 명령 | 풀네임·의미 | 변경 수준 |  
| :--- | :--- | :---: |
| `sudo apt update` | Advanced Package Tool Update / Package 목록 갱신 | 변경 |  
| `sudo apt install -y nginx` | Advanced Package Tool Install / Nginx 설치 | 변경 |  
| `sudo systemctl enable --now nginx` | System Control / 자동 시작 등록과 즉시 실행 | 변경 |  
| `sudo systemctl status nginx --no-pager` | Nginx Service 상태 확인 | 조회 |  
| `sudo systemctl stop nginx` | Nginx 중지 | 변경 |  
| `sudo systemctl start nginx` | Nginx 시작 | 변경 |  
| `sudo ss -lntp` | Socket Statistics / Listening TCP Port와 Process 확인 | 조회 |  
| `sudo journalctl -u nginx` | Journal Control / Nginx Service Log 확인 | 조회 |  

### 🟡 Linux Option  

| Option | 의미 |  
| :--- | :--- |
| `sudo` | Superuser Do / 한 명령을 관리자 권한으로 실행 |  
| `apt -y` | 설치 확인 질문에 자동으로 Yes |  
| `systemctl --now` | 설정 변경과 동시에 Service 실행 |  
| `--no-pager` | 별도 Pager 없이 현재 화면에 출력 |  
| `ss -l` | Listening Socket만 표시 |  
| `ss -n` | Port와 주소를 숫자로 표시 |  
| `ss -t` | TCP Socket만 표시 |  
| `ss -p` | Socket을 사용하는 Process 표시 |  
| `journalctl -u nginx` | Nginx Unit의 Log만 표시 |  
| `journalctl -n 30` | 최근 30줄만 표시 |  









<br><br>

## 🟢 15. HTTP 검증과 파일 생성 명령  

| 명령 | 풀네임·의미 | 실행 위치 |  
| :--- | :--- | :---: |
| `curl -I https://example.com` | Client URL Head / EC2 Outbound HTTPS 확인 | EC2 |  
| `curl -i http://localhost/health` | Client URL Include / 내부 Header와 Body 확인 | EC2 |  
| `curl -i http://PUBLIC_IP/health` | 외부 Network Path 전체 확인 | Mac |  
| `printf 'OK\n'` | Print Formatted / `OK` 문자열 생성 | EC2 |  
| `sudo tee /var/www/html/health` | 관리자 권한으로 Health 파일 작성 | EC2 |  
| `grep ':80'` | Global Regular Expression Print / 80번 Port 줄만 선택 | EC2 |  

### 🟡 `curl` Option  

| Option | 의미 |  
| :--- | :--- |
| `-I` | Response Header만 확인 |  
| `-i` | Response Header와 Body를 함께 확인 |  
| `--connect-timeout 5` | 연결을 최대 5초만 기다림 |  









<br><br>

## 🟢 16. EC2와 AWS 리소스 삭제 명령  

삭제 명령은 되돌리기 어렵다. 07번 문서의 삭제 순서와 변수 ID를 다시 확인한 뒤 실행한다.  

| 명령 | 삭제 대상·역할 | 위험도 |  
| :--- | :--- | :---: |
| `aws ec2 terminate-instances` | EC2 영구 종료 | 높음 |  
| `aws ec2 wait instance-terminated` | EC2 종료 완료까지 대기 | 조회·대기 |  
| `aws ec2 delete-volume` | 남은 EBS 영구 삭제 | 높음 |  
| `aws ec2 delete-security-group` | 사용자 정의 Security Group 삭제 | 높음 |  
| `aws ec2 disassociate-route-table` | Subnet과 Route Table 연결 해제 | 높음 |  
| `aws ec2 delete-route` | `0.0.0.0/0 → IGW` Route 삭제 | 높음 |  
| `aws ec2 delete-route-table` | 사용자 정의 Route Table 삭제 | 높음 |  
| `aws ec2 detach-internet-gateway` | IGW를 VPC에서 분리 | 높음 |  
| `aws ec2 delete-internet-gateway` | IGW 삭제 | 높음 |  
| `aws ec2 delete-subnet` | Public Subnet 삭제 | 높음 |  
| `aws ec2 delete-key-pair` | AWS의 Public Key 정보 삭제 | 높음 |  
| `aws ec2 delete-vpc` | VPC 삭제 | 매우 높음 |  
| `rm -- "$KEY_FILE"` | Mac의 Private Key 파일 삭제 | 매우 높음 |  









<br><br>

## 🟢 17. 명령 이름에서 작업 종류 구분하기  

| 동사 | 의미 | 예시 |  
| :--- | :--- | :--- |
| `describe` | 조회 | `describe-vpcs` |  
| `create` | 생성 | `create-subnet` |  
| `modify` | 설정 변경 | `modify-vpc-attribute` |  
| `authorize` | 접근 허용 추가 | `authorize-security-group-ingress` |  
| `associate` | 논리적 연결 | `associate-route-table` |  
| `disassociate` | 논리적 연결 해제 | `disassociate-route-table` |  
| `attach` | 리소스 부착 | `attach-internet-gateway` |  
| `detach` | 리소스 분리 | `detach-internet-gateway` |  
| `run` | 실행·생성 | `run-instances` |  
| `terminate` | 영구 종료 | `terminate-instances` |  
| `delete` | 삭제 | `delete-vpc` |  
| `wait` | 특정 상태가 될 때까지 대기 | `wait instance-running` |  









<br><br>

## 🟢 18. 막혔을 때 추가로 사용할 도움말 명령  

아래 명령은 06번과 07번의 실행 순서에는 없다. 명령의 사용법을 잊었을 때 추가로 사용하는 조회 전용 명령이며 AWS 리소스를 만들지 않는다.  

```bash
# AWS CLI 전체 도움말을 연다.  
aws help  

# EC2 Service의 전체 Operation 목록을 연다.  
aws ec2 help  

# run-instances의 Option과 Example을 연다.  
aws ec2 run-instances help  

# create-vpc의 Option과 Example을 연다.  
aws ec2 create-vpc help  

# 현재 설치된 AWS CLI Version을 다시 확인한다.  
aws --version  
```

| 도움말 명령 | 의미 |  
| :--- | :--- |
| `aws help` | AWS CLI 기본 문법 확인 |  
| `aws ec2 help` | EC2에서 사용할 수 있는 Operation 확인 |  
| `aws ec2 명령 help` | 특정 Operation의 Option, 출력, Example 확인 |  









<br><br>

## 🟢 빠른 검색표  

| 하고 싶은 일 | 찾을 명령 |  
| :--- | :--- |
| 현재 인증 사용자 확인 | `aws sts get-caller-identity` |  
| VPC 만들기 | `aws ec2 create-vpc` |  
| Subnet 만들기 | `aws ec2 create-subnet` |  
| 인터넷 출입구 만들기 | `aws ec2 create-internet-gateway` |  
| 인터넷 Route 만들기 | `aws ec2 create-route` |  
| 방화벽 만들기 | `aws ec2 create-security-group` |  
| Port 허용하기 | `aws ec2 authorize-security-group-ingress` |  
| SSH Key 만들기 | `aws ec2 create-key-pair` |  
| Ubuntu AMI 찾기 | `aws ec2 describe-images` |  
| EC2 만들기 | `aws ec2 run-instances` |  
| EC2 접속하기 | `ssh -i` |  
| Nginx 설치하기 | `sudo apt install -y nginx` |  
| 웹 응답 확인하기 | `curl -i` |  
| Nginx Log 보기 | `sudo journalctl -u nginx` |  
| EC2 삭제하기 | `aws ec2 terminate-instances` |  
| VPC 삭제하기 | `aws ec2 delete-vpc` |  









<br><br>

## 🟢 보안상 실행하면 안 되는 명령 예시  

```bash
# 금지: AWS Credentials 파일에는 Secret Access Key가 들어 있으므로 출력하지 않는다.  
# cat "$HOME/.aws/credentials"  

# 금지: EC2 Private Key 내용이 외부에 노출되므로 출력하지 않는다.  
# cat "$KEY_FILE"  

# 금지: SSH 22번 Port를 전 세계에 공개하지 않는다.  
# aws ec2 authorize-security-group-ingress --port 22 --cidr 0.0.0.0/0  

# 금지: 대상 ID를 확인하지 않은 삭제 명령을 실행하지 않는다.  
# aws ec2 delete-vpc --vpc-id "$VPC_ID"  
```

주석을 제거해서 실행하면 안 된다.  
