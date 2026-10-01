# 🟩 AWS 클라우드 리소스 정리 체크리스트  

<br>

## 🟢 목적  

실습 완료 후 불필요한 클라우드 리소스가 남아 과금이 발생하는 것을 원천 차단하기 위해 아래 체크리스트 순서대로 리소스를 삭제/정리합니다.  




<br><br>

## 🟢 삭제하기  

```bash
# EC2를 영구 종료한다.  
aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" --profile "$PROFILE" --region "$REGION"  

# EC2가 terminated 상태가 될 때까지 기다린다.  
aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID" --profile "$PROFILE" --region "$REGION"  

# Project Tag가 붙은 EBS가 남았는지 확인한다.  
aws ec2 describe-volumes --filters "Name=tag:Project,Values=$PROJECT" --query 'Volumes[].[VolumeId,State,Size]' --output table --profile "$PROFILE" --region "$REGION"  
```

### EBS가 `available`로 남았다면 정확한 ID를 확인한 뒤에만 실행한다.  

```bash
# 남은 프로젝트 EBS 하나를 영구 삭제한다.  
aws ec2 delete-volume --volume-id <확인한_PROJECT_VOLUME_ID> --profile "$PROFILE" --region "$REGION"  


# ----------------------------------------------------------------------------  
# 나머지 리소스 삭제  

# 종료된 EC2가 사용하던 Security Group을 삭제한다.  
aws ec2 delete-security-group --group-id "$SG_ID" --profile "$PROFILE" --region "$REGION"  

# Public Subnet과 Route Table의 연결을 해제한다.  
aws ec2 disassociate-route-table --association-id "$RT_ASSOC_ID" --profile "$PROFILE" --region "$REGION"  

# Internet Gateway로 향하는 기본 경로를 삭제한다.  
aws ec2 delete-route --route-table-id "$RT_ID" --destination-cidr-block 0.0.0.0/0 --profile "$PROFILE" --region "$REGION"  

# 사용자 정의 Route Table을 삭제한다.  
aws ec2 delete-route-table --route-table-id "$RT_ID" --profile "$PROFILE" --region "$REGION"  

# Internet Gateway를 VPC에서 분리한다.  
aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" --profile "$PROFILE" --region "$REGION"  

# 분리된 Internet Gateway를 삭제한다.  
aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID" --profile "$PROFILE" --region "$REGION"  

# Public Subnet을 삭제한다.  
aws ec2 delete-subnet --subnet-id "$SUBNET_ID" --profile "$PROFILE" --region "$REGION"  

# AWS에 등록된 Public Key 정보를 삭제한다.  
aws ec2 delete-key-pair --key-name "$KEY_NAME" --profile "$PROFILE" --region "$REGION"  

# 마지막으로 프로젝트 VPC를 삭제한다.  
aws ec2 delete-vpc --vpc-id "$VPC_ID" --profile "$PROFILE" --region "$REGION"  
```

Mac의 Private Key는 AWS 리소스 삭제를 확인한 후 정확한 경로를 보고 삭제한다.  

```bash
# 삭제 대상이 프로젝트 전용 Private Key인지 확인한다.  
ls -l "$KEY_FILE"  

# 확인한 프로젝트 전용 Private Key 파일 하나만 삭제한다.  
rm -- "$KEY_FILE"  
```


### log  

```bash

raiactivity3129@c6r10s3 ~ % aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" --profile "$PROFILE" --region "$REGION"  
{  
    "TerminatingInstances": [  
        {  
            "InstanceId": "i-04f7febaed27571c8",  
            "CurrentState": {  
                "Code": 32,  
                "Name": "shutting-down"  
            },  
            "PreviousState": {  
                "Code": 16,  
                "Name": "running"  
            }  
        }  
    ]  
}  
raiactivity3129@c6r10s3 ~ % aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID" --profile "$PROFILE" --region "$REGION"  
raiactivity3129@c6r10s3 ~ % aws ec2 describe-volumes --filters "Name=tag:Project,Values=$PROJECT" --query 'Volumes[].[VolumeId,State,Size]' --output table --profile "$PROFILE" --region "$REGION"  
raiactivity3129@c6r10s3 ~ % aws ec2 delete-volume --volume-id <확인한_PROJECT_VOLUME_ID> --profile "$PROFILE" --region "$REGION"  
zsh: no such file or directory: 확인한_PROJECT_VOLUME_ID  
raiactivity3129@c6r10s3 ~ % aws ec2 delete-security-group --group-id "$SG_ID" --profile "$PROFILE" --region "$REGION"  
{  
    "Return": true,  
    "GroupId": "sg-05eefbc4478e64123"  
}  
raiactivity3129@c6r10s3 ~ % aws ec2 disassociate-route-table --association-id "$RT_ASSOC_ID" --profile "$PROFILE" --region "$REGION"  
raiactivity3129@c6r10s3 ~ % aws ec2 delete-route --route-table-id "$RT_ID" --destination-cidr-block 0.0.0.0/0 --profile "$PROFILE" --region "$REGION"  
raiactivity3129@c6r10s3 ~ % aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" --profile "$PROFILE" --region "$REGION"  
raiactivity3129@c6r10s3 ~ % aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID" --profile "$PROFILE" --region "$REGION"  
raiactivity3129@c6r10s3 ~ % aws ec2 delete-subnet --subnet-id "$SUBNET_ID" --profile "$PROFILE" --region "$REGION"  
raiactivity3129@c6r10s3 ~ % aws ec2 delete-key-pair --key-name "$KEY_NAME" --profile "$PROFILE" --region "$REGION"  
{  
    "Return": true,  
    "KeyPairId": "key-0e13c705b3e211ce5"  
}  
raiactivity3129@c6r10s3 ~ % aws ec2 delete-vpc --vpc-id "$VPC_ID" --profile "$PROFILE" --region "$REGION"  

aws: [ERROR]: An error occurred (DependencyViolation) when calling the DeleteVpc operation: The vpc 'vpc-08c23771d133a47ae' has dependencies and cannot be deleted.  
raiactivity3129@c6r10s3 ~ % aws ec2 delete-vpc --vpc-id "$VPC_ID" --profile "$PROFILE" --region "$REGION"  

aws: [ERROR]: An error occurred (DependencyViolation) when calling the DeleteVpc operation: The vpc 'vpc-08c23771d133a47ae' has dependencies and cannot be deleted.  
raiactivity3129@c6r10s3 ~ % aws ec2 delete-route-table --route-table-id "$RT_ID" --profile "$PROFILE" --region "$REGION"  
raiactivity3129@c6r10s3 ~ % aws ec2 delete-vpc --vpc-id "$VPC_ID" --profile "$PROFILE" --region "$REGION"  
raiactivity3129@c6r10s3 ~ % ls -l "$KEY_FILE"  
-r--------  1 raiactivity3129  raiactivity3129  388 10  1 19:27 /Users/raiactivity3129/.ssh/learn-aws/aws-basic-lab-key.pem  
raiactivity3129@c6r10s3 ~ % rm -- "$KEY_FILE"  
override r-------- raiactivity3129/raiactivity3129 for /Users/raiactivity3129/.ssh/learn-aws/aws-basic-lab-key.pem? y  

```







<br><br>

## 🟢 삭제 여부 최종 확인하기  

```bash
# Project Tag를 가진 VPC가 남았는지 확인한다.  
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=$PROJECT" --query 'Vpcs[].[VpcId,State]' --output table --profile "$PROFILE" --region "$REGION"  

# Project Tag를 가진 Subnet이 남았는지 확인한다.  
aws ec2 describe-subnets --filters "Name=tag:Project,Values=$PROJECT" --query 'Subnets[].[SubnetId,State]' --output table --profile "$PROFILE" --region "$REGION"  

# Project Tag를 가진 IGW가 남았는지 확인한다.  
aws ec2 describe-internet-gateways --filters "Name=tag:Project,Values=$PROJECT" --query 'InternetGateways[].[InternetGatewayId,Attachments]' --output table --profile "$PROFILE" --region "$REGION"  

# Project Tag를 가진 EBS가 남았는지 확인한다.  
aws ec2 describe-volumes --filters "Name=tag:Project,Values=$PROJECT" --query 'Volumes[].[VolumeId,State,Size]' --output table --profile "$PROFILE" --region "$REGION"  

# 계정의 Elastic IP를 조회해 이 실습에서 만든 것이 없음을 확인한다.  
aws ec2 describe-addresses --query 'Addresses[].[AllocationId,AssociationId,PublicIp]' --output table --profile "$PROFILE" --region "$REGION"  
```






<br><br>

## 🟢 체크리스트  


| 구분 | 작업 단계 | 실행 명령어 / 확인 내용 | 수행 여부 |  
| --- | --- | --- | --- |
| EC2 인스턴스 | 인스턴스 영구 종료 | `aws ec2 terminate-instances` 실행 후 종료 완료(`wait instance-terminated`) 대기 | [✓] |  
| EBS 볼륨 | 잔여 볼륨 확인 및 삭제 | `describe-volumes` 조회 후 `available` 상태인 EBS 볼륨 `delete-volume` 진행 | [✓] |  
| 보안 그룹 | Security Group 삭제 | EC2 종료 후 `aws ec2 delete-security-group` 실행 | [✓] |  
| 라우팅 테이블 | 연결 해제 및 라우트 삭제 | Subnet 연결 해제(`disassociate-route-table`) 및 `0.0.0.0/0` 라우트 삭제(`delete-route`) | [✓] |  
| 라우팅 테이블 | 사용자 정의 RT 삭제 | `aws ec2 delete-route-table` 실행 | [✓] |  
| 인터넷 게이트웨이 | IGW 분리 및 삭제 | VPC 분리(`detach-internet-gateway`) 후 `delete-internet-gateway` 실행 | [✓] |  
| 서브넷 | Public Subnet 삭제 | `aws ec2 delete-subnet` 실행 | [✓] |  
| 키 페어 | AWS Key Pair 삭제 | `aws ec2 delete-key-pair` 실행 | [✓] |  
| VPC | 프로젝트 VPC 삭제 | `aws ec2 delete-vpc` 실행 | [✓] |  
| 로컬 파일 | 로컬 Private Key 삭제 | `ls -l`로 경로 확인 후 `rm` 명령어로 `.pem` 파일 삭제 | [✓] |  
| 최종 검증 | VPC / Subnet 잔여 확인 | `describe-vpcs`, `describe-subnets` 조회 결과 빈 표(None) 확인 | [✓] |  
| 최종 검증 | IGW / EBS 잔여 확인 | `describe-internet-gateways`, `describe-volumes` 조회 결과 빈 표(None) 확인 | [✓] |  
| 최종 검증 | Elastic IP 잔여 확인 | `describe-addresses` 조회 결과 미사용 EIP 없는지 확인 | [✓] |  