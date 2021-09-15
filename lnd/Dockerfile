# use go-lang docker image
FROM golang:1.13 as lnd-base
# set GOPATH environment variable to /go
ENV GOPATH /go
# set /go/src as working directory
WORKDIR $GOPATH/src

# LND
# set LND_VER environment variable to current version `v0.11.1-beta`
ENV LND_VER v0.11.1-beta
# download lnd implementation of the Lightning network
RUN go get -d github.com/lightningnetwork/lnd
# set `/go/src/github.com/lightningnetwork/lnd` as working directory
WORKDIR $GOPATH/src/github.com/lightningnetwork/lnd
# checkout `v0.11.1-beta`
RUN git checkout tags/${LND_VER}
# install lnd
RUN make && make install

## Multi-stage build
# use ubuntu as base image 
FROM ubuntu:20.04 AS lnd-run
# update and install `jq` utility for querying json-data
RUN apt update && apt install -y jq 
# copy lnd implemenation from `lnd-base` image
COPY --from=lnd-base /go /go
# copy bitcoin core binaries from paymeinbitcoin/bitcoind image
COPY --from=paymeinbitcoin/bitcoind /usr/local/ /usr/local/
# set GOPATH environment variable to /go
ENV GOPATH /go
# add go to the path variable
ENV PATH $PATH:$GOPATH/bin
# `lnd` dir contains `lnd.conf` configuration for bitcoind regtest-mode/rpcuser/rpcpassword/rpchost/zeromq etc.
ADD lnd /lnd
# Make a symbolic link
RUN ln -s /lnd /root/.lnd
# Entrypoint script starts lnd node once bitcoin core daemon has started
ADD lnd-entrypoint.sh /usr/local/bin
# Make `lnd-entrypoint.sh` executable
RUN chmod +x /usr/local/bin/lnd-entrypoint.sh

# LND P2P
EXPOSE 9735/tcp
# set lnd as working directory
WORKDIR /lnd
# Execute `lnd-entrypoint.sh` script while running the container
ENTRYPOINT ["/usr/local/bin/lnd-entrypoint.sh"]
# Print logs
CMD ["tail", "-f", "/lnd/logs/bitcoin/regtest/lnd.log"]
