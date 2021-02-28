# Bastion 서버 구성

## 1. Bastion 서버(EC2) 생성
```
1. EC2 메뉴에서 "인스턴스 시작"
2. AMI 선택 메뉴에서 Amazon Linux 2 선택
3. 인스턴스 유형 선택 메뉴에서 "t2.micro" 선택 - 최소 사양으로 해도 됨
4. 인스턴스 세부 정보 구성 메뉴에서 퍼블릭 IP 자동 할당 "활성화" 선택
5. 스토리지 추가 메뉴에서 크기를 30Gb(프리티어는 30Gb까지 무료)로 수정
6. Tag 지정에 키 : Name / 값 : 자기가 알아볼 수 있는 서버이름(ex. testproject-bastion) 추가
7. 보안 그룹 구성 메뉴에서 "기존 보안 그룹 선택" default 그룹 지정
   - 자기만 접속할 수 있도록 보안 그룹 생성하려면 "새 보안 그룹 생성" 선택하고 보안 설정(현재 접속하는 IP만 허용)
8. 검토 및 시작에서 정보 확인(형식적으로;;)하고 "시작하기" 클릭
   - 키 페어 선택 창이 뜨면 "새 키 페어 생성" 선택하고 키 페어 이름 입력(ex. testproject-keypair)후 다운로드 후 "인스턴스 시작" 클릭하여 생성
   - 기존에 생성해 둔 키 페어가 있을 경우 "기존 키 페어 선택" 선택하고 키 페어 정보 선택한 뒤 "인스턴스 시작" 클릭하여 생성
```

## 2. Bastion 서버(EC2) 접속(mobaxterm 사용)
```
1. https://mobaxterm.mobatek.net/download-home-edition.html 에서 아무 버전(Portable or Installer)다운로드 및 설치(Installer 버전)
2. AWS 콘솔에서 EC2에서 생성한 Bastion 서버의 Public IP 복사
3. mobaxterm 실행 후 "Session" 아이콘 클릭 후 SSH 클릭
4. Remote host : "Bastion 서버 IP 주소" 입력
5. Specify username 체크 후 : "ec2-user" 입력
6. Advanced SSH settings 에서 Use private key 체크 후 key 파일 경로 선택
```

# AWS CLI 구성
```
# 2021-02-27 기준 ( EKS까지 구성 고려 )
  - awscli : 2.1.28
  - jq : 1.6
  - git : 2.23.3 (CentOS)
  - eksctl : 0.38.0
  - kubectl : 1.19.6
  - kubectx, kubens
  - helm : v3.5.2
```

## 1. awscli 설치
```
## 다운로드 및 설치
$ curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
$ unzip awscliv2.zip
$ sudo ./aws/install

## 기존에 설치된 awscli 를 업그레이드할 때
$ sudo ./aws/install --update

## 버전 확인
$ aws --version
aws-cli/2.1.28 Python/3.8.8 Linux/5.4.72-microsoft-standard-WSL2 exe/x86_64.centos.7 prompt/off
```

## 2. aws  접속 설정(aws configure)
### 2.1. aws 엑세스 키 생성(액세스 키가 없을 경우에만 생성)
```
1. https://console.aws.amazon.com/iam/home#/users 접속
2. 자신의 IAM 계정명(사용자명)을 찾아 클릭
3. "보안 자격 증명" 탭 클릭
4. "액세스 키 만들기" 버튼 클릭
   - 생성된 "액세스 키 ID"와 "비밀 액세스 키" 정보 복사(csv 파일로 다운로드 가능)
   * 복사하지 않고 팝업 화면을 닫으면 재조회가 불가능하기 때문에 다시 생성해야 한다.
```

### 2.2. aws configure
```
## 접속 설정
$ aws configure
AWS Access Key ID [None]:            // 1.2.2. 에서 만든 "액세스 키 ID" 값 입력
AWS Secret Access Key [None]:        // 1.2.2. 에서 만든 "비밀 엑세스 키" 값 입력
Default region name [None]:          // 사용할 리전 입력 (ex. 서울리전 : ap-northeast-2 )
Default output format [None]:        // json

## configure 가 제대로 적용되었는지 확인 (S3 버킷 리스트 확인 명령)
$ aws s3 ls

## 실제 적용된 파일 확인 (default profile 로 설정되어 있음)
$ cat ~/.aws/config
[default]
region = ap-northeast-2
output = json
$ cat ~/.aws/credentials
[default]
aws_access_key_id = ABCDEFGHJIKLMNOPQRST
aws_secret_access_key = ABCDEFGHIJKLMNOPQRSTUVWXYZ12345678901234
```

## 3. jq
```
## 다운로드 및 권한 설정
$ sudo curl -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -o /usr/local/bin/jq
$ sudo chmod a+x /usr/local/bin/jq

## 버전 확인
$ jq --version
jq-1.6
```

## 4. git
```
## yum 을 사용해서 설치
$ sudo yum install -y git

## 버전 확인(centos 기준)
$ git version
git version 1.8.3.1
```

## 5. eksctl
```
## 다운로드 및 설치
$ sudo curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C ./
$ sudo mv ./eksctl /usr/local/bin

## 버전 확인
$ eksctl version
0.38.0

## eksctl 자동완성 기능 설정(bash_completion 설치되어 있어야 함)
$ eksctl completion bash >> ~/.bash_completion
$ . /etc/profile.d/bash_completion.sh
$ . ~/.bash_completion
```

## 6. kubectl
```
## 다운로드 및 설치
$ curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl
$ chmod 755 kubectl
$ sudo mv kubectl /usr/local/bin

## 버전 확인
$ kubectl version --short --client
```

## 7. kubectx, kubens
다수의 kubernetes 클러스터와 namespace 사용시 손쉬운 전환을 위해 설치
* 참고 : https://github.com/ahmetb/kubectx
```
$ sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
$ sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
$ sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
```

## 8. helm
```
## 설치 스크립트 다운로드 및 설치
$ curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
$ chmod 700 get_helm.sh
$ ./get_helm.sh
```
