DB_URL=postgresql://root:root@localhost:5432/kai_bank?sslmode=disable

postgres:
	docker run --name postgres -p 5432:5432 -e POSTGRES_USER=root -e POSTGRES_PASSWORD=root -d postgres:12-alpine

createdb:
	docker exec -it postgres createdb --username=root --owner=root kai_bank

dropdb:
	docker exec -it postgres dropdb kai_bank

migrateup:
	migrate -path db/migration -database "$(DB_URL)" -verbose up

migratedown:
	migrate -path db/migration -database "$(DB_URL)" -verbose down

migrateup1:
	migrate -path db/migration -database "$(DB_URL)" -verbose up 1

sqlc:
	sqlc generate

est:
	go test -v -cover ./...

.PHONY: postgres createdb dropdb migrateup migratedown sqlc