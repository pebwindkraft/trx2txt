#!/bin/sh
# tool to examine bitcoin transactions
#
# Copyright (c) 2015, 2016 Volker Nowarra 
# Coded in Nov/Dec 2015 following this reference:
#   https://en.bitcoin.it/wiki/Protocol_specification#tx
# 
# included example trx:
# https://blockchain.info/de/rawtx/
#  cc8a279b0736e6a2cc20b324acc5aa688b3af7b63bbb002f46f6573c1ad84408?format=hex
#
# Version	by	date	comment
# 0.1		svn	01jun16	initial release
# 0.2		svn	01jun16	added unsigned raw trx 
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

###########################
# Some variables ...      #
###########################
LOOPCOUNTER=0
TRX=''
RAW_TRX=''
RAW_TRX_LINK=https://blockchain.info/de/rawtx/cc8a279b0736e6a2cc20b324acc5aa688b3af7b63bbb002f46f6573c1ad84408
RAW_TRX_LINK2HEX="?format=hex"
RAW_TRX_DEFAULT=010000000253603b3fdb9d5e10de2172305ff68f4b5227310ba6bd81d4e1bf60c0de6183bc010000006a4730440220128487f04a591c43d7a6556fff9158999b46d6119c1a4d4cf1f5d0ac1dd57a94022061556761e9e1b1e656c0a70aa7b3e83454cd61662df61ebdc31e43196b5e0c10012102b12126a716ce7bbb84703bcfbf0afa80283c75a7304a48cd311a5027efd906c2ffffffff0e52c4701577287b6dd02f422c2a8033fa0b4614f75fa9f0a5c4ab69634b5ba7000000006b483045022100a428348ff55b2b59bc55ddacb1a00f4ecdabe282707ba5185d39fe9cdf05d7f0022074232dae76965b6311cea2d9e5708a0f137f4ea2b0e36d0818450c67c9ba259d0121025f95e8a33556e9d7311fa748e9434b333a4ecfb590c773480a196deab0dedee1ffffffff0290257300000000001976a914fca68658b537382e27a85522d292e1ad9543fe0488ac98381100000000001976a9146af1d17462c6146a8a61217e8648903acd3335f188ac00000000
USR_TRX=''
V_INT=0
VERBOSE=0
VVERBOSE=0

#################################
# procedure to display helptext #
#################################
proc_help() {
  echo "  "
  echo "usage: $0 [-h|-r|-t|-u|-v|-vv] [[raw]trx][...]"
  echo "  "
  echo "1. examine a raw trx into separate lines, as specified by:"
  echo "   https://en.bitcoin.it/wiki/Protocol_specification#tx"
  echo "2. create and/or sign a raw trx"
  echo "  "
  echo " -h   show this help text"
  echo " -r   examine RAW trx (requires hex data as a parameter string)"
  echo " -t   examine an existing TRX (requires TRANSACTION_ID, to fetch from blockchain.info)"
  echo " -u   examine UNSIGNED raw transaction (requires hex data as a parameter string)"
  echo " -v   display verbose output"
  echo " -vv  display even more verbose output"
  echo "  "
  echo " without parameter, a default transaction will be displayed"
  echo " "
  echo " "
  echo "�note: currently limited to 1 prev TRX_ID, with one input, and one output index"
  echo " "
}

############################################
# procedure to check trx length (=64chars) #
############################################
check_trx_len() {
  if [ ${#TRX} -ne 64 ] ; then
    echo "*** expecting a proper formatted Bitcoin TRANSACTION_ID."
    echo "    please provide a 64 bytes string (aka 32 hex chars) with '-t'."
    exit 0
  fi
}

#######################################
# procedure to display verbose output #
#######################################
v_output() {
  if [ $VERBOSE -eq 1 ] ; then
    echo $1
  fi
}

#################################################
# procedure to display even more verbose output #
#################################################
vv_output() {
  if [ $VVERBOSE -eq 1 ] ; then
    echo $1
  fi
}

#################################################
# procedure to reverse a hex data string        #
#################################################
# "s=s substr($0,i,1)" means that substr($0,i,1) is appended to the variable s; s=s+something
reverse_hex() {
  echo $1 | awk '{ for(i=length;i!=0;i=i-2)s=s substr($0,i-1,2);}END{print s}'
} 

###############################################################
# procedure to calculate value of var_int or compact size int #
###############################################################
# 
# var_int is defined as:
# value         size Format
# < 0xfd        1    uint8_t
# <= 0xffff     3    0xfd + uint16_t
# <= 0xffffffff 5    0xfe + uint32_t
# -             9    0xff + uint64_t 
# if value <= 0xfd, length = 2
# if value =  0xfd, offset = offset + 2, length = 4
# if value =  0xfe, offset = offset + 2, length = 8
# if value =  0xff, offset = offset + 2, length = 16
proc_var_int() {
  length=2
  to=$(( $offset + 1 ))
  V_INT=$( echo $RAW_TRX | cut -b $offset-$to )
  if [ "$V_INT" == "FD" ] ; then
    offset=$(( $offset + 2 ))
    to=$(( $offset + 3 ))
    V_INT=$( echo $RAW_TRX | cut -b $offset-$to )
    # big endian conversion!
    V_INT=$( reverse_hex $V_INT )
    offset=$(( $offset + 4 ))
  elif [ "$V_INT" == "FE" ] ; then
    offset=$(( $offset + 2 ))
    to=$(( $offset + 7 ))
    V_INT=$( echo $RAW_TRX | cut -b $offset-$to )
    # big endian conversion!
    V_INT=$( reverse_hex $V_INT )
    offset=$(( $offset + 8 ))
  elif [ "$V_INT" == "FF" ] ; then
    offset=$(( $offset + 2 ))
    to=$(( $offset + 15 ))
    V_INT=$( echo $RAW_TRX | cut -b $offset-$to )
    # big endian conversion!
    V_INT=$( reverse_hex $V_INT )
    offset=$(( $offset + 16 ))
  else
    offset=$(( $offset + 2 ))
  fi
}

#################################################
# procedure to display even more verbose output #
#################################################
decode_pkscript() {
    result=$( sh ./trx_out_pk_script.sh -q $1 )
    echo "$result"
    # only decode into bitcoin address, if
    #   $result=20 hex bytes length (40 chars)
    #   $result=65 hex bytes length (130 chars)
    # need to strip off any 2nd param (e.g. like "P2SH") for the length check
    result=$( echo "$result" | tail -n1 )
    len=$( echo $result | cut -d " " -f 1 )
    len=${#len}
    if [ $len -eq 130 ] ; then
      echo "and translates base58 encoded into this bitcoin address:"
      echo "sh ./trx_base58check_enc.sh -q -p1 $result"
      sh ./trx_base58check_enc.sh -q -p1 $result
    fi
    if [ $len -eq 66 ] ; then
      echo "and translates base58 encoded into this bitcoin address:"
      sh ./trx_base58check_enc.sh -q -p3 $result
    fi
    if [ $len -eq 40 ] ; then
      echo "and translates base58 encoded into this bitcoin address:"
      sh ./trx_base58check_enc.sh -q -p3 $result
    fi
}

echo "#################################################################"
echo "### trx2txt.sh: script to de-serialize/decode a Bitcoin trx   ###"
echo "#################################################################"
echo "  "

################################
# command line params handling #
################################

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
      -h)
         proc_help
         exit 0
         ;;
      -r)
         if [ "$TRX" ] || [ "$USR_TRX" ] ; then
           echo "*** you cannot use -r with any of -t|-u at the same time!"
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
      -t)
         if [ "$RAW_TRX" ] || [ "$USR_TRX" ] ; then
           echo "*** you cannot use -t with any of -r|-u at the same time!"
           echo " "
           exit 0
         fi
         if [ "$2" == ""  ] ; then
           echo "*** you must provide a Bitcoin TRANSACTION_ID to the -t parameter!"
           exit 0
         else
           TRX=$2
           shift 
         fi
         check_trx_len
         shift 
         ;;
      -u)
         if [ "$RAW_TRX" ] || [ "$TRX" ] ; then
           echo "*** you cannot use -u with any of -r|-t at the same time!"
           echo " "
           exit 0
         fi
         if [ "$2" == ""  ] ; then
           echo "*** you must provide an unsigned raw transaction to the -u parameter!"
           exit 0
         else
           USR_TRX=1  
           RAW_TRX=$2 
           shift 
         fi
         shift 
         ;;
      -v)
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
         echo "*** unknown parameter $1 "
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
  http_get_cmd="curl -sS -L "
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

vv_output "d.) tr ?"
which tr > /dev/null
if [ $? -eq 0 ]; then
  vv_output "    yes" 
else
  echo "*** tr not found, please install tr."
  echo "exiting gracefully ..." 
  exit 0
fi

vv_output "e.) dc ?"
which dc > /dev/null
if [ $? -eq 0 ]; then
  vv_output "    yes" 
else
  echo "dc not found, please install dc."
  echo "the tool can be used, but the option '-vv' will not work."
fi

vv_output "f.) sed ?"
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
# if param -t was given, then a Bitcoin TRANSACTION_ID should be in variable "TRX":
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
  if [ $OS == "Linux" ] ; then
    nw_if=$( netstat -rn | awk '/^0.0.0.0/ { print $NF }' | head -n1 )
    ifstatus $nw_if | grep -q "up"
  else
    nw_if=$( netstat -rn | awk '/^default/ { print $NF }' | head -n1 )
    ifconfig $nw_if | grep -q " active"
  fi
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
### STEP 1 - VERSION (8 chars) - Transaction data format version           ###
##############################################################################
### Size Data type 
###  4   uint32_t 
if [ "$VERBOSE" -eq 1 ] ; then
  echo " "
  echo "### VERSION"
fi
offset=1
to=$(( $offset + 7 ))
echo $RAW_TRX | cut -b $offset-$to 
offset=$(( $offset + 8 ))
 
##############################################################################
### STEP 2 - TX_IN COUNT, Number of Inputs (var_int)                       ###
##############################################################################
### Size Data type 
###  1+  var_int   
if [ "$VERBOSE" -eq 1 ] ; then
  echo " "
  echo "### TX_IN COUNT [var_int]"
fi
proc_var_int
tx_in_count_hex=$V_INT
tx_in_count_dec=$( echo "ibase=16; $tx_in_count_hex"|bc) 
if [ "$VERBOSE" -eq 1 ] ; then
  echo "hex=$tx_in_count_hex, dez=$tx_in_count_dec"
else
  echo $tx_in_count_hex
fi

while [ $LOOPCOUNTER -lt $tx_in_count_dec ]
 do
  ##############################################################################
  ### TX_IN, a data structure of one or more transaction inputs (var_int)    ###
  ##############################################################################
  ### Size Data type 
  ### 41+  tx_in[]   
  if [ "$VERBOSE" -eq 1 ] ; then
    echo " "
    echo "### TX_IN[$LOOPCOUNTER]"
  fi
  # TX_IN consists of the following fields:
  # Size Description       Data type Comments
  # 36   previous_output   outpoint, the previous output trx reference
  #      OutPoint structure: (The first output is 0, etc.)
  #      32   hash         char[32]  the hash of the referenced transaction (reversed).
  #       4   index        uint32_t  the index of the specific output in the transaction. 
  # 1+   script length     var_int   the length of the signature script
  # ?    signature script  uchar[]   script for confirming transaction authorization
  # 4    sequence          uint32_t  transaction version as defined by the sender. 
  #                                  intended for "replacement" of transactions when information 
  #                                  is updated before inclusion into a block. 
  if [ "$VERBOSE" -eq 1 ] ; then
    echo "###   OutPoint hash[$LOOPCOUNTER] (char[32])"
  fi
  ##############################################################################
  ### STEP 3 - TX_IN, previous output transaction hash: 32hex = 64 chars     ###
  ##############################################################################
  to=$(( $offset + 63 ))
  prev_trx=$( echo $RAW_TRX | cut -b $offset-$to )
  prev_trx=$( reverse_hex $prev_trx )
  echo $prev_trx
  offset=$(( $offset + 64 ))
  
  if [ "$VERBOSE" -eq 1 ] ; then
    echo "###   OutPoint index[$LOOPCOUNTER] (uint32_t)"
  fi
  # previous output index: 4hex = 8 chars
  to=$(( $offset + 7 ))
  echo $RAW_TRX | cut -b $offset-$to 
  offset=$(( $offset + 8 ))
  
  ##############################################################################
  ### STEP 4 - TX_IN, script length is var_int, 1-4 hex chars ...            ###
  ##############################################################################
  proc_var_int
  script_length_hex=$V_INT
  script_length_dez=$( echo "ibase=16; $script_length_hex"|bc) 
  if [ "$VERBOSE" -eq 1 ] ; then
    echo "###   Script Length[$LOOPCOUNTER] (var_int)"
    echo "hex=$script_length_hex, dez=$script_length_dez"
  else
    echo $script_length_hex
  fi
  length=$(($script_length_dez * 2 ))

  if [ "$VERBOSE" -eq 1 ] ; then
    echo "###   Script Sig[$LOOPCOUNTER] (uchar[])"
  fi
  ##############################################################################
  ### STEP 5 - TX_IN, signature script, first hex Byte is length (2 chars)   ###
  ##############################################################################
  # For unsigned raw transactions, this is temporarily filled with the scriptPubKey 
  # of the output. First a one-byte varint which denotes the length of the scriptSig 
  to=$(( $offset + $length - 1 ))
  sig_script=$( echo $RAW_TRX | cut -b $offset-$to )
  echo $sig_script 

  ##############################################################################
  ### STEP 6 - TX_IN, signature script, uchar[] - variable length            ###
  ##############################################################################
  if [ "$VVERBOSE" -eq 1 ] && [ "$length" -ne 0 ] ; then
    if [ "$USR_TRX" != "" ] ; then
      echo "This is USR_TRX, special code required - tbd"
      decode_pkscript $sig_script
    else
      ./trx_in_sig_script.sh -q $sig_script 
      echo " "
    fi
  fi
  offset=$(( $offset + $length ))
  v_output "###   Sequence[$LOOPCOUNTER] (uint32_t)"
  ##############################################################################
  ### STEP 7 - TX_IN, SEQUENCE: This is currently always set to 0xffffffff   ###
  ##############################################################################
  to=$(( $offset + 7 ))
  echo $RAW_TRX | cut -b $offset-$to 
  offset=$(( $offset + 8 ))

  LOOPCOUNTER=$(($LOOPCOUNTER + 1))
done

##############################################################################
### STEP 8 - TX_OUT, Number of Transaction outputs (var_int)               ###
##############################################################################
### Number of Transaction outputs
### Size Data type
###  1+  var_int   
### Explanation from bitcointalk.org forum: 
### A typical UTXO will have a script of the form: 
### "Tell me x and y where hash(x) = <bitcoin adr> and y is a valid signature for x". 
### To spend the UTXO, one needs to provide x and y satisfying the script, a feat 
### practically impossible without a corresponding private key. 

if [ "$VERBOSE" -eq 1 ] ; then
  echo " "
  echo "### TX_OUT COUNT"
fi
proc_var_int
tx_out_count_dez=$( echo "ibase=16; $V_INT"|bc) 
if [ "$VERBOSE" -eq 1 ] ; then
  echo "hex=$V_INT, dez=$tx_out_count_dez"
else
  echo $V_INT
fi
# offset=$(( $offset + 2 ))

LOOPCOUNTER=0
while [ $LOOPCOUNTER -lt $tx_out_count_dez ]
do
  ##############################################################################
  ### TX_OUT, a data structure of 1 or more transaction outputs or destinations 
  ##############################################################################
  ### Size Description      Data type  Comments
  ###  8   value 	          uint64_t   Transaction Value
  ###  1+  pk_script length var_int    Length of the pk_script
  ###  ?   pk_script        uchar[]    Usually contains the public key as a Bitcoin 
  ###                                  script setting up conditions to claim this output. 
  if [ "$VERBOSE" -eq 1 ] ; then
    echo " "
    echo "### TX_OUT[$LOOPCOUNTER]"
  fi

  ##############################################################################
  ### STEP 9 - TX_OUT, AMOUNT: a 4 bytes hex (8 chars) for the amount        ###
  ##############################################################################
  to=$(( $offset + 15 ))
  trx_value_hex=$( echo $RAW_TRX | cut -b $offset-$to )
  reverse=$( reverse_hex $trx_value_hex )

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
  offset=$(($offset + 16 ))

  ##############################################################################
  ### STEP 10 - TX_OUT, LENGTH: Number of bytes in the PK script (var_int)   ###
  ##############################################################################
  proc_var_int
  pk_script_length_hex=$V_INT
  pk_script_length_dez=$( echo "ibase=16; $pk_script_length_hex"|bc) 
  if [ "$VERBOSE" -eq 1 ] ; then
    echo "###   PK_Script Length[$LOOPCOUNTER] (var_int)"
    echo "hex=$pk_script_length_hex, dez=$pk_script_length_dez"
  else
    echo $pk_script_length_hex
  fi

  ##############################################################################
  ### STEP 11 - TX_OUT, PUBLIC KEY SCRIPT: the OP Codes of the PK script     ###
  ##############################################################################
  if [ "$VERBOSE" -eq 1 ] ; then
    echo "###   pk_script[$LOOPCOUNTER] (uchar[])"
  fi
  length=$(($pk_script_length_dez * 2 ))
  to=$(( $offset + $length - 1 ))
  pk_script=$(echo $RAW_TRX | cut -b $offset-$to )
  echo $pk_script

  if [ "$VVERBOSE" -eq 1 ] && [ $pk_script_length_dez -ne 0 ] ; then
    decode_pkscript $pk_script
  fi
  offset=$(($offset + $length))
  LOOPCOUNTER=$(($LOOPCOUNTER + 1))
done

##############################################################################
### STEP 12 - LOCK_TIME: block n� or timestamp at which this trx is locked ###
##############################################################################
### Size Data type 
###  4   uint32_t  
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
to=$(( $offset + 7 ))
echo $RAW_TRX | cut -b $offset-$to 

################################
### and here we are done :-) ### 
################################


