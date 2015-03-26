#!/bin/sh

CVM_HOST=${1:-10.207.158.26}
DST=${2:-trps}

rsync \
    -racvz \
    -e "ssh -o 'ProxyCommand /usr/local/bin/corkscrew cvm-proxy.opencloud.qq.com 80 $CVM_HOST 36000'" \
    --exclude dev/ \
    --exclude rel/trps \
    ./* app1101129079@$CVM_HOST:~/$DST
