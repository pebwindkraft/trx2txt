#!/bin/sh
# convert a raw trx from blockchain.info into the separate parts, as specified by:
# 
# included example trx:
# https://blockchain.info/de/rawtx/
#  cc8a279b0736e6a2cc20b324acc5aa688b3af7b63bbb002f46f6573c1ad84408?format=hex
#
#
# Copyright (c) 2015, 2016 Volker Nowarra 
# Complete rewrite of code in Nov/Dec 2015 from following reference:
#   https://en.bitcoin.it/wiki/Protocol_specification#tx
# 
# 
# Permission to use, copy, modify, and distribute this software for any 
# purpose with or without fee is hereby granted, provided that the above 
# copyright notice and this permission notice appear in all copies. 
# 
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES 
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF 
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY 
# SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER 
# RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, 
# NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE 
# USE OR PERFORMANCE OF THIS SOFTWARE. 
# 

###########################
# Some variables ...      #
###########################
LOOPCOUNTER=0
TRX=''
RAW_TRX=''
RAW_TRX_LINK=https://blockchain.info/de/rawtx/cc8a279b0736e6a2cc20b324acc5aa688b3af7b63bbb002f46f6573c1ad84408
RAW_TRX_LINK2HEX="?format=hex"
RAW_TRX_DEFAULT=010000000253603b3fdb9d5e10de2172305ff68f4b5227310ba6bd81d4e1bf60c0de6183bc010000006a4730440220128487f04a591c43d7a6556fff9158999b46d6119c1a4d4cf1f5d0ac1dd57a94022061556761e9e1b1e656c0a70aa7b3e83454cd61662df61ebdc31e43196b5e0c10012102b12126a716ce7bbb84703bcfbf0afa80283c75a7304a48cd311a5027efd906c2ffffffff0e52c4701577287b6dd02f422c2a8033fa0b4614f75fa9f0a5c4ab69634b5ba7000000006b483045022100a428348ff55b2b59bc55ddacb1a00f4ecdabe282707ba5185d39fe9cdf05d7f0022074232dae76965b6311cea2d9e5708a0f137f4ea2b0e36d0818450c67c9ba259d0121025f95e8a33556e9d7311fa748e9434b333a4ecfb590c773480a196deab0dedee1ffffffff0290257300000000001976a914fca68658b537382e27a85522d292e1ad9543fe0488ac98381100000000001976a9146af1d17462c6146a8a61217e8648903acd3335f188ac00000000
VERBOSE=0
VVERBOSE=0

proc_help() {
  echo "  "
  echo "usage: trx2txt.sh [-h|--help|-r|--rawtrx|-t|--trx|-v|--verbose|-vv] [[raw]trx]"
  echo "  "
  echo "convert a raw trx into separate lines, as specified by:"
  echo "https://en.bitcoin.it/wiki/Protocol_specification#tx"
  echo "  "
  echo " -h|--help     show this help text"
  echo " -r|--rawtrx   requires hex data from a raw transaction "
  echo " -t|--trx      requires hash of a trx (64 Bytes) to fetch from blockchain.info"
  echo " -v|--verbose  display verbose output"
  echo " -vv           display even more verbose output"
  echo "  "
  echo " without parameter, a default transaction will be displayed"
  echo " "
}

v_output() {
  if [ $VERBOSE -eq 1 ] ; then
    echo $1
  fi
}

vv_output() {
  if [ $VVERBOSE -eq 1 ] ; then
    echo $1
  fi
}

################################
# command line params handling #
################################

echo "#################################################################"
echo "### trx2txt.sh: script to de-serialize/decode a Bitcoin trx   ###"
echo "#################################################################"
echo "  "

if [ $# -eq 0 ] ; then
  echo "no parameter(s) given, using defaults"
  echo " "
  echo "alternativly, try --help"
  echo " "
  RAW_TRX=$RAW_TRX_DEFAULT
else
  while [ $# -ge 1 ] 
   do
    case "$1" in
      -h | --help)
         proc_help
         exit 0
         ;;
      -r | --rawtrx)
         if [ "$TRX" ] ; then
           echo "*** you cannot use -t and -r at the same time!"
           echo " "
           exit 0
         fi
         if [ "$2" == ""  ] ; then
           echo "*** you must provide a string to the -r parameter!"
           exit 0
         else
           RAW_TRX=$2
           shift 
         fi
         shift 
         ;;
      -t | --trx)
         if [ "$RAW_TRX" ] ; then
           echo "*** you cannot use -r and -t at the same time!"
           echo " "
           exit 0
         fi
         if [ "$2" == ""  ] ; then
           echo "*** you must provide a string to the -t parameter!"
           exit 0
         else
           TRX=$2
           shift 
         fi
         if [ ${#TRX} -ne 64 ] ; then
           echo "*** Bitcoin protocol requires a proper formatted trx."
           echo "please provide a 64 bytes hex string with '-t'."
           exit 0
         fi
         shift 
         ;;
      -v | --verbose)
         VERBOSE=1
         echo "VERBOSE output turned on"
         if [ "$2" == ""  ] ; then
           RAW_TRX=$RAW_TRX_DEFAULT
         fi
         shift
         ;;
      -vv)
         VERBOSE=1
         VVERBOSE=1
         echo "VVERBOSE and VERBOSE output turned on"
         if [ "$2" == ""  ] ; then
           RAW_TRX=$RAW_TRX_DEFAULT
         fi
         shift
         ;;
      *)  # No more options
         echo "unknown parameter $1 "
         proc_help
         exit 1
         # break
         ;;
    esac
  done
fi

# verify operating system, cause 
# Linux wants to have "--posix" for their gawk program ...
http_get_cmd="echo " 
OS=$(uname)
if [ $OS == "OpenBSD" ] ; then
  awk_cmd=awk 
  http_get_cmd="ftp -M -V -o - "
fi
if [ $OS == "Darwin" ] ; then
  awk_cmd=$(which awk) 
  http_get_cmd="curl -sS -L "
fi
if [ $OS == "Linux" ] ; then
  awk_cmd="awk --posix" 
  http_get_cmd="curl "
fi

v_output "#########################################"
v_output "### Check if necessay tools are there ###"
v_output "#########################################"
vv_output "a.) awk ?"
which awk > /dev/null
if [ $? -eq 0 ]; then
  vv_output "    yes" 
else
  echo "*** awk not found, please install awk."
  echo "exiting gracefully ..." 
  exit 0
fi

vv_output "b.) openssl ?" 
which openssl > /dev/null
if [ $? -eq 0 ]; then
  vv_output "    yes"
else
  echo "openssl not found, please install openssl."
  echo "the tool can be used, but the option '-vv' will not work."
fi

vv_output "c.) bc ?"
which bc > /dev/null
if [ $? -eq 0 ]; then
  vv_output "    yes" 
else
  echo "*** bc not found, please install bc."
  echo "exiting gracefully ..." 
  exit 0
fi

vv_output "d.) dc ?"
which dc > /dev/null
if [ $? -eq 0 ]; then
  vv_output "    yes" 
else
  echo "dc not found, please install dc."
  echo "the tool can be used, but the option '-vv' will not work."
fi

vv_output "e.) sed ?"
which sed > /dev/null
if [ $? -eq 0 ]; then
  vv_output "    yes" 
else
  echo "sed not found, please install sed."
  echo "the tool can be used, but the option '-vv' will not work."
fi

###############################################
### Check if network is required and active ###
###############################################
# 
# if param -t was given, then a trx string should be in variable "TRX":
#   ./trx2txt -t cc8a279b0736e6a2cc20b324acc5aa688b3af7b63bbb002f46f6573c1ad84408
# 
# no we need to:
# 1.) check if network interface is active ...
# 2.) go to the network, like this:
#     https://blockchain.info/de/rawtx/cc8a279b07...3c1ad84408?format=hex
# 3.) use OS specific calls:
#     OpenBSD: ftp -M -V -o - https://blockchain.info/de/rawtx/...
# 4.) pass everything into the variable "RAW_TRX"
# 
if [ "$TRX" ] ; then
  echo "###############################################"
  echo "### Check if network is required and active ###"
  echo "###############################################"
  v_output "working with this TRX: $TRX"
  nw_if=$( netstat -rn | awk '/^default/ { print $NF }' | head -n1 )
  ifconfig $nw_if | grep -q " active"
  if [ $? -eq 0 ] ; then
    v_output "network interface is active, good"
    v_output "trying to fetch data from blockchain.info"
    RAW_TRX=$( $http_get_cmd https://blockchain.info/de/rawtx/$TRX$RAW_TRX_LINK2HEX )
    if [ $? -ne 0 ] ; then
      echo "*** error - fetching RAW_TRX data:"
      echo "    $http_get_cmd https://blockchain.info/de/rawtx/$TRX$RAW_TRX_LINK2HEX"
      echo "    downoad manually, and call 'trx2txt -r ...'"
      exit 1
    fi
    if [ ${#RAW_TRX} -eq 0 ] ; then
      echo "*** The raw trx has a length of 0. Something failed."
      echo "    downoad manually, and call 'trx2txt -r ...'"
      exit 0
    fi
  else
    echo "*** error - no network connection"
    echo "    check 'netstat -rn' default gateway, and 'ifconfig'"
    exit 1
  fi
fi

RAW_TRX=$( echo $RAW_TRX | tr [:lower:] [:upper:] )
v_output "raw trx is this:"
v_output $RAW_TRX
echo "###################"
echo "### so let's go ###"
echo "###################"


##############################################################################
### VERSION
### Transaction data format version
### Size Data type 
###  4   uint32_t 
##############################################################################
if [ "$VERBOSE" -eq 1 ] ; then
  echo " "
  echo "### VERSION"
fi
length=8
offset=1
echo $RAW_TRX | awk -v off=$offset -v len=$length '{ print substr($0, off, len) }'
offset=$(($offset + $length))
 
##############################################################################
### TX_IN COUNT 
### Number of Transaction inputs
### Size Data type 
###  1+  var_int   
##############################################################################
if [ "$VERBOSE" -eq 1 ] ; then
  echo " "
  echo "### TX_IN COUNT"
fi
# 
# var_int is defined as:
# value         size Format
# < 0xfd        1    uint8_t
# <= 0xffff     3    0xfd + uint16_t
# <= 0xffffffff 5    0xfe + uint32_t
# -             9    0xff + uint64_t 
# if value eq negative, length = 18
# if ${RAW_TRX:offset:1} == "negative" then length = 18
# if value <= 0xffffffff, length = 10
# if ${RAW_TRX:offset:4} == "ffff" then length = 10
# if value <= 0xffff, length = 6
# if ${RAW_TRX:offset:1} == "f" and ${RAW_TRX:offset+1:1} == "d" then length = 6
length=2
# tx_in_count_hex=$( echo ${RAW_TRX:offset:length} )
tx_in_count_hex=$( echo $RAW_TRX | awk -v off=$offset -v len=$length '{ print substr($0, off, len) }' )
tx_in_count_dez=$( echo "ibase=16; $tx_in_count_hex"|bc) 
if [ "$VERBOSE" -eq 1 ] ; then
  echo "hex=$tx_in_count_hex, dez=$tx_in_count_dez"
else
  echo $tx_in_count_hex
fi
offset=$(($offset + $length))

while [ $LOOPCOUNTER -lt $tx_in_count_dez ]
do
  ##############################################################################
  ### TX_IN 
  ### A list of 1 or more transaction inputs or sources for coins
  ### Size Data type 
  ### 41+  tx_in[]   
  ##############################################################################
  if [ "$VERBOSE" -eq 1 ] ; then
    echo " "
    echo "### TX_IN[$LOOPCOUNTER]"
  fi
  # txin consists of the following fields:
  # Size Description       Data type Comments
  # 36   previous_output   outpoint  The previous output trx reference, as an OutPoint structure
  # 1+   script length     var_int   The length of the signature script
  # ?    signature script  uchar[]   Script for confirming transaction authorization
  # 4    sequence          uint32_t  Transaction version as defined by the sender. 
  #                                  Intended for "replacement" of transactions when information 
  #                                  is updated before inclusion into a block. 
  #
  # The OutPoint structure consists of the following fields:
  # Size Descr. Data type Comments
  # 32   hash   char[32] 	The hash of the referenced transaction.
  # 4    index  uint32_t 	The index of the specific output in the transaction. 
  #                       The first output is 0, etc. 
  if [ "$VERBOSE" -eq 1 ] ; then
    echo "###   OutPoint hash[$LOOPCOUNTER] (char[32])"
  fi
  length=64
  echo $RAW_TRX | awk -v off=$offset -v len=$length '{ print substr($0, off, len) }'
  offset=$(($offset + $length))
  
  if [ "$VERBOSE" -eq 1 ] ; then
    echo "###   OutPoint index[$LOOPCOUNTER] (uint32_t)"
  fi
  length=8
  echo $RAW_TRX | awk -v off=$offset -v len=$length '{ print substr($0, off, len) }'
  offset=$(($offset + $length))
  
  # var_int is defined as:
  # value         size Format
  # < 0xfd        1    uint8_t
  # <= 0xffff     3    0xfd + uint16_t
  # <= 0xffffffff 5    0xfe + uint32_t
  # -             9    0xff + uint64_t 
  # if value eq negative, length = 18
  # if ${RAW_TRX:offset:1} == "negative" then length = 18
  # if value <= 0xffffffff, length = 10
  # if ${RAW_TRX:offset:4} == "ffff" then length = 10
  # if value <= 0xffff, length = 6
  # if ${RAW_TRX:offset:1} == "f" and ${RAW_TRX:offset+1:1} == "d" then length = 6
  length=2
  # script_length_hex=$( echo ${RAW_TRX:offset:length} )
  script_length_hex=$( echo $RAW_TRX | awk -v off=$offset -v len=$length '{ print substr($0, off, len) }' )
  script_length_dez=$( echo "ibase=16; $script_length_hex"|bc) 
  if [ "$VERBOSE" -eq 1 ] ; then
    echo "###   Script Length[$LOOPCOUNTER] (var_int)"
    echo "hex=$script_length_hex, dez=$script_length_dez"
  else
    echo $script_length_hex
  fi
  offset=$(($offset + $length))
  length=$(($script_length_dez * 2 ))

  if [ "$VERBOSE" -eq 1 ] ; then
    echo "###   Script Sig[$LOOPCOUNTER] (uchar[])"
  fi
  sig_script=$(echo $RAW_TRX | awk -v off=$offset -v len=$length '{ print substr($0, off, len) }' )
  echo $sig_script 
  if [ "$VVERBOSE" -eq 1 ] ; then
    # echo $sig_script | $awk_cmd -f trx_in_sig_script.awk
    ./trx_in_sig_script.sh -q $sig_script 
    echo " "
  fi
  offset=$(($offset + $length))
 
  if [ "$VERBOSE" -eq 1 ] ; then
    echo "###   Sequence[$LOOPCOUNTER] (uint32_t)"
  fi
  length=8
  echo $RAW_TRX | awk -v off=$offset -v len=$length '{ print substr($0, off, len) }'
  offset=$(($offset + $length))

  LOOPCOUNTER=$(($LOOPCOUNTER + 1))
done

##############################################################################
### TX_OUT COUNT 
### Number of Transaction outputs
### Size Data type
###  1+  var_int   
### Explanation from bitcointalk.org forum: 
### A typical UTXO will have a script of the form: 
### "Tell me x and y where hash(x) = <bitcoin adr> and y is a valid signature for x". 
### To spend the UTXO, one needs to provide x and y satisfying the script, a feat 
### practically impossible without a corresponding private key. 
##############################################################################
if [ "$VERBOSE" -eq 1 ] ; then
  echo " "
  echo "### TX_OUT COUNT"
fi
# 
# var_int is defined as:
# value         size Format
# < 0xfd        1    uint8_t
# <= 0xffff     3    0xfd + uint16_t
# <= 0xffffffff 5    0xfe + uint32_t
# -             9    0xff + uint64_t 
# if value eq negative, length = 18
# if ${RAW_TRX:offset:1} == "negative" then length = 18
# if value <= 0xffffffff, length = 10
# if ${RAW_TRX:offset:4} == "ffff" then length = 10
# if value <= 0xffff, length = 6
# if ${RAW_TRX:offset:1} == "f" and ${RAW_TRX:offset+1:1} == "d" then length = 6
length=2
# tx_out_count_hex=$( echo ${RAW_TRX:offset:length} )
tx_out_count_hex=$( echo $RAW_TRX | awk -v off=$offset -v len=$length '{ print substr($0, off, len) }' )
tx_out_count_dez=$( echo "ibase=16; $tx_out_count_hex"|bc) 
if [ "$VERBOSE" -eq 1 ] ; then
  echo "hex=$tx_out_count_hex, dez=$tx_out_count_dez"
else
  echo $tx_out_count_hex
fi
offset=$(($offset + $length))

LOOPCOUNTER=0
while [ $LOOPCOUNTER -lt $tx_out_count_dez ]
do
  ##############################################################################
  ### TX_OUT
  ### A list of 1 or more transaction outputs or destinations for coins
  ### Size Data type
  ###  8+  tx_out[]  
  ##############################################################################
  if [ "$VERBOSE" -eq 1 ] ; then
    echo " "
    echo "### TX_OUT[$LOOPCOUNTER]"
  fi

  # The TxOut structure consists of the following fields:
  # Size Description      Data type  Comments
  #  8   value 	          uint64_t   Transaction Value
  #  1+  pk_script length var_int    Length of the pk_script
  #  ?   pk_script        uchar[]    Usually contains the public key as a Bitcoin 
  #                                  script setting up conditions to claim this output. 

  length=16
  trx_value_hex=$( echo $RAW_TRX | awk -v off=$offset -v len=$length '{ print substr($0, off, len) }' )

  # reverse the trx value (hex) string, so BC can eat it to convert to dez value
  #
  # for some reason a loop in a while loop crashes my ksh, 
  # so have to do "manual loops" :-)
  #
  reverse=""
  reverse=$reverse$( echo $trx_value_hex | awk '{ print substr($0, 15, 2) }' )
  reverse=$reverse$( echo $trx_value_hex | awk '{ print substr($0, 13, 2) }' )
  reverse=$reverse$( echo $trx_value_hex | awk '{ print substr($0, 11, 2) }' )
  reverse=$reverse$( echo $trx_value_hex | awk '{ print substr($0, 9, 2) }' )
  reverse=$reverse$( echo $trx_value_hex | awk '{ print substr($0, 7, 2) }' )
  reverse=$reverse$( echo $trx_value_hex | awk '{ print substr($0, 5, 2) }' )
  reverse=$reverse$( echo $trx_value_hex | awk '{ print substr($0, 3, 2) }' )
  reverse=$reverse$( echo $trx_value_hex | awk '{ print substr($0, 1, 2) }' )
  echo "$reverse"

  trx_value_dez=$(echo "ibase=16; $reverse"|bc) 
  # try to get it in bitcoin notation
  len=${#trx_value_dez}
  if [ $len -lt 8 ] ; then
    trx_value_bitcoin="0"$(echo "scale=8; $trx_value_dez / 100000000;" | bc)
  else
    trx_value_bitcoin=$(echo "scale=8; $trx_value_dez / 100000000;" | bc)
  fi
  if [ "$VERBOSE" -eq 1 ] ; then
    echo "###   TRX Value[$LOOPCOUNTER] (uint64_t)"
    echo "hex=$trx_value_hex, reversed_hex=$reverse, dez=$trx_value_dez, bitcoin=$trx_value_bitcoin"
  else
    echo $trx_value_hex
  fi
  offset=$(($offset + $length))

  # var_int is defined as:
  # value         size Format
  # < 0xfd        1    uint8_t
  # <= 0xffff     3    0xfd + uint16_t
  # <= 0xffffffff 5    0xfe + uint32_t
  # -             9    0xff + uint64_t 
  # if value eq negative, length = 18
  # if ${RAW_TRX:offset:1} == "negative" then length = 18
  # if value <= 0xffffffff, length = 10
  # if ${RAW_TRX:offset:4} == "ffff" then length = 10
  # if value <= 0xffff, length = 6
  # if ${RAW_TRX:offset:1} == "f" and ${RAW_TRX:offset+1:1} == "d" then length = 6
  #
  length=2
  # pk_script_length_hex=$( echo ${RAW_TRX:offset:length} )
  pk_script_length_hex=$( echo $RAW_TRX | awk -v off=$offset -v len=$length '{ print substr($0, off, len) }' )
  pk_script_length_dez=$( echo "ibase=16; $pk_script_length_hex"|bc) 
  if [ "$VERBOSE" -eq 1 ] ; then
    echo "###   PK_Script Length[$LOOPCOUNTER] (var_int)"
    echo "hex=$pk_script_length_hex, dez=$pk_script_length_dez"
  else
    echo $pk_script_length_hex
  fi
  offset=$(($offset + $length))

  if [ "$VERBOSE" -eq 1 ] ; then
    echo "###   pk_script[$LOOPCOUNTER] (uchar[])"
  fi
  length=$(($pk_script_length_dez * 2 ))
  pk_script=$(echo $RAW_TRX | awk -v off=$offset -v len=$length '{ print substr($0, off, len) }' )
  echo $pk_script

  if [ "$VVERBOSE" -eq 1 ] && [ $pk_script_length_dez -ne 0 ] ; then
    result=$( sh ./trx_out_pk_script.sh -q $pk_script )
    echo "$result"
    # only decode into bitcoin address, if we have 20 hex bytes length (40 chars)
    # seems like bitcoin addresses can have also other length, but for now ... :-)
    # need to strip off any 2nd param (e.g. like "P2SH") for the length check
    result=$( echo "$result" | tail -n1 )
    len=$( echo $result | cut -d " " -f 1 )
    len=${#len}
    if [ $len -eq 40 ] ; then
      echo "and translates base58 encoded into this bitcoin address:"
      sh ./base58check_enc.sh -q $result
    fi
  fi
  offset=$(($offset + $length))
  LOOPCOUNTER=$(($LOOPCOUNTER + 1))
done

##############################################################################
### LOCK_TIME
### The block number or timestamp at which this transaction is locked:
### Size Data type 
###  4   uint32_t  
##############################################################################
###      Value        Description
###      0            Always locked
###      < 500000000  Block number at which this transaction is locked
###      >= 500000000 UNIX timestamp at which this transaction is locked
###      A non-locked transaction must not be included in blocks, and 
###      it can be modified by broadcasting a new version before the 
###      time has expired (replacement is currently disabled in Bitcoin, 
###      however, so this is useless). 
### 
if [ "$VERBOSE" -eq 1 ] ; then
  echo " "
  echo "### LOCK_TIME"
fi
length=8
# echo ${RAW_TRX:offset:length} 
echo $RAW_TRX | awk -v off=$offset -v len=$length '{ print substr($0, off, len) }' 

################################
### and here we are done :-) ### 
################################


