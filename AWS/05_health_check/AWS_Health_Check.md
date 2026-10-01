# 🟩 EC2 Nginx Health Check  

```bash
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
| `--connect-timeout 5` | 연결을 최대 5초만 기다림 |  
| `${PUBLIC_IP}` | Public IP 변수값을 URL 안에 사용 |  

외부 `curl`의 `200 OK`와 `OK` 결과가 외부 접속 검증 방식 B의 증빙이다.  


<br>

### 🟡 실제 log  

```bash
raiactivity3129@c6r10s3 ~ % nc -vz "$PUBLIC_IP" 80  
Connection to 43.201.150.176 port 80 [tcp/http] succeeded!  

raiactivity3129@c6r10s3 ~ % curl --connect-timeout 5 -i "http://${PUBLIC_IP}/health"  
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