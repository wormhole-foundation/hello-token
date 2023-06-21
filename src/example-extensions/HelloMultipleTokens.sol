// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "wormhole-relayer-solidity-sdk/WormholeRelayerSDK.sol";

struct LiquidityProvided {
    uint16 senderChain;
    address sender;
    address tokenA;
    address tokenB;
    uint256 amount;
}

contract HelloMultipleTokens is TokenSender, TokenReceiver {
    uint256 constant GAS_LIMIT = 400_000;

    LiquidityProvided public lastLiquidityProvided;

    constructor(address _wormholeRelayer, address _tokenBridge, address _wormhole)
        TokenBase(_wormholeRelayer, _tokenBridge, _wormhole)
    {}

    function quoteRemoteLP(uint16 targetChain) public view returns (uint256 cost) {
        (cost,) = wormholeRelayer.quoteEVMDeliveryPrice(targetChain, 0, GAS_LIMIT);
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

        // add transfers to additionalVaas list so they will be delivered along with the payload
        VaaKey[] memory vaaKeys = new VaaKey[](2);
        vaaKeys[0] = transferTokens(tokenA, amount, targetChain, targetAddress);
        vaaKeys[1] = transferTokens(tokenB, amount, targetChain, targetAddress);

        uint256 cost = quoteRemoteLP(targetChain);
        require(msg.value >= cost, "msg.value must be >= quoteRemoteLP(targetChain)");

        // encode payload and send
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
        require(transfers[0].amount == transfers[1].amount, "Expected equal token amounts");

        // decode payload
        address lpProvider = abi.decode(payload, (address));

        // do something with the tokens
        lastLiquidityProvided = LiquidityProvided(
            sourceChain,
            lpProvider,
            fromWormholeFormat(transfers[0].tokenAddress),
            fromWormholeFormat(transfers[1].tokenAddress),
            // Note: token bridge normalizes values to 8 decimals for cross-ecosystem compatibility
            transfers[0].amount * 1e10
        );
    }
}
