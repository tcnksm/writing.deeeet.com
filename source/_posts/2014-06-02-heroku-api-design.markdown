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

Provide the full resource representation (i.e. the object with all attributes) whenever possible in the response. Always provide the full resource on 200 and 201 responses, including PUT/PATCH and DELETE requests, e.g.:

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

202 responses will not include the full resource representation, e.g.:

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

Accept serialized JSON on PUT/PATCH/POST request bodies, either instead of or in addition to form-encoded data. This creates symmetry with JSON-serialized response bodies, e.g.:

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

パスの末尾に個々のリソースに対する特別なアクションが必要ないのが望ましいが，必要な場合は，以下のようにそれを`actions`の後に置く．

```
/resources/:resource/actions/:action
```

例えば，

```
/runs/{run_id}/actions/stop
```

### パスと要素名には小文字を使う

ホスト名に合わせて，パスは小文字かつ`-`を使う．例えば，

```
service-api.com/users
service-api.com/app-setups
```

同様に，Javascriptで使うことを考慮して，要素名には小文字かつ`_`を使う．例えば，

```javascript
"service_class": "first"
```

### 外部キーはネストする

外部キーによる一連の参照はネストして記述する．例えば，

```javascript
{
  "name": "service-production",
  "owner_id": "5d8201b0...",
  ...
}
```

とするのではなく，以下のようにする．

```javascript
{
  "name": "service-production",
  "owner": {
      "id": "5d8201b0..."
  },
  ...
}
```

こうすることで，レスポンスの構造を変更したり，トップレベルにフィールドを追加することなく，関連したリソースを追加することができる．

```javascript
{
  "name": "service-production",
  "owner": {
      "id": "5d8201b0...",
      "name": "Alice",
      "email": "alice@heroku.com"
  },
  ...
}
```

### ID以外の参照方法をサポートする

ユーザにとってリソースの特定にIDを使うのが不便な場合がある．例えば，ユーザは，HerokuアプリケーションをUUIDではなく，名前で見分けているかもしれない．このような場合，IDと名前の両方でアクセスできるとよい．例えば，

```bash
$ curl https://service.com/apps/{app_id_or_name}
$ curl https://service.com/apps/97addcf0-c182
$ curl https://service.com/apps/www-prod
```

ただし，IDを除き名前のみでアクセスできるようにするべきではない．

### 構造的なエラーを出力する

エラーの際は，一貫した構造的なレスポンスを生成すること．コンピュータが解釈しやすいエラー`id`と，人間が理解しやすいエラー`message`を含めること．さらに，エラーとその解決方法を示すより詳細な情報を示すための`url`をクライアントに示すとよい．例えば，

```
HTTP/1.1 429 Too Many Requests
```

```javascript
{
  "id":      "rate_limit",
  "message": "Account reached its API rate limit.",
  "url":     "https://docs.service.com/rate-limits"
}
```

エラーのフォーマットと，`id`のドキュメントを作成すること．

### Etagによるキャッシュをサポートする

Include an ETag header in all responses, identifying the specific version of the returned resource. The user should be able to check for staleness in their subsequent requests by supplying the value in the If-None-Match header.

### リクエストIDでリクエストを追跡する

Include a Request-Id header in each API response, populated with a UUID value. If both the server and client log these values, it will be helpful for tracing and debugging requests.

### レンジでPaginateする

Paginate with Ranges
Paginate any responses that are liable to produce large amounts of data. Use Content-Range headers to convey pagination requests. Follow the example of the Heroku Platform API on Ranges for the details of request and response headers, status codes, limits, ordering, and page-walking.

### 限定されたステータスの状態を示す

Rate limit requests from clients to protect the health of the service and maintain high service quality for other clients. You can use a token bucket algorithm to quantify request limits.

Return the remaining number of request tokens with each request in the RateLimit-Remaining response header.

### Acceptsヘッダーでバージョニングする

始めからAPIをバージョニングすること．`Accepts`ヘッダーを使ってバージョンを指定する．例えば，

```
Accept: application/vnd.heroku+json; version=3
```

クライアントに対して特定のバージョンを指定することを明示的に指示する代わりに，デフォルトのバージョンがあるのは好ましくない．

- [APIのバージョニングは限局分岐でやるのが良い](http://kenn.hatenablog.com/entry/2014/03/06/105249)
- [Rebuild: 35: You Don't Need API Version 2 (Kenn Ejima)](http://rebuild.fm/35/)

### パスのネストを最小限にする

ネストした親子関係をもつリソースのデータモデルでは，パスは深くネストすることになる．例えば，

```
/orgs/{org_id}/apps/{app_id}/dynos/{dyno_id}
```

ルートパスにリソースを配置するようにパスのネストの深さを制限すること．ネストを範囲をしぼった集合を示すために使うこと．例えば，上の例では，1つのdynoは1つのappに属し，1つのappは1つのorgに属する，

```
/orgs/{org_id}
/orgs/{org_id}/apps
/apps/{app_id}
/apps/{app_id}/dynos
/dynos/{dyno_id}
```

### コンピュータが読みやすいJSONスキーマを与える

正確にAPIについて明記するため，コンピュータが読みやすいJSONスキーマを与えること．[prmd](https://github.com/interagent/prmd)を使ってスキーマを管理し，`prmd varify`でそれを評価すること．

### 人間が読みやすいドキュメントを準備する

クライアントの開発者がAPIを理解できるように読みやすいドキュメントを準備すること．

[prmd](https://github.com/interagent/prmd)を使ってスキーマを作成したなら，`prmd doc`で簡単にmarkdown形式のドキュメントを生成できる．

これに加えて，以下のようなAPIの概要を準備すること．

- Authentication, including acquiring and using authentication tokens.
- API stability and versioning, including how to select the desired API version.
- Common request and response headers.
- Error serialization format.
- Examples of using the API with clients in different languages.

### 実行可能な実例を準備する

Provide executable examples that users can type directly into their terminals to seeworking API calls. To the greatest extent possible, these examples should be usable verbatim, to minimize the amount of work a user needs to do to try the API, e.g.:

```bash
$ export TOKEN=... # acquire from dashboard
$ curl -is https://$TOKEN@service.com/users
```

### 安定性を記述する

Describe the stability of your API or its various endpoints according to its maturity and stability, e.g. with prototype/development/production flags.

See the Heroku API compatibility policy for a possible stability and change management approach.

Once your API is declared production-ready and stable, do not make backwards incompatible changes within that API version. If you need to make backwards-incompatible changes, create a new API with an incremented version number.

### Require SSL

Require SSL to access the API, without exception. It’s not worth trying to figure out or explain when it is OK to use SSL and when it’s not. Just require SSL for everything.

### デフォルトでJSONをいい感じに出力する

The first time a user sees your API is likely to be at the command line, using curl. It’s much easier to understand API responses at the command-line if they are pretty-printed. For the convenience of these developers, pretty-print JSON responses, e.g.:

```javascript
{
  "beta": false,
  "email": "alice@heroku.com",
  "id": "01234567-89ab-cdef-0123-456789abcdef",
  "last_login": "2012-01-01T12:00:00Z",
  "created_at": "2012-01-01T12:00:00Z",
  "updated_at": "2012-01-01T12:00:00Z"
}
```

```javascript
{"beta":false,"email":"alice@heroku.com","id":"01234567-89ab-cdef-0123-456789abcdef","last_login":"2012-01-01T12:00:00Z", "created_at":"2012-01-01T12:00:00Z","updated_at":"2012-01-01T12:00:00Z"}
```

Be sure to include a trailing newline so that the user’s terminal prompt isn’t obstructed.

For most APIs it will be fine performance-wise to pretty-print responses all the time. You may consider for performance-sensitive APIs not pretty-printing certain endpoints (e.g. very high traffic ones) or not doing it for certain clients (e.g. ones known to be used by headless programs).


