# EKS 클러스터 생성
## 1. 클러스터 생성을 위한 config 파일 작성
다음의 Config File 템플릿에서 각 변수들을 환경에 맞춰 변경하고 파일을 생성한다.
상세한 Config File Schema는 https://eksctl.io/usage/schema/ 를 참고한다.
```
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: <CLUSTER_NAME>                 # EKS 클러스터 이름
  region: <REGION>                     # ex) ap-northeast-2 (서울리전)
  version: <VERSION>                   # kubernetes 버전(최신:1.19)
  tags:
    ServiceName: <SERVICE_NAME>        # 서비스명

kubernetesNetworkConfig:
  serviceIPv4CIDR: <SERVICE_IPV4_CIDR> # Service Cluster IP CIDR

vpc:
#  cidr: <VPC_CIDR_BLOCK>              # 네트워크 자동 생성을 원하면 VIC CIDR BLOCK 을 지정하고 subnet 정보는 작성하지 않는다.
  subnets:
    public:
      <PUBLIC_AZ1>:                    # ex) ap-northeast-2a
        id: <PUBLIC_SUBNET_ID1>
      <PUBLIC_AZ2>:                    # ex) ap-northeast-2c
        id: <PUBLIC_SUBNET_ID2>
    private:
      <PRIVATE_AZ1>:                   # ex) ap-northeast-2a
        id: <PRIVATE_SUBNET_ID1>
      <PRIVATE_AZ2>:                   # ex) ap-northeast-2c
        id: <PRIVATE_SUBNET_ID2>
  clusterEndpoints:
    publicAccess: true                 # 인터넷으로 EKS 접근이 필요한 경우(default: false)
    privateAccess: true                # 내부망에서 EKS 접근이 필요한 경우(default: true)

#privateCluster:
#  enabled: true
```
예시) cluster.yaml 이라는 이름으로 파일 생성
```
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: testproject-dev-an2-eks
  region: ap-northeast-2
  version: "1.19"
  tags:
    ServiceName: testproject
    Name: testproject-dev-an2-eks

kubernetesNetworkConfig:
  serviceIPv4CIDR: 10.244.0.0/17

vpc:
#  cidr: 100.64.15.0/24
  subnets:
    public:
      ap-northeast-2a:
        id: subnet-014949df6a0c90586
      ap-northeast-2c:
        id: subnet-01a7585016c08bca0
    private:
      ap-northeast-2a:
        id: subnet-1ad0a228062a1d915
      ap-northeast-2c:
        id: subnet-055552646fd1339d8
  clusterEndpoints:
    publicAccess: true
    privateAccess: true

#privateCluster:
#  enabled: true
```

## 2. 클러스터 생성
eksctl 명령을 수행하여 클러스터를 생성한다. ( 약 25분 소요 - 생성 12~15분, 업데이트 10분 )
```
$ eksctl create cluster -f cluster.yaml
```
(publicAccess를 false로 구성한 경우) EKS Control Plane을 Public에서 접근할 수 있도록 임시로 endpoint를 활성화시킨다. (외부에서 kubectl 명령 수행시 Public Access 가 허용되어야 접근 가능하다.)
```
$ eksctl utils update-cluster-endpoints --cluster testproject-dev-an2-eks --approve --public-access
```