---
layout: post
title: 'ChefでOS Xの環境セットアップするやつ'
date: 2013-10-16 00:43
comments: true
categories: 
---

[tcnksm/chef-dev-env](https://github.com/tcnksm/chef-dev-env) をつくった．以下のことができる．

- Homebrewパッケージのインストール
- dmgパッケージのインストール
- rubygemsのインストール
- dotfilesのインストールとセットアップ

OS X特有のレシピだとDockの設定とかできそうだけど，得にデフォで問題ないからやってない．
ここまできたら，AppStoreからのダウンロードもできたらなと思う．

インストール対象のパッケージはdata_bugsとかを使うとすっきり書けた．
作業してて，これ使うなーと思ったらここにどんどん貯めていく．

``` ruby
#data_bags/packages/homebrew.json
{
    "id": "homebrew",
    "targets": [
                "tig",
                "coreutils",
                "rmtrash",
                "go",
                ....
                ]
}
```

で，後は以下で呼び出すだけ．

``` ruby
item = data_bag_item(:packages, "homebrew")

item["targets"].each do |pkg|
    package pkg
end
```

あとRakefile作っておくと便利．

``` ruby
namespace :run do
    task :osx do
        sh "chef-solo -c config/solo.rb -j nodes/osx.json"
    end
end
```

会社だとUbuntuでの開発もやったりするからnode追加して，Ubuntu用も作る予定．
これでどこでも同じ環境がすぐに作れる．便利．

Chefの基礎と各ディレクトリの役割とかは["入門Chef Solo - Infrastructure as Code"](http://www.amazon.co.jp/%E5%85%A5%E9%96%80Chef-Solo-Infrastructure-as-Code-ebook/dp/B00BSPH158)を読んでほとんど理解できた．OS Xのセットアップに関しては以下を参考にした．

- [Managing My Workstations With Chef](http://jtimberman.housepub.org/blog/2011/04/03/managing-my-workstations-with-chef/)
- [pivotal-sprout/sprout](https://github.com/pivotal-sprout/sprout)
- [dann/chef-macbox](https://github.com/dann/chef-macbox)




