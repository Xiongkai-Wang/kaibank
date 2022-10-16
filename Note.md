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
