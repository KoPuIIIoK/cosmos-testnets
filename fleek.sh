#!/bin/bash


# "Get Fleek Network" is an attempt to make our software more accessible.
# By providing scripts to automate the installation process of our software,
# we believe that it can help improve the onboarding experience of our users.
#
# Quick install: `curl https://get.fleek.network | bash`
#
# This script automates the process illustrated in our "Getting started" guides
# advanced users might find it better to follow the instructions in the doc version
# If that's your preference, go ahead and check our guides https://docs.fleek.network
#
# Contributing?
# - If you'd like to run the install script against a Lightning branch, use the env var `LIGHTNING_BRANCH``
#
# Found an issue? Please report it here: https://github.com/fleek-network/get.fleek.network

# Workdir
if ! cd "$(mktemp -d)"; then
  echo "👹 Oops! We tried to create a temporary directory to host some install artifacts but failed for some reason..."

  exit 1
fi

# Date
dateRuntime=$(date '+%Y%m%d%H%M%S')

# Constants
kbPerGb=1000000

# Defaults
defaultName="lightning"
defaultCLIBuildName="$defaultName-node"
defaultAlphaTestnetBranch="testnet-alpha-0"
defaultCLIAlias="lgtn"
defaultLightningPath="$HOME/fleek-network/$defaultName"
defaultLightningLogPath="/var/log/$defaultName"
defaultLightningDiagnosticFilename="diagnostic.log"
defaultLightningOutputFilename="output.log"
defaultLightningDiagnosticLogAbsPath="$defaultLightningLogPath/$defaultLightningDiagnosticFilename"
defaultLightningOutputLogAbsPath="$defaultLightningLogPath/$defaultLightningOutputFilename"
defaultLightningSystemdServiceName="$defaultName"
defaultLightningSystemdServicePath="/etc/systemd/system/$defaultLightningSystemdServiceName.service"
defaultLightningConfigFilename="config.toml"
defaultLightningBasePath="$HOME/.$defaultName"
defaultLightningConfigPath="$defaultLightningBasePath/$defaultLightningConfigFilename"
defaultLightningHttpsRepository="https://github.com/fleek-network/$defaultName.git"
defaultDiscordUrl="https://discord.gg/fleekxyz"
defaultDocsSite="https://docs.fleek.network"
defaultMinMemoryKBytesRequired=32000000
defaultMinDiskSpaceKBytesRequired=20000000

# App state
vCPUs=$(nproc --all)
selectedLightningPath="$defaultLightningPath"
vCPUsMinusOne=$(($vCPUs - 1))

# Error codes
err_non_root=87

# Utils
checkSystemHasRecommendedResources() {
  mem=$(awk '/^MemTotal:/{print $2}' /proc/meminfo);
  partDiskSpace=$(df --output=avail -B 1 "$PWD" |tail -n 1)

  if [[ ("$mem" -lt "$defaultMinMemoryKBytesRequired") ]] || [[ ( "$partDiskSpace" -lt "$defaultMinDiskSpaceKBytesRequired" ) ]]; then
    echo "😬 Oh no! You need to have at least $((defaultMinMemoryKBytesRequired / kbPerGb))GB of RAM and $((defaultMinDiskSpaceKBytesRequired / kbPerGb))GB of available disk space."
    echo
    printf -v prompt "\n\n🤖 Are you sure you want to continue (yes/no)?"
    read -r -p "$prompt"$'\n> ' answer

    if [[ "$answer" == [nN] || "$answer" == [nN][oO] ]]; then
      printf "🦖 Exited the installation process\n\n"

      exit 1
    fi

    echo "😅 Alright, let's try that, but your system is below our recommendations, so don't expect it to work correctly..."

    sleep 5

    return 0
  fi
  
  echo "👍 Great! Your system has enough resources (disk space and memory)"
}

identifyOS() {
  unameOut="$(uname -s)"

  case "${unameOut}" in
      Linux*)     os=Linux;;
      Darwin*)    os=Mac;;
      CYGWIN*)    os=Cygwin;;
      MINGW*)     os=MinGw;;
      *)          os="UNKNOWN:${unameOut}"
  esac

  echo "$os" | tr '[:upper:]' '[:lower:]'
}

identifyDistro() {
  if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    echo "$ID"

    exit 0
  fi
  
  uname
}

isOSSupported() {
  os=$(identifyOS)

  if [[ "$os" == "linux" ]]; then
    distro=$(identifyDistro)

    if [[ "$distro" == "ubuntu" ]]; then
      currVersion=$(lsb_release -r -s | tr -d '.')

      if [[ "$currVersion" -lt "2004" ]]; then
        echo
        echo "👹 Oops! You'll need Ubuntu 20.04 at least"
        echo

        exit 1
      fi
    elif [[ "$distro" == "debian" ]]; then
      currVersion=$(lsb_release -r -s | tr -d '.')

      if [[ "$currVersion" -lt "11" ]]; then
        echo
        echo "👹 Oops! You'll need Debian 11 at least"
        echo

        exit 1
      fi
    else
      printf "👹 Oops! Your operating system (%) distro (%s) is not supported by the installer at this time. Check our guides to learn how to install on your own https://docs.fleek.network\n" "$os" "$distro"

      exit 1    
    fi

    echo "✅ Operating system ($os), distro ($distro) is supported!"
  else
    printf "👹 Oops! Your operating system (%) is not supported by the installer at this time. Check our guides to learn how to install on your own https://docs.fleek.network\n" "$os"

    exit 1
  fi
}

hasCommand() {
  command -v "$1" >/dev/null 2>&1
}

# The white space before and after is intentional
cat << "ART"

  ⭐️ Fleek Network Lightning CLI installer ⭐️

              zeeeeee-
              z$$$$$$"
            d$$$$$$"
            d$$$$$P
          d$$$$$P
          $$$$$$"
        .$$$$$$"
      .$$$$$$"
      4$$$$$$$$$$$$$"
    z$$$$$$$$$$$$$"
    """""""3$$$$$"
          z$$$$P
          d$$$$"
        .$$$$$"
      z$$$$$"
      z$$$$P
    d$$$$$$$$$$"
    *******$$$"
        .$$$"
        .$$"
      4$P"
      z$"
    zP
    z"
  /

ART

echo
echo "★★★★★★★★★ 🌍 Website https://fleek.network"
echo "★★★★★★★★★ 📚 Documentation https://docs.fleek.network"
echo "★★★★★★★★★ 💾 Git repository https://github.com/fleek-network/lightning"
echo "★★★★★★★★★ 🤖 Discord https://discord.gg/fleekxyz"
echo "★★★★★★★★★ 🐤 Twitter https://twitter.com/fleek_net"
echo "★★★★★★★★★ 🎨 Ascii art by https://www.asciiart.eu"
echo

printf "🤖 Check if operating system is supported\n"
isOSSupported

(
  exec < /dev/tty;

  # 🚑 Check if running in Bash and supported version
  [ "$BASH" ] || { printf >&2 '🙏 Run the script with Bash, please!\n'; exit 1; }
  (( BASH_VERSINFO[0] > 4 || BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 2 )) || { printf >&2 '🙏 Bash 4.2 or newer is required!\n'; exit 1; }

  # 🚑 Check total Processing Units
  defaultMinCPUUnitsCount=2
  vCPUs=$(nproc --all)
  if [[ "$vCPUs" -lt "$defaultMinCPUUnitsCount" ]]; then
    while read -rp "😅 The installer needs at least $defaultMinCPUUnitsCount total processing units, your system has $vCPUs. The installer is likely to fail, would you like to continue? (yes/no)" answer; do
      if [[ "$answer" == [nN] || "$answer" == [nN][oO] ]]; then
        printf "🦖 Exited the installation process\n\n"

        exit 1
      elif [[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]]; then
        printf "😅 Good luck!\n\n"

        break;
      fi

      printf "💩 Uh-oh! We expect a yes or no answer. Try again...\n"
    done
  fi

  echo

  # Check if system has recommended resources (disk space and memory)
  checkSystemHasRecommendedResources "$os"

  # 🚑 Check if ports available
  if ! hasCommand lsof; then
    printf "🤖 Install lsof for installer port verification\n"
    DEBIAN_FRONTEND=noninteractive sudo apt-get install lsof -yq
  fi

  # Obs: In the future there'll be ports for Worker (80*1) and Mempool (80*2)
  declare -a requiredPorts=(4069 4200 6969 18000 18101 18102)

  hasPortsAvailable=0
  for port in "${requiredPorts[@]}"; do
    if lsof -i :"$port" >/dev/null; then
      printf "💩 Uh-oh! The port %s is required but is in use...\n" "$port"

      hasPortsAvailable=1
    fi
  done

  if [[ "$hasPortsAvailable" -eq 1 ]]; then
    printf "👹 Oops! Required port(s) are in use, make sure the ports are open before retrying, please!\n"

    exit 1
  fi


  # Check if user is sudoer, as the command uses `sudo` warn the user
  if ! groups | grep -q 'root\|sudo'; then
    printf "⛔️ Attention! You need to have admin privileges (sudo), switch user and try again please! 🙏\n" >&2;

    exit "$err_non_root";
  fi

  # Install location
  printf "🤖 The $defaultName source-code is going to be stored in the recommended path %s (otherwise, type \"n\" to modify path)\n" "$defaultLightningPath"
  printf -v prompt "Should we proceed and install to path %s? (yes/no)" "$defaultLightningPath"

  while read -r -p "$prompt"$'\n> ' answer; do
    if [[ "$answer" == [nN] || "$answer" == [nN][oO] ]]; then
      printf -v prompt "\n🙋‍♀️ What path should we clone the %s source-code to?\n" "$defaultName"
      read -r -p "$prompt"$'\n> ' answer

      if [[ -d "$answer" ]]; then
        printf "👹 Oops! The path %s already exists! This might be annoying but we don't want to mess with your system. So, clear the path and try again...\n" "$answer"

        exit 1
      fi

      if ! mkdir -p "$selectedLightningPath"; then
        printf "👹 Oops! Failed to create the path %s\n" "$selectedLightningPath"

        exit 1
      fi

      selectedLightningPath="$answer"

      break
    fi

    if [[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]]; then
      selectedLightningPath="$defaultLightningPath"
      
      break
    fi
  done

  echo

  # Dependencies verification process
  if ! hasCommand git; then
    printf "🤖 Install Git\n"
    DEBIAN_FRONTEND=noninteractive sudo apt-get install git -yq
  fi

  echo

  printf "🤖 Clone the %s source-code (git repository) to %s\n" "$defaultName" "$selectedLightningPath"
  if [[ -n ${LIGHTNING_BRANCH+x} ]]; then
    echo "🥷 Switch to branch $LIGHTNING_BRANCH"
    if ! git clone -b "$LIGHTNING_BRANCH" "$defaultLightningHttpsRepository" "$selectedLightningPath"; then
      echo "👹 Oops! Failed to clone the $defaultName repository"

      exit 1
    fi
  else
    if ! git clone -b "$defaultAlphaTestnetBranch" "$defaultLightningHttpsRepository" "$selectedLightningPath"; then
      echo "👹 Oops! Failed to clone the $defaultName repository"

      exit 1
    fi
  fi

  echo

  printf "🤖 Change directory to %s (git repository)\n" "$selectedLightningPath"
  if ! cd "$selectedLightningPath"; then
    printf "👹 Oops! Failed to change directory to %s\n" "$selectedLightningPath"

    exit 1
  fi

  # Check if rust toolchain is available
  if ! command -vp "cargo" &> /dev/null && ! command -vp "rustc" &> /dev/null; then
    printf "🤖 Install the Rustup tool\n"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

    echo

    # TODO: `cargo not found` under sudoer for some reason
    # although the `cargo --version` below works but not the follow up cargo build
    printf "🤖 Reload PATH environments to include Cargo\n"
    source "$HOME/.cargo/env"
    
    echo

    printf "✅ Rust is installed!\n"

    printf "Cargo version is %s\n" "$(cargo --version)"
  else
    printf "🤖 Update Rustup\n"
    rustup update
  fi

  echo

  printf "🤖 Install the build-essentials, libraries and packages, necessary for compiling general software and for our use-case %s CLI\n" "$defaultName"
  DEBIAN_FRONTEND=noninteractive sudo apt-get install build-essential cmake clang pkg-config libssl-dev protobuf-compiler gcc-multilib -yq

  if [[ "$(identifyDistro)" == "debian" ]]; then
    sudo apt-get install gcc
    sudo apt-get update
  fi
  
  echo

  printf "🤖 Build and install the %s CLI\n" "$defaultName"

  # TODO: put back stable release as "install" (should set PATH automatically, so can remove the handling for PATH setup)
  # TODO: once changed switch from `debug` to `release`
  # if ! cargo +stable build --release; then
  targetName="debug"
  if ! cargo build; then
    printf "👹 Oops! Failed to build and install the %s CLI. If you are experiencing issues, help us improve by letting us know in our Discord %s\n" "$defaultName" "$defaultDiscordUrl"

    exit 1
  fi

  echo

  printf "🤖 Symlink the %s CLI binary to /usr/local/bin. By default rustup should've set the .cargo/bin into your system PATH, in any case we'll attempt to symlink to ensure %s is available globally\n" "$defaultName" "$defaultDiscordUrl"
  # Remove previous symlink if one exists
  if [[ -L "/usr/local/bin/$defaultCLIAlias" ]]; then
    # TODO: Symlink not getting removed for some reason
    if ! sudo rm -f "/usr/local/bin/$defaultCLIAlias"; then
      printf "👹 Oops! Failed to remove simbolic link %s \n" "/usr/local/bin/$defaultCLIAlias"
    fi
  fi

  # TODO: As we're using non `+stable` and not `install`, this location should
  # be replaced by the /target version
  if [[ -f "$HOME/.cargo/bin/$defaultName" ]]; then
    if ! sudo ln -s "$HOME/.cargo/bin/$defaultName" /usr/local/bin/$defaultCLIAlias; then
      printf "👹 Oops! Failed to symlink %s to /usr/local/bin/%s\n" "$HOME/.cargo/bin/$defaultName" "$defaultName"
      echo
      read -rp "😅 After the installation, if $defaultName CLI command is not available globally, then you need to add $HOME/.cargo/bin/ursa to your system PATH or symlink the binary to /usr/local/bin/$defaultName, as we've failed to do it. Press ENTER to continue..."
    fi
  else
    if ! sudo ln -s "$selectedLightningPath/target/$targetName/$defaultCLIBuildName" /usr/local/bin/$defaultCLIAlias; then
      printf "👹 Oops! Failed to symlink %s to /usr/local/bin/$defaultCLIAlias\n" "$selectedLightningPath/target/$targetName/$defaultCLIBuildName"
      echo
      read -rp "😅 After the installation, if $defaultName $defaultCLIBuildName CLI command is unavailable globally, then you need to add $selectedLightningPath/$targetName/release/$defaultCLIBuildName to your system PATH or symlink the binary to /usr/local/bin/$defaultCLIAlias, as we've failed to do it. Press ENTER to continue..."
    fi
  fi

  echo

  printf "🤖 Create the ~/.lightning directory\n"
  if ! mkdir "$defaultLightningBasePath"; then
    printf "👹 Oops! Failed to create the ~/.lightning directory\n"
  fi

  echo

  printf "🔑 Generate keys"
  if ! lgtn keys generate; then
    printf "⚠️ Keys already exist, will NOT generate new keys!\n"
  fi

  echo

  printf "🔑 The public keys are\n"
  if ! lgtn keys show | grep 'Node Public\|Consensus Public'; then
    printf "👹 Oops! Failed to show the public keys for Node and Consensus for some reason\n"
  fi

  echo

  printf "Find the private keys in the location %s\n\n" "$HOME/.$defaultName/keystore"
  printf "⚠️ The public key is open to anybody to see and it represents a unique node in the Fleek Network, a bit like a bank account number. On the other hand, the private key is secret and the operator is responsible to store it privately.\n\n"
  printf "⚠️ Fleek Network has no way to help access, retrieve or recover lost keys. The keys are the node operator responsability! Learn more about the keystore by checking the documentation site at %s\n\n" "$defaultDocsSite"

  printf "👌 Great! You have successfully installed required packages, libraries, have compiled and installed %s\n" "$defaultName"
  printf "The %s CLI should be available globally, there's a symlink to the /usr/local/bin/%s. Which means that from now on you can start a Network Node by typing %s\n" "$defaultName" "$defaultCLIAlias" "$defaultCLIAlias"

  if hasCommand ufw && sudo ufw status | grep -q 'Status: active'; then
    printf "💡 Detected that ufw is active\n"

    printf -v prompt "🚓 Warning! Make sure you don't have the ports %s blocked by a firewall. The installer will fail if you don't have the required ports open! Press ENTER to continue..." "${requiredPorts[*]}"
    read -rp "$prompt"
  fi

  echo

  printf "🤖 Create a Systemd %s service\n" "$defaultName"
  printf "🤖 Create the %s log directory %s\n" "$defaultName" "$defaultLightningLogPath"
  if ! sudo mkdir -p "$defaultLightningLogPath"; then
    printf "💩 Uh-oh! Failed to create the %s system log dir %s for some reason...\n" "$defaultName" "$defaultLightningLogPath"
  else
    if ! sudo chown "$(whoami):$(whoami)" "$defaultLightningLogPath"; then
      printf "💩 Uh-oh! Failed to chown %s\n" "$defaultLightningLogPath"
    fi
  fi

  echo

  printf "🤖 Declare the service and store in the system path\n"

# Important: the LIGHTNING_SERVICE it does not have identation on purpose, do not change
echo "
[Unit]
Description=Fleek Network Node lightning service

[Service]
User=$(whoami)
Type=simple
MemoryHigh=32G
RestartSec=15s
Restart=always
ExecStart=$defaultCLIAlias -c $defaultLightningConfigPath $ run
StandardOutput=append:$defaultLightningOutputLogAbsPath
StandardError=append:$defaultLightningDiagnosticLogAbsPath

[Install]
WantedBy=multi-user.target
" | sudo tee "$defaultLightningSystemdServicePath" > /dev/null

  printf "🤖 Set service file permissions\n"
  sudo chmod 644 "$defaultLightningSystemdServicePath"

  printf "🤖 System control daemon reload\n"
  sudo systemctl daemon-reload

  printf "🤖 Enable %s service on startup when the system boots\n" "$defaultName"
  sudo systemctl enable "$defaultLightningSystemdServiceName"

  # TODO: Disabled during early testnet due to whitelisting
  # echo
  # while read -rp "🤖 The installer can launch the service for you. Would you like to start the service? (yes/no)" answer; do
  #   if [[ "$answer" == [nN] || "$answer" == [nN][oO] ]]; then
  #     break;
  #   elif [[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]]; then
  #     printf "🤖 Start the %s service\n" "$defaultName"
  #     systemctl start "$defaultLightningSystemdServiceName"

  #     printf "🤖 %s service availability check\n" "$defaultName"
  #     pingAttempts=0

  #     printf "🦖 Please be patient as the Fleek Network Node is launching and may take awhile 🙏\n\n"

  #     while ! curl -s -X POST -H "Content-Type: application/json" -d '{ "jsonrpc": "2.0", "method": "flk_ping", "params": [], "id": 1 }' localhost:4069/rpc/v0 | grep -q "\"result\"\:\"pong\""; do
  #       if [[ "$pingAttempts" -gt 10 ]]; then
  #         printf "👹 Oh no! Failed to health-check the localhost on port 4069\n"

  #         break;
  #       fi

  #       if grep -sqin 'node is not whitelisted' "$defaultLightningDiagnosticLogAbsPath"; then
  #         printf "⚠️ Warning: The node is not whitelisted! Learn how to request access to testnet in https://docs.fleek.network/docs/node/testnet-onboarding\n\n"

  #         exit 1
  #       fi

  #       printf "🤖 Awaiting %s on port 4069...\n" "$defaultName"
  #       sleep 10

  #       ((pingAttempts++))
  #     done

  #     break;
  #   fi

  #   printf "💩 Uh-oh! We expect a yes or no answer. Try again...\n"
  # done

  # TODO: Switch to /health
  if curl -s -X POST -H "Content-Type: application/json" -d '{ "jsonrpc": "2.0", "method": "flk_ping", "params": [], "id": 1 }' localhost:4069/rpc/v0 | grep -q "\"result\"\:\"pong\""; then
    echo "🌈 The Fleek Network Node is running!"
  else
    echo "🌈 The Fleek Network Node lightning CLI was installed and a Systemd Service was setup, to learn how to launch the service read below!"
  fi

  echo
  echo "⚠️ WARNING: You'll have to request access to participate on Testnet. Only whitelisted nodes will be able to participate, if you fail to request the node will not run."
  read -rp "Request access by reading the onboarding instructions provided in our documentation https://docs.fleek.network/docs/node/testnet-onboarding to enable the network node to run successfully. Once happy with the information provided, press ENTER to continue..."
  echo

  echo "🤖 Launch or stop the Network Node by running:"
  echo "systemctl start $defaultName"
  echo "systemctl stop $defaultName"
  echo "systemctl restart $defaultName"
  echo
  echo "🎛️ Check the status of the service:"
  echo "systemctl status $defaultName"
  echo
  echo "👀 You can watch the Node output by running the command:"
  echo "tail -f $defaultLightningOutputLogAbsPath"
  echo
  echo "🥼 For diagnostics run the command:"
  echo "tail -f $defaultLightningDiagnosticLogAbsPath"
  echo
  echo "Learn more by checking our guides at https://docs.fleek.network"
  echo "✨ That's all!"
  echo
)
