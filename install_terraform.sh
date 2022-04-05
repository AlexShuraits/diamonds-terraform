#!/usr/bin/env bash
ostype=""
tf_version="1.1.7"

case $OSTYPE in
  "linux-gnu")
    ostype="linux"
    ;;
  "darwin"*)
    ostype="darwin"
    ;;
  *)
    echo "Unsupported platform $OSTYPE"
    exit 1
esac

if [ ! -f ./terraform ]; then
    url="https://releases.hashicorp.com/terraform/${tf_version}/terraform_${tf_version}_${ostype}_amd64.zip"
    curl -sS $url > terraform.zip
    unzip -o terraform.zip
    rm terraform.zip
fi

./terraform init
