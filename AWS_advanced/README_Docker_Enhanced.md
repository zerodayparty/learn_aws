# 🟩 AWS 실습 고도화 사용 설명서  

## 🟢 1. 하는 일  

Ubuntu 컨테이너 안의 Bash와 AWS CLI로 실습용 VPC, Public Subnet, Internet Gateway, Route Table, Security Group, Key Pair, EC2를 준비한다. 웹 서버는 EC2의 Ubuntu에 Nginx로 설치한다.  

- 공식 실행 위치는 `AWS_advanced/`다.  
- 실제 `up`은 AWS 리소스를 만들고 비용이 생길 수 있다. 무료 여부는 계정의 현재 혜택으로 확인해야 한다.  
- 기존 수동 실습 리소스는 자동 인수하지 않는다. `Project`, `LabId`, `ManagedBy=aws-lab` Tag가 모두 맞는 대상만 관리한다.  
- 조회가 실패하면 없는 리소스로 처리하지 않는다. 생성 도중 실패해도 이미 만든 리소스를 자동 삭제하지 않는다.  
- 학습은 `_practice/20_AWS_고도화_수동_컨테이너.md`부터 시작한다. Dockerfile·Compose는 30번에서 마지막에 직접 작성한다.  

<br><br>

## 🟢 2. 지원 조건  

| 항목 | 기준 |  
| --- | --- |
| 호스트 | Docker의 Linux 컨테이너 실행 환경 |  
| Compose | v2.24.0 이상, env_file의 required 지원 필요 |  
| 컨테이너 | Ubuntu 24.04, Bash, AWS CLI 2.36.44, jq, Python 3, OpenSSH, curl |  
| 인증 | 실습 전용 파일 기반 AWS 프로필. SSO·별도 Role 전환 미지원 |  
| AWS 서버 | 서울 리전 Canonical Ubuntu EBS AMI, t2.micro·t3.micro·t4g.micro 중 호환 선택 |  
| 저장소 | 루트 EBS 10GiB gp3, 암호화, EC2 종료 시 삭제 |  
| 명령 옵션 | up·status·health·ssh·down·help만 지원, 추가 옵션은 실패 |  
| 첫 생성 | 대화형 입력 필요. SSH 호스트 키를 직접 확인 |  
| 삭제 | 대화형 DELETE 확인 필요, 자동 승인 옵션 미지원 |  

CLI는 Command Line Interface, SSO는 Single Sign-On, EBS는 Elastic Block Store, AMI는 Amazon Machine Image다. 호스트 Docker CPU와 AWS EC2 CPU는 별개다.  

Ubuntu와 AWS 공식 이미지로 제작한다. 공식 AWS 이미지의 설치 경로를 복사하는 부분은 [AWS Dockerfile](https://github.com/aws/aws-cli/blob/v2/docker/Dockerfile)을 참고했다. 공식 이미지의 버전 사용 기준은 [AWS 문서](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-docker.html)를 따른다. Ubuntu 패키지는 빌드 시 보안 업데이트를 포함하므로 패키지 전체가 byte 단위로 고정된 빌드는 아니다.  

<br><br>

## 🟢 3. 최초 준비  

### 🟡 Bash 준비 명령  

```bash
cd AWS_advanced # change directory: 저장소 루트에서 고도화 폴더로 이동한다.  
mkdir -p config/aws runtime # make directory: 필요한 부모 폴더까지 만든다.  
cp config/aws-basic-lab.env.example config/aws-basic-lab.env # copy: 비밀값 없는 예시를 사용자 설정으로 복사한다. 기존 설정이 있으면 덮어쓰지 말고 직접 편집한다.  
```

Linux에서는 연결한 파일을 자신의 UID/GID로 사용할 수 있도록 아래 값을 해당 터미널에 설정한다. UID는 User Identifier, GID는 Group Identifier다. 이 두 값은 파일 권한에만 사용하고 AWS 대상에는 영향을 주지 않는다.  

```bash
export LAB_UID="$(id -u)" # id의 user 옵션: 현재 Linux 사용자 번호를 Docker 실행 사용자로 지정한다.  
export LAB_GID="$(id -g)" # id의 group 옵션: 현재 Linux 그룹 번호를 지정한다.  
```

macOS·Windows Docker Desktop은 기본 1000:1000으로 사용한다. 쓰기 권한 오류가 있으면 호스트 공유 폴더 설정과 소유권을 확인한다. `runtime` 전체를 모두에게 공개하지 않는다.  

### 🟡 PowerShell 준비 명령  

```powershell
Set-Location AWS_advanced # 현재 위치를 고도화 폴더로 바꾼다.  
New-Item -ItemType Directory -Force config/aws, runtime | Out-Null # 필요한 폴더를 만들고 출력은 줄인다.  
Copy-Item config/aws-basic-lab.env.example config/aws-basic-lab.env # 예시를 복사한다. 기존 설정이 있으면 덮어쓰지 않는다.  
```

CMD 사용자도 같은 두 폴더와 설정 파일을 준비하면 이후 공식 Docker 명령을 그대로 사용할 수 있다.  

### 🟡 설정과 인증 파일 작성  

`config/aws-basic-lab.env`를 편집해서 `EXPECTED_ACCOUNT_ID`, `SSH_ALLOWED_CIDR`, `AMI_ID`의 빈 값을 채운다. 설정 예시에 모든 변수 설명이 있다. SSH 허용 주소는 자신의 현재 인터넷 IPv4와 `/32`다. AMI는 서울 리전의 Canonical Ubuntu LTS를 직접 확인해서 선택한다. LTS는 Long Term Support다.  

`config/aws/config`에는 프로필 section `[profile aws-basic]`와 `region = ap-northeast-2`를 준비한다. `config/aws/credentials`에는 `[aws-basic]`와 실제 Access Key·Secret Key를 직접 입력한다. 임시 인증이면 Session Token도 필요하다. 이 문서나 채팅에 인증값을 붙여넣지 않는다. 다른 프로필을 쓰면 환경파일의 `AWS_PROFILE`도 일치시킨다.  

- 기존 호스트 인증 폴더 전체를 복사하지 않는다. 실습용 프로필만 준비한다.  
- 파일은 Git과 Docker 빌드에서 제외된다. 읽기 전용으로 `/run/aws`에 연결한다.  
- 인증파일에 `credential_process`, SSO, Role 전환 설정을 넣지 않는다.  
- 로그인 실패의 원문은 인증값 보호를 위해 로그에 출력하지 않는다. 프로필·키 만료·IAM 권한·네트워크를 로컬에서 확인한다.  
- 설정의 계정 ID는 소유 범위 검사에 필요하다. 화면 안내에서는 마지막 4자리만 보인다.  

Bash에서는 두 인증 파일의 읽기 권한을 제한한다. Windows에서는 해당 폴더를 자신의 사용자만 읽을 수 있도록 파일 접근 권한을 설정한다.  

```bash
chmod 700 config/aws # change mode: 인증 폴더에 다른 사용자가 들어오지 못하게 한다.  
chmod 600 config/aws/config config/aws/credentials # change mode: 인증파일을 자신의 사용자만 읽고 쓰게 한다.  
```

### 🟡 빌드와 첫 조회  

```bash
docker compose build aws-lab # Dockerfile로 도구 이미지를 만든다. AWS 리소스는 생성하지 않는다.  
docker compose run --rm aws-lab help # 인증 없이 사용법을 확인한다. config/aws와 runtime 폴더는 필요하다.  
docker compose run --rm aws-lab status # 실제 AWS 계정 일치와 실습 상태를 읽기 전용으로 조회한다.  
```

`build`는 이미지 제작, `run`은 일회성 서비스 실행, `--rm`은 종료된 컨테이너 remove다. 컨테이너 자동 삭제는 AWS 리소스 삭제를 의미하지 않는다. 이미지 빌드와 pull은 외부 이미지 저장소에 접속한다.  

<br><br>

## 🟢 4. 공식 실행 명령과 Wrapper  

### 🟡 공식 실행 명령  

```bash
docker compose run --rm aws-lab up # 실습 리소스와 Nginx를 준비하고 health를 확인한다.  
docker compose run --rm aws-lab status # Tag로 현재 상태를 조회한다.  
docker compose run --rm aws-lab health # 내부 localhost와 외부 Public IP의 HTTP 200·OK를 검사한다.  
docker compose run --rm aws-lab ssh # Ubuntu EC2에 대화형 SSH로 접속한다.  
docker compose run --rm aws-lab down # 목록을 확인하고 DELETE 입력 후 관리 대상을 정리한다.  
```

### 🟡 Wrapper 명령 : MacOS / Linux  
Bash는 `./aws-lab up`처럼 사용한다. 나머지 명령도 동일하다.  
두 Wrapper 모두 같은 Compose 서비스에 명령과 종료 코드를 그대로 전달한다.  

### 🟡 Wrapper 명령 : Windows  
PowerShell은 `.\aws-lab.ps1 up`처럼 사용한다. 나머지 명령도 동일하다.  
두 Wrapper 모두 같은 Compose 서비스에 명령과 종료 코드를 그대로 전달한다.  
PowerShell 실행 정책이 Wrapper를 막으면 공식 명령을 사용한다.  

### 🟡 설명  

- `up`은 계정·설정·기존 연결을 검사하고 단계별로 진행한다. 실패하면 다음 단계는 실행하지 않는다.  
- SSH 최초 Fingerprint는 AWS 콘솔 EC2의 시스템 로그 등에 있는 서버 호스트 키와 대조해서 승인한다. Key Pair의 개인키 Fingerprint와 서버 호스트 키 Fingerprint를 혼동하지 않는다.  
- 호스트 키가 바뀌면 접속을 중단한다. known_hosts를 무조건 지우거나 StrictHostKeyChecking을 끄지 않는다.  
- `status`의 미생성은 조회가 성공했고 대상이 없다는 뜻이다. Nginx 상태는 `health`로 확인한다.  
- `health`는 HTTP 상태와 본문을 함께 검사한다. 끝 LF만 제거하고 `OK`와 비교한다. Redirect는 성공이 아니다.  
- `down`은 EC2 종료 → 잔여 디스크·고정 IP → AWS Key Pair → Security Group → Route Table 연결·경로표 → IGW 연결·통로 → Subnet → VPC 순서다. 조회로 잔여 없음까지 확인한다.  
- 연결 중인 EBS·Elastic IP, 기본 Route Table, 다른 Subnet 연결은 자동 해제·삭제하지 않는다. 의존성 오류는 별도 원인 확인이 필요하다.  
- 상태·개인키는 `runtime/`에 남는다. AWS 삭제 후 로컬 개인키와 known_hosts는 자동 삭제하지 않는다.  
- 개인키는 화면, 일반 상태파일, 로그에 출력하지 않는다. 임시 복사본은 컨테이너 내부 `/tmp`에서 사용 후 정리한다.  

<br><br>

## 🟢 5. 실패와 복구  

| 현상 | 처리 |  
| --- | --- |
| 필수 설정 누락 | AWS 요청 전에 누락 변수 안내, 명령에 필요한 설정만 검사 |  
| 잘못된 계정·루트 계정 | 인증 확인 후 EC2 호출 중단 |  
| 같은 종류 리소스가 여러 개 | 임의 선택 중단, Tag와 실제 소유 범위를 확인 |  
| 생성 설정이 기존 ConfigHash와 다름 | 자동 교체 중단, 기존 실습을 정리하거나 새 LAB_ID로 별도 준비 |  
| AWS Key Pair는 있는데 개인키 없음 | 생성 중단, 기존 개인키를 찾거나 키·서버 복구 방법을 별도로 결정 |  
| `.pending` 파일 존재 | 생성 성공 여부가 불명확하므로 up 중단 |  
| `lock` 폴더 존재 | 다른 생성·삭제 실행과 겹치지 않도록 중단 |  
| 삭제 도중 실패 | 실패 원인을 확인한 뒤 down 재실행, 이미 삭제된 대상은 건너뜀 |  

### 🟡 잠금 복구  

`runtime/state/<계정>/<리전>/<Project>/<LabId>/lock/owner`의 컨테이너 이름과 실행 번호를 확인한다. 다른 터미널이나 다른 컴퓨터에서 같은 실습을 변경하고 있지 않은지도 확인한다. Docker 실행 목록에서 해당 작업이 끝났음을 확인한 뒤 남은 `owner`와 빈 `lock`만 지운다. 폴더가 오래됐다는 이유만으로 자동 삭제하지 않는다.  

```bash
docker ps --format '{{.Names}} {{.Status}}' # process status: 실행 중인 컨테이너 이름과 상태만 확인한다.  
```

### 🟡 불명확한 생성 요청 복구  

`status`로 현재 Tag 조회 결과를 확인한다. `.pending`은 성공 여부를 단정할 수 없는 요청 기록이다. 생성 요청 자체를 바로 다시 실행하지 않는다.  

- 관리 대상이 존재하면 가장 단순한 복구는 확인 후 `down`으로 정리하고 새로 `up`하는 방식이다.  
- 기존 대상을 보존하려면 AWS 콘솔에서 계정·리전·소유 Tag·실제 설정·중복 여부를 직접 확인해야 한다. 확인 완료 후 해당 `.pending`만 지우고 재실행한다.  
- Key Pair 응답이 끊겼다면 개인키를 다시 내려받을 수 없을 수 있다. 키를 정상이라고 처리하지 않는다.  
- AWS 조회 결과도 불명확하면 멈춘다. `.pending`을 지워 생성 요청을 반복하면 중복 과금이 발생할 수 있다.  
- EC2 요청의 Client Token은 상태 폴더에 기록한다. 이 구현은 불명확한 요청을 자동 재전송하지 않는다.  
- 생성 기록·Tag가 소실된 리소스는 자동 관리 대상에서 빠질 수 있다. Tag를 수동으로 지우지 말고, AWS 콘솔에서도 정리 대상을 확인한다.  

<br><br>

## 🟢 6. 로컬 검증  

호스트에 Python 3, Bash, jq가 있다면 다음 명령으로 모의 테스트를 실행한다. 실제 AWS·SSH·curl은 PATH의 가짜 도구로 대체한다.  

```bash
python3 tests/run_tests.py # Python 테스트를 실행한다. API 요청 대신 임시 JSON 상태를 만들고 자동 정리한다.  
```

Ubuntu 이미지에서 네트워크까지 차단하고 정적 검사와 테스트를 실행할 수 있다. 다음 명령은 Bash 기준이다. `$PWD`는 현재 작업 디렉터리다.  

```bash
docker run --rm --network none --entrypoint bash -v "$PWD:/workspace:ro" aws-basic-lab:local /workspace/tests/check.sh # 네트워크 없이, 프로젝트를 read-only 연결해 모의 검증한다.  
```

`--network none`은 외부 연결 차단, `--entrypoint`는 실행 진입점 선택, `-v`는 volume 연결, `:ro`는 read-only다. `check.sh`는 `bash -n` 문법 검사, ShellCheck 정적 검사, Python 모의 테스트를 실행한다. ShellCheck에서는 동적 source와 여러 파일이 공유하는 전역변수 경고 SC1090·SC1091·SC2034만 제외하고 warning 이상을 검사한다.  

AWS CLI의 `--generate-cli-skeleton output`으로 생성 JSON 7개의 입력 형식도 API 호출 없이 확인한다. `skeleton`은 예시 입출력 틀이며, 이 검사는 실제 AWS 권한을 검사하지 않는다. Compose의 비관리자·읽기 전용·권한 제한까지 검증하려면 다음 재현 명령을 사용한다. 테스트용 설정은 네트워크를 차단하고 가짜 도구의 실행 폴더만 추가한다. 실제 서비스의 /tmp 실행 금지 정책은 유지한다.  

```bash
docker compose -f compose.yaml -f tests/compose.offline.yaml run --rm --entrypoint bash -v "$PWD:/workspace:ro" aws-lab /workspace/tests/check.sh # file 옵션으로 오프라인 설정을 합쳐 권한 제한 환경에서 모의 검증한다.  
```

실제 검증 결과는 `tests/VALIDATION.md`에 기록한다. 모의 성공은 실제 AWS 생성·접속·삭제 성공을 증명하지 않는다. 비용이나 권한 조건이 달라질 수 있으므로 실제 실행은 별도 확인이 필요하다.  

<br><br>

## 🟢 7. 출력·보안·제출  

출력 함수는 `info`, `success`, `warn`, `error`, `step_start`, `step_end`다. 안내는 stderr, 데이터·상태표는 stdout이다. 단계 종료 후 추가 줄바꿈 3개를 공통 함수에서 처리한다. 실제 터미널에서만 색상을 쓰며 `NO_COLOR`도 존중한다.  

`.gitattributes`는 Bash·Dockerfile·환경파일·Compose의 LF를 보장한다. PowerShell Wrapper는 UTF-8 BOM과 CRLF로 저장한다. Windows PowerShell에서 한국어 주석 인코딩을 명확하게 하기 위한 정책이다. Git 제외 파일은 Git 줄바꿈 규칙만으로 변환되지 않으므로 환경파일을 편집할 때 LF로 저장한다.  

로그를 공유할 때 계정, IP, Resource ID, 사용자 식별정보를 검토해서 가린다. 인증값과 개인키는 어떤 로그에도 남기지 않는다. `set -x`, 전체 환경변수 출력, 인증파일 출력, AWS `--debug`를 사용하지 않는다.  

IAM에 필요한 작업은 `docs/iam-actions.md`에 정리했다. 이 프로그램은 IAM 사용자·정책을 만들지 않는다. 관리자 권한으로 오류를 해결하지 않는다.  

과제 제출 시 기존 `docs/requirement.md`의 아키텍처·외부 접속 증빙·트러블슈팅·정리 체크리스트를 맞춘다. 이번 구현의 모의 결과를 실제 AWS 증빙으로 제출하지 않는다. 외부 접속 증빙은 방식 B인 `GET /health`의 HTTP 200·OK를 사용하고 실제 실행 후 스크린샷을 추가한다.  

VPC와 Subnet은 [AWS의 VPC waiter](https://docs.aws.amazon.com/cli/latest/reference/ec2/wait/vpc-available.html)와 [Subnet waiter](https://docs.aws.amazon.com/cli/latest/reference/ec2/wait/subnet-available.html)로 준비 상태를 확인한다. 각 waiter는 15초 간격으로 최대 40회 조회하며 실패 시 중단한다.  
