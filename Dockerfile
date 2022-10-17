# Build stage
FROM golang:1.19-alpine3.16 AS builder 
WORKDIR /app
COPY . .
RUN go build -o main main.go
# FROM: imageVersion
# WORKDIR : working dir inside image
# COPY: data from currentPath(in host) to imagePath

# Run stage
FROM alpine:3.16
WORKDIR /app
COPY --from=builder /app/main .
COPY app.env .
COPY db/migration ./db/migration
# multiple stage: copy --from=builder: copy compiled binary file only
# donot have to inherite all files from last stage(build), only copy the target you want 

EXPOSE 8080
CMD [ "/app/main" ]
# RUN, ENTRYPOINT和CMD都是在docker image里执行一条命, 但有一些微妙的区别
# besides, CMD和ENTRYPOINT组合起来使用, 完成更加丰富的功能
# RUN命令执行命令并创建新的镜像层，通常用于安装软件包/or 构建多层image时build前面的层
# CMD命令设置容器启动后默认执行的命令及其参数，但CMD设置的命令能够被docker run命令后面的命令行参数替换
#   如 docker run -it [image] /bin/bash，CMD 会被忽略掉，/bin/bash 将被执行
# ENTRYPOINT配置容器启动时的执行命令（不会被忽略，一定会被执行，即使运行 docker run时指定了其他命令）
#   如 ENTRYPOINT ["/bin/echo", "Hello"] ，当容器通过 docker run -it [image] 启动时，输出为 Hello
#   而如果通过 docker run -it [image] CloudMan 启动，则输出为 Hello CloudMan
#   当file中有ENTRYPOINT ["/bin/echo", "Hello"] 和 CMD ["world"]是， 
#     docker run -it [image] 启动时，输出为 Hello World
#     通过 docker run -it [image] CloudMan 启动, 输出为Hello CloudMan
