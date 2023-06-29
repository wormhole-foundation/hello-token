// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "wormhole-solidity-sdk/WormholeRelayerSDK.sol";

contract HelloMultipleTokens is TokenSender, TokenReceiver {
    uint256 constant GAS_LIMIT = 400_000;

    constructor(address _wormholeRelayer, address _tokenBridge, address _wormhole)
        TokenBase(_wormholeRelayer, _tokenBridge, _wormhole)
    {}

    function quoteCrossChainDeposit(uint16 targetChain) public view returns (uint256 cost) {
        uint256 deliveryCost;
        (deliveryCost,) = wormholeRelayer.quoteEVMDeliveryPrice(targetChain, 0, GAS_LIMIT);
        cost = deliveryCost + 2 * wormhole.messageFee();
    }

    function sendCrossChainDeposit(
        uint16 targetChain,
        address targetHelloTokens,
        address recipient,
        uint256 amountA,
        address tokenA,
        uint256 amountB,
        address tokenB
    ) public payable {
        // emit token transfers
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        // encode payload to go with both token transfers
        bytes memory payload = abi.encode(recipient);

        // add transfers to additionalVaas list so they will be delivered along with the payload
        VaaKey[] memory vaaKeys = new VaaKey[](2);
        vaaKeys[0] = transferTokens(tokenA, amountA, targetChain, targetHelloTokens);
        vaaKeys[1] = transferTokens(tokenB, amountB, targetChain, targetHelloTokens);

        uint256 cost = quoteCrossChainDeposit(targetChain);
        require(msg.value == cost, "msg.value must be quoteCrossChainDeposit(targetChain)");

        wormholeRelayer.sendVaasToEvm{value: cost - 2 * wormhole.messageFee()}(
            targetChain,
            targetHelloTokens,
            payload,
            0, // no receiver value needed since we're just passing a message + wrapped tokens
            GAS_LIMIT,
            vaaKeys
        );
    }

    function receivePayloadAndTokens(
        bytes memory payload,
        TokenReceived[] memory receivedTokens,
        bytes32, // sourceAddress
        uint16,
        bytes32 // deliveryHash
    ) internal override onlyWormholeRelayer {
        require(receivedTokens.length == 2, "Expected 2 token transfers");

        // decode payload
        address recipient = abi.decode(payload, (address));

        // send tokens to recipient
        IERC20(receivedTokens[0].tokenAddress).transfer(recipient, receivedTokens[0].amount);
        IERC20(receivedTokens[1].tokenAddress).transfer(recipient, receivedTokens[1].amount);

    }
}
