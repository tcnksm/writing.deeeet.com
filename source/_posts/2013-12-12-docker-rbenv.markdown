---
layout: post
title: 'Dockerで複数バージョンのrubyがインストールされたイメージを作る'
date: 2013-12-12 00:47
comments: true
categories: docker
---

[docker-rbev](https://github.com/tcnksm/docker-rbenv)

これを使って作成できるイメージは以下の2つ．

- [tcnksm/rbenv](https://index.docker.io/u/tcnksm/rbenv/): 複数バージョンのrubyがインストールされたイメージ
- [tcnksm/rbenv-rubygems](https://index.docker.io/u/tcnksm/rbenv-rubygems/): 上のイメージに加えてbundlerやその他の基本的なrubygemsがインストールされたイメージ

どちらも[index.docker.io](https://index.docker.io/)に上げてあるので，pullすればそのまま使うことができる．

簡単にこれらのイメージを作成するDockerfileの解説を書いておく．

まず，[rbenv-image/Dockerfile](https://github.com/tcnksm/docker-rbenv/blob/master/rbenv-image/Dockerfile)は，基本的には普段rbenvとruby-buildによるインストールと同じことをしている．

```
FROM base

MAINTAINER tcnksm, https://github.com/tcnksm

RUN apt-get update
RUN apt-get install -y --force-yes build-essential curl git
RUN apt-get install -y --force-yes zlib1g-dev libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt-dev
RUN apt-get clean

RUN git clone https://github.com/sstephenson/rbenv.git /root/.rbenv
RUN git clone https://github.com/sstephenson/ruby-build.git /root/.rbenv/plugins/ruby-build
RUN ./root/.rbenv/plugins/ruby-build/install.sh

ADD ./rbenvrc /etc/profile.d/rbenvrc
ADD ./rubies.txt /root/rubies.txt

ENV PATH /root/.rbenv/bin:$PATH

# Install multiple versions of ruby
ENV CONFIGURE_OPTS --disable-install-doc
RUN xargs -L 1 rbenv install < /root/rubies.txt

```

1. ベースイメージを持ってくる(`FROM base`)
1. rubyのビルドに必要なパッケージのインストール(`RUN apt-get ...`)
1. [rbenv](https://github.com/tcnksm/docker-rbenv/tree/master)のダウンロード
1. [ruby-build](https://github.com/sstephenson/ruby-build)のダウンロード
1. rbenvで利用する環境変数を記述した`rbevrc`をイメージ内に配置(`ADD ./rbenvrc /etc/profile.d/rbenvrc`)
1. インストールしたいrubyのバージョンを記述した`rubies.txt`をイメージ内に配置

あとは`rubies.txt`に記述したバージョンのrubyを順にインストールするだけ．別のバージョンがインストールされたイメージを作りたい場合は`rubies.txt`を編集する．実行は以下のコマンドで行う．

``` bash
docker build -t rbenv rbenv-image/
```

index.docker.ioに上げたい場合は以下を実行する．

``` bash
docker login
docker push rbenv
```

次に，[rbenv-rubygems-image/Dockerfile](https://github.com/tcnksm/docker-rbenv/blob/master/rbenv-rubygems-image/Dockerfile)は，上のイメージに追加で，バージョンごとにbundlerとGemfileに記述したrubygemsのインストールを行う．

```
FROM tcnksm/rbenv
MAINTAINER tcnksm, https://github.com/tcnksm

ADD ./Gemfile /root/Gemfile

# Install bundler
RUN . /etc/profile.d/rbenvrc; for v in $(cat /root/rubies.txt); do rbenv global $v; gem install --no-rdoc --no-ri bundler; done

# Install basic rubygems by bundler
RUN . /etc/profile.d/rbenvrc; cd /root/; for v in $(cat rubies.txt); do rbenv global $v; bundle install; done
```

1. rbenvイメージを持ってくる(`FROM tcnksm/rbenv`)
1. Gemfileの配置(`ADD ./Gemfile /root/Gemfile`)
1. Bundlerのインストール
1. `bundle install`の実行

実行は以下．

``` bash
docker build -t rbenv-rubygems rbenv-rubygems-image
```

かなり簡単にできた．でも，複数バージョンを扱うためにかなり無理矢理なシェルスクリプトのワンライナーを書いた．もっとDockerfileは柔軟かつ構造的に書けるようになってほしいと思う．


参考

- [Docker for Rubyists](http://www.sitepoint.com/docker-for-rubyists/)
- [docker-plenv-vanilla](https://github.com/miyagawa/docker-plenv-vanilla)
- [Dockerを使ってJenkinsのジョブごとにテスト実行環境を分離する - orangain flavor](http://orangain.hatenablog.com/entry/jenkins-docker)
- [Docker虎の巻](https://gist.github.com/tcnksm/7700047)








