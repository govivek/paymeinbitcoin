#!/bin/bash
set -Eeuo pipefail

echo Starting bitcoind...
bitcoind -datadir=/bitcoind -daemon
until bitcoin-cli -datadir=/bitcoind -rpcwait getblockchaininfo  > /dev/null 2>&1
do
	sleep 1
done
echo bitcoind started...

# Executing CMD
echo "$@"
exec "$@"
