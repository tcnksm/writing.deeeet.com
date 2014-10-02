---
layout: post
title: '認証付きのDocker Private registryを立てる'
date: 2014-10-02 15:50
comments: true
categories: docker
---

深淵な理由で気軽にDockerHub（Public registry）を使えない場合は，Private Registryを立てる必要がある．DockerはPrivate registry用のDockerイメージを提供しているため，コンテナを立てるだけですぐに使い始めることができる．

```bash
$ docker run -p 5000:5000 registry
$ docker push docker-private.com:5000/test-image:latest
```

ただ，これだとURLを知っていれば誰でも好きにイメージをpushできてしまうので，認証を行う必要がある．認証には，Dockerクライアント（`docker login`）が対応している，Basic認証を利用する．Docker registryには認証機構がないため，nginxやApacheをリバースプロキシとして配置して，Basic認証を行う．

このとき，いくつか前提がある．

- DockerクライアントのBasic認証はSSLが必須である
- Dockerクライアントは証明書の正当性をちゃんとチェックする（無視できない）

気軽さを求めて自己署名証明書を使った場合，いくつかハマったのでまとめておく．環境としては，サーバーはUbuntuで，リバースプロキシにnginx，クライアントはOSX+boot2dockerとする．

## サーバー側の設定

サーバー側では以下の3つの設定を行う．

- nginxの設定
- 認証するユーザのパスワードの設定
- 自己署名証明書の作成

### nginxの設定

```bash
$ sudo apt-get install -y nginx
```

リバースプロキシにはnginxを用いる．Docker registryはBasic認証を行うためのnginxの設定例を提供している（[docker-registry/contrib/nginx](https://github.com/docker/docker-registry/tree/master/contrib/nginx)）ので，それをそのまま利用する．

```bash
$ git clone https://github.com/docker/docker-registry
$ cp docker-registry/contrib/nginx/nginx_1-3-9.conf /etc/nginx/conf.d/.
$ cp docker-registry/contrib/nginx/docker-registry.conf /etc/nginx/.
```

### パスワードの設定

Docker Registryを利用するユーザの設定を行う．

```bash
$ htpasswd -bc /etc/nginx/docker-registry.htpasswd USERNAME PASSWORD
```

### 自己署名証明書の作成

自己署名（オレオレ）証明書を作る．まず，CAの秘密鍵と公開鍵を作成しておく．

```bash
$ openssl genrsa -des3 -out ca-key.pem 2048
$ openssl req -new -x509 -days 365 -key ca-key.pem -out ca.pem
```

次に，このCAを使ってサーバーの秘密鍵と証明書（CRT）を作成する．

```bash
$ openssl genrsa -des3 -out server-key.pem 2048
$ openssl req -subj '/CN=<Your Hostname Here>' -new -key server-key.pem -out server.csr
$ openssl x509 -req -days 365 -in server.csr -CA ca.pem -CAkey ca-key.pem -out server-cert.pem
```

パスフレーズは削除しておく．

```bash
$ openssl rsa -in server-key.pem -out server-key.pem
```

最後にこれを配置する．

```bash
$ sudo cp server-cert.pem /etc/ssl/certs/docker-registry
$ sudo cp server-key.pem /etc/ssl/private/docker-registry
```

## クライアント側の設定

クライアント側では，サーバーの自己署名証明書を受け入れる設定をする．無視できるようにしようという流れはあるが，実現はしていない，というかなさそう（2014年10月現在）（[#2687](https://github.com/docker/docker/pull/2687)，[#5817](https://github.com/docker/docker/pull/5817)）．

OSX上でboot2dockerを使っている場合は，**OSXで設定するのではなくboot2docker-vmに設定する必要がある**．上でサーバーの自己署名証明書の作成したCAの公開鍵（`ca.pem`）を使う．

```bash
$ boot2docker ssh
$ cat ca.pem >> /etc/ssl/certs/ca-certificates.crt
```





