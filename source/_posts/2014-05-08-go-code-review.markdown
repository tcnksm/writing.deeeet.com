---
layout: post
title: 'Go言語のコードレビュー'
date: 2014-05-08 00:02
comments: true
categories: golang
---

SoundCloudが2.5年間ほどGo言語を本番で運用した知見を[GopherCon](http://www.gophercon.com/)で発表していた（["Go: Best Practices for Production Environments"](http://peter.bourgon.org/go-in-production/)）．その中で，GoogleのGo言語のコードレビューをまとめたサイトが紹介されていた．

[CodeReviewComments](https://code.google.com/p/go-wiki/wiki/CodeReviewComments#Import_Dot)

- [gofmt](http://golang.org/cmd/gofmt/)でコードの整形をすること．
- [コメント](http://golang.org/doc/effective_go.html#commentary)は文で書くこと．対象となる関数（変数）名で初めて，ピリオドで終わること．

```go
// A Request represents a request to run a command.
type Request struct { ...

// Encode writes the JSON encoding of req to w.
func Encode(w io.Writer, req *Request) { ...
```

- Doc Comments．All top-level, exported names should have doc comments, as should non-trivial unexported type or function declarations. See http://golang.org/doc/effective_go.html#commentary for more information about commentary conventions.
- 通常の[エラー処理](http://golang.org/doc/effective_go.html#errors)に`panic`を使わないこと．errorと複数の戻り値を使うこと．
- エラー文字列は通常は他で利用されることが多いので，固有名詞や頭字語でない限り，大文字で始めたり，句読点で終わったりしないこと．つまり，`fmt.Errorf("Something bad")`と大文字で始めるのではなく，`fmt.Errorf("something bad")`とすること．こうすれば，例えば，`log.Print("Reading %s: %v", filename, err)`としても，文の途中に大文字が入るようなことがなくなる．
- エラーの戻り値を`_`で捨てないこと．関数がエラーを返すなら，関数が成功したかをチェックすること．エラーハンドリングをして，どうしようもないときに`panic`とする．
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

- `.`を使ったパッケージのインポートはテストで使える．The import . form can be useful in tests that, due to circular dependencies, cannot be made part of the package being tested:．In this case, the test file cannot be in package foo because it uses bar/testutil, which imports foo. So we use the 'import .' form to let the file pretend to be part of package foo even though it is not. Except for this one case, do not use import . in your programs. It makes the programs much harder to read because it is unclear whether a name like Quux is a top-level identifier in the current package or in an imported package.

```go
package foo_test

import (
    . "foo"
        "bar/testutil"  // also imports "foo"
)
```

- 通常の処理はなるべく浅いネストで記述すること．最初にエラー処理をネストして記述すること．これにより可読性が高まる．例えば，

```go
if err != nil {
    // エラー処理
} else {
    // 通常処理
}
```

ではなく，以下のようにする．

```go
if err != nil {
    // エラー処理
    return // or continue, etc.
}
// 通常処理       
```






