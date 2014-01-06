---
layout: post
title: 'OSXからVagrant上のDockerコンテナにsshで接続する'
date: 2014-01-05 23:54
comments: true
categories: docker
---

以下のようにする．

- Vagrant VMにIPアドレスを割り当てる
- Vagrant VMの任意のポートをDockerコンテナの任意のポートにport forwardする

まずVagrantfile

```
Vagrant.configure("2") do |config|
    config.vm.box = "precise64"
    config.vm.box_url = "http://files.vagrantup.com/precise64.box"
    config.vm.provision :docker do |d|
        d.pull_images "base"
    end
end
```
