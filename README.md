EKS 클러스터 구성
```
2020.11.16 기준
- aws-cli : 2.1.1
- eksctl  : 0.31.0
```

# 0. 작업 폴더 구분 
```
00.BASTION                  // bastion 서버 구성 관련 파일
01.SET-EKS-ENV              // EKS Cluster 구성 관련 파일
02.NGINX-INGRESS-CONTROLLER // ingress controller 구성 관련 파일
03.MONITORING               // prometheus, grafana 구성 관련 파일
04.LOGGING                  // EFK(elasticsearch + fluentbit + kibana) 구성 관련 파일
05.ISTIO                    // ISTIO 구성 관련 파일
06.CICD                     // CICD 구성 관련 파일
07.APP_CICD                 // CICD 테스트용 APP 관련 파일
08.APP_SIMPLE               // SAMPLE APP 관련 파일
```

# 1.Bastion 서버 구성
## 1.1. Bastion 서버(EC2) 생성 및 접속
### 1.1.1. Bastion 서버(EC2) 생성
    1. EC2 메뉴에서 "인스턴스 시작"
    2. AMI 선택 메뉴에서 Amazon Linux 2 선택
    3. 인스턴스 유형 선택 메뉴에서 "t2.micro" 선택 - 사양 최소로 해도 됨
    4. 인스턴스 세부 정보 구성 메뉴에서 퍼블릭 IP 자동 할당 "활성화" 선택
    5. 스토리지 추가 메뉴에서 크기를 30Gb(30Gb까지 무료)로 수정
    6. Tag 지정에 키 : Name / 값 : 자기가 알아볼 수 있는 서버이름(ex. skcc07715-bastion) 추가
    7. 보안 그룹 구성 메뉴에서 "기존 보안 그룹 선택" default 그룹 지정
       - 자기만 접속할 수 있도록 보안 그룹 생성하려면 "새 보안 그룹 생성" 선택하고 보안 설정
    8. 검토 및 시작에서 정보 확인(형식적으로;;)하고 "시작하기" 클릭
       - 키 페어 선택 창이 뜨면 "새 키 페어 생성" 선택하고 키 페어 이름 입력(ex. skcc07715)후 다운로드 후 "인스턴스 시작" 클릭하여 생성
       - 기존에 생성해 둔 키 페어가 있을 경우 "기존 키 페어 선택" 선택하고 키 페어 정보 선택한 뒤 "인스턴스 시작" 클릭하여 생성
### 1.1.2. Bastion 서버(EC2) 접속(mobaxterm 사용)
    1. https://mobaxterm.mobatek.net/download-home-edition.html 에서 아무 버전(Portable or Installer)다운로드 및 설치(Installer 버전)
    2. AWS 콘솔에서 EC2에서 생성한 Bastion 서버의 Public IP 복사
    3. mobaxterm 실행 후 "Session" 아이콜 클릭 후 SSH 클릭
    4. Remote host : "Bastion 서버 IP 주소" 입력
    5. Specify username 체크 후 : "ec2-user" 입력
    6. Advanced SSH settings 에서 Use private key 체크 후 key 파일 경로 선택
## 1.2. AWS(EKS) 관리 환경 구성
### 1.2.1. awscli 설치
    # 다운로드 및 설치
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install

    # 이미 awscli가 설치되어 있어서 업데이트 할땐
    sudo ./aws/install --update

    # 버전 확인
    aws --version
### 1.2.2. AWS 액세스 키 생성
    1. https://console.aws.amazon.com/iam/home#/users 접속
    2. 자신의 "사용자 이름" 찾아서 클릭
    3. 사용자 정보에서 "보안 자격 증명" 탭 클릭
    4. "액세스 키 만들기" 버튼 클릭
       > 생성된 "액세스 키 ID" 와 "비밀 엑세스 키" 정보 복사 ( csv 파일 다운로드 하면 해당 정보 저장됨 )
       > 복사하지 않고 팝업 화면을 닫아버리면 다시 만들어야 함 ( 정보 확인 불가 )
### 1.2.3. aws 접속 설정
    aws configure
    - AWS Access Key ID [None]:            // 1.2.2. 에서 만든 "액세스 키 ID" 값 입력
    - AWS Secret Access Key [None]:        // 1.2.2. 에서 만든 "비밀 엑세스 키" 값 입력
    - Default region name [None]:          // 사용할 리전 입력 (ex. 서울리전 : ap-northeast-2 )
    - Default output format [None]:        // json
    
    # configure 가 제대로 적용되었는지 확인
    EC2_NAME=[내 bastion 서버 Tag 의 Name(ex. skcc07715-bastion)]
    aws ec2 describe-instances --filters Name=tag:Name,Values=${EC2_NAME}
    # 설정이 제대로 되었다면 bastion 서버 정보가 json 포멧으로 출력됨
### 1.2.4. eksctl 다운로드
    # 2020-11-17 기준 최신 버전 : 0.31.0
    # 다운로드 및 설치
    sudo curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C ./
    sudo mv ./eksctl /usr/local/bin

    # 버전 확인
    eksctl version
    
    # eksctl 자동완성 기능 설정
    eksctl completion bash >> ~/.bash_completion
    . /etc/profile.d/bash_completion.sh
    . ~/.bash_completion
### 1.2.5. kubectl 다운로드
    # 2020-11-17 기준 최신 버전 : 1.18.8
    # 다운로드 및 설치
    curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.18.8/2020-09-18/bin/linux/amd64/kubectl
    chmod 755 kubectl
    sudo mv kubectl /usr/local/bin

    # 버전 확인
    kubectl version --short --client
### 1.2.6. git 설치
    sudo yum install -y git
### 1.2.7. jq 설치
    sudo curl -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -o /usr/local/bin/jq
    sudo chmod a+x /usr/local/bin/jq
### 1.2.8. helm 설치
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
    chmod 700 get_helm.sh
    ./get_helm.sh

    helm version
---
# 2. EKS 클러스터 & 노드 그룹 생성
```
- 작업경로 : 01.SET-EKS-ENV
```

- 다음의 yaml 포멧을 사용하여 EKS 클러스터와 노드 그룹을 생성한다.

      # An example of ClusterConfig object with custom VPC IPv4 CIDR,
      # and auto-allocated IPv6 CIDRs for all subnets; also without
      # any nodegroups:
      ---
      apiVersion: eksctl.io/v1alpha5
      kind: ClusterConfig

      metadata:
        name: {{클러스터이름}}
        region: {{리전이름}}
        version: "1.18"            # 2020-11-17 기준 최신 버전 : 1.18

      vpc:
        cidr: {{CIDR블록설정}}      # ex. 10.15.0.0/16
        clusterEndpoints:
          publicAccess: true
          privateAccess: true

      nodeGroups: []
      managedNodeGroups:
        - name: {{노드그룹이름}}     # ex. worker-node-mng
          tags:
            nodegroup-role: "worker"
            managed: "true"
          labels:
            role: worker
          instanceType: t3.medium
          privateNetworking: true
          minSize: 3
          desiredCapacity: 4
          maxSize: 5
          volumeSize: 20
          ssh:
            allow: true

## 2.1. EKS 클러스터 생성
- 클러스터와 노드 그룹을 한 번에 생성할 수도 있으나 eksctl 버전에 따라 노드 그룹 생성 오류가 발생해서 클러스터만 먼저 생성한 뒤에 노드 그룹을 생성한다.

      eksctl create cluster -f create_cluster_worker.managednodegroup.yaml --without-nodegroup

      or

      eksctl create cluster -f create_cluster_worker.nodegroup.yaml --without-nodegroup

## 2.2. Node Group 생성 & Label 설정
### 2.2.1. Node Group 생성
- Managed Node Group 생성

      eksctl create cluster -f create_cluster_worker.managednodegroup.yaml --without-nodegroup

- Non-managed Node Group 생성

      eksctl create cluster -f create_cluster_worker.nodegroup.yaml        --without-nodegroup

### 2.2.2. 노드에 Label 설정
- Node Group 생성 후 노드 정보를 확인(kubectl get node)하면 ROLES 정보가 none 으로 표기된다.

      $ kubectl get node
      NAME                                               STATUS   ROLES    AGE   VERSION
      ip-10-15-105-124.ap-southeast-2.compute.internal   Ready    <none>   20h   v1.18.9-eks-d1db3c
      ip-10-15-118-95.ap-southeast-2.compute.internal    Ready    <none>   20h   v1.18.9-eks-d1db3c
      ip-10-15-76-119.ap-southeast-2.compute.internal    Ready    <none>   20h   v1.18.9-eks-d1db3c
      ip-10-15-84-244.ap-southeast-2.compute.internal    Ready    <none>   20h   v1.18.9-eks-d1db3c

- 노드 별 Role 지정을 위해 Label 을 추가한다. ( 여기선 worker로 지정 )

      ### 노드 그룹 생성시 node의 label에 role=worker 로 설정한 상태에서 명령 수행이 가능하다.
      $ kubectl get node -lrole=worker | grep -v ^NAME | awk '{print $1}' | while read name; do kubectl label node  $name node-role.kubernetes.io/worker=true; done

      ### 적용 확인
      $ kubectl get node
      NAME                                               STATUS   ROLES    AGE   VERSION
      ip-10-15-105-124.ap-southeast-2.compute.internal   Ready    worker   20h   v1.18.9-eks-d1db3c
      ip-10-15-118-95.ap-southeast-2.compute.internal    Ready    worker   20h   v1.18.9-eks-d1db3c
      ip-10-15-76-119.ap-southeast-2.compute.internal    Ready    worker   20h   v1.18.9-eks-d1db3c
      ip-10-15-84-244.ap-southeast-2.compute.internal    Ready    worker   20h   v1.18.9-eks-d1db3c

## 2.3 Managed Node Group vs. Non-Managed Node Group
- Managed Node Group 과 Non-Managed Node Group(그냥 Node Group 이라고 함)의 차이는 간단하게 아래와 같이 eksctl 명령으로 생성시 적용 가능한 옵션(schema) 차이라고 보면 된다. AWS 에서 지원하는 최소한의 설정만으로 관리를 편하게 하려는 목적이라면 Managed Node Group을, 관리하는 환경에 맞춰 Customizing 이 필요한 경우 Non-Managed Node Group을 선택하여 생성하면 된다.

|eksctl schema|설명|NodeGroup|ManagedNodeGroup|
|---|---|---|---|
|name|노드 그룹 이름|O|O|
|ami|Custom ami 사용시 지정|O|X|
|amiFamily|AWS에서 지원하는 ami 지정|O|O|
|instanceType|노드의 EC2 type 지정|O|O|
|instancesDistribution||O|X|
|instancePrefix|EC2의 Name Tag(Prefix)|O|X|
|instanceName|EC2의 Name Tag(Name)|O|X|
|availabilityZones|사용할 AZ 지정|O|O|
|tags|tag 설정|O|O|
|privateNetworking|private subnet 사용 여부|O|O|
|securityGroups||O|X|
|desiredCapacity|초기 생성 node수|O|O|
|minSize|node 최대 수|O|O|
|maxSize|node 최소 수|O|O|
|asgMetricsCollection||O|X|
|ebsOptimized||O|X|
|volumeSize|node에 붙일 디스크 크기|O|O|
|volumeType|디스크 Type|O|X|
|volumeName|Name Tag 지정|O|X|
|volumeEncrypted|암호화 여부|O|X|
|volumeKmsKeyID||O|X|
|volumeIOPS||O|X|
|maxPodsPerNode|node에 생성되는 최대 POD 수|O|X|
|labels|label 설정|O|O|
|taints|taint 설정|O|X|
|classicLoadBalancerNames||O|X|
|targetGroupARNs||O|X|
|ssh|ssh로 노드 접속 설정|O|O|
|iam|iam 설정|O|O|
|bottlerocket||O|X|
|preBootstrapCommands|node 부팅시 추가 command 설정|O|X|
|overrideBootstrapCommand||O|X|
|clusterDNS||O|X|
|kubeletExtraConfig|kube config 추가|O|X|

## 2.9. EKS 클러스터 삭제
- EKS 클러스터와 노드 그룹 생성시 사용한 yaml 파일을 사용하여 삭제한다.

      # managed node group
      eksctl delete cluster -f create_cluster_worker.managednodegroup.yaml
      
      # non-managed node group
      eksctl delete cluster -f create_cluster_worker.nodegroup.yaml



---
# 3. Kubernetes 기본 구성
## 3.1. Nginx Ingress Controller 설치
```
- 작업경로 : 02.NGINX-INGRESS-CONTROLLER
- Helm Chart 버전(2020-11-17 기준) : ingress-nginx/ingress-nginx 버전 3.10.1
```
### 3.1.1. 외부 서비스용
    # Namespace 생성
    kubectl create namespace infra

    # 1.values.yaml.ingress-nginx-3.10.1.external 파일을 사용하여 Helm 배포
    helm install nginx-ingress-external ingress-nginx/ingress-nginx -f 1.values.yaml.ingress-nginx-3.10.1.external -n infra

### 3.1.2. 내부 서비스용 ( 내부망 or DC <-> AWS 간 연동 등에 사용시 )
    # Namespace 생성
    kubectl create namespace infra
    
    # 2.values.yaml.ingress-nginx-3.10.1.internal 파일을 사용하여 Helm 배포
    helm install nginx-ingress-external ingress-nginx/ingress-nginx -f 2.values.yaml.ingress-nginx-3.10.1.internal -n infra

### 3.1.3. 외부 서비스용 (고정IP적용 - LB IP를 Elastic IP로 고정하여 사용시)
    # 사전 작업
      1) VPC의 Elastic IP(탄력적 IP) 메뉴에서 EKS에서 사용하는 AZ마다 Elastic IP를 생성하고 allocation ID(할당ID)값을 메모한다.
      2) 3.values.yaml.ingress-nginx-3.10.1.external-eip 파일의 310 line 에서 allocation ID를 입력 (AZ 개수만큼 , 로 구분하여 입력)

    # Namespace 생성
    kubectl create namespace infra
    
    # 3.values.yaml.ingress-nginx-3.10.1.internal 파일을 사용하여 Helm 배포
    helm install nginx-ingress-external ingress-nginx/ingress-nginx -f 3.values.yaml.ingress-nginx-3.10.1.external-eip -n infra

# 4. 모니터링 구성
```
- 작업경로 : 03.MONITORING
- Helm Chart 버전(2020-11-17 기준) : prometheus-community/prometheus 버전 11.16.9
                                    grafana/grafana 버전 
- 참고 URL : https://www.eksworkshop.com/intermediate/240_monitoring/
```

## 4.1. metric-server 설치
- 메트릭 서버 : kubelet에서 metric 데이터를 수집해서 메모리에 저장하면서 apiserver를 통해 POD나 NODE의 metric 정보를 조회하는데 사용하는 API를 제공하는 서비스다. 간단한 정보 조회용(ex. kubectl top node)으로 설치한다고 보면 된다.

      # 2020-11-17 기준 최신 버전 : v0.4.0
      # 설치 ( git에 있는 yaml 파일경로로 바로 설치 )
      kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.4.0/components.yaml

## 4.2. Prometheus 설치
```
# 사전 작업 - values.yaml 수정사항
  1) Prometheus / Configmap Reloader 관련
    . prometheus alertrules configMap 참조하도록 extraConfigmapMounts 설정 수정
    . Reload 쪽 extraConfigmapMounts 도 수정해서 configMap 수정하면 Prometheus 재기동 없이 동적 반영
  2) alertmanager ( slack 연동 설정 )
    . slack 에 workspace 와 채널 생성
    . webhook app 추가하고 생성한 채널에 대한 webhook 생성
      - URL : https://hooks.slack.com/services/XXXXXXXXXXX/YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
    . 1.values.yaml.prometheus-11.16.9 파일의 alertmanager.yml 내용에 slack 연동 내용 추가
  3) alertrule 적용을 위한 ConfigMap 파일 생성
    . 5-1.configmap.prometheus-alerts.yaml 참고하여 수정(추가/삭제)

# NameSpace 생성
kubectl create namespace prometheus

# AlertRule ConfigMap 생성
kubectl apply -f 5-1.configmap.prometheus-alerts.yaml

# 1.values.yaml.prometheus-11.16.9 파일을 이용하여 Helm 배포
helm install  prometheus prometheus-community/prometheus -f 1.values.yaml.prometheus-11.16.9 -n prometheus

# web브라우저를 통해 접속하기 위해 ingress 생성
kubectl apply -f 9-1.ingress.prometheus.yaml
kubectl apply -f 9-2.ingress.alertmanager.yaml

# ingress controller LB IP 정보 확인 ( 사전에 "3.1. Nginx Ingress Controller 설치" 진행되어야 함 )
nslookup `kubectl -n infra get svc nginx-ingress-external-ingress-nginx-controller -o json | jq -r '.status.loadBalancer.ingress[].hostname'` | grep ^Address | tail -1 | awk '{print $2}'

# 확인한 LB IP를 PC의 hosts 파일에 추가
1.2.3.4 prometheus.ekstest.com
1.2.3.4 alertmanager.ekstest.com
```

## 4.3. Grafana 설치
```
# 사전 작업 - grafana.yaml 파일 작성 ( 4.2 에서 설치한 prometheus 연동 설정 적용 )

# NameSpace 생성
kubectl create namespace grafana

# grafana.yaml 파일을 사용하여 Helm 설치 ( values.yaml 은 기본값으로 설치해서 별도 파일 관리 X )
helm install grafana grafana/grafana \
    --namespace grafana \
    --set persistence.storageClassName="gp2" \
    --set persistence.enabled=true \
    --set adminPassword='alskfl12~!' \
    --values grafana.yaml

# web브라우저를 통해 접속하기 위해 ingress 생성
kubectl apply -f 9-3.ingress.grafana.yaml

# ingress controller LB IP 정보 확인 ( 사전에 "3.1. Nginx Ingress Controller 설치" 진행되어야 함 )
nslookup `kubectl -n infra get svc nginx-ingress-external-ingress-nginx-controller -o json | jq -r '.status.loadBalancer.ingress[].hostname'` | grep ^Address | tail -1 | awk '{print $2}'

# 확인한 LB IP를 PC의 hosts 파일에 추가
1.2.3.4 grafana.ekstest.com
```

- Grafana 접속 후 Sample 대시보드 생성

      # 1. Cluster 모니터링
      #    - '+' 버튼 누르고 'Import' 메뉴 클릭
      #    - Grafana.com Dashboard 칸에 '3119' 입력하고 'Load' 버튼 클릭
      #    - data sources 에 'Prometheus' 선택하고 'Import' 버튼 클릭
      
      # 2. Pod 모니터링
      #    - '+' 버튼 누르고 'Import' 메뉴 클릭
      #    - Grafana.com Dashboard 칸에 '6417' 입력하고 'Load' 버튼 클릭
      #    - dashboard 이름을 'Kubernetes Pods Monitoring'으로 수정
      #    - data sources 에 'Prometheus' 선택하고 'Import' 버튼 클릭

# 5. 로깅 구성
```
- 작업경로 : 04.LOGGING
- 참고 URL : https://www.eksworkshop.com/intermediate/230_logging/
```
## 5.1. EFK(elasticsearch, fluentd, kibana) 구성
### 5.1.1. 환경 변수 설정
    export AWS_REGION={{리전이름}}
    export ACCOUNT_ID=`aws sts get-caller-identity | jq -r .Account`
    export CLUSTER_NAME={{EKS클러스터이름}}
    export ES_DOMAIN_NAME="eks-${CLUSTER_NAME}-logging"
    export ES_VERSION="7.8"                  ## 2018-11-17 기준 최신 버전 : 7.8
    export ES_DOMAIN_USER="admin"
    export ES_DOMAIN_PASSWORD="{{어드민패스워드}}"
    export FLUENT_BIT_POLICY="${CLUSTER_NAME}-fluent-bit-policy"

### 5.1.2. IAM 구성
    ##### a. Enabling IAM roles for service accounts on your cluster
    eksctl utils associate-iam-oidc-provider \
        --cluster ${CLUSTER_NAME} \
        --approve

    ##### b. Creating an IAM role and policy for your service account
    # 작업용 폴더 생성
    mkdir ./logging/

    # policy 생성을 위한 json 파일 작성
    cat <<EoF > ./logging/fluent-bit-policy.json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "es:ESHttp*"
                ],
                "Resource": "arn:aws:es:${AWS_REGION}:${ACCOUNT_ID}:domain/${ES_DOMAIN_NAME}"
            }
        ]
    }
    EoF

    # policy 생성
    cp ./logging/fluent-bit-policy.json ~/fluent-bit-policy.json
    aws iam create-policy   \
      --policy-name ${FLUENT_BIT_POLICY} \
      --policy-document file://~/fluent-bit-policy.json
    rm ~/fluent-bit-policy.json

    ##### c. Create an IAM role
    kubectl create namespace logging

    # fluent-bit 에서 위에서 생성한 policy 에 접근할 수 있도록 iamserviceaccount 생성
    eksctl create iamserviceaccount \
        --name fluent-bit \
        --namespace logging \
        --cluster ${CLUSTER_NAME} \
        --attach-policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/${FLUENT_BIT_POLICY}" \
        --approve \
        --override-existing-serviceaccounts

    #### d. EKS 클러스터에 fluent bit 에 대한 ServiceAccount 생성 확인
    kubectl -n logging describe sa fluent-bit

### 5.1.3. ElasticSearch Service에 신규 Domain 생성
    ##### a. Create ES Domain
    # ES Domain 생성을 위한 json 파일 생성
    curl -sS https://www.eksworkshop.com/intermediate/230_logging/deploy.files/es_domain.json \
      | envsubst > ./logging/es_domain.json

    # ES Domain 생성
    cp ./logging/es_domain.json ~/es_domain.json
    aws es create-elasticsearch-domain \
      --cli-input-json  file://~/es_domain.json
    rm ~/es_domain.json

    ##### b. ES 생성 확인 ( 약 10~12분 정도 걸림 )
    while true
    do
      if [ $(aws es describe-elasticsearch-domain --domain-name ${ES_DOMAIN_NAME} --query 'DomainStatus.Processing') == "false" ]; then
        tput setaf 2; echo "[`date +%H:%M:%S`] The Elasticsearch cluster is ready"   ; tput setaf 9
        break;
      else
        tput setaf 1; echo "[`date +%H:%M:%S`] The Elasticsearch cluster is NOT ready"; tput setaf 9
      fi
      sleep 10
    done

    ##### c. CONFIGURE ELASTICSEARCH ACCESS ( ElasticSearch 에 접속할 수 있는 권한 부여 )
    export FLUENTBIT_ROLE=$(eksctl get iamserviceaccount --cluster ${CLUSTER_NAME} --namespace logging -o json | jq '.iam.serviceAccounts[].status.roleARN' -r)
    export ES_ENDPOINT=$(aws es describe-elasticsearch-domain --domain-name ${ES_DOMAIN_NAME} --output text --query "DomainStatus.Endpoint")

    curl -sS -u "${ES_DOMAIN_USER}:${ES_DOMAIN_PASSWORD}" \
        -X PATCH \
        https://${ES_ENDPOINT}/_opendistro/_security/api/rolesmapping/all_access?pretty \
        -H 'Content-Type: application/json' \
        -d'
    [
      {
        "op": "add", "path": "/backend_roles", "value": ["'${FLUENTBIT_ROLE}'"]
      }
    ]
    '

### 5.1.4. Fluent-bit 설치
    ##### a. 설치용 템플릿 파일 생성
    curl -Ss https://www.eksworkshop.com/intermediate/230_logging/deploy.files/fluentbit.yaml \
        | envsubst > ./logging/fluentbit.yaml

    ##### b. 템플릿 파일에서 일부 내용 수정 - label 이 맞지 않아 수정 필요
    perl -pi -e "s/k8s-app: fluent-bit/app: fluent-bit/g" ./logging/fluentbit.yaml

    ##### c. 배포(fluentbit 설치)
    kubectl apply -f ./logging/fluentbit.yaml

    ##### d. 확인 ( daemonset으로 각 노드에 1개씩 잘 뜨는지 확인 )
    kubectl -n logging get pod -o wide

### 5.1.5. Kibana 에서 Index Pattern 생성 및 사용
    ##### a. KIBANA URL 확인 후 접속(웹브라우저)
    KIBANA_URL="https://$ES_ENDPOINT/_plugin/kibana"; echo $KIBANA_URL

    ##### b. kibana 접속 후 아래 순서로 index 등록
    1. 메인화면에서 "Connect to your Elasticsearch index" 클릭
    2. Index pattern 에 "*fluent-bit*" 입력 후 "Next step" 클릭
    3. Time Filter field name 에 "@timestamp" 선택 후 "Create Index Pattern" 클릭

    ##### c. discover 에서 로그가 정상적으로 조회되는지 확인

## 5.9. EFK(elasticsearch, fluentd, kibana) 삭제
    ##### a. 환경 변수 설정
    export AWS_REGION={{리전이름}}
    export ACCOUNT_ID=`aws sts get-caller-identity | jq -r .Account`
    export CLUSTER_NAME={{EKS클러스터이름}}
    export ES_DOMAIN_NAME="eks-${CLUSTER_NAME}-logging"
    export ES_VERSION="7.8"                  ## 2018-11-17 기준 최신 버전 : 7.8
    export ES_DOMAIN_USER="admin"
    export ES_DOMAIN_PASSWORD="{{어드민패스워드}}"
    export FLUENT_BIT_POLICY="${CLUSTER_NAME}-fluent-bit-policy"

    ##### b. fluentbit 삭제
    kubectl delete -f ./logging/fluentbit.yaml

    ##### c. ES 삭제
    aws es delete-elasticsearch-domain \
        --domain-name ${ES_DOMAIN_NAME}

    ##### d. iam service account 삭제
    eksctl delete iamserviceaccount \
        --name fluent-bit \
        --namespace logging \
        --cluster ${CLUSTER_NAME} \
        --wait

    ##### e. iam policy 삭제
    aws iam delete-policy   \
      --policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/${FLUENT_BIT_POLICY}"

    ##### f. logging namespace 삭제
    kubectl delete namespace logging
---

# 6. istio 구성
```
- 작업경로 : 05.ISTIO
- 참고사이트 : istio 공식 사이트(https://istio.io)
```
## 6.1. Istio 설치
    # 2020-11-19 : 1.7.5 / 1.8.0 동시 released 되었는데 1.7.5로 구성 테스트 진행
### 6.1.1. 설치 파일 다운로드 및 설치
    # 설치 파일 다운로드
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.7.5 TARGET_ARCH=x86_64 sh -

    # PATH 설정
    cd istio-1.7.5
    export PATH=$PWD/bin:$PATH

    # profile 지정하여 설치
    istioctl install --set profile=demo

* istio 설치 profile 별 구성되는 Core components 정보는 아래와 같다.

|Core components|default|demo|minimal|remote|empty|preview|
|---|---|---|---|---|---|---|
|istio-egressgateway||O|||||
|istio-ingressgateway|O|O||||O|
|istiod|O|O|O|||O|

### 6.1.2. addon 서비스 설치
* 모든 addon 한방에 설치하기

      kubectl apply -f samples/addons -n istio-system
* 개별 addon 선택하여 설치하기 (ex. prometheus)

      kubectl apply -f samples/addons/prometheus.yaml -n istio-system

* addon 정보는 아래 링크를 참고한다.
https://github.com/istio/istio/blob/master/samples/addons/README.md

* kiali /jarget 접속을 위한 ingress 배포

      kubectl apply -f ../ingress.kiali.yaml
      kubectl apply -f ../ingress.jaeger.yaml

* ingress controller LB IP 정보 확인 ( 사전에 "3.1. Nginx Ingress Controller 설치" 진행되어야 함 )

      nslookup `kubectl -n infra get svc nginx-ingress-external-ingress-nginx-controller -o json | jq -r '.status.loadBalancer.ingress[].hostname'` | grep ^Address | tail -1 | awk '{print $2}'

* 확인한 LB IP를 PC의 hosts 파일에 추가

      1.2.3.4 kiali.ekstest.com
      1.2.3.4 jaeger.ekstest.com


## 6.2. Istio 테스트 ( Book Info )
### 6.2.1. 테스트용 namespace에 label 설정
istio 를 통해 application 흐름 제어를 하기 위해서는 해당 application이 배포되는 namespace에 <b>istio-injection=enabled</b> label을 설정해야 한다.

    kubectl label namespace default istio-injection=enabled

### 6.2.2. Book Info application 구성도
* Bookinfo Application without Istio

![Image of Bookinfo without Istio](https://istio.io/latest/docs/examples/bookinfo/noistio.svg)

* Bookinfo Application with Istio

![Image of Bookinfo with Istio](https://istio.io/latest/docs/examples/bookinfo/withistio.svg)


### 6.2.3. Book Info application 배포
    # sample app 배포
    kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
    
    # 배포 확인
    kubectl get services
    kubectl get pods

    # 클러스터 내부에서 서비스 호출 테스트 ( product page 호출해서 title 정보 확인 )
    kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -s productpage:9080/productpage | grep -o "<title>.*</title>"
    # 출력 결과
    <title>Simple Bookstore App</title>

    # 웹브라우저 호출 테스트를 위한 ingress 배포
    kubectl apply -f ../ingress.productpage.yaml

    # ingress controller LB IP 정보 확인 ( 사전에 "3.1. Nginx Ingress Controller 설치" 진행되어야 함 )
    nslookup `kubectl -n infra get svc nginx-ingress-external-ingress-nginx-controller -o json | jq -r '.status.loadBalancer.ingress[].hostname'` | grep ^Address | tail -1 | awk '{print $2}'

    # 확인한 LB IP를 PC의 hosts 파일에 추가
    1.2.3.4 productpage.ekstest.com

    # 웹브라우저에서 호출 ( ingress controller )
    http://productpage.ekstest.com/productpage

    # kiali에서 유입 확인
    productpage를 호출하는 source가 "unknown" 으로 표기됨.

### 6.2.4. Book Info GateWay/VirtualService/DestinationRule 배포
    # GateWay/Virtual Service 생성
    kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
    # Destination Rule 생성
    kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml

    # GateWay/Virtual Service/DestinationRule 생성 확인
    kubectl get gateway
    kubectl get virtualservice
    kubectl get destinationrule

    # istio gateway 의 dns 정보 확인
    nslookup `kubectl -n istio-system get svc istio-ingressgateway -o json | jq -r '.status.loadBalancer.ingress[].hostname'` | grep ^Address | tail -1 | awk '{print $2}'

    # 확인한 LB IP를 PC의 hosts 파일에 추가
    1.2.3.4 istio.ekstest.com

    # 웹브라우저에서 호출 ( istio gateway )
    http://istio.ekstest.com/productpage

    # kiali에서 유입 확인
    productpage를 호출하는 source가 "istio gateway"로 표기됨.

### 6.2.5. Istio network flow 제어 테스트
* Reviews 로그인 사용자별 분기

      # reviews 로그인 사용자별 분기 적용(virtual service 배포)
      kubectl apply -f virtual-service-reviews-byuser.yaml

      # kiali 확인
      reviews 서비스에 virtualservice 표기 추가됨

      # 서비스 확인 1 - productpage 호출 ( reviews v1 호출 )
      http://istio.ekstest.com/productpage

      # 서비스 확인 2 - productpage 호출하고 "infra" 로그인 ( reviews v2 호출 )
      http://istio.ekstest.com/productpage

      # 서비스 확인 3 - productpage 호출하고 "jason" 로그인 ( reviews v3 호출 )
      http://istio.ekstest.com/productpage

* Ratings 사용자별 delay 적용

      # ratings 에 jason 사용자 호출시 2초 delay
      kubectl apply -f virtual-service-ratings-test-delay-2sec.yaml

      # 서비스 확인 - productpage 호출하고 "jason" 로그인시 2초 후 화면 로딩
      http://istio.ekstest.com/productpage

      # ratings 에 jason 사용자 호출시 3초 delay
      kubectl apply -f virtual-service-ratings-test-delay-3sec.yaml

      # 서비스 확인 - productpage 호출하고 "jason" 로그인시 3초 후 ratings 화면 에러 표기
        ( reviews 에 2.5초 timeout 적용되어 있음 )
      http://istio.ekstest.com/productpage


### 6.2.6. circuit breaker 적용 ( TBD )

## 6.9 Istio 삭제
### 6.9.1. Book Info Application 삭제
```
samples/bookinfo/platform/kube/cleanup.sh
```

### 6.9.2. Addon 서비스 삭제
```
kubectl delete -f samples/addons
```

### 6.9.3. istio 삭제
```
istioctl manifest generate --set profile=demo | kubectl delete --ignore-not-found=true -f -
```

### 6.9.4. Label / Namespace 삭제
```
kubectl label namespace default istio-injection-

kubectl delete namespace istio-system
```
---

# 7. CICD 구성 및 application 배포
> 1. Simple App
- apple/banana
- guestbook(w/redis)
> 2. CICD App
- CICD 구성
- bff / restapi app 배포 ( DB 연동 이슈 발생할 수 있음 )


