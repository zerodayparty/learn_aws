# 🟩 AWS 현재 구성 상태 확인하기

> VPC, Subnet, Public IP, Route, Security Group Inbound, EC2의 상태 등을 확인한다. 


<br>

## 🟢 확인 명령어

```bash
# VPC, Subnet CIDR과 Public IP 설정을 확인한다.  
aws ec2 describe-subnets --subnet-ids "$SUBNET_ID" --query 'Subnets[0].[VpcId,SubnetId,CidrBlock,AvailabilityZone,MapPublicIpOnLaunch]' --output table --profile "$PROFILE" --region "$REGION"  

# Route와 Subnet Association을 확인한다.  
aws ec2 describe-route-tables --route-table-ids "$RT_ID" --query 'RouteTables[0].[Routes,Associations]' --output json --profile "$PROFILE" --region "$REGION"  

# Security Group Inbound 규칙을 확인한다.  
aws ec2 describe-security-group-rules --filters "Name=group-id,Values=$SG_ID" --query 'SecurityGroupRules[?IsEgress==`false`].[IpProtocol,FromPort,ToPort,CidrIpv4]' --output table --profile "$PROFILE" --region "$REGION"  

# EC2의 상태와 네트워크 연결 관계를 확인한다.  
aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].[InstanceId,State.Name,PublicIpAddress,VpcId,SubnetId]' --output table --profile "$PROFILE" --region "$REGION"  

# nginx 상태 확인
ssh -i "$KEY_FILE" ubuntu@"$PUBLIC_IP"
sudo systemctl status nginx --no-pager
```


<br><br>

## 🟢 출력 log 

```bash
# VPC, Subnet CIDR과 Public IP 설정을 확인한다.
raiactivity3129@c6r10s3 ~ % aws ec2 describe-subnets --subnet-ids "$SUBNET_ID" --query 'Subnets[0].[VpcId,SubnetId,CidrBlock,AvailabilityZone,MapPublicIpOnLaunch]' --output table --profile "$PROFILE" --region "$REGION"
------------------------------
|       DescribeSubnets      |
+----------------------------+
|  vpc-08c23771d133a47ae     |
|  subnet-0b12ed582eeb6653f  |
|  10.0.1.0/24               |
|  ap-northeast-2a           |
|  True                      |
+----------------------------+




# Route와 Subnet Association을 확인한다. 
raiactivity3129@c6r10s3 ~ % aws ec2 describe-route-tables --route-table-ids "$RT_ID" --query 'RouteTables[0].[Routes,Associations]' --output json --profile "$PROFILE" --region "$REGION"
[
    [
        {
            "DestinationCidrBlock": "10.0.0.0/16",
            "GatewayId": "local",
            "Origin": "CreateRouteTable",
            "State": "active"
        },
        {
            "DestinationCidrBlock": "0.0.0.0/0",
            "GatewayId": "igw-04cf6607b7dacf774",
            "Origin": "CreateRoute",
            "State": "active"
        }
    ],
    [
        {
            "Main": false,
            "RouteTableAssociationId": "rtbassoc-01dcbdc3f2839f36f",
            "RouteTableId": "rtb-0946c365525d63f0c",
            "SubnetId": "subnet-0b12ed582eeb6653f",
            "AssociationState": {
                "State": "associated"
            }
        }
    ]
]




# Security Group Inbound 규칙을 확인한다.
raiactivity3129@c6r10s3 ~ % aws ec2 describe-security-group-rules --filters "Name=group-id,Values=$SG_ID" --query 'SecurityGroupRules[?IsEgress==`false`].[IpProtocol,FromPort,ToPort,CidrIpv4]' --output table --profile "$PROFILE" --region "$REGION"
------------------------------------------
|       DescribeSecurityGroupRules       |
+-----+-----+-----+----------------------+
|  tcp|  22 |  22 |  121.135.181.46/32   |
|  tcp|  80 |  80 |  0.0.0.0/0           |
+-----+-----+-----+----------------------+




# EC2의 상태와 네트워크 연결 관계를 확인한다.  
raiactivity3129@c6r10s3 ~ % aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].[InstanceId,State.Name,PublicIpAddress,VpcId,SubnetId]' --output table --profile "$PROFILE" --region "$REGION"
------------------------------
|      DescribeInstances     |
+----------------------------+
|  i-04f7febaed27571c8       |
|  running                   |
|  43.201.150.176            |
|  vpc-08c23771d133a47ae     |
|  subnet-0b12ed582eeb6653f  |
+----------------------------+


# nginx 상태 확인
raiactivity3129@c6r10s3 ~ % ssh -i "$KEY_FILE" ubuntu@"$PUBLIC_IP"

ubuntu@ip-10-0-1-68:~$ sudo systemctl status nginx --no-pager
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: enabled)
     Active: active (running) since Thu 2026-10-01 11:08:03 UTC; 11s ago
       Docs: man:nginx(8)
    Process: 2088 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
    Process: 2090 ExecStart=/usr/sbin/nginx -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
   Main PID: 2091 (nginx)
      Tasks: 3 (limit: 627)
     Memory: 2.7M (peak: 2.7M)
        CPU: 17ms
```