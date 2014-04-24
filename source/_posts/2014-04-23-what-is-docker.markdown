---
layout: post
title: 'Dockerとは何か？どこで使うべきか？'
date: 2014-04-23 18:27
comments: true
categories: docker
---


この記事はDockerに関する実験的な記事や，Buildpackを使ってHeroku AppをDocker Containerとして使えるようにする["building"](https://github.com/CenturyLinkLabs/building)で知られるCenturyLink Labsの
["What is Docker and When To Use It"](http://www.centurylinklabs.com/what-is-docker-and-when-to-use-it/)の翻訳です．
Dockerとは何か？Dockerをいつ使うべきか？についてよく見かける記事とは異なった視点で説明されています．
翻訳は[許可](https://twitter.com/CenturyLinkLabs/status/459030687484362752)をとった上で行っています．
なお，読みやすさを重視して，若干の意訳を含めます．

## Dockerとは何でないか

まず，Dockerとは何かを説明する前に，Dockerは何で**ない**かについて述べる．

Dockerの否定形は何か？Dockerの制限は何か？Dockerができないことは何か？

- DockerはLXCのようなLinux Containerでは**ない**
- DockerはLXCだけのラッパーでは**ない**（理論的には仮想マシンも管理できる）
- DockerはChefやPuppet，SaltStackのようなConfiguration toolの代替では**ない**
- DockerはPaaSでは**ない**
- Dockerは異なるホスト間での連携が得意では**ない**
- DockerはLXC同士を隔離するのが得意では**ない**

## Dockerとは何か

では，Dockerのメリットはなにか？

- DockerはディスクイメージのビルドやDocker Indexを通じてそれらを共有することができる
- Dockerはインフラを管理することができる（現在はLinux Containerのみだが，将来的にはKVMやHyper-v，Xenも管理できるようになる）
- DockerはChefやPuppetといったConfiguration toolでビルドされたサーバのテンプレートにとって，イメージ配布の良いモデルである
- DockerはCopy-on-wirteのファイルシステムである[btrfs](http://ja.wikipedia.org/wiki/Btrfs)を使っており，Gitのようにファイルシステムの差分を管理することができる
- Dockerはディスクイメージのレポジトリをもっているため，簡単に様々なOS上でDockerを動かすことができる

## Dockerの代替は何か

Amazonの[AWS Marketplace](https://aws.amazon.com/marketplace/ref=mkt_ste_amis_redirect?b_k=291)はDocker Indexに近い．ただし，AMIはAWS上でしか動かすことができないのに対して，Dockerイメージは，Dockerが動いているLinuxサーバであればどこでも動かすことができる．

Cloud Foundryの[Warden](https://github.com/cloudfoundry/warden)はLXCの管理ツールであり，Dockerに近い．ただし，Docker Indexのような他人とイメージを共有する仕組みを持っていない．

## Dockerをいつ使うべきか

DockerはGitやJavaのように基本的な開発ツールであり，日々の開発やオペレーションでDockerを導入し始めるべきである．

例えば，

- アプリケーションの**OSのバージョン管理システム**として使う
- チームにアプケーションの**OSを配布する**のに使う
- 利用している**サーバーと同様の環境をラップトップ上に再現する**のに使う（例えば[building](https://github.com/centurylinklabs/building)を使う）
- アプリケーションに**異なる開発フェーズ**（dev，stg，prod，QA）が必要なときに使う
- [ChefのCookbook](http://tech.paulcz.net/2013/09/creating-immutable-servers-with-chef-and-docker-dot-io.html)や[PuppetのManifest](http://puppetlabs.com/blog/building-puppet-based-applications-inside-docker)と使う


## DockerとJavaはどこが似ているのか

Javaには"Write Once. Run Anywhere（一度書けばどこでも実行できる）"という確約がある．

Dockerにも同様の確約がある．一度サーバのテンプレートをつくれば，Dockerが動いているLinuxサーバであれば，どこでも全く同じようにそれを動かすことができる（["Build Once．Run Anywhere"](https://speakerdeck.com/naoya/dockerapurikesiyonfalsepotabiriteiwokao-eru-number-dockerjp)）

例えば，以下のようなJavaコードがあるとする．

```java
// HelloWorld.java
class HelloWorldApp {
    public static void main(String[] args) {
        System.out.println("Hello World!");
    }
}
```

`javac HelloWorld.java`により生成される`HelloWorld.class`はJVMさえあればどんなマシン上でも動かすことができる．



Then run javac HelloWorld.java. The resulting HelloWorld.class can be run on any machine with a JVM.

In Docker, you write a Dockerfile:

FROM ubuntu:13.10

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -qq -y && \
    apt-get install curl -qq -y && \
    apt-get clean

RUN curl -sSL https://get.rvm.io | bash -s stable --ruby=2.1.1
Then run docker build -t my/ruby . and the resulting container, my/ruby can be run on any machine with a Docker server.

The Docker server is like a JVM for systems. It lets you get around the leaky abstraction of Virtual Machines by giving you an abstraction that runs just above virtualization (or even bare metal).

HOW DOCKER IS LIKE GIT

Git’s promise: Tiny footprint with lightning fast performance.

Docker has the same promise. Except instead of for tracking changes in code, you can track changes in systems. Git outclasses SCM tools like Subversion, CVS, Perforce, and ClearCase with features like cheap local branching, convenient staging areas, and multiple workflows. Docker outclasses other tools with features like ultra-fast container startup times (microseconds, not minutes), convenient image building tools, and collaboration workflows.

For example, in Git you make some change and can see changes with git status:

$ git init .
$ touch README.md
$ git add .
$ git status
On branch master

Initial commit

Changes to be committed:
  (use "git rm --cached ..." to unstage)

  new file:   README.md
$ git commit -am "Adding README.md"
[master (root-commit) 78184aa] Adding README.md
 1 file changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 README.md
$ git push
Counting objects: 49, done.
Delta compression using up to 4 threads.
Compressing objects: 100% (39/39), done.
Writing objects: 100% (49/49), 4.29 KiB | 0 bytes/s, done.
Total 49 (delta 13), reused 0 (delta 0)
To git@github.com:my/repo.git
 * [new branch]      master -> master
Branch master set up to track remote branch master from origin.
$ git pull
remote: Counting objects: 4, done.
remote: Compressing objects: 100% (3/3), done.
remote: Total 3 (delta 0), reused 0 (delta 0)
Unpacking objects: 100% (3/3), done.
From github.com:cardmagic/docker-ruby
   f98f3ac..4578f21  master     -> origin/master
Updating f98f3ac..4578f21
Fast-forward
 README.md | 3 +++
 1 file changed, 3 insertions(+)
 create mode 100644 README.md
$ git whatchanged
commit 78184aa2a04b4a9fefb13d534d157ef4ac7e81b9
Author: Lucas Carlson <lucas@rufy.com>
Date:   Mon Apr 21 16:46:34 2014 -0700

    Adding README.md

:000000 100644 0000000... e69de29... A  README.md
In Docker, you can track changes throughout your entire system:

$ MY_DOCKER=$(docker run -d ubuntu bash -c 'touch README.md; sleep 10000')
$ docker diff $MY_DOCKER
A /README.md
C /dev
C /dev/core
C /dev/fd
C /dev/ptmx
C /dev/stderr
C /dev/stdin
C /dev/stdout
$ docker commit -m "Adding README.md" $MY_DOCKER my/ubuntu
4d46072299621b8e5409cbc5d325d5ce825f788517101fe63f5bda448c9954da
$ docker push my/ubuntu
The push refers to a repository [my/ubuntu] (len: 1)
Sending image list
Pushing repository my/ubuntu (1 tags)
511136ea3c5a: Image already pushed, skipping
Image 6170bb7b0ad1 already pushed, skipping
Image 9cd978db300e already pushed, skipping
de2fdfc8f7d8: Image successfully pushed
Pushing tag for rev [de2fdfc8f7d8] on {https://registry-1.docker.io/v1/repositories/my/ubuntu/tags/latest}
$ docker pull my/ubuntu
Pulling repository my/ubuntu
de2fdfc8f7d8: Download complete
511136ea3c5a: Download complete
6170bb7b0ad1: Download complete
9cd978db300e: Download complete
$ docker history my/ubuntu
IMAGE               CREATED             CREATED BY                                      SIZE
de2fdfc8f7d8        3 minutes ago       bash -c touch README.md; sleep 10000            77 B
9cd978db300e        11 weeks ago        /bin/sh -c #(nop) ADD precise.tar.xz in /       204.4 MB
6170bb7b0ad1        11 weeks ago        /bin/sh -c #(nop) MAINTAINER Tianon Gravi
CONCLUSIONS

These collaboration features (docker push and docker pull) are one of the most disruptive parts of Docker. The fact that any Docker image can run on any machine running Docker is amazing. But The Docker pull/push are the first time developers and ops guys have ever been able to easily collaborate quickly on building infrastructure together. The app guys can focus on building perfect app servers and the ops guys can focus on building perfect service containers. The app guys can share app containers with ops guys and the ops guys can share MySQL and PosgreSQL and Redis servers with app guys.

This is the game changer with Docker. That is why Docker is changing the face of development for our generation. The Docker community is already curating and cultivating generic service containers that anyone can use as starting points. The fact that you can use these Docker containers on any system that runs the Docker server is an incredible feat of engineering.

To learn more about how to incorporate Docker into your daily life, follow along on this blog. Here is a good starting point.
