## database migration:
`brew install golang-migrate`
`migrate create -ext sql -dir db/migration -seq init_schema` to generate empty up&down file
(-seq: generate sequential version number for migration file)
then start postgres container & createdb
`migrate -path db/migration -database "postgresql://root:root@localhost:5432/kai_bank" -verbose up`
(-verbose: print verbose(冗长的) logging)

## generate CRUD code
`brew install sqlc`
`sqlc init` to generate sqlc.yaml then config yaml file
`sqlc generate`
( 
  models.go : all struct;
  db.go: defined DBTX interface that sql.DB & sql.Tx both implemented (so can freely use db/transaction to exec a query) 
  structName.sql.go: crud code for a struct
)

## transfer transaction
ACID: Atomicity, consistency, Isolation, Durability
SQL transaction: BEGIN; dothings; COMMIT;(or ROLLBACK)
`SELECT * FROM accounts WHERE id = $1 LIMIT 1 FOR NO KEY UPDATE;`
(select for update: query with lock, block other transaction)
(no key: tell primary key will not be touched, need no lock to foreign key constraints)

## Continuous Intergration
githubActions: trigger(on: push/pull request/schedule...) -> workflow(run ci.yaml)
    jobs: run parallelly(except need)
      steps: run sequentially

### SSL & TSL
网络接口层(物理/数据链路层 ethernet)->网络层(IP)-传输层(tcp/udp)->应用层(http/ftp/smpt/dns)
SSL: Secure Socket Layer(the prodecessor of TSL)
TSL: Transport Layer Security(cryptographic protocol over computer network)
`http+tsl=https; smpt+tsl=smtps; ftp+tsl=ftps`

### Build image with docker
dockerfile:
`docker build -t kaibank:latest .` (current dir: Dockerfile)
`docker run --name kaibank --network="host" -p 8080:8080 kaibank:latest`
(--network="host": because db instance in host machine)
or `docker network create kaiBankNet` then `docker run --network=kaiBankNet` on both postgre & kaibank
(& `docker network connect kaiBankNet postgres/kaibank...`  `docker inspect kaiBankNet` to check) 
or `docker run --name kaibank -p 8080:8080 -e DB_SOURCE=postgresql://root:root@realpath:5432/kai_bank?sslmode=disable kaibank:latest`

docker compose: run multiple services at one time
`build: context & dockerfile`: means build with dockerfile in which dir
`enviroment: @postgres`: means the above serviceName
`docker compose up`
`docker compose down` to remove all containers & images composed

about run service in order: 
https://docs.docker.com/compose/startup-order/
https://github.com/Eficode/wait-for
in docker-compose, we add entrypoint, so cmd in docker file will be overwrite.

### push images to AWS ECR
Elastic Container Register: create repository -> kaibank -> create a user with ECRfullAccess Policy(get access keyID & key) -> github project>settings>secret(actions)>create new repository secret to store keyID&key -> 
(How to login AWS ECR: https://github.com/marketplace/actions/amazon-ecr-login-action-for-github-actions)

`docker build -t imageName:tagName .` (-t: tag can set multiple tags)
`docker tag kaibank:latest 402167448073.dkr.ecr.us-east-2.amazonaws.com/kaibank:latest` 
(kaibank:latest标记为(remote repository's) kaibank/kaibank:latest)
`docker push 402167448073.dkr.ecr.us-east-2.amazonaws.com/kaibank:latest` 
`docker push -a` (--all-tags: push all tagged images)

## AWS RDS
Relational database service: create bd -> postgres(master username:root, password:auto-gen)
`migrate -path db/migration -database "postgresql://root:jzX0nA9T9EFw3JE3Hsm6@kai-bank.cfxrsrtn3mc0.us-east-2.rds.amazonaws.com:5432/kai_bank" -verbose up`

### use AWS Secrets Manager to store env
store a new password ->  store env variable & db(dburl/dbdrive/serveraddress/tokenkey/tokenduration)
`openssl rand -hex | head -c 32` :generate random

### use AWS-CLI
`which aws`
`aws configure` to configure user keyID/key (stored in ~/.aws/credentials  ~/.aws/config)
`aws secretsmanager get-secret-value --secret-id kai_bank` to get secrets(add SecretManagerPolicy before this command)
`aws secretsmanager get-secret-value --secret-id kai_bank --query SecretString --output text`
(--query SecretString: only need secrets(no other data like version) --output; specify format)
(still need work to format secret into format as "db_url=root@local...")
`brew install jq` 
`aws secretsmanager get-secret-value --secret-id kai_bank --query SecretString --output text | jq -r 'to_entries|map("\(.key)=\(.value)")|.[]' > app.env `

`docker pull uriOfECR` --- no auth error
`aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 402167448073.dkr.ecr.us-east-2.amazonaws.com` -- to login aws for local docker

### EKS
EKS vs Kubernetes: eks easy to use(only need to add work nodes to eks cluster, then connect to the cluster with kubectl... then run)
config cluster -> creat iam role for eks -> 
add node group -> create iam role for work nodes(EKS_CNI(have IP config permission) + EKSWorkerNode policy(allow connect to eks cluster)) -> config num of nodes needed (open detailed: auto scaling group to see )
`brew install kubectl` `kubectl version --client` 
`kubectl cluster-info` to check connected kube-cluster: error if no cluster
`aws eks update-kubeconfig --name kai-bank --region us-east-2` config aws eks to local kube
(make sure aws config user have eks permission) -> (Added new context arn:aws:eks:us-east-2:402167448073:cluster/kai-bank to /Users/xiongkai/.kube/config)
`kubectl config use-context arn:aws:eks:us-east-2:402167448073:cluster/kai-bank`

`kubectl get pods` -> (error: You must be logged in to the server (Unauthorized)) -->
(because user we used in aws-cli be different from who created eks) --> 2  ways:
1-can use root user `vim ~/.aws/credentials` to add root access key 
2-extend eks access to github-ci user  "https://aws.amazon.com/cn/premiumsupport/knowledge-center/amazon-eks-cluster-access/"
`export AWS_PROFILE=github` choose which ~/.aws/credentials `aws sts get-caller-identity` to check
add `eks/aws-auth.yaml`  `export AWS_PROFILE=default | kubectl apply -f eks/aws-auth.yaml` apply it
`kubectl config current-context`

deploy app in kube: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
`eks/deployment.yaml` `kubectl apply -f eks/deployment.yaml`

Non-terminated Pods: 4: kube system self occupy 4 pods.

deploy app to kube pods does not allow us to the api  directly, we have to deploy Sevice.
https://kubernetes.io/docs/concepts/services-networking/service/
`kubectl apply -f eks/service.yaml` and visit external IP 
`nslookup ipAddr` 查询DNS的记录，查看域名解析是否正常，在网络故障的时候用来诊断网络问
service type: 
`ClusterIP`: allow internal visit only; 
`LoadBalancer`: to have external IP to provide outside visit; 

the external IP is long and not static ---> buy domain name

`ingress.yaml` :use Ingress to route traffics to different services

### another useful kube tool: 
`brew install k9s`  `k9s` to enter
:service
:deployment -> api -> logs
