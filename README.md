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

- Create a config file and override default config
  - see `src/default_config.sh`
- Run command below
```
rstart config.sh
```
