# 🟩 고도화 구현 검증 기록

## 🟢 확인한 환경

| 항목 | 확인 값 |
| --- | --- |
| 호스트 | Apple Silicon macOS |
| Docker 엔진 | Linux aarch64 |
| Docker Compose | v5.5.1 |
| 실행 이미지 | Ubuntu 24.04, AWS CLI 2.36.44 |
| ARM64 | 실제 Docker Linux ARM64 이미지 빌드·실행 |
| AMD64 | 이 Mac의 Docker 에뮬레이션. 실제 AMD64 PC 검증과 구분 |
| Windows·PowerShell | 파일 작성과 내용 검토 완료, 실제 실행 미검증 |
| 실제 AWS | 인증·생성·변경·삭제·SSH·웹 요청 모두 미실행 |

<br><br>

## 🟢 확인된 결과

| 검사 | 결과 |
| --- | --- |
| 최종 ARM64 모의 테스트 | 20개 통과 |
| 최종 AMD64 에뮬레이션 모의 테스트 | 20개 통과, 약 308초 |
| Compose 비관리자·읽기 전용·권한 제한 모의 테스트 | 20개 통과 |
| 생성 JSON 입력 형식 | 실제 AWS CLI에서 7개 통과, 네트워크 차단 |
| 공식 Compose help | 성공, AWS 호출 없음 |
| runtime 쓰기 | 빈 임시 폴더 생성·삭제 성공 |
| Git 제외·줄바꿈 | 사용자 설정·인증·runtime 제외, Bash LF·PowerShell CRLF 속성 확인 |

## 🟢 검증 범위

- Bash 문법 검사와 ShellCheck warning 이상 검사.
- 가짜 AWS·SSH·curl·ssh-keygen을 PATH에 연결한 모의 테스트.
- 네트워크가 없는 Ubuntu에서 실제 AWS CLI의 생성 JSON 7개를 skeleton output으로 입력 검증.
- 도움말은 실제 Compose 서비스로 실행하고 AWS 요청 없이 성공.
- runtime에는 비밀정보 없이 빈 폴더를 만들고 즉시 제거해서 비관리자 쓰기 권한 확인.
- Git 제외 규칙과 줄바꿈 속성 확인.
- 작성한 실행 코드의 줄별 쉬운 주석과 개인 사용자 경로 제외 확인.

Docker Compose의 비관리자·읽기 전용·cap_drop·권한 상승 금지 제한을 유지한 검증도 별도로 수행한다. 이 검증은 네트워크를 차단하고, 가짜 실행 파일을 위한 `/lab-tests` 임시 실행 경로만 추가한다. 실제 서비스 `/tmp`의 noexec 제한은 유지한다. 테스트용 인증·키·상태는 모두 가짜이며 임시 폴더 종료 시 제거한다.

<br><br>

## 🟢 테스트가 확인하는 동작

| 범위 | 확인 내용 |
| --- | --- |
| 진입점 | help의 AWS 접근 없음, 잘못된 명령·옵션 실패 |
| 설정 | 필수 설정 누락, 잘못된 CIDR·전체 공개 SSH 차단 |
| 인증 | 예상 계정 불일치 후 EC2 호출 없음 |
| 출력 | 실제 실패 코드 유지, stdout 분리, 비TTY ANSI 없음, 단계 간격 |
| 조회 | 미생성과 조회 실패 구분, 중복·타 소유 응답 중단 |
| 생성 | 전체 생성, 동일 설정 재사용, ConfigHash 불일치 중단 |
| 응답 실패 | 생성 직후 Timeout 기록, 재시도 차단, 중복 생성 없음 |
| 키 보호 | 개인키 화면·상태파일 노출 없음, 유실 시 신규 서버 생성 중단 |
| 동시 실행 | 타 실행 잠금 보존·변경 중단 |
| 웹 검사 | 내부·외부 정상 응답, 잘못된 본문·Redirect 실패 |
| 정리 | DELETE 확인, 취소 시 서버 보존, 삭제 재실행·잔여 확인 |
| 연결 보호 | 타 Subnet 연결 발견 시 서버 종료·경로 해제 전 중단 |
| Wrapper | Bash Wrapper의 동일 서비스·인자 경계·Docker 종료 코드 |
| AWS 입력 | 실제 AWS CLI가 생성 JSON 형식을 받아들이는지 오프라인 확인 |

<br><br>

## 🟢 검사 과정에서 해결한 문제

- ShellCheck가 기본 Locale에서 한국어 주석을 출력하지 못해 검사 진입점에 C.UTF-8을 지정했다.
- AMD64 에뮬레이션에서 초기 30초 테스트 제한이 짧아 시간 초과가 발생했다. 모의 명령의 제한을 180초로 조정하고 시간 초과 프로세스 종료 처리도 추가했다.
- /tmp 실행 금지 때문에 공식 Compose 제한에서 가짜 도구가 실행되지 않았다. 실제 서비스의 제한은 유지하고 모의 도구 전용 임시 실행 경로를 분리했다. 재현용 설정은 tests/compose.offline.yaml에 저장했다.
- 공식 이미지 저장소의 인증 토큰 요청이 한 번 Timeout으로 실패했다. 빌드에서 확인한 공식 multi-architecture Digest를 고정해 이후 빌드를 완료했다.

<br><br>

## 🟢 남아 있는 실제 검증

실제 AWS의 IAM 허용 여부, EC2 생성·SSH Fingerprint 확인·Nginx 설치·외부 접속·삭제 완료는 검증하지 않았다. 모의 응답과 skeleton 검사는 이 항목을 증명하지 않는다. Windows PowerShell/CMD와 실제 Linux·AMD64 호스트에서도 별도 실행 검증이 필요하다.
