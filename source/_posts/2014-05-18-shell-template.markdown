---
layout: post
title: '使いやすいシェルスクリプトを書く'
date: 2014-05-18 14:11
comments: true
categories: 
---

できればシェルスクリプトなんて書きたくないんだけど，まだまだ書く機会は多い．シェル芸やワンライナーのような凝ったことではなく，他のひとが使いやすいシェルスクリプトを書くために自分が実践していることのまとめておく．

## ヘルプメッセージ

書いてるシェルスクリプトを何度も使う可能性がある場合は，そのシェルの使い方として`usage`を書く．これを書くのは以下の理由．

- 使えるものならチームに共有しやすい
- インタフェースの定義をあらかじめ書ける

チームに共有するときに`usage`が書いてあれば，とりあえず`usage`見てくださいと言えるため．また，そもそも自分が使い方を忘れるため．だから，自分だけが使う場合でもなるべく書くようにしている．

自分の場合はコードより前に`usage`を書いてしまう．そうすることで「このオプションではこういう動作をする」というインターフェースを自分の中で整理してから，コードを書きはじめることができる．

以下のように書く．

```bash
function usage {
    cat <<EOF
$(basename ${0}) is a tool for ...

Usage:
    $(basename ${0}) [command] [<options>]

Options:
    --version, -v     print $(basename ${0}) version
    --help, -h        print this
EOF
}
```

バージョンを書いたりもする．

```bash
function version {
    echo "$(basename ${0}) version 0.0.1 "
}    
```

## 出力に色をつける

ErrorやWarningによって出力の色を変えて出力を目立たせられると良い．コンソールの出力への色づけはエスケープシーケンスを利用する．基本の構文は以下．

```bash
\033[{属性値}m{文字列}\033[m
```

属性値を変更するだけで，文字色や背景色，文字種を変更することができる．自分は以下のような関数を準備して使う．

```bash
red=31
green=32
yellow=33
blue=34

function cecho {
    color=$1
    shift
    echo -e "\033[${color}m$@\033[m"
}
```

以下のように使う．

```bash
cecho $red "hello"
```
## 対話処理　

例えば，以下のようにユーザ名やパスワードを対話的に入力させることはよくあると思う．

```bash
printf "ID: "
read ID

stty -echo
printf "PASSWORD: "
read PASSWORD
stty echo
```

何度も使うスクリプトだったりすると，これを毎回やらせるのは鬱陶しい．環境変数で事前に設定できるようにしてあげると親切．

```bash
if [ -z "${ID}" ]; then
    printf "ID: "
    read ID
fi

if [ -z "${PASSWORD}" ]; then
    stty -echo
    printf "PASSWORD: "
    read PASSWORD
    stty echo
fi    
```

環境変数を毎回設定するのが鬱陶しいと言われたら，["direnv"](http://deeeet.com/writing/2014/05/06/direnv/)を教えてあげれば良い．

## サブコマンド（引数処理）

サブコマンドやオプションを持たせて処理を分岐したいことはよくある．引数処理をシェルスクリプトでやる場合は，`case`文を使う．例えば，第一引数をサブコマンドとする場合は以下のようにする．

```bash
case ${1} in

    start)
        start
    ;;

    stop)
        stop
    ;;

    restart)
        start && stop
    ;;

    help|--help|-h)
        usage
    ;;

    version|--version|-v)
        version
    ;;
    
    *)
        echo "[ERROR] Invalid subcommand '${1}'"
        usage
        exit 1
    ;;
esac
```

マッチ後の処理を関数にしておけばきれいに書けるし，関数の使い回しもできる．`|`を使えば，複数のマッチを書くことができる．何度も使うような処理には短縮コマンドを準備して上げると良い（例えば，`list`に対して`ls`など）．また，エラーの際には上で言及した`usage`を表示するとより親切になる．

オプションを複数とる場合は，`while`で回す．例えば以下のようにする．

```bash
while [ $# -gt 0 ];
do
    case ${1} in

        --debug|-d)
            set -x
        ;;

        --host|-h)
            HOST=${2}
            shift
        ;;

        --port|-p)
            PORT=${2}
            shift
        ;;

        *)
            echo "[ERROR] Invalid option '${1}'"
            usage
            exit 1
        ;;
    esac
    shift
done
```

オプション引数は，そのときの第二引数とする（厳密にやるなら，この処理はもう少し丁寧に書くべき）．`set -x`はいちいち書いたり消したりせずに，`--debug`オプションで切り替え可能にしておくと，開発中にはとても捗る．







