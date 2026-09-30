# 🟩 AWS 클라우드 리소스 정리 체크리스트  

<br><br>

## 🟢 목적  

실습 완료 후 불필요한 클라우드 리소스가 남아 과금이 발생하는 것을 원천 차단하기 위해 아래 체크리스트 순서대로 리소스를 삭제/정리합니다.  

<br><br>

## 🟢 삭제 및 정리 체크리스트  

| 순서 | 대상 리소스 | 확인 항목 및 작업 내용 | 삭제 여부 (상태) |  
| :---: | :--- | :--- | :---: |  
| 1 | **EC2 인스턴스** | EC2 인스턴스 선택 -> Instance State -> Terminate (종료) 확인 | `[v] 완료 (Terminated)` |  
| 2 | **EBS 볼륨** | 미사용 EBS(Elastic Block Store) 볼륨 잔존 여부 확인 및 Delete Volume | `[v] 완료 (Deleted)` |  
| 3 | **Elastic IP (EIP)** | 할당받은 탄력적 IP(Elastic IP) Release (해제) 확인 | `[v] 완료 (Released)` |  
| 4 | **Internet Gateway** | VPC에서 Detach 후 Internet Gateway 삭제 완료 | `[v] 완료 (Deleted)` |  
| 5 | **Subnet / Route Table** | 서브넷 및 라우트 테이블 연동 해제 후 삭제 | `[v] 완료 (Deleted)` |  
| 6 | **VPC** | 최종 VPC(Virtual Private Cloud) 삭제 확인 | `[v] 완료 (Deleted)` |  
| 7 | **Billing Dashboard** | AWS Billing & Cost Management 메뉴 접속 후 잔여 요금 발생 여부 최종 검증 | `[v] 완료 (Confirmed)` |  
