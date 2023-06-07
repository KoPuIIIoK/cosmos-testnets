#!/bin/bash
source <(curl -s https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/utils/common.sh)

printLogo

read -p "Enter EMPO_WALL name:" EMPO_WALL
echo 'export EMPO_WALL='$EMPO_WALL
read -p "Enter your EMPO_MONIKER :" EMPO_MONIKER
echo 'export EMPO_MONIKER='$EMPO_MONIKER
read -p "Enter your PORT (for example 17, default port=26):" PORT
echo 'export PORT='$PORT

# set vars
echo "export EMPO_WALL="$EMPO_WALL"" >> $HOME/.bash_profile
echo "export EMPO_MONIKER="$EMPO_MONIKER"" >> $HOME/.bash_profile
echo "export EMPOWER_CHAIN_ID="circulus-1"" >> $HOME/.bash_profile
echo "export EMPOWER_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$EMPO_MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$EMPO_WALL\e[0m"
echo -e "Chain id:       \e[1m\e[32m$EMPOWER_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$EMPOWER_PORT\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
! [ -x "$(command -v go)" ] && {
VER="1.20.3"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
}
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin

echo $(go version) && sleep 1

source <(curl -s https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/utils/dependencies_install)

printGreen "4. Installing binary..." && sleep 1
# download binary
cd $HOME
rm -rf empowerchain
git clone https://github.com/EmpowerPlastic/empowerchain
cd empowerchain
git checkout v1.0.0-rc1
cd chain
make install

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
empowerd config node tcp://localhost:${EMPOWER_PORT}657
empowerd config keyring-backend os
empowerd config chain-id circulus-1
empowerd init "$EMPO_MONIKER" --chain-id circulus-1
sleep 1
echo done

printGreen "6. Downloading genesis and addrbook..." && sleep 1
# download genesis and addrbook
wget -O $HOME/.empowerchain/config/genesis.json https://testnet-files.itrocket.net/empower/genesis.json
wget -O $HOME/.empowerchain/config/addrbook.json https://testnet-files.itrocket.net/empower/addrbook.json
sleep 1
echo done

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1
# set seeds and peers
SEEDS="c597ec01e412d6e0f62c6f5501224b7fb8393912@empower-testnet-seed.itrocket.net:16656"
PEERS="c413d3d16e250ddbd8f8d495204b2de46ef36b63@empower-testnet-peer.itrocket.net:16656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.empowerchain/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${EMPOWER_PORT}317%g;
s%:8080%:${EMPOWER_PORT}080%g;
s%:9090%:${EMPOWER_PORT}090%g;
s%:9091%:${EMPOWER_PORT}091%g;
s%:8545%:${EMPOWER_PORT}545%g;
s%:8546%:${EMPOWER_PORT}546%g" $HOME/.empowerchain/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${EMPOWER_PORT}658\"%; 
s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://0.0.0.0:${EMPOWER_PORT}657\"%; 
s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${EMPOWER_PORT}060\"%;
s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${EMPOWER_PORT}656\"%;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${EMPOWER_PORT}656\"%;
s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${EMPOWER_PORT}660\"%" $HOME/.empowerchain/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"nothing\"/" $HOME/.empowerchain/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.empowerchain/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.empowerchain/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's/minimum-gas-prices =.*/minimum-gas-prices = "0.0umpwr"/g' $HOME/.empowerchain/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.empowerchain/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.empowerchain/config/config.toml
sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/empowerd.service > /dev/null <<EOF
[Unit]
Description=empower node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.empowerchain
ExecStart=$(which empowerd) start --home $HOME/.empowerchain
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# reset and download snapshot
empowerd tendermint unsafe-reset-all --home $HOME/.empowerchain
if curl -s --head curl https://testnet-files.itrocket.net/empower/snap_empower.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://testnet-files.itrocket.net/empower/snap_empower.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.empowerchain
    else
  echo no have snap
fi

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable empowerd
sudo systemctl restart empowerd && sudo journalctl -u empowerd -f
