# Metrics-server 설치
간단하게 노드의 자원 사용량 확인(kubectl top node)하거나 POD AutoScaling 기능을 사용하기 위해 metrics-server를 설치한다.  

## 1. 설치 파일 다운로드  
> 공식 github에서 설치 파일(components.yaml)을 다운로드 받는다.  
> [helm repo](https://github.com/helm/charts/tree/master/stable/metrics-server)도 있긴 하지만 2020/11/03 부로 업데이트가 되지 않는 것으로 공지되어 있어 yaml 파일로 설치한다.
```console
$ wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

## 2. components.yaml파일의 container 설정에 'hostNetwork: true' 추가  
> calico 등 overlay 네트워크 구성시 POD IP를 node IP로 설정해야 정상 작동하기 때문에 기본 설정으로 추가해준다.
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
$ kubectl apply -f components.yaml
```

참고)  
https://docs.aws.amazon.com/eks/latest/userguide/metrics-server.html  
https://github.com/kubernetes-sigs/metrics-server

# Prometheus 설치 ( with alertrules )

## 1. Helm Repo 추가
```console
$ helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```

## 2. prometheus alertrule 생성
> alertrule이 정의된 configMap을 미리 생성해두고 helm chart 설치시 참조할 수 있도록 values.yaml 수정
```console
$ kubectl apply -f configmap.prometheus-alerts.yaml
```

## 3. 설치
```console
$ helm install prometheus prometheus-community/prometheus -f values.yaml.prometheus-13.6.0 -n prometheus
```

참고)  
https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/prometheus.html  
https://www.eksworkshop.com/intermediate/240_monitoring/

# Grafana 설치

## 1. Helm Repo 추가
```console
$ helm repo add grafana https://grafana.github.io/helm-charts
```

## 2. grafana.yaml 파일 생성
> grafana datasource에 prometheus 연결하기 위한 설정 파일(grafana.yaml)을 작성한다.
```console
$ cat << EoF > grafana.yaml
datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: http://prometheus-server.prometheus.svc.cluster.local
      access: proxy
      isDefault: true
EoF
```

## 3. 설치
```console
$ helm install grafana grafana/grafana \
    --namespace grafana \
    --set persistence.storageClassName="gp2" \
    --set persistence.enabled=true \
    --set adminPassword='alskfl12~!' \
    --values grafana.yaml
```

참고)  
https://www.eksworkshop.com/intermediate/240_monitoring/  
