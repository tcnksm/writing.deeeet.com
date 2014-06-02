---
layout: post
title: 'HerokuのAPIデザイン'
date: 2014-06-02 22:20
comments: true
categories: 
---

Herokuが[実践している](https://devcenter.heroku.com/articles/platform-api-reference)APIのデザインをGithubで公開した．

["HTTP API Design Guide"](https://github.com/interagent/http-api-design#provide-machine-readable-json-schema)

この目的は些細なデザイン上の議論を避けて，ビジネスロジックに集中することを目的にしている．


### 適切なステータスコードを返す

それぞれのレスポンスには適切なHTTPステータスコードを返すこと．例えば，成功を示すステータスコードは以下に従う．

- `200`: `GET`や`DELETE`，`PATCH`のリクエストが成功し，処理が完了した場合
- `201`: `POST`のリクエストが成功し，処理が完了した場合
- `202`: `POST`や`DELETE`，`PATCH`のリクエスト成功したが，処理は完了していない場合
- `206`: `GET`のリクエストは成功したが，レスポンスがリソースに対して部分的である場合

詳しくは，[RFC 2616](http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html)を参照．

### 可能なリソースを全て返す


```bash
$ curl -X DELETE \
  https://service.com/apps/1f9b/domains/0fd4
```

```javascript
HTTP/1.1 200 OK
Content-Type: application/json;charset=utf-8
...
{
  "created_at": "2012-01-01T12:00:00Z",
  "hostname": "subdomain.example.com",
  "id": "01234567-89ab-cdef-0123-456789abcdef",
  "updated_at": "2012-01-01T12:00:00Z"
}
```

```bash
$ curl -X DELETE \
  https://service.com/apps/1f9b/dynos/05bd
```

```javascript
HTTP/1.1 202 Accepted
Content-Type: application/json;charset=utf-8
...
{}
```

### リクエストボディのシリアライズされたJSONを受け入れる

```bash
$ curl -X POST https://service.com/apps \
    -H "Content-Type: application/json" \
    -d '{"name": "demoapp"}'    
```

```javascript
{
  "id": "01234567-89ab-cdef-0123-456789abcdef",
  "name": "demoapp",
  "owner": {
      "email": "username@example.com",
      "id": "01234567-89ab-cdef-0123-456789abcdef"
  },
  ...
}
```

### リソースの(UU)IDを与える

それぞれのリソースにデフォルトでid要素を与えること．特別な理由がない限りUUIDを使うこと．サービスの他のリソースの中で一意でないIDを使わないこと．

小文字で`8-4-4-4-12`フォーマットを使うこと．例えば，

```javascript
"id": "01234567-89ab-cdef-0123-456789abcdef"
```

### タイムスタンプを与える

`created_at`と`updated_at`のタイムスタンプをデフォルトで与えること．例えば，

```javascript
{
  ...
  "created_at": "2012-01-01T12:00:00Z",
  "updated_at": "2012-01-01T13:00:00Z",
  ...
}
```

### 時刻はISO8601表記のUTCを使う

時刻はUTCのみを返答する，もしくは受け入れること．[ISO 8601](http://ja.wikipedia.org/wiki/ISO_8601)のフォーマットを用いること．例えば，

```javascript
"finished_at": "2012-01-01T12:00:00Z"
```

### 一貫したパス名を使う

リソースの名前には複数形を使う．ただし，リソースがシステム全体でシングルトンである場合は，単数形を使う（例えば，ほとんどのシステムではユーザはただ1つのアカウントをのみを持つ）．これにより，特定のリソースへの参照に一貫性を持たせることができる．

パスの末尾に個々のリソースに対する特別なアクションが必要ないのが望ましい．特別なアクションが必要な場合は，以下のようにそれを`actions`の後に置く．

```
/resources/:resource/actions/:action
```

例えば，

```
/runs/{run_id}/actions/stop
```




