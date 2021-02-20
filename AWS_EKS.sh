#######################################################################################
# Bastion 서버 생성 및 환경 구성
#######################################################################################

################################################
# [ 1. Bastion 서버(EC2) 생성 ]
################################################

# 1. EC2 메뉴에서 "인스턴스 시작"
#####

# 2. AMI 선택 메뉴에서 Amazon Linux 2 선택
#####

# 3. 인스턴스 유형 선택 메뉴에서 "t2.micro" 선택 - 사양 최소로 해도 됨
#####

# 4. 인스턴스 세부 정보 구성 메뉴에서 퍼블릭 IP 자동 할당 "활성화" 선택
#####

# 5. 스토리지 추가 메뉴에서 크기를 30Gb(30Gb까지 무료)로 수정
#####

# 6. Tag 지정에 키 : Name / 값 : 자기가 알아볼 수 있는 서버이름(ex. skcc07715-bastion) 추가
#####

# 7. 보안 그룹 구성 메뉴에서 "기존 보안 그룹 선택" default 그룹 지정
#####
# - 자기만 접속할 수 있도록 보안 그룹 생성하려면 "새 보안 그룹 생성" 선택하고 보안 설정

# 8. 검토 및 시작에서 정보 확인(형식적으로;;)하고 "시작하기" 클릭
#####
# - 키 페어 선택 창이 뜨면 "새 키 페어 생성" 선택하고 키 페어 이름 입력(ex. skcc07715)후 다운로드 후 "인스턴스 시작" 클릭하여 생성
# - 기존에 생성해 둔 키 페어가 있을 경우 "기존 키 페어 선택" 선택하고 키 페어 정보 선택한 뒤 "인스턴스 시작" 클릭하여 생성


################################################
# [ 2. AWS(EKS) 관리 환경 구성 ]
#   - 1) awscli 설치       : aws 계정 접근해서 사용하기 위해 설치
#   - 2) AWS 액세스 키 생성
#   - 3) aws 접속 설정
#   - 4) eksctl 다운로드   : EKS 클러스터 생성/관리를 위한 cli 프로그램
#   - 5) kubectl 다운로드  : kubernetes cli 프로그램
#   - 6) git 설치          : github 사용을 위한 프로그램
#   - 7) jq 설치           : json 처리하는 프로그램(aws나 kubernetes 자원에 대한 정보는 json 포멧으로 확인)
#   - 8) helm 설치         : helm chart 관리를 위한 cli 프로그램
################################################

# 1. awscli 설치 ( 2021-02-20 기준 awscli 2.1.27 최신 )
#####
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

aws --version

# 기존에 설치되어 있어서 업데이트 할때
#curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
#unzip awscliv2.zip
#sudo ./aws/install --update

#aws --version

# 2. AWS 액세스 키 생성
#####
# - https://console.aws.amazon.com/iam/home#/users 접속
# - 자신의 "사용자 이름" 찾아서 클릭
# - 사용자 정보에서 "보안 자격 증명" 탭 클릭
# - "액세스 키 만들기" 버튼 클릭
#   > 생성된 "액세스 키 ID" 와 "비밀 엑세스 키" 정보 복사 ( csv 파일 다운로드 하면 해당 정보 저장됨 )
#   > 복사하지 않고 팝업 화면을 닫아버리면 다시 만들어야 함 ( 정보 확인 불가 )

# 3. AWS 접속 설정
#####
aws configure
# - AWS Access Key ID [None]:     3. 에서 만든 "액세스 키 ID" 값 입력
# - AWS Secret Access Key [None]: 3. 에서 만든 "비밀 엑세스 키" 값 입력
# - Default region name [None]:   사용할 리전 입력(ex. 서울리전 : ap-northeast-2 )
# - Default output format [None]: json

# 내 bastion 서버 정보 확인 ( aws configure 가 제대로 되었는지 확인 )
EC2_NAME=[내 bastion 서버 Tag 의 Name(ex. skcc07715-bastion)]
aws ec2 describe-instances --filters Name=tag:Name,Values=${EC2_NAME}
# 설정이 제대로 되었다면 서버 정보가 json 포멧으로 출력됨

# 4. eksctl 다운로드 ( 2021-02-20 기준 eksctl 0.38.0 최신 )
#####
sudo curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

eksctl version

# eksctl 자동완성
eksctl completion bash >> ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion

# 5. kubectl 다운로드 ( 2021-02-20 기준 kubectl 1.19.6 최신 )
#####
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl
#curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.18.9/2020-11-02/bin/linux/amd64/kubectl
chmod 755 kubectl
sudo mv kubectl /usr/local/bin

kubectl version --short --client

# 6. git 설치
#####
sudo yum install -y git

# 7. jq 설치
#####
sudo curl -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -o /usr/local/bin/jq
sudo chmod a+x /usr/local/bin/jq

# 8-1. helm 설치
#####
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh

helm version

# 8-2. helm repo 추가 ( stable, ingress-nginx, prometheus, grafana )
#####
# 추가
helm repo add stable               https://charts.helm.sh/stable
helm repo add ingress-nginx        https://kubernetes.github.io/ingress-nginx
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana              https://grafana.github.io/helm-charts

# 확인
helm repo list
# repo 업데이트(최신버전 현행화)
helm repo update



#######################################################################################
# EKS 클러스터 구성
# - 2021-02-20
#   . 리전       : 시드니(ap-southeast-2) 사용           <- 개인별 수정해서 사용
#                  => 리전별로 VPC 기본 5개 제한, NAT G/W IP 기본 5개 제한되어서
#                     별도 신청해서 제한 개수를 늘려놓지 않은 상태라면 EKS 생성(VPC, NAT G/W IP 1개씩 필요)이 안될 수 있는데
#                     사람들이 서울 리전에서 테스트를 많이 해서 부족할 가능성이 높기 때문에 다른 리전 선택해서 테스트하는 것을 권고
#   . 클러스터명 : skcc07715                             <- 개인별 수정해서 사용
#   . k8s 버전   : 1.19  (최신 버전) 사용                <- 1.16, 1.17, 1.18, 1.19 중 선택
#   . VPC        : 100.64.0.0/24 사용                    <- 개인별 수정해서 사용
#   . AZ         : ap-southeast-2a, ap-southeast-2c 사용 <- 개인별 수정해서 사용(리전에 맞춰서)
#######################################################################################

################################################
# [ 1. EKS 클러스터 생성 ]
#   - 작업경로 : 01.SET-EKS-ENV
#     . managednodegroup or nodegroup yaml 이용해서 EKS 클러스터 생성
#     . --without-nodegroup 옵션 사용해서 클러스터만 생성하고 노드 그룹은 별도로 생성
#       => 클러스터 생성 후 업데이트 진행하는데 이때 managednodegroup 생성 오류 발생해서 따로 생성
#
#     . managednodegroup : 일반적인 속성만 지정해서 생성 ( 웹콘솔에서 관리 가능 )
#     . nodegroup        : 상세한 속성까지 지정해서 생성 가능 ( 웹콘솔에서 관리 불가능 - 보이지도 않음 )
#       => managednodegroup 으로 진행
#
#     . eksctl 로 생성시 실제 AWS 리소스 생성 확인하려면 "CloudFormation - Stack - eksctl-{클러스터명}-cluster" 에서 이벤트 정보 확인
#       - ServiceRole / VPC / InternetGateway / NATIP 생성
#       - VPC에 InternetGateway Attach
#       - Subnet 생성
#       - Security Group 생성
#       - 기본 모니터링 구성(CloudWatchMetrics 등)
#       - ControlPlane(Master node) 생성
#       - ...
################################################

# eksctl 명령 사용해서 EKS Cluster 생성
eksctl create cluster -f create_cluster_worker.managednodegroup.yaml --without-nodegroup
#eksctl create cluster -f create_cluster_worker.nodegroup.yaml        --without-nodegroup


################################################
# [ 2. Node Group 생성 & Label 설정 ]
#   - 작업경로 : 01.SET-EKS-ENV
################################################

# eksctl 명령 사용해서 NodeGroup 생성
eksctl create nodegroup -f create_cluster_worker.managednodegroup.yaml
#eksctl create nodegroup -f create_cluster_worker.nodegroup.yaml

# worker 노드에 대한 label 설정 ( kubectl get node 했을 때 ROLE : worker 로 표기되도록 )
kubectl get node -lrole=worker | grep -v ^NAME | awk '{print $1}' | while read name; do kubectl label node  $name node-role.kubernetes.io/worker=true; done


################################################
# [ 9. EKS 클러스터 삭제 ]
#   - 작업경로 : 01.SET-EKS-ENV
################################################

# 생성한 nodegroup에 따라 아래 2개 명령 선택하여 실행
eksctl delete cluster -f create_cluster_worker.managednodegroup.yaml
#eksctl delete cluster -f create_cluster_worker.nodegroup.yaml



#######################################################################################
# K8S 기본 구성
# - 1. Nginx Ingress Controller 설치
# - 2. 모니터링 - metric-server 설치
# - 3. 모니터링 - Proemtheus 설치
# - 4. 모니터링 - Grafana 설치
# - 5. 로깅     - Elasticsearch service 연동
#######################################################################################

################################################
# [ 1. Nginx ingress controller 설치 ]
#   - 작업경로 : 02.NGINX-INGRESS-CONTROLLER
#   - 2020-11-16 : ingress-nginx/ingress-nginx 버전 3.10.1
################################################

# 1. "infra" namespace 생성(infra 관리용)
kubectl create namespace infra

# 2-1. deploy external service(외부망)
helm install nginx-ingress-external ingress-nginx/ingress-nginx -f 1.values.yaml.ingress-nginx-3.10.1.external -n infra

# 2-2. deploy internal service(VPC 내부망)
#helm install nginx-ingress-external ingress-nginx/ingress-nginx -f 2.values.yaml.ingress-nginx-3.10.1.internal -n infra

# 3. 설치 확인 -  helm list
helm list -n infra

### 참고 - ingress controller 에 고정IP(Elastic IP) 를 적용
# 1) VPC의 Elastic IP(탄력적 IP) 메뉴에서 EKS에서 사용하는 AZ 개수만큼 Elastic IP를 생성하고 allocation ID(할당ID)값을 메모
# 2) 1.values.yaml.ingress-nginx-3.10.1.external-eip 파일의 310 line 에서 allocation ID를 입력 (AZ 개수만큼 , 로 구분하여 입력)
# 3) 1.values.yaml.ingress-nginx-3.10.1.external-eip 파일을 이용해서 ingress controller helm chart 배포
#    $ helm install nginx-ingress-external-eip ingress-nginx/ingress-nginx -f 3.values.yaml.ingress-nginx-3.10.1.external-eip -n infra


################################################
# [ 2. metric-server 설치 ]
#   - 참고 URL : https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/metrics-server.html
#   - 리소스 사용량 데이터 집계를 위해 설치(설치 후 kubectl top node 명령으로 사용량 확인 가능)
#   - 2020-11-05 : v0.4.0 release
################################################

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.4.0/components.yaml


################################################
# [ 3. prometheus 설치 ]
#   - 작업경로 : 03.MONITORING
#   - 2020-11-16 : prometheus-community/prometheus 버전 11.16.9
#   - 참고 URL : https://www.eksworkshop.com/intermediate/240_monitoring/
################################################
# namespace 생성
kubectl create namespace prometheus

# prometheus alertrule 생성
# - configMap 미리 생성해두고 helm chart 설치시 참조하도록 values.yaml 수정
kubectl apply -f 5-1.configmap.prometheus-alerts.yaml

# prometheus 설치 ( w/helm )
# - values.yaml 수정사항
#   . prometheus alertrules configMap 참조하도록extraConfigmapMounts 설정 수정
#   . reload 쪽 extraConfigmapMounts 도 수정해서 configMap 수정하면 prometheus 재기동 없이 동적 반영
#  2) alertmanager -> slack 연동 설정
#   . slack 에 "skccinfra" workspace 생성 후 "eks-slack" 채널 생성
#     - webhook app 추가하고 tbiz-atcl 채널에 대한 webhook 생성
#       URL : https://hooks.slack.com/services/XXXXXXXXXXX/YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
#     - 1.values.yaml.prometheus-11.16.9 파일의 alertmanager.yml 내용에 slack 연동 내용 추가
#     - 이쁜 템플릿 사용하는 건 아직 적용 못함 ( alertmanager 에 extra volume 추가하는 내용이 없어서 template 을 뜯어 고칠지 values.yaml 에 template 내용을 넣을지<아주 괴로운 작업이 될듯> 고민중 )
helm install  prometheus prometheus-community/prometheus -f 1.values.yaml.prometheus-11.16.9 -n prometheus

### 참고. eks workshop 가이드 ( 기본 설치)
#helm install prometheus stable/prometheus \
#    --namespace prometheus \
#    --set alertmanager.persistentVolume.storageClass="gp2" --set server.persistentVolume.storageClass="gp2"

# prometheus, alertmanager 접속용 ingress 생성
kubectl apply -f 9-1.ingress.prometheus.yaml
kubectl apply -f 9-2.ingress.alertmanager.yaml

# ingress controller nlb 주소 확인
# - IP 정보 확인하고 local PC의 hosts 파일에 prometheus 정보 추가
nslookup `kubectl -n infra get svc nginx-ingress-external-ingress-nginx-controller -o json | jq -r '.status.loadBalancer.ingress[].hostname'` | grep ^Address | tail -1 | awk '{print $2}'

# prometheus 접속을 위해 PC의 hosts 파일 설정
# - 위 명령에서 확인한 IP 를 가지고 hosts 파일에 아래 정보 입력
#    1.2.3.4 prometheus.ekstest.com
#    1.2.3.4 alertmanager.ekstest.com


################################################
# [ 4. grafana 설치 ]
#   - 작업경로 : 03.MONITORING
#   - 참고 URL : https://www.eksworkshop.com/intermediate/240_monitoring/
################################################
# namespace 생성
kubectl create namespace grafana

# Install grafana ( grafana.yaml 은 위에 설치한 prometheus data를 grafana에서 사용하기 위한 연결 설정 )
helm install grafana grafana/grafana \
    --namespace grafana \
    --set persistence.storageClassName="gp2" \
    --set persistence.enabled=true \
    --set adminPassword='alskfl12~!' \
    --values grafana.yaml

# grafana 접속용 ingress 생성
kubectl apply -f 9-3.ingress.grafana.yaml

# ingress controller nlb 주소 확인 - IP 정보 확인하고 local PC의 hosts 파일에 grafana 정보 추가
nslookup `kubectl -n infra get svc nginx-ingress-external-ingress-nginx-controller -o json | jq -r '.status.loadBalancer.ingress[].hostname'` | grep ^Address | tail -1 | awk '{print $2}'

# grafana 접속을 위해 PC의 hosts 파일 설정
#     1.2.3.4 grafana.ekstest.com

# Grafana 대시보드 생성(샘플)
# 1. Cluster 모니터링
#    - '+' 버튼 누르고 'Import' 메뉴 클릭
#    - Grafana.com Dashboard 칸에 '3119' 입력하고 'Load' 버튼 클릭
#    - data sources 에 'Prometheus' 선택하고 'Import' 버튼 클릭

# 2. Pod 모니터링
#    - '+' 버튼 누르고 'Import' 메뉴 클릭
#    - Grafana.com Dashboard 칸에 '6417' 입력하고 'Load' 버튼 클릭
#    - dashboard 이름을 'Kubernetes Pods Monitoring'으로 수정
#    - data sources 에 'Prometheus' 선택하고 'Import' 버튼 클릭



################################################
# 5. Logging 구성 ( AWS Elasticsearch Service 사용 )
#    - 작업경로 : 04.LOGGING
#    - node ( fluentd ) ==> Elasticsearch service ==> kibana ( 로그 조회 )
################################################

# 1. 환경 변수 설정
export AWS_REGION=ap-southeast-2
export ACCOUNT_ID=`aws sts get-caller-identity | jq -r .Account`
export CLUSTER_NAME=skcc07715
export ES_DOMAIN_NAME="eks-skcc07715-logging"
export ES_VERSION="7.8"
export ES_DOMAIN_USER="admin"
export ES_DOMAIN_PASSWORD="Sktngm12#$"
export FLUENT_BIT_POLICY="skcc07715-fluent-bit-policy"

# 2. IAM 구성 : node에서 ElasticSearch Service 로 접근(로그 전송?)할 권한 부여
#    a. Enabling IAM roles for service accounts on your cluster
eksctl utils associate-iam-oidc-provider \
    --cluster ${CLUSTER_NAME} \
    --approve

#    b. Creating an IAM role and policy for your service account
mkdir ./logging/

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

#### policy-name 이 동일 리전 내에 중복되지 않도록 주의
cp ./logging/fluent-bit-policy.json ~/fluent-bit-policy.json
aws iam create-policy   \
  --policy-name ${FLUENT_BIT_POLICY} \
  --policy-document file://~/fluent-bit-policy.json
rm ~/fluent-bit-policy.json

#    c. Create an IAM role
kubectl create namespace logging

eksctl create iamserviceaccount \
    --name fluent-bit \
    --namespace logging \
    --cluster ${CLUSTER_NAME} \
    --attach-policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/${FLUENT_BIT_POLICY}" \
    --approve \
    --override-existing-serviceaccounts

#    d. EKS 클러스터에 fluent bit 에 대한 ServiceAccount 생성 확인
kubectl -n logging describe sa fluent-bit


# 3. Elasticsearch Service에 신규 Domain 생성
#    a. Create ES Domain
curl -sS https://www.eksworkshop.com/intermediate/230_logging/deploy.files/es_domain.json \
  | envsubst > ./logging/es_domain.json

cp ./logging/es_domain.json ~/es_domain.json
aws es create-elasticsearch-domain \
  --cli-input-json  file://~/es_domain.json
rm ~/es_domain.json

#   b. ES 생성 확인 ( 약 12분 정도 걸림 )
while true
do
  if [ $(aws es describe-elasticsearch-domain --domain-name ${ES_DOMAIN_NAME} --query 'DomainStatus.Processing') == "false" ]
    then
      tput setaf 2; echo "[`date +%H:%M:%S`] The Elasticsearch cluster is ready"   ; tput setaf 9
          break;
    else
      tput setaf 1; echo "[`date +%H:%M:%S`] The Elasticsearch cluster is NOT ready"; tput setaf 9
  fi
  sleep 10
done

#    c. CONFIGURE ELASTICSEARCH ACCESS ( elasticsearch 에 접속할 수 있는 권한 부여 )
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

# 4. Fluent bit 설치
#    a. 설치용 템플릿 파일 생성
curl -Ss https://www.eksworkshop.com/intermediate/230_logging/deploy.files/fluentbit.yaml \
    | envsubst > ./logging/fluentbit.yaml

#    b. 템플릿 파일에서 일부 내용 수정 - label 이 맞지 않아 수정 필요
perl -pi -e "s/k8s-app: fluent-bit/app: fluent-bit/g" ./logging/fluentbit.yaml

#    c. 배포(fluentbit 설치)
kubectl apply -f ./logging/fluentbit.yaml

#    d. 확인 ( daemonset으로 각 노드에 1개씩 잘 뜨는지 확인 )
kubectl -n logging get pod -o wide


# 5. Kibana 에서 Index Pattern 생성 및 사용
#    - KIBANA URL 확인 후 접속(웹브라우저)
KIBANA_URL="https://$ES_ENDPOINT/_plugin/kibana"; echo $KIBANA_URL

#    - kibana 접속 후 아래 순서로 index 등록
#      1. 메인화면에서 "Connect to your Elasticsearch index" 클릭
#      2. Index pattern 에 "*fluent-bit*" 입력 후 "Next step" 클릭
#      3. Time Filter field name 에 "@timestamp" 선택 후 "Create Index Pattern" 클릭


# 9. Logging 구성 삭제
#    a. 환경 변수 설정
export AWS_REGION=ap-southeast-2
export ACCOUNT_ID=`aws sts get-caller-identity | jq -r .Account`
export CLUSTER_NAME=skcc07715
export ES_DOMAIN_NAME="eks-skcc07715-logging"
export ES_VERSION="7.8"
export ES_DOMAIN_USER="admin"
export ES_DOMAIN_PASSWORD="Sktngm12#$"
export FLUENT_BIT_POLICY="skcc07715-fluent-bit-policy"

#    b. fluentbit 삭제
kubectl delete -f ./logging/fluentbit.yaml

#    c. ES 삭제
aws es delete-elasticsearch-domain \
    --domain-name ${ES_DOMAIN_NAME}

#    d. iam service account 삭제
eksctl delete iamserviceaccount \
    --name fluent-bit \
    --namespace logging \
    --cluster ${CLUSTER_NAME} \
    --wait

#    e. iam policy 삭제
aws iam delete-policy   \
  --policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/${FLUENT_BIT_POLICY}"

#    f. logging namespace 삭제
kubectl delete namespace logging



#######################################################################################
# SAMPLE App 배포 테스트
#######################################################################################

################################################
# [ 1. apple / banana ]
#   - 작업경로 : 07.APP_SIMPLE/01.test.apple_banana
################################################

# 배포
./01.test.apple_banana.sh

# 삭제
./02.cleanup.apple_banana.sh

################################################
# [ 2. guestbook ]
#   - 작업경로 : 04.APP_SIMPLE/02.test.guestbook
################################################

# 배포
./01.test.guestbook.sh

# 삭제
./02.cleanup.guestbook.sh



#######################################################################################
# EKS에 GitLab + Jenkins + EFS Provisioner 구성
#######################################################################################

################################################
# [ 1. EFS 볼륨 생성 ]
################################################

1. EKS Cluster 의 VPC 를 사용하도록 생성
        => AZ 3개에 Main CIDR 대역으로 3개의 IP를 사용하게됨
        => EFS의 DNS Name 확인 : fs-39c6f358.efs.ap-southeast-2.amazonaws.com

2. 생성시 - Security Group 변경 ( default로 하면 EFS Provisionner에서 EFS 볼륨 사용못하니, EKS Cluster의 Security Group을 지정해야함. )
        => sg-05abc447a66a03a33 - eks-cluster-sg-skcc05599-647076920

################################################
# [ 2. EFS Provisioner 생성 - helm chart 배포 ]
#   - 작업경로 : 05.CICD/01.efs-provisioner-0.11.1
################################################
# 배포 대상 노드의 role=devops label 추가
kubectl label node XXXX role=devops

# helm chart 검색(search) / 다운로드(fetch)
helm search repo stable/efs-provisioner
helm fetch  stable/efs-provisioner

# helm chart 설정 파일(values.yaml.edit) 수정
# 수정사항 - values.yaml.edit 파일에서 efsFileSystemId 값을 좀 전에 생성한 EKS id 로 수정
tar -xvf efs-provisioner-0.11.1.tgz
diff values.yaml.edit efs-provisioner/values.yaml

9c9
<   deployEnv: prd
---
>   deployEnv: dev
38,40c38,40
<   efsFileSystemId: fs-39c6f358
<   awsRegion: ap-southeast-2
<   path: /efs-pv
---
>   efsFileSystemId: fs-12345678
>   awsRegion: us-east-2
>   path: /example-pv
44c44
<     isDefault: true
---
>     isDefault: false
49c49
<     reclaimPolicy: Retain
---
>     reclaimPolicy: Delete
79,80c79
< nodeSelector:
<   role: devops
---
> nodeSelector: {}

# ( infra namespace가 없을 경우 ) infra namespaces 생성
kubectl create ns infra
# efs-provisioner 설치
helm install efs-provisioner --namespace infra -f values.yaml.edit stable/efs-provisioner --version v0.11.1

....
You can provision an EFS-backed persistent volume with a persistent volume claim like below:
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: my-efs-vol-1
  annotations:
    volume.beta.kubernetes.io/storage-class: aws-efs
spec:
  storageClassName: aws-efs
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Mi


################################################
# [ 3. GITLAB 구성 ] => Helm gitlab/gitlab은 너무 무겁고, Sub-Pack 들이 많이 뜨니, Docker 버전을 Deployment로 띄우자
#   - 작업경로 : 05.CICD/02.gitlab-ce.12.10.11
################################################
kubectl apply -f 1.gitlab-configmap.yaml
kubectl apply -f 2.gitlab-pvc-svc-ingress.yaml
kubectl apply -f 3.deploy.gitlab-ce.yaml


################################################
# [ 4. Jenkins 구성 ] => helm v2.0.1
#   - 작업경로 : 05.CICD/03.jenkins
################################################

# helm chart 검색(search) / 다운로드(fetch)
helm search repo stable/jenkins --version v2.0.1
helm fetch stable/jenkins --version v2.0.1

# helm chart 설정 파일(values.yaml.edit) 수정
tar -xvf jenkins-2.0.1.tgz
diff values.yaml.edit jenkins/values.yaml

104c104
<   adminPassword: "패스워드"
---
>   # adminPassword: <defaults to random>
374c374
<     enabled: true
---
>     enabled: false
394c394
<     hostName: jenkins.ffptest.com
---
>     hostName:
422,425c422,425
<   hostAliases:
<    - ip: 172.20.112.181
<      hostnames:
<        - gitlab.ffptest.com
---
>   hostAliases: []
>   # - ip: 192.168.50.50
>   #   hostnames:
>   #     - something.local
598c598
<   storageClass: aws-efs
---
>   storageClass:

# jenkins 설치
helm install jenkins -n infra -f values.yaml.edit stable/jenkins --version v2.0.1


################################################
# [ 5. EKS에 sa/jenkins 에 cluster-admin 권한 부여 ]
#   - 작업경로 : 05.CICD/04.jenkins.setting
################################################
kubectl apply -f 1.ClusteRoleBinding.yaml

################################################
# [ 6. Jenkins Pipeline 구성 ]
#   - 작업경로 : 05.CICD/04.jenkins.setting , 06.APP_CICD/restapi
#   - 2.pipeline.groovy 참고해서 Jenkins Console에서 구성할 것
################################################
# 1. /etc/hosts 에 Domain 추가 ( local PC, bastion 서버 )
3.34.173.12 gitlab.ffptest.com
3.34.173.12 jenkins.ffptest.com
3.34.173.12 ffptest.com

# 2. (웹사이트) gitlab.ffptest.com 접속해서 신규 계정 생성 및 restapi project 생성

# 3. (bastion) 샘플 app 소스 경로의 파일을 gitlab에 push
cd 06.APP_CICD/restapi

git init
git remote add origin http://gitlab.ffptest.com/kukubabo/restapi.git
git add .
git commit -m "test"
git push -u origin master

# 4. Jenkis pipeline 생성 ( jenkins 계정 : admin / alskfl12~! )
# a) 'new item' 생성
#     - name 입력
#     - pileline 선택
#     - "ok" 버튼 클릭
# b) 가장 아래에 pileline 스크립트 작성
#     - 2.pipeline.groovy 파일 내용에서 주석 제외한 내용 복사해서 붙여넣기
# c) 윗부분에서 "이 빌드는 매ㅐ변수가 있습니다." 체크
#     - "매개변수 추가" 버튼 눌러서 "String Parameter" 4개 추가
#       . GIT_URL          = http://gitlab-ce.infra.svc.cluster.local/[project명]/restapi.git
#       . DOCKER_REGISTRY  = 847322629192.dkr.ecr.ap-southeast-2.amazonaws.com
#       . DOCKER_REPO      = restapi
#       . DOCKER_TAG       = 1.0
#     - "매개변수 추가" 버튼 눌러서 "Credentials Parameter" 1개 추가
#       . Name : 아무거나 입력
#       . Credential Type : Usernae with password 선택
#       . Default Value 옆에 "Add" 버튼 클릭하고 "jenkins" 선택
#       . Username / Password 에 gitlab 계정 정보 입력
#       . Dafault Value 눌러서 방금 입력한 계정 정보 선택
# d) "저장" 버튼 눌러서 pipeline 생성
# e) jenkins 화면에서 방금 생성한 pipeline 선택하고 "Build with Parameters" 선택하고 "빌드하기" 버튼 클릭
# f) 화면 새로고침해보면 왼쪽하던에 Build 번호가 확인되는데 해당 Build 번호 클릭
# g) Build 화면에서 "Console Output" 클릭하면 빌드 진행사항 확인 가능

################################################
# [ 7. Test용 RestAPI 호출 방법 ]
################################################
# 1. hosts 설정이 없을 경우 /etc/hosts 설정에 Doain 추가
3.34.173.12 gitlab.ffptest.com
3.34.173.12 jenkins.ffptest.com
3.34.173.12 ffptest.com

# 2. Rest API 호출
        # while true
        # do
        #    curl http://ffptest.com/api/get/salary/10001 | jq .
        #    sleep 1
        # done[
