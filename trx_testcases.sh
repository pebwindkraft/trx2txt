#!/bin/sh
# some testcases for the shell script "trx2txt.sh" 
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
  echo "*********************   checksum  mismatch   ********************" 
fi
}

testcase1() {
# first get the checksums of all necessary files
echo "#################################################################" | tee -a $logfile
echo "### TESTCASE 1:                                               ###" | tee -a $logfile
echo "#################################################################" | tee -a $logfile
echo "###  first get the checksums of all necessary files           ###" >> $logfile
echo "#################################################################" >> $logfile

echo "TESTCASE 1a: $chksum_cmd trx2txt.sh" | tee -a $logfile
result=$( $chksum_cmd trx2txt.sh )
echo $result | tee -a $logfile
chksum_verify "$result" "SHA256(trx2txt.sh)= f9edb381ef544c5a2032f46964973716eb174d4a6428c569c3b20fd7c6a8ffd9" 

echo "TESTCASE 1b: $chksum_cmd trx_in_sig_script.sh" | tee -a $logfile
result=$( $chksum_cmd trx_in_sig_script.sh )
echo $result | tee -a $logfile
chksum_verify "$result" "SHA256(trx_in_sig_script.sh)= 5b384370a619031d8c809024b483d7fad7f49ac30cd8cf8273780ee3a7e12bb9"

echo "TESTCASE 1c: $chksum_cmd trx_out_pk_script.sh" | tee -a $logfile
result=$( $chksum_cmd trx_out_pk_script.sh )
echo $result | tee -a $logfile
chksum_verify "$result" "SHA256(trx_out_pk_script.sh)= 6382edca728971c043a72e2383b4276963691fdbe6e13514756db660e83a196c" 

echo "TESTCASE 1d: $chksum_cmd base58check_enc.sh" | tee -a $logfile
result=$( $chksum_cmd base58check_enc.sh )
echo $result | tee -a $logfile
chksum_verify "$result" "SHA256(base58check_enc.sh)= 995a68c23f7b6499a06d9075c61ac4269e73ce7e1e168352a0d5fd63611f2ef3" 

echo " " | tee -a $logfile
}

testcase2() {
# do a testcase with the included example transaction
echo "#################################################################" | tee -a $logfile
echo "### TESTCASE 2:                                               ###" | tee -a $logfile
echo "#################################################################" | tee -a $logfile
echo "###  do a testcase with the parameters set incorrectly, and   ###" >> $logfile
echo "###  at the end 3 correct settings. This just serves to       ###" >> $logfile
echo "###  verify, that code is executing properly                  ###" >> $logfile
echo "#################################################################" >> $logfile

echo "TESTCASE 2a: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  echo "This call should fail, cause xyz is unknown" | tee -a $logfile
  ./trx2txt.sh xyz >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh xyz > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= b13c815429e3050d5180bafb727fc37459d4d8a161ee25edd38853a95e23af4c" 

echo "TESTCASE 2b: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  echo "This call should fail, cause -r has no params " | tee -a $logfile
  ./trx2txt.sh -r >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -r > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= 4ac9c1c48b82bc59dfb775becfa075c41c0455c61b14fc107316701f7c7bd96a"

echo "TESTCASE 2c: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  echo "This call should fail, cause -t has no params " | tee -a $logfile
  ./trx2txt.sh -t >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -t > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= 67f89326ba5c1f12b69e12a9723cf176056655fcdb3aca720b11e941b7db5b25" 

echo "TESTCASE 2d: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  echo "This call should fail, cause -r and -t is used " | tee -a $logfile
  ./trx2txt.sh -r abc -t def >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -r abc -t def > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= b731a7ba9c31267193df6ddb0cb4f3e3f415dc3adbb809546961a0396f3480da" 

echo "TESTCASE 2e: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  echo "This call should fail, cause param to -t is too short " | tee -a $logfile
  ./trx2txt.sh -t abc >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -t abc > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= bc63cf89cb676c08f7025e09c81b81ac7c379f37b2f4ac5a7b02bb114a760276" 

echo "TESTCASE 2f: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  echo "This call should fail, cause param 'abc' is unknown " | tee -a $logfile
  ./trx2txt.sh -v abc >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -v abc > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= 3820f5b533a152e796007b884d7cc06f3fa68f8904f00578e80abae45039b1e1" 

echo "TESTCASE 2g: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  echo "This call should simply display the help text " | tee -a $logfile
  ./trx2txt.sh -h >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -h > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= f385045dd410711e4796b776b57653b3808c762660b5d13c90bab1c1c3d581c8" 

echo "TESTCASE 2h: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= d3404a67668acc8d2045e44a3b95a9ed519648c157d734953cbfeb1116d98fdc" 

echo "TESTCASE 2i: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh -v >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -v > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= e6ac2c9bc6b3e40541a1a3ddd5984220e6aa98ac4c24cc1271ca64ec3d3ae1d2" 

echo "TESTCASE 2j: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh -vv >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -vv > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= 0fcc3cb01aad378b299072550db26990a5ebbe3f621107be8064b96d979a2e39" 
echo " " | tee -a $logfile
}

testcase3() {
# this is a fairly simple trx, 1 input, 1 output
echo "#################################################################" | tee -a $logfile
echo "### TESTCASE 3:                                               ###" | tee -a $logfile
echo "#################################################################" | tee -a $logfile
echo "###  we check functionality to load data via -t parameter     ###" >> $logfile
echo "###  from https://blockcahin.info ...                         ###" >> $logfile
echo "###  this is a fairly simple trx, 1 input, 1 output           ###" >> $logfile
echo "#################################################################" >> $logfile
echo "https://blockchain.info/de/rawtx/30375f40adcf361f5b2a5074b615ca75e5696909e8bc2f8e553c69631826fcf6" >> $logfile

echo "TESTCASE 3a: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh -t 30375f40adcf361f5b2a5074b615ca75e5696909e8bc2f8e553c69631826fcf6 >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -t 30375f40adcf361f5b2a5074b615ca75e5696909e8bc2f8e553c69631826fcf6 > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= b2fb4ac4d0c7d9b10695003ba4246d5e92773449b2cea6ad8ef66bc84dcead8f" 

echo "TESTCASE 3b: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh -v -t 30375f40adcf361f5b2a5074b615ca75e5696909e8bc2f8e553c69631826fcf6 >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -v -t 30375f40adcf361f5b2a5074b615ca75e5696909e8bc2f8e553c69631826fcf6 > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= a9011157769d19db63d994ebb05af78cc7d8671448637f1bc8305ac2eed052de"

echo "TESTCASE 3c: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh -vv -t 30375f40adcf361f5b2a5074b615ca75e5696909e8bc2f8e553c69631826fcf6 >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -vv -t 30375f40adcf361f5b2a5074b615ca75e5696909e8bc2f8e553c69631826fcf6 > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= 22319b3ff988da419a28a6f8964d7a696c6381eee880a125d0b84ecfd463ae20"
echo " " | tee -a $logfile
}

testcase4() {
# this is a fairly simple trx, 1 input, 2 outputs
echo "#################################################################" | tee -a $logfile
echo "### TESTCASE 4:                                               ###" | tee -a $logfile
echo "#################################################################" | tee -a $logfile
echo "###  this is a fairly simple trx, 1 input, 2 outputs          ###" >> $logfile
echo "#################################################################" >> $logfile
echo "https://blockchain.info/de/rawtx/91c91f31b7586b807d0ddc7a1670d10cc34bdef326affc945d4987704c7eed62" >> $logfile

echo "TESTCASE 4a: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh -r 010000000117f83daeec34cca28b90390b691d278f658b85b20fae29983acda10273cc7d32010000006b483045022100b95be9ab9148d85d47d51d069923272ad5131505b40b8e27211475305c546c6e02202ae8f2386e0d7afa6ab0acfafa78b0e23e669972d6e656b345b69c6d268aecbd0121020b2b582ca9333957cf8457a4a1b46e5337471cc98582fdf37c58a201dba50dd2feffffff0210201600000000001976a91407ddfbe06b04f3867cae654448174ea2f9a173ea88acda924700000000001976a9143940dcd0bfb7ad9bff322405954949c450742cd588accd3d0600 >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -r 010000000117f83daeec34cca28b90390b691d278f658b85b20fae29983acda10273cc7d32010000006b483045022100b95be9ab9148d85d47d51d069923272ad5131505b40b8e27211475305c546c6e02202ae8f2386e0d7afa6ab0acfafa78b0e23e669972d6e656b345b69c6d268aecbd0121020b2b582ca9333957cf8457a4a1b46e5337471cc98582fdf37c58a201dba50dd2feffffff0210201600000000001976a91407ddfbe06b04f3867cae654448174ea2f9a173ea88acda924700000000001976a9143940dcd0bfb7ad9bff322405954949c450742cd588accd3d0600 > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= 75d4a1aa8c114a11ad73d894f01f893713b771ba5114e686d2b92c77eeeeb715"

echo "TESTCASE 4b: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh -v -r 010000000117f83daeec34cca28b90390b691d278f658b85b20fae29983acda10273cc7d32010000006b483045022100b95be9ab9148d85d47d51d069923272ad5131505b40b8e27211475305c546c6e02202ae8f2386e0d7afa6ab0acfafa78b0e23e669972d6e656b345b69c6d268aecbd0121020b2b582ca9333957cf8457a4a1b46e5337471cc98582fdf37c58a201dba50dd2feffffff0210201600000000001976a91407ddfbe06b04f3867cae654448174ea2f9a173ea88acda924700000000001976a9143940dcd0bfb7ad9bff322405954949c450742cd588accd3d0600 >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -v -r 010000000117f83daeec34cca28b90390b691d278f658b85b20fae29983acda10273cc7d32010000006b483045022100b95be9ab9148d85d47d51d069923272ad5131505b40b8e27211475305c546c6e02202ae8f2386e0d7afa6ab0acfafa78b0e23e669972d6e656b345b69c6d268aecbd0121020b2b582ca9333957cf8457a4a1b46e5337471cc98582fdf37c58a201dba50dd2feffffff0210201600000000001976a91407ddfbe06b04f3867cae654448174ea2f9a173ea88acda924700000000001976a9143940dcd0bfb7ad9bff322405954949c450742cd588accd3d0600 > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= cd6df91d6fd4c04c10f7e48163b1650fbaeda056b655fa80f42c1f205c37a15b"

echo "TESTCASE 4c: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh -vv -r 010000000117f83daeec34cca28b90390b691d278f658b85b20fae29983acda10273cc7d32010000006b483045022100b95be9ab9148d85d47d51d069923272ad5131505b40b8e27211475305c546c6e02202ae8f2386e0d7afa6ab0acfafa78b0e23e669972d6e656b345b69c6d268aecbd0121020b2b582ca9333957cf8457a4a1b46e5337471cc98582fdf37c58a201dba50dd2feffffff0210201600000000001976a91407ddfbe06b04f3867cae654448174ea2f9a173ea88acda924700000000001976a9143940dcd0bfb7ad9bff322405954949c450742cd588accd3d0600 >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -vv -r 010000000117f83daeec34cca28b90390b691d278f658b85b20fae29983acda10273cc7d32010000006b483045022100b95be9ab9148d85d47d51d069923272ad5131505b40b8e27211475305c546c6e02202ae8f2386e0d7afa6ab0acfafa78b0e23e669972d6e656b345b69c6d268aecbd0121020b2b582ca9333957cf8457a4a1b46e5337471cc98582fdf37c58a201dba50dd2feffffff0210201600000000001976a91407ddfbe06b04f3867cae654448174ea2f9a173ea88acda924700000000001976a9143940dcd0bfb7ad9bff322405954949c450742cd588accd3d0600 > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= daef4a4649bae1ad856845d34a5cb27b7803080cdd58a7bab0ec99d1492e6bcb"
echo " " | tee -a $logfile
}

testcase5() {
# this is a fairly simple trx, 3 inputs, 1 output 
echo "#################################################################" | tee -a $logfile
echo "### TESTCASE 5:                                               ###" | tee -a $logfile
echo "#################################################################" | tee -a $logfile
echo "###  this is a fairly simple trx, 3 inputs, 1 P2SH output     ###" >> $logfile
echo "#################################################################" >> $logfile
echo "https://blockchain.info/de/rawtx/4f292aeff2ad2da37b5d5719bf34846938cf96ea7e75c8715bc3edac01b39589" >> $logfile

echo "TESTCASE 5a: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh -r 010000000301de569ae0b3d49dff80f79f7953f87f17f61ca1f6d523e815a58e2b8863d098000000006a47304402203930d1ba339c9692367ae37836b1f21c1431ecb4522e7ce0caa356b9813722dc02204086f7ad81d5d656ab1b6d0fd4709b5759c22c44a0aeb1969c1cdb7c463912fa012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffff97e60e0bec78cf5114238678f0b5eab617ca770752796b4c795c9d3ada772da5000000006a473044022046412e2b3f820f846a5e8f1cc92529cb694cf0d09d35cf0b5128cc7b9bf32a0802207f736b322727babd41793aeedfad41cc0541c0a1693e88b2a620bcd664da8551012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffffce559734242e6a6e0608caa07ee1178d5b9e53e0814d61f002930d78422e8402000000006b4830450221009fab428713fa76057e1bd87381614abc270089ddb23c345b0a56114db0fb8fd30220187a80bedfbb6b23bcf4eaf25017be2efdd64f02a732be9f4846142ad3408798012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffff011005d0010000000017a91469545b58fd41a120da3f606be313e061ea818edf8700000000 >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -r 010000000301de569ae0b3d49dff80f79f7953f87f17f61ca1f6d523e815a58e2b8863d098000000006a47304402203930d1ba339c9692367ae37836b1f21c1431ecb4522e7ce0caa356b9813722dc02204086f7ad81d5d656ab1b6d0fd4709b5759c22c44a0aeb1969c1cdb7c463912fa012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffff97e60e0bec78cf5114238678f0b5eab617ca770752796b4c795c9d3ada772da5000000006a473044022046412e2b3f820f846a5e8f1cc92529cb694cf0d09d35cf0b5128cc7b9bf32a0802207f736b322727babd41793aeedfad41cc0541c0a1693e88b2a620bcd664da8551012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffffce559734242e6a6e0608caa07ee1178d5b9e53e0814d61f002930d78422e8402000000006b4830450221009fab428713fa76057e1bd87381614abc270089ddb23c345b0a56114db0fb8fd30220187a80bedfbb6b23bcf4eaf25017be2efdd64f02a732be9f4846142ad3408798012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffff011005d0010000000017a91469545b58fd41a120da3f606be313e061ea818edf8700000000 > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= 556aab489ea821be120af54320810b11ff7580214eec1c6bcb7c9713cd5993b7"

echo "TESTCASE 5b: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh -v -r 010000000301de569ae0b3d49dff80f79f7953f87f17f61ca1f6d523e815a58e2b8863d098000000006a47304402203930d1ba339c9692367ae37836b1f21c1431ecb4522e7ce0caa356b9813722dc02204086f7ad81d5d656ab1b6d0fd4709b5759c22c44a0aeb1969c1cdb7c463912fa012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffff97e60e0bec78cf5114238678f0b5eab617ca770752796b4c795c9d3ada772da5000000006a473044022046412e2b3f820f846a5e8f1cc92529cb694cf0d09d35cf0b5128cc7b9bf32a0802207f736b322727babd41793aeedfad41cc0541c0a1693e88b2a620bcd664da8551012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffffce559734242e6a6e0608caa07ee1178d5b9e53e0814d61f002930d78422e8402000000006b4830450221009fab428713fa76057e1bd87381614abc270089ddb23c345b0a56114db0fb8fd30220187a80bedfbb6b23bcf4eaf25017be2efdd64f02a732be9f4846142ad3408798012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffff011005d0010000000017a91469545b58fd41a120da3f606be313e061ea818edf8700000000 >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -v -r 010000000301de569ae0b3d49dff80f79f7953f87f17f61ca1f6d523e815a58e2b8863d098000000006a47304402203930d1ba339c9692367ae37836b1f21c1431ecb4522e7ce0caa356b9813722dc02204086f7ad81d5d656ab1b6d0fd4709b5759c22c44a0aeb1969c1cdb7c463912fa012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffff97e60e0bec78cf5114238678f0b5eab617ca770752796b4c795c9d3ada772da5000000006a473044022046412e2b3f820f846a5e8f1cc92529cb694cf0d09d35cf0b5128cc7b9bf32a0802207f736b322727babd41793aeedfad41cc0541c0a1693e88b2a620bcd664da8551012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffffce559734242e6a6e0608caa07ee1178d5b9e53e0814d61f002930d78422e8402000000006b4830450221009fab428713fa76057e1bd87381614abc270089ddb23c345b0a56114db0fb8fd30220187a80bedfbb6b23bcf4eaf25017be2efdd64f02a732be9f4846142ad3408798012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffff011005d0010000000017a91469545b58fd41a120da3f606be313e061ea818edf8700000000 > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= c44efc6f107dd2dab02ffc7bf673478b545804c6933912b0faec31791048036c"

echo "TESTCASE 5c: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh -vv -r 010000000301de569ae0b3d49dff80f79f7953f87f17f61ca1f6d523e815a58e2b8863d098000000006a47304402203930d1ba339c9692367ae37836b1f21c1431ecb4522e7ce0caa356b9813722dc02204086f7ad81d5d656ab1b6d0fd4709b5759c22c44a0aeb1969c1cdb7c463912fa012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffff97e60e0bec78cf5114238678f0b5eab617ca770752796b4c795c9d3ada772da5000000006a473044022046412e2b3f820f846a5e8f1cc92529cb694cf0d09d35cf0b5128cc7b9bf32a0802207f736b322727babd41793aeedfad41cc0541c0a1693e88b2a620bcd664da8551012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffffce559734242e6a6e0608caa07ee1178d5b9e53e0814d61f002930d78422e8402000000006b4830450221009fab428713fa76057e1bd87381614abc270089ddb23c345b0a56114db0fb8fd30220187a80bedfbb6b23bcf4eaf25017be2efdd64f02a732be9f4846142ad3408798012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffff011005d0010000000017a91469545b58fd41a120da3f606be313e061ea818edf8700000000 >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -vv -r 010000000301de569ae0b3d49dff80f79f7953f87f17f61ca1f6d523e815a58e2b8863d098000000006a47304402203930d1ba339c9692367ae37836b1f21c1431ecb4522e7ce0caa356b9813722dc02204086f7ad81d5d656ab1b6d0fd4709b5759c22c44a0aeb1969c1cdb7c463912fa012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffff97e60e0bec78cf5114238678f0b5eab617ca770752796b4c795c9d3ada772da5000000006a473044022046412e2b3f820f846a5e8f1cc92529cb694cf0d09d35cf0b5128cc7b9bf32a0802207f736b322727babd41793aeedfad41cc0541c0a1693e88b2a620bcd664da8551012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffffce559734242e6a6e0608caa07ee1178d5b9e53e0814d61f002930d78422e8402000000006b4830450221009fab428713fa76057e1bd87381614abc270089ddb23c345b0a56114db0fb8fd30220187a80bedfbb6b23bcf4eaf25017be2efdd64f02a732be9f4846142ad3408798012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffff011005d0010000000017a91469545b58fd41a120da3f606be313e061ea818edf8700000000 > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= 7bff06301da8478797246774f4cc5a1e67afa850d4bdc9092d12e04c6c9bb6fc"
echo " " | tee -a $logfile
}

testcase6() {
# this trx has 1 input, and 4 outputs.
echo "#################################################################" | tee -a $logfile
echo "### TESTCASE 6:                                               ###" | tee -a $logfile
echo "#################################################################" | tee -a $logfile
echo "###  this trx has 1 input, and 4 outputs.                     ###" >> $logfile
echo "###  trx-in sequence = feffffff - what does this mean?        ###" >> $logfile
echo "#################################################################" >> $logfile
echo "https://blockchain.info/de/rawtx/7264f8ba4a85a4780c549bf04a98e8de4c9cb1120cb1dfe8ab85ff6832eff864" >> $logfile

echo "TESTCASE 6a: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh -r 0100000001df64d3e790779777de937eea18884e9b131c9910bdb860b1a5cea225b61e3510020000006b48304502210082e594fdd17f4f2995edc180e5373a664eb56f56420f0c8761a27fa612db2a2b02206bcd4763303661c9ccaac3e4e7f6bfc062f17ce4b6b1b479ee067a05e5a578b10121036932969ec8c5cecebc1ff6fc07126f8cb5589ada69db8ca97a4f1291ead8c06bfeffffff04d130ab00000000001976a9141f59b78ccc26b6d84a65b0d362185ac4683197ed88acf0fcf300000000001976a914f12d85961d3a36119c2eaed5ad0e728a789ab59c88acb70aa700000000001976a9142baaf47baf1bd1e3dad3956db536c3f2e87c237b88ac94804707000000001976a914cb1b1d3c8be7db6416c16a1d29db170930970a3088acce3d0600 >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -r 0100000001df64d3e790779777de937eea18884e9b131c9910bdb860b1a5cea225b61e3510020000006b48304502210082e594fdd17f4f2995edc180e5373a664eb56f56420f0c8761a27fa612db2a2b02206bcd4763303661c9ccaac3e4e7f6bfc062f17ce4b6b1b479ee067a05e5a578b10121036932969ec8c5cecebc1ff6fc07126f8cb5589ada69db8ca97a4f1291ead8c06bfeffffff04d130ab00000000001976a9141f59b78ccc26b6d84a65b0d362185ac4683197ed88acf0fcf300000000001976a914f12d85961d3a36119c2eaed5ad0e728a789ab59c88acb70aa700000000001976a9142baaf47baf1bd1e3dad3956db536c3f2e87c237b88ac94804707000000001976a914cb1b1d3c8be7db6416c16a1d29db170930970a3088acce3d0600 > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= a2213bf49fd7d6a22610cff0f8375bc80ad9d243443b5dea88052c3e611d2065"

echo "TESTCASE 6b: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh -v -r 0100000001df64d3e790779777de937eea18884e9b131c9910bdb860b1a5cea225b61e3510020000006b48304502210082e594fdd17f4f2995edc180e5373a664eb56f56420f0c8761a27fa612db2a2b02206bcd4763303661c9ccaac3e4e7f6bfc062f17ce4b6b1b479ee067a05e5a578b10121036932969ec8c5cecebc1ff6fc07126f8cb5589ada69db8ca97a4f1291ead8c06bfeffffff04d130ab00000000001976a9141f59b78ccc26b6d84a65b0d362185ac4683197ed88acf0fcf300000000001976a914f12d85961d3a36119c2eaed5ad0e728a789ab59c88acb70aa700000000001976a9142baaf47baf1bd1e3dad3956db536c3f2e87c237b88ac94804707000000001976a914cb1b1d3c8be7db6416c16a1d29db170930970a3088acce3d0600 >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -v -r 0100000001df64d3e790779777de937eea18884e9b131c9910bdb860b1a5cea225b61e3510020000006b48304502210082e594fdd17f4f2995edc180e5373a664eb56f56420f0c8761a27fa612db2a2b02206bcd4763303661c9ccaac3e4e7f6bfc062f17ce4b6b1b479ee067a05e5a578b10121036932969ec8c5cecebc1ff6fc07126f8cb5589ada69db8ca97a4f1291ead8c06bfeffffff04d130ab00000000001976a9141f59b78ccc26b6d84a65b0d362185ac4683197ed88acf0fcf300000000001976a914f12d85961d3a36119c2eaed5ad0e728a789ab59c88acb70aa700000000001976a9142baaf47baf1bd1e3dad3956db536c3f2e87c237b88ac94804707000000001976a914cb1b1d3c8be7db6416c16a1d29db170930970a3088acce3d0600 > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= 33801c2b908c2e942b6a3cce08aa5c42e8de488b8ee74e7cdb4de72eb8b2f64f"

echo "TESTCASE 6c: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh -vv -r 0100000001df64d3e790779777de937eea18884e9b131c9910bdb860b1a5cea225b61e3510020000006b48304502210082e594fdd17f4f2995edc180e5373a664eb56f56420f0c8761a27fa612db2a2b02206bcd4763303661c9ccaac3e4e7f6bfc062f17ce4b6b1b479ee067a05e5a578b10121036932969ec8c5cecebc1ff6fc07126f8cb5589ada69db8ca97a4f1291ead8c06bfeffffff04d130ab00000000001976a9141f59b78ccc26b6d84a65b0d362185ac4683197ed88acf0fcf300000000001976a914f12d85961d3a36119c2eaed5ad0e728a789ab59c88acb70aa700000000001976a9142baaf47baf1bd1e3dad3956db536c3f2e87c237b88ac94804707000000001976a914cb1b1d3c8be7db6416c16a1d29db170930970a3088acce3d0600 >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -vv -r 0100000001df64d3e790779777de937eea18884e9b131c9910bdb860b1a5cea225b61e3510020000006b48304502210082e594fdd17f4f2995edc180e5373a664eb56f56420f0c8761a27fa612db2a2b02206bcd4763303661c9ccaac3e4e7f6bfc062f17ce4b6b1b479ee067a05e5a578b10121036932969ec8c5cecebc1ff6fc07126f8cb5589ada69db8ca97a4f1291ead8c06bfeffffff04d130ab00000000001976a9141f59b78ccc26b6d84a65b0d362185ac4683197ed88acf0fcf300000000001976a914f12d85961d3a36119c2eaed5ad0e728a789ab59c88acb70aa700000000001976a9142baaf47baf1bd1e3dad3956db536c3f2e87c237b88ac94804707000000001976a914cb1b1d3c8be7db6416c16a1d29db170930970a3088acce3d0600 > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= efd10c6ed5dbb1cdc562b398636e790b2ce5ac2bb4b0c5e5782f9b6541e99c7a"
echo " " | tee -a $logfile
}

testcase7() {
# this trx has 1 input, 2 outputs (one is P2SH script)
echo "#################################################################" | tee -a $logfile
echo "### TESTCASE 7:                                               ###" | tee -a $logfile
echo "#################################################################" | tee -a $logfile
echo "###  blockchain.info shows a single TRX-IN ECDSA Key as a     ###" >> $logfile
echo "###  PS2H address (3A75K3usH7...). However, there seem to     ###" >> $logfile
echo "###  be two signatures in the hex code of the script:         ###" >> $logfile
echo "###      ...                                                  ###" >> $logfile
echo "###      47: OP_DATA_0x47                                     ###" >> $logfile
echo "###      52: unknown opcode                                   ###" >> $logfile
echo "###      21: OP_DATA_0x21                                     ###" >> $logfile
echo "###      02: OP_INT_0x02                                      ###" >> $logfile
echo "###          0285CB139A82DD90:62B9AC1091CB1F91                ###" >> $logfile
echo "###          A01C11AB9C6A46BD:09D0754DAB86A38C                ###" >> $logfile
echo "###          C9                                               ###" >> $logfile
echo "###   * This is Public ECDSA Key, corresponding bitcoin ...   ###" >> $logfile
echo "###   1LcBDzTGSJiN5snVBHiyeWsT7SqRWUW7mp                      ###" >> $logfile
echo "###      21: OP_DATA_0x21                                     ###" >> $logfile
echo "###      03: OP_INT_0x03                                      ###" >> $logfile
echo "###          0328C37F938748DC:BBF15A0E5A9D1BA2                ###" >> $logfile
echo "###          0F93F2C2D0EAD63C:7C14A5A10959B5CE                ###" >> $logfile
echo "###          89                                               ###" >> $logfile
echo "###   * This is Public ECDSA Key, corresponding bitcoin ...   ###" >> $logfile
echo "###   1LisHErVXWhY1A1ZJqZSDdGYKrbGn1M6bx                      ###" >> $logfile
echo "###                                                           ###" >> $logfile
echo "###  trx-in script len seems to be '0xda'. Script then starts ###" >> $logfile
echo "###  with '00483045...', what does this mean, where is docu ? ###" >> $logfile
echo "#################################################################" >> $logfile
echo "https://blockchain.info/de/rawtx/c0889855c93eed67d1f5a6b8a31e446e3327ce03bc267f2db958e79802941c73" >> $logfile

echo "TESTCASE 7a: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh -r 0100000001b9c6777f2d8d710f1e0e3bb5fbffa7cdfd6c814a2257a7cfced9a2205448dd0601000000da0048304502210083a93c7611f5aeee6b0b4d1cbff2d31556af4cd1f951de8341c768ae03f780730220063b5e6dfb461291b1fbd93d58a8111d04fd03c7098834bac5cdf1d3c5fa90d0014730440220137c7320e03b73da66e9cf89e5f5ed0d5743ebc65e776707b8385ff93039408802202c30bc57010b3dd20507393ebc79affc653473a7baf03c5abf19c14e2136c646014752210285cb139a82dd9062b9ac1091cb1f91a01c11ab9c6a46bd09d0754dab86a38cc9210328c37f938748dcbbf15a0e5a9d1ba20f93f2c2d0ead63c7c14a5a10959b5ce8952aeffffffff0280c42b03000000001976a914d199925b52d367220b1e2a2d8815e635b571512f88ac65a7b3010000000017a9145c4dd14b9df138840b34237fdbe9159c420edbbe8700000000 >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -r 0100000001b9c6777f2d8d710f1e0e3bb5fbffa7cdfd6c814a2257a7cfced9a2205448dd0601000000da0048304502210083a93c7611f5aeee6b0b4d1cbff2d31556af4cd1f951de8341c768ae03f780730220063b5e6dfb461291b1fbd93d58a8111d04fd03c7098834bac5cdf1d3c5fa90d0014730440220137c7320e03b73da66e9cf89e5f5ed0d5743ebc65e776707b8385ff93039408802202c30bc57010b3dd20507393ebc79affc653473a7baf03c5abf19c14e2136c646014752210285cb139a82dd9062b9ac1091cb1f91a01c11ab9c6a46bd09d0754dab86a38cc9210328c37f938748dcbbf15a0e5a9d1ba20f93f2c2d0ead63c7c14a5a10959b5ce8952aeffffffff0280c42b03000000001976a914d199925b52d367220b1e2a2d8815e635b571512f88ac65a7b3010000000017a9145c4dd14b9df138840b34237fdbe9159c420edbbe8700000000 > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= ecfe6b4c83bfeaeff7237dd58b3c45892e11b3d3eee9c41cb1f51b1f2a1ad177"

echo "TESTCASE 7b: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh -v -r 0100000001b9c6777f2d8d710f1e0e3bb5fbffa7cdfd6c814a2257a7cfced9a2205448dd0601000000da0048304502210083a93c7611f5aeee6b0b4d1cbff2d31556af4cd1f951de8341c768ae03f780730220063b5e6dfb461291b1fbd93d58a8111d04fd03c7098834bac5cdf1d3c5fa90d0014730440220137c7320e03b73da66e9cf89e5f5ed0d5743ebc65e776707b8385ff93039408802202c30bc57010b3dd20507393ebc79affc653473a7baf03c5abf19c14e2136c646014752210285cb139a82dd9062b9ac1091cb1f91a01c11ab9c6a46bd09d0754dab86a38cc9210328c37f938748dcbbf15a0e5a9d1ba20f93f2c2d0ead63c7c14a5a10959b5ce8952aeffffffff0280c42b03000000001976a914d199925b52d367220b1e2a2d8815e635b571512f88ac65a7b3010000000017a9145c4dd14b9df138840b34237fdbe9159c420edbbe8700000000 >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -v -r 0100000001b9c6777f2d8d710f1e0e3bb5fbffa7cdfd6c814a2257a7cfced9a2205448dd0601000000da0048304502210083a93c7611f5aeee6b0b4d1cbff2d31556af4cd1f951de8341c768ae03f780730220063b5e6dfb461291b1fbd93d58a8111d04fd03c7098834bac5cdf1d3c5fa90d0014730440220137c7320e03b73da66e9cf89e5f5ed0d5743ebc65e776707b8385ff93039408802202c30bc57010b3dd20507393ebc79affc653473a7baf03c5abf19c14e2136c646014752210285cb139a82dd9062b9ac1091cb1f91a01c11ab9c6a46bd09d0754dab86a38cc9210328c37f938748dcbbf15a0e5a9d1ba20f93f2c2d0ead63c7c14a5a10959b5ce8952aeffffffff0280c42b03000000001976a914d199925b52d367220b1e2a2d8815e635b571512f88ac65a7b3010000000017a9145c4dd14b9df138840b34237fdbe9159c420edbbe8700000000 > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= b7ba1c017f81639445a96badb996d2a99110d43f53402abfd71d9426f0c70ac9"

echo "TESTCASE 7c: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh -vv -r 0100000001b9c6777f2d8d710f1e0e3bb5fbffa7cdfd6c814a2257a7cfced9a2205448dd0601000000da0048304502210083a93c7611f5aeee6b0b4d1cbff2d31556af4cd1f951de8341c768ae03f780730220063b5e6dfb461291b1fbd93d58a8111d04fd03c7098834bac5cdf1d3c5fa90d0014730440220137c7320e03b73da66e9cf89e5f5ed0d5743ebc65e776707b8385ff93039408802202c30bc57010b3dd20507393ebc79affc653473a7baf03c5abf19c14e2136c646014752210285cb139a82dd9062b9ac1091cb1f91a01c11ab9c6a46bd09d0754dab86a38cc9210328c37f938748dcbbf15a0e5a9d1ba20f93f2c2d0ead63c7c14a5a10959b5ce8952aeffffffff0280c42b03000000001976a914d199925b52d367220b1e2a2d8815e635b571512f88ac65a7b3010000000017a9145c4dd14b9df138840b34237fdbe9159c420edbbe8700000000 >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -vv -r 0100000001b9c6777f2d8d710f1e0e3bb5fbffa7cdfd6c814a2257a7cfced9a2205448dd0601000000da0048304502210083a93c7611f5aeee6b0b4d1cbff2d31556af4cd1f951de8341c768ae03f780730220063b5e6dfb461291b1fbd93d58a8111d04fd03c7098834bac5cdf1d3c5fa90d0014730440220137c7320e03b73da66e9cf89e5f5ed0d5743ebc65e776707b8385ff93039408802202c30bc57010b3dd20507393ebc79affc653473a7baf03c5abf19c14e2136c646014752210285cb139a82dd9062b9ac1091cb1f91a01c11ab9c6a46bd09d0754dab86a38cc9210328c37f938748dcbbf15a0e5a9d1ba20f93f2c2d0ead63c7c14a5a10959b5ce8952aeffffffff0280c42b03000000001976a914d199925b52d367220b1e2a2d8815e635b571512f88ac65a7b3010000000017a9145c4dd14b9df138840b34237fdbe9159c420edbbe8700000000 > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= 5106ba53b1b9173f37b105a8a949105df740c8892f451f1ea5eb81835e36afb3"
echo " " | tee -a $logfile
}

testcase8() {
# this trx has 1 input, 4 outputs (one is P2SH script)
echo "#################################################################" | tee -a $logfile
echo "### TESTCASE 8:                                               ###" | tee -a $logfile
echo "#################################################################" | tee -a $logfile
echo "###  this trx has 1 input, 4 outputs (one is P2SH script)     ###" >> $logfile
echo "###  the trx-in script sig is unclear, need further docu...   ###" >> $logfile
echo "###  the trx-in script sig is having more than one signature. ###" >> $logfile
echo "###  Blockchain.info shows only a single one...               ###" >> $logfile
echo "###  docu? support?                                           ###" >> $logfile
echo "#################################################################" >> $logfile
echo "https://blockchain.info/de/rawtx/ea9462053d74024ec46dac07c450200194051020698e8640a5a024d8ac085590" >> $logfile

echo "TESTCASE 8a: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh -r 01000000013153f60f294bc14d0481138c1c9627ff71a580b596987a82e9eebf2ae3de232202000000fc0047304402200c2f9e8805de97fa785b93dcc9072197bf5c1095ea536320ed26c645ec3bfafc02202882258f394449f1b1365ce80eed26fbe01217657729664af6827d041e7e98510147304402206d5cbef275b6972bd8cc00aff666a6ca18f09a5b1d1bf49e6966ad815db7119a0220340e49d4b747c9bd8ac80dbe073525c57da43dc4d2727b789be7e66bed9c6d02014c695221037b7c16024e2e6f6575b7a8c55c581dce7effcd6045bdf196461be8ff88db24f1210223eefa59f9b51ca96e1f4710df3639c58aae32c4cef1dd0333e7478de3dd4c6321034d03a7e6806e734c171be535999239aac76822427c217ee7564ab752cdc12dde53aeffffffff048d40ad120100000017a914fb8e0ce6d2f35c566908fd225b7f96e72df603d3872d5f0000000000001976a914768ac2a2530b2987d2e6506edc71dcf9f0a7b6e688ac00350c00000000001976a91452f28673c5aed9126b91d9eac5cbe1e02276a2cb88ac18b30700000000001976a914f3678c60ec389c7b132b5e5b0e1434b6dcd48f4188ac00000000 >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -r 01000000013153f60f294bc14d0481138c1c9627ff71a580b596987a82e9eebf2ae3de232202000000fc0047304402200c2f9e8805de97fa785b93dcc9072197bf5c1095ea536320ed26c645ec3bfafc02202882258f394449f1b1365ce80eed26fbe01217657729664af6827d041e7e98510147304402206d5cbef275b6972bd8cc00aff666a6ca18f09a5b1d1bf49e6966ad815db7119a0220340e49d4b747c9bd8ac80dbe073525c57da43dc4d2727b789be7e66bed9c6d02014c695221037b7c16024e2e6f6575b7a8c55c581dce7effcd6045bdf196461be8ff88db24f1210223eefa59f9b51ca96e1f4710df3639c58aae32c4cef1dd0333e7478de3dd4c6321034d03a7e6806e734c171be535999239aac76822427c217ee7564ab752cdc12dde53aeffffffff048d40ad120100000017a914fb8e0ce6d2f35c566908fd225b7f96e72df603d3872d5f0000000000001976a914768ac2a2530b2987d2e6506edc71dcf9f0a7b6e688ac00350c00000000001976a91452f28673c5aed9126b91d9eac5cbe1e02276a2cb88ac18b30700000000001976a914f3678c60ec389c7b132b5e5b0e1434b6dcd48f4188ac00000000 > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= 3343b3975b6ec3f1a72fa9dec0a649d5e81d4f2ca52cbd5ddb2715a5b2561842"

echo "TESTCASE 8b: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh -v -r 01000000013153f60f294bc14d0481138c1c9627ff71a580b596987a82e9eebf2ae3de232202000000fc0047304402200c2f9e8805de97fa785b93dcc9072197bf5c1095ea536320ed26c645ec3bfafc02202882258f394449f1b1365ce80eed26fbe01217657729664af6827d041e7e98510147304402206d5cbef275b6972bd8cc00aff666a6ca18f09a5b1d1bf49e6966ad815db7119a0220340e49d4b747c9bd8ac80dbe073525c57da43dc4d2727b789be7e66bed9c6d02014c695221037b7c16024e2e6f6575b7a8c55c581dce7effcd6045bdf196461be8ff88db24f1210223eefa59f9b51ca96e1f4710df3639c58aae32c4cef1dd0333e7478de3dd4c6321034d03a7e6806e734c171be535999239aac76822427c217ee7564ab752cdc12dde53aeffffffff048d40ad120100000017a914fb8e0ce6d2f35c566908fd225b7f96e72df603d3872d5f0000000000001976a914768ac2a2530b2987d2e6506edc71dcf9f0a7b6e688ac00350c00000000001976a91452f28673c5aed9126b91d9eac5cbe1e02276a2cb88ac18b30700000000001976a914f3678c60ec389c7b132b5e5b0e1434b6dcd48f4188ac00000000 >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -v -r 01000000013153f60f294bc14d0481138c1c9627ff71a580b596987a82e9eebf2ae3de232202000000fc0047304402200c2f9e8805de97fa785b93dcc9072197bf5c1095ea536320ed26c645ec3bfafc02202882258f394449f1b1365ce80eed26fbe01217657729664af6827d041e7e98510147304402206d5cbef275b6972bd8cc00aff666a6ca18f09a5b1d1bf49e6966ad815db7119a0220340e49d4b747c9bd8ac80dbe073525c57da43dc4d2727b789be7e66bed9c6d02014c695221037b7c16024e2e6f6575b7a8c55c581dce7effcd6045bdf196461be8ff88db24f1210223eefa59f9b51ca96e1f4710df3639c58aae32c4cef1dd0333e7478de3dd4c6321034d03a7e6806e734c171be535999239aac76822427c217ee7564ab752cdc12dde53aeffffffff048d40ad120100000017a914fb8e0ce6d2f35c566908fd225b7f96e72df603d3872d5f0000000000001976a914768ac2a2530b2987d2e6506edc71dcf9f0a7b6e688ac00350c00000000001976a91452f28673c5aed9126b91d9eac5cbe1e02276a2cb88ac18b30700000000001976a914f3678c60ec389c7b132b5e5b0e1434b6dcd48f4188ac00000000 > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= da90aa615a98d3ad5cdedc31d0103e566fd3080cdb0d692d9dcd2994c66fe580"

echo "TESTCASE 8c: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh -vv -r 01000000013153f60f294bc14d0481138c1c9627ff71a580b596987a82e9eebf2ae3de232202000000fc0047304402200c2f9e8805de97fa785b93dcc9072197bf5c1095ea536320ed26c645ec3bfafc02202882258f394449f1b1365ce80eed26fbe01217657729664af6827d041e7e98510147304402206d5cbef275b6972bd8cc00aff666a6ca18f09a5b1d1bf49e6966ad815db7119a0220340e49d4b747c9bd8ac80dbe073525c57da43dc4d2727b789be7e66bed9c6d02014c695221037b7c16024e2e6f6575b7a8c55c581dce7effcd6045bdf196461be8ff88db24f1210223eefa59f9b51ca96e1f4710df3639c58aae32c4cef1dd0333e7478de3dd4c6321034d03a7e6806e734c171be535999239aac76822427c217ee7564ab752cdc12dde53aeffffffff048d40ad120100000017a914fb8e0ce6d2f35c566908fd225b7f96e72df603d3872d5f0000000000001976a914768ac2a2530b2987d2e6506edc71dcf9f0a7b6e688ac00350c00000000001976a91452f28673c5aed9126b91d9eac5cbe1e02276a2cb88ac18b30700000000001976a914f3678c60ec389c7b132b5e5b0e1434b6dcd48f4188ac00000000 >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -vv -r 01000000013153f60f294bc14d0481138c1c9627ff71a580b596987a82e9eebf2ae3de232202000000fc0047304402200c2f9e8805de97fa785b93dcc9072197bf5c1095ea536320ed26c645ec3bfafc02202882258f394449f1b1365ce80eed26fbe01217657729664af6827d041e7e98510147304402206d5cbef275b6972bd8cc00aff666a6ca18f09a5b1d1bf49e6966ad815db7119a0220340e49d4b747c9bd8ac80dbe073525c57da43dc4d2727b789be7e66bed9c6d02014c695221037b7c16024e2e6f6575b7a8c55c581dce7effcd6045bdf196461be8ff88db24f1210223eefa59f9b51ca96e1f4710df3639c58aae32c4cef1dd0333e7478de3dd4c6321034d03a7e6806e734c171be535999239aac76822427c217ee7564ab752cdc12dde53aeffffffff048d40ad120100000017a914fb8e0ce6d2f35c566908fd225b7f96e72df603d3872d5f0000000000001976a914768ac2a2530b2987d2e6506edc71dcf9f0a7b6e688ac00350c00000000001976a91452f28673c5aed9126b91d9eac5cbe1e02276a2cb88ac18b30700000000001976a914f3678c60ec389c7b132b5e5b0e1434b6dcd48f4188ac00000000 > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= bbe8293dee7a176700d71c2741f08d69b16833789e77d96b31034b8d52901c98"
echo " " | tee -a $logfile
}

testcase9() {
# this trx has a complicated input script (PK script?)
echo "#################################################################" | tee -a $logfile
echo "### TESTCASE 9:                                               ###" | tee -a $logfile
echo "#################################################################" | tee -a $logfile
echo "###  this trx has 35 output scripts ...                       ###" >> $logfile
echo "#################################################################" >> $logfile
echo "https://blockchain.info/https://blockchain.info/de/rawtx/7c83fe5ba301e655973e9de8eb9fb5e20ef3a6dd9b46c503679c858399eda50f" >> $logfile

echo "TESTCASE 9a: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh -r 01000000014675ab74e5c496c8eecaaa87c6136bc68ebaaac7a25e70ee29b7bbaffad6810f000000008b4830450220296d4f4869a63efdee4c5ea31dcad559b4e03332462ba5442bfdf00a662cb77102210088a7f10361eae3e159ae6a8b5b7a569bf6bfa2de64fb3f5d0552f8be568ba6f50141042a9a97b2109ef496ffb1033576a5635cecc6ab679ad0b7c43d33ddf38b1f44c22ea42d5c01ac2752094ff81e79dda77d8b501a64102207c45fb89ea1ad9229ddffffffff23e8030000000000001976a914801314cd462b98c64dd4c3f4d6474cad11ea39d588ace8030000000000001976a9145bb7d22851413e1d61e8db5395a8c7c537256ea088ace8030000000000001976a914371f197d5ba5e32bd98260eec7f0e51227b6969088ace8030000000000001976a9143e546d0acc0de5aa3d66d7a920900ecbc66c203188ace8030000000000001976a9140337e0710056f114c9c469a68775498df9f9fa1688ace8030000000000001976a9149c628c82aa7b81da7c6a235049eb2979c4a65cfc88ace8030000000000001976a914cd1d7e863f891c493e093ada840ef5a67ad2d6cc88ace8030000000000001976a91476f074340381e6f8a40aec4a6e2d92485679412c88ace8030000000000001976a9140fb87a5071385b6976397d1c53ee16f09139a33488ace8030000000000001976a9143d37873ffd2964a1a4c8bade4852020ec5426d3688ace8030000000000001976a9145d14a857fce8da8edfb8f7d1c4bbc316622b722788ace8030000000000001976a9140a77fdb4cc81631b6ea2991ff60b47d57812d8e788ace8030000000000001976a91454514fe9251b5e381d13171cd6fca63f61d8b72688ace8030000000000001976a914cffe3e032a686cc3f2c9e417865afa8a52ed962b88ace8030000000000001976a914fd9dc3525076c1ffe9c33389ea157d07af2e41d488ace8030000000000001976a9143bedfe927d55a8c8adfe5e4b5dddd4ea3487b4c988ace8030000000000001976a914e49275e86ece605f271f26a9559520eb9c0ae8d888ace8030000000000001976a91469256ba90b0d7e406d86a51d343d157ff0aab7bd88ace8030000000000001976a9148ab0cb809cd893cb0cb16f647d024db94f09d76588ace8030000000000001976a9140688e383f02b528c92e25caae5785ffaa81a26aa88ace8030000000000001976a914d959be6c92037995558f43a55b1c271628f96e8d88ac8038f240000000001976a914d15e54e341d538ce3e9e7596e0dbcda8c12cc08988ace8030000000000001976a91495019a8168e8dcd2ef2d47ca57c1bf49358eb6fe88ace8030000000000001976a914caf67cfe28b511498b0d1792bedeec6b6e8a3c8d88ace8030000000000001976a914082a3adf4c8497fbd7d90f21cbec318b0dfdd2b288ace8030000000000001976a9144c53722fd5b0bc8a5b23ae4efc6233142b69d8ee88ace8030000000000001976a9146abd1edce61a7fdd2d134e8468560ecffb45334e88ace8030000000000001976a914dc3343b674cf2016b8968e6146ba5cc9228f14a488ace8030000000000001976a9145f395a91d07712604d7cd6fabd685b9bfd3900dd88ace8030000000000001976a914fc35239072cd5c19d9f761996951679fb03bb43188ace8030000000000001976a914b1ec1d5e0591abbbe3134c94c37e74d034b9312288ace8030000000000001976a9142d6351944aa38af6aa46d4a74cbb9016cf19ee7e88ace8030000000000001976a914879a49b3822806e0322565d457ce2b5989adaa6188ace8030000000000001976a9145ff26e3f8d542c5bb612e539649eaec0222afc3c88ace8030000000000001976a914105d54a4edcbe114a50bb01c79d230b7ed74a3e488ac00000000 >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -r 01000000014675ab74e5c496c8eecaaa87c6136bc68ebaaac7a25e70ee29b7bbaffad6810f000000008b4830450220296d4f4869a63efdee4c5ea31dcad559b4e03332462ba5442bfdf00a662cb77102210088a7f10361eae3e159ae6a8b5b7a569bf6bfa2de64fb3f5d0552f8be568ba6f50141042a9a97b2109ef496ffb1033576a5635cecc6ab679ad0b7c43d33ddf38b1f44c22ea42d5c01ac2752094ff81e79dda77d8b501a64102207c45fb89ea1ad9229ddffffffff23e8030000000000001976a914801314cd462b98c64dd4c3f4d6474cad11ea39d588ace8030000000000001976a9145bb7d22851413e1d61e8db5395a8c7c537256ea088ace8030000000000001976a914371f197d5ba5e32bd98260eec7f0e51227b6969088ace8030000000000001976a9143e546d0acc0de5aa3d66d7a920900ecbc66c203188ace8030000000000001976a9140337e0710056f114c9c469a68775498df9f9fa1688ace8030000000000001976a9149c628c82aa7b81da7c6a235049eb2979c4a65cfc88ace8030000000000001976a914cd1d7e863f891c493e093ada840ef5a67ad2d6cc88ace8030000000000001976a91476f074340381e6f8a40aec4a6e2d92485679412c88ace8030000000000001976a9140fb87a5071385b6976397d1c53ee16f09139a33488ace8030000000000001976a9143d37873ffd2964a1a4c8bade4852020ec5426d3688ace8030000000000001976a9145d14a857fce8da8edfb8f7d1c4bbc316622b722788ace8030000000000001976a9140a77fdb4cc81631b6ea2991ff60b47d57812d8e788ace8030000000000001976a91454514fe9251b5e381d13171cd6fca63f61d8b72688ace8030000000000001976a914cffe3e032a686cc3f2c9e417865afa8a52ed962b88ace8030000000000001976a914fd9dc3525076c1ffe9c33389ea157d07af2e41d488ace8030000000000001976a9143bedfe927d55a8c8adfe5e4b5dddd4ea3487b4c988ace8030000000000001976a914e49275e86ece605f271f26a9559520eb9c0ae8d888ace8030000000000001976a91469256ba90b0d7e406d86a51d343d157ff0aab7bd88ace8030000000000001976a9148ab0cb809cd893cb0cb16f647d024db94f09d76588ace8030000000000001976a9140688e383f02b528c92e25caae5785ffaa81a26aa88ace8030000000000001976a914d959be6c92037995558f43a55b1c271628f96e8d88ac8038f240000000001976a914d15e54e341d538ce3e9e7596e0dbcda8c12cc08988ace8030000000000001976a91495019a8168e8dcd2ef2d47ca57c1bf49358eb6fe88ace8030000000000001976a914caf67cfe28b511498b0d1792bedeec6b6e8a3c8d88ace8030000000000001976a914082a3adf4c8497fbd7d90f21cbec318b0dfdd2b288ace8030000000000001976a9144c53722fd5b0bc8a5b23ae4efc6233142b69d8ee88ace8030000000000001976a9146abd1edce61a7fdd2d134e8468560ecffb45334e88ace8030000000000001976a914dc3343b674cf2016b8968e6146ba5cc9228f14a488ace8030000000000001976a9145f395a91d07712604d7cd6fabd685b9bfd3900dd88ace8030000000000001976a914fc35239072cd5c19d9f761996951679fb03bb43188ace8030000000000001976a914b1ec1d5e0591abbbe3134c94c37e74d034b9312288ace8030000000000001976a9142d6351944aa38af6aa46d4a74cbb9016cf19ee7e88ace8030000000000001976a914879a49b3822806e0322565d457ce2b5989adaa6188ace8030000000000001976a9145ff26e3f8d542c5bb612e539649eaec0222afc3c88ace8030000000000001976a914105d54a4edcbe114a50bb01c79d230b7ed74a3e488ac00000000 > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= 0a1f0b6c5dce37e107665674fdc38eb786f7b1c434989ea1ce8b0c4658240fc7"

echo "TESTCASE 9b: " | tee -a $logfile

if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh -v -r 01000000014675ab74e5c496c8eecaaa87c6136bc68ebaaac7a25e70ee29b7bbaffad6810f000000008b4830450220296d4f4869a63efdee4c5ea31dcad559b4e03332462ba5442bfdf00a662cb77102210088a7f10361eae3e159ae6a8b5b7a569bf6bfa2de64fb3f5d0552f8be568ba6f50141042a9a97b2109ef496ffb1033576a5635cecc6ab679ad0b7c43d33ddf38b1f44c22ea42d5c01ac2752094ff81e79dda77d8b501a64102207c45fb89ea1ad9229ddffffffff23e8030000000000001976a914801314cd462b98c64dd4c3f4d6474cad11ea39d588ace8030000000000001976a9145bb7d22851413e1d61e8db5395a8c7c537256ea088ace8030000000000001976a914371f197d5ba5e32bd98260eec7f0e51227b6969088ace8030000000000001976a9143e546d0acc0de5aa3d66d7a920900ecbc66c203188ace8030000000000001976a9140337e0710056f114c9c469a68775498df9f9fa1688ace8030000000000001976a9149c628c82aa7b81da7c6a235049eb2979c4a65cfc88ace8030000000000001976a914cd1d7e863f891c493e093ada840ef5a67ad2d6cc88ace8030000000000001976a91476f074340381e6f8a40aec4a6e2d92485679412c88ace8030000000000001976a9140fb87a5071385b6976397d1c53ee16f09139a33488ace8030000000000001976a9143d37873ffd2964a1a4c8bade4852020ec5426d3688ace8030000000000001976a9145d14a857fce8da8edfb8f7d1c4bbc316622b722788ace8030000000000001976a9140a77fdb4cc81631b6ea2991ff60b47d57812d8e788ace8030000000000001976a91454514fe9251b5e381d13171cd6fca63f61d8b72688ace8030000000000001976a914cffe3e032a686cc3f2c9e417865afa8a52ed962b88ace8030000000000001976a914fd9dc3525076c1ffe9c33389ea157d07af2e41d488ace8030000000000001976a9143bedfe927d55a8c8adfe5e4b5dddd4ea3487b4c988ace8030000000000001976a914e49275e86ece605f271f26a9559520eb9c0ae8d888ace8030000000000001976a91469256ba90b0d7e406d86a51d343d157ff0aab7bd88ace8030000000000001976a9148ab0cb809cd893cb0cb16f647d024db94f09d76588ace8030000000000001976a9140688e383f02b528c92e25caae5785ffaa81a26aa88ace8030000000000001976a914d959be6c92037995558f43a55b1c271628f96e8d88ac8038f240000000001976a914d15e54e341d538ce3e9e7596e0dbcda8c12cc08988ace8030000000000001976a91495019a8168e8dcd2ef2d47ca57c1bf49358eb6fe88ace8030000000000001976a914caf67cfe28b511498b0d1792bedeec6b6e8a3c8d88ace8030000000000001976a914082a3adf4c8497fbd7d90f21cbec318b0dfdd2b288ace8030000000000001976a9144c53722fd5b0bc8a5b23ae4efc6233142b69d8ee88ace8030000000000001976a9146abd1edce61a7fdd2d134e8468560ecffb45334e88ace8030000000000001976a914dc3343b674cf2016b8968e6146ba5cc9228f14a488ace8030000000000001976a9145f395a91d07712604d7cd6fabd685b9bfd3900dd88ace8030000000000001976a914fc35239072cd5c19d9f761996951679fb03bb43188ace8030000000000001976a914b1ec1d5e0591abbbe3134c94c37e74d034b9312288ace8030000000000001976a9142d6351944aa38af6aa46d4a74cbb9016cf19ee7e88ace8030000000000001976a914879a49b3822806e0322565d457ce2b5989adaa6188ace8030000000000001976a9145ff26e3f8d542c5bb612e539649eaec0222afc3c88ace8030000000000001976a914105d54a4edcbe114a50bb01c79d230b7ed74a3e488ac00000000 >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -v -r 01000000014675ab74e5c496c8eecaaa87c6136bc68ebaaac7a25e70ee29b7bbaffad6810f000000008b4830450220296d4f4869a63efdee4c5ea31dcad559b4e03332462ba5442bfdf00a662cb77102210088a7f10361eae3e159ae6a8b5b7a569bf6bfa2de64fb3f5d0552f8be568ba6f50141042a9a97b2109ef496ffb1033576a5635cecc6ab679ad0b7c43d33ddf38b1f44c22ea42d5c01ac2752094ff81e79dda77d8b501a64102207c45fb89ea1ad9229ddffffffff23e8030000000000001976a914801314cd462b98c64dd4c3f4d6474cad11ea39d588ace8030000000000001976a9145bb7d22851413e1d61e8db5395a8c7c537256ea088ace8030000000000001976a914371f197d5ba5e32bd98260eec7f0e51227b6969088ace8030000000000001976a9143e546d0acc0de5aa3d66d7a920900ecbc66c203188ace8030000000000001976a9140337e0710056f114c9c469a68775498df9f9fa1688ace8030000000000001976a9149c628c82aa7b81da7c6a235049eb2979c4a65cfc88ace8030000000000001976a914cd1d7e863f891c493e093ada840ef5a67ad2d6cc88ace8030000000000001976a91476f074340381e6f8a40aec4a6e2d92485679412c88ace8030000000000001976a9140fb87a5071385b6976397d1c53ee16f09139a33488ace8030000000000001976a9143d37873ffd2964a1a4c8bade4852020ec5426d3688ace8030000000000001976a9145d14a857fce8da8edfb8f7d1c4bbc316622b722788ace8030000000000001976a9140a77fdb4cc81631b6ea2991ff60b47d57812d8e788ace8030000000000001976a91454514fe9251b5e381d13171cd6fca63f61d8b72688ace8030000000000001976a914cffe3e032a686cc3f2c9e417865afa8a52ed962b88ace8030000000000001976a914fd9dc3525076c1ffe9c33389ea157d07af2e41d488ace8030000000000001976a9143bedfe927d55a8c8adfe5e4b5dddd4ea3487b4c988ace8030000000000001976a914e49275e86ece605f271f26a9559520eb9c0ae8d888ace8030000000000001976a91469256ba90b0d7e406d86a51d343d157ff0aab7bd88ace8030000000000001976a9148ab0cb809cd893cb0cb16f647d024db94f09d76588ace8030000000000001976a9140688e383f02b528c92e25caae5785ffaa81a26aa88ace8030000000000001976a914d959be6c92037995558f43a55b1c271628f96e8d88ac8038f240000000001976a914d15e54e341d538ce3e9e7596e0dbcda8c12cc08988ace8030000000000001976a91495019a8168e8dcd2ef2d47ca57c1bf49358eb6fe88ace8030000000000001976a914caf67cfe28b511498b0d1792bedeec6b6e8a3c8d88ace8030000000000001976a914082a3adf4c8497fbd7d90f21cbec318b0dfdd2b288ace8030000000000001976a9144c53722fd5b0bc8a5b23ae4efc6233142b69d8ee88ace8030000000000001976a9146abd1edce61a7fdd2d134e8468560ecffb45334e88ace8030000000000001976a914dc3343b674cf2016b8968e6146ba5cc9228f14a488ace8030000000000001976a9145f395a91d07712604d7cd6fabd685b9bfd3900dd88ace8030000000000001976a914fc35239072cd5c19d9f761996951679fb03bb43188ace8030000000000001976a914b1ec1d5e0591abbbe3134c94c37e74d034b9312288ace8030000000000001976a9142d6351944aa38af6aa46d4a74cbb9016cf19ee7e88ace8030000000000001976a914879a49b3822806e0322565d457ce2b5989adaa6188ace8030000000000001976a9145ff26e3f8d542c5bb612e539649eaec0222afc3c88ace8030000000000001976a914105d54a4edcbe114a50bb01c79d230b7ed74a3e488ac00000000 > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= 348af0e1fa48b20486604a28f76d4eff3bee1bbbdcfd9b2b51684f70e2b9d838"

echo "TESTCASE 9c: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh -vv -r 01000000014675ab74e5c496c8eecaaa87c6136bc68ebaaac7a25e70ee29b7bbaffad6810f000000008b4830450220296d4f4869a63efdee4c5ea31dcad559b4e03332462ba5442bfdf00a662cb77102210088a7f10361eae3e159ae6a8b5b7a569bf6bfa2de64fb3f5d0552f8be568ba6f50141042a9a97b2109ef496ffb1033576a5635cecc6ab679ad0b7c43d33ddf38b1f44c22ea42d5c01ac2752094ff81e79dda77d8b501a64102207c45fb89ea1ad9229ddffffffff23e8030000000000001976a914801314cd462b98c64dd4c3f4d6474cad11ea39d588ace8030000000000001976a9145bb7d22851413e1d61e8db5395a8c7c537256ea088ace8030000000000001976a914371f197d5ba5e32bd98260eec7f0e51227b6969088ace8030000000000001976a9143e546d0acc0de5aa3d66d7a920900ecbc66c203188ace8030000000000001976a9140337e0710056f114c9c469a68775498df9f9fa1688ace8030000000000001976a9149c628c82aa7b81da7c6a235049eb2979c4a65cfc88ace8030000000000001976a914cd1d7e863f891c493e093ada840ef5a67ad2d6cc88ace8030000000000001976a91476f074340381e6f8a40aec4a6e2d92485679412c88ace8030000000000001976a9140fb87a5071385b6976397d1c53ee16f09139a33488ace8030000000000001976a9143d37873ffd2964a1a4c8bade4852020ec5426d3688ace8030000000000001976a9145d14a857fce8da8edfb8f7d1c4bbc316622b722788ace8030000000000001976a9140a77fdb4cc81631b6ea2991ff60b47d57812d8e788ace8030000000000001976a91454514fe9251b5e381d13171cd6fca63f61d8b72688ace8030000000000001976a914cffe3e032a686cc3f2c9e417865afa8a52ed962b88ace8030000000000001976a914fd9dc3525076c1ffe9c33389ea157d07af2e41d488ace8030000000000001976a9143bedfe927d55a8c8adfe5e4b5dddd4ea3487b4c988ace8030000000000001976a914e49275e86ece605f271f26a9559520eb9c0ae8d888ace8030000000000001976a91469256ba90b0d7e406d86a51d343d157ff0aab7bd88ace8030000000000001976a9148ab0cb809cd893cb0cb16f647d024db94f09d76588ace8030000000000001976a9140688e383f02b528c92e25caae5785ffaa81a26aa88ace8030000000000001976a914d959be6c92037995558f43a55b1c271628f96e8d88ac8038f240000000001976a914d15e54e341d538ce3e9e7596e0dbcda8c12cc08988ace8030000000000001976a91495019a8168e8dcd2ef2d47ca57c1bf49358eb6fe88ace8030000000000001976a914caf67cfe28b511498b0d1792bedeec6b6e8a3c8d88ace8030000000000001976a914082a3adf4c8497fbd7d90f21cbec318b0dfdd2b288ace8030000000000001976a9144c53722fd5b0bc8a5b23ae4efc6233142b69d8ee88ace8030000000000001976a9146abd1edce61a7fdd2d134e8468560ecffb45334e88ace8030000000000001976a914dc3343b674cf2016b8968e6146ba5cc9228f14a488ace8030000000000001976a9145f395a91d07712604d7cd6fabd685b9bfd3900dd88ace8030000000000001976a914fc35239072cd5c19d9f761996951679fb03bb43188ace8030000000000001976a914b1ec1d5e0591abbbe3134c94c37e74d034b9312288ace8030000000000001976a9142d6351944aa38af6aa46d4a74cbb9016cf19ee7e88ace8030000000000001976a914879a49b3822806e0322565d457ce2b5989adaa6188ace8030000000000001976a9145ff26e3f8d542c5bb612e539649eaec0222afc3c88ace8030000000000001976a914105d54a4edcbe114a50bb01c79d230b7ed74a3e488ac00000000 >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -vv -r 01000000014675ab74e5c496c8eecaaa87c6136bc68ebaaac7a25e70ee29b7bbaffad6810f000000008b4830450220296d4f4869a63efdee4c5ea31dcad559b4e03332462ba5442bfdf00a662cb77102210088a7f10361eae3e159ae6a8b5b7a569bf6bfa2de64fb3f5d0552f8be568ba6f50141042a9a97b2109ef496ffb1033576a5635cecc6ab679ad0b7c43d33ddf38b1f44c22ea42d5c01ac2752094ff81e79dda77d8b501a64102207c45fb89ea1ad9229ddffffffff23e8030000000000001976a914801314cd462b98c64dd4c3f4d6474cad11ea39d588ace8030000000000001976a9145bb7d22851413e1d61e8db5395a8c7c537256ea088ace8030000000000001976a914371f197d5ba5e32bd98260eec7f0e51227b6969088ace8030000000000001976a9143e546d0acc0de5aa3d66d7a920900ecbc66c203188ace8030000000000001976a9140337e0710056f114c9c469a68775498df9f9fa1688ace8030000000000001976a9149c628c82aa7b81da7c6a235049eb2979c4a65cfc88ace8030000000000001976a914cd1d7e863f891c493e093ada840ef5a67ad2d6cc88ace8030000000000001976a91476f074340381e6f8a40aec4a6e2d92485679412c88ace8030000000000001976a9140fb87a5071385b6976397d1c53ee16f09139a33488ace8030000000000001976a9143d37873ffd2964a1a4c8bade4852020ec5426d3688ace8030000000000001976a9145d14a857fce8da8edfb8f7d1c4bbc316622b722788ace8030000000000001976a9140a77fdb4cc81631b6ea2991ff60b47d57812d8e788ace8030000000000001976a91454514fe9251b5e381d13171cd6fca63f61d8b72688ace8030000000000001976a914cffe3e032a686cc3f2c9e417865afa8a52ed962b88ace8030000000000001976a914fd9dc3525076c1ffe9c33389ea157d07af2e41d488ace8030000000000001976a9143bedfe927d55a8c8adfe5e4b5dddd4ea3487b4c988ace8030000000000001976a914e49275e86ece605f271f26a9559520eb9c0ae8d888ace8030000000000001976a91469256ba90b0d7e406d86a51d343d157ff0aab7bd88ace8030000000000001976a9148ab0cb809cd893cb0cb16f647d024db94f09d76588ace8030000000000001976a9140688e383f02b528c92e25caae5785ffaa81a26aa88ace8030000000000001976a914d959be6c92037995558f43a55b1c271628f96e8d88ac8038f240000000001976a914d15e54e341d538ce3e9e7596e0dbcda8c12cc08988ace8030000000000001976a91495019a8168e8dcd2ef2d47ca57c1bf49358eb6fe88ace8030000000000001976a914caf67cfe28b511498b0d1792bedeec6b6e8a3c8d88ace8030000000000001976a914082a3adf4c8497fbd7d90f21cbec318b0dfdd2b288ace8030000000000001976a9144c53722fd5b0bc8a5b23ae4efc6233142b69d8ee88ace8030000000000001976a9146abd1edce61a7fdd2d134e8468560ecffb45334e88ace8030000000000001976a914dc3343b674cf2016b8968e6146ba5cc9228f14a488ace8030000000000001976a9145f395a91d07712604d7cd6fabd685b9bfd3900dd88ace8030000000000001976a914fc35239072cd5c19d9f761996951679fb03bb43188ace8030000000000001976a914b1ec1d5e0591abbbe3134c94c37e74d034b9312288ace8030000000000001976a9142d6351944aa38af6aa46d4a74cbb9016cf19ee7e88ace8030000000000001976a914879a49b3822806e0322565d457ce2b5989adaa6188ace8030000000000001976a9145ff26e3f8d542c5bb612e539649eaec0222afc3c88ace8030000000000001976a914105d54a4edcbe114a50bb01c79d230b7ed74a3e488ac00000000 > tmpfile
  result=$( $chksum_cmd tmpfile )
  echo $result
fi
chksum_verify "$result" "SHA256(tmpfile)= a54195209225363f1811139cb83daae78244eff7353ec233512af5d6bd1f8735"
echo " " | tee -a $logfile
}


testcase10() {
echo "TESTCASE 10a: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh > tmpfile
  $chksum_cmd tmpfile
fi

echo "TESTCASE 10b: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh -v >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -v > tmpfile
  $chksum_cmd tmpfile
fi

echo "TESTCASE 10c: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  ./trx2txt.sh -vv >> $logfile
  echo "##=======================================================================##" | tee -a $logfile
  echo " " | tee -a $logfile
else
  ./trx2txt.sh -vv > tmpfile
  $chksum_cmd tmpfile
fi
echo " " | tee -a $logfile
}


all_testcases() {
  testcase1 
  testcase2 
  testcase3 
  testcase4 
  testcase5 
  testcase6 
  testcase7 
  testcase8 
  testcase9 
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

case "$1" in
  -l|--log)
     LOG=1
     shift
     all_testcases
     ;;
  -?|-h|--help)
     echo "usage: trx_testcases.sh [1-8|-?|-h|--help|-l|--log]"
     echo "  "
     echo "script does several testcases, mostly with checksums for verification"
     echo "script accepts max one parameter !" 
     echo "  "
     exit 0
     ;;
  1|2|3|4|5|6|7|8|9)
     testcase$1 
     shift
     ;;
  *)
     all_testcases
     ;;
esac

