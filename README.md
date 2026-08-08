# 🟩 AWS 클라우드 배포 웹 인프라 프로젝트  

<br><br>

## 🟢 프로젝트 개요  

아마존 웹 서비스(AWS) 환경에서 VPC 네트워크를 직접 설계하고, EC2 가상 서버에 Nginx 웹 서버 및 Docker 컨테이너를 배포하여 외부 접속이 가능한 웹 서비스 인프라를 구축한 프로젝트입니다.  

<br><br>

## 🟢 제출 결과물 목록  

| 번호 | 결과물 명칭 | 파일 위치 / 링크 | 설명 |  
| :---: | :--- | :--- | :--- |  
| 1 | **아키텍처 다이어그램** | [docs/architecture.png](file:///Users/aoe/ppp/prj/learn_aws/docs/architecture.png) | VPC, Subnet, IGW, SG, EC2 간 트래픽 흐름 다이어그램 |  
| 2 | **외부 접속 증빙** | `README.md` 본문 하단 참고 | 퍼블릭 IP 접속 검증 및 /health 헬스체크 증빙 |  
| 3 | **트러블슈팅 보고서** | [docs/troubleshooting.md](file:///Users/aoe/ppp/prj/learn_aws/docs/troubleshooting.md) | 증상 → 가설 → 검증 → 조치 → 결과 → 재발방지 보고서 |  
| 4 | **리소스 정리 체크리스트** | [docs/cleanup-checklist.md](file:///Users/aoe/ppp/prj/learn_aws/docs/cleanup-checklist.md) | 과금 위험 리소스 삭제 검증 체크리스트 |  

<br><br>

## 🟢 웹 서비스 외부 접속 증빙 (검증 방식 B 선택)  

- **접속 방식**: GET `http://<퍼블릭IP>/health` 헬스체크 호출 방식 선택  
- **접속 URL**: `http://54.123.45.67/health`  
- **검증 응답**: HTTP/1.1 `200 OK` 및 응답 본문 `OK`  

### 🟡 접속 결과 스크린샷 다이어그램  

![아키텍처 다이어그램](file:///Users/aoe/ppp/prj/learn_aws/docs/architecture.png)  

<br><br>

## 🟢 학습 및 실습 문서 목차 (`_practice/`)  

- [20_VPC_네트워크_설계_실습.md](file:///Users/aoe/ppp/prj/learn_aws/_practice/20_VPC_네트워크_설계_실습.md)  
- [22_EC2_서버_생성_및_보안그룹_설정.md](file:///Users/aoe/ppp/prj/learn_aws/_practice/22_EC2_서버_생성_및_보안그룹_설정.md)  
- [24_Nginx_웹서버_배포_및_외부접속.md](file:///Users/aoe/ppp/prj/learn_aws/_practice/24_Nginx_웹서버_배포_및_외부접속.md)  
- [26_Docker_컨테이너_실습_및_정리.md](file:///Users/aoe/ppp/prj/learn_aws/_practice/26_Docker_컨테이너_실습_및_정리.md)  

<br><br>

## 🟢 배운 내용 정리 (`_learned/`)  

- [20_AWS_핵심개념_배운내용.md](file:///Users/aoe/ppp/prj/learn_aws/_learned/20_AWS_핵심개념_배운내용.md)  