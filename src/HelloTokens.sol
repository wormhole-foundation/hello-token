// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "wormhole-relayer-sdk/WormholeRelayerSDK.sol";

import "wormhole-relayer-sdk/interfaces/IWormholeRelayer.sol";
import "wormhole-relayer-sdk/interfaces/IWormholeReceiver.sol";
import "wormhole-relayer-sdk/interfaces/ITokenBridge.sol";
import "wormhole-relayer-sdk/interfaces/IWormhole.sol";

struct LiquidityProvided {
    uint16 senderChain;
    address sender;
    address tokenA;
    address tokenB;
    uint256 amount;
}

contract HelloTokens is TokenSender, TokenReceiver {
    uint256 constant GAS_LIMIT = 400_000;

    LiquidityProvided[] public liquidityProvidedHistory;

    constructor(address _wormholeRelayer, address _tokenBridge, address _wormhole)
        TokenBase(_wormholeRelayer, _tokenBridge, _wormhole)
    {}

    function quoteRemoteLP(uint16 targetChain) public view returns (uint256 cost) {
        (cost,) = wormholeRelayer.quoteEVMDeliveryPrice(targetChain, 0, GAS_LIMIT);
    }

    function sendRemoteLP(uint16 targetChain, address targetAddress, uint256 amount, address tokenA, address tokenB)
        public
        payable
    {
        // emit token transfers
        IERC20(tokenA).transferFrom(msg.sender, address(this), amount);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amount);

        VaaKey[] memory vaaKeys = new VaaKey[](2);
        vaaKeys[0] = transferTokens(tokenA, amount, targetChain, targetAddress);
        vaaKeys[1] = transferTokens(tokenB, amount, targetChain, targetAddress);

        uint256 cost = quoteRemoteLP(targetChain);
        require(msg.value == cost, "msg.value must equal quoteRemoteLP(targetChain)");

        // encode payload
        bytes memory lpProvider = abi.encode(msg.sender);
        wormholeRelayer.sendVaasToEvm{value: cost}(
            targetChain,
            targetAddress,
            lpProvider,
            0, // no receiver value needed since we're just passing a message + wrapped tokens
            GAS_LIMIT,
            vaaKeys
        );
    }

    function receivePayloadAndTokens(
        bytes memory payload,
        ITokenBridge.TransferWithPayload[] memory transfers,
        bytes32, // sourceAddress
        uint16 sourceChain,
        bytes32 // deliveryHash
    ) internal override onlyWormholeRelayer {
        require(transfers.length == 2, "Expected 2 token transfers");

        address lpProvider = abi.decode(payload, (address));
        provideLiquidity(sourceChain, lpProvider, transfers[0], transfers[1]);
    }

    // dummy function for demonstration purposes
    function provideLiquidity(
        uint16 sourceChain,
        address lpProvider,
        ITokenBridge.TransferWithPayload memory transferA,
        ITokenBridge.TransferWithPayload memory transferB
    ) internal {
        liquidityProvidedHistory.push(
            LiquidityProvided(
                sourceChain,
                lpProvider,
                fromWormholeFormat(transferA.tokenAddress),
                fromWormholeFormat(transferB.tokenAddress),
                transferA.amount * 1e10 // Note: token bridge normalizes values to 8 decimals for cross-ecosystem compatibility
            )
        );
    }

    // getter to allow testing
    function getLiquiditiesProvidedHistory() public view returns (LiquidityProvided[] memory) {
        return liquidityProvidedHistory;
    }
}
