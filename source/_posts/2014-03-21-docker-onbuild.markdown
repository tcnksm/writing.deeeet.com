---
layout: post
title: 'DockerfileのONBUILDを用いた開発プロセス'
date: 2014-03-21 15:02
comments: true
categories: docker
---

Docker 0.8において`ONBUILD`というDockerfile用のコマンドが導入された．0.8ではOSXのdocker clientが脚光を浴びたが，この`ONBUILD`はかなり強力な機能．リリースノートは[こちら](http://blog.docker.io/2014/02/docker-0-8-quality-new-builder-features-btrfs-storage-osx-support/)．`ONBUILD`の公式ドキュメントは[こちら](http://docs.docker.io/en/latest/reference/builder/#onbuild)．

`ONBUILD`を使うと，次のビルドで実行するコマンドをイメージに仕込むことができるようになる．つまり，ベースイメージに`ONBUILD`によるコマンドを仕込み，別のDockerfileでそのベースイメージを読み込みビルドした際に，そのコマンドを実行させるということが可能になる．要するに，`親Dockerfile`のDockerfileコマンドを`子Dockerfile`のビルド時に実行させることができる機能．

これは，アプリケーション用のイメージを作るときや，ユーザ特有の設定を組み込んだデーモン用のイメージを作るときなどに有用になる．

言葉では伝わらないと思うので簡単に実例を示す．例えば，以下のような`Dockerfile.base`を準備する．

```bash
# Docekerfile.base
FROM ubuntu
ONBUILD RUN echo "See you later"
```

これを`tcnksm/echo_base`という名前でビルドする．

```bash
$ docker build -t tcnksm/echo_base - < Dockerfile.base
Step 0 : FROM ubuntu
Pulling repository ubuntu
...
f323cf34fd77: Download complete
---> 9cd978db300e
Step 1 : ONBUILD RUN echo "See you later"
---> Running in 9e42ede94d60
---> e18fdd8d9fa8
```

`RUN echo`は実行されていない．

次に，この`tcnksm/echo_base`を基にした別のイメージを作成する`Dockerfile`を準備する．

```bash
FROM tcnksm/echo_base
```

`tcnksm/echo`という名前でビルドする．

```bash
$ docker build -t tcnksm/echo .
Uploading context 3.584 kB
Uploading context
Step 0 : FROM tcnksm/base
# Executing 1 build triggers
Step onbuild-0 : RUN echo "See you later"
---> Running in cddf3cf85ff8
See you later
---> 9f0189c1e902
---> 9f0189c1e902
Successfully built 9f0189c1e902
```

ベースイメージ`tcnksm/echo_base`で仕込んだ`RUN echo ..`が実行された．これが`ONBUILD`の機能．

では，開発プロセスにおいて，どのように使えるか．**ベースイメージの開発とアプリーションの開発の分離が可能になる．**

## Apacheイメージの例

/var/www以下のhtdocsを表示する単純なアプリーションを作るとする．開発の流れは以下のようになる．

1. ベースイメージの作成/ビルド
2. ベースイメージを使った開発
3. 最終イメージのビルド
4. デプロイ

まず，ベースイメージの作成．以下のような`Dockerfile.base`を作成する．

```bash
FROM ubuntu:12.04

RUN apt-get update
RUN apt-get install -y apache2

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

ONBUILD ADD ./htdocs /var/www/

EXPOSE 80
ENTRYPOINT ["/usr/sbin/apache2"]
CMD ["-D", "FOREGROUND"]
```

やっているのは，

- Apacheのインストール
- `ONBUILD`による次回のビルド時の`htdocs`ディレクトリの`/var/www`への追加
- 起動コマンドの設定

ベースイメージをビルドする．

```bash
$ docker build -t tcnksm/apache_base - < Dockerfile.base
```

次に，アプリーションの開発（単純にhtmlを書くだけだが）．アプリーションの開発者は，ベースのイメージがどうなっているかは知らなくてもよい．ただ，`tcnksm/apache_base`を使って，`htdocs`以下にhtmlを書けばよいということだけを知っていればよい．

開発中は，`-v`オプションを用いて，ローカルの`htdocs`ディレクトリをイメージにマウントする．

```
$ mkdir htdocs
$ echo "<h1>Hello, docker</h1>" > htdocs/index.html
$ docker run -p 80:80 -v $(pwd)/htdocs:/var/www -t tcnksm/apache_base
```

後は，htdocs以下を作り込むだけ．編集はリアルタイムで更新される．`vagrant share`みたいに外部のひととやり取りしつつ開発したいなら，[Docker share](http://deeeet.com/writing/2014/03/12/docker-share/)を使う．

開発が終了したら，最終イメージのビルド．以下のようなDockerfileを準備してビルドするだけ．

```bash
FROM tcnksm/apache_base
```

```bash
$ docker build -t tcnksm/apache .
```

起動確認をする．

```bash
$ docker run -p 80:80 tcnksm/apache
```

あとは，[ORCHARD](https://orchardup.com/)なり，[DigitalOcean](https://www.digitalocean.com/)なりにイメージを持って行くだけ．

ちなみに，この`tcnksm/apache_base`はdocker.ioに上げてあるので誰でも使える．イメージをpullしてhtdocsをつくるだけ．

## Railsイメージの例

Railsアプリでも同様のことができる．ベースイメージは，以下のような感じ．

```
# ... Install ruby 

RUN mkdir /app
WORKDIR /app

ONBUILD ADD rails_app/Gemfile /app/Gemfile
ONBUILD RUN bundle install
ONBUILD ADD rails_app /app

ENTRYPOINT ["bash", "-l", "-c"]
```

（Gemfileの`ADD`については，["How to Skip Bundle Install When Deploying a Rails App to Docker if the Gemfile Hasn’t Changed"](http://ilikestuffblog.com/2014/01/06/how-to-skip-bundle-install-when-deploying-a-rails-app-to-docker/)を参考に）

アプリケーション開発者は，`rails_app`というディレクトリ名でアプリケーションを開発すればよいということを知っていればよい．

## 参考

- [A reveal.js Docker Base Image with ONBUILD](http://mindtrove.info/a-reveal.js-docker-base-image-with-onbuild/)
- [Docker quicktip #3 – ONBUILD](http://www.tech-d.net/2014/02/06/docker-quicktip-3-onbuild/)
- ["Toward FutureOps: Stable, repeatable, environments from dev to prod"](http://www.slideshare.net/profyclub_ru/8-mitchell-hashimoto-hashicorp)


