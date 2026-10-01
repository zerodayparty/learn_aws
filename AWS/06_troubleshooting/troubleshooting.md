# 🟩 트러블슈팅 보고서 (Troubleshooting)

<br>

## 🟢 Nginx 프로세스 중단으로 인한 서비스 접속 불가에 대한 조치

<br>

### 🟡 6칸 구조 트러블슈팅 요약

| 칸 | 내용 |
| --- | --- |
| **증상** | 외부 및 내부에서 `/health` 엔드포인트 요청 시 `curl: (7) Failed to connect ... Connection refused` 발생 |
| **원인 가설** | (1) Security Group 등 네트워크 설정 문제<br>

<br>(2) Nginx 프로세스 미실행(Stopped/Inactive) 상태 |
| **검증 방법** | (1) EC2 내부에서 `curl http://localhost/health` 실행 → 실패 (`curl exit 7`)<br>

<br>(2) `sudo systemctl status nginx` 확인 → `Active: inactive (dead)` 상태 확인 |
| **조치 내용** | `sudo systemctl start nginx` 명령을 실행하여 Nginx 서비스 재시작 |
| **결과** | 내부 및 외부에서 `curl` 요청 시 모두 `HTTP/1.1 200 OK` 응답 확인 |
| **재발 방지** | 배포 후 프로세스 실행 상태와 Health Check를 함께 자동 검사하도록 스크립트 보완 및 `systemd` auto-restart 설정 적용 |



<br><br>

### 🟡 상세 트러블슈팅 진행 과정



#### ⚫️ 1. 증상 확인 (Symptom)

외부 Client(Mac) 및 EC2 내부에서 Health Check 요청 시 Connection Refused 에러 발생.

* **외부(Mac) 호출 명령 및 출력**
```bash
curl --connect-timeout 5 -i "http://43.201.150.176/health"

```


```text
curl: (7) Failed to connect to 43.201.150.176 port 80 after 5 ms: Couldn't connect to server

```


* **EC2 내부 호출 명령 및 출력**
```bash
curl --connect-timeout 5 -i http://localhost/health

```


```text
curl: (7) Failed to connect to localhost port 80 after 0 ms: Couldn't connect to server

```







<br>

#### ⚫️ 2. 원인 가설 수립 (Hypothesis)

* **가설 1**: Security Group(보안 그룹) 80번 포트 미허용 또는 라우팅 문제 (네트워크 층)
* **가설 2**: Nginx 서비스 중단으로 80번 포트 LISTEN 부재 (서버 층)





<br>

#### ⚫️ 3. 가설 검증 (Verification)

* **검증 1**: `curl` 반환 코드가 `exit 28 (timeout)`이 아닌 `exit 7 (Connection refused)`로 출력됨.
* `Connection refused`는 패킷이 서버까지 도달하였으나 RST를 받은 상태이므로 네트워크/Security Group 설정은 정상임을 의미함.
* 이에 따라 **가설 1(네트워크 문제) 기각**.


* **검증 2**: EC2 내부에서 Nginx 프로세스 상태 확인.
```bash
sudo systemctl status nginx --no-pager

```


```text
○ nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: enabled)
     Active: inactive (dead) since Thu 2026-10-01 11:05:11 UTC; 3s ago

```


* Nginx 상태가 `inactive (dead)` 상태임을 확인. **가설 2(Nginx 중단) 확정**.







<br>

#### ⚫️ 4. 조치 내용 (Action)

Nginx 서비스를 재시작하여 프로세스를 정상화함.

```bash
sudo systemctl start nginx

```





<br>

#### ⚫️ 5. 결과 확인 (Result)

Nginx 서비스 실행 상태, 시스템 저널 로그, 내부/외부 Health Check 응답을 종합적으로 검증함.

* **Nginx 서비스 상태 확인**
```bash
sudo systemctl status nginx --no-pager

```


```text
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: enabled)
     Active: active (running) since Thu 2026-10-01 11:08:03 UTC; 11s ago
   Main PID: 2091 (nginx)

```


* **Journal Control 로그 확인**
```bash
sudo journalctl -u nginx -n 30 --no-pager

```


```text
Oct 01 11:05:11 ip-10-0-1-68 systemd[1]: Stopping nginx.service - A high performance web server and a reverse proxy server...
Oct 01 11:05:11 ip-10-0-1-68 systemd[1]: nginx.service: Deactivated successfully.
Oct 01 11:05:11 ip-10-0-1-68 systemd[1]: Stopped nginx.service - A high performance web server and a reverse proxy server.
Oct 01 11:08:03 ip-10-0-1-68 systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Oct 01 11:08:03 ip-10-0-1-68 systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.

```


* **EC2 내부 Health Check**
```bash
curl --connect-timeout 5 -i http://localhost/health

```


```text
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

```


* **외부 Client(Mac) Health Check**
```bash
curl --connect-timeout 5 -i "http://43.201.150.176/health"

```


```text
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







<br>

#### ⚫️ 6. 재발 방지 대책 (Prevention)

* **프로세스 모니터링 자동화**: Nginx 비정상 종료 시 자동 재시작되도록 `systemd` 설정에 `Restart=always` 옵션 반영 검토
* **배포 및 검증 절차 표준화**: 배포 스크립트 실행 후 `systemctl is-active` 확인 및 Health Check(`HTTP 200`) 검증 단계를 필수 파이프라인으로 추가