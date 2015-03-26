#!/bin/sh

CVM_HOST=${1:-10.207.158.26}
CVM_PORT=${2:-22}

ssh -l app1101129079 -p $CVM_PORT $CVM_HOST -o 'ProxyCommand /usr/local/bin/corkscrew cvm-proxy.opencloud.qq.com 80 $CVM_HOST 36000'
