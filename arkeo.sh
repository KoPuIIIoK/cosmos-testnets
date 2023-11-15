#!/bin/bash
exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists curl; then
echo ''
else
  sudo apt update && sudo apt install curl -y < "/dev/null"
fi
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi
sleep 1 && curl -s https://api.nodes.guru/logo.sh | bash && sleep 1

NODE=Arkeo
NODE_HOME=$HOME/.arkeo
BINARY=arkeod
CHAIN_ID=arkeo
echo 'export CHAIN_ID='\"${CHAIN_ID}\" >> $HOME/.bash_profile

if [ ! $VALIDATOR ]; then
    read -p "Enter validator name: " VALIDATOR
    echo 'export VALIDATOR='\"${VALIDATOR}\" >> $HOME/.bash_profile
fi
echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
source $HOME/.bash_profile
sleep 1
cd $HOME
sudo apt update
sudo apt install make clang pkg-config lz4 libssl-dev build-essential git jq ncdu bsdmainutils htop -y < "/dev/null"

echo -e '\n\e[42mInstall Go\e[0m\n' && sleep 1
cd $HOME
if [ ! -f "/usr/local/go/bin/go" ]; then
    VERSION=1.21.1
    wget -O go.tar.gz https://go.dev/dl/go$VERSION.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go.tar.gz && rm go.tar.gz
    echo 'export GOROOT=/usr/local/go' >> $HOME/.bash_profile
    echo 'export GOPATH=$HOME/go' >> $HOME/.bash_profile
    echo 'export GO111MODULE=on' >> $HOME/.bash_profile
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile && . $HOME/.bash_profile
    go version
fi

echo -e '\n\e[42mInstall software\e[0m\n' && sleep 1
cd $HOME
rm -rf arkeod
wget -O arkeod https://snapshots.nodes.guru/arkeo/arkeod
sudo chmod +x $HOME/arkeod
sudo mv $HOME/arkeod /usr/local/bin/arkeod || exit
sleep 1
$BINARY init "$VALIDATOR" --chain-id $CHAIN_ID
SEEDS="20e1000e88125698264454a884812746c2eb4807@seeds.lavenderfive.com:22856,df0561c0418f7ae31970a2cc5adaf0e81ea5923f@arkeo-testnet-seed.itrocket.net:18656"
sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.001uarkeo\"/" $NODE_HOME/config/app.toml
sed -i.bak -e "s/^seeds *=.*/seeds = \"$SEEDS\"/" $NODE_HOME/config/config.toml
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="10"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $NODE_HOME/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $NODE_HOME/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $NODE_HOME/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $NODE_HOME/config/app.toml
sed -i -e "s/indexer *=.*/indexer = \"null\"/g" $NODE_HOME/config/config.toml

wget -O $HOME/.arkeo/config/genesis.json https://snapshots.nodes.guru/arkeo/genesis.json
$BINARY tendermint unsafe-reset-all


echo -e '\n\e[42mDownloading a snapshot\e[0m\n' && sleep 1
curl https://snapshots.nodes.guru/arkeo/arkeo.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.arkeo

echo -e '\n\e[42mRunning\e[0m\n' && sleep 1
echo -e '\n\e[42mCreating a service\e[0m\n' && sleep 1

echo "[Unit]
Description=$NODE Node
After=network.target

[Service]
User=$USER
Type=simple
ExecStart=/usr/local/bin/$BINARY start 
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target" > $HOME/$BINARY.service
sudo mv $HOME/$BINARY.service /etc/systemd/system
sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF


sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:15958\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:15957\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:15960\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:15956\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":15966\"%" $HOME/.arkeo/config/config.toml
sed -i -e "s%^address = \"tcp://localhost:1317\"%address = \"tcp://0.0.0.0:15917\"%; s%^address = \":8080\"%address = \":15980\"%; s%^address = \"localhost:9090\"%address = \"0.0.0.0:15990\"%; s%^address = \"localhost:9091\"%address = \"0.0.0.0:15991\"%; s%:8545%:15945%; s%:8546%:15946%; s%:6065%:15965%" $HOME/.arkeo/config/app.toml


echo -e '\n\e[42mRunning a service\e[0m\n' && sleep 1
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable $BINARY
sudo systemctl restart $BINARY

echo -e '\n\e[42mCheck node status\e[0m\n' && sleep 1
if [[ `service $BINARY status | grep active` =~ "running" ]]; then
  echo -e "Your $NODE node \e[32minstalled and works\e[39m!"
  echo -e "You can check node status by the command \e[7mservice $BINARY status\e[0m"
  echo -e "Press \e[7mQ\e[0m for exit from status menu"
else
  echo -e "Your $NODE node \e[31mwas not installed correctly\e[39m, please reinstall."
fi
