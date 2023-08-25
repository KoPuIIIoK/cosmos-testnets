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


if [ ! $DYM_MONIKER ]; then
	read -p "Enter node name: " DYM_MONIKER
	echo 'export MONIKER_AND='$DYM_MONIKER >> $HOME/.bash_profile
fi


echo -e "Your node name: \e[1m\e[32m$DYM_MONIKER\e[0m"





# Clone project repository
cd $HOME
rm -rf dymension
git clone https://github.com/dymensionxyz/dymension.git
cd dymension
git checkout v1.0.2-beta

# Build binaries
make build

# Prepare binaries for Cosmovisor
mkdir -p $HOME/.dymension/cosmovisor/genesis/bin
mv bin/dymd $HOME/.dymension/cosmovisor/genesis/bin/
rm -rf build

# Create application symlinks
ln -s $HOME/.dymension/cosmovisor/genesis $HOME/.dymension/cosmovisor/current
sudo ln -s $HOME/.dymension/cosmovisor/current/bin/dymd /usr/local/bin/dymd


# Download and install Cosmovisor
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.4.0

# Create service
sudo tee /etc/systemd/system/dymd.service > /dev/null << EOF
[Unit]
Description=dymension-testnet node service
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=$HOME/.dymension"
Environment="DAEMON_NAME=dymd"
Environment="UNSAFE_SKIP_BACKUP=true"

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable dymd


# Set node configuration
dymd config chain-id froopyland_100-1
dymd config keyring-backend test
dymd config node tcp://localhost:46657

# Initialize the node
dymd init $DYM_MONIKER --chain-id froopyland_100-1

# Download genesis and addrbook
curl -Ls https://snapshots.kjnodes.com/dymension-testnet/genesis.json > $HOME/.dymension/config/genesis.json
curl -Ls https://snapshots.kjnodes.com/dymension-testnet/addrbook.json > $HOME/.dymension/config/addrbook.json

# Add seeds
sed -i -e "s|^seeds *=.*|seeds = \"3f472746f46493309650e5a033076689996c8881@dymension-testnet.rpc.kjnodes.com:14659\"|" $HOME/.dymension/config/config.toml

# Set minimum gas price
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.025udym,0.025uatom\"|" $HOME/.dymension/config/app.toml

# Set pruning
sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "19"|' \
  $HOME/.dymension/config/app.toml

# Set custom ports
sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:46658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:46657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:46060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:46656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":46660\"%" $HOME/.dymension/config/config.toml
sed -i -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:46317\"%; s%^address = \":8080\"%address = \":46080\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:46090\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:46091\"%; s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:46545\"%; s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:46546\"%" $HOME/.dymension/config/app.toml


curl -L https://snapshots.kjnodes.com/dymension-testnet/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.dymension
[[ -f $HOME/.dymension/data/upgrade-info.json ]] && cp $HOME/.dymension/data/upgrade-info.json $HOME/.dymension/cosmovisor/genesis/upgrade-info.json

sudo systemctl start dymd && sudo journalctl -u dymd -f --no-hostname -o cat
