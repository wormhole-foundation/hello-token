# Building Your First Cross-Chain Token Sending and Receiving Application

This repository contains a [solidity contract](./src/HelloToken.sol) that can be deployed onto many EVM chains to form a fully functioning cross-chain application with the ability to send and receive tokens between blockchains.

## Getting Started

Included in this repository is:

- Example Solidity Code
- Example Forge local testing setup
- Testnet Deploy Scripts
- Example Testnet testing setup

### Environment Setup

- Node 18.9.1 or later, npm 8.19.1 or later: [https://docs.npmjs.com/downloading-and-installing-node-js-and-npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm)
- forge 0.2.0 or later: [https://book.getfoundry.sh/getting-started/installation](https://book.getfoundry.sh/getting-started/installation)

### Testing Locally

```bash
npm run build
forge test
```

Expected output is

```bash
Running 1 test for test/HelloToken.t.sol:HelloTokenTest
[PASS] testRemoteDeposit() (gas: 1338038)
Test result: ok. 1 passed; 0 failed; finished in 5.64s
```

### Deploying to Testnet

You will need a wallet with at least 0.05 Testnet AVAX and 0.01 Testnet CELO. 

- [Obtain testnet AVAX here](https://core.app/tools/testnet-faucet/?token=C)
- [Obtain testnet CELO here](https://faucet.celo.org/alfajores)

```bash
EVM_PRIVATE_KEY=your_wallet_private_key npm run deploy
```

### Testing on Testnet

You will need a wallet with at least 0.02 Testnet AVAX. [Obtain testnet AVAX here](https://core.app/tools/testnet-faucet/?token=C)

You must have also deployed contracts onto testnet (as described in the above section).

To test sending and receiving a message on testnet, execute the test as such:

```bash
EVM_PRIVATE_KEY=your_wallet_private_key npm run test
```

