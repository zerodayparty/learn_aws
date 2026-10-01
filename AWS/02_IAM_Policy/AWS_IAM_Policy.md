# 🟩 과제 전용 IAM Policy  

- AWS 검색창에서 IAM 검색하여 들어간다.  
- IAM → Policies → Create policy → JSON 으로 이동한다.  


<br><br>

## 🟢 JSON에는 다음 권한들을 넣는다.  

```json
{  
    "Version": "2012-10-10",  
    "Statement": [  
        {  
            "Sid": "IAM_AccessKeys",  
            "Effect": "Allow",  
            "Action": [  
                "iam:ListUsers",  
                "iam:ListGroups",  
                "iam:TagUser",  
                "iam:ListUserTags",  
                "iam:GetUser",  
                "iam:ListAccessKeys",  
                "iam:CreateAccessKey",  
                "iam:UpdateAccessKey",  
                "iam:DeleteAccessKey"    
            ],  
            "Resource": "*"  
        },  
        {  
            "Sid": "EC2Read",  
            "Effect": "Allow",  
            "Action": [  
                "ec2:Describe*"  
            ],  
            "Resource": "*"  
        },  
        {  
            "Sid": "AWSBasicLabWrite",  
            "Effect": "Allow",  
            "Action": [          
                "ec2:CreateVpc",  
                "ec2:DeleteVpc",  
                "ec2:ModifyVpcAttribute",  

                "ec2:CreateSubnet",  
                "ec2:DeleteSubnet",  
                "ec2:ModifySubnetAttribute",  

                "ec2:CreateInternetGateway",  
                "ec2:DeleteInternetGateway",  
                "ec2:AttachInternetGateway",  
                "ec2:DetachInternetGateway",  

                "ec2:CreateRouteTable",  
                "ec2:DeleteRouteTable",  
                "ec2:AssociateRouteTable",  
                "ec2:DisassociateRouteTable",  
                "ec2:CreateRoute",  
                "ec2:DeleteRoute",  

                "ec2:CreateSecurityGroup",  
                "ec2:DeleteSecurityGroup",  
                "ec2:AuthorizeSecurityGroupIngress",  
                "ec2:RevokeSecurityGroupIngress",  

                "ec2:CreateKeyPair",  
                "ec2:DeleteKeyPair",  

                "ec2:RunInstances",  
                "ec2:StartInstances",  
                "ec2:StopInstances",  
                "ec2:TerminateInstances",  

                "ec2:CreateTags",  
                "ec2:DeleteTags",  

                "ec2:CreateVolume",  
                "ec2:DeleteVolume",  

                "ec2:AllocateAddress",  
                "ec2:AssociateAddress",  
                "ec2:DisassociateAddress",  
                "ec2:ReleaseAddress"  
            ],  
            "Resource": "*"  
        }  
    ]  
}  
```