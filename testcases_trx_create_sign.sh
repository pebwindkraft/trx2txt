#!/bin/sh
# some testcases for the shell script "trx_create_sign.sh" 
#
# Copyright (c) 2015, 2016 Volker Nowarra 
# Complete rewrite in Nov/Dec 2015 
# 
# Permission to use, copy, modify, and distribute this software for any 
# purpose with or without fee is hereby granted, provided that the above 
# copyright notice and this permission notice appear in all copies. 
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES 
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF 
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY 
# SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER 
# RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, 
# NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE 
# USE OR PERFORMANCE OF THIS SOFTWARE. 
# 

typeset -i LOG=0
logfile=$0.log

chksum_verify() {
if [ "$1" == "$2" ] ; then
  echo "ok"
else
  echo $1 | tee -a $logfile
  echo "********************* checksum  mismatch: **********************" | tee -a $logfile
  echo $2 | tee -a $logfile
  echo " " | tee -a $logfile
fi
}

to_logfile() {
  echo $chksum_ref >> $logfile
  cat tmpfile >> $logfile
  echo "================================================================" >> $logfile
  echo " " | tee -a $logfile
}

chksum_prep() {
result=$( $chksum_cmd tmpfile | cut -d " " -f 2 )
# echo $result | cut -d " " -f 2 >> $logfile
chksum_verify "$result" "$chksum_ref" 
if [ $LOG -eq 1 ] ; then to_logfile ; fi
}

testcase1() {
# first get the checksums of all necessary files
echo "#############################################################" | tee -a $logfile
echo "### TESTCASE 1:                                           ###" | tee -a $logfile
echo "#############################################################" | tee -a $logfile
echo "###  first get the checksums of all necessary files       ###" >> $logfile
echo "#############################################################" >> $logfile
# based on: http://bitcoin.stackexchange.com/questions/3374/how-to-redeem-a-basic-tx

echo "TESTCASE 1a: $chksum_cmd trx_create_sign.sh" | tee -a $logfile
chksum_ref="1af82c2c2c276a42322c1f2e03166b24dc7bd6781841f702c775199a927d8752" 
cp trx_create_sign.sh tmpfile
chksum_prep

echo "TESTCASE 1b: $chksum_cmd trx_key2pem.sh" | tee -a $logfile
chksum_ref="56a38f616f94edd8c6c10360fa05466ec0265b6ef5746c5f1e35d622bace967e" 
cp trx_key2pem.sh tmpfile
chksum_prep

echo "TESTCASE 1c: $chksum_cmd trx_verify_bc_address.awk" | tee -a $logfile
chksum_ref="400057c2073db19e4b47cd31796bbfbfc492c82ca2acda75df030a30a39a622b" 
cp trx_verify_bc_address.awk tmpfile
chksum_prep

echo "TESTCASE 1d: $chksum_cmd trx_verify_hexkey.awk" | tee -a $logfile
chksum_ref="055b79074a8f33d0aa9aa7634980d29f4e3eb0248a730ea784c7a88e64aa7cfd" 
cp trx_verify_hexkey.awk tmpfile
chksum_prep

echo "TESTCASE 1e: $chksum_cmd trx_base58.awk" | tee -a $logfile
chksum_ref="eb7e79feeba3f1181291ce39620d93b1b8cf807cdfbe911b42e1d6cdbfecfbdc" 
cp trx_base58.awk tmpfile
chksum_prep

echo " " | tee -a $logfile
}


testcase2() {
# do a testcase with the included example transaction
echo "#############################################################" | tee -a $logfile
echo "### TESTCASE 2:                                           ###" | tee -a $logfile
echo "#############################################################" | tee -a $logfile
echo "###  manually create a trx and sign it afterwards         ###" >> $logfile
echo "#############################################################" >> $logfile

echo "TESTCASE 2a: ./trx_create_sign.sh -c -v -m ..." | tee -a $logfile
chksum_ref="d59adf9c7c90b7fd49d3b5b6c7f5177a4cc766a6590d4cb2b5181f18958c60bc" 
./trx_create_sign.sh -c -v -m F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmpfile
chksum_prep

echo "TESTCASE 2b: ./trx_create_sign.sh -vv -s -u ..." | tee -a $logfile
chksum_ref="b641f10713408fe424ef812c714caef4be9fce09810d90d9a030880b4200fb33" 
./trx_create_sign.sh -vv -s -u 0100000001ECCF7E3034189B851985D871F91384B8EE357CD47C3024736E5676EB2DEBB3F2010000001976a914010966776006953d5567439e5e39f86a0d273bee88acffffffff01605AF405000000001976A914097072524438D003D23A2F23EDB65AAE1BB3E46988AC0000000001000000 -x 18E14A7B6A307F426A94F8114701E7C8E774E7F9A47E2C2035DB29A206321725 -p 0450863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b23522cd470243453a299fa9e77237716103abc11a1df38855ed6f2ee187e9c582ba6 > tmpfile1 
# the signatures are changing everytime, so only use first set of lines ...
cat tmpfile1 | head -n 36 > tmpfile
chksum_prep
echo " " | tee -a $logfile
}

testcase3() {
# this is a fairly simple trx, 1 input, 1 output
echo "#############################################################" | tee -a $logfile
echo "### TESTCASE 3:                                           ###" | tee -a $logfile
echo "#############################################################" | tee -a $logfile
echo "###  same as testcase 2... slightly different parameters  ###" >> $logfile
echo "#############################################################" >> $logfile
# based on: http://www.cryptosys.net/pki/ecc-bitcoin-raw-transaction.html

echo "TESTCASE 3a: ./trx_create_sign.sh -c -v -m " | tee -a $logfile
chksum_ref="f24f418e7eb7e77a3bfb1e0915774b2385dbcf6adb6f812fddb851e4379fdd64" 
./trx_create_sign.sh -c -v -m 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac 118307 14zWNsgUMmHhYx4suzc2tZD6HieGbkQi5s > tmpfile
chksum_prep

echo "TESTCASE 3b: ./trx_create_sign.sh -s -vv -u " | tee -a $logfile
chksum_ref="9f3bb3c01d57a2ad56d5f39cd7982fa5eb27ce4118074dc6ee4a1e42bd95b81a" 
./trx_create_sign.sh -s -vv -u 0100000001be66e10da854e7aea9338c1f91cd489768d1d6d7189f586d7a3613f2a24d5396000000001976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88acffffffff0123CE0100000000001976A9142BC89C2702E0E618DB7D59EB5CE2F0F147B4075488AC0000000001000000 -x 0ecd20654c2e2be708495853e8da35c664247040c00bd10b9b13e5e86e6a808d -p 042daa93315eebbe2cb9b5c3505df4c6fb6caca8b756786098567550d4820c09db988fe9997d049d687292f815ccd6e7fb5c1b1a91137999818d17c73d0f80aef9 > tmpfile1
# the signatures are changing everytime, so only use first set of lines ...
cat tmpfile1 | head -n 36 > tmpfile
chksum_prep
echo " " | tee -a $logfile
}


testcase4() {
# this is a fairly simple trx, 1 input, 1 output
echo "#############################################################" | tee -a $logfile
echo "### TESTCASE 4:                                           ###" | tee -a $logfile
echo "#############################################################" | tee -a $logfile
echo "###  same as testcase 2... slightly different parameters  ###" >> $logfile
echo "### 4a has an invalid bitcoin adress (x at the end)       ###" >> $logfile
echo "### 4b is corrected, should work seamlessly               ###" >> $logfile
echo "### 4c is the signing process.                            ###" >> $logfile
echo "#############################################################" >> $logfile
# based on: http://www.cryptosys.net/pki/ecc-bitcoin-raw-transaction.html

echo "TESTCASE 4a: ./trx_create_sign.sh -vv -c -m " | tee -a $logfile
chksum_ref="124328d513d107d47341d65b0877692e64f49e94f2eb30650de27875e947cc26" 
./trx_create_sign.sh -vv -c -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdx > tmpfile
chksum_prep

echo "TESTCASE 4b: ./trx_create_sign.sh -vv -c -m " | tee -a $logfile
chksum_ref="844c6761899cf3ae01f40a4f50f5bf5831604776bebcd98e2c3ab29cb7b2c969" 
./trx_create_sign.sh -vv -c -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmpfile
chksum_prep

echo "TESTCASE 4c: ./trx_create_sign.sh -vv -s -u " | tee -a $logfile
chksum_ref="6d4df9db7ef4d263eddd4784ec428885e813a2caa24de91221e16a8624207f5e" 
./trx_create_sign.sh -vv -s -u 0100000001f93853272363d3099254b85c2cdabc8036c392d1b47b41e35859132c7cfd2374010000001976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988acffffffff01A0860100000000001976A914DE4457D577BB45DEE513BB695BDFDC3B34D467DD88AC0000000001000000 -w Kwrg58xptD7X8peGUNH4KTt8Qy8wtwfftMnBVPVZbNMzn4jtwCSa -p 0293CCB70FEE4D33179C93BADE0A9FEFD62FDE5AC53ADC017649F513EEC599509C > tmpfile1
cat tmpfile1 | head -n 36 > tmpfile
chksum_prep
echo " " | tee -a $logfile
}

testcase5() {
# this is a fairly simple trx, 1 input, 1 output
echo "#############################################################" | tee -a $logfile
echo "### TESTCASE 5:                                           ###" | tee -a $logfile
echo "#############################################################" | tee -a $logfile
echo "### same as testcase 2... but my own trx :-)              ###" >> $logfile
echo "#############################################################" >> $logfile

echo "TESTCASE 5a: ./trx_create_sign.sh -c -v -m " | tee -a $logfile
chksum_ref="6b2070c48505f8674d7eed402628870a90d5799babcb3f010bc336de6b815570" 
./trx_create_sign.sh -vv -c -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1090000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmpfile
chksum_prep
echo " " | tee -a $logfile
}


all_testcases() {
  testcase1 
  testcase2 
  testcase3 
  testcase4 
  testcase5 
}

#####################
### here we start ###
#####################
logfile=$0.log
if [ -f "$logfile" ] ; then rm $logfile; fi
echo $date > $logfile

###################################################################
# verify our operating system, cause checksum commands differ ... #
###################################################################
OS=$(uname) 
if [ OS="OpenBSD" ] ; then
  chksum_cmd=sha256
fi
if [ OS="Linux" ] ; then
  chksum_cmd="openssl sha256"
fi
if [ OS="Darwin" ] ; then
  chksum_cmd="openssl sha256"
fi

################################
# command line params handling #
################################

if [ $# -eq 0 ] ; then
  all_testcases
fi

if [ $# -eq 1 ] && [ "$1" == "-l" ] ; then
  LOG=1
  shift
  all_testcases
fi

while [ $# -ge 1 ] 
 do
  case "$1" in
  -h)
     echo "usage: $0 -h|-l [1-9]"
     echo "  "
     echo "script does several testcases, mostly with checksums for verification"
     echo "  "
     exit 0
     ;;
  -l)
     LOG=1
     shift
     ;;
  1|2|3|4|5|6|7|8|9)
     testcase$1 
     shift
     ;;
  *)
     echo "unknown parameter(s), try -h, exiting gracefully ..."
     exit 0
     ;;
  esac
done

# clean up
for i in tmp*; do
  if [ -f "$i" ]; then rm $i ; fi
done
for i in *hex; do
  if [ -f "$i" ]; then rm $i ; fi
done
for i in *pem; do
  if [ -f "$i" ]; then rm $i ; fi
done

