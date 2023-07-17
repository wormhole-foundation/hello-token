// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "wormhole-solidity-sdk/interfaces/IWormholeRelayer.sol";
import "wormhole-solidity-sdk/interfaces/IWormholeReceiver.sol";
import "wormhole-solidity-sdk/interfaces/ITokenBridge.sol";
import "wormhole-solidity-sdk/interfaces/IWormhole.sol";
import "wormhole-solidity-sdk/interfaces/IERC20.sol";

contract HelloTokenWithoutSDK is IWormholeReceiver {
    uint256 constant GAS_LIMIT = 250_000;

    IWormholeRelayer public immutable wormholeRelayer;
    ITokenBridge public immutable tokenBridge;
    IWormhole public immutable wormhole;

    constructor(address _wormholeRelayer, address _tokenBridge, address _wormhole) {
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
        tokenBridge = ITokenBridge(_tokenBridge);
        wormhole = IWormhole(_wormhole);
    }

    function quoteCrossChainDeposit(uint16 targetChain) public view returns (uint256 cost) {
        uint256 deliveryCost;
        (deliveryCost,) = wormholeRelayer.quoteEVMDeliveryPrice(targetChain, 0, GAS_LIMIT);
        cost = deliveryCost + wormhole.messageFee();
    }

    function sendCrossChainDeposit(
        uint16 targetChain,
        address targetHelloToken,
        address recipient,
        uint256 amount,
        address token
    ) public payable {
        // emit token transfers
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(address(tokenBridge), amount);
        uint64 sequence = tokenBridge.transferTokens{value: wormhole.messageFee()}(
            token, amount, targetChain, toWormholeFormat(targetHelloToken), 0, 0
        );

        // specify the token transfer vaa should be delivered along with the payload
        VaaKey[] memory additionalVaas = new VaaKey[](1);
        additionalVaas[0] = VaaKey({
            emitterAddress: toWormholeFormat(address(tokenBridge)),
            sequence: sequence,
            chainId: wormhole.chainId()
        });

        uint256 cost = quoteCrossChainDeposit(targetChain);
        require(msg.value == cost, "Incorrect payment to cover delivery cost");

        // encode payload
        bytes memory payload = abi.encode(recipient);

        wormholeRelayer.sendVaasToEvm{value: cost - wormhole.messageFee()}(
            targetChain,
            targetHelloToken,
            payload,
            0, // no receiver value needed since we're just passing a message + wrapped token
            GAS_LIMIT,
            additionalVaas
        );
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory additionalVaas,
        bytes32, // sourceAddress
        uint16,
        bytes32 // deliveryHash
    ) public payable override {
        require(msg.sender == address(wormholeRelayer), "Only wormhole allowed");
        require(additionalVaas.length == 2, "Expected 2 additional VAA keys for token transfers");

        address recipient = abi.decode(payload, (address));

        IWormhole.VM memory parsedVM = wormhole.parseVM(additionalVaas[0]);
        ITokenBridge.Transfer memory transfer = tokenBridge.parseTransfer(parsedVM.payload);
        tokenBridge.completeTransfer(additionalVaas[0]);

        address wrappedTokenAddress = transfer.tokenChain == wormhole.chainId() ? fromWormholeFormat(transfer.tokenAddress) : tokenBridge.wrappedAsset(transfer.tokenChain, transfer.tokenAddress);
        
        uint256 decimals = getDecimals(wrappedTokenAddress);
        uint256 powerOfTen = 0;
        if(decimals > 8) powerOfTen = decimals - 8;
        IERC20(wrappedTokenAddress).transfer(recipient, transfer.amount * 10 ** powerOfTen); // 
    }

}

function toWormholeFormat(address addr) pure returns (bytes32) {
    return bytes32(uint256(uint160(addr)));
}

function fromWormholeFormat(bytes32 whFormatAddress) pure returns (address) {
    if (uint256(whFormatAddress) >> 160 != 0) {
        revert NotAnEvmAddress(whFormatAddress);
    }
    return address(uint160(uint256(whFormatAddress)));
}

function getDecimals(address tokenAddress) view returns (uint8 decimals) {
    // query decimals
    (,bytes memory queriedDecimals) = address(tokenAddress).staticcall(abi.encodeWithSignature("decimals()"));
    decimals = abi.decode(queriedDecimals, (uint8));
}
