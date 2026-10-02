# AWS 공식 이미지의 고정 버전에서 CLI만 가져온다.
FROM public.ecr.aws/aws-cli/aws-cli:2.36.44@sha256:e8467f2c319f9bc9a1471808a69949a76915e9c95eaf4a09ece9f9e85fd32747 AS awscli
# Ubuntu LTS를 실습의 표준 Bash 환경으로 사용한다.
FROM ubuntu:24.04@sha256:a853f94d226358a79c740cfc7bce0c289748f3fe3488d921d038ccd752c61b60
# 설치 질문 없이 필요한 도구만 설치하고 패키지 목록을 정리한다.
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends bash ca-certificates curl jq openssh-client python3 coreutils shellcheck && rm -rf /var/lib/apt/lists/*
# 아키텍처에 맞는 AWS CLI 설치 디렉터리를 복사한다.
COPY --from=awscli /usr/local/aws-cli /usr/local/aws-cli
# AWS 실행 경로를 연결하고 빌드 중 실제 실행 가능 여부를 확인한다.
RUN ln -s /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws && aws --version
# AWS가 사용하는 화면 대기와 인증 fallback을 비활성화한다.
ENV AWS_PAGER="" AWS_EC2_METADATA_DISABLED=true PYTHONDONTWRITEBYTECODE=1
# 실행 코드는 호스트 파일로 덮어쓰지 않고 이미지에 넣는다.
COPY scripts /app/scripts
# 프로젝트의 컨테이너 내부 작업 위치를 통일한다.
WORKDIR /app
# 확장자가 없는 명령은 공통 Bash 진입점에서 분기한다.
ENTRYPOINT ["bash", "/app/scripts/entrypoint.sh"]
# 명령을 생략하면 AWS 요청 없이 사용법을 표시한다.
CMD ["help"]
