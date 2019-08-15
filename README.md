UberEATS CHEAPER
====

## 概要
UberEATSで指定したお店の配送料が安くなったら教えてくれる通知アプリケーションです

## 詳細
Rubyツールです。

アクセス負荷がかからないくらいで5分おきにデータを取得し、安くなったかどうかを判断しています。

通知方法は`Slack`と`Mac OS`の2つに対応しています。

(他のサービス、`Windows`などは反響があれば作ろうかなと思います。)

html要素はcssセレクターで取得していますが、html構造が変わったらこの
ツールは使えなくなるかもしれません。ご了承くださいませ。

## デモ画像
<img src="https://github.com/nochiraaa/ubereats_cheaper/blob/master/sample-mac.png" width="500px">
<img src="https://github.com/nochiraaa/ubereats_cheaper/blob/master/sample-slack.png" width="500px">

## 必要なツール・ライブラリ
- Ruby(2.6.3)
- chrome webdriver(ChromeDriver 76.0.3809.68 (420c9498db8ce8fcd190a954d51297672c1515d5-refs/branch-heads/3809@{#864}))


## 使い方

`$ bundle exec ruby ubereats_cheaper.rb [通知方法] [郵便番号] [UberEATSのお店のURL] [希望配送手数料] [Slackのwebhook url オプション引数]`

- 引数1 通知方法
  - `mac`（デフォルト）・・・macの通知センターから通知を送ります。画面右上からぴょこっと出てきます。
  - `slack`・・・Slackの特定のチャンネルに通知を送ります。引数5にて`slack webhook url`が必要になります。

- 引数2 郵便番号
  - `[0-9]{6}`のフォーマットで入力してください。

- 引数3 UberEATSのお店のURL
  - ここにはお店の個別ページのURLを入力してください。
  - 例:https://www.ubereats.com/ja-JP/tokyo/food-delivery/%E3%82%B7-%E3%82%A2%E3%83%AC%E3%82%A4-%E6%B8%8B%E8%B0%B7246%E5%BA%97-the-alley-shibuya-246/C7X1V9lWQ5KIoPq7YYLc4A/

- 引数4 希望配送手数料
  - 数字を入力してください。ここで入力した数字よりも配送手数料が低くなったら通知がきます。

- 引数5 slackのwebhook url
  - [https://www.sejuku.net/blog/74471](https://www.sejuku.net/blog/74471)
  - こちらを参考に、webhook urlを取得してください。一応このwebhook urlは後々削除されるとのことなので、反響があれば後々新しい方に切り替えようと思います。


### コマンド例

`bundle exec ruby ubereats_cheaper.rb 'slack' 1070062 'https://www.ubereats.com/ja-JP/tokyo/food-delivery/%E3%82%B7-%E3%82%A2%E3%83%AC%E3%82%A4-%E6%B8%8B%E8%B0%B7246%E5%BA%97-the-alley-shibuya-246/C7X1V9lWQ5KIoPq7YYLc4A/' 1000 'https://hooks.slack.com/services/hoge1/hoge2/hoge3'`


なお、`bundle exec ruby ubereats_cheaper.rb`だけで実行すると、`mac`で、自分が最近よくいる`南青山`へ、大好きな`渋谷のジ アレイ（有名なタピオカミルクティーのお店）`の配送手数料が`1000円`（1000円より安くなることが割と少ない）よりも安くなった時に通知が来るようになっています。


## インストール

1. このリポジトリをcloneしてください

`$ git clone git@github.com:nochiraaa/ubereats_cheaper.git`

2. `$ bundle install`を実行

3. Chromeドライバをインストール。以下のURLより取得できます。

[https://sites.google.com/a/chromium.org/chromedriver/downloads](https://sites.google.com/a/chromium.org/chromedriver/downloads)


もしくはHomebrewを使っている方は下記でもインストールができます。

`$ brew install chromedriver`

`Homebrew`が入っていない方はこちらから

[http://brew.sh/index_ja.html](http://brew.sh/index_ja.html)


Chromeドライバのバージョンは最新のものであれば問題なく動くと思います。

動作確認は`ChromeDriver 76.0.3809.68 (420c9498db8ce8fcd190a954d51297672c1515d5-refs/branch-heads/3809@{#864})`で行っています。


## コントリビューション
ご自由にどうぞ

## ライセンス

[MIT](https://github.com/nochiraaa/ubereats_cheaper/blob/master/LICENSE.txt)

## 著者

[nochiraaa](https://github.com/nochiraaa)
