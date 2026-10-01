# 🟩 AWS CLI로 과제 전체 수행하기 2  

#### ⚫️ [들어가기 전] VPC, Subnet, Route Table, Internet Gateway 파악하기  
- AWS 네트워크에서 핵심은 정말 VPC, Subnet, Route Table, Internet Gateway 이 4가지이다.  
    - `VPC`              = 하나의 도시  
    - `Subnet`           = 도시 안의 동네  
    - `Route Table`      = 도로 안내판 / 내비게이션  
    - `Internet Gateway` = 도시 밖 인터넷으로 나가는 톨게이트  

- **VPC**: Virtual Private Cloud  
    - AWS 안에 만드는 나만의 사설 네트워크 공간이다.  
    - EC2 같은 AWS 리소스들이 들어갈 전체 네트워크 범위를 만든다.  
    - 예: `10.0.0.0/16`  

- **Subnet**  
    - VPC의 IP 주소 범위를 더 작은 네트워크 구역으로 나눈 것이다.  
    - EC2는 반드시 특정 Subnet 안에 배치된다.  
    - 예: VPC가 `10.0.0.0/16`이라면 `10.0.1.0/24`, `10.0.2.0/24`처럼 나눌 수 있다.  
    - 인터넷으로 가는 경로가 있으면 Public Subnet, 없으면 Private Subnet으로 구성할 수 있다.  

- **Route Table**  
    - 네트워크 트래픽을 어디로 보낼지 결정하는 경로 규칙표이다.  
    - 목적지 IP 주소를 보고 다음 경로를 결정한다.  
    - 예: `10.0.0.0/16 → local`  
    - 예: `0.0.0.0/0 → Internet Gateway`  
    - 즉, 패킷이 VPC 내부로 갈지 인터넷으로 갈지 결정한다.  

- **Internet Gateway**  
    - VPC와 인터넷을 연결하는 출입구이다.  
    - VPC에 연결해서 사용한다.  
    - Internet Gateway만 연결한다고 인터넷이 되는 것은 아니고, Route Table에 `0.0.0.0/0 → Internet Gateway` 경로가 있어야 한다.  
    - 인터넷과 직접 통신해야 하는 EC2는 일반적으로 Public Subnet과 Public IP도 함께 필요하다.  










<br><br>

## 🟢 5단계: VPC 생성과 DNS 설정  

> Virtual Private Cloud  

#### ⚫️ VPC가 도대체 뭐지?  
- 예) 하나의 도시  
- VPC라는 이름은 AWS에서만 쓰는 것이지만,  
- 클라우드 안에서 격리된 사설 네트워크를 만든다는 개념 자체는 공통적인 네트워크 개념이다.  
    - 사설 네트워크로 나만의 울타리를 먼저 치고,  
    - 그 안에 중요한 시스템은 안쪽에 숨기고,  
    - 바깥에 공개할 것만 딱 정해서 문을 여는 개념이다.  
    - 사설망을 깔아놓고 거기서 필요한 통로만 골라서 여는 것!  


#### ⚫️ 여기서 하는 것  
1. VPC를 생성  
2. DNS 해석 기능을 활성화  
    - DNS를 활성화해야만 Domain 명칭(ex. naver.com)을 IP주소로 바꿔서 실제 접속을 할 수 있기 때문이다.  



<br>

### 🟡 여러 줄 명령  

```bash
# VPC를 생성하고 반환된 ID를 저장한다.  
VPC_ID="$(  
    aws ec2 create-vpc \  
        --cidr-block "$VPC_CIDR" \  
        --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${PROJECT}-vpc},{Key=Project,Value=${PROJECT}}]" \  
        --query 'Vpc.VpcId' \  
        --output text \  
        --profile "$PROFILE" \  
        --region "$REGION"  
)"  

# VPC가 available 상태가 될 때까지 기다린다.  
aws ec2 wait vpc-available \  
    --vpc-ids "$VPC_ID" \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# VPC 내부 DNS 해석 기능을 활성화한다.  
aws ec2 modify-vpc-attribute \  
    --vpc-id "$VPC_ID" \  
    --enable-dns-support '{"Value":true}' \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# Public DNS Hostname 기능을 활성화한다.  
aws ec2 modify-vpc-attribute \  
    --vpc-id "$VPC_ID" \  
    --enable-dns-hostnames '{"Value":true}' \  
    --profile "$PROFILE" \  
    --region "$REGION"  
```

<br>

### 🟡 한 줄 명령  

```bash
# VPC를 생성하고 반환된 ID를 저장한다.  
VPC_ID="$(aws ec2 create-vpc --cidr-block "$VPC_CIDR" --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${PROJECT}-vpc},{Key=Project,Value=${PROJECT}}]" --query 'Vpc.VpcId' --output text --profile "$PROFILE" --region "$REGION")"  

# VPC가 available 상태가 될 때까지 기다린다.  
aws ec2 wait vpc-available --vpc-ids "$VPC_ID" --profile "$PROFILE" --region "$REGION"  

# VPC 내부 DNS 해석 기능을 활성화한다.  
aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-support '{"Value":true}' --profile "$PROFILE" --region "$REGION"  

# Public DNS Hostname 기능을 활성화한다.  
aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames '{"Value":true}' --profile "$PROFILE" --region "$REGION"  
```

<br>

### 🟡 명령 의미  

| 명령·옵션 | 의미 |  
| :--- | :--- |
| `create-vpc` | 새 VPC 생성 |  
| `--cidr-block` | VPC IPv4 범위 지정 |  
| `--tag-specifications` | 생성과 동시에 Tag 지정 |  
| `wait vpc-available` | VPC 사용 가능 상태까지 대기 |  
| `modify-vpc-attribute` | VPC 설정 변경 |  
| `--enable-dns-support` | VPC 내부 DNS 해석 활성화 |  
| `--enable-dns-hostnames` | Public DNS Hostname 기능 활성화 |  









<br><br><br>

## 🟢 6단계: Public Subnet 생성  

> 서브넷(Subnetwork)  

#### ⚫️ 먼저 `Subnet`이란 뭘까?  
- 하나의 거대한 IP 네트워크를 논리적으로 분할하여 만든 더 작은 독립적 네트워크.  
    - IP 주소 공간을 `서브네팅`하여 나누어 형성된 것들 중 하나  
        - `서브네팅(Subnetting)`은 하나의 큰 IP 네트워크를 `서브넷 마스크(Subnet Mask)`를 사용하여 **네트워크 영역**과 **호스트 영역**으로 나누어, 여러 개의 작은 하위 네트워크(서브넷)로 나누는 행위/기술.  
            - 서브네팅의 작동 방식  
                - 비트 빌리기(Bit Borrowing): IP 주소 구조 변경  
                    - IP 주소의 호스트(Host) 영역 비트를 일부 가져와 서브넷(Subnet) 영역으로 할당함  
                    - 서브넷 마스크의 1의 개수를 늘려 네트워크 비트 범위를 확장함  
                    - 결과적으로 전체 호스트 수가 줄어드는 대신, 독립된 서브넷의 개수가 늘어남  
- 동일한 서브넷 내부의 기기들은 라우터를 거치지 않고 직접 통신함.  



#### ⚫️ 그렇다면 `Public Subnet`은 뭘까?  
- 정의 1. 특정 하나의 서브넷이 **외부 인터넷과 연결되면** 그것을 `Public Subnet`이라고 부른다.  
- 정의 2. 클라우드/네트워크 환경에서 서브넷이 외부 인터넷과 직접 통신이 가능하도록 인터넷 게이트웨이(IGW)로 향하는 라우팅 경로가 연결되어 있는 서브넷을 의미함.  
- 정의 3. 외부에서 직접 접근할 수 있는 공인 IP(Public IP)를 할당받거나, 인터넷 게이트웨이와 직접 연결된 라우팅 테이블(Routing Table)을 보유함.  




<br>

### 🟡 여러 줄 명령  

```bash
# VPC 안에 Public Subnet을 만들고 ID를 저장한다.  
SUBNET_ID="$(  
    aws ec2 create-subnet \  
        --vpc-id "$VPC_ID" \  
        --cidr-block "$SUBNET_CIDR" \  
        --availability-zone "$AZ" \  
        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PROJECT}-public-subnet},{Key=Project,Value=${PROJECT}}]" \  
        --query 'Subnet.SubnetId' \  
        --output text \  
        --profile "$PROFILE" \  
        --region "$REGION"  
)"  

# 새 EC2가 Public IPv4를 자동으로 받도록 설정한다.  
aws ec2 modify-subnet-attribute \  
    --subnet-id "$SUBNET_ID" \  
    --map-public-ip-on-launch \  
    --profile "$PROFILE" \  
    --region "$REGION"  
```

<br>

### 🟡 한 줄 명령  

```bash
# VPC 안에 Public Subnet을 만들고 ID를 저장한다.  
SUBNET_ID="$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block "$SUBNET_CIDR" --availability-zone "$AZ" --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PROJECT}-public-subnet},{Key=Project,Value=${PROJECT}}]" --query 'Subnet.SubnetId' --output text --profile "$PROFILE" --region "$REGION")"  

# 새 EC2가 Public IPv4를 자동으로 받도록 설정한다.  
aws ec2 modify-subnet-attribute --subnet-id "$SUBNET_ID" --map-public-ip-on-launch --profile "$PROFILE" --region "$REGION"  
```

<br>

### 🟡 명령 의미  

| 명령·옵션 | 의미 |  
| :--- | :--- |
| `create-subnet` | VPC 안에 Subnet 생성 |  
| `--vpc-id` | Subnet이 들어갈 VPC 지정 |  
| `--availability-zone` | Subnet을 만들 AZ 지정 |  
| `modify-subnet-attribute` | Subnet 설정 변경 |  
| `--map-public-ip-on-launch` | 새 EC2에 Public IPv4 자동 할당 |  







<br><br><br>

## 🟢 7단계: Internet Gateway 생성과 연결  


> Internet Gateway  


#### ⚫️ Internet Gateway 무엇인가?  
- VPC와 인터넷을 연결하는 출입구이다.  
- VPC에 연결해서 사용한다.  
- Internet Gateway만 연결한다고 인터넷이 되는 것은 아니고, Route Table에 `0.0.0.0/0 → Internet Gateway` 경로가 있어야 한다.  
- 인터넷과 직접 통신해야 하는 EC2는 일반적으로 Public Subnet과 Public IP도 함께 필요하다.  


<br>

### 🟡 여러 줄 명령  

```bash
# Internet Gateway를 만들고 ID를 저장한다.  
IGW_ID="$(  
    aws ec2 create-internet-gateway \  
        --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${PROJECT}-igw},{Key=Project,Value=${PROJECT}}]" \  
        --query 'InternetGateway.InternetGatewayId' \  
        --output text \  
        --profile "$PROFILE" \  
        --region "$REGION"  
)"  

# Internet Gateway를 VPC에 연결한다.  
aws ec2 attach-internet-gateway \  
    --internet-gateway-id "$IGW_ID" \  
    --vpc-id "$VPC_ID" \  
    --profile "$PROFILE" \  
    --region "$REGION"  
```

<br>

### 🟡 한 줄 명령  

```bash
# Internet Gateway를 만들고 ID를 저장한다.  
IGW_ID="$(aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${PROJECT}-igw},{Key=Project,Value=${PROJECT}}]" --query 'InternetGateway.InternetGatewayId' --output text --profile "$PROFILE" --region "$REGION")"  

# Internet Gateway를 VPC에 연결한다.  
aws ec2 attach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" --profile "$PROFILE" --region "$REGION"  
```

<br>

### 🟡 명령 의미  

| 명령 | 의미 |  
| :--- | :--- |
| `create-internet-gateway` | 인터넷 출입구 생성 |  
| `attach-internet-gateway` | Internet Gateway를 VPC에 연결 |  









<br><br><br>

## 🟢 8단계: Public Route Table 생성과 연결  

> Route Table  


#### ⚫️ Route Table 무엇인가?  
- ex) 도로 안내판 / 내비게이션  
- 네트워크 트래픽을 어디로 보낼지 결정하는 경로 규칙표이다.  
- 목적지 IP 주소를 보고 다음 경로를 결정한다.  
    - 예: `10.0.0.0/16 → local(VPC 내부 직접 통신)`  
    - 예: `0.0.0.0/0 → Internet Gateway`  
- 즉, 패킷이 VPC 내부로 갈지 인터넷으로 갈지 결정한다.  



#### ⚫️ Public Route Table은 무엇인가?  
- Public Subnet에 연결된 Route Table”을 그렇게 부르는 것  



<br>

### 🟡 여러 줄 명령  

```bash
# 사용자 정의 Route Table을 만들고 ID를 저장한다.  
RT_ID="$(  
    aws ec2 create-route-table \  
        --vpc-id "$VPC_ID" \  
        --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${PROJECT}-public-rt},{Key=Project,Value=${PROJECT}}]" \  
        --query 'RouteTable.RouteTableId' \  
        --output text \  
        --profile "$PROFILE" \  
        --region "$REGION"  
)"  

# 모든 외부 IPv4 목적지를 Internet Gateway로 보내는 경로를 만든다.  
aws ec2 create-route \  
    --route-table-id "$RT_ID" \  
    --destination-cidr-block 0.0.0.0/0 \  
    --gateway-id "$IGW_ID" \  
    --profile "$PROFILE" \  
    --region "$REGION"  

# Public Subnet을 Route Table에 연결하고 Association ID를 저장한다.  
RT_ASSOC_ID="$(  
    aws ec2 associate-route-table \  
        --route-table-id "$RT_ID" \  
        --subnet-id "$SUBNET_ID" \  
        --query 'AssociationId' \  
        --output text \  
        --profile "$PROFILE" \  
        --region "$REGION"  
)"  
```

<br>

### 🟡 한 줄 명령  

```bash
# 사용자 정의 Route Table을 만들고 ID를 저장한다.  
RT_ID="$(aws ec2 create-route-table --vpc-id "$VPC_ID" --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${PROJECT}-public-rt},{Key=Project,Value=${PROJECT}}]" --query 'RouteTable.RouteTableId' --output text --profile "$PROFILE" --region "$REGION")"  

# 모든 외부 IPv4 목적지를 Internet Gateway로 보내는 경로를 만든다.  
aws ec2 create-route --route-table-id "$RT_ID" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID" --profile "$PROFILE" --region "$REGION"  

# Public Subnet을 Route Table에 연결하고 Association ID를 저장한다.  
RT_ASSOC_ID="$(aws ec2 associate-route-table --route-table-id "$RT_ID" --subnet-id "$SUBNET_ID" --query 'AssociationId' --output text --profile "$PROFILE" --region "$REGION")"  

```



<br>

### 🟡 명령 의미  

| 명령·옵션 | 의미 |  
| :--- | :--- |
| `create-route-table` | 새 Route Table 생성 |  
| `create-route` | 목적지 경로 추가 |  
| `0.0.0.0/0` | 모든 외부 IPv4 목적지 |  
| `--gateway-id` | 목적지로 사용할 IGW 지정 |  
| `associate-route-table` | Route Table을 Subnet에 연결 |  
| `AssociationId` | 나중에 연결을 해제할 때 사용할 ID |  







<br>

### 🟡 실제 log

```bash
# 실제 log
xxx@xxx ~ % RT_ID="$(aws ec2 create-route-table --vpc-id "$VPC_ID" --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${PROJECT}-public-rt},{Key=Project,Value=${PROJECT}}]" --query 'RouteTable.RouteTableId' --output text --profile "$PROFILE" --region "$REGION")"

xxx@xxx ~ % echo $RT_ID
rtb-0946c365525d63f0c

xxx@xxx ~ % aws ec2 create-route --route-table-id "$RT_ID" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID" --profile "$PROFILE" --region "$REGION"
{
    "Return": true
}

xxx@xxx ~ % RT_ASSOC_ID="$(aws ec2 associate-route-table --route-table-id "$RT_ID" --subnet-id "$SUBNET_ID" --query 'AssociationId' --output text --profile "$PROFILE" --region "$REGION")"
```


