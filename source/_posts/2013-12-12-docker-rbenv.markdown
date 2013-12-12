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

どちらも[index.docker.io](https://index.docker.io/)に上げてあるので，pullすればそのまま使うことができる．これを使えば，例えば以下のように，Travis CIのような複数rubyのバージョンのrspecテストを実行することができる．

``` bash
docker run tcnksm/rbenv-rubygems sh -ex sample.sh
```

``` bash
// sample.sh

. /etc/profile.d/rbenvrc

git clone https://github.com/tcnksm/sample-rb-project project
cd project

for v in 1.9.3-p392 2.0.0-p353
do
  rbenv global $v
  bundle
  rspec
done
            
```

簡単にこれらのイメージを作成するDockerfileの解説を書いておく．

まず，[rbenv-image/Dockerfile](https://github.com/tcnksm/docker-rbenv/blob/master/rbenv-image/Dockerfile)は，基本的には普段rbenvとruby-buildによるインストールと同じことをしている．

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

1. rbenvイメージを持ってくる(`FROM tcnksm/rbenv`)
1. Gemfileの配置(`ADD ./Gemfile /root/Gemfile`)
1. Bundlerのインストール
1. `bundle install`の実行

実行は以下．

``` bash
docker build -t rbenv-rubygems rbenv-rubygems-image
```

かなり簡単にできた．でも，複数バージョンを扱うためにかなり無理矢理なシェルスクリプトのワンライナーを書いた．もっとDockerfileは柔軟かつ構造的に書けるようになってほしいと思う．

あとは，イメージに対してもう少し簡単にテストを走らせれるような工夫をしたい．

参考

- [Docker for Rubyists](http://www.sitepoint.com/docker-for-rubyists/)
- [docker-plenv-vanilla](https://github.com/miyagawa/docker-plenv-vanilla)
- [Dockerを使ってJenkinsのジョブごとにテスト実行環境を分離する - orangain flavor](http://orangain.hatenablog.com/entry/jenkins-docker)
- [Docker虎の巻](https://gist.github.com/tcnksm/7700047)








