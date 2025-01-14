# Consumer Chain Launch Process

This guide is intended for consumer chain teams that are looking to be onboarded on to the Replicated Security testnet.

## Quick facts about the Replicated Security Testnet
* The Replicated Security (RS) testnet is to be used to launch and test consumer chains. We recommend consumer chains to launch on the testnet before launching on the mainnet.
* All information about the RS testnet is available in this [repository](https://github.com/cosmos/testnets/tree/master/replicated-security)
* The testnet coordinators (Hypha) have majority voting power in the RS testnet. This means we need to work with you to bring your chain live and also to successfully pass any governance proposals you make

## How to join the RS testnet
* All the consumer chains have their own directory, you can use [`consumer-1`](consumer-1/README.md) as an example
* Feel free to clone the consumer-1 directory, replicate it for your consumer chain, and make a PR with the relevant information
* Ensure that you include all relevant documentation to build your consumer chain binary from a release or a tag
* Please include the genesis file in your PR. It should have: 
  - Properly funded accounts (e.g., gas fees for relayer, faucet, etc.)
  - Adequate slashing parameters to give validators time to join without getting jailed
  - A genesis time that matches the spawn time in the proposal
- We can also provide you with a sample proposal with adequate parameters (e.g., unbonding time and ccv timeout)
* When you make your proposal, please let us know well in advance. We also recommend making the proposal with us on a sync call. Current voting period is 1min to allow for quick iterations; we’ll need to vote right after you submit your proposal. We may change this voting period in the future if this format doesn’t work
* Please update the [schedule page](SCHEDULE.md) with your testnet launch date
* Please publish a post in the `#announcements` channel in the Interchain Security category of the Cosmos Network Discord server. If you need permissions for posting, please reach out to us

## Expectations from consumer chains
We expect you to run the minimum infrastructure required to make your consumer chain usable by testnet participants. This means running:
1. **Seed/persistent nodes**  
2. **Relayer** - must be launched before the chain times out, preferably right after blocks start being produced
   - **IMPORTANT**: If you will be running a relayer, make sure you have funds to pay gas for the relayer. You will likely need to set up a genesis account with funds

Additionally you may want to run:
- a faucet such as this simple [REST faucet](https://github.com/hyphacoop/cosmos-rest-faucet) (it may need a separate funded account in the genesis file as well)
- a block explorer such as [ping.pub](https://github.com/ping-pub/explorer)

## Talk to us
If you're a consumer chain looking to launch, please get in touch with Hypha. You can reach Lexa Michaelides at `lexa@hypha.coop` or on Telegram