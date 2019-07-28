#!/bin/bash
# First script of "joker utxo teleportation" technique
#
# Adapt the options (mandatory)
# Call it once to create 3 addys and backup privkeys
# Fund the address of "" account (getaccountaddress "")
# then call fill3addys.sh
# then call sendfrom3addys.sh

# Options

# Full path to komodo-cli
komodoexec=/home/phm87/komodo/src/komodo-cli
#utxo split count
utxo_split_count=10
#NN addy
NN=RYTWfHVK5p8jeXye4rxcPB3W8Y9T5AV2U6

# end of options


addy1=$($komodoexec getnewaddress)
echo "addy1 = $addy1"
addy2=$($komodoexec getnewaddress)
echo "addy2 = $addy2"
addy3=$($komodoexec getnewaddress)
echo "addy3 = $addy3"

privkey1=$($komodoexec dumpprivkey $addy1)
privkey2=$($komodoexec dumpprivkey $addy2)
privkey3=$($komodoexec dumpprivkey $addy3)

begin="#!/bin/bash\n
addy1=$addy1\n
privkey1=$privkey1\n
addy2=$addy2\n
privkey2=$privkey2\n
addy3=$addy3\n
privkey3=$privkey3\n
komodoexec=$komodoexec\n

waitforconfirm () {\n
  confirmations=0\n
  while [[ \${confirmations} -lt 1 ]]; do\n
    sleep 1\n
    confirmations=\$($komodoexec gettransaction \$1 2> /dev/null | jq -r .confirmations) > /dev/null 2>&1\n
    # Keep re-broadcasting\n
    $komodoexec sendrawtransaction \$($komodoexec getrawtransaction \$1 2> /dev/null) > /dev/null 2>&1\n
  done\n
}"

# https://bitcoin.stackexchange.com/questions/41670/how-to-send-btc-from-the-specific-address-using-bitcoin-api

filladdy="$begin\n
res1=\$($komodoexec setaccount $addy1 addy1)\n
res2=\$($komodoexec setaccount $addy2 addy2)\n
res3=\$($komodoexec setaccount $addy3 addy3)\n

bal=\$($komodoexec getbalance \"\")\n
bal=\$(bc -l <<< \"scale=4;\$bal/3-0.0001\")\n
echo \$bal\n

#red1=\$($komodoexec sendfrom \"\" \"\$addy1\" \$bal)\n
#red2=\$($komodoexec sendfrom \"\" \"\$addy2\" \$bal)\n
#red3=\$($komodoexec sendfrom \"\" \"\$addy3\" \$bal)\n

# bitcoin-cli createrawtransaction "[{\"txid\":\"myid\",\"vout\":0}]" "[{\"address\":0.01}]"\n

#mainaddy=\$($komodoexec getaccountaddress \"\")\n
utxo=\$($komodoexec listunspent | jq '[.[]| select(.account==\"\")][0]')\n
txid=\$(echo \$utxo | jq -r .txid)\n
echo \$txid\n
vout=\$(echo \$utxo | jq -r .vout)\n
bal=\$(echo \$utxo | jq -r .amount)\n
echo \$bal\n
bal=\$(bc -l <<< \"scale=4;\$bal/3-0.0001\")\n
echo \$bal\n

rawtx=\$($komodoexec createrawtransaction \"[{\\\"txid\\\":\\\"\$txid\\\",\\\"vout\\\":\$vout}]\" \"{\\\"\$addy1\\\":\$bal,\\\"\$addy2\\\":\$bal,\\\"\$addy3\\\":\$bal}\")\n
#echo \"[{\"txid\":\"$txid\",\"vout\":$vout}]\"\n
#echo \"[{\"$addy1\":$bal,\"$addy2\":$bal,\"$addy3\":$bal}]\"\n
#echo \"[{\"txid\":\"\$txid\",\"vout\":\$vout}]\"\n
#echo \"[{\"\$addy1\":\$bal,\"\$addy2\":\$bal,\"\$addy3\":\$bal}]\")\n
echo \$rawtx\n
#echo \$(echo \$rawtx | jq -r .hex)\n
sgtx=\$($komodoexec signrawtransaction \$rawtx)\n
echo \$sgtx\n
echo \$(echo \$sgtx | jq -r .hex)\n
sdtx=\$($komodoexec sendrawtransaction \$(echo \$sgtx | jq -r .hex))\n
echo \$sdtx\n

waitforconfirm \$sdtx

echo \"You can launch the coinsplitfrom\""

echo -e $filladdy>fill3addys.sh
chmod +x fill3addys.sh



coinsplitfrom="$begin\n

# wget https://raw.githubusercontent.com/webworker01/komodotools/master/webworker01/splitfunds\n

sed -i -e 's/NN_ADDRESS=/NN_ADDRESS=\$NN/g' splitfunds\n

# sed -i -e 's/sort_by(.amount)[0]/jq -r --arg addyfrom $addy1  '[.[] | select(.address==\$addyfrom)] | sort_by(.amount)[0]/g' splitfunds\n
#./splitfunds AddyFrom KMD 10\n
"
echo $addy1
echo -e $coinsplitfrom>coinsplitfrom.sh
chmod +x coinsplitfrom.sh
