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


if [ ! $MONIKER_CASCAD ]; then
	read -p "Enter node name: " MONIKER_CASCAD
	echo 'export MONIKER_CASCAD='$MONIKER_CASCAD >> $HOME/.bash_profile
fi
if [ ! $CASCAD_PORT ]; then
	read -p "Enter port number: " CASCAD_PORT
	echo 'export CASCAD_PORT='$CASCAD_PORT >> $HOME/.bash_profile
fi


echo -e "Your node name: \e[1m\e[32m$MONIKER_CASCAD\e[0m"
echo -e "Your port: \e[1m\e[32m$CASCAD_PORT\e[0m"


git clone https://github.com/cascadiafoundation/cascadia
cd cascadia 
git checkout v0.1.2 
make install

cascadiad config chain-id cascadia_6102-1
cascadiad config keyring-backend test
cascadiad config node tcp://localhost:${CASCAD_PORT}657

cascadiad init $MONIKER_CASCAD --chain-id cascadia_6102-1

wget -O $HOME/.cascadiad/config/genesis.json "https://anode.team/Cascadia/test/genesis.json"
wget -O $HOME/.cascadiad/config/addrbook.json "https://anode.team/Cascadia/test/addrbook.json"

EXADDRESS=$(wget -qO- eth0.me)
sed -i.bak -e "s/^external_address *=.*/external_address = \"$EXADDRESS:${CASCAD_PORT}656\"/" $HOME/.cascadiad/config/config.toml
PEERS="1d61222b7b8e180aacebfd57fbd2d8ab95ebdc4c@65.109.93.152:35656"
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.cascadiad/config/config.toml
SEEDS=""
sed -i.bak -e "s/^seeds =.*/seeds = \"$SEEDS\"/" $HOME/.cascadiad/config/config.toml
sed -i 's/max_num_inbound_peers =.*/max_num_inbound_peers = 50/g' $HOME/.cascadiad/config/config.toml
sed -i 's/max_num_outbound_peers =.*/max_num_outbound_peers = 25/g' $HOME/.cascadiad/config/config.toml
sed -i -e "s/^filter_peers *=.*/filter_peers = \"true\"/" $HOME/.cascadiad/config/config.toml

sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${CASCAD_PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${CASCAD_PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${CASCAD_PORT}060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${CASCAD_PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${CASCAD_PORT}660\"%" $HOME/.cascadiad/config/config.toml
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${CASCAD_PORT}317\"%; s%^address = \":8080\"%address = \":${CASCAD_PORT}080\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${CASCAD_PORT}090\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${CASCAD_PORT}091\"%" $HOME/.cascadiad/config/app.toml

# config pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="10"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.cascadiad/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.cascadiad/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.cascadiad/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.cascadiad/config/app.toml




sudo tee /etc/systemd/system/cascadiad.service > /dev/null <<EOF
[Unit]
Description=cascadiad node
After=network-online.target

[Service]
User=root
ExecStart=$(which cascadiad) start --home $HOME/.cascadiad
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# reset and download snapshot
cascadiad tendermint unsafe-reset-all --home $HOME/.cascadiad
curl https://testnet-files.itrocket.net/cascadia/snap_cascadia.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.cascadiad

sudo systemctl daemon-reload
sudo systemctl enable cascadiad
sudo systemctl restart cascadiad

journalctl -fu cascadiad -o cat
