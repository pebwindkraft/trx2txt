#!/bin/sh
##############################################################################
# Read the bitcoin script_SIG OPCODES from a transaction's TRX_IN 
# script by Sven-Volker Nowarra 
# 
# Version	by	date	comment
# 0.1		svn	11jun16 initial release
# 0.2		svn	25jul16 added multisig functionality
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
#  ???
# 

typeset -i msig_offset=1
typeset -i cur_opcode_dec
offset=1

QUIET=0
VERBOSE=0
param=483045022100A428348FF55B2B59BC55DDACB1A00F4ECDABE282707BA5185D39FE9CDF05D7F0022074232DAE76965B6311CEA2D9E5708A0F137F4EA2B0E36D0818450C67C9BA259D0121025F95E8A33556E9D7311FA748E9434B333A4ECFB590C773480A196DEAB0DEDEE1

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
  result=$( echo $ret_string | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
  result=$( printf "$result" | openssl dgst -sha256 | cut -d " " -f 2 )
  result=$( echo $result | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
  result=$( printf "$result" | openssl dgst -rmd160 | cut -d " " -f 2 )
  ./trx_base58check_enc.sh -q $result
  ret_string=''
}
############################################################
### procedure to show data separated by colon or newline ###
############################################################
op_data_show() {
  n=1
  output=
  while [ $n -le $cur_opcode_dec ]
   do
    to=$(( offset + 1 ))
    opcode=$( echo $param | cut -b $offset-$to )
    output=$output$opcode
    ret_string=$ret_string$opcode
    if [ $n -eq 8 ] || [ $n -eq 24 ] || [ $n -eq 40 ] || [ $n -eq 56 ] ; then 
      output=$output":"
    elif [ $n -eq 16 ] || [ $n -eq 32 ] || [ $n -eq 48 ] || [ $n -eq 64 ] ; then 
      echo "       $output" 
      output=
      opcode=
    fi
    n=$(( n + 1 ))
    offset=$(( offset + 2 ))
  done 
  echo "       $opcode" 
}

#####################
### GET NEXT CODE ###
#####################
get_next_opcode() {
  to=$(( offset + 1 ))
  cur_opcode=$( echo $param | cut -b $offset-$to )
  # echo "from=$offset, to=$to, opcode=$cur_opcode"
  cur_hexcode="0x"$cur_opcode
  cur_opcode_dec=$( echo "ibase=16;$cur_opcode" | bc )
  # v_output "offset=$offset, opcode=$cur_opcode, opcode_dec=$cur_opcode_dec"
  offset=$(( offset + 2 ))
}

#####################################
### STATUS 1 (S1_SIG_LEN_0x47)    ###
#####################################
S1_SIG_LEN_0x47() {
  v_output "S1_SIG_LEN_0x47"
  get_next_opcode
  case $cur_opcode in
    30) echo "   $cur_opcode: OP_LENGTH_0x30"
        S5_Sigtype
        ;;
    52) echo "   $cur_opcode: OP_2"
        # in case we go for msig, then length of msig is 0x47 Bytes (2x71chars=142)
        msig_len=142
        S30_MSIG2of2
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 2 (S2_SIG_LEN_0x48)    ###
#####################################
S2_SIG_LEN_0x48() {
  v_output "S2_SIG_LEN_0x48"
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
  v_output "S3_SIG_LEN_0x21"
  get_next_opcode
  case $cur_opcode in
    02) echo "   $cur_opcode: OP_INT_0x02"
        ret_string=02
        S19_PK   
        ;;
    03) echo "   $cur_opcode: OP_INT_0x03"
        ret_string=03
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
  v_output "S4_SIG_LEN_0x41"
  get_next_opcode
  case $cur_opcode in
    04) echo "   $cur_opcode: OP_LENGTH_0X04"
        ret_string=04
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
    v_output "S19_PK"
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
### STATUS 30 (S30_MSIG2of2)      ###
#####################################
S30_MSIG2of2() {
  S30_to=$(( $offset + msig_len ))
  if [ $S30_to -gt $opcodes_len ] ; then
    S30_to=$opcodes_len 
  fi
  v_output "S30_MSIG2of2, offset=$offset, S30_to=$S30_to, opcodes_len=$opcodes_len"
  while [ $offset -le $S30_to ]  
   do
    get_next_opcode
    case $cur_opcode in
      21) echo "   $cur_opcode: OP_DATA_0x21: compressed pub key"
          op_data_show
          echo "* This terminates the MultiSig's Public Key (X9.63 COMPRESSED form)"
          echo "* corresponding bitcoin address is:"
          get_address
          echo " "
          ;;
      41) echo "   $cur_opcode: OP_DATA_0x41: uncompressed pub key"
          op_data_show
          echo "* This terminates the MultiSig's Public Key (X9.63 UNCOMPRESSED form)"
          echo "* corresponding bitcoin address is:"
          get_address
          echo " "
          ;;
      52) echo "   $cur_opcode: OP_2: push 2 Bytes onto stack"
          echo "       Multisig needs 2 pubkeys ?"
          ;;
      AE) echo "   $cur_opcode: OP_CHECKMULTISIG"
          echo "       ########## Multisignature end ###########"
          break
          ;;
      *)  echo "   $cur_opcode: unknown OpCode"
          ;;
    esac
  done
  # v_output "********* end S30 while ****************"
}
############################
### STATUS 35 (MSIG ...) ###
############################
S35_MSIG2of3() {
  get_next_opcode
  case $cur_opcode in
    *)  echo "   $cur_opcode: OP_INTEGER $cur_opcode_dec Bytes (0x$cur_opcode) go to stack"
        msig_len=$cur_opcode_dec
        S36_LENGTH
        ;;
  esac
}
##########################
### STATUS 36 (length) ###
##########################
S36_LENGTH() {
  get_next_opcode
  case $cur_opcode in
    52) echo "   $cur_opcode: OP_2: push 2 Bytes onto stack"
        echo "       ###### we go multisig, ( 2 out of n multisig ?) #######"
        S37_OP2
        ;;
    *)  echo "   $cur_opcode: unknown opcode "
        ;;
  esac
}
##########################
### STATUS 37 (length) ###
##########################
S37_OP2() {
  S37_to=$(( $offset + msig_len ))
  if [ $S37_to -gt $opcodes_len ] ; then
    S37_to=$opcodes_len 
  fi
  v_output "S37_MSIG2of2, offset=$offset, S37_to=$S37_to, opcodes_len=$opcodes_len"
  while [ $offset -le $S37_to ]  
   do
    get_next_opcode
    case $cur_opcode in
      21) echo "   $cur_opcode: OP_DATA_0x21: compressed pub key"
          op_data_show
          echo "* This terminates the MultiSig's Public Key (X9.63 COMPRESSED form)"
          echo "* corresponding bitcoin address is:"
          get_address
          echo " "
          ;;
      41) echo "   $cur_opcode: OP_DATA_0x41: uncompressed pub key"
          op_data_show
          echo "* This terminates the MultiSig's Public Key (X9.63 UNCOMPRESSED form)"
          echo "* corresponding bitcoin address is:"
          get_address
          echo " "
          ;;
      53) echo "   $cur_opcode: OP_3: push 3 Bytes onto stack"
          echo "   Multisig needs 3 pubkeys ?"
          ;;
      AE) echo "   $cur_opcode: OP_CHECKMULTISIG"
          echo "       ########## Multisignature end ###########"
          break
          ;;
      *)  echo "   $cur_opcode: unknown OpCode"
          ;;
    esac
  done
  # v_output "********* end S37 while ****************"
}

##########################################################################
### AND HERE WE GO ...                                                 ###
##########################################################################

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

if [ $QUIET -eq 0 ] ; then 
  echo "a valid bitcoin signature (r,s) is going to look like:"
  echo "<30><len><02><len><r bytes><02><len><s bytes><01>"
  echo "with 9 <= length(sig) <= 73"
  echo " "
  echo "Multisig is much more complicated :-)"
  echo " "
fi

#####################################
### STATUS 0 - INIT               ###
#####################################
  opcodes_len=${#param}
  while [ $offset -le $opcodes_len ]  
   do
    get_next_opcode
    v_output "S0_INIT, opcode=$cur_opcode"
    
    case $cur_opcode in
      21) echo "   $cur_opcode: OP_DATA_0x21"
	  S3_SIG_LEN_0x21
          ;;
      3C) echo "   $cur_opcode: OP_DATA_0x3C"
	  S24_SIG_LEN_0x3C
          ;;
      4C) echo "   $cur_opcode: OP_PUSHDATA1 (next byte is number of bytes that go to stack)" 
	  S35_MSIG2of3
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
      *)  echo "   $cur_opcode: unknown OpCode"
          ;;
    esac

    # sometimes the script hangs, need to have emergency break.
    # careful: multisig scripts can get longer!!!
    if [ $offset -gt 510 ] ; then
      echo "emergency exit, output scripts should not reach this size?"
      echo "          offset=$offset, scriptlen=$opcodes_len"
      exit 1
    fi
  done


