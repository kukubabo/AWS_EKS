
ingress 구성을 위한 aws-loadbalancer-controller 를 설치한다.
   
```bash
## a) Add helm repository  
$ helm repo add eks https://aws.github.io/eks-charts  
    
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
