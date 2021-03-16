# Metrics-server 설치
간단하게 노드의 자원 사용량 확인(kubectl top node)하거나 POD AutoScaling 기능을 사용하기 위해 metrics-server를 설치한다.  

## 1. 설치 파일 다운로드
```console
$ wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

## 2. components.yaml파일의 container 설정에 'hostNetwork: true' 추가  
> calico 등 layout 네트워크 구성시 POD IP를 node IP로 설정해야 정상 작동하기 때문에 기본 설정으로 추가해준다.
```console
## 추가
$ sed -i '170 a \      hostNetwork: true' components.yaml

## 확인
$ sed -n 168,175p components.yaml
      volumes:
      - emptyDir: {}
        name: tmp-dir
      hostNetwork: true
---
apiVersion: apiregistration.k8s.io/v1
kind: APIService
metadata:
```

## 3. 설치
```console
kubectl apply -f components.yaml
```

참고)  
https://docs.aws.amazon.com/eks/latest/userguide/metrics-server.html  
https://github.com/kubernetes-sigs/metrics-server
