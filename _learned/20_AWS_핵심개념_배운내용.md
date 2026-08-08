# 🟩 AWS 클라우드 웹 인프라 배포 핵심 배운 내용  

<br><br>

## 🟢 배운 내용 요약  

- **VPC, Subnet, Route Table, Internet Gateway의 역할 및 트래픽 흐름**:  
    - VPC는 물리적 서버실 대신 클라우드 내에 나만의 전용 격리 공간을 만드는 단위이다.  
    - Internet Gateway를 통해 외부 인터넷 트래픽이 VPC 내부로 인입되며, Route Table의 라우팅 이정표(`0.0.0.0/0 -> IGW`)를 통해 Public Subnet으로 전송된다.  
- **Security Group과 IAM의 차이점 및 최소권한 원칙**:  
    - Security Group은 네트워크 트래픽(포트 및 IP)을 차단/허용하는 가상 방화벽이다.  
    - IAM은 AWS 사용자/서비스가 어떤 제어 권한(생성, 수정, 삭제)을 가지는지 관리하는 보안 통제 도구이다.  
    - 운영/관리용 포트(SSH 22)는 보안을 위해 사용자 개인 IP로만 한정하여 최소 권한을 유지한다.  
- **외부 접속 경로 설정 필수 요소**:  
    - Public IP + Route Table(IGW 바인딩) + Security Group(HTTP 80포트 인바운드 허용)  
- **리소스 과금 방지 및 안전 정리 체계**:  
    - 미사용 중인 EC2, EBS, Elastic IP, IGW, VPC는 실습 종료 즉시 삭제하여 비용 청구를 방지한다.  
