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
#
#  * See https://bitcointalk.org/index.php?topic=8392.0
#  ...
#  a valid bitcoin signature (r,s) is going to look like
#  <30><len><02><len><r bytes><02><len><s bytes><01>
#  where the r and s values are non-negative, and don't exceed 33 bytes 
#  including a possible padding zero byte.
#
# from: https://bitcointalk.org/index.php?topic=1383883.0
#  Unless the bottom 5 bits are 0x02 (SIGHASH_NONE) or 0x03 (SIGHASH_SINGLE), 
#  all the outputs are included.  If the bit for 0x20 is set, then all inputs 
#  are blanked except the current input (SIGHASH_ANYONE_CAN_PAY).
#  SIGHASH_ALL = 1,
#  SIGHASH_NONE = 2,
#  SIGHASH_SINGLE = 3,
#  SIGHASH_ANYONECANPAY = 0x80
# 
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
  # if [ $QUIET -eq 0 ] ; then echo "get_address"; fi
  result=$( echo $ret_string | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
  result=$( printf "$result" | openssl dgst -sha256 | cut -d " " -f 2 )
  result=$( echo $result | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
  result=$( printf "$result" | openssl dgst -rmd160 | cut -d " " -f 2 )
  ./base58check_enc.sh -q $result
}
############################################################
### procedure to show data separated by colon or newline ###
############################################################
op_data_show() {
  # if [ $QUIET -eq 0 ] ; then echo "op_data_show"; fi
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
  # if [ $QUIET -eq 0 ] ; then echo "get_next_opcode"; fi
  cur_opcode=${opcode_ar[offset]}
  cur_hexcode="0x"$cur_opcode
  cur_opcode_dec=$( echo "ibase=16;$cur_opcode" | bc )
  # echo "offset=$offset, opcode=$cur_opcode, opcode_dec=$cur_opcode_dec"
  offset=$(( offset + 1 ))
}

#####################################
### STATUS 1 (S1_SIG_LEN_0x47)    ###
#####################################
S1_SIG_LEN_0x47() {
  # if [ $QUIET -eq 0 ] ; then echo "S1_SIG_LEN_0x47"; fi
  get_next_opcode
  case $cur_opcode in
    30) echo "   $cur_opcode: OP_LENGTH_0x30"
        S5_Sigtype
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 2 (S2_SIG_LEN_0x48)    ###
#####################################
S2_SIG_LEN_0x48() {
  # if [ $QUIET -eq 0 ] ; then echo "S1_SIG_LEN_0x48"; fi
  get_next_opcode
  case $cur_opcode in
    30) echo "   $cur_opcode: OP_LENGTH_0x30"
        S12_Sigtype
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 3 (S3_SIG_LEN_0x21)    ###
#####################################
S3_SIG_LEN_0x21() {
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
### STATUS 4 (S4_SIG_LEN_0x41)    ###
#####################################
S4_SIG_LEN_0x41() {
  # get_next_opcode
  cur_opcode=${opcode_ar[offset]}
  case $cur_opcode in
    41) echo "   $cur_opcode: OP_LENGTH_0X41"
        S20_PK 
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 5 (S5_Sigtype)        ###
#####################################
S5_Sigtype() {
  get_next_opcode
  case $cur_opcode in
    44) echo "   $cur_opcode: OP_LENGTH_0x44"
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
    02) echo "   $cur_opcode: OP_R_INT_0x02"
        S7_R_Length 
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 7 (S7_R_Length)        ###
#####################################
S7_R_Length() {
  get_next_opcode
  case $cur_opcode in
    20) echo "   $cur_opcode: OP_LENGTH_0x20 *** this is SIG R"
        op_data_show
        S8_SIG_R
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        if [ $cur_opcode_dec -eq 0 ] ; then 
          echo "*** Zero-length integers are not allowed for R."
        fi
#     // Negative numbers are not allowed for R.
#     if (sig[lenR + 6] & 0x80) return false;
        ;;
  esac
}
#####################################
### STATUS 8 (S8_SIG_R)           ###
#####################################
S8_SIG_R() {
  get_next_opcode
  case $cur_opcode in
    02) echo "   $cur_opcode: OP_S_INT_0x02"
        S9_S_Length 
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 9 (S9_S_Length)        ###
#####################################
S9_S_Length() {
  get_next_opcode
  case $cur_opcode in
    20) echo "   $cur_opcode: OP_LENGTH_0x20 *** this is SIG S"
        op_data_show 
        S10_SIG_S
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        if [ $cur_opcode_dec -eq 0 ] ; then 
          echo "*** Zero-length integers are not allowed for S."
        fi
#     // Negative numbers are not allowed for S.
#     if (sig[lenR + 6] & 0x80) return false;
        ;;
  esac
}
#####################################
### STATUS 10 (S10_SIG_S)         ###
#####################################
S10_SIG_S() {
  get_next_opcode
  case $cur_opcode in
    01) echo "   $cur_opcode: OP_SIGHASHALL *** This terminates the sigs"
        S11_SIG 
        ;;
    02) echo "   $cur_opcode: OP_SIGHASH_NONE *** This terminates the sigs"
        S11_SIG 
        ;;
    03) echo "   $cur_opcode: OP_SIGHASH_SINGLE *** This terminates the sigs"
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
### STATUS 12 (S12_Sigtype)      ###
#####################################
S12_Sigtype () {
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
        S14_R_Length 
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 14 ()                  ###
#####################################
S14_R_Length() {
  get_next_opcode
  case $cur_opcode in
    20) echo "   $cur_opcode: OP_LENGTH_0x20 *** this is SIG R"
        op_data_show
        S15_SIG_R 
        ;;
    21) echo "   $cur_opcode: OP_LENGTH_0x21 *** this is SIG R"
        op_data_show
        S15_SIG_R 
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        if [ $cur_opcode_dec -eq 0 ] ; then 
          echo "*** Zero-length integers are not allowed for R."
        fi
#     // Negative numbers are not allowed for R.
#     if (sig[lenR + 6] & 0x80) return false;
        ;;
  esac
}
#####################################
### STATUS 15 (S15_SIG_R)         ###
#####################################
S15_SIG_R() {
  get_next_opcode
  case $cur_opcode in
    02) echo "   $cur_opcode: OP_INT_0x02"
        S16_S_Length 
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 16 (S16_S_Length)      ###
#####################################
S16_S_Length() {
  get_next_opcode
  case $cur_opcode in
    20) echo "   $cur_opcode: OP_LENGTH_0x20 *** this is SIG S"
        op_data_show
        S17_SIG_S
        ;;
    21) echo "   $cur_opcode: OP_LENGTH_0x20 *** this is SIG S"
        op_data_show
        S17_SIG_S
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        if [ $cur_opcode_dec -eq 0 ] ; then 
          echo "*** Zero-length integers are not allowed for S."
        fi
#     // Negative numbers are not allowed for S.
#     if (sig[lenR + 6] & 0x80) return false;
        ;;
  esac
}
#####################################
### STATUS 17 (S17_SIG_S)         ###
#####################################
S17_SIG_S() {
  get_next_opcode
  case $cur_opcode in
    01) echo "   $cur_opcode: OP_SIGHASHALL *** This terminates the sigs"
        S11_SIG 
        ;;
    03) echo "   $cur_opcode: OP_SIGHASH_SINGLE *** This terminates the sigs"
        S11_SIG 
        ;;
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
    # if [ $QUIET -eq 0 ] ; then echo "S19_PK"; fi
    cur_opcode_dec=33
    op_data_show
    echo "* This is Public ECDSA Key, corresponding bitcoin address is:"
    get_address
}
#####################################
### STATUS 20 ()                  ###
#####################################
S20_PK() {
    # if [ $QUIET -eq 0 ] ; then echo "S20_PK"; fi
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

if [ $QUIET -eq 0 ] ; then 
  echo "a valid bitcoin signature (r,s) is going to look like:"
  echo "<30><len><02><len><r bytes><02><len><s bytes><01>"
  echo "with 9 <= length(sig) <= 73"
  echo " "
fi
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
    # if [ $QUIET -eq 0 ] ; then echo "S0_INIT"; fi
    get_next_opcode
    
    case $cur_opcode in
      47) echo "   $cur_opcode: OP_DATA_0x47"
          S1_SIG_LEN_0x47
          ;;
      48) echo "   $cur_opcode: OP_DATA_0x48"
	  S2_SIG_LEN_0x48
          ;;
      21) echo "   $cur_opcode: OP_DATA_0x21"
	  S3_SIG_LEN_0x21
          ;;
      41) echo "   $cur_opcode: OP_DATA_0x41"
	  S4_SIG_LEN_0x41
          ;;
      *)  echo "   $cur_opcode: unknown OpCode"
          ;;
    esac

    if [ $offset -gt 250 ] ; then
      echo "emergency exit, output scripts should not reach this size?"
      exit 1
    fi
  done


