---
layout: post
title: 'Go言語のコードレビュー'
date: 2014-05-16 00:02
comments: true
categories: golang
---

SoundCloudが2年半ほどGo言語を利用したプロダクトを本番で運用した知見を[GopherCon](http://www.gophercon.com/)で発表していた（["Go: Best Practices for Production Environments"](http://peter.bourgon.org/go-in-production/)）．その中で，GoogleのGo言語のコードレビューコメントをまとめたサイトが紹介されていた．

自分でも最近Go言語を書くようになり，使えそうなので，ざっと抄訳．

[CodeReviewComments](https://code.google.com/p/go-wiki/wiki/CodeReviewComments#Import_Dot)

- [gofmt](http://golang.org/cmd/gofmt/)でコードの整形をすること
- [コメント](http://golang.org/doc/effective_go.html#commentary)は文章で書くこと．`godoc`がいい感じに抜き出してくれる．対象となる関数（変数）名で初めて，ピリオドで終わること

```go
// A Request represents a request to run a command.
type Request struct { ...

// Encode writes the JSON encoding of req to w.
func Encode(w io.Writer, req *Request) { ...
```

- 外から参照されるトップレベルの識別子にはコメントを書くべき
- 通常の[エラー処理](http://golang.org/doc/effective_go.html#errors)に`panic`を使わないこと．errorと複数の戻り値を使うこと
- エラー文字列は他で利用されることが多いので，（固有名詞や頭字語でない限り）大文字で始めたり，句読点で終わったりしないこと．つまり`fmt.Errorf("Something bad")`のように大文字で始めるのではなく，`fmt.Errorf("something bad")`とすること．こうすれば，例えば，`log.Print("Reading %s: %v", filename, err)`としても，文の途中に大文字が入るようなことがなくなる
- エラーの戻り値を`_`で破棄しないこと．関数がエラーを返すなら，関数が成功したかをチェックすること．エラーハンドリングをして，どうしようもないときに`panic`とする．
- パッケージのインポートは空行を入れることでグループとしてまとめるとよい．最初のグループに標準ライブラリをおく．これらは[goimport](https://godoc.org/code.google.com/p/go.tools/cmd/goimports)がやってくれる．

```go
import (
    "fmt"
    "hash/adler32"
    "os"

    "appengine/user"
    "appengine/foo"
        
    "code.google.com/p/x/y"
    "github.com/foo/bar"
)    
```

- `.`形式によるパッケージのインポートはテストで使える．例えば，以下のように依存の問題で，テストしたいパッケージ名が使えない場合，
```go
package foo_test

import (
    . "foo"
    "bar/testutil"  // also imports "foo"
)
```

上の場合，`bar/testutil`が`foo`パッケージをインポートしているため，テストファイルは`foo`パッケージにはなれない．`.`形式で`foo`をインポートすると，このテストファイルが`foo`パッケージの一部であるかのように見なすことができる．ただし，このようなケースを除いて`.`形式のインポートは可読性が落ちるため使うべきではない．

- 通常の処理はなるべく浅いネストで記述すること．最初にエラー処理をネストして記述すること．これにより可読性が高まる．例えば，

```go
if err != nil {
    // エラー処理
} else {
    // 通常処理
}
```

のように書くのではなく，以下のようにする．

```go
if err != nil {
    // エラー処理
    return // or continue, etc.
}
// 通常処理       
```





