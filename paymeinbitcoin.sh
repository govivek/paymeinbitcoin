#!/bin/bash
# Exit if any error occurs
#set -e
set -Eeuo pipefail

# 1. Create a brand new private block-chain based on Bitcoin consensus
#   New private block-chain has been created while running docker container for bitcoind
#   bitcoind started in `bitcoind-entrypoint.sh` by line `bitcoind -datadir=/bitcoind -daemon`

# 2. Mine Bitcoin block in the new block-chain
# 2.1 create or load wallet to receive bitcoin coinbase reward
wallet_name="regtest_wallet_"$RANDOM
docker-compose exec -T bitcoind bitcoin-cli -regtest -datadir=/bitcoind createwallet $wallet_name

echo "generating new address in this wallet"
address=$(docker-compose exec -T bitcoind bash -c "bitcoin-cli -regtest --rpcuser=regtest --rpcpassword=regtest -rpcwallet=$wallet_name getnewaddress")
echo "address:" $address

# 2.2 Mine 101 blocks to make block #1 coinbase reward of 50 coins spendable
docker-compose exec -T bitcoind bitcoin-cli -regtest -datadir=/bitcoind generatetoaddress 101 ${address}
bitcoin_balance=$(docker-compose exec -T bitcoind bash -c "bitcoin-cli -regtest --rpcuser=regtest --rpcpassword=regtest -datadir=/bitcoind -rpcwallet=$wallet_name getbalance")
echo "Total bitcoin Balance:" $bitcoin_balance

# 3. Send coins to Lightning Node Source ("You")
# 3.1 generate a wallet address for "You"
your_wallet_address=$(docker-compose exec -T You bash -c "lncli -n regtest newaddress np2wkh | jq -r .address")
# 3.2 send half of the coins to "You"
docker-compose exec -T bitcoind bitcoin-cli -datadir=/bitcoind -rpcwallet=$wallet_name sendtoaddress ${your_wallet_address} $((${bitcoin_balance%.*} / 2))
your_wallet_balance=$(docker-compose exec -T You bash -c "lncli -n regtest walletbalance | jq -r .total_balance")
echo "You" New Wallet Balance: ${your_wallet_balance}
# 3.3 Mine 6 blocks for 6 confirmations of the transaction 
docker-compose exec -T bitcoind bitcoin-cli -regtest --rpcuser=regtest --rpcpassword=regtest -datadir=/bitcoind generatetoaddress 6 ${address}
echo Getting Lightning node IDs
your_address=$(docker-compose exec -T You bash -c "lncli -n regtest getinfo | jq -r .identity_pubkey")
my_address=$(docker-compose exec -T Me bash -c "lncli -n regtest getinfo | jq -r .identity_pubkey")
echo You:  ${your_address}
echo Me:   ${my_address}

echo Sending coins from "You" to "Me" through direct Lightning network channel...

# 4. Source Lightning node connect to Destination
docker-compose exec -T You lncli -n regtest listpeers | grep ${my_address} ||
docker-compose exec -T You lncli -n regtest connect ${my_address}@Me

# 5. Open a lightning channel between "You" and "Me"
docker-compose exec -T You lncli -n regtest openchannel ${my_address} 1000000

# 6. Funding Transaction gets confirmed after 6 on-chain confirmations
docker-compose exec -T bitcoind bitcoin-cli -datadir=/bitcoind generatetoaddress 6 ${address}

# 7. "Me" creates payment invoice request
echo Get sats invoice from "Me"
my_invoice=$(docker-compose exec -T Me bash -c "lncli -n regtest addinvoice 5000 | jq -r .payment_request")
echo Me invoice ${my_invoice}

# 8. "You" pay invoice request from "Me"
echo You pay Me invoice of 5k sats through the lightning network channel
docker-compose exec -T You lncli -n regtest payinvoice ${my_invoice}

# 9. close channel to receive coins in wallet to spend
channel=$(docker-compose exec -T Me bash -c "lncli -n regtest listchannels | jq '.channels[0] | .channel_point'")
echo "closing channel..."
docker-compose exec -T Me lncli -n regtest closechannel --funding_txid=${channel:1:${#channel}-4} --output_index=${channel:${#channel}-2:1}

# 10. Make one on-chain block confirmation
docker-compose exec -T bitcoind bitcoin-cli -datadir=/bitcoind generatetoaddress 1 ${address}
me_wallet_balance=$(docker-compose exec -T Me bash -c "lncli -n regtest walletbalance | jq -r .confirmed_balance")
echo Me New Confirmed Wallet Balance: ${me_wallet_balance}

# if "Me" wallet balance goes over 0, then print
if [[ ${me_wallet_balance} -gt 0 ]]
then
    echo "Hurray! You just paid Me in bitcoin!!!"
fi