# What is remote_builer

アプリケーションのビルドやメディアファイルのエンコード等、ローカルPCでは時間のかかるタスクを、クラウド上のマシンに丸投げし、短時間で完了させることを目的とするコマンドラインツールです。プリエンプティブインスタンスを使うことで、低価格で任意のスペックのマシンを利用することができます。

# Features

- Google Cloud Platform の GCE インスタンスの構築
  - ファイアウォールの自動設定
- ローカルで変更のあったファイルを自動的に同期
- インスタンス構築時、起動時、ファイル転送時をトリガーとした任意の処理差し込み

# Pre-requisites

- Google Account
- 下記の権限を持っている GCP Project
  - GCE Instance の参照・作成
  - Firewall の参照・作成
- commands
  - gcloud (Google Cloud SDK)
  - docker-machine
  - watchmedo
  - bash ( >= 4.0)
  - rsync ( >= 3.0)

# Install

```
git clone git@github.com:tomoemon/remote_builder.git

echo "PATH=$(cd remote_builder/bin; pwd):\$PATH">>~/.bashrc
```


# Usage

1. `template_config` 内のテンプレート設定ファイルをコピーして設定ファイルを作成

    cp remote_builder/template_config/dev_appserver.sh config.sh
    # edit config.sh
    
2. コマンドを実行

    rstart config.sh
