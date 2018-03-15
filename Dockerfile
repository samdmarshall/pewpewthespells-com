FROM nimlang/nim:0.18.0-alpine
RUN apk update
RUN apk add openssl
COPY . /src
WORKDIR /src
RUN nimble build -y

FROM library/node:8
COPY . /src
WORKDIR /src
RUN yarn install
RUN yarn exec danger ci
