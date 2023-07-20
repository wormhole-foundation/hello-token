# Building Your Cross-Chain Token Transfer Application

Welcome to the Crosscontinental Bridge project! This integration test suite enables seamless token transfers between the Avalanche and Moonbeam blockchains on the Testnet environment, making cross-chain transactions a reality.

## Summary

This repository includes:

- Example Solidity Code
- Example Forge local testing setup
- Testnet Deploy Scripts
- Example Testnet testing setup

### Environment Setup

- Node 16.14.1 or later, npm 8.5.0 or later
- Forge 0.2.0 or later

### Testing Locally

Clone the repo, navigate to it, then build and run unit tests:

```bash
git clone https://github.com/wormhole-foundation/hello-token.git
cd hello-token
npm run build
forge test
```

Expected output is:

```bash
Running 1 test for test/HelloToken.t.sol:HelloTokenTest
[PASS] testCrossChainDeposit() (gas: 1338038)
Test result: ok. 1 passed; 0 failed; finished in 5.64s
```

### Deploying to Testnet

Ensure you have a wallet with at least 0.05 Testnet AVAX and 0.01 Moonbase DEV.

- [Obtain Testnet AVAX here](https://core.app/tools/testnet-faucet/?token=C)
- [Obtain Testnet Moonbase](https://app.beamswap.io/bridge/faucet)

```bash
EVM_PRIVATE_KEY=your_wallet_private_key npm run deploy
```

### Testing on Testnet

Ensure you have a wallet with at least 0.02 Testnet AVAX. [Obtain Testnet AVAX here](https://core.app/tools/testnet-faucet/?token=C)

Deploy contracts onto Testnet as described in the above section.

To test sending and receiving a message on Testnet, execute the test as follows:

```bash
EVM_PRIVATE_KEY=your_wallet_private_key npm run test
```

## Getting Started

Let's write a [HelloToken contract](https://github.com/wormhole-foundation/hello-token/blob/main/src/HelloToken.sol) that enables users to send an arbitrary amount of an IERC20 token to an address on another chain.

### Wormhole Solidity SDK

To ease development, we'll use the [Wormhole Solidity SDK](https://github.com/wormhole-foundation/wormhole-solidity-sdk). Include this SDK in your cross-chain application by running:

```bash 
forge install wormhole-foundation/wormhole-solidity-sdk
``` 

and import it in your contract:

```solidity
import "wormhole-solidity-sdk/WormholeRelayerSDK.sol";
```

This SDK provides helpers for cross-chain development with Wormhole, offering TokenSender and TokenReceiver abstract classes with useful functionality for sending and receiving tokens using TokenBridge.

### Implement Sending Function

Let's start by writing a function to send some amount of a token to a specific recipient on a target chain.

```solidity
function sendCrossChainDeposit(
    uint16 targetChain,
    address targetHelloToken,
    address recipient,
    uint256 amount,
    address token
) public payable;
```

The body of this function sends the token and a payload to the HelloToken contract on the target chain. The payload contains the intended recipient's address, allowing the target chain HelloToken contract to send the token to the recipient.

To send the token and payload to the HelloToken contract, we use the `sendTokenWithPayloadToEvm` helper from the Wormhole Solidity SDK.

### Implement Receiving Function

We implement the `TokenReceiver` abstract class, also included in the Wormhole Solidity SDK.

```solidity
struct TokenReceived {
    bytes32 tokenHomeAddress;
    uint16 tokenHomeChain;
    address tokenAddress; 
    uint256 amount;
    uint256 amountNormalized; 
}

function receivePayloadAndTokens(
    bytes memory payload,
    TokenReceived[] memory receivedTokens,
    bytes32 sourceAddress,
    uint16 sourceChain,
    bytes32 deliveryHash
) internal virtual {}
```

After calling `sendTokenWithPayloadToEvm` on the source chain, the message goes through the standard Wormhole message lifecycle. Once a VAA (Virtual Asset Address) is available, the delivery provider calls `receivePayloadAndTokens` on the target chain and target address specified.

The implementation of `receivePayloadAndTokens` involves parsing the signed VAA and ensuring the transfer was successful before returning a `TokenReceived` struct containing information about the transfer.

These functions together create a complete working example of a cross-chain application using TokenBridge to send and receive tokens.

Try [cloning and running HelloToken](https://github.com/wormhole-foundation/hello-token/tree/main#readme) to see this example in action!

## How do these Solidity Helpers Work?

The `sendTokenWithPayloadToEvm` and `receivePayloadAndTokens` functions make use of the Wormhole Relayer SDK to send and receive tokens.

Sending a Token: 
- We use the EVM TokenBridge contract to publish a wormhole message indicating the token transfer.
- The `sendTokenWithPayloadToEvm` helper gets the signed VAA corresponding to the published token bridge wormhole message delivered to the target address.

Receiving a Token: 
- After calling `sendVaasToEvm`, `receiveWormholeMessages` is called on `targetAddress` with the payload and additionalVaas containing the signed VAA.
- The VAA is parsed and verified, and the transfer is completed to receive the transferred tokens.
- The `receivePayloadAndTokens` function processes the received tokens and payload accordingly.

Explore the full implementation of Wormhole Relayer SDK helpers [here](https://github.com/wormhole-foundation/wormhole-solidity-sdk/blob/main/src/WormholeRelayerSDK.sol).