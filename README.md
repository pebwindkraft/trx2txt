********************************************
08-dec-2016
********************************************
this software is discontinued, please see:
https://github.com/pebwindkraft/trx_cl_suite
********************************************


GITHUB messes with the text and newlines, please view in "raw" mode...

##########################################
### 1. TRX2TXT tool suite description: ###
##########################################
A suite of shell scripts to display a Bitcoin transaction in plain text, similiar to the Bitcoin core client or "www.blockchain.info" JSON output. 

Scripts are written to run on OpenBSD and OSX and Linux systems at the command shell (ksh, bash). Existing tools on the web (Bitcoin CLI tools and others), are written to work only with BASHv4. In this suite, all scripts are coded with the intention, to be (nearly) POSIX compliant. Tested on OpenBSD korn shell, MAC OSX BASHv3 and SuSE Linux BASHv4. 

Main program (shell script) to display contents of a transaction is "trx2txt.sh". It refers to:
   https://en.bitcoin.it/wiki/Protocol_specification#tx 
The TRX_IN and TRX_OUT parts are shown, with the decoded sig script and pk pubkey script details, and it's corresponding bitcoin address(es). 
Script "trx2txt.sh" has several command line options (just open with "-h" or "--help").

Code is not (yet?) written for best performance: there are many calls to shell functions (which always fork during shell execution). And also several external (Unix standard) programs are called. 

Readability: current version of programs are heavily commented, to be able to follow/understand the program’s logic. 


#######################
### file trx2txt.sh ###
#######################
The main script. You'll want to start here :-) 

Usecases:

./trx2txt.sh 
  Without parameters, the details of a sample transaction are shown, line by line.

./trx2txt.sh -r 
  pass the hex code of a RAW TRANSACTION as option, for example the output of:
  https://blockchain.info/de/rawtx/cc8a279b0736e6a2cc20b324acc5aa688b3af7b63bbb002f46f6573c1ad84408?format=hex
  which would give some lines of hexcode. Simply cut&paste, and add after the -r parameter:
  ./trx2txt.sh -r 010000000253603b3fdb9d5e10de2172305ff68f4b5227310ba6bd81d4e1bf60c0de6183...

./trx2txt.sh -t
  pass the hex code of a TRANSACTION HASH as option, e.g.: 
  ./trx2txt.sh -t cc8a279b0736e6a2cc20b324acc5aa688b3af7b63bbb002f46f6573c1ad84408
  The script will check for network connectivity, and will then try to download the raw trx data from the given trx number.

./trx2txt.sh -u 
  pass the hex code of an UNSIGNED RAW TRX as option.
  This is an advanced option, so if you created your unsigned raw trx (eventually with 'trx_create_sign.sh' of this suite), it can be double checked.

The program checks the parameters, checks the version of the shell (for cases where POSIX compliance can not be achieved, in particular with arrays), checks availability for all necessary sub-programs (openssl, awk, bc, ...) to decode a transaction, and then begins to break down the transactions.

./trx2txt.sh -v
with parameter -v, a more detailed view is provided, along the guidelines of the bitcoin wiki.

./trx2txt.sh -vv
with parameter -vv, a very detailed view is provided, including the decoding of the sig script and the public key script. Two png files are provided, which show the state machine. The script verification/decoding is supported by three helper scripts (description below): 
trx_in_sig_script.sh - to decode the TRX_IN script
trx_out_pk_script.sh - to decode the TRX_OUT script
base58check_enc.sh   - to convert the scripts addresses to "human readable" bitcoin addresses

to understand the particular steps to decode a transaction, run this command:
  cat trx2txt.sh | grep STEP -A 2 -B 1 
The displayed steps are derived from: https://en.bitcoin.it/wiki/Protocol_specification#tx


###########################
### 2. Supporting files ###
###########################
The supporting scripts are used by the main program (trx2txt.sh), but can also be used independantly, when provided with the correct parameters. Use the '-h' parameters to these scripts to explain. 


#################################
### file trx_in_sig_script.sh ###
#################################
This shell script tries to decode the TRX-IN sig script via it's internal simple state diagram. The way the OPCodes are processed follows the picture "trx_in_sig_state_machine.png". At anytime the script can be used "stand alone". Without parameters, it displays as per below, alternativly just provide a sig script as parameter (or as usual, use '-h'). 

   48: OP_DATA_0x48
   30: OP_LENGTH_0x30
   45: OP_LENGTH_0x45
   02: OP_INT_0x02
   21: OP_LENGTH_0x21 *** this is SIG R
       00A428348FF55B2B:59BC55DDACB1A00F
       4ECDABE282707BA5:185D39FE9CDF05D7
       F0
   02: OP_INT_0x02
   20: OP_LENGTH_0x20 *** this is SIG S
       74232DAE76965B63:11CEA2D9E5708A0F
       137F4EA2B0E36D08:18450C67C9BA259D
       
   01: OP_SIGHASHALL *** This terminates the ECDSA signature (ASN1-DER structure)
 
   21: OP_DATA_0x21
   02: OP_INT_0x02
       025F95E8A33556E9:D7311FA748E9434B
       333A4ECFB590C773:480A196DEAB0DEDE
       E1
* This terminates the Public Key (X9.63 COMPRESSED form)
* corresponding bitcoin address is:
1HTNtayFkoBV28wqDygMbW33qSnRjxAuNR 

#################################
### file trx_out_pk_script.sh ###
#################################
This shell script tries to decode the TRX-OUT public key script via it's internal simple state diagram. The way the OPCodes are processed follows the picture "trx_out_pk_state_machine.png". At anytime the script can be used "stand alone". Without parameters, it displays as per below, alternativly just provide a sig script as parameter (or as usual, use '-h'). 

76A9146AF1D17462C6146A8A61217E8648903ACD3335F188AC
   76: OP_DUP
   A9: OP_HASH160
   14: OP_Data14 (= decimal 20)
       6AF1D17462C6146A:8A61217E8648903A
       CD3335F1
   88: OP_EQUALVERIFY
   AC: OP_CHECKSIG
* This is a P2PKH script
6AF1D17462C6146A8A61217E8648903ACD3335F1

The string of the 20 bytes in the middle of this output is the hexadecimal representation of the Bitcoin address. To show the "human readable" chars, a third script is used:


###################################
### file trx_base58check_enc.sh ###
###################################
This shell script tries to decode the addresses in BITCOIN SCRIPTs. It reads the hex codes, does a base58 conversion, and displays the bitcoin address. At anytime the file can be used "stand alone". Without parameters, it displays as per below, alternativly just provide a sig script as parameter (or as usual, use '-h').

./trx_base58check_enc.sh
using 010966776006953D5567439E5E39F86A0D273BEE
 
4: add 0x00 or 0x05 [P2SH] at the beginning
5. sha256
445c7a8007a93d8733188288bb320a8fe2debd2ae1b47f0f50bc10bae845c094
6. another sha256
d61967f63c7dd183914a4ae452c9f6ad5d462ce3d277798075b107615c1a8a30
7. take first four Bytes from step 6 as checksum
d61967f63c7dd183914a4ae452c9f6ad5d462ce3d277798075b107615c1a8a30
8. append checksum from step 7 to the result from step4
00010966776006953D5567439E5E39F86A0D273BEEd61967f6
9. encode Base58
16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM 


#################################
### file testcases_trx2txt.sh ###
#################################
This shell script supports the development process, and verifies the script output(s).
1.) build sha256 checksums of the involved source code scripts
2.) runs script "trx2txt.sh" with different parameters and transactions
3.) sends output into a file, and calculate it’s SHA256 hash value
4.) compare checksums 

Most easily it is used like this:

  ./testcases_trx2txt.sh 

which runs all tests (time consuming). This can be easily compared on all platforms. When hash is equal on all platforms, code is ready to be uploaded to GITHUB (or similiar). 

  ./trx_testcases.sh -l
  "-l", a log file ("trx_testcases.sh.log") is created. All checks are performed.

  ./trx_testcases.sh -h
  "-h" displays a help text

  ./trx_testcases.sh 1|2|3|4|5|6|7|8|9
  [1-9] runs only the mentioned testcases, to get quicker results


###############################
### file trx_create_sign.sh ###
###############################
Advanced usage! If you understand the idea of cold storage, and creating unsigned raw transactions, this is for you! The script tries to create or sign a transaction. It is a basis for an online/cold storage combination. On the Internet connected system you would create a raw transaction, copy it to your USB stick, and run the same script file(s) on the cold standby machine to sign the trx. Then copy the signed trx back to USB, bring it back to the Internet connected machine, and send the trx to the network. 
At anytime the file can be used "stand alone". Obviously not very useful without parameters, just provide a sig script as parameter (or as usual, use '-h').

Usage example:
(You will need to know the first three parameters from the previous trx, from which you want to redeem. Start with '-h' to better undertsand. Also do not try this unless previous transaction is confirmed!)

  ./trx_create_sign.sh -c -m <trx hash> <output> <pubkey script> <amount> <address> 

translates into something like this:
  ./trx_create_sign.sh -c -m c3434be....5c5b7a310cc67 0 76A9141FE307887696CF781DA237DBE2E12DB05C10986A88AC 110000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM

Hint: in its initial version the create/sign process allows for one input, one output and uses a P2PKH structure.


#########################################
### file testcases_trx_create_sign.sh ###
#########################################
This shell script supports the development process, and verifies the script output(s).
It is setup the exactly same way as 'testcases_trx2txt.sh'. Details up there ...
Most easily it is used like this:

  ./testcases_trx_create_sign.sh 


###########################
### file trx_key2pem.sh ### 
###########################
This shell script is necessary when the signing process is executed. The signature is done using the 'openssl' suite, which requires PEM keys. This script helps to convert from wif, wif-c or hex to PEM. At anytime the file can be used "stand alone". Obviously not very useful without parameters, just provide a sig script as parameter (or as usual, use '-h').

Hint: in its initial version the create/sign process allows for one input, one output and uses a P2PKH structure.


#####################################
### file testcases_trx_key2pem.sh ###
#####################################
This shell script supports the development process, and verifies the script output(s).
It is setup the exactly same way as 'testcases_trx2txt.sh'. Details up there ...
Most easily it is used like this:

  ./testcases_trx_key2pem.sh 


######################################
### file trx_verify_bc_address.awk ###
######################################
This awk script is a little helper tool, to make the code be more transportable. It is used by 
trx_create_sign.sh and trx_key2pem.sh.


##################################
### file trx_verify_hexkey.awk ###
##################################
This awk script is a little helper tool, to make the code be more transportable. It is used by 
trx_create_sign.sh and trx_key2pem.sh.


###########################
### file trx_base58.awk ###
###########################
This awk script is a little helper tool, to make the code be more transportable. It is used by 
trx_create_sign.sh and trx_key2pem.sh.


#########################
### 3. Documentation: ###
#########################
README.md                        - this file :-)
Changelog.txt                    - view changes over the files 
trx_in_sig_state_machine.graphml - graphics source file for the state machine
                                   (java based app: "yEd Graph Editor")
trx_in_sig_state_machine.png     - the exported png for script sig part
trx_out_pk_state_machine.graphml - graphics source file for the state machine
                                   (java based app: "yEd Graph Editor")
trx_out_pk_state_machine.png     - the exported png for PUBKEY script
trx_OP_CODES_desc.txt            - used references for PK_SCRIPT and their OpCodes
trx_state_matrix.ods             - table with three sheets, showing the state machine’s logic
trx_todos.txt*

Documentation files are not included in the hashing with any testcases.


