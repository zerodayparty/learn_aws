# PowerShell에서 Bash와 동일한 Compose 서비스를 실행한다.
$ErrorActionPreference = 'Stop' # Wrapper 자체 오류를 숨기지 않는다.
Push-Location -LiteralPath $PSScriptRoot # 공백이 있는 프로젝트 경로도 그대로 사용한다.
try { # 종료 후 사용자의 원래 디렉터리로 돌아간다.
    & docker compose --project-directory $PSScriptRoot -f (Join-Path $PSScriptRoot 'compose.yaml') run --rm aws-lab @args # 동일 인자를 Docker에 전달한다.
    $result = $LASTEXITCODE # Docker 종료 코드를 보관한다.
} finally { # 성공·실패 모두 원래 위치를 복구한다.
    Pop-Location # 사용자가 있던 디렉터리로 돌아간다.
} # 위치 복구를 끝낸다.
exit $result # Docker 실패를 성공으로 바꾸지 않는다.
