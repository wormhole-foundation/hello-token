// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "wormhole-relayer-sdk/WormholeRelayerSDK.sol";

struct Deposit {
    uint16 senderChain;
    address sender;
    address token;
    uint256 amount;
}

contract HelloToken is TokenSender, TokenReceiver {
    uint256 constant GAS_LIMIT = 350_000;

    Deposit public lastDeposit;

    constructor(address _wormholeRelayer, address _tokenBridge, address _wormhole)
        TokenBase(_wormholeRelayer, _tokenBridge, _wormhole)
    {}

    function quoteRemoteDeposit(uint16 targetChain) public view returns (uint256 cost) {
        (cost,) = wormholeRelayer.quoteEVMDeliveryPrice(targetChain, 0, GAS_LIMIT);
    }

    function sendRemoteDeposit(
        uint16 targetChain,
        address targetAddress,
        uint256 amount,
        address token
    ) public payable {
        uint256 cost = quoteRemoteDeposit(targetChain);
        require(msg.value >= cost, "msg.value must equal quoteRemoteLP(targetChain)");

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        bytes memory payload = abi.encode(msg.sender);
        sendTokenWithPayloadToEvm(
            targetChain, targetAddress, payload, 0, GAS_LIMIT, cost, token, amount
        );
    }

    function receivePayloadAndTokens(
        bytes memory payload,
        ITokenBridge.TransferWithPayload[] memory transfers,
        bytes32, // sourceAddress
        uint16 sourceChain,
        bytes32 // deliveryHash
    ) internal override onlyWormholeRelayer {
        require(transfers.length == 1, "Expected 1 token transfers");

        address depositor = abi.decode(payload, (address));

        // do something with the tokens
        lastDeposit = Deposit(
            sourceChain,
            depositor,
            fromWormholeFormat(transfers[0].tokenAddress),
            transfers[0].amount * 1e10 // Note: token bridge normalizes values to 8 decimals for cross-ecosystem compatibility
        );
    }
}
