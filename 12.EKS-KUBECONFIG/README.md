# EKS 클러스터에 접근 권한 부여(IAM Role)
```
1. EKSMASTER : EKS를 생성한 IAM 사용자
2. EKSADMIN : EKS에 ADMIN 권한으로 접근할 IAM 사용자
3. EKSUSER : EKS에 개발자(특정 namespace 접근) 권한으로 접근할 IAM 사용자
```
EKS를 생성한 계정이 아닌 다른 IAM 계정에서 EKS 클러스터에 접근을 하기 위해 kubeconfig 생성을 할 경우 추가적인 설정을 하지 않은 상태에서는 접근이 되지 않는다.
  
[사용자 : EKSADMIN] kubernetes admin 권한 부여할 IAM 계정에서 접근 테스트
```console
## awscli 명령을 수행하여 kubeconfig 생성
## aws eks --region <REGION_NAME> update-kubeconfig --name <CLUSTER_NAME>
$ aws eks --region ap-northeast-2 update-kubeconfig --name testproject-dev-an2-eks
Updated context arn:aws:eks:ap-northeast-2:123456789012:cluster/testproject-dev-an2-eks in /home/ec2-user/.kube/config

## kubeconfig 생성 후 kubectl 명령 수행해도 접근 권한이 없다는 메시지가 뜨면서 명령이 정상 수행되지 않음
$ kubectl get all --all-namespaces
error: You must be logged in to the server (Unauthorized)
```
  
[사용자 : EKSUSER] kubernetes user 권한 부여할 IAM 계정에서 접근 테스트
```console
## awscli 명령을 수행하여 kubeconfig 생성
## aws eks --region <REGION_NAME> update-kubeconfig --name <CLUSTER_NAME>
$ aws eks --region ap-northeast-2 update-kubeconfig --name testproject-dev-an2-eks
Updated context arn:aws:eks:ap-northeast-2:123456789012:cluster/testproject-dev-an2-eks in /home/ec2-user/.kube/config

## kubeconfig 생성 후 kubectl 명령 수행해도 접근 권한이 없다는 메시지가 뜨면서 명령이 정상 수행되지 않음
$ kubectl get all --all-namespaces
error: You must be logged in to the server (Unauthorized)
```

[사용자 : EKSMASTER] EKSADMIN, EKSUSER 계정 접근을 위한 IAM ROLE을 생성하는 스크립트(create_role.sh)를 작성하여 수행한다.  
(스크립트 예제) create_role.sh
```bash
#!/bin/bash
## 1. arn:aws:iam::마스터ID:root 에 대해 sts:AssumeRole POLICY 포함한 ROLE 생성 (ex. <서비스명>-<구분>-role-eksadmin, <서비스명>-<구분>-role-eksuser)
## 2. 생성한 role을 eks에 연결 ( eksctl create iamidentitymapping 명령 수행하여 EKS 클러스터의 aws-auth ConfigMap에 role - User 연결해서 설정 추가 )
##    -> eksctl 안쓰고 ConfigMap 직접 수정도 가능하다
 
### Set EKS info. #########################
REGION_NAME=ap-northeast-2                  # EKS 클러스터 생성 리전명
CLUSTER_NAME=testproject-dev-an2-eks        # EKS 클러스터 이름
SERVICE_NAME=testproject                    # ServiceName 입력
SERVICE_TYPE=dev                            # prod / dev
###########################################
 
### get account id ########################
ACCOUNT_ID=`aws sts get-caller-identity | jq -r .Account`
###########################################
 
### define policy #########################
POLICY=$(echo -n '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::'; echo -n "$ACCOUNT_ID"; echo -n ':root"},"Action":"sts:AssumeRole","Condition":{}}]}')
###########################################
 
### create role ###########################
aws iam create-role \
  --role-name ${SERVICE_NAME}-${SERVICE_TYPE}-role-eksadmin \
  --description "Kubernetes administrator role (for AWS IAM Authenticator for Kubernetes)." \
  --assume-role-policy-document "$POLICY" \
  --output text \
  --query 'Role.Arn'
 
aws iam create-role \
  --role-name ${SERVICE_NAME}-${SERVICE_TYPE}-role-eksuser \
  --description "Kubernetes developer role (for AWS IAM Authenticator for Kubernetes)." \
  --assume-role-policy-document "$POLICY" \
  --output text \
  --query 'Role.Arn'
###########################################
 
### put role in aws-auth as a master ######
eksctl create iamidentitymapping \
  --cluster ${CLUSTER_NAME} \
  --arn arn:aws:iam::${ACCOUNT_ID}:role/${SERVICE_NAME}-${SERVICE_TYPE}-role-eksadmin \
  --username admin \
  --group system:masters
 
eksctl create iamidentitymapping \
  --cluster ${CLUSTER_NAME} \
  --arn arn:aws:iam::${ACCOUNT_ID}:role/${SERVICE_NAME}-${SERVICE_TYPE}-role-eksuser \
  --username dev-user
###########################################
 
### Print kubeconfig create command #######
echo "### User setting guide (get kubeconfig) ###############"
echo "aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${REGION_NAME} --role-arn arn:aws:iam::${ACCOUNT_ID}:role/${SERVICE_NAME}-${SERVICE_TYPE}-role-eksadmin"
echo "aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${REGION_NAME} --role-arn arn:aws:iam::${ACCOUNT_ID}:role/${SERVICE_NAME}-${SERVICE_TYPE}-role-eksuser"
echo "#######################################################"
```
  
[사용자 : EKSMASTER] 생성한 스크립트에서 "Set EKS info." 를 수정한 뒤 실행한다.
```console
$ sh create_role.sh
arn:aws:iam::123456789012:role/testproject-dev-role-eksadmin
arn:aws:iam::123456789012:role/testproject-dev-role-eksuser
[ℹ] eksctl version 0.38.0
[ℹ] using region ap-northeast-2
[ℹ] adding identity "arn:aws:iam::123456789012:role/testproject-dev-role-eksadmin" to auth ConfigMap
[ℹ] eksctl version 0.38.0
[ℹ] using region ap-northeast-2
[ℹ] adding identity "arn:aws:iam::123456789012:role/testproject-dev-role-eksuser" to auth ConfigMap
### user setting guide (get kubeconfig) ###############
aws eks update-kubeconfig --name testproject-dev-an2-eks --region ap-northeast-2 --role-arn arn:aws:iam::123456789012:role/testproject-dev-role-eksadmin
aws eks update-kubeconfig --name testproject-dev-an2-eks --region ap-northeast-2 --role-arn arn:aws:iam::123456789012:role/testproject-dev-role-eksuser
```

[사용자 : EKSMASTER] 생성된 ROLE은 동일 마스터 계정 내 모든 IAM 계정에서 사용 가능하기 때문에 특정 사용자만 추가하는 작업을 해준다.  
a) IAM 서비스에서 역할(ROLE) 메뉴로 들어가 생성한 ROLE(ex. testproject-d-role-eksadmin)을 선택한다.  
b) "신뢰 관계" 탭에서 신뢰할 수 있는 개체는 마스터계정 정보(계정:123456789012)가 출력되는데 "신뢰 관계 편집" 버튼을 눌러 수정해준다.  
c) Principal 에서 AWS 값에 있는 root 정보를 IAM user 명으로 수정한 뒤 "신뢰 정책 업데이트" 버튼을 눌러 저장한다. ( 여려명을 추가하려면 , 로 구분하여 추가하면 된다. )  
d) 저장 후 신뢰할 수 있는 개체가 특정 IAM 사용자로 변경된 것을 확인할 수 있다.  
예제) Principal 편집 예제  
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:user/iamuser-eksadmin"
      },
      "Action": "sts:AssumeRole",
      "Condition": {}
    }
  ]
}
```
  
[사용자 : EKSMASTER] EKSUSER 계정은 특정 namespace에서만 명령 수행할 수 있도록 kubernetes role, rolebinding을 추가하는 스크립트를 작성하여 생성한다.  
(스크립트 예제) roleNrolebinding.sh
```bash
#!/bin/bash
 
if [ $# -ne 1 ] ; then
    echo "Usage: $0 default"
    exit 1
else
    kubectl get ns $1 >/dev/null 2>&1
    if [ $? -ne 0 ] ; then
        echo "namespapce '$1' is not exist. create namespace"
    else
 
cat << EOF | kubectl apply -f - -n $1
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: dev-role
rules:
  - apiGroups:
      - "*"
    resources:
      - "*"
    verbs:
      - "*"
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: dev-role-binding
subjects:
- kind: User
  name: dev-user
roleRef:
  kind: Role
  name: dev-role
  apiGroup: rbac.authorization.k8s.io
EOF
 
    fi
fi
```
  
[사용자 : EKSMASTER] role을 적용할 namespace를 생성한 뒤 namespace명을 파라미터로 넣어 스크립트를 수행한다.
```console
$ kubectl create namespace testproject-ns

$ sh roleNrolebinding.sh testproject-ns
```
  
작업 완료 후 EKSADMIN, EKSUSER에서 ROLE 기반으로 kubeconfig를 생성하고 kubectl 명령 수행 테스트를 진행한다.
  
[사용자 : EKSADMIN] kubernetes admin 권한 부여할 IAM 계정에서 접근 테스트
```console
## aws eks update-kubeconfig 명령 수행시 --role-arn 옵션을 추가하여 위에서 생성한 eksadmin ROLE의 arn 정보를 입력한다.
$ aws eks --region ap-northeast-2 update-kubeconfig --name testproject-dev-an2-eks --role-arn arn:aws:iam::123456789012:role/testproject-dev-role-eksadmin
Updated context arn:aws:eks:ap-northeast-2:123456789012:cluster/testproject-dev-an2-eks in /home/ec2-user/.kube/config
 
## kubeconfig 생성 후 kubectl 명령이 정상적으로 수행된다.
$ kubectl get ns
NAME              STATUS   AGE
default           Active   2d12h
kube-node-lease   Active   2d12h
kube-public       Active   2d12h
kube-system       Active   2d12h
```
  
[사용자 : EKSUSER] kubernetes user 권한 부여할 IAM 계정에서 접근 테스트
```console
## aws eks update-kubeconfig 명령 수행시 --role-arn 옵션을 추가하여 위에서 생성한 eksuser ROLE의 arn 정보를 입력한다.
$ aws eks --region ap-northeast-2 update-kubeconfig --name testproject-dev-an2-eks --role-arn arn:aws:iam::123456789012:role/testproject-dev-role-eksauser
Updated context arn:aws:eks:ap-northeast-2:123456789012:cluster/testproject-dev-an2-eks in /home/ec2-user/.kube/config
 
 
## kubeconfig 생성 후 testproject-ns namespace에서 kubectl 명령이 정상적으로 수행된다.
$ kubectl -n testproject-ns get pod
No resources found in testnamespace namespace.
 
 
## 다른 namespace나 --all-namespaces 로 명령 수행시 권한 오류가 발생한다.
$ kubectl get all --all-namespaces
Error from server (Forbidden): pods is forbidden: User "dev-user" cannot list resource "pods" in API group "" at the cluster scope
Error from server (Forbidden): replicationcontrollers is forbidden: User "dev-user" cannot list resource "replicationcontrollers" in API group "" at the cluster scope
Error from server (Forbidden): services is forbidden: User "dev-user" cannot list resource "services" in API group "" at the cluster scope
Error from server (Forbidden): daemonsets.apps is forbidden: User "dev-user" cannot list resource "daemonsets" in API group "apps" at the cluster scope
Error from server (Forbidden): deployments.apps is forbidden: User "dev-user" cannot list resource "deployments" in API group "apps" at the cluster scope
Error from server (Forbidden): replicasets.apps is forbidden: User "dev-user" cannot list resource "replicasets" in API group "apps" at the cluster scope
Error from server (Forbidden): statefulsets.apps is forbidden: User "dev-user" cannot list resource "statefulsets" in API group "apps" at the cluster scope
Error from server (Forbidden): horizontalpodautoscalers.autoscaling is forbidden: User "dev-user" cannot list resource "horizontalpodautoscalers" in API group "autoscaling" at the cluster scope
Error from server (Forbidden): jobs.batch is forbidden: User "dev-user" cannot list resource "jobs" in API group "batch" at the cluster scope
Error from server (Forbidden): cronjobs.batch is forbidden: User "dev-user" cannot list resource "cronjobs" in API group "batch" at the cluster scope
```

[사용자 : EKSUSER] kubernetes admin ROLE을 사용하여 kubeconfig를 생성할 경우 명령 수행이 되는지 테스트
```console
## aws eks update-kubeconfig 명령 수행시 --role-arn 옵션을 추가하여 위에서 생성한 eksadmin ROLE의 arn 정보를 입력한다.
## kubeconfig 는 정상적으로 생성된다.
$ aws eks --region ap-northeast-2 update-kubeconfig --name testproject-dev-an2-eks --role-arn arn:aws:iam::123456789012:role/testproject-dev-role-eksadmin
Updated context arn:aws:eks:ap-northeast-2:123456789012:cluster/testproject-dev-an2-eks in /home/ec2-user/.kube/config
 
 
## kubectl 명령 수행시 ROLE에 대한 권한이 없다는 메시지가 뜨면서 정상 수행되지 않는다.
$ kubectl get ns
An error occurred (AccessDenied) when calling the AssumeRole operation: User: arn:aws:iam::123456789012:user/iamuser-eksusr is not authorized to perform: sts:AssumeRole on resource: arn:aws:iam::123456789012:role/testproject-dev-role-eksadmin
Unable to connect to the server: getting credentials: exec: exit status 254
```
