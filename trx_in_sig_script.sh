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
#  Pieter Wuille, August 2013 
#    (http://bitcoin.stackexchange.com/questions/12554/
#            why-the-signature-is-always-65-13232-bytes-long/12556#12556)
#  A correct DER-encoded signature has the following form:
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
#  Where initial 0x00 bytes for R and S are not allowed, except when their 
#  first byte would otherwise be above 0x7F (in which case a single 0x00 in 
#  front is required). Also note that inside transaction signatures, an 
#  extra hashtype byte follows the actual signature data.
#
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
VERBOSE=0
param=483045022100A428348FF55B2B59BC55DDACB1A00F4ECDABE282707BA5185D39FE9CDF05D7F0022074232DAE76965B6311CEA2D9E5708A0F137F4EA2B0E36D0818450C67C9BA259D0121025F95E8A33556E9D7311FA748E9434B333A4ECFB590C773480A196DEAB0DEDEE1

case "$1" in
  -q)
     QUIET=1
     shift
     ;;
  -v)
     VERBOSE=1
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

#################################
### Some procedures first ... ###
#################################

v_output() {
  if [ $VERBOSE -eq 1 ] ; then
    echo $1
  fi
}

###################
### GET ADDRESS ###
###################
# supporting web sites:
# https://en.bitcoin.it/wiki/
#         Technical_background_of_version_1_Bitcoin_addresses#How_to_create_Bitcoin_Address
# http://gobittest.appspot.com/Address
get_address() {
  # if [ $QUIET -eq 0 ] ; then echo "get_address"; fi
  result=$( echo $ret_string | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
  result=$( printf "$result" | openssl dgst -sha256 | cut -d " " -f 2 )
  result=$( echo $result | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
  result=$( printf "$result" | openssl dgst -rmd160 | cut -d " " -f 2 )
  ./trx_base58check_enc.sh -q $result
}
############################################################
### procedure to show data separated by colon or newline ###
############################################################
op_data_show() {
  # if [ $QUIET -eq 0 ] ; then echo "op_data_show"; fi
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
  # if [ $QUIET -eq 0 ] ; then echo "get_next_opcode"; fi
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
  # if [ $QUIET -eq 0 ] ; then echo "S1_SIG_LEN_0x47"; fi
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
  # if [ $QUIET -eq 0 ] ; then echo "S2_SIG_LEN_0x48"; fi
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
  v_output S4_SIG_LEN_0x41
  cur_opcode=${opcode_ar[offset]}
  case $cur_opcode in
    04) echo "   $cur_opcode: OP_LENGTH_0X04"
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
    01) echo "   $cur_opcode: OP_SIGHASHALL *** This terminates the ECDSA signature (ASN1-DER structure)"
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
    01) echo "   $cur_opcode: OP_SIGHASHALL *** This terminates the ECDSA signature (ASN1-DER structure)"
        S11_SIG 
        ;;
    02) echo "   $cur_opcode: OP_SIGHASHALL *** This terminates the ECDSA signature (ASN1-DER structure)"
        S11_SIG 
        ;;
    03) echo "   $cur_opcode: OP_SIGHASHALL *** This terminates the ECDSA signature (ASN1-DER structure)"
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
    01) echo "   $cur_opcode: OP_SIGHASHALL *** This terminates the ECDSA signature (ASN1-DER structure)"
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
    # if [ $QUIET -eq 0 ] ; then echo "S19_PK"; fi
    cur_opcode_dec=33
    op_data_show
    echo "* This terminates the Public Key (X9.63 COMPRESSED form)"
    echo "* corresponding bitcoin address is:"
    get_address
}
#####################################
### STATUS 20 ()                  ###
#####################################
S20_PK() {
    v_output S20_PK
    cur_opcode_dec=65
    op_data_show
    echo "* This terminates the Public Key (X9.63 UNCOMPRESSED form)"
    echo "* corresponding bitcoin address is:"
    get_address
}
#####################################
### STATUS 21 (S21_SIG_LEN_0x49)  ###
#####################################
S21_SIG_LEN_0x49() {
  # if [ $QUIET -eq 0 ] ; then echo "S21_SIG_LEN_0x49"; fi
  get_next_opcode
  case $cur_opcode in
    30) echo "   $cur_opcode: OP_LENGTH_0x30"
        S22_Sigtype
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 22 (S22_Sigtype)       ###
#####################################
S22_Sigtype () {
  get_next_opcode
  case $cur_opcode in
    46) echo "   $cur_opcode: OP_LENGTH_0x46"
        S23_Length
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 23 (S23_Length)        ###
#####################################
S23_Length() {
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
### STATUS 24 (S24_SIG_LEN_0x3C)  ###
#####################################
S24_SIG_LEN_0x3C() {
  # if [ $QUIET -eq 0 ] ; then echo "S21_SIG_LEN_0x49"; fi
  get_next_opcode
  case $cur_opcode in
    30) echo "   $cur_opcode: OP_LENGTH_0x30"
        S25_Sigtype
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 25 (S25_Sigtype)       ###
#####################################
S25_Sigtype () {
  get_next_opcode
  case $cur_opcode in
    39) echo "   $cur_opcode: OP_LENGTH_0x39"
        S26_Length
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 26 (S26_Length)        ###
#####################################
S26_Length() {
  get_next_opcode
  case $cur_opcode in
    02) echo "   $cur_opcode: OP_LENGTH_0x02"
        S27_X_Length
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 27 (S27_SIG_X)         ###
#####################################
S27_X_Length() {
  get_next_opcode
  case $cur_opcode in
    15) echo "   $cur_opcode: OP_INT_0x15 *** this is SIG X"
        op_data_show 
        S28_SIG_X
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 28 (S28_Y_Length)      ###
#####################################
S28_SIG_X() {
  get_next_opcode
  case $cur_opcode in
    02) echo "   $cur_opcode: OP_LENGTH_0x02"
        S16_S_Length
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}

#####################################
### STATUS 30 (OP_DUP)            ###
#####################################
S30_OP_DUP() {
  get_next_opcode
  case $cur_opcode in
    A9) echo "   $cur_opcode: OP_HASH160"
        S31_OP_HASH160
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 31 (OP_HASH160)        ###
#####################################
S31_OP_HASH160() {
  get_next_opcode
  case $cur_opcode in
    14) echo "   $cur_opcode: OP_Data$cur_opcode (= decimal $cur_opcode_dec)"
        op_data_show
        S32_OP_DATA20
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 32 (OP_DATA20)         ###
#####################################
S32_OP_DATA20() {
  get_next_opcode
  case "$cur_opcode" in
    88) echo "   $cur_opcode: OP_EQUALVERIFY"
        S33_OP_EQUALVERIFY
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 33 (OP_EQUALVERIFY)    ###
#####################################
S33_OP_EQUALVERIFY() {
  get_next_opcode
  case $cur_opcode in
    AC) echo "   $cur_opcode: OP_CHECKSIG"
        S34_P2PKH
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 34 (P2PKH)             ###
#####################################
S34_P2PKH() {
  echo "* This is a P2PKH script in an unsigned raw transaction"
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
    v_output S0_INIT
    get_next_opcode
    
    case $cur_opcode in
      21) echo "   $cur_opcode: OP_DATA_0x21"
	  S3_SIG_LEN_0x21
          ;;
      3C) echo "   $cur_opcode: OP_DATA_0x3C"
	  S24_SIG_LEN_0x3C
          ;;
      41) echo "   $cur_opcode: OP_DATA_0x41"
	  S4_SIG_LEN_0x41
          ;;
      47) echo "   $cur_opcode: OP_DATA_0x47"
          S1_SIG_LEN_0x47
          ;;
      48) echo "   $cur_opcode: OP_DATA_0x48"
	  S2_SIG_LEN_0x48
          ;;
      49) echo "   $cur_opcode: OP_DATA_0x49"
	  S21_SIG_LEN_0x49
          ;;
      76) echo "   $cur_opcode: OP_DATA_0x76"
	  S30_OP_DUP
          ;;
      *)  echo "   $cur_opcode: unknown OpCode"
          ;;
    esac

    if [ $offset -gt 300 ] ; then
      echo "emergency exit, output scripts should not reach this size?"
      exit 1
    fi
  done


