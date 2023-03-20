#!/bin/bash

echo -e "\033[1;36m"
echo " ::::::'##:'########:'########:'########::'####:'##::::'## ";
echo " :::::: ##: ##.....::... ##..:: ##.... ##:. ##::. ##::'## ";
echo " :::::: ##: ##:::::::::: ##:::: ##:::: ##:: ##:::. ##'## ";
echo " :::::: ##: ######:::::: ##:::: ########::: ##::::. ### ";
echo " '##::: ##: ##...::::::: ##:::: ##.. ##:::: ##:::: ## ## ";
echo "  ##::: ##: ##:::::::::: ##:::: ##::. ##::: ##::: ##:. ## ";
echo " . ######:: ########:::: ##:::: ##:::. ##:'####: ##:::. ## ";
echo " :......:::........:::::..:::::..:::::..::....::..:::::..::";
echo -e "\e[0m"


sleep 2


# set vars
if [ ! $SGE_MONIKER ]; then
	read -p "Enter node name: " SGE_MONIKER
	echo 'export SGE_MONIKER='$SGE_MONIKER >> $HOME/.bash_profile
fi
read -p "Enter node port: " SGE_PORTS
echo 'export SGE_PORTS='$SGE_PORTS >> $HOME/.bash_profile
if [ ! $WALLET ]; then
	echo "export WALLET=wallet" >> $HOME/.bash_profile
fi
echo "export SGE_CHAINID=sge-network-2" >> $HOME/.bash_profile
echo "export SGE_PORTS=${SGE_PORTS}" >> $HOME/.bash_profile
source $HOME/.bash_profile

echo '================================================='
echo -e "Your node name: \e[1m\e[32m$SGE_MONIKER\e[0m"
echo -e "Your wallet name: \e[1m\e[32m$WALLET\e[0m"
echo -e "Your chain name: \e[1m\e[32m$SGE_CHAINID\e[0m"
echo -e "Your port: \e[1m\e[32m$SGE_PORTS\e[0m"
echo '================================================='
sleep 2

echo -e "\e[1m\e[32m1. Updating packages... \e[0m" && sleep 1
# update
sudo apt update && sudo apt upgrade -y

echo -e "\e[1m\e[32m2. Installing dependencies... \e[0m" && sleep 1
# packages
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu gcc git jq chrony liblz4-tool -y

# install go
ver="1.18.2"
cd $HOME
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
source ~/.bash_profile
go version

echo -e "\e[1m\e[32m3. Downloading and building binaries... \e[0m" && sleep 1
# download binary
cd $HOME
git clone https://github.com/sge-network/sge
git clone https://github.com/sge-network/networks
cd sge
git fetch --tags
git checkout v0.0.5
cd sge
go mod tidy
make install


# config
sged config chain-id $SGE_CHAINID
sged config keyring-backend test
sged config node tcp://localhost:${SGE_PORTS}657

# init
sged init $SGE_MONIKER --chain-id $SGE_CHAINID


# download genesis and addrbook
wget -O $HOME/.sge/config/genesis.json "https://raw.githubusercontent.com/sge-network/networks/master/sge-network-2/genesis.json"

# set custom ports

sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${SGE_PORTS}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${SGE_PORTS}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${SGE_PORTS}060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${SGE_PORTS}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${SGE_PORTS}660\"%" $HOME/.sge/config/config.toml
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${SGE_PORTS}317\"%; s%^address = \":8080\"%address = \":${SGE_PORTS}080\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${SGE_PORTS}090\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${SGE_PORTS}091\"%" $HOME/.sge/config/app.toml

# config pruning
pruning="custom" && \
pruning_keep_recent="100" && \
pruning_keep_every="0" && \
pruning_interval="10" && \
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" ~/.sge/config/app.toml && \
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" ~/.sge/config/app.toml && \
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" ~/.sge/config/app.toml && \
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" ~/.sge/config/app.toml
indexer="null" && \
sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.sge/config/config.toml

# optimisation
echo -e "                     \e[1m\e[32m4. Node optimization and improvement--> \e[0m" && sleep 1

sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0usge\"/" $HOME/.sge/config/app.toml
sed -i -e "s/^filter_peers *=.*/filter_peers = \"true\"/" $HOME/.sge/config/config.toml
peers="62b76a24869829fb3be53c25891ba37eca5994bd@95.217.224.252:26656,b29612454715a6dc0d1f0c42b426bf30f1d27738@78.46.99.50:24656,14823c9230ac2eb50fd48b7313e8ddd4c13207c6@94.130.219.37:26000,cfa86646e5eb05e111e7dde27750ff8ebe67d165@89.117.56.126:23956,43b05a6bab7ca735397e9fae2cb0ad99977cf482@34.83.191.67:26656,ddcd5fda167e6b45208faed8fd7e2f0640b4185c@52.44.14.245:26656,a05353fe9ae39dd0edbfa6341634dec781d84a5c@65.108.105.48:17756,1168931936c638e92ea6d93e2271b3fe5faee6d1@135.125.247.228:26656,27f0b281ea7f4c3db01fdb9f4cf7cc910ad240a6@209.34.205.57:26656,b4f800aa8ff11d0d7ab3f5ce19230f049dfebe4b@38.242.199.160:26656,8c74885d4310f606986c88e9613f5e48c9e154dd@65.108.2.41:56656,a13512dbb3def06f91aef81afb397db63d78b25c@51.195.89.114:20656,bbf84e77c0defea82d389e1bd0940d7718f0ee34@103.230.84.4:26656,3e644c24129e14d457e82bab3b5a16c510b12927@50.19.180.153:26656,d200a21e2b3edab24679d4544fea48471515098f@65.108.225.158:17756,dc831d440c18c4a4f72250806cd03e5b240f8935@3.15.209.96:26656"
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.sge/config/config.toml
seeds=""
sed -i.bak -e "s/^seeds =.*/seeds = \"$seeds\"/" $HOME/.sge/config/config.toml
sed -i 's/max_num_inbound_peers =.*/max_num_inbound_peers = 50/g' $HOME/.sge/config/config.toml
sed -i 's/max_num_outbound_peers =.*/max_num_outbound_peers = 50/g' $HOME/.sge/config/config.toml

# reset
sged tendermint unsafe-reset-all

wget -O $HOME/.sge/config/addrbook.json "https://raw.githubusercontent.com/obajay/nodes-Guides/main/SGE/addrbook.json"

echo -e "\e[1m\e[32m4. Starting service... \e[0m" && sleep 1
# create service
sudo tee /etc/systemd/system/sged.service > /dev/null <<EOF
[Unit]
Description=sge
After=network-online.target

[Service]
User=$USER
ExecStart=$(which sged) start
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# start service
sudo systemctl daemon-reload
sudo systemctl enable sged
sudo systemctl restart sged

echo '=============== SETUP FINISHED ==================='
echo -e 'To check logs: \e[1m\e[32mjournalctl -u sged -f -o cat\e[0m'
echo -e "To check sync status: \e[1m\e[32mcurl -s localhost:${SGE_PORTS}657/status | jq .result.sync_info\e[0m"
