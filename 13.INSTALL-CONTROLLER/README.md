# AWS-LOADBALANCER-CONTROLLER 설치
ingress 구성을 위한 aws-loadbalancer-controller 를 설치한다.  
   
```console
## a) Add helm repository  
$ helm repo add eks https://aws.github.io/eks-charts  
"eks" has been added to your repositories
$ helm repo list
NAME            URL
eks             https://aws.github.io/eks-charts
   
## b) Install TargetGroupBinding CRD  
$ kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"  
   
## c) Install helm chart ( CLUSTER_NAME : 생성한 EKS 클러스터 이름 )  
## $ helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \  
##  -n kube-system \  
##  --set clusterName=<CLUSTER_NAME> \  
##  --set hostNetwork=true # https://github.com/kubernetes-sigs/aws-load-balancer-controller/issues/1591  
$ helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \  
  -n kube-system \  
  --set clusterName=testproject-dev-an2-eks \  
  --set hostNetwork=true # https://github.com/kubernetes-sigs/aws-load-balancer-controller/issues/1591  
  
## d) ingress 생성시 class 명을 alb 로 지정하면 alb loadbalancer 가 자동생성되면서 target 그룹으로 EKS 노드포트가 설정(b에서 설치한 TargetGroupBinding CRD 덕분)된다.  
## ingress 생성시 상세 옵션은 aws(https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.1/guide/ingress/annotations/) 를 참고하면 된다.  
```
      
샘플 ingress 코드)  
```yaml:ingress.yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: alb-ingress-example
  namespace: testproject-ns
  annotations:
    kubernetes.io/ingress.class: alb
  labels:
    app: alb-ingress-example
spec:
  rules:
  - host: alb-ingress.example.com
    http:
      paths:
        - path: /*
          backend:
            serviceName: test-app
            servicePort: 80

```


# Nginx Ingress Controller 설치
kubernetes 일반적으로 많이 쓰는 nginx ingress controller 를 설치한다.  
```
AWS-LOADBALANCER-CONTROLLER 대신 nginx ingress controller 를 선택하는 이유  
. ALB 기능이 훌륭(great)하지만 nginx ingress controller 가 사용하는 NLB가 더 적합한 사례가 있기 때문  
. nginx ingress controller 는 모든 요청을 받아 namespace, app별 분기하는 중앙 집중식 라우팅 방식으로 관리할 수 있기 때문  
  (AWS-LOADBALANCER-CONTROLLER 는 ingress 생성시 전용 alb가 생성되는 개별관리 방식)  
```
```
NLB가 ALB 보다 좋은 점  
. Static IP/elastic IP addresses 사용이 가능  
. scaling 을 통한 확장성이 용이  
. Available Zone 제어(?) 가능  
. Source IP 주소 보존(preservation) 가능? ( ALB에선 안되는지 확인 필요 )  
. Long-lived TCP 연결 가능  
. 대역폭 사용량 감소 : ALB, CLB 에 비해 약 25% 사용량 감소  
. SSL termination : SSL termination will need to happen at the backend, since SSL termination on NLB for Kubernetes is not yet available.  
```

```console
## a) Add helm repository
$ helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
"ingress-nginx" has been added to your repositories
$ helm repo update

$ helm repo list
NAME            URL
ingress-nginx   https://kubernetes.github.io/ingress-nginx

## b-1) install ingress-nginx ( 외부 서비스용 )
helm install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace kube-system \
	--set controller.hostNetwork=true \
	--set controller.containerPort.http=80 \
	--set controller.containerPort.https=443 \
	--set controller.kind=DaemonSet \
	--set controller.hostPort.enabled=true \
	--set controller.hostPort.ports.http=80 \
	--set controller.hostPort.ports.https=443 \
	--set controller.electionID="ingress-controller-leader-external" \
	--set controller.ingressClass="nginx" \
	--set controller.podLabels.app="ingress-nginx-external" \
	--set controller.admissionWebhooks.port=8443 \
	--set controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type=nlb \
	--set defaultBackend.enabled=true

## b-2) install ingress-nginx ( 내부 서비스용 )
helm install ingress-nginx-internal ingress-nginx/ingress-nginx \
    --namespace kube-system \
	--set controller.hostNetwork=true \
	--set controller.containerPort.http=10080 \
	--set controller.containerPort.https=10443 \
	--set controller.kind=DaemonSet \
	--set controller.hostPort.enabled=true \
	--set controller.hostPort.ports.http=10080 \
	--set controller.hostPort.ports.https=10443 \
	--set controller.electionID="ingress-controller-leader-internal" \
	--set controller.ingressClass="nginx-internal" \
	--set controller.podLabels.app="ingress-nginx-internal" \
	--set controller.admissionWebhooks.port=18443 \
	--set controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type=nlb \
	--set controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-internal=true \
	--set defaultBackend.enabled=true

## b-3) external 서비스용 ( 고정 E-IP NLB 사용, Daemonset )   ==== annoation 안 먹어서 추가 테스트 필요
helm install ingress-nginx-eip ingress-nginx/ingress-nginx \
    --namespace kube-system \
	--set controller.hostNetwork=true \
	--set controller.containerPort.http=20080 \
	--set controller.containerPort.https=20443 \
	--set controller.kind=DaemonSet \
	--set controller.hostPort.enabled=true \
	--set controller.hostPort.ports.http=20080 \
	--set controller.hostPort.ports.https=20443 \
	--set controller.electionID="ingress-controller-leader-eip" \
	--set controller.ingressClass="nginx-eip" \
	--set controller.podLabels.app="ingress-nginx-eip" \
	--set controller.admissionWebhooks.port=28443 \
	--set controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type=nlb \
	--set controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-eip-allocations="eipalloc-07ef75724516085ca,eipalloc-0181202a7c68c88d7" \
	--set defaultBackend.enabled=true
```

