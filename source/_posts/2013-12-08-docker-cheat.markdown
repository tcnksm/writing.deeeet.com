---
layout: post
title: 'Docker基礎コマンド'
date: 2013-12-08 22:04
comments: true
categories: docker
---

[Docker 虎の巻](https://gist.github.com/tcnksm/7700047)

Dockerの基礎のまとめが良かったので翻訳してみた．原典は，[Docker Cheat Sheet](https://gist.github.com/wsargent/7049221)．このまとめは説明は十分にあるが，例がほとんどない．実例を使って，コンテナとイメージに関する基礎コマンドをまとめてみる．Dockerの導入などはここでは触れない．

## はじめに

ベースイメージを取得しておく．

```
docker pull ubuntu
```

コンテナのIDをいちいち保持しておくのは面倒，忘れるので，以下のaliasを設定しておくと直近に起動したコンテナのIDを呼び出すことができるようになる（[15 Docker tips in 5 minutes](http://sssslide.com/speakerdeck.com/bmorearty/15-docker-tips-in-5-minutes)）．


``` bash
alias dl='docker ps -l -q'
```


## コンテナ

コンテナを作成する．`-d`オプションでバックグラウンドで実行する．

``` bash
docker run -d ubuntu /bin/sh -c "while true; do echo hello world; sleep 1; done"
```

コンテナを停止する．

``` bash
docker stop `dl`
```

コンテナを起動する．

``` bash
docker start `dl`
```

コンテナを再起動する．

``` bash
docker restart `dl`
```

起動中のコンテナに接続する．

``` bash
docker attach `dl`
```

コンテナ内のファイルをホストにコピーする．

``` bash
docker cp `dl`:/etc/passwd .
```

ホストのディレクトリをコンテナにマウントする．

``` bash
docker run -v /home/vagrant/test:/root/test ubuntu echo yo
```

コンテナを削除する．

``` bash
dockr rm `dl`
```

## コンテナの情報

起動中のコンテナを表示する．停止中のコンテナも表示するには，`-a`オプション．

``` bash
docker ps
```

コンテナの情報（IPなど）を表示する.

``` bash
docker inspect `dl`
```

コンテナのログを表示する．

``` bash
docker logs `dl`
```

コンテナのプロセスを表示する．

``` bash
docker top `dl`
```


## イメージ


コンテナからイメージを作成する．タグ名は\<username>/\<imagename\>が[奨励されている](http://docs.docker.io/en/latest/use/workingwithrepository/#committing-a-container-to-a-named-image)

``` bash
docker run -d ubuntu /bin/sh -c "apt-get install -y hello"
docker commit -m "My first container" `dl` tcnksm/hello
```

Dockerfileからイメージを作成する．

``` bash
echo -e "FROM base\nRUN apt-get install hello\nCMD hello" > Dockerfile
docker build tcnksm/hello .
```

イメージ内にログインする．`-rm`オプションをつけるとコンテナの停止後にそのコンテナは破棄される．

``` bash
docker run -rm -t -i tcnksm/hello /bin/bash
```

イメージをリモートレポジトリにアップロードする．あらかじめ[Docker index](https://index.docker.io/)にアカウントを作成しておく必要がある．今回の例は[こちら](https://index.docker.io/u/tcnksm/hello). 

``` bash
docker login
docker push tcnksm/hello
```

イメージを削除する．

``` bash
docker rmi tcnkms/hello
```

## イメージの情報

イメージ一覧を表示する.

``` bash
docker images
```

イメージの詳細情報(IPなど)を表示する．

``` bash
docker inspect tcnksm/hello
```

イメージのコマンド履歴を表示する．

``` bash
docker history tcnksm/hello
```




