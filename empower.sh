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
if [ ! $EMPOWER_NODENAME ]; then
	read -p "Enter node name: " EMPOWER_NODENAME
	echo 'export EMPOWER_NODENAME='$EMPOWER_NODENAME >> $HOME/.bash_profile
fi
read -p "Enter node port: " EMP_PORT
echo 'export EMP_PORT='$EMP_PORT >> $HOME/.bash_profile
if [ ! $WALLET ]; then
	echo "export WALLET=wallet" >> $HOME/.bash_profile
fi
echo "export EMP_CHAIN_ID=circulus-1" >> $HOME/.bash_profile
echo "export EMP_PORT=${EMP_PORT}" >> $HOME/.bash_profile
source $HOME/.bash_profile

echo '================================================='
echo -e "Your node name: \e[1m\e[32m$EMPOWER_NODENAME\e[0m"
echo -e "Your wallet name: \e[1m\e[32m$WALLET\e[0m"
echo -e "Your chain name: \e[1m\e[32m$EMP_CHAIN_ID\e[0m"
echo -e "Your port: \e[1m\e[32m$EMP_PORT\e[0m"
echo '================================================='
sleep 2

echo -e "\e[1m\e[32m1. Updating packages... \e[0m" && sleep 1
# update
sudo apt update && sudo apt upgrade -y

echo -e "\e[1m\e[32m2. Installing dependencies... \e[0m" && sleep 1
# packages
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu gcc git jq chrony liblz4-tool -y

# install go
cd $HOME
version="1.20.4"
wget "https://golang.org/dl/go$version.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$version.linux-amd64.tar.gz"
rm "go$version.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
go version

echo -e "\e[1m\e[32m3. Downloading and building binaries... \e[0m" && sleep 1
# download binary
cd $HOME
git clone https://github.com/EmpowerPlastic/empowerchain
cd empowerchain/chain
make build
chmod +x ./build/empowerd && mv ./build/empowerd /usr/local/bin/empowerd


# config
empowerd config chain-id $EMP_CHAIN_ID
empowerd config keyring-backend test
empowerd config node tcp://localhost:${EMP_PORT}657

# init
empowerd init $EMPOWER_NODENAME --chain-id $EMP_CHAIN_ID


# download genesis and addrbook
wget -O $HOME/.empowerchain/config/genesis.json "https://services.circulus-1.empower.aviaone.com/genesis.json"
wget -O $HOME/.empowerchain/config/addrbook.json "https://services.circulus-1.empower.aviaone.com/addrbook.json"
# set peers and seeds
SEEDS=""
PEERS="ca8b9d5fecd3258cb8bb4164017114898cd63ad5@empower-testnet.nodejumper.io:31656,6dae9286b4ef23151148922befc0f32a00cc1ec4@65.21.134.202:26656,ab4b4331d161cf0e98d3244e30225e4f38ac8d2f@65.109.28.177:44656,d9307a7ba665a54e65f4fa5dbb5401448e1c3456@65.109.30.117:30656,46b552c62df0523a2bfff285eb384e4b197484aa@65.21.133.125:33656,408980a63332b230a90ad549e93162dab303836f@65.108.225.158:17456,605b175a3cf6f71d454840baef08d0e81d94935f@65.108.52.192:46656,86669cd5e5914f862578d43de483f49e93d396b1@51.83.35.129:26656,b405572f7bf70f681d1e82f196e1399bf90a9d8a@138.201.197.163:26656,c5d44acd2f0ee122352d2f8154d9b29aeb9bf0ec@159.69.65.97:36656,2b3da30140b57d64a57a25485c237f9c7c3c3324@194.163.136.90:26656,8abceaabc650d81a751e40382f80af6c98ba466f@185.239.209.180:35656,333de3fc2eba7eead24e0c5f53d665662b2ba001@35.187.86.119:26656,b5df76282e8704d253012688613d4eb725d3cb12@77.37.176.99:56656,8498049b61177a53b3f0e6b8f7c4a574251a2bbb@149.102.157.96:36656,56d05d4ae0e1440ad7c68e52cc841c424d59badd@96.234.160.22:26656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.empowerchain/config/config.toml

# set custom ports

sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${EMP_PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${EMP_PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${EMP_PORT}060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${EMP_PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${EMP_PORT}660\"%" $HOME/.empowerchain/config/config.toml
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${EMP_PORT}317\"%; s%^address = \":8080\"%address = \":${EMP_PORT}080\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${EMP_PORT}090\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${EMP_PORT}091\"%" $HOME/.empowerchain/config/app.toml

# config pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="10"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.empowerchain/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.empowerchain/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.empowerchain/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.empowerchain/config/app.toml

# reset and download snapshot
empowerd tendermint unsafe-reset-all --home $HOME/.empowerchain
if curl -s --head curl https://testnet-files.itrocket.net/empower/snap_empower.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://testnet-files.itrocket.net/empower/snap_empower.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.empowerchain
    else
  echo no have snap
fi

wget -O $HOME/.empowerchain/config/addrbook.json "https://services.circulus-1.empower.aviaone.com/addrbook.json"

echo -e "\e[1m\e[32m4. Starting service... \e[0m" && sleep 1
# create service
sudo tee /etc/systemd/system/empowerd.service > /dev/null <<EOF
[Unit]
Description=empower
After=network-online.target

[Service]
User=$USER
ExecStart=$(which empowerd) start --home $HOME/.empowerchain
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# start service
sudo systemctl daemon-reload
sudo systemctl enable empowerd
sudo systemctl restart empowerd

echo '=============== SETUP FINISHED ==================='
echo -e 'To check logs: \e[1m\e[32mjournalctl -u empowerd -f -o cat\e[0m'
echo -e "To check sync status: \e[1m\e[32mcurl -s localhost:${EMP_PORT}657/status | jq .result.sync_info\e[0m"
