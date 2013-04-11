#!/bin/bash
DAT_DIR=$(cd `dirname $0`;pwd)
cd $DAT_DIR
echo "get 1355062957.dat"
wget 'http://ex14.vip2ch.com/news4ssnip/kako/1355/13550/1355062957.dat' || {
  echo '  Fail to download!'
  exit 1
}
echo "get 1358944586.dat"
wget 'http://ex14.vip2ch.com/news4ssnip/kako/1358/13589/1358944586.dat' || {
  echo '  Fail to download!'
  exit 1
}
echo "get 1283691129.dat"
wget 'http://ex14.vip2ch.com/news4ssnip/kako/1283/12836/1283691129.dat' || {
  echo '  Fail to download!'
  exit 1
}

