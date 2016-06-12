#!/bin/sh
# base58encode a hex string to the final bitcoin address.
# basically implementing steps 4 - 9 from:
# https://en.bitcoin.it/wiki/Technical_background_of_version_1_Bitcoin_addresses
# created with support from bitcoin_tools by "grondilu@yahoo.fr"
# 
# Copyright (c) 2015, 2016 Volker Nowarra 
# Complete rewrite of code in Nov/Dec 2015 from following reference:
#   https://en.bitcoin.it/wiki/Protocol_specification#tx
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

P2SH=0
QUIET=0
param=010966776006953D5567439E5E39F86A0D273BEE
base58str="123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
base58_arr=" 1 2 3 4 5 6 7 8 9 A B C D E F G H J K L M N P Q R S T U V W X Y Z
             a b c d e f g h i j k m n o p q r s t u v w x y z"

if [ "$3" == "P2SH" ] ; then
  P2SH=1
fi
case "$1" in
  -q)
     QUIET=1
     shift
     ;;
  -?|-h|--help)
     echo "usage: base58check_enc.sh [-?|-h|--help|-q] hex_string"
     echo "  "
     echo "convert a raw hex istring from a blockchain trx into a bitcoin address"
     echo "basically implementing steps 4 - 9 from:"
     echo "https://en.bitcoin.it/wiki/Technical_background_of_version_1_Bitcoin_addresses"
     echo "if no parameter is given, the data from the web page is demonstrated"
     echo "  "
     exit 0
     ;;
  *)
     ;;
esac

if [ $QUIET -eq 0 ] ; then 
  echo "##################################################################"
  echo "### base58check_enc: convert a hex string to a bitcoin address ###"
  echo "##################################################################"
  echo "  "
fi

if [ $# -eq 0 ] ; then 
  if [ $QUIET -eq 0 ] ; then 
    echo "no parameter, hence implementing steps from:"
    echo "https://en.bitcoin.it/wiki/Technical_background_of_version_1_Bitcoin_addresses"
  fi
else 
  param=$1
fi

if [ $QUIET -eq 0 ] ; then 
  echo "using $param"
  echo " "
fi

  
####################################
### 4: add zero at the beginning ###
####################################
if [ $QUIET -eq 0 ] ; then 
  echo "4: add 0x00 or 0x05 (P2SH) at the beginning" 
fi
if [ $P2SH -eq 0 ] ; then 
  # result="$(printf "%2s%${3:-40}s" ${2:-00} $param | sed 's/ /0/g')"
  result="00$param"
else
  # result="$(printf "%2s%${3:-40}s" ${2:-05} $param | sed 's/ /0/g')"
  result="05$param"
fi
result4=$result

### verify result string: check, that string is a 
### hex field (length of chars must be divisible by 2)
len_result=${#result} 
if [ $QUIET -eq 0 ] ; then 
  echo "   $result"
fi
result_mod2=$(( $len_result % 2 ))
if [ $result_mod2 -ne 0 ] ; then
  if [ $QUIET -eq 0 ] ; then
    echo "*** ERROR: string does not look like hex, not divisible by 2"
  fi
  exit 1
fi

####################################################
### echo "5. sha256"                             ###
### Bitcoin never does sha256 with the hex codes ###
####################################################
if [ $QUIET -eq 0 ] ; then
  echo "5. sha256"
fi
result=$( echo $result | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
result=$( printf "$result" | openssl dgst -sha256 | cut -d " " -f 2 )
if [ $QUIET -eq 0 ] ; then
  echo "   $result"
fi

####################################################
### 6. another sha256                            ###
### Bitcoin never does sha256 with the hex codes ###
####################################################
if [ $QUIET -eq 0 ] ; then
  echo "6. another sha256"
fi
result=$( echo $result | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
result=$( printf "$result" | openssl dgst -sha256 | cut -d " " -f 2 )
if [ $QUIET -eq 0 ] ; then
  echo "   $result"
fi

################################
### 7. take first four Bytes ### 
################################
if [ $QUIET -eq 0 ] ; then
  echo "7. take first four Bytes from step 6 as checksum"
fi
checksum=$( echo $result | cut -b 1,2,3,4,5,6,7,8 )
if [ $QUIET -eq 0 ] ; then
  echo "   $checksum"
fi

############################################################
### 8. add the checksum to the address result from step4 ###
############################################################
if [ $QUIET -eq 0 ] ; then
  echo "8. append checksum from step 7 to the result from step4"
fi
result=$result4$checksum
if [ $QUIET -eq 0 ] ; then
  echo "   $result"
fi

###########################################
### 9. encodeBase58 result from step 8: ### 
###    dc 58=0x3A                       ###
###########################################
if [ $QUIET -eq 0 ] ; then
  echo "9. encode Base58"
fi
tmpvar=$( echo $result | tr "[:lower:]" "[:upper:]" )
echo "$tmpvar" | sed -e's/^\(\(00\)*\).*/\1/' -e's/00/1/g' | tr -d '\n'

#
# !!! UGLY MATRIX HANDLING !!!
#   NO POSIX compliance: matrix handling for Linux, OSX and BSD 
#   shells are too different. This declaration and the "while read loop" 
#   in step 9 are the only occurences, where the script is non posix compliant.
# !!! UGLY MATRIX HANDLING !!!
#

shell_string=$( echo $SHELL | cut -d / -f 3 )
if [ $shell_string == "bash" ] ; then
  i=0
  declare -a base58
  base58_len=${#base58str}
  while [ $i -lt $base58_len ]
   do
    base58[$i]=${base58str:$i:1}
    # echo base58[$i]=${base58[i]}
    i=$(( i + 1 ))
  done
  dc -e "16i $tmpvar [3A ~r d0<x]dsxx +f" | while read -r n; do echo "${base58[n]}"; done | tr -d '\n'
  #                                   ^ ??
  #                                 ^ execute
  #                                ^ execute
  #                               ^ remove it from the stack (s)
  #                              ^ duplicates the top of the stack
  #                             ^ [...] STRING in brackets on stack
  #                           ^^ The top two elements of the stack are popped and compared.
  #                          ^ the value "0" is put on stack
  #                         ^ duplicates the top of the stack
  #                      ^^ top two values on the stack are divided and remaindered (~) 
  #                   ^^ dec 58 = hex 0x3A on Stack
  #                  ^ [...] STRING in brackets on stack
  #          ^ the string that dc will work on ...
  #        ^ i pops the value off the top of the stack and uses it to set the input radix.
  #      ^^base 
  #  ^^ execute script
  # for the GURUs: "man dc" 
  # http://wiki.bash-hackers.org/howto/calculate-dc
  # https://en.wikipedia.org/wiki/Dc_%28Unix%29
elif [ $shell_string == "ksh" ] ; then
  set -A items $base58_arr
  dc -e "16i $tmpvar [3A ~r d0<x]dsxx +f" | while read -r n; do echo -n "${items[n]}"; done
else
  if [ $QUIET -eq 0 ] ; then 
    echo " "
    echo "*** ERROR: could not determine shell, don't know how to proceed."
    echo "           exiting gracefully"
    echo " "
    exit 1
  fi
fi 

echo " "
exit 0


