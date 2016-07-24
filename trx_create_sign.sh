#!/bin/sh
# tool to create a raw, unsigned bitcoin transaction or 
# sign any unsigned raw transaction
# 
# Copyright (c) 2015, 2016 Volker Nowarra 
# Coded in June 2016 following this reference:
#   https://en.bitcoin.it/wiki/Protocol_specification#tx
#   http://bitcoin.stackexchange.com/questions/3374/how-to-redeem-a-basic-tx
# 
#
# Version	by	date	comment
# 0.1		svn	22jul16	initial release
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
# https://en.bitcoin.it/wiki/Elliptic_Curve_Digital_Signature_Algorithm:
# signature: A number that proves that a signing operation took place. A signature 
# is mathematically generated from a hash of something to be signed, plus a private 
# key. The signature itself is two numbers known as r and s. With the public key, a 
# mathematical algorithm can be used on the signature to determine that it was 
# originally produced from the hash and the private key, without needing to know 
# the private key. Signatures are either 73, 72, or 71 bytes long, with probabilities
# approximately 25%, 50% and 25% respectively, although sizes even smaller than that
# are possible with exponentially decreasing probability.
#
#
###########################
# Some variables ...      #
###########################
QUIET=0
VERBOSE=0
VVERBOSE=0

typeset -i i=0
PREV_TRX=''
RAW_TRX=''
RAW_TRX_LINK2HEX="?format=hex"
SIGNED_TRX=''

hex_privkey=''
wif_privkey=''
C_PARAM_FLAG=0
M_PARAM_FLAG=0
S_PARAM_FLAG=0
T_PARAM_FLAG=0
STEPCODE=''
SCRIPTSIG=''

#################################
# procedure to display helptext #
#################################
proc_help() {
  echo "  "
  echo "create usage: $0 [-h|-q|-v|-vv] -c -m|-t <trx_id> <params>"
  echo "sign usage:   $0 [-h|-q|-v|-vv] -s -u <raw_trx> -w|-x <privkey> -p <pubkey>"
  echo "  "
  echo " -h  show this HELP text"
  echo " -q  real QUIET mode, don't display anything"
  echo " -v  display VERBOSE output"
  echo " -vv display VERY VERBOSE output"
  echo " "
  echo " -c  CREATE an unsigned, raw trx."
  echo " -m  MANUALLY provide all <params> (see below)"
  echo "     You need to know and provide all parameters as per below"
  echo " -p  public key (UNCOMPRESSED or COMPRESSED) in hex format"
  echo " -t  previous TRANSACTION_ID: fetch trx_id from blockchain.info"
  echo " -u  next param is an unsigned raw transaction"
  echo " -w  next param is a WIF or WIF-C encoded private key (51 or 52 chars)"
  echo " -x  next param is a HEX encoded private key (32Bytes=64chars)"
  echo " "
  echo " <params> consists of these details (keep the order!):"
  echo "  1) <prev output index> : output index from previous TRX_ID"
  echo "  2) <prev pubkey script>: only with "-m": the PUBKEY SCRIPT from previous TRX_ID"
  echo "  3) <amount>            : the amount to spend (decimal, in Satoshi)"
  echo "                           *** careful: input - output = trx fee !!!"
  echo "  4) <address>           : the target Bitcoin address"
  echo " "
  echo "limited to 1 prev TRX_ID, with one prev output index, and one address"
  echo "  "
}

#######################################
# procedure to display verbose output #
#######################################
v_output() {
  if [ $VERBOSE -eq 1 ] ; then
    echo "$1"
  fi
}

#################################################
# procedure to display even more verbose output #
#################################################
vv_output() {
  if [ $VVERBOSE -eq 1 ] ; then
    echo "$1"
  fi
}

#################################################
# procedure to concatenate string for raw trx   #
#################################################
trx_concatenate() {
  RAW_TRX=$RAW_TRX$STEPCODE
  vv_output "$RAW_TRX"
  vv_output " "
}

##########################################
# procedure to reverse a hex data string #
##########################################
# "s=s substr($0,i,1)" means that substr($0,i,1) 
# is appended to the variable s; s=s+something
reverse_hex() {
  echo $1 | awk '{ for(i=length;i!=0;i=i-2)s=s substr($0,i-1,2);}END{print s}'
} 

##########################################################
# to stay with portable code, use zero paddin function ###
##########################################################
zero_pad(){
  # zero_pad <string> <length>
  [ ${#1} -lt $2 ] && printf "%0$(($2-${#1}))d" ''
  printf "%s" "$1"
}

##########################################
# procedure to check for necessary tools #
##########################################
check_tool() {
  vv_output "$1 ?"
  which $1 > /dev/null
  if [ $? -eq 0 ]; then
    vv_output "    yes" 
  else
    echo "*** $1 not found, please install $1."
    echo "exiting gracefully ..." 
    exit 0
  fi
}

##########################################
# procedure to check for necessary tools #
##########################################
leading_zeros() {
  # get the length of the string h, and if not 'even', add a beginning 
  # zero. Background: we need to convert the hex characters to a hex value, 
  # and need to have an even amount of characters... 
  len=${#h}
  s=`expr $len % 2`
  if [ $s -ne 0 ] ; then
    h=$( echo "0$h" )
  fi
  len=${#h}
  echo "after mod 2 calc, h=$h"
} 

#####################################################
# procedure to calculate the checksum of an address #
#####################################################
#
get_chksum() {
# this is not working properly on other UNIXs, made it more "transportable"
# chksum_f8=$( xxd -p -r <<<"00$h" |
# openssl dgst -sha256 -binary |
# openssl dgst -sha256 -binary |
# xxd -p -c 80 |
# head -c 8 |
# tr [:lower:] [:upper:] )
  # Step 4 - add network byte
  chksum_f8=$( echo "00$h" | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
  printf $chksum_f8 > tmpfile
  # Step 5 - hash 256
  openssl dgst -sha256 -binary tmpfile > tmpfile1
  # Step 6 - another hash 256
  openssl dgst -sha256 -binary tmpfile1 > tmpfile
  # Step 7 - get first 4 Bytes (8 chars) as the checksum
  chksum_f8=$( od -An -t x1 tmpfile | tr -d [[:blank:]] | tr -d "\n" | 
               cut -b 1-8 | tr [:lower:] [:upper:] )
}

echo "######################################################################"
echo "### trx_create_sign.sh: create or sign a raw, unsigned Bitcoin trx ###"
echo "######################################################################"

################################
# command line params handling #
################################

if [ "$1" == "-h" ] ; then
  proc_help
  exit 0
fi  

if [ $# -lt 4 ] ; then
  echo "insufficient parameter(s) given... "
  echo " "
  proc_help
  exit 0
else
  while [ $# -ge 1 ] 
   do
    case "$1" in
      -c)
         C_PARAM_FLAG=1
         echo "  [-c] param given, creating a raw, unsigned trx"
         shift 
         ;;
      -m)
         M_PARAM_FLAG=1
         if [ $# -lt 6 ] ; then
           echo "*** you must provide correct number of parameters"
           proc_help
           exit 1
         fi
         if [ $T_PARAM_FLAG -eq 1 ] ; then
           echo "*** you cannot use -m with -t at the same time."
           echo "    Exiting gracefully ... "
           exit 1
         fi
         if [ "$2" == ""  ] ; then
           echo "*** you must provide a Bitcoin TRANSACTION_ID to the -t parameter!"
           exit 1
         fi
         PREV_TRX=$2
         PREV_TRX_OutPoint=$3
         PREV_PKSCRIPT=$4
         AMOUNT=$5
         TARGET_ADDRESS=$6
         shift 
         shift 
         shift 
         shift 
         shift 
         shift 
         ;;
      -p)
         pubkey=$2
         shift
         shift
         ;;
      -q)
         QUIET=1
         shift
         ;;
      -s)
         S_PARAM_FLAG=1
         echo "  [-s] param given, sign a raw, unsigned trx"
         shift
         ;;
      -t)
         T_PARAM_FLAG=1
         if [ $# -lt 5 ] ; then
           echo "*** you must provide correct number of parameters"
           proc_help
           exit 0
         fi
         if [ $M_PARAM_FLAG -eq 1 ] ; then
           echo "*** you cannot use -t with -m at the same time!"
           echo "    Exiting gracefully ... "
           exit 0
         fi
         if [ "$2" == ""  ] ; then
           echo "*** you must provide a Bitcoin TRANSACTION_ID to the -t parameter!"
           exit 0
         fi
         PREV_TRX=$2
         PREV_TRX_OutPoint=$3
         AMOUNT=$4
         TARGET_ADDRESS=$5
         shift 
         shift 
         shift 
         shift 
         shift 
         ;;
      -u)
         if [ "$2" == ""  ] ; then
           echo "*** you must provide a Bitcoin TRANSACTION_ID to the -u parameter!"
           exit 0
         fi
         RAW_TRX=$2
         shift
         shift
         ;;
      -v)
         VERBOSE=1
         echo "VERBOSE output turned on"
         shift
         ;;
      -vv)
         VERBOSE=1
         VVERBOSE=1
         echo "VERY VERBOSE and VERBOSE output turned on"
         shift
         ;;
      -w)
         if [ "$hex_privkey" ] ; then 
           echo "*** cannot use -w and -x at the same time, exiting gracefully ..."
           exit 1
         fi
         wif_privkey=$2
         if [ ${#wif_privkey} -ne 51 ] && [ ${#wif_privkey} -ne 52 ] ; then 
           echo "*** wrong privkey length (${#wif_privkey}), must be 51 or 52 chars"
           exit 1
         fi
         shift
         shift
         ;;
      -x)
         if [ "$wif_privkey" ] ; then 
           echo "*** cannot use -x and -w at the same time, exiting gracefully ..."
           exit 1
         fi
         hex_privkey=$2
         if [ ${#hex_privkey} -ne 64 ] ; then 
           echo "*** wrong privkey length (${#hex_privkey}), must be 64 chars (32 Bytes)"
           exit 1
         fi
         shift
         shift
         ;;
      *)
         echo "unknown parameter(s), don't know what to do. Exiting gracefully ..."
         proc_help
         exit 1
         ;;
    esac
  done
fi


###############################################
### Check length of provided trx characters ###
###############################################
if [ "$T_PARAM_FLAG" -eq 1 ] && [ ${#PREV_TRX} -ne 64 ] ; then
  echo "*** expecting a proper formatted Bitcoin TRANSACTION_ID."
  echo "    Please provide a 64 bytes string (aka 32 hex chars)"
  echo "    current length:"
  ${#PREV_TRX}
  exit 1
fi

if [ "$M_PARAM_FLAG" -eq 1 ] ; then
  vv_output "PREV_TRX=$PREV_TRX"
  vv_output "PREV_TRX_OutPoint=$PREV_TRX_OutPoint"
  vv_output "PREV_PKSCRIPT=$PREV_PKSCRIPT"
  vv_output "AMOUNT=$AMOUNT"
  vv_output "TARGET_ADDRESS=$TARGET_ADDRESS"
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

vv_output "##########################################"
vv_output "### Check if necessary tools are there ###"
vv_output "##########################################"
check_tool awk
check_tool bc
check_tool cut
check_tool dc
check_tool openssl
check_tool sed
check_tool tr

# echo "###################"
# echo "### so let's go ###"
# echo "###################"

###############################################
### Check if network is required and active ###
###############################################
# 
# if we create a trx, and param -t was given, then a 
# Bitcoin TRANSACTION_ID should be in variable "PREV_TRX":
# 
# now we need to:
# 1.) check if network interface is active ...
# 2.) go to the network, like this:
#     https://blockchain.info/de/rawtx/cc8a279b07...3c1ad84408?format=hex
# 3.) use OS specific calls:
#     OpenBSD: ftp -M -V -o - https://blockchain.info/de/rawtx/...
# 4.) pass everything into the variable "RAW_TRX"
# 
if [ "$T_PARAM_FLAG" -eq 1 ] ; then
  echo "###############################################"
  echo "### Check if network is required and active ###"
  echo "###############################################"
  v_output "working with this TRX: $PREV_TRX"
  if [ $OS == "Linux" ] ; then
    nw_if=$( netstat -rn | awk '/^0.0.0.0/ { print $NF }' | head -n1 )
    ifstatus $nw_if | grep -q "up"
  else
    nw_if=$( netstat -rn | awk '/^default/ { print $NF }' | head -n1 )
    ifconfig $nw_if | grep -q " active"
  fi
  # check if we can reach www.blockchain.info
  v_output "checking ping to www.blockchain.info"
  ping -c1 www.blockchain.info > /dev/zero
  if [ $? -eq 1 ] ; then
    echo "*** error: www.blockchain.info not reachable"
    echo "    verify your network settings, or assemble trx manually [-m]"
    echo "    exiting gracefully ... "
    exit 1
  fi
  if [ $? -eq 0 ] ; then
    v_output "network interface is active, good"
    v_output "trying to fetch data from blockchain.info"
    RAW_TRX=$( $http_get_cmd https://blockchain.info/de/rawtx/$PREV_TRX$RAW_TRX_LINK2HEX )
    if [ $? -ne 0 ] ; then
      echo "*** error - fetching RAW_TRX data:"
      echo "    $http_get_cmd https://blockchain.info/de/rawtx/$PREV_TRX$RAW_TRX_LINK2HEX"
      echo "    downoad manually, and call 'trx2txt -r ...'"
      exit 1
    fi
    if [ ${#RAW_TRX} -eq 0 ] ; then
      echo "*** The raw trx has a length of 0. Something failed."
      echo "    downoad manually, and call 'trx2txt -r ...'"
      exit 1
    fi
  else
    echo "*** error - no network connection"
    echo "    check 'netstat -rn' default gateway, and 'ifconfig'"
    exit 1
  fi
  #  if param "-t" is given, then we this shall be executed:
  #    ./trx2txt.sh -vv -r $RAW_TRX | grep -A7 TX_OUT[$PREV_TRX_OutPoint] > tmp_rawtx.txt
  #  It would come back with this data, where we can grep / fetch:
  #  
  #  1--> ### TX_OUT[1]
  #       000000000001B1FC
  #       ###   TRX Value[1] (uint64_t)
  #       hex=FCB1010000000000, reversed_hex=000000000001B1FC, dez=111100, bitcoin=0.00111100
  #       ###   PK_Script Length[1] (var_int)
  #  2--> hex=19, dez=25
  #  3--> ###   pk_script[1] (uchar[])
  #       76A9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988AC
  #       ...
  #  
  #  1--> used to be in the right output ($PREV_TRX_OutPoint)
  #  2--> used for STEP 5, need to grep and cut
  #  3--> used for STEP 6, need to grep -A1 -B1 pk_script[$PREV_TRX_OutPoint]
  #  
  echo "./trx2txt.sh -vv -r $RAW_TRX | grep -A7 TX_OUT[$PREV_TRX_OutPoint] > tmp_rawtx.txt"
  ./trx2txt.sh -vv -r $RAW_TRX | grep -A7 TX_OUT[[]$PREV_TRX_OutPoint[]] > tmp_rawtx.txt
  T_FLAG_STEP5_VAL=$( grep -A1 -B1 pk_script tmp_rawtx.txt | head -n1 | cut -b 5,6 )
  T_FLAG_STEP6_VAL=$( grep -A1 -B1 pk_script tmp_rawtx.txt | tail -n1 )
  RAW_TRX=''
fi

if [ "$C_PARAM_FLAG" -eq 1 ] ; then
  ##############################################################################
  ### STEP 1 - VERSION (8 chars) - Add four-byte version field               ###
  ##############################################################################
  v_output " "
  v_output "###  1. VERSION"
  STEPCODE="01000000"
  trx_concatenate
  
  ##############################################################################
  ### STEP 2 - TX_IN COUNT, One-byte varint specifying the number of inputs  ###
  ##############################################################################
  v_output "###  2. TX_IN COUNT"
  STEPCODE="01"
  trx_concatenate
  
  ##############################################################################
  ### STEP 3 - TX_IN, previous transaction hash: 32hex = 64 chars            ###
  ##############################################################################
  v_output "###  3. TX_IN, previous transaction hash"
  v_output "previous trx hash=$PREV_TRX"
  STEPCODE=$( reverse_hex $PREV_TRX )
  v_output "reversed trx hash=$STEPCODE"
  trx_concatenate
  
  ##############################################################################
  ### STEP 4 - TX_IN, the output index we want to redeem from                ###
  ##############################################################################
  v_output "###  4. TX_IN, the output index we want to redeem from"
  # does not work with bash 4 - grrrrrrrr
  # STEPCODE=$( printf "%08s" $(echo "obase=16;$PREV_TRX_OutPoint"|bc -l) )
  STEPCODE=$( echo "obase=16;$PREV_TRX_OutPoint"|bc -l)
  STEPCODE=$( zero_pad $STEPCODE 8 )
  STEPCODE=$( reverse_hex $STEPCODE )
  v_output "convert from $PREV_TRX_OutPoint (the output index parameter) to reversed hex: $STEPCODE"
  trx_concatenate
  
  ##############################################################################
  ### STEP 5 - TX_IN, scriptsig length: first hex Byte is length (2 chars)   ###
  ##############################################################################
  # For the purpose of signing the transaction, this is temporarily filled 
  # with the scriptPubKey of the output we want to redeem. 
  v_output "###  5. TX_IN, scriptsig length: first hex Byte is length (2 chars)"
  if [ $T_PARAM_FLAG -eq 0 ] ; then
    STEPCODE="19"
  else
    vv_output "STEPCODE=$T_FLAG_STEP5_VAL"
    STEPCODE=$T_FLAG_STEP5_VAL
  fi 
  trx_concatenate
  
  ##############################################################################
  ### STEP 6 - TX_IN, signature script, uchar[] - variable length            ###
  ##############################################################################
  # the actual scriptSig (which is the scriptPubKey of the PREV_TRX
  v_output "###  6. TX_IN, signature script, uchar[] - variable length"
  if [ $T_PARAM_FLAG -eq 0 ] ; then
    STEPCODE=$PREV_PKSCRIPT
    vv_output "$STEPCODE"
  else
    vv_output "STEPCODE=$T_FLAG_STEP6_VAL"
    STEPCODE=$T_FLAG_STEP6_VAL
  fi 
  trx_concatenate
  
  ##############################################################################
  ### STEP 7 - TX_IN, SEQUENCE: This is currently always set to 0xffffffff   ###
  ##############################################################################
  # This is currently always set to 0xffffffff
  v_output "###  7. TX_IN, This is currently always set to 0xffffffff"
  STEPCODE="ffffffff"
  trx_concatenate
  
  ##############################################################################
  ### STEP 8 - TX_OUT, Number of Transaction outputs (var_int)               ###
  ##############################################################################
  # This is per default set to 1 
  v_output "###  8. TX_OUT, Number of Transaction outputs (var_int)"
  STEPCODE="01"
  trx_concatenate
  
  ##############################################################################
  ### STEP 9 - TX_OUT, AMOUNT: a 4 bytes hex (8 chars) for the amount        ###
  ##############################################################################
  # a 8-byte reversed hex field, e.g.: 3a01000000000000"
  # does not work with bash 4 - grrrrrrrr
  # STEPCODE=$( printf "%016s" $(echo "obase=16;$AMOUNT"|bc -l) )
  STEPCODE=$(echo "obase=16;$AMOUNT"|bc -l) 
  STEPCODE=$( zero_pad $STEPCODE 16 )
  v_output "###  9. TX_OUT, decimal amount=$AMOUNT, in hex=$STEPCODE"
  STEPCODE=$( reverse_hex $STEPCODE ) 
  v_output "                reversed=$STEPCODE"
  v_output "                be careful: amount(TX_IN) - amount(TX_OUT) = TRX fee !"
  trx_concatenate
  
  ##############################################################################
  ### STEP 10 - TX_OUT, LENGTH: Number of bytes in the PK script (var_int)   ###
  ##############################################################################
  # pubkey script length, we use 0x19 here ...
  v_output "### 10. TX_OUT, LENGTH: Number of bytes in the PK script (var_int)"
  STEPCODE="19"
  trx_concatenate
  
  ##############################################################################
  ### STEP 11 - TX_OUT, PUBLIC KEY SCRIPT: the OP Codes of the PK script     ###
  ##############################################################################
  # convert parameter TARGET_ADDRESS to the pubkey script.
  # the P2PKH script is preceeded with "76A914" and ends with "88AC":
  #
  # bitcoin-tools.sh have this logic, which only works in bash. I changed
  # it to also work in ksh (more POISX compliant)
  # decodeBase58() {
  #     echo -n "$1" | sed -e's/^\(1*\).*/\1/' -e's/1/00/g' | tr -d '\n'
  #     dc -e "$dcr 16o0$(sed 's/./ 58*l&+/g' <<<$1)p" |
  #     while read n; do echo -n ${n/\\/}; done
  # }
  #
  v_output "### 11. TX_OUT, PUBLIC KEY SCRIPT: the OP Codes of the PK script"
  s=$TARGET_ADDRESS 
  echo $s | awk -f trx_verify_bc_address.awk
  if [ $? -eq 1 ] ; then
    echo "*** ERROR: could not recognize valid bitcoin address"
    echo "    exiting gracefully ..."
    exit 1
  fi 

  s=$( echo $s | awk -f trx_base58.awk )
  vv_output "$s"
  s=$( echo $s | sed 's/[0-9]*/ 58*&+ /g' )
  vv_output "$s"
  h=$( echo "16o0d $s +f" | dc )
  vv_output "$h"

  # separating the hash value (last 8 chars) of this string
  len=${#h}
  from=`expr $len - 7`
  chksum_l8=$( echo $h | cut -b $from-$len )
  # vv_output "chksum_l8 (last 8 chars): $chksum_l8"
  
  # checksum verification: 
  # remove last 8 chars ('the checksum'), double sha256 the string, and the 
  # first 8 chars should match the value from $chksum_l8. 
  to=`expr $len - 8`
  h=$( echo $h | cut -b 1-$to )

  # First find the length of the string, and if not 'even', add a beginning 
  # zero. Background: we need to convert the hex characters to a hex value, 
  # and need to have an even amount of characters... 
  leading_zeros

  get_chksum
  if [ "$chksum_f8" != "$chksum_l8" ] ; then
    # try max 10 iterations for leading zeros ...
    i=0
    while [ $i -lt 10 ] 
     do
      h=$( echo "0$h" )
      leading_zeros
      echo "h=$h, f8=$chksum_f8, l8=$chksum_l8"
      get_chksum
      if [ "$chksum_f8" == "$chksum_l8" ] ; then
        vv_output "calculated chksum of $h: $chksum_f8 == $chksum_l8"
        i=10
        break
      fi
      i=`expr $i + 1`
    done
    if [ "$chksum_f8" != "$chksum_l8" ] ; then
      echo "*** calculated chksum of $h: $chksum_f8 != $chksum_l8"
      echo "*** looks like an invalid bitcoin address"
      exit 1
    fi
  fi
  STEPCODE=$h
  STEPCODE=$( echo "76A914"$STEPCODE )
  STEPCODE=$( echo $STEPCODE"88AC")
  trx_concatenate
  
  ############################################################################
  ### STEP 12 - LOCK_TIME: block nor timestamp at which this trx is locked ###
  ############################################################################
  v_output "### 12. LOCK_TIME: block nor timestamp at which this trx is locked"
  STEPCODE="00000000" 
  trx_concatenate
  
  ##############################################################################
  ### STEP 13 - HASH CODE TYPE                                               ###
  ##############################################################################
  v_output "### 13. HASH CODE TYPE"
  STEPCODE="01000000" 
  trx_concatenate
  
  echo " "
  echo "$RAW_TRX" | tr [:upper:] [:lower:] > tmp_urtx.txt
  echo "###########################################################################"
  echo "here we have created a unsigned raw transaction into file 'tmp_urtx.txt'."
  echo "Take this file on a clean USB stick to the cold storage (second computer),"
  echo "and sign it there ... "
  echo " "
  echo "$RAW_TRX" | tr [:upper:] [:lower:] 
  echo " "
  echo "you may also want to verify things here with 'cat tmp_urtx.txt', "
  echo "and cut&paste output to './trx2txt.sh -vv -u <hextrx>' command"
  echo "###########################################################################"
  exit 0
fi

##############################################################################
### STEP 14 - SINGLE HASH the raw unsigned trx                             ###
##############################################################################
v_output "### 14. DOUBLE HASH the raw unsigned trx"

# Bitcoin never does sha256 with the hex chars, so ned to convert it to hex codes first
echo "$RAW_TRX" | tr [:upper:] [:lower:] > tmp_urtx.txt
result=$( cat tmp_urtx.txt | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
printf $result > tmp_urtx.raw
openssl sha256 <tmp_urtx.raw -binary >tmp_urtx_sha256.raw
openssl sha256 <tmp_urtx_sha256.raw -binary >tmp_urtx_dsha256.raw

if [ "$VVERBOSE" -eq 1 ] ; then 
  echo " "
  echo "the RAW_TRX"
  echo $RAW_TRX
  echo "the unsigned raw trx, sha256'd (tmp_urtx_sha256.raw):"
  hexdump -C tmp_urtx_sha256.raw
  echo "the unsigned raw trx, double sha256'd (tmp_urtx_dsha256.raw):"
  hexdump -C tmp_urtx_dsha256.raw
  echo " "
fi

##############################################################################
### STEP 15 - OpenSSL sign the hash from step 14 with the private key      ###
##############################################################################
# 15. We then create a public/private key pair out of the provided private key. 
#     We sign the hash from step 14 with the private key. 
#     and add the one byte hash code "01" to it's end.
v_output "### 15. sign the hash from step 14 with the private key"
# verify keys are working correctly ...
if [ "$hex_privkey" ] ; then 
  ./trx_key2pem.sh -q -x $hex_privkey -p $pubkey 
  if [ $? -eq 1 ] ; then 
    echo "*** error in key handling, exiting gracefully ..."
    exit 1
  fi
else
  ./trx_key2pem.sh -q -w $wif_privkey -p $pubkey 
  if [ $? -eq 1 ] ; then 
    echo "*** error in key handling, exiting gracefully ..."
    exit 1
  fi
fi

vv_output "-->openssl dgst -sha256 -sign privkey.pem -out tmp_trx.sig tmp_urtx_sha256.raw"
openssl dgst -sha256 -sign privkey.pem -out tmp_trx.sig tmp_urtx_sha256.raw
SCRIPTSIG=$( od -An -t x1 tmp_trx.sig | tr -d [:blank:] | tr -d "\n" )
vv_output $SCRIPTSIG
vv_output " "

# make sure, SIG has correct parts - this is "Bitcoin" specific... 
# SIG is <r><s> concatenated together. An s value greater than N/2 
# is not allowed. Need to add code: if s -gt N/2 ; then s = N - s
# N is the curve order: 
# N hex:   FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
# N hex/2: 7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
# N dec:   115792089237316195423570985008687907852837564279074904382605163141518161494337
# N dec/2:  57896044618658097711785492504343953926418782139537452191302581570759080747168
#

# A correct DER-encoded signature has the following form:
# 
#   0x30: a header byte indicating a compound structure.
#   A 1-byte length descriptor for all what follows.
#   0x02: a header byte indicating an integer.
#   A 1-byte length descriptor for the R value
#   The R coordinate, as a big-endian integer.
#   0x02: a header byte indicating an integer.
#   A 1-byte length descriptor for the S value.
#   The S coordinate, as a big-endian integer.
#    
#        // Minimum and maximum size constraints.
#        if (sig.size() < 9) return false;
#        if (sig.size() > 73) return false;
#    
#        // A signature is of type 0x30 (compound).
#        if (sig[0] != 0x30) return false;
#    
#        // Make sure the length covers the entire signature.
#        if (sig[1] != sig.size() - 3) return false;
#    
#        // Extract the length of the R element.
#        unsigned int lenR = sig[3];
#    
#        // Make sure the length of the S element is still inside the signature.
#        if (5 + lenR >= sig.size()) return false;
#    
#        // Extract the length of the S element.
#        unsigned int lenS = sig[5 + lenR];
#    
#        // Verify that the length of the signature matches the sum of the length
#        // of the elements.
#        if ((size_t)(lenR + lenS + 7) != sig.size()) return false;
#     
#        // Check whether the R element is an integer.
#        if (sig[2] != 0x02) return false;
#    
#        // Zero-length integers are not allowed for R.
#        if (lenR == 0) return false;
#    
#        // Negative numbers are not allowed for R.
#        if (sig[4] & 0x80) return false;
#    
#        // Null bytes at the start of R are not allowed, unless R would
#        // otherwise be interpreted as a negative number.
#        if (lenR > 1 && (sig[4] == 0x00) && !(sig[5] & 0x80)) return false;
#    
#        // Check whether the S element is an integer.
#        if (sig[lenR + 4] != 0x02) return false;
#    
#        // Zero-length integers are not allowed for S.
#        if (lenS == 0) return false;
#    
#        // Negative numbers are not allowed for S.
#        if (sig[lenR + 6] & 0x80) return false;
#    
#        // Null bytes at the start of S are not allowed, unless S would otherwise be
#        // interpreted as a negative number.
#        if (lenS > 1 && (sig[lenR + 6] == 0x00) && !(sig[lenR + 7] & 0x80)) return false;
#    
#        return true;
#    }
#    
##############################################################################
### STEP 16 - construct the final scriptSig                                ###
##############################################################################
# 16. We construct the final scriptSig by concatenating: 
v_output "### 16. construct the final scriptSig"
# a: <One-byte script OPCODE containing the length of the DER-encoded signature plus 1>
#       (for the one byte has code)
STEPCODE=$( wc -c < "tmp_trx.sig" )
STEPCODE=$( echo "obase=16;$STEPCODE + 1" | bc )
# b: <The actual DER-encoded signature plus the one-byte hash code type>
SCRIPTSIG=$STEPCODE$SCRIPTSIG
STEPCODE=01
SCRIPTSIG=$SCRIPTSIG$STEPCODE
# c: <One-byte script OPCODE containing the length of the public key>
STEPCODE=${#pubkey}
vv_output "len pubkey=$STEPCODE (Chars)"
STEPCODE=$( echo "obase=16;$STEPCODE / 2" | bc )
vv_output "in hex=$STEPCODE (Bytes)"
SCRIPTSIG=$SCRIPTSIG$STEPCODE
# d: <The actual public key>
SCRIPTSIG=$SCRIPTSIG$pubkey
vv_output $SCRIPTSIG
vv_output " "

##############################################################################
### STEP 17 - replace len from step 5 with the len of data from step 16    ###
##############################################################################
# 17. We then replace the one-byte, varint length-field from step 5 with the length of 
#     the data from step 16. The length is in chars, devide it by 2 and convert to hex.
# 
v_output "### 17. replace len from step 5 with the len of data from step 16"
STEPCODE=${#SCRIPTSIG} 
vv_output "len SCRIPTSIG=$STEPCODE (Chars)"
STEPCODE=$( echo "obase=16;$STEPCODE / 2" | bc )
vv_output "in hex=$STEPCODE (Bytes)"
# the new signed transaction will be composed, here steps 1,2,3 and 4:
# len STEP1 = VERSION         -->  4 Bytes -->  8 chars
# len STEP2 = VARINT!         -->  1 Byte  -->  2 chars
# len STEP3 = prevaddresshash --> 32 Bytes --> 64 chars
# len STEP4 = output index    -->  4 Bytes -->  8 chars
# total                                        82 chars
SIGNED_TRX=$( echo $RAW_TRX | cut -b 1-82 )
SIGNED_TRX=$SIGNED_TRX$STEPCODE
vv_output $SIGNED_TRX
vv_output " "

##############################################################################
### STEP 18 - replace scriptSig with the data structure of step 16         ###
##############################################################################
# 18. And we replace the actual scriptSig with the data structure constructed in step 16. 
#     We use the old scriptsig, go 82 chars forward, skip 1 byte (2 chars) for the 
#     length, and 25Bytes (50chars) for the P2PKH script --> 82 + 52 (+1) = 135
#     we take everything from 135 til end and attach behind new script sig.
# 
#     hint: when making a raw trx with Bitcoin QT, length is different (84)
# 010000000167cc10a3b7c5c52435770b6a1cb34a6a783803f028c42e95f9364d21e64b43c30000000000ffffffff01ec8a0100000000001976a9140de4457d577bb45dee513bb695bdfdc3b34d467d88ac0000000001000000

v_output "### 18. replace scriptSig with the data structure of step 16"
SIGNED_TRX=$SIGNED_TRX$SCRIPTSIG
STEPCODE=$( echo $RAW_TRX | cut -b 135- )
SIGNED_TRX=$SIGNED_TRX$STEPCODE
vv_output $SIGNED_TRX
vv_output " "

##############################################################################
### STEP 19 - remove four-byte hash code type from step 13                 ###
##############################################################################
# 19. We finish off by removing the four-byte hash code type we added in step 13, 
# and we end up with the following stream of bytes, which is the final transaction:
# construct the final scriptSig by concatenating: 
#   <One-byte script OPCODE (length of the DER-encoded signature plus 1)>
#   <The actual DER-encoded signature plus the one-byte hash code type>
#   <One-byte script OPCODE containing the length of the public key>
#   <The actual public key>
v_output "### 19. remove four-byte hash code type from step 13"
STEPCODE=${#SIGNED_TRX}
STEPCODE=$( echo "$STEPCODE - 8" | bc )
SIGNED_TRX=$( echo $SIGNED_TRX | cut -b 1-$STEPCODE )
echo $SIGNED_TRX

################################
### and here we are done :-) ### 
################################


