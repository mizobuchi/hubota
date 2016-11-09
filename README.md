# hubota

内定者のサポートを行います

hubotaはHubot製のボットです．
あるサイトの更新をお知らせするために生まれました．

# 機能

Webページを指定された間隔で確認し，更新があればお知らせします．

Webページは確認にログインが必要という前提です．

通知はIFTTTを通して行われます．

監視したいページの要素を指定し，その部分だけ比較を行います．

# 設定

`data/community.json`に設定ファイルを置きます．`data/community.json.sample`を利用していただくと良いかもしれません．

項目は以下のとおりです．

| key | 説明 |
| --- | --- |
| `url` | アクセス先のURL |
| `id` | ログインID |
| `id_form_name` | ログインIDを入力するinput要素のname |
| `password` | ログインパスワード |
| `password_form_name` | ログインパスワードを入力するinput要素のname |
| `cron_time` | 確認時間指定 書き方はhttps://github.com/kelektiv/node-cronを参照 |
| `pages.name` | ページ名（更新があった場合，これが送信されます） |
| `pages.url` | 確認したいページのURL |
| `pages.id` | 上のページの中で確認する要素のid(このid以外の箇所が更新されても通知しません) |
| `ifttt_event` | 通知するiftttのeventの名前 |
| `ifttt_key` | iftttのkey |
