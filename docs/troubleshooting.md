# 🟩 트러블슈팅 보고서  

<br><br>

## 🟢 1. EC2 인스턴스 SSH 원격 접속 불가 트러블슈팅  

| 구분 | 내용 |  
| :--- | :--- |  
| **증상 (Problem)** | EC2 인스턴스 생성 후 SSH(Port 22)로 원격 접속 시 타임아웃(Connection timed out) 에러가 발생하며 접속 불가능 |  
| **원인 가설 (Hypothesis)** | 보안 그룹(Security Group) 인바운드 규칙에 SSH(22 포트) 허용 규칙이 없거나, 소스 IP 대역이 내 접속 위치와 다르게 설정되어 있음 |  
| **검증 방법 (Verification)** | 1. AWS 콘솔에서 인스턴스에 적용된 보안 그룹(Security Group) 상세 인바운드 규칙 조회<br>2. `curl ifconfig.me` 명령으로 현재 내 컴퓨터의 공인 IP 주소 확인 및 비교 |  
| **조치 내용 (Action)** | 해당 인스턴스의 보안 그룹 인바운드 규칙에서 `SSH (Port 22)`의 소스 IP를 기존 규칙에서 현재 개인 IP (`x.x.x.x/32`)로 수정 |  
| **결과 (Result)** | 터미널에서 `ssh -i key.pem ubuntu@<Public IP>` 실행 시 암호화 연결 정상 성공 |  
| **재발 방지 (Prevention)** | EC2 인스턴스 배포 시 사전 보안 체크리스트 항목에 "SSH 22번 포트 소스 IP 지정 규칙"을 필수 검증 항목으로 명시 |  

<br><br>

## 🟢 2. 외부 브라우저 접속 타임아웃 트러블슈팅  

| 구분 | 내용 |  
| :--- | :--- |  
| **증상 (Problem)** | EC2 인스턴스 내부에서는 `curl http://localhost` 200 OK 응답을 받으나, 외부 인터넷 브라우저 접속 시 연결 불가 |  
| **원인 가설 (Hypothesis)** | 1. Public Subnet의 라우팅 테이블(Route Table)에 Internet Gateway(IGW) 경로 missing<br>2. 보안 그룹(Security Group)에서 HTTP(80 포트) 인바운드가 열려있지 않음 |  
| **검증 방법 (Verification)** | 1. Route Table 엔트리에 `0.0.0.0/0 -> igw-xxxx` 존재 여부 확인<br>2. Security Group 인바운드에 `HTTP 80 0.0.0.0/0` 허용 여부 체크 |  
| **조치 내용 (Action)** | Route Table에 Internet Gateway 연결 추가 및 Security Group HTTP 80 포트 인바운드 허용 추가 |  
| **결과 (Result)** | 외부 브라우저 및 `curl http://<퍼블릭IP>` 실행 시 Nginx 200 OK 정상 응답 확인 |  
| **재발 방지 (Prevention)** | 퍼블릭 서브넷 구성 자동화 스크립트 작성 시 IGW 라우팅 연동 모듈을 상시 포함 |  
