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
```
<span style="color:orange">*복사하지 않고 팝업 화면을 닫으면 재조회가 불가능하기 때문에 다시 생성해야 한다.*</span>
