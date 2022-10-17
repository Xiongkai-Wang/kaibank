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