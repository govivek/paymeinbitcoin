# Use ubuntu as base image for bitcoin
FROM ubuntu:20.04
# Run update
RUN apt update
# set environment variable `BITCOIND_VERSION` to current version
ENV BITCOIND_VERSION 0.21.0
# Download binaries for Bitcoin Core
ADD https://bitcoincore.org/bin/bitcoin-core-${BITCOIND_VERSION}/bitcoin-${BITCOIND_VERSION}-x86_64-linux-gnu.tar.gz /usr/local
# Unzip and install binaries for Bitcoin Core
RUN cd /usr/local/ \
	&& tar -zxf bitcoin-${BITCOIND_VERSION}-x86_64-linux-gnu.tar.gz \
	&& cd bitcoin-${BITCOIND_VERSION} \
	&& install bin/* /usr/local/bin \
	&& install include/* /usr/local/include \
	&& install -v lib/* /usr/local/lib
# `bitcoind` dir contains `bitcoin.conf` configuration for regtest-mode/rpcuser/rpcpassword/rpcport/zeromq etc.
ADD bitcoind /bitcoind
# Make a symbolic link
RUN ln -s /bitcoind /root/.
# Entrypoint script starts bitcoin core daemon while running the container from this image
ADD bitcoind-entrypoint.sh /usr/local/bin
# Make `bitcoind-entrypoint.sh` executable
RUN chmod +x /usr/local/bin/bitcoind-entrypoint.sh

# bitcoind regtest RPC
EXPOSE 18443/tcp
# zmqpubrawblock - ZeroMQ : publisher(Bitcoin)/subscriber(Lightning) messaging system
EXPOSE 12005/tcp
# zmqpubrawtx - Enable publish raw transaction to address as per `bitcoin.conf` configuration
EXPOSE 12006/tcp
# Set `/bitcoind` as working directory
WORKDIR /bitcoind
# Execute `bitcoind-entrypoint.sh` script while running the container
ENTRYPOINT ["/usr/local/bin/bitcoind-entrypoint.sh"]
# Print logs
CMD ["tail", "-f", "/bitcoind/regtest/debug.log"]
