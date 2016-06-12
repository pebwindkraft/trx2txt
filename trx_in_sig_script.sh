#!/bin/sh
##############################################################################
# Read the bitcoin script_SIG OPCODES from a transaction's TRX_IN 
# script by Sven-Volker Nowarra 
# 
# Version	by	date	comment
# 0.1		svn	11jun16	initial release
# 
# Copyright (c) 2015, 2016 Volker Nowarra 
# Complete rewrite of code in June 2016 from following reference:
#   https://en.bitcoin.it/wiki/Protocol_specification#tx
#   https://en.bitcoin.it/wiki/Script
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

QUIET=0
param=483045022100A428348FF55B2B59BC55DDACB1A00F4ECDABE282707BA5185D39FE9CDF05D7F0022074232DAE76965B6311CEA2D9E5708A0F137F4EA2B0E36D0818450C67C9BA259D0121025F95E8A33556E9D7311FA748E9434B333A4ECFB590C773480A196DEAB0DEDEE1

case "$1" in
  -q)
     QUIET=1
     shift
     ;;
  -?|-h|--help)
     echo "usage: trx_in_sig_script.sh [-?|-h|--help|-q] hex_string"
     echo "  "
     echo "convert a raw hex string from a bitcoin trx-out into it's OpCodes. "
     echo "if no parameter is given, the data from a demo trx is used. "
     echo "  "
     exit 0
     ;;
  *)
     ;;
esac

if [ $QUIET -eq 0 ] ; then 
  echo "################################################################"
  echo "### trx_in_sig_script.sh: read SIG_script OPCODES from a trx ###"
  echo "################################################################"
  echo "  "
fi

if [ $# -eq 0 ] ; then 
  if [ $QUIET -eq 0 ] ; then 
    echo "no parameter, hence showing example pk_script:"
    echo "$param"
  fi
else 
  param=$( echo $1 | tr "[:lower:]" "[:upper:]" )
fi

###################
### GET ADDRESS ###
###################
# supporting web sites:
# https://en.bitcoin.it/wiki/
#         Technical_background_of_version_1_Bitcoin_addresses#How_to_create_Bitcoin_Address
# http://gobittest.appspot.com/Address
get_address() {
    result=$( echo $ret_string | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
    result=$( printf "$result" | openssl dgst -sha256 | cut -d " " -f 2 )
    result=$( echo $result | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
    result=$( printf "$result" | openssl dgst -rmd160 | cut -d " " -f 2 )
    ./base58check_enc.sh -q $result
}
############################################################
### procedure to show data following an "OP_DATA" opcode ###
############################################################
op_data_show() {
  ret_string=''
  n=1
  output=
  while [ $n -le $cur_opcode_dec ]
   do
    output=$output${opcode_ar[offset]}
    ret_string=$ret_string${opcode_ar[offset]}
    if [ $n -eq 8 ] || [ $n -eq 24 ] || [ $n -eq 40 ] || [ $n -eq 56 ] ; then 
      output=$output":"
    fi
    if [ $n -eq 16 ] || [ $n -eq 32 ] || [ $n -eq 48 ] || [ $n -eq 64 ] ; then 
      echo "       $output" 
      output=
    fi
    n=$(( n + 1 ))
    offset=$(( offset + 1 ))
  done 
  echo "       $output" 
}

#####################
### GET NEXT CODE ###
#####################
get_next_opcode() {
  cur_opcode=${opcode_ar[offset]}
  cur_hexcode="0x"$cur_opcode
  cur_opcode_dec=$( echo "ibase=16;$cur_opcode" | bc )
  # echo "offset=$offset, opcode=$cur_opcode, opcode_dec=$cur_opcode_dec"
  offset=$(( offset + 1 ))
}

#####################################
### STATUS 1 (S1_OP_Data_0x47)    ###
#####################################
S1_OP_Data_0x47() {
  get_next_opcode
  case $cur_opcode in
    30) echo "   $cur_opcode: OP_Length_0x30"
        S5_Sequence
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 2 (S2_OP_Data_0x48)    ###
#####################################
S2_OP_Data_0x48() {
  get_next_opcode
  case $cur_opcode in
    30) echo "   $cur_opcode: OP_Length_0x30"
        S12_Sequence
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 3 (S3_OP_Data_0x21)    ###
#####################################
S3_OP_Data_0x21() {
  # get_next_opcode
  cur_opcode=${opcode_ar[offset]}
  case $cur_opcode in
    02) echo "   $cur_opcode: OP_INT_0x02"
        S19_PK   
        ;;
    03) echo "   $cur_opcode: OP_INT_0x03"
        S19_PK   
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 4 (S4_OP_Data_0x41)    ###
#####################################
S4_OP_Data_0x41() {
  # get_next_opcode
  cur_opcode=${opcode_ar[offset]}
  case $cur_opcode in
    41) echo "   $cur_opcode: OP_Length_0x41"
        S20_PK 
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 5 (S5_Sequence)        ###
#####################################
S5_Sequence() {
  get_next_opcode
  case $cur_opcode in
    44) echo "   $cur_opcode: OP_Length_0x44"
        op_data_show
        S6_Length 
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 6 (S6_Length)          ###
#####################################
S6_Length() {
  get_next_opcode
  case $cur_opcode in
    01) echo "   $cur_opcode: OP_SIGHASHALL *** This terminates the signature"
        S11_SIG 
        ;;
    02) echo "   $cur_opcode: OP_INT_0x02"
        S7_Int 
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 7 (S7_Int)             ###
#####################################
S7_Int() {
  get_next_opcode
  case $cur_opcode in
    20) echo "   $cur_opcode: OP_LENGTH_0x20 *** this is SIG X"
        op_data_show
        S8_SIG_X
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 8 (S8_SIG_X)           ###
#####################################
S8_SIG_X() {
  get_next_opcode
  case $cur_opcode in
    02) echo "   $cur_opcode: OP_INT_0x02"
        S9_Int 
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 9 (S9_Int)             ###
#####################################
S9_Int() {
  get_next_opcode
  case $cur_opcode in
    20) echo "   $cur_opcode: OP_LENGTH_0x20 *** this is SIG Y"
        op_data_show
        S10_Sig_Y 
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 10 (S10_SIG_Y)         ###
#####################################
S10_SIG_Y() {
  get_next_opcode
  case $cur_opcode in
    01) echo "   $cur_opcode: OP_SIGHASHALL *** This terminates the sigs"
        S11_SIG 
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 11 (S11_SIG)           ###
#####################################
S11_SIG() {
    echo " "
}
#####################################
### STATUS 12 (S12_Sequence)      ###
#####################################
S12_Sequence () {
  get_next_opcode
  case $cur_opcode in
    45) echo "   $cur_opcode: OP_LENGTH_0x45"
        S13_Length
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 13 (S13_Length)        ###
#####################################
S13_Length() {
  get_next_opcode
  case $cur_opcode in
    02) echo "   $cur_opcode: OP_INT_0x02"
        S14_Int 
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 14 ()                  ###
#####################################
S14_Int() {
  get_next_opcode
  case $cur_opcode in
    21) echo "   $cur_opcode: OP_LENGTH_0x21 *** this is SIG X"
        op_data_show
        S15_SIG_X 
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 15 (S15_SIG_X)         ###
#####################################
S15_SIG_X() {
  get_next_opcode
  case $cur_opcode in
    02) echo "   $cur_opcode: OP_INT_0x02"
        S16_Int 
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 16 (S16_Int)           ###
#####################################
S16_Int() {
  get_next_opcode
  case $cur_opcode in
    20) echo "   $cur_opcode: OP_LENGTH_0x20 *** this is SIG Y"
        op_data_show
        S17_SIG_Y
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 17 (S17_SIG_Y)         ###
#####################################
S17_SIG_Y() {
  get_next_opcode
  case $cur_opcode in
    01) echo "   $cur_opcode: OP_SIGHASHALL *** This terminates the sigs"
        S18_SIG 
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 18 (S18_SIG)           ###
#####################################
S18_SIG() {
    echo " "
}
#####################################
### STATUS 19 (S19_PK)            ###
#####################################
S19_PK() {
    cur_opcode_dec=33
    op_data_show
    echo "* This is Public ECDSA Key, corresponding bitcoin address is:"
    get_address
}
#####################################
### STATUS 20 ()                  ###
#####################################
S20_PK() {
    cur_opcode_dec=65
    op_data_show
    echo "* This is Public ECDSA Key, corresponding bitcoin address is:"
    get_address
}

##########################################################################
### AND HERE WE GO ...                                                 ###
##########################################################################

typeset -i cur_opcode_dec
offset=0

opcode_array=$( echo $param | sed 's/[[:xdigit:]]\{2\}/ &/g' )
opcode_array_elements=$( echo ${#opcode_array} / 3 | bc )
# echo "opcode_array_elements=$opcode_array_elements, array=$opcode_array"

shell_string=$( echo $SHELL | cut -d / -f 3 )
if [ "$shell_string" == "bash" ] ; then
  i=0
  j=1
  declare -a opcode_ar
  while [ $i -lt $opcode_array_elements ]
   do
    # echo ${opcode_array:$j:2}
    opcode_ar[$i]=${opcode_array:$j:2}
    # echo "opcode_ar[$j]=$opcode_ar[$j]"
    i=$(( i + 1 ))
    j=$(( j + 3 ))
  done
elif [ "$shell_string" == "ksh" ] ; then
  set -A opcode_ar $opcode_array
fi

#####################################
### STATUS 0  INIT                ###
#####################################
  while [ $offset -lt $opcode_array_elements ]  
   do
    get_next_opcode

    case $cur_opcode in
      47) echo "   $cur_opcode: OP_DATA_0x47"
          S1_OP_Data_0x47
          ;;
      48) echo "   $cur_opcode: OP_DATA_0x48"
	  S2_OP_Data_0x48
          ;;
      21) echo "   $cur_opcode: OP_DATA_0x21"
	  S3_OP_Data_0x21
          ;;
      41) echo "   $cur_opcode: OP_DATA_0x41"
	  S4_OP_Data_0x41
          ;;
      *)
          ;;
    esac

    if [ $offset -gt 250 ] ; then
      echo "emergency exit, output scripts should not reach this size?"
      exit 1
    fi
  done


