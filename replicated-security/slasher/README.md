
# `slasher` Chain Details

> Status: **STOPPED**

The `slasher` chain was launched to test the slash rate limiter feature of the provider chain. As soon as it received the first packet, the `slasher` chain attempted to jail all validators:

---
### Slash event timeline

A delegation transaction was sent in block `13198`. This caused a Validator Set Change packet to be sent to the slasher chain. The slasher chain responded by sending a downtime infraction for each of the validators.

The slash rate limiter "throttled" all the received packets so the chain would not halt. The table below shows the blocks and times at which each of the six validators were jailed (all times are in UTC).

| Time                  | Height  | Slash meter | Slash meter allowance | Next replenish candidate | Validator jailed |
|-----------------------|---------|------------:|-----------------------|--------------------------|:----------------:|
| `2023-02-03T15:20:15` | `13203` | `-62500009` | `24500001`            | `2023-02-03T15:53:07`    |    Blockapsis    |
| `2023-02-03T17:53:15` | `14789` | `-89950007` | `24850001`            | `2023-02-03T18:53:15`    |      cherry      |
| `2023-02-03T21:53:27` | `17279` | `-87750004` | `24800001`            | `2023-02-03T22:53:27`    |       DSRV       |
| `2023-02-04T02:53:38` | `20512` | `-89999999` | `19950001`            | `2023-02-04T03:53:38`    |      banana      |
| `2023-02-04T06:53:47` | `22983` | `-96177995` | `24455501`            | `2023-02-04T07:53:47`    |      apple       |
| `2023-02-04T10:53:53` | `25453` | `-57419494` | `29205001`            | `2023-02-04T11:53:53`    |    Stakecito     |

The `SlashMeterReplenishPeriod` parameter was set to one hour on the provider, so each hour the slash rate limiter would re-evaluate the slash meter by adding the slash meter allowance to it. Whenever the slash meter turned positive, another validator was allowed to be jailed.

---

* **Chain-ID**: `slash`
* **denom**: `uslash`
* **Spawn time**: `2023-02-03T15:00:00.000000Z`
* **Stop time**: `2023-02-06T21:00:00.000000Z`
* **GitHub repo**: [cosmos/interchain-security](https://github.com/cosmos/interchain-security)
* **Commit**: [`e6bd5b72650e107ff0ce613af5d2e17310f7e984`](https://github.com/cosmos/interchain-security/commit/e6bd5b72650e107ff0ce613af5d2e17310f7e984)
* **Genesis file with CCV state:** [slasher-genesis.json](slasher-genesis.json)

* **Reference binary**: `slasher-linux-amd64`
* **Binary sha256sum**: `c6660834e0786c3032369de6d7798bb411993c741d0c7c2709fc4cbc9cfa1864`
* **Genesis file _without CCV state_:** `slasher-genesis-without-ccv.json`
* **SHA256 for genesis file _without CCV state_**: `f2bcaeec812058d761399d355124ceb8945b79168a2848c46c4455bebebe7d00`

The following items will be included in the consumer addition proposal:

* Genesis file hash
  * The SHA256 is used to verify against the genesis file (without CCV state) that the proposer has made available for review.
  * The `slasher-genesis-without-ccv.json` file cannot be used to run the chain: it must be updated with the CCV (Cross Chain Validation) state after the spawn time is reached.
  * The genesis file includes funds for a relayer and a faucet account, and `signed_blocks_window` has been set to `20000`.
* Binary hash
  * The `slasher-linux-amd64` binary is only provided to verify the SHA256. It was built with commit [`e6bd5b72650e107ff0ce613af5d2e17310f7e984`](https://github.com/cosmos/interchain-security/commit/e6bd5b72650e107ff0ce613af5d2e17310f7e984) of the Interchain Security repo. You can generate the binary following the build instructions in that repo or using one of the scripts provided here.
* Spawn time
  * Even if a proposal passes, the CCV state will not be available from the provider chain until after the spawn time is reached.

For more information regarding the consumer chain creation process, see [CCV: Overview and Basic Concepts](https://github.com/cosmos/ibc/blob/main/spec/app/ics-028-cross-chain-validation/overview_and_basic_concepts.md).

## Endpoints

Persistent nodes:

1. `b7d0bd260fca7a5a19c7631b15f6068891faa60e@slasher-apple.rs-testnet.polypore.xyz:26656`
2. `49d75c6094c006b6f2758e45457c1f3d6002ce7a@slasher-banana.rs-testnet.polypore.xyz:26656`
3. `f2520026fb9086f1b2f09e132d209cbe88064ec1@slasher-cherry.rs-testnet.polypore.xyz:26656`

## IBC Information

Connections and channels will be posted here shortly after the chain launches.

## How to Join

#### Bash Scripts

The scripts provided in this repo will install a malicious branch of `interchain-security-cd` and optionally set up a Cosmovisor service on your machine. 

Run either one of the scripts provided to set up a `slasher` service:
* `join-rs-slasher.sh` will create a `slasher` service.
* `join-rs-slasher-cv.sh` will create a `cosmovisor` service.
* Both scripts must be run either as root or from a sudoer account.
* Both scripts will attempt to build a binary from the [cosmos/interchain-security] repo.
