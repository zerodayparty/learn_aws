# 🟩 실습에 필요한 IAM 작업 목록

## 🟢 범위

IAM은 Identity and Access Management다. 아래는 실제 코드가 호출하는 작업 목록이며, 관리자 권한을 부여하라는 뜻이 아니다. 정책을 자동 생성·적용하지 않는다.

| 책임 | 필요한 IAM Action |
| --- | --- |
| 조회 | ec2:DescribeVpcs, ec2:DescribeSubnets, ec2:DescribeInternetGateways, ec2:DescribeRouteTables, ec2:DescribeSecurityGroups, ec2:DescribeKeyPairs, ec2:DescribeInstances, ec2:DescribeVolumes, ec2:DescribeAddresses |
| 생성 전 이미지·CPU 검사 | ec2:DescribeImages, ec2:DescribeInstanceTypes |
| 네트워크 생성 | ec2:CreateVpc, ec2:ModifyVpcAttribute, ec2:CreateSubnet, ec2:CreateInternetGateway, ec2:AttachInternetGateway |
| 경로표 | ec2:CreateRouteTable, ec2:CreateRoute, ec2:AssociateRouteTable |
| 접근 규칙 | ec2:CreateSecurityGroup, ec2:AuthorizeSecurityGroupIngress |
| 키·서버 | ec2:CreateKeyPair, ec2:RunInstances |
| 생성 시 Tag | ec2:CreateTags |
| 서버·저장소 정리 | ec2:TerminateInstances, ec2:DeleteVolume, ec2:ReleaseAddress, ec2:DeleteKeyPair |
| 네트워크 정리 | ec2:DeleteSecurityGroup, ec2:DisassociateRouteTable, ec2:DeleteRouteTable, ec2:DetachInternetGateway, ec2:DeleteInternetGateway, ec2:DeleteSubnet, ec2:DeleteVpc |
| waiter 조회 | ec2:DescribeInstanceStatus, ec2:DescribeInstances |
| 수동 SSH 호스트 키 확인 | ec2:GetConsoleOutput. 프로그램이 호출하지 않으며 AWS 콘솔 시스템 로그 확인에 필요 |

`sts get-caller-identity`는 계정 확인용이다. EC2 생성에는 AMI, Subnet, Security Group, Key Pair, Instance, Volume 등 여러 Resource의 허용 범위가 필요하다. 조회 작업 일부는 Resource 단위 제한을 지원하지 않으므로 Action별 지원 여부를 확인해야 한다.

<br><br>

## 🟢 정책 작성 시 확인

- Action 목록을 기준으로 서울 리전과 필요한 리소스만 허용한다.
- 생성에는 Request Tag, 수정·삭제에는 Resource Tag 조건의 지원 여부를 Action별로 확인한다.
- 생성 중 Tag 부여에 필요한 CreateTags 권한을 생성 Action 조건과 함께 검토한다.
- RunInstances에는 인스턴스와 디스크뿐 아니라 참조 리소스 권한도 필요하다.
- 암호화 EBS에 고객 관리 KMS 키를 적용하면 추가 권한 검토가 필요하다. 첫 구현은 기본 EBS 암호화 설정을 사용한다.
- 서버에 IAM Role을 붙이지 않으므로 iam:PassRole을 요구하지 않는다.
- 이 목록은 실제 IAM 정책의 동작 검증을 대신하지 않는다. [EC2 권한·Resource·조건 공식 목록](https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonec2.html)으로 각 Action을 확인하고 실제 계정에서 별도로 검증한다.
