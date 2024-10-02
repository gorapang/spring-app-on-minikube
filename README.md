# Minikube를 이용한 Spring App 배포

Ubuntu 22.04 LTS

Docker version 27.3.1, build ce12230


---

## 🎁 준비: Minikube 시작하기

- **minikube 시작**
    - `minikube`란? 학습 및 테스트용 싱글 노드 클러스터

```bash
minikube delete
minikube start
minikube status
```

- **dashboard 활용을 위한 설정**

```bash
minikube addons list

minikube addons enable dashboard  
minikube dashboard

minikube addons enable metrics-server #리소스 모니터링 활성화

#사용량 확인
kubectl top pods
```

---

## 🐳 1. Spring App 도커 이미지 생성

![](https://velog.velcdn.com/images/wnwjdqkr/post/3a99b5fc-0b28-42bf-a70c-d5a2248423ef/image.png)


- **`Dockerfile` 생성**

```bash
FROM openjdk:17-slim AS base

WORKDIR /app
COPY SpringApp-0.0.1-SNAPSHOT.jar app.jar

ENTRYPOINT ["java", "-jar", "app.jar"]
```

- **도커 이미지 빌드**

```bash
docker build -t my-spring-app .
docker images
```

- **도커 로그인**

```bash
docker login -u youremail@gmail.com
```

- **도커 이미지 푸시**
    - `jeongju` 부분에 dockerhub username을 넣으면 된다.

```bash
docker tag my-spring-app jeognju/my-spring-app
docker push jeognju/my-spring-app
```

---

## 🚀 2. 배포 및 서비스 생성

- **spring app 배포 생성**

```bash
kubectl create deployment springapp --image=jeongju/my-spring-app --replicas=3
```

- **spring app 서비스 생성**

```bash
kubectl expose deployment springapp --type=LoadBalancer --port=8999
```

- **상태 확인**

```bash
kubectl get pods
kubectl get services
```

```bash
username@servername:~/minikube_test$ kubectl get pods
NAME                        READY   STATUS    RESTARTS   AGE
springapp-7f848dbf8-9ml7x   1/1     Running   0          17m
springapp-7f848dbf8-mfvvx   1/1     Running   0          21m
springapp-7f848dbf8-wzw8j   1/1     Running   0          21m
```

```bash
username@servername:~/minikube_test$ kubectl get services
[1]+  Killed                  minikube tunnel
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP          24m
springapp    NodePort    10.110.10.248   <none>        8999:31108/TCP   100s
```


Dashboard에서도 확인 가능하다.
![](https://velog.velcdn.com/images/wnwjdqkr/post/bcc4543c-3d20-4aa8-943a-ae6667d7a56d/image.png)



- **터널 설정**

```bash
minikube tunnel
minikube ip
```

- **포트포워딩**
    
    SpringApp의 <EXTERNAL_IP>:<포트번호>를 vscode 포트 포워딩에 추가한다.
    

![](https://velog.velcdn.com/images/wnwjdqkr/post/57421132-6eac-427c-85ab-ef5030fac8b1/image.png)


- **통신 확인**

```bash
curl http://10.105.13.229:8999/test
```


![](https://velog.velcdn.com/images/wnwjdqkr/post/5760bfc6-4d08-401e-b8cf-35eba83cc7c6/image.png)

정상적으로 응답이 오는 것을 확인하였다.

---

## 🔧 트러블슈팅

### 1. `tunnel` 실행되지 않는 문제

- `SVC_TUNNEL_START` 에러: 에러 메시지에서 제공해주는 PID를 죽이면 해결

![](https://velog.velcdn.com/images/wnwjdqkr/post/c752b8c5-82a3-4312-8686-1c061d90462e/image.png)


- 에러 메시지에 PID가 제공되지 않는 경우

![](https://velog.velcdn.com/images/wnwjdqkr/post/3e4ea5f0-8321-49e4-b80b-4591322f9e25/image.png)



```bash
username@servername:~/minikube_test$ ps aux | grep minikube
username   55629  0.0  0.9 1749428 75620 pts/1   Tl   10:17   0:00 minikube tunnel
```

```bash
sudo kill -9 55629
```

### 2. SpringApp에 EXTERNAL_IP가 할당되지 않는 문제

- 기존 `NodePort` 로 생성
    - **`NodePort`** 서비스는 외부 IP를 할당하지 않으며, 노드의 IP와 포트를 통해 접근할 수 있다
    - `External IP`가 할당되는 것은 **`LoadBalancer`** 타입의 서비스에서만 가능함
        - 단, Minikube는 로컬 환경에서 실행되기 때문에 `LoadBalancer` 타입의 서비스를 사용할 때도 외부 클라우드처럼 동작하지 않는다. 그래서 `minikube tunnel` 명령어를 통해 외부 IP를 할당하는 과정이 필요한 것이다.

```bash
kubectl expose deployment springapp --type=NodePort --port=8999
```

- 해결: `LoadBalancer` 타입으로 서비스 노출하기

```bash
kubectl delete service springapp #서비스 삭제
kubectl expose deployment springapp --type=LoadBalancer --port=8999
```


---
