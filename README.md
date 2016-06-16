GITHUB messes with the text and newlines, please view in "raw" mode...

###############################
### 1. TRX2TXT description: ###
###############################
A suite of shell scripts to display a Bitcoin transaction in plain text, similiar to the Bitcoin core client or "www.blockchain.info" JSON output. 

Scripts are written to run on BSD/UNIX systems. Existing tools on the web (Bitcoin CLI tools and others), are written to work only with BASHv4. In this suite, all scripts are coded with the intention, to be (nearly) POSIX compliant. Tested on OpenBSD korn shell, MAC OSX BASHv3 and SuSE Linux BASHv4. 

Main program (shell script) to display contents of a transaction is "trx2txt.sh". It refers to:
   https://en.bitcoin.it/wiki/Protocol_specification#tx 
The TRX_IN and TRX_OUT parts are shown, with the decoded sig script and pk pubkey script details, and the corresponding bitcoin address(es). 
Script "trx2txt.sh" has several command line options (just open with "-h" or "--help").

Code is not (yet?) written for best performance: there are many calls to shell functions (which always fork during shell execution). And also several external programs are called. 

Readability: current version of programs are heavily commented, to be able to follow/understand the program’s logic. 


#######################
### file trx2txt.sh ###
#######################
The main script. You'll want to start here :-)
The program checks the parameters, checks the version of the shell (for cases where POSIX compliance can not be achieved, in particular with arrays), checks availability for all necessary sub-programs (openssl, awk, bc, ...) to decode a transaction, and then begins to break down the transactions.

./trx2txt.sh 
Without parameters, the details of a sample transaction are shown, line by line.

./trx2txt.sh -v
with parameter -v, a more detailed view is provided, along the guidelines of the bitcoin wiki.

./trx2txt.sh -vv
with parameter -vv, a very detailed view is provided, including the decoding of the sig script and the public key script. Two png files are provided, which show the state machine. The script verification/decoding is supported by three helper scripts (description below): 
trx_in_sig_script.sh - to decode the TRX_IN script
trx_out_pk_script.sh - to decode the TRX_OUT script
base58check_enc.sh   - to convert the scripts addresses to "human readable" bitcoin addresses

./trx2txt.sh -r 
you can pass the Hex code of a raw trx as option, for example the output of:
   https://blockchain.info/de/rawtx/cc8a279b0736e6a2cc20b324acc5aa688b3af7b63bbb002f46f6573c1ad84408?format=hex
which would give some lines of hexcode. Simply cut&paste, and add after the -r parameter:
  ./trx2txt.sh -r 010000000253603b3fdb9d5e10de2172305ff68f4b5227310ba6bd81d4e1bf60c0de6183...

./trx2txt.sh -t
you can pass the hash value of a trx as option, e.g.: 
   ./trx2txt.sh -t cc8a279b0736e6a2cc20b324acc5aa688b3af7b63bbb002f46f6573c1ad84408
The script will check for network connectivity, and will then try to download the raw trx data from the given trx number.


###########################
### 2. Supporting files ###
###########################
The supporting scripts are used by the main program (trx2txt.sh), but can also be used independantly, when provided with the correct parameters. 


#################################
### file trx_in_sig_script.sh ###
#################################
This shell script tries to decode the TRX-IN sig script via it's internal simple state diagram. The way the OPCodes are processed follows the picture "trx_in_sig_state_machine.png". At anytime the script can be used "stand alone". Just need to provide a sig script as parameter: 

./trx_in_sig_script.sh <sig scipt hex codes> 
   48: OP_DATA_0x48
   30: OP_Length_0x30
   45: OP_LENGTH_0x45
   02: OP_INT_0x02
   21: OP_LENGTH_0x21 *** this is SIG X
       00A428348FF55B2B:59BC55DDACB1A00F
       4ECDABE282707BA5:185D39FE9CDF05D7
       F0
   02: OP_INT_0x02
   20: OP_LENGTH_0x20 *** this is SIG Y
       74232DAE76965B63:11CEA2D9E5708A0F
       137F4EA2B0E36D08:18450C67C9BA259D
       
   01: OP_SIGHASHALL *** This terminates the sigs
 
   21: OP_DATA_0x21
   02: OP_INT_0x02
       025F95E8A33556E9:D7311FA748E9434B
       333A4ECFB590C773:480A196DEAB0DEDE
       E1
* This is Public ECDSA Key, corresponding bitcoin address is:
1HTNtayFkoBV28wqDygMbW33qSnRjxAuNR 


#################################
### file trx_out_pk_script.sh ###
#################################
This shell script tries to decode the TRX-OUT public key script via it's internal simple state diagram. The way the OPCodes are processed follows the picture "trx_out_pk_state_machine.png". At anytime the script can be used "stand alone". Just need to provide a pubkey script as parameter:

./trx_out_pk_script.sh <PK_Script>
   76: OP_DUP
   A9: OP_HASH160
   14: OP_Data14 (= decimal 20)
       6AF1D17462C6146A:8A61217E8648903A
       CD3335F1
   88: OP_EQUALVERIFY
   AC: OP_CHECKSIG
* This is a P2PKH script

The string of the 20 bytes in the middle of this output is the hexadecimal representation of the Bitcoin address. To show the "human readable" chars, a third script is used:


###############################
### file base58check_enc.sh ###
###############################
This shell script tries to decode the addresses in BITCOIN SCRIPTs. It reads the hex codes, does a base58 conversion, and displays the bitcoin address. At anytime the file can be used "stand alone". Just provide the 20 hex bytes as parameter:

./base58check_enc.sh -q 6AF1D17462C6146A8A61217E8648903ACD3335F1
1AkUKA3NNQt4gs3GGexhacnkSMcmYHsN3S

The "-q" parameter is for "quiet" output. Without it, script will display details on the steps. 


#############################
### file trx_testcases.sh ###
#############################
This shell script supports the development process, and verifies the script output(s).
1.) build sha256 checksums of the involved source code scripts
2.) runs script "trx2txt.sh" with different parameters and transactions
3.) sent output into a file, and calculate it’s SHA256 hash value
4.) compare checksums 

Most easily it is used like this:

  ./trx_testcases.sh > tmptest
   openssl dgst -sha256 tmptest

which provides a hash of all hashes. This can be easily compared on all platforms. When hash is equal on all platforms, code is ready to be uploaded to GITHUB (or similiar). 

./trx_testcases.sh -l|--log
"-l", a log file ("trx_testcases.sh.log") is created. All checks are performed.

./trx_testcases.sh -?|-h|--help
"-h" displays a help text

./trx_testcases.sh 1|2|3|4|5|6|7|8
[1-8] runs the specific testcases, to get quickly the sha256 hashes


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

Documentation files are not included in the hashing with ./trx_testcases.sh. 

