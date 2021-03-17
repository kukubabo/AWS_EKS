# Calico CNI 적용
> 생성하는 POD 수가 많아서 할당받은 노드그룹 Subnet IP대역보다 더 많은 IP가 필요할 경우 calico CNI를 적용하면 POD 네트워크는 사설망 대역으로 사용할 수 있다.  
> 생성 순서는 "EKS 클러스터 생성" - "aws-node Daemonset 삭제 & calico CNI 설치" - "노드 그룹 생성" - "calico 관련 설정" 순으로 진행한다.  
> 이미 노드그룹을 생성한 상태에서 구성할 경우 calico 설치 작업 후 기존 노드를 재시작(혹은 노드 그룹 재생성)한 뒤 calico 설정 작업을 진행한다.  

## 1. EKS 클러스터를 생성하면 기본으로 구성되는 Amazon VPC CNI(aws-node)를 삭제한다.
```console
$ kubectl delete daemonset -n kube-system aws-node
```

## 2. calico CNI를 설치한다.
> 참고 URL : https://docs.projectcalico.org/getting-started/kubernetes/managed-public-cloud/eks
```console
$ kubectl apply -f https://docs.projectcalico.org/manifests/calico-vxlan.yaml
configmap/calico-config created
customresourcedefinition.apiextensions.k8s.io/bgpconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/bgppeers.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/blockaffinities.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/clusterinformations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/felixconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworksets.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/hostendpoints.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamblocks.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamconfigs.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamhandles.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ippools.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/kubecontrollersconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networksets.crd.projectcalico.org created
clusterrole.rbac.authorization.k8s.io/calico-kube-controllers created
clusterrolebinding.rbac.authorization.k8s.io/calico-kube-controllers created
clusterrole.rbac.authorization.k8s.io/calico-node created
clusterrolebinding.rbac.authorization.k8s.io/calico-node created
daemonset.apps/calico-node created
serviceaccount/calico-node created
deployment.apps/calico-kube-controllers created
serviceaccount/calico-kube-controllers created
poddisruptionbudget.policy/calico-kube-controllers created
```

## 3. 노드 그룹 생성 ( 기 생성되어 있을 경우 재시작 or 재생성 )

## 4. 노드 생성(재시작) 후 POD 정보 확인
> daemonset 으로 배포된 POD를 제외한 POD의 IP 정보를 보면 calico 기본 CIDR (192.168.0.0/16) 대역으로 할당되어 있다.
```console
$ kubectl get pod -o wide -A
NAMESPACE   NAME                                     READY STATUS  RESTARTS AGE IP            NODE                                             NOMINATED NODE READINESS GATES
kube-system calico-kube-controllers-8586758878-45zvx 1/1   Running 0        21h 192.168.209.3 ip-100-64-55-84.ap-northeast-2.compute.internal  <none>         <none>
kube-system calico-node-7p4gs                        1/1   Running 0        29m 100.64.55.84  ip-100-64-55-84.ap-northeast-2.compute.internal  <none>         <none>
kube-system calico-node-rrrx4                        1/1   Running 0        28m 100.64.55.126 ip-100-64-55-126.ap-northeast-2.compute.internal <none>         <none>
kube-system coredns-6fb4cf484b-5s2s7                 1/1   Running 0        23h 192.168.209.1 ip-100-64-55-84.ap-northeast-2.compute.internal  <none>         <none>
kube-system coredns-6fb4cf484b-nllzp                 1/1   Running 0        23h 192.168.209.2 ip-100-64-55-84.ap-northeast-2.compute.internal  <none>         <none>
kube-system kube-proxy-b8584                         1/1   Running 0        28m 100.64.55.126 ip-100-64-55-126.ap-northeast-2.compute.internal <none>         <none>
kube-system kube-proxy-jggjb                         1/1   Running 0        29m 100.64.55.84  ip-100-64-55-84.ap-northeast-2.compute.internal  <none>         <none>
```

## 5. POD CIDR를 설정하기 위해 ippool 을 편집모드로 연다.
```console
$ kubectl edit ippool default-ipv4-ippool
```

## 6. sepc.cidr 값에 변경할 POD CIDR 대역 정보로 수정하고 저장한다.
```yaml
apiVersion: crd.projectcalico.org/v1
kind: IPPool
metadata:
  annotations:
  projectcalico.org/metadata: '{"uid":"ceff6c11-1933-4511-9fc1-f7e9bcbba255","creationTimestamp":"2020-12-03T01:11:30Z"}'
  name: default-ipv4-ippool
spec:
  blockSize: 26
  cidr: 10.244.128.0/17
  ipipMode: Never
  natOutgoing: true
  nodeSelector: all()
```

## 7. calico 기본 POD CIDR(192.168.0.0/16)대역의 IP를 사용중인 POD들을 재시작하여 IP를 새로 발급 받도록 한다.
```console
$ kubectl delete pod -n kube-system calico-kube-controllers-8586758878-45zvx coredns-6fb4cf484b-5s2s7 coredns-6fb4cf484b-nllzp
pod "calico-kube-controllers-8586758878-45zvx" deleted
pod "coredns-6fb4cf484b-5s2s7" deleted
pod "coredns-6fb4cf484b-nllzp" deleted

$ kubectl get pod -o wide -A
NAMESPACE   NAME                                     READY STATUS  RESTARTS AGE IP            NODE                                             NOMINATED NODE READINESS GATES
kube-system calico-kube-controllers-8586758878-439gs 1/1   Running 0         1m 100.244.237.4   ip-100-64-55-84.ap-northeast-2.compute.internal  <none>         <none>
kube-system calico-node-7p4gs                        1/1   Running 0        29m 100.64.55.84    ip-100-64-55-84.ap-northeast-2.compute.internal  <none>         <none>
kube-system calico-node-rrrx4                        1/1   Running 0        28m 100.64.55.126   ip-100-64-55-126.ap-northeast-2.compute.internal <none>         <none>
kube-system coredns-6fb4cf484b-sd54f                 1/1   Running 0         1m 100.244.157.135 ip-100-64-55-84.ap-northeast-2.compute.internal  <none>         <none>
kube-system coredns-6fb4cf484b-df523                 1/1   Running 0         1m 100.244.157.136 ip-100-64-55-84.ap-northeast-2.compute.internal  <none>         <none>
kube-system kube-proxy-b8584                         1/1   Running 0        28m 100.64.55.126   ip-100-64-55-126.ap-northeast-2.compute.internal <none>         <none>
kube-system kube-proxy-jggjb                         1/1   Running 0        29m 100.64.55.84    ip-100-64-55-84.ap-northeast-2.compute.internal  <none>         <none>
```

## 8. ipamblock 에서 기존 IP Block(192-168-x-x-26)을 확인하고 삭제한다.
```console
$ kubectl get ipamblocks
NAME              AGE
10-244-157-128-26 11m
10-244-237-0-26   11m
192-168-209-0-26  32m
192-168-59-64-26  31m

$ kubectl delete ipamblocks 192-168-209-0-26 192-168-59-64-26
ipamblock.crd.projectcalico.org "192-168-209-0-26" deleted
ipamblock.crd.projectcalico.org "192-168-59-64-26" deleted

$ kubectl get ipamblocks
NAME              AGE
10-244-157-128-26 11m
10-244-237-0-26   11m
```
