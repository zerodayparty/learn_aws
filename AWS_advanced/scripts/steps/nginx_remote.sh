#!/usr/bin/env bash
set -euo pipefail # 원격 설치 단계는 명령 실패 시 즉시 종료한다.
export DEBIAN_FRONTEND=noninteractive # 패키지 설치 질문을 비활성화한다.
sudo -n timeout 300 apt-get update -qq # Ubuntu 패키지 목록을 갱신한다.
sudo -n timeout 300 env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx curl # 웹 서버와 검사 도구를 설치한다.
printf '%s\n' 'server { # 실습 HTTP 서버를 정의한다.' '    listen 80 default_server; # HTTP 80번 포트를 사용한다.' '    server_name _; # Public IP 요청도 받는다.' '    location = /health { # 정확한 health 경로를 검사한다.' '        default_type text/plain; # 문자열 응답을 사용한다.' '        return 200 "OK\n"; # 성공 상태와 정해진 본문을 반환한다.' '    } # health 설정을 끝낸다.' '    location / { # 기본 접속도 확인할 수 있게 한다.' '        default_type text/plain; # 기본 문자열 응답이다.' '        return 200 "AWS Lab\n"; # 실습 페이지를 반환한다.' '    } # 기본 경로를 끝낸다.' '} # 서버 설정을 끝낸다.' | sudo -n tee /etc/nginx/sites-available/default >/dev/null # Nginx 설정을 만들고 내용 출력은 줄인다.
sudo -n nginx -t # 설정 문법을 확인한다.
sudo -n systemctl enable --now nginx # 재부팅 후에도 웹 서버가 시작되게 한다.
sudo -n systemctl reload nginx # 새 설정을 적용한다.
sudo -n systemctl is-active --quiet nginx # 서비스 실행 상태를 검사한다.
curl --fail --silent --show-error --connect-timeout 5 --max-time 15 https://example.com >/dev/null # 인터넷 아웃바운드를 확인한다.
