---
layout: post
title: 'Dockerのイメージはどこに保存されているのか?'
date: 2013-12-16 20:18
comments: true
categories: docker
---

[Where are Docker images stored?](http://blog.thoward37.me/articles/where-are-docker-images-stored/)

ある程度Dockerについて理解したあとに，若干はまりやすい部分についてとても分かりやすい説明がされていたので，簡単にまとめてみる．

## 用語について

Dockerで使われている用語は，若干意味がかぶっていたり，あいまいだったり，他の技術で使われている用語と若干異なる使われ方がされている．

まず，**Registry**と**Index**の違い．*Index*はユーザのアカウントやその権限，検索，タグ付けといったWebインターフェースが提供する部分を管理する．*Registry*は，実際にDockerのイメージなどを保持，提供する部分を管理する．例えば，`docker search`は*Registry*ではなく，*Index*を検索する．`docker push`や`docker pull`を実行すると，*Index*はそのイメージにアクセスしたり，変更を加える権限があるかを決定する．*Index*が承認した後に，*Registry*はイメージの保持や，変更を行う．

次に，**Repository**について．*Repository*は，Githubや他のバージョン管理システムで使われる用語と似ている．よく浮かぶ疑問は，

- *Repository*と*Registory*の違いは何か?
- *Repository*と*Image*の違いは何か?
- *Repository*と*Indexにおけるユーザ名*の違い何か?

`docker images`を実行すると以下のような出力が得られる．

```bash
$ docker images
REPOSITORY    TAG        IMAGE ID        CREATED         VIRTUAL SIZE
ubuntu        12.04      8dbd9e392a96    8 months ago    128 MB
ubuntu        latest     8dbd9e392a96    8 months ago    128 MB
ubuntu        precise    8dbd9e392a96    8 months ago    128 MB
ubuntu        12.10      b750fe79269d    8 months ago    175.3 MB
ubuntu        quantal    b750fe79269d    8 months ago    175.3 MB
```

*Image*のリストは，Repositoryのリストのようにも見える．実際，イメージとはGUID（識別子）であり，`docker images`コマンドはそれらとinteractする方法ではない．

`docker build`や`docker commit`するときに，イメージに名前をつけることができる．名前のフォーマットは`username/image_name`とすることが多いが，そうしなくてもよい．例えば，ubuntuという名前をつけてもよい．

しかし，`docker push`するときにIndexは名前を検索し，一致するRepositryが存在するかを確認する．もし存在する場合はそのレポジトリにアクセスする権限があるかを確認し，あれば新しいバージョンのイメージとしてpushすることを許可する．つまり，Registryは複数のRepositryを保持していることになる．そしてRepositoryはGUIDにより管理された複数のImageを持つ．ではタグとは何か? イメージにはタグをつけることができ，ひとつのRepositoryで異なるGUIDをもつ複数のバージョンのイメージを保持することができる．異なるタグをつけられたバージョンにアクセスするためには，`username/image_name:tag`という形式でアクセスする．

```bash
$ docker images
REPOSITORY    TAG        IMAGE ID        CREATED         VIRTUAL SIZE
ubuntu        12.04      8dbd9e392a96    8 months ago    128 MB
ubuntu        latest     8dbd9e392a96    8 months ago    128 MB
ubuntu        precise    8dbd9e392a96    8 months ago    128 MB
ubuntu        12.10      b750fe79269d    8 months ago    175.3 MB
ubuntu        quantal    b750fe79269d    8 months ago    175.3 MB
```

もう一度，`docker images`の出力をみる．ここには，`ubuntu`という名前がつけられた異なる5つのバージョンのイメージが存在する．Repositryはそれらすべてを`ubuntu`という名前で保持している．つまり，`ubuntu`というのは，イメージの名前に思えるが，実際はRepositoryの名前であり，どこからpullしてきて，どこにpushするべきかを示している．さらに，Repositryの名前は特別なスキーマをもっている．Indexはその最初の部分をusernameとしてパースすることができ，どのRegistryに存在しているかを解釈することができる．

そして，混乱する部分．`thoward/scooby_snacks`という名前のイメージがあるとする．公式のRepositryの名前は，`thoward/scooby_snacks`である，たとえGitHubなどのように`scooby_snacks`の部分がRepository名であると思えるとしても．実際，Dockerのドキュメントなどでも，時には，usernameを含めてRepositryと呼んだり，username以外の部分をRepositoryと呼ぶこともある．それは，`ubuntu`のように，usernameを持たない特別なRepositoryが存在するためである．usernameを別々に考えるのは重要で，なぜなら，Indexが認証で利用するためである．

## どこにイメージは存在するのか?

`docker images`を実行した際に，表示されるimageはどこに保持されているのか? 最初にみるべきは`/var/lib/docker/`．`repositories-aufs`には，RepositoryがJSON形式で保存されている．

```bash
$ sudo cat ls /var/lib/docker/repositories-aufs | python -mjson.tool
{
    "Repositories": {
        "ubuntu": {
           "12.04": "8dbd9e392a964056420e5d58ca5cc376ef18e2de93b5cc90e868a1bbc8318c1c",
           "12.10": "b750fe79269d2ec9a3c593ef05b4332b1d1a02a62b4accb2c21d589ff2f5f2dc",
           "latest": "8dbd9e392a964056420e5d58ca5cc376ef18e2de93b5cc90e868a1bbc8318c1c",
           "precise": "8dbd9e392a964056420e5d58ca5cc376ef18e2de93b5cc90e868a1bbc8318c1c",
           "quantal": "b750fe79269d2ec9a3c593ef05b4332b1d1a02a62b4accb2c21d589ff2f5f2dc"
     }
   }
 }
```

`docker images`と同様の出力が得られた．

```bash
$ docker images
REPOSITORY    TAG        IMAGE ID        CREATED         VIRTUAL SIZE
ubuntu        12.04      8dbd9e392a96    8 months ago    128 MB
ubuntu        latest     8dbd9e392a96    8 months ago    128 MB
ubuntu        precise    8dbd9e392a96    8 months ago    128 MB
ubuntu        12.10      b750fe79269d    8 months ago    175.3 MB
ubuntu        quantal    b750fe79269d    8 months ago    175.3 MB
```

次に，`/var/lib/docker/graph`以下を見てみる．

```
sudo ls -al /var/lib/docker/graph
drwx------  2 root root 4096 Dec 14 07:10 8dbd9e392a964056420e5d58ca5cc376ef18e2de93b5cc90e868a1bbc8318c1c
drwx------  2 root root 4096 Dec 14 07:10 b750fe79269d2ec9a3c593ef05b4332b1d1a02a62b4accb2c21d589ff2f5f2d
drwx------  2 root root 4096 Dec 15 14:31 0bd7d6219d792ee54f565e22212d85bb1eba6ee12f29ea01f08f96e038af6d94
drwx------  2 root root 4096 Dec 15 14:31 1751cf354737bf424ecf67f48444b06288e1372fc263a6ded299b92d5fdc9663
...
```

見にくいが，Dockerがどのように`repositories-aufs`に基づき，どのようにimageを保持しているかがわかる．現在`ubuntu` repositoryの2つのイメージがある．12.04とpreciseそしてlatestのTAGは全て'8dbd9e392a964056420e5d58ca5cc376ef18e2de93b5cc90e868a1bbc8318c1c'というidに紐づいたイメージと一致する．

では，実際にそこには何が保存されているのか?

```bash
$ sudo ls -al /var/lib/docker/graph/8dbd9e392a964056420e5d58ca5cc376ef18e2de93b5cc90e868a1bbc8318c1c
total 16
drwx------  2 root root 4096 Dec 14 07:10 .
drwx------ 22 root root 4096 Dec 15 14:31 ..
-rw-------  1 root root  437 Dec 14 07:10 json
-rw-------  1 root root    9 Dec 14 07:10 layersize
```

`json`はイメージのメタデータを保持している

``` bash
$ sudo cat /var/lib/docker/graph/8dbd9e392a964056420e5d58ca5cc376ef18e2de93b5cc90e868a1bbc8318c1c/json | python -mjson.tool
{
    "comment": "Imported from -",
        "container_config": {
        "AttachStderr": false,
        "AttachStdin": false,
        "AttachStdout": false,
        "Cmd": null,
        "Env": null,
        "Hostname": "",
        "Image": "",
        "Memory": 0,
        "MemorySwap": 0,
        "OpenStdin": false,
        "PortSpecs": null,
        "StdinOnce": false,
        "Tty": false,
        "User": ""
     },
     "created": "2013-04-11T14:13:15.57812-07:00",
     "docker_version": "0.1.4",
     "id": "8dbd9e392a964056420e5d58ca5cc376ef18e2de93b5cc90e868a1bbc8318c1c"
}
```

`layersize`にはlayerのサイズを記録してある．

```
sudo cat /var/lib/docker/graph/8dbd9e392a964056420e5d58ca5cc376ef18e2de93b5cc90e868a1bbc8318c1c/layersize
128029199
```

とても単純．これが，Repository名でimageを参照するために背後で行われている方法である．
