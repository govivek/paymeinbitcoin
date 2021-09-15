#!/bin/bash
set -Eeuo pipefail

# start lightning node only after bitcoin core has already started.
echo Waiting for bitcoind to start...
# check if bitcoin core can be connected and blockchain information can be retrieved
until bitcoin-cli -rpcconnect=bitcoind -rpcport=18443 -rpcuser=regtest -rpcpassword=regtest getblockchaininfo  > /dev/null 2>&1
do
	sleep 1
done

echo Starting lnd...
# now start lightning node
lnd --lnddir=/lnd --noseedbackup > /dev/null &
until lncli --lnddir=/lnd -n regtest getinfo > /dev/null 2>&1
do
	sleep 1
done
echo "lnd started..."

echo "$@"
exec "$@"
