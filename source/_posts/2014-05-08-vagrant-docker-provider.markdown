---
layout: post
title: 'VagrantのDocker provider'
date: 2014-05-08 21:42
comments: true
categories: vagrant docker
---

[Feature Preview: Docker-Based Development Environments](http://www.vagrantup.com/blog/feature-preview-vagrant-1-6-docker-dev-environments.html)

Vagrant 1.6からDocker providerがサポートされた．つまり，VagrantでVMだけでなくコンテナも管理できるようになった．

この機能はネイティブでDockerをサポートしてないOSXでも使え，この場合は裏側でProxy VM（[boot2docker box](https://vagrantcloud.com/mitchellh/boot2docker)）が勝手に立ち上がって，その上でコンテナが立ち上がる．イメージとしては以下のようになる．

```
OSX -> (Proxy VM) -> Docker Container
```

## 何が嬉しいのか

VagrantでDockerコンテナを立ち上げる利点はかなりあると思う，

- `vagrant up`だけで環境を立ち上げられる
- 同様のインターフェースでVagrantはLinuxでもOSXでも動かせる
- Vagrantの機能（syncd folder，ネットワーク設定，`vagrant ssh`，provisioner，`vagrant share`）が使える
- コンテナの立ち上げの設定をVagrantfileに書ける
- Proxy VMの設定をVagranfileに書ける
- プラグインが書ける


これはそのままVagrantの利点だけど，それをDockerコンテナに持ち込めるのがよい．つまり，[Vagrant道](http://mitchellh.com/the-tao-of-vagrant)をDockerコンテナを使った開発にも適用できるようになる．

自分的には，`Vagrantfile`にコンテナの設定などを再現可能な状態で簡単に残せるのがよい．今までOSXでDocker使うときは，`boot2docker init`して，`VBoxManage modifyvm`でポートフォワードして，`export DOCKER_HOST`して，などなど一手間あったが，`vagrant up`だけになる．それだけでも嬉しい．

また，v1.6から任意のディレクトリからVagrantのVMを操作できるようになった（[Global Status and Control](http://www.vagrantup.com/blog/feature-preview-vagrant-1-6-global-status.html)）ので，ほとんどDockerを扱うような感覚で扱える．

## 使ってみた

OSX上でざっと触ってみた．まずは，最新版(1.6.1)をインストール．

```bash
$ vagrant -v
Vagrant 1.6.1
```

### Dockerfile

まず，`Dockerfile`の準備．ここでは簡単な例としてApacheコンテナを立ち上げるための`Dockerfile`を準備する．

```bash
FROM ubuntu:12.04

RUN apt-get update
RUN apt-get install -y apache2

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

RUN echo 'Hello, vagrant docker provider' > /var/www/index.html

EXPOSE 80
ENTRYPOINT ["/usr/sbin/apache2"]
CMD ["-D", "FOREGROUND"]
```

### Vagrantfile

次にコンテナ用の`Vagrantfile`を準備する．

```ruby
Vagrant.configure("2") do |config|
    config.vm.provider "docker" do |d|
        d.build_dir = "."
    end
    config.vm.network :forwarded_port, guest: 80, host: 8080
end          
```

やっているのは，

- カレントディレクトリ（`.`）のDockerfileをもとにイメージをビルド
- そのイメージからコンテナの立ち上げ

コンテナの立ち上げの際は，Proxy VMの8080ポートをコンテナの80ポートにポートフォワードする．

あとは，いつも通りに立ち上げるだけ．

```bash
$ vagrant up --provider=docker
```

これを実行すると，VagrantはProxy CM（boot2docker box）のインストール，イメージのビルドなどをよしなにやってくれる．

[global status](http://www.vagrantup.com/blog/feature-preview-vagrant-1-6-global-status.html)を見てみると，VMとコンテナの両方が起動しているのが確認できる．

```bash
$ vagrant global-status
2bb2281  default virtualbox running   /Users/deeeet/.vagrant.d/data/docker-host
4f5f9d8  default docker     preparing /Users/deeeet/dev/sample/
```

他にも，

- `vagrant reload`でDockerfileの再ビルドを実行する
- `vagrant docker-logs`で立ち上がったコンテナのログを確認する

などができる．

また，ホスト（OSX）の4243ポートはProxy VMの4243ポートへポートフォワードされているので，`tcp://localhost:4243`を介してDockerコマンドを直接叩くこともできる．

### Vagrantfile (Proxy VM)

上の例は，コンテナの起動まではちゃんと動作する．しかし，OSXからコンテナにアクセスするといったことができない．というのもOSXからProxy VMのポートフォワードが設定されていないので，そもそも到達しない．

このようにデフォルトのProxy VMにはまだまだ不都合がありそうなので，自分で設定を触れるようにしておく．Docker providerでは，Proxy VMのための`Vagrantfile`を指定することができる．以下のように`vagrant_vagrantfile`を使う．

```bash
Vagrant.configure("2") do |config|
    config.vm.provider "docker" do |d|
        d.vagrant_vagrantfile = "proxy-vm/Vagrantfile"
        d.build_dir = "."
    end
    config.vm.network :forwarded_port, guest: 80, host: 8080
end
```

デフォルトのProxy VMには，以下のVagrantfileが使われいる．

```ruby
# https://github.com/mitchellh/vagrant/blob/master/plugins/providers/docker/hostmachine/Vagrantfile

Vagrant.configure("2") do |config|
    config.vm.box = "mitchellh/boot2docker"

    config.vm.provider "virtualbox" do |v|
        # On VirtualBox, we don't have guest additions or a functional vboxsf
        # in TinyCore Linux, so tell Vagrant that so it can be smarter.
        v.check_guest_additions = false
        v.functional_vboxsf     = false
    end

    # b2d doesn't support NFS
    config.nfs.functional = false
end
```

このVagranfileにPort Forwardの設定を追記して，`vagrant_vagrantfile`で指定する形にしておく．

## 雑感

他にも`vagrant ssh`やsyncd folderも使えそう．sshできれば，chefやpuppetのprovisionerをコンテナに流せるし，syncd folderは，Dockerのvolume機能と相性が良さそう．






