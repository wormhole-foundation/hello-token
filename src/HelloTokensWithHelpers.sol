// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/WormholeRelayerSDK.sol";

import "./interfaces/IWormholeRelayer.sol";
import "./interfaces/IWormholeReceiver.sol";
import "./interfaces/ITokenBridge.sol";
import "./interfaces/IWormhole.sol";

import "openzeppelin/token/ERC20/IERC20.sol";

import "forge-std/console.sol";

struct LiquidityProvided {
    uint16 senderChain;
    address sender;
    address tokenA;
    address tokenB;
    uint256 amount;
}

contract HelloTokensWithHelpers is VaaSenderBase, IWormholeReceiver {
    uint256 constant GAS_LIMIT = 350_000;

    LiquidityProvided[] public liquidityProvidedHistory;

    constructor(
        address _wormholeRelayer,
        address _tokenBridge,
        address _wormhole
    ) VaaSenderBase(_wormholeRelayer, _tokenBridge, _wormhole) {}

    function quoteRemoteLP(
        uint16 targetChain
    ) public view returns (uint256 cost) {
        (cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            0,
            GAS_LIMIT
        );
    }

    function sendRemoteLP(
        uint16 targetChain,
        address targetAddress,
        uint256 amount,
        address tokenA,
        address tokenB
    ) public payable {
        // emit token transfers
        IERC20(tokenA).transferFrom(msg.sender, address(this), amount);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amount);

        VaaKey[] memory vaaKeys = new VaaKey[](2);
        vaaKeys[0] = transferTokens(tokenA, amount, targetChain, targetAddress);
        vaaKeys[1] = transferTokens(tokenB, amount, targetChain, targetAddress);

        uint256 cost = quoteRemoteLP(targetChain);
        require(
            msg.value == cost,
            "msg.value must equal quoteRemoteLP(targetChain)"
        );

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

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory additionalVaas,
        bytes32, // sourceAddress
        uint16 sourceChain,
        bytes32 // deliveryHash
    ) public payable override {
        address lpProvider = abi.decode(payload, (address));

        tokenBridge.completeTransfer(additionalVaas[0]);
        tokenBridge.completeTransfer(additionalVaas[1]);

        // parse transfers to get token addresses and amounts
        IWormhole.VM memory parsedVMA = wormhole.parseVM(additionalVaas[0]);
        IWormhole.VM memory parsedVMB = wormhole.parseVM(additionalVaas[1]);

        ITokenBridge.Transfer memory transferA = tokenBridge.parseTransfer(
            parsedVMA.payload
        );
        ITokenBridge.Transfer memory transferB = tokenBridge.parseTransfer(
            parsedVMB.payload
        );

        provideLiquidity(sourceChain, lpProvider, transferA, transferB);
    }

    // dummy function for demonstration purposes
    function provideLiquidity(
        uint16 sourceChain,
        address lpProvider,
        ITokenBridge.Transfer memory transferA,
        ITokenBridge.Transfer memory transferB
    ) internal {
        liquidityProvidedHistory.push(
            LiquidityProvided(
                sourceChain,
                lpProvider,
                fromWormholeFormat(transferA.tokenAddress),
                fromWormholeFormat(transferB.tokenAddress),
                transferA.amount * 1e10 // Note: wormhole normalizes values to 8 decimals for cross-ecosystem compatibility
            )
        );
    }

    // getter to allow testing
    function getLiquiditiesProvidedHistory()
        public
        view
        returns (LiquidityProvided[] memory)
    {
        return liquidityProvidedHistory;
    }
}