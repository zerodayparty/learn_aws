#!/usr/bin/env python3
import json  # 테스트 응답을 확인한다.
import os  # 실제 인증 환경을 테스트에 전달하지 않는다.
from pathlib import Path  # 프로젝트 파일을 찾는다.
import pty  # 대화형 확인이 필요한 명령의 입력을 재현한다.
import subprocess  # 실제 AWS 대신 가짜 도구를 실행한다.
import tempfile  # 테스트 자료를 자동 삭제되는 임시 폴더에 둔다.
import unittest  # 의미 있는 실패·복구 검증을 실행한다.
ROOT = Path(__file__).resolve().parents[1]  # 고도화 프로젝트 위치다.
class LabTests(unittest.TestCase):  # AWS 요청 없이 동작을 검증한다.
    def setUp(self):  # 각 테스트가 독립된 상태에서 시작하게 한다.
        self.temp = tempfile.TemporaryDirectory(prefix='aws-lab-test-', dir=os.environ.get('LAB_TEST_TMP'))  # 가짜 인증과 상태 저장 공간이다.
        self.addCleanup(self.temp.cleanup)  # 테스트 종료 후 모두 정리한다.
        self.base = Path(self.temp.name)  # 임시 폴더 위치다.
        self.bin = self.base / 'bin'  # 가짜 실행 도구 위치다.
        self.bin.mkdir()  # 도구 폴더를 만든다.
        self.env = {'PATH': str(self.bin) + os.pathsep + os.environ['PATH'], 'HOME': str(self.base), 'PROJECT': 'test-project', 'LAB_ID': 'test-01', 'EXPECTED_ACCOUNT_ID': '123456789012', 'AWS_REGION': 'ap-northeast-2', 'AWS_PROFILE': 'test', 'VPC_CIDR': '10.20.0.0/16', 'SUBNET_CIDR': '10.20.1.0/24', 'SSH_ALLOWED_CIDR': '192.0.2.1/32', 'AMI_ID': 'ami-0123456789abcdef0', 'INSTANCE_TYPE': 't3.micro', 'RUNTIME_DIR': str(self.base / 'runtime'), 'FAKE_STORE': str(self.base / 'aws.json'), 'FAKE_CALLS': str(self.base / 'calls'), 'FAKE_PAYLOADS': str(self.base / 'payloads')}  # 실제 인증·계정과 분리한다.
        config = self.base / 'config'  # 비밀값 없는 설정 파일이다.
        config.write_text('[profile test]\nregion=ap-northeast-2\n')  # 프로필 설정만 준비한다.
        credentials = self.base / 'credentials'  # 가짜 인증파일이다.
        credentials.write_text('[test]\naws_access_key_id=FAKE\naws_secret_access_key=FAKE\n')  # 외부 요청에 사용하지 않는 값이다.
        self.env.update(AWS_CONFIG_FILE=str(config), AWS_SHARED_CREDENTIALS_FILE=str(credentials))  # 가짜 인증 위치를 지정한다.
        self.tool('aws', (ROOT / 'tests/fake_aws.py').read_text())  # 실제 AWS 바이너리를 완전히 대체한다.
        self.tool('sha256sum', '#!/usr/bin/env python3\nimport hashlib,sys # 테스트 지문 계산이다.\nprint(hashlib.sha256(sys.stdin.buffer.read()).hexdigest()) # 데이터만 요약한다.\n')  # macOS에서도 같은 설정 지문을 만든다.
        self.tool('ssh-keygen', '#!/usr/bin/env bash\nexit 0 # 가짜 개인키 형식 검사다.\n')  # 테스트에서 실제 개인키를 만들지 않는다.
        self.tool('ssh', '#!/usr/bin/env bash\nif [[ "$*" == *curl* ]]; then printf "${FAKE_HTTP:-OK\\n\\n200}"; else cat >/dev/null; fi # 가짜 원격 응답을 만든다.\n')  # 실제 SSH 연결을 차단한다.
        self.tool('curl', '#!/usr/bin/env bash\nprintf "${FAKE_HTTP:-OK\\n\\n200}" # 가짜 외부 HTTP 응답을 만든다.\n')  # 실제 인터넷 요청을 차단한다.
    def tool(self, name, content):  # 가짜 실행 파일을 설치한다.
        file = self.bin / name  # PATH에서 먼저 선택되는 파일이다.
        file.write_text(content)  # 가짜 구현을 저장한다.
        file.chmod(0o755)  # 실행 권한을 부여한다.
    def run_lab(self, command, interactive=False, answer=''):  # 명령의 결과를 수집한다.
        if interactive:  # 대화형 stdin을 재현한다.
            master, slave = pty.openpty()  # 테스트용 터미널 쌍이다.
            process = subprocess.Popen(['bash', str(ROOT / 'scripts/entrypoint.sh'), command], env=self.env, stdin=slave, stdout=subprocess.PIPE, stderr=subprocess.PIPE)  # 가짜 도구로만 실행한다.
            os.close(slave)  # 부모 쪽의 불필요한 터미널을 닫는다.
            if answer: os.write(master, (answer + '\n').encode())  # DELETE 확인을 재현한다.
            try: out, err = process.communicate(timeout=180)  # 에뮬레이션에서도 제한된 시간만 기다린다.
            except subprocess.TimeoutExpired:  # 테스트 실패 후 프로세스를 남기지 않는다.
                process.kill()  # 시간 초과 작업을 종료한다.
                process.communicate()  # 종료된 작업을 회수한다.
                raise  # 시간 초과를 실패로 보고한다.
            finally: os.close(master)  # 테스트 터미널을 정리한다.
            return process.returncode, out.decode(), err.decode()  # 결과만 전달한다.
        result = subprocess.run(['bash', str(ROOT / 'scripts/entrypoint.sh'), command], env=self.env, capture_output=True, text=True, timeout=180)  # 일반 명령을 실행한다.
        return result.returncode, result.stdout, result.stderr  # 코드와 출력 스트림을 분리한다.
    def calls(self):  # 가짜 API 호출 기록을 읽는다.
        file = Path(self.env['FAKE_CALLS'])  # 요청 기록 위치다.
        return file.read_text().splitlines() if file.exists() else []  # 호출이 없으면 빈 목록이다.
    def test_help_without_configuration_or_api(self):  # 도움말은 AWS에 접근하지 않아야 한다.
        for key in ['PROJECT', 'LAB_ID', 'EXPECTED_ACCOUNT_ID']: self.env.pop(key)  # 실습 설정을 제거한다.
        self.assertEqual(self.run_lab('help')[0], 0)  # 도움말 성공을 확인한다.
        self.assertEqual(self.calls(), [])  # API 호출이 없음을 확인한다.
    def test_invalid_command_and_argument(self):  # 명령 오타가 AWS 호출로 이어지지 않아야 한다.
        self.assertNotEqual(self.run_lab('unknown')[0], 0)  # 오타는 실패해야 한다.
        result = subprocess.run(['bash', str(ROOT / 'scripts/entrypoint.sh'), 'status', '--yes'], env=self.env, capture_output=True)  # 미지원 옵션을 확인한다.
        self.assertNotEqual(result.returncode, 0)  # 자동 승인 옵션을 허용하지 않는다.
        self.assertEqual(self.calls(), [])  # 잘못된 명령에 API 호출이 없다.
    def test_missing_config_before_api(self):  # 누락된 설정은 외부 요청 전에 실패해야 한다.
        self.env.pop('EXPECTED_ACCOUNT_ID')  # 필수 대상 설정을 없앤다.
        self.assertNotEqual(self.run_lab('status')[0], 0)  # 누락을 실패로 처리한다.
        self.assertEqual(self.calls(), [])  # 요청 전에 실패했음을 확인한다.
    def test_status_without_creation_settings(self):  # 조회에 AMI를 강제하지 않는다.
        for key in ['AMI_ID', 'VPC_CIDR', 'INSTANCE_TYPE']: self.env.pop(key)  # 생성 전용 설정을 제거한다.
        code, output, _ = self.run_lab('status')  # 빈 실습 상태를 조회한다.
        self.assertEqual(code, 0)  # 정상 조회는 성공이다.
        self.assertIn('미생성', output)  # 빈 리소스를 표현한다.
    def test_wrong_account_stops_before_ec2(self):  # 계정 불일치는 변경 전에 차단한다.
        self.env['FAKE_SCENARIO'] = 'wrong-account'  # 다른 계정을 재현한다.
        self.assertNotEqual(self.run_lab('status')[0], 0)  # 계정 확인 실패다.
        self.assertEqual(self.calls(), ['get-caller-identity'])  # EC2 조회도 실행하지 않는다.
    def test_denied_error_is_not_empty_success(self):  # 권한 실패를 미생성으로 숨기지 않는다.
        self.env['FAKE_SCENARIO'] = 'deny'  # API 오류를 만든다.
        code, out, err = self.run_lab('status')  # 조회 실패를 받는다.
        self.assertNotEqual(code, 0)  # 실패 종료 코드다.
        self.assertNotIn('DENIED_SECRET_MARKER', out + err)  # 원문 비밀값을 출력하지 않는다.
    def test_duplicate_and_foreign_resources_stop(self):  # 충돌과 다른 소유 리소스를 보호한다.
        for scenario in ('duplicates', 'foreign'):  # 두 가지 잘못된 조회를 확인한다.
            self.env['FAKE_SCENARIO'] = scenario  # 가짜 응답을 선택한다.
            self.assertNotEqual(self.run_lab('status')[0], 0)  # 임의 선택하지 않고 실패한다.
    def test_noninteractive_mutation_stops(self):  # 비대화형으로 변경 요청을 보내지 않는다.
        for command in ('up', 'down'):  # 생성과 정리를 확인한다.
            self.assertNotEqual(self.run_lab(command)[0], 0)  # 대화형 명령은 실패한다.
        self.assertFalse(any(name.startswith('create-') or name.startswith('delete-') for name in self.calls()))  # 실제 변경 요청이 없다.
    def test_full_lifecycle_reuse_and_key_secrecy(self):  # 생성·재실행·조회·정리 흐름을 연결해 검사한다.
        code, out, err = self.run_lab('up', interactive=True)  # 가짜 리소스를 생성한다.
        self.assertEqual(code, 0, err)  # 전체 단계 성공을 확인한다.
        self.assertNotIn('PRIVATE_TEST_MARKER', out + err)  # 개인키가 출력되지 않아야 한다.
        creates = [name for name in self.calls() if name.startswith('create-') or name == 'run-instances']  # 생성 횟수를 기록한다.
        code, _, err = self.run_lab('up', interactive=True)  # 같은 설정으로 다시 실행한다.
        self.assertEqual(code, 0, err)  # 기존 리소스를 재사용한다.
        self.assertEqual(creates, [name for name in self.calls() if name.startswith('create-') or name == 'run-instances'])  # 중복 생성하지 않는다.
        self.assertEqual(self.run_lab('health')[0], 0)  # 단독 health 성공이다.
        code, _, err = self.run_lab('down', interactive=True, answer='DELETE')  # 정리를 승인한다.
        self.assertEqual(code, 0, err)  # 실제 잔여 조회까지 성공한다.
        self.assertEqual(self.run_lab('down', interactive=True, answer='DELETE')[0], 0)  # 정리 재실행도 성공한다.
        keys = list((self.base / 'runtime').rglob('*.pem'))  # 로컬 개인키 보관 여부를 확인한다.
        self.assertEqual(len(keys), 1)  # AWS 삭제 후에도 키를 보존한다.
        self.assertFalse(list((self.base / 'runtime').rglob('*.pending')))  # 정리 후 미해결 기록이 없다.
        for file in (self.base / 'runtime').rglob('*.json'): self.assertNotIn('PRIVATE_TEST_MARKER', file.read_text())  # 상태파일에 키가 없다.
    def test_generated_requests_with_real_cli_offline(self):  # 실제 SDK의 입력 형식으로 가짜 생성 요청을 확인한다.
        binary = os.environ.get('AWS_LAB_SCHEMA_CLI')  # Docker 검사에서만 실제 CLI 경로를 받는다.
        if not binary: self.skipTest('실제 CLI 입력 검사는 Ubuntu 이미지에서 수행')  # 호스트에 CLI를 설치하지 않는다.
        code, _, err = self.run_lab('up', interactive=True)  # 가짜 AWS에서 생성 JSON을 수집한다.
        self.assertEqual(code, 0, err)  # 요청 수집이 성공했는지 확인한다.
        for file in (self.base / 'payloads').glob('*.json'):  # 생성 작업별 JSON을 확인한다.
            args = [binary, '--region', 'ap-northeast-2', 'ec2', file.stem, '--cli-input-json', 'file://' + str(file), '--generate-cli-skeleton', 'output']  # 요청하지 않고 SDK 형식만 검사한다.
            result = subprocess.run(args, env={'PATH': os.environ['PATH'], 'HOME': str(self.base), 'AWS_EC2_METADATA_DISABLED': 'true', 'AWS_PAGER': ''}, capture_output=True, text=True, timeout=60)  # 실제 인증없이 실행한다.
            self.assertEqual(result.returncode, 0, file.stem + ': ' + result.stderr)  # 허용되지 않는 필드는 실패로 드러낸다.
    def test_changed_config_stops_reuse(self):  # 다른 설정으로 기존 자원을 덮어쓰지 않는다.
        self.assertEqual(self.run_lab('up', interactive=True)[0], 0)  # 첫 생성은 성공한다.
        self.env['SSH_ALLOWED_CIDR'] = '192.0.2.2/32'  # 접근 설정을 변경한다.
        code, _, err = self.run_lab('up', interactive=True)  # 재사용을 요청한다.
        self.assertNotEqual(code, 0)  # 불일치는 실패다.
        self.assertIn('지문 불일치', err)  # 변경 이유를 안내한다.
    def test_timeout_keeps_pending_and_blocks_retry(self):  # 생성 결과가 불명확하면 중복 생성하지 않는다.
        self.env['FAKE_SCENARIO'] = 'timeout'  # 생성 직후 응답 실패다.
        self.assertNotEqual(self.run_lab('up', interactive=True)[0], 0)  # 첫 실행은 실패한다.
        self.env.pop('FAKE_SCENARIO')  # 이후 조회는 정상이다.
        self.assertNotEqual(self.run_lab('up', interactive=True)[0], 0)  # 미해결 상태는 재실행을 막는다.
        self.assertEqual(self.calls().count('create-vpc'), 1)  # 요청은 한 번뿐이다.
    def test_http_wrong_body_and_redirect_fail(self):  # 상태 코드만으로 성공을 주장하지 않는다.
        self.assertEqual(self.run_lab('up', interactive=True)[0], 0)  # 가짜 웹 서비스를 준비한다.
        for response in ('BAD\\n\\n200', 'OK\\n\\n302'):  # 잘못된 본문과 Redirect를 검사한다.
            self.env['FAKE_HTTP'] = response  # 오류 응답을 선택한다.
            self.assertNotEqual(self.run_lab('health')[0], 0)  # 둘 다 health 실패여야 한다.
    def test_lock_blocks_changes(self):  # 타 실행의 잠금을 지우거나 우회하지 않는다.
        lock = self.base / 'runtime/state/123456789012/ap-northeast-2/test-project/test-01/lock'  # 공통 잠금 경로다.
        lock.mkdir(parents=True)  # 다른 실행이 있다고 재현한다.
        self.assertNotEqual(self.run_lab('up', interactive=True)[0], 0)  # 중복 실행은 실패한다.
        self.assertTrue(lock.exists())  # 타 잠금은 보존한다.
    def test_output_spacing_and_failure_code(self):  # 출력의 간격과 데이터 분리를 확인한다.
        source = 'source "$1"; run_step TEST bash -c "exit 7"'  # 실패 단계를 재현한다.
        result = subprocess.run(['bash', '-c', source, 'test', str(ROOT / 'scripts/lib/output.sh')], env=self.env, capture_output=True, text=True)  # 비TTY 로그로 실행한다.
        self.assertEqual(result.returncode, 7)  # 원래 실패 코드를 유지한다.
        self.assertEqual(result.stdout, '')  # stdout 데이터에 안내가 섞이지 않는다.
        self.assertNotIn('\x1b', result.stderr)  # ANSI 문자를 남기지 않는다.
        self.assertTrue(result.stderr.endswith('\n\n\n\n'))  # 종료 줄 끝과 추가 간격을 확인한다.
    def test_invalid_cidr_stops_before_api(self):  # 잘못된 네트워크와 SSH 공개를 사전에 막는다.
        for key, value in [('SUBNET_CIDR', '10.99.1.0/24'), ('SSH_ALLOWED_CIDR', '0.0.0.0/0')]:  # 범위 오류를 확인한다.
            original = self.env[key]  # 정상 값을 보관한다.
            self.env[key] = value  # 잘못된 설정을 재현한다.
            self.assertNotEqual(self.run_lab('up', interactive=True)[0], 0)  # 요청 전 실패해야 한다.
            self.env[key] = original  # 다음 검사에 정상 설정을 복원한다.
        self.assertEqual(self.calls(), [])  # AWS 요청 전에 차단했음을 확인한다.
    def test_cancelled_deletion_preserves_resources(self):  # DELETE가 아닌 입력은 삭제하지 않는다.
        self.assertEqual(self.run_lab('up', interactive=True)[0], 0)  # 가짜 실습을 만든다.
        code, _, _ = self.run_lab('down', interactive=True, answer='NO')  # 정리 승인을 거부한다.
        self.assertNotEqual(code, 0)  # 취소를 성공 삭제로 표시하지 않는다.
        state = json.loads(Path(self.env['FAKE_STORE']).read_text())  # 가짜 실제 리소스를 확인한다.
        self.assertEqual(len(state['Instances']), 1)  # 서버를 보존한다.
        self.assertNotIn('terminate-instances', self.calls())  # 종료 요청이 없었다.
    def test_foreign_route_association_is_not_deleted(self):  # 다른 서브넷 연결을 해제하지 않는다.
        self.assertEqual(self.run_lab('up', interactive=True)[0], 0)  # 실습 자원을 준비한다.
        file = Path(self.env['FAKE_STORE'])  # 가짜 AWS 상태다.
        state = json.loads(file.read_text())  # 연결 정보를 읽는다.
        state['RouteTables'][0]['Associations'][0]['SubnetId'] = 'subnet-foreign'  # 타 서브넷 연결을 재현한다.
        file.write_text(json.dumps(state))  # 변경 상태를 저장한다.
        self.assertNotEqual(self.run_lab('down', interactive=True, answer='DELETE')[0], 0)  # 안전 검사에서 중단한다.
        self.assertNotIn('disassociate-route-table', self.calls())  # 타 연결을 해제하지 않는다.
        self.assertNotIn('terminate-instances', self.calls())  # 연결 충돌은 서버 종료 전부터 차단한다.
    def test_missing_private_key_stops_server_creation(self):  # 발급 키가 사라졌으면 새 서버를 만들지 않는다.
        self.assertEqual(self.run_lab('up', interactive=True)[0], 0)  # 가짜 키와 서버를 준비한다.
        file = Path(self.env['FAKE_STORE'])  # 현재 가짜 AWS 상태다.
        state = json.loads(file.read_text())  # 서버 종료 후 키만 남는 상황이다.
        state['Instances'] = []  # 서버가 없게 만든다.
        state['Volumes'] = []  # 잔여 디스크도 없다.
        file.write_text(json.dumps(state))  # 키 등록만 남겨둔다.
        for key in (self.base / 'runtime').rglob('*.pem'): key.unlink()  # 로컬 개인키 유실을 재현한다.
        self.assertNotEqual(self.run_lab('up', interactive=True)[0], 0)  # 키 없는 서버 생성을 차단한다.
        self.assertEqual(self.calls().count('run-instances'), 1)  # 처음 만들었던 서버 외에 생성하지 않는다.
    def test_bash_wrapper_arguments_and_exit(self):  # Wrapper가 AWS 로직 없이 동일 서비스를 호출한다.
        self.tool('docker', '#!/usr/bin/env python3\nimport json,os,sys # 가짜 Docker 호출이다.\nopen(os.environ["FAKE_CALLS"],"w").write(json.dumps(sys.argv[1:])) # 인자 경계를 보관한다.\nsys.exit(17) # 실패 코드 전달을 검사한다.\n')  # Docker도 가짜로 대체한다.
        result = subprocess.run([str(ROOT / 'aws-lab'), 'status', 'with space'], env=self.env, cwd=self.base, capture_output=True)  # 다른 디렉터리에서도 호출한다.
        self.assertEqual(result.returncode, 17, result.stderr.decode())  # 가짜 Docker 실패 코드와 Wrapper 자체 오류를 구분한다.
        args = json.loads(Path(self.env['FAKE_CALLS']).read_text())  # 전달된 인자를 확인한다.
        self.assertEqual(args[-5:], ['run', '--rm', 'aws-lab', 'status', 'with space'])  # 같은 서비스와 인자 경계를 보존한다.
if __name__ == '__main__':  # 직접 실행한 경우 테스트를 시작한다.
    unittest.main(verbosity=2)  # 각 검증 결과를 표시한다.
