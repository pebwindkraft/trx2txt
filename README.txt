# trx2txt
CLI tools to display Bitcoin TRX data in korn or bash shell 

Suite of shell script tools to display bitcoin transaction info in plain text 
(similiar to the bitcoin core client or blockchain.info output)

All data of a trx is displayed, the sig script and pk pubkey script details (decoded), and the corresponding bitcoin address(es). It works on OpenBSD korn shell, MAC OSX bash(v3) and SuSE Linux bash (v4). Existing tools on the web (Bitcoin CLI tools and others), are written to work only with BASHv4, and do not work on other Unix-like systems. In this script suite, all scripts are nearly POSIX compliant.

Main script is trx2txt.sh which has several command line options (just open with „—-help“).
It refers to https://en.bitcoin.it/wiki/Protocol_specification#tx to disassemble a bitcoin trx. 

The program checks the parameters, checks the version of the shell (for cases where POSIX  compliance can not be achieved, in particular with arrays), checks availability for all necessary sub-programs (openssl, awk, bc …) to decode a transaction, and then begins to break down the transactions.

A script (trx_testcases.sh) with a set of test cases is provided, so verification on different platforms can be achieved easily. Basically this scripts verifies the checksums of the involved files, and then runs several times „trx2txt.sh“ with different parameters and transactions. The output is sent into a file, and it’s SHA256 hash value is calculated. 
Most easily you’d call this:

./trx_testcases.sh > tmptest
openssl dgst -sha256 tmptest

which provides a hash of all hashes and returns (in current v0.1 implementation): 
SHA256(tmptest)= d3045d3f0a09d5f574106d3dd22c36e3b4a5de5a840581bcd1c1233c8afebbca

The code is not written for best performance. There are many calls to shell functions (always a fork during shell execution). Also several external programs are called. 
On readability: current version of programs are heavily commented, so one can follow/understand  the program’s logic. 

###########################

trx2txt.sh
==========

Without parameters, the details of a sample transaction are shown, similar to:
https://blockchain.info/de/rawtx/cc8a279b0736e6a2cc20b324acc5aa688b3af7b63bbb002f46f6573c1ad84408

Alternatively, you can pass the Hex code of a raw trx, for example:
https://blockchain.info/de/rawtx/cc8a279b0736e6a2cc20b324acc5aa688b3af7b63bbb002f46f6573c1ad84408?format=hex

Parameter -v
with parameter „-v“ a more detailed view is provided, along the guidelines of the bitcoin wiki.

Parameter -vv
with parameter „-vv“ a very detailed view is provided, including the decoding of the sig script and the public key script. To decode the bitcoin trx-in and trx-out scripts, and supporting programs are used:

for TRX-IN sig script a shell script is called: „trx_in_sig_script.awk“
for TRX-OUT public key script a shell script is called: „trx_out_pk_script.sh“
for displaying the ("human readable") bitcoin address, a shell script is called: "base58check_enc.sh"


TRX-IN sig script:
==================
A shell file („trx_in_sig_script.sh“) is used for decoding via a „state machine“ the OPCodes. See picture „trx_in_sig_state_machine.png“. At anytime the script can be used „stand alone“. Just need to provide a sig script as parameter: 

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


TRX-OUT public key script:
==========================
A shell file („trx_out_pk_script.sh“) is used for decoding via a „state machine“ the OPCodes. See picture „trx_out_pk_state_machine.png“. At anytime the file can be used „stand alone“. Just need to provide a pubkey script as parameter:

./trx_out_pk_script.sh <PK_Script>
   76: OP_DUP
   A9: OP_HASH160
   14: OP_Data14 (= decimal 20)
       6AF1D17462C6146A:8A61217E8648903A
       CD3335F1
   88: OP_EQUALVERIFY
   AC: OP_CHECKSIG
* This is a P2PKH script

The string of the 20 bytes in the middle of this output is the hexadecimal representation of the bitcoin address. To show the „human readable“ chars, a third script is used:


BITCOIN Addresses in PK_SCRIPT:
===============================
A shell file („base58check_enc.sh“) is used. This script reads the OPCodes, does a base58 conversion, and displays the bitcoin address. At anytime the file can be used „stand alone“. Just provide the 20 hex bytes as parameter:

./base58check_enc.sh -q 6AF1D17462C6146A8A61217E8648903ACD3335F1
1AkUKA3NNQt4gs3GGexhacnkSMcmYHsN3S

The „-q“ parameter is for „quiet“ output. Remove it, and you’ll see details, as outlined here:
https://en.bitcoin.it/wiki/Technical_background_of_version_1_Bitcoin_addresses


Documentation:
==============
README.txt                       - this file :-)
Changelog.txt                    - view changes over the version(s)
trx_OP_CODES_desc.txt            - used references for PK_SCRIPT and their OpCodes
trx_in_sig_state_machine.graphml - graphics source file for the state machine
                                   (java based app: „yEd Graph Editor“)
trx_in_sig_state_machine.png     - the exported png for script sig part
trx_out_pk_state_machine.graphml - graphics source file for the state machine
                                   (java based app: „yEd Graph Editor“)
trx_out_pk_state_machine.png     - the exported png for PUBKEY script
trx_state_matrix.ods             - table with three sheets, showing the state machine’s logic

Documentation files are not included in the hashing with ./trx_testcases.sh. 

