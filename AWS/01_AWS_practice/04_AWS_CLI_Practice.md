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





<br>

### 🟡 실제 log  

```bash


xxx@xxx ~ % nc -vz "$PUBLIC_IP" 22  
Connection to 43.201.150.176 port 22 [tcp/ssh] succeeded!  

xxx@xxx ~ % ssh -i "$KEY_FILE" ubuntu@"$PUBLIC_IP"  
The authenticity of host '43.201.150.176 (43.201.150.176)' can't be established.  
ED25519 key fingerprint is SHA256:3134f1230w/873dw8aWA3n9123214ef3f1M.  
This key is not known by any other names.  
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes  
Warning: Permanently added '43.201.150.176' (ED25519) to the list of known hosts.  
Welcome to Ubuntu 24.04.5 LTS (GNU/Linux 7.0.0-1013-aws x86_64)  

 * Documentation:  https://help.ubuntu.com  
 * Management:     https://landscape.canonical.com  
 * Support:        https://ubuntu.com/pro  

 System information as of Thu Oct  1 10:46:09 UTC 2026  

  System load:  0.0               Temperature:           -273.1 C  
  Usage of /:   29.8% of 6.71GB   Processes:             119  
  Memory usage: 25%               Users logged in:       0  
  Swap usage:   0%                IPv4 address for ens5: 10.0.1.68  

Expanded Security Maintenance for Applications is not enabled.  

0 updates can be applied immediately.  

Enable ESM Apps to receive additional future security updates.  
See https://ubuntu.com/esm or run: sudo pro status  


The list of available updates is more than a week old.  
To check for new updates run: sudo apt update  


The programs included with the Ubuntu system are free software;  
the exact distribution terms for each program are described in the  
individual files in /usr/share/doc/*/copyright.  

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by  
applicable law.  

To run a command as administrator (user "root"), use "sudo <command>".  
See "man sudo_root" for details.  

ubuntu@ip-10-0-1-68:~$  


```










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


<br>

### 🟡 실제 log  

```bash

ubuntu@ip-10-0-1-68:~$ whoami  
ubuntu  

ubuntu@ip-10-0-1-68:~$ hostname  
ip-10-0-1-68  

ubuntu@ip-10-0-1-68:~$ curl -I https://example.com  
HTTP/2 200  
date: Thu, 01 Oct 2026 10:47:54 GMT  
content-type: text/html; charset=utf-8  
server: cloudflare  
last-modified: Mon, 28 Sep 2026 16:19:32 GMT  
allow: GET, HEAD  
accept-ranges: bytes  
age: 8202  
cf-cache-status: HIT  
cf-ray: a43ae4545debf364-ICN  

ubuntu@ip-10-0-1-68:~$ sudo apt install -y nginx  
Reading package lists... Done  
Building dependency tree... Done  
Reading state information... Done  
The following additional packages will be installed:  
  nginx-common  
Suggested packages:  
  fcgiwrap nginx-doc ssl-cert  
The following NEW packages will be installed:  
  nginx nginx-common  
0 upgraded, 2 newly installed, 0 to remove and 19 not upgraded.  
Need to get 570 kB of archives.  

ubuntu@ip-10-0-1-68:~$ sudo systemctl enable --now nginx  
Synchronizing state of nginx.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.  
Executing: /usr/lib/systemd/systemd-sysv-install enable nginx  

ubuntu@ip-10-0-1-68:~$ sudo systemctl status nginx --no-pager  
● nginx.service - A high performance web server and a reverse proxy server  
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: enabled)  
     Active: active (running) since Thu 2026-10-01 10:48:28 UTC; 39s ago  
       Docs: man:nginx(8)  
   Main PID: 1757 (nginx)  
      Tasks: 3 (limit: 627)  
     Memory: 2.4M (peak: 5.2M)  
        CPU: 27ms  
     CGroup: /system.slice/nginx.service  
             ├─1757 "nginx: master process /usr/sbin/nginx -g daemon on; master_process on;"  
             ├─1760 "nginx: worker process"  
             └─1761 "nginx: worker process"  
Oct 01 10:48:28 ip-10-0-1-68 systemd[1]: Starting nginx.service - A high performance web server and a rev…rver...  
Oct 01 10:48:28 ip-10-0-1-68 systemd[1]: Started nginx.service - A high performance web server and a reve…server.  
Hint: Some lines were ellipsized, use -l to show in full.  

ubuntu@ip-10-0-1-68:~$ sudo ss -lntp | grep ':80'  
LISTEN 0      511          0.0.0.0:80        0.0.0.0:*    users:(("nginx",pid=1761,fd=5),("nginx",pid=1760,fd=5),("nginx",pid=1757,fd=5))  
LISTEN 0      511             [::]:80           [::]:*    users:(("nginx",pid=1761,fd=6),("nginx",pid=1760,fd=6),("nginx",pid=1757,fd=6))  

ubuntu@ip-10-0-1-68:~$ printf 'OK\n' | sudo tee /var/www/html/health >/dev/null  

ubuntu@ip-10-0-1-68:~$ curl -i http://localhost/health  
HTTP/1.1 200 OK  
Server: nginx/1.24.0 (Ubuntu)  
Date: Thu, 01 Oct 2026 10:51:24 GMT  
Content-Type: application/octet-stream  
Content-Length: 3  
Last-Modified: Thu, 01 Oct 2026 10:50:10 GMT  
Connection: keep-alive  
ETag: "6abe3ae2-3"  
Accept-Ranges: bytes  

OK  



```















<br><br><br>

## 🟢 17단계: Mac에서 외부 접속 검증  

```bash
# Exit: SSH Session을 종료하고 Mac Terminal로 돌아간다.  
exit  

# Netcat: 외부에서 EC2 HTTP 80번 Port에 연결되는지 확인한다.  
nc -vz "$PUBLIC_IP" 80  

# Client URL: Mac에서 EC2 /health를 호출한다.  
curl --connect-timeout 5 -i "http://${PUBLIC_IP}/health"  

# 실제 브라우저로 들어가도 ok가 나오는 것을 확인할 수 있다.  
http://43.201.150.176/health  
```

<br>

### 🟡 명령 의미  

| 명령·옵션 | 의미 |  
| :--- | :--- |
| `exit` | SSH Session 종료 |  
| `--connect-timeout 5` | 연결을 최대 5초만 기다림 |  
| `${PUBLIC_IP}` | Public IP 변수값을 URL 안에 사용 |  

외부 `curl`의 `200 OK`와 `OK` 결과가 외부 접속 검증 방식 B의 증빙이다.  


<br>

### 🟡 실제 log  

```bash

xxx@xxx ~ % nc -vz "$PUBLIC_IP" 80  
Connection to 43.201.150.176 port 80 [tcp/http] succeeded!  


xxx@xxx ~ % curl --connect-timeout 5 -i "http://${PUBLIC_IP}/health"  
HTTP/1.1 200 OK  
Server: nginx/1.24.0 (Ubuntu)  
Date: Thu, 01 Oct 2026 10:52:55 GMT  
Content-Type: application/octet-stream  
Content-Length: 3  
Last-Modified: Thu, 01 Oct 2026 10:50:10 GMT  
Connection: keep-alive  
ETag: "6abe3ae2-3"  
Accept-Ranges: bytes  

OK  


```








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



<br>

### 🟡 실제 log  

```bash

xxx@xxx ~ % aws ec2 describe-subnets --subnet-ids "$SUBNET_ID" --query 'Subnets[0].[VpcId,SubnetId,CidrBlock,AvailabilityZone,MapPublicIpOnLaunch]' --output table --profile "$PROFILE" --region "$REGION"  
------------------------------
|       DescribeSubnets      |  
+----------------------------+  
|  vpc-08c23771d133a47ae     |  
|  subnet-0b12ed582eeb6653f  |  
|  10.0.1.0/24               |  
|  ap-northeast-2a           |  
|  True                      |  
+----------------------------+  

xxx@xxx ~ % aws ec2 describe-route-tables --route-table-ids "$RT_ID" --query 'RouteTables[0].[Routes,Associations]' --output json --profile "$PROFILE" --region "$REGION"  
[  
    [  
        {  
            "DestinationCidrBlock": "10.0.0.0/16",  
            "GatewayId": "local",  
            "Origin": "CreateRouteTable",  
            "State": "active"  
        },  
        {  
            "DestinationCidrBlock": "0.0.0.0/0",  
            "GatewayId": "igw-04cf6607b7dacf774",  
            "Origin": "CreateRoute",  
            "State": "active"  
        }  
    ],  
    [  
        {  
            "Main": false,  
            "RouteTableAssociationId": "rtbassoc-01dcbdc3f2839f36f",  
            "RouteTableId": "rtb-0946c365525d63f0c",  
            "SubnetId": "subnet-0b12ed582eeb6653f",  
            "AssociationState": {  
                "State": "associated"  
            }  
        }  
    ]  
]  

xxx@xxx ~ % aws ec2 describe-security-group-rules --filters "Name=group-id,Values=$SG_ID" --query 'SecurityGroupRules[?IsEgress==`false`].[IpProtocol,FromPort,ToPort,CidrIpv4]' --output table --profile "$PROFILE" --region "$REGION"  
------------------------------------------
|       DescribeSecurityGroupRules       |  
+-----+-----+-----+----------------------+  
|  tcp|  22 |  22 |  121.135.181.46/32   |  
|  tcp|  80 |  80 |  0.0.0.0/0           |  
+-----+-----+-----+----------------------+  

xxx@xxx ~ % aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].[InstanceId,State.Name,PublicIpAddress,VpcId,SubnetId]' --output table --profile "$PROFILE" --region "$REGION"  
------------------------------
|      DescribeInstances     |  
+----------------------------+  
|  i-04f7febaed27571c8       |  
|  running                   |  
|  43.201.150.176            |  
|  vpc-08c23771d133a47ae     |  
|  subnet-0b12ed582eeb6653f  |  
+----------------------------+  
```
















<br><br><br>

## 🟢 19단계: 안전한 트러블슈팅 실습  

> 위험한 Security Group 규칙을 만들지 않는다. Nginx만 잠시 중지해 실제 장애를 재현한다.  

```bash
# Secure Shell: Ubuntu EC2에 다시 접속한다.  
ssh -i "$KEY_FILE" ubuntu@"$PUBLIC_IP"  

# System Control: Nginx만 잠시 중지한다.  
sudo systemctl stop nginx  

# System Control: Nginx가 inactive 상태인지 확인한다.  
sudo systemctl status nginx --no-pager  

# Client URL: localhost 요청이 실패하는지 확인한다.  
curl --connect-timeout 5 -i http://localhost/health  

# Client URL: Mac 외부에서도 실패하는지 확인한다.  
curl --connect-timeout 5 -i "http://${PUBLIC_IP}/health"  

xxx@xxxs3 ~ % curl --connect-timeout 5 -i "http://${PUBLIC_IP}/health"  
# curl: (7) Failed to connect to 43.201.150.176 port 80 after 5 ms: Couldn't connect to server  

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







<br>

### 🟡 실제 log  

```bash
Last login: Thu Oct  1 10:46:10 2026 from 121.135.181.46  


ubuntu@ip-10-0-1-68:~$ sudo systemctl stop nginx  


ubuntu@ip-10-0-1-68:~$ sudo systemctl status nginx --no-pager  
○ nginx.service - A high performance web server and a reverse proxy server  
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: enabled)  
     Active: inactive (dead) since Thu 2026-10-01 11:05:11 UTC; 3s ago  
   Duration: 16min 43.401s  
       Docs: man:nginx(8)  
    Process: 2073 ExecStop=/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx.pid (code=exited, status=0/SUCCESS)  
   Main PID: 1757 (code=exited, status=0/SUCCESS)  
        CPU: 34ms  

Oct 01 10:48:28 ip-10-0-1-68 systemd[1]: Starting nginx.service - A high performance web server and a reve…rver...  
Oct 01 10:48:28 ip-10-0-1-68 systemd[1]: Started nginx.service - A high performance web server and a rever…server.  
Oct 01 11:05:11 ip-10-0-1-68 systemd[1]: Stopping nginx.service - A high performance web server and a reve…rver...  
Oct 01 11:05:11 ip-10-0-1-68 systemd[1]: nginx.service: Deactivated successfully.  
Oct 01 11:05:11 ip-10-0-1-68 systemd[1]: Stopped nginx.service - A high performance web server and a rever…server.  
Hint: Some lines were ellipsized, use -l to show in full.  


ubuntu@ip-10-0-1-68:~$ curl --connect-timeout 5 -i http://localhost/health  
curl: (7) Failed to connect to localhost port 80 after 0 ms: Couldn't connect to server  



xxx@xxx ~ % curl --connect-timeout 5 -i "http://${PUBLIC_IP}/health"  
curl: (7) Failed to connect to 43.201.150.176 port 80 after 5 ms: Couldn't connect to server  


ubuntu@ip-10-0-1-68:~$ sudo systemctl start nginx  


ubuntu@ip-10-0-1-68:~$ sudo systemctl status nginx --no-pager  
● nginx.service - A high performance web server and a reverse proxy server  
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: enabled)  
     Active: active (running) since Thu 2026-10-01 11:08:03 UTC; 11s ago  
       Docs: man:nginx(8)  
    Process: 2088 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)  
    Process: 2090 ExecStart=/usr/sbin/nginx -g daemon on; master_process on; (code=exited, status=0/SUCCESS)  
   Main PID: 2091 (nginx)  
      Tasks: 3 (limit: 627)  
     Memory: 2.7M (peak: 2.7M)  
        CPU: 17ms  
     CGroup: /system.slice/nginx.service  
             ├─2091 "nginx: master process /usr/sbin/nginx -g daemon on; master_process on;"  
             ├─2092 "nginx: worker process"  
             └─2093 "nginx: worker process"  

Oct 01 11:08:03 ip-10-0-1-68 systemd[1]: Starting nginx.service - A high performance web server and a reve…rver...  
Oct 01 11:08:03 ip-10-0-1-68 systemd[1]: Started nginx.service - A high performance web server and a rever…server.  
Hint: Some lines were ellipsized, use -l to show in full.  


ubuntu@ip-10-0-1-68:~$ curl --connect-timeout 5 -i http://localhost/health  
HTTP/1.1 200 OK  
Server: nginx/1.24.0 (Ubuntu)  
Date: Thu, 01 Oct 2026 11:08:23 GMT  
Content-Type: application/octet-stream  
Content-Length: 3  
Last-Modified: Thu, 01 Oct 2026 10:50:10 GMT  
Connection: keep-alive  
ETag: "6abe3ae2-3"  
Accept-Ranges: bytes  

OK  


ubuntu@ip-10-0-1-68:~$ sudo journalctl -u nginx -n 30 --no-pager  
Oct 01 10:48:28 ip-10-0-1-68 systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...  
Oct 01 10:48:28 ip-10-0-1-68 systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.  
Oct 01 11:05:11 ip-10-0-1-68 systemd[1]: Stopping nginx.service - A high performance web server and a reverse proxy server...  
Oct 01 11:05:11 ip-10-0-1-68 systemd[1]: nginx.service: Deactivated successfully.  
Oct 01 11:05:11 ip-10-0-1-68 systemd[1]: Stopped nginx.service - A high performance web server and a reverse proxy server.  
Oct 01 11:08:03 ip-10-0-1-68 systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...  
Oct 01 11:08:03 ip-10-0-1-68 systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.  





xxx@xxx ~ % curl --connect-timeout 5 -i "http://${PUBLIC_IP}/health"  
HTTP/1.1 200 OK  
Server: nginx/1.24.0 (Ubuntu)  
Date: Thu, 01 Oct 2026 11:08:47 GMT  
Content-Type: application/octet-stream  
Content-Length: 3  
Last-Modified: Thu, 01 Oct 2026 10:50:10 GMT  
Connection: keep-alive  
ETag: "6abe3ae2-3"  
Accept-Ranges: bytes  

OK  
```









<br><br><br>

## 🟢 20단계: Terminal을 닫았을 때 ID 복구  

> 만약 나의 terminal이 종료되었다면 다시 복구할 수 있습니다. 이렇게 할 수 있다는 것을 알아두면 됩니다.  
> 2단계 공통 변수를 다시 설정한 뒤 Tag로 ID를 찾는다.  

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


