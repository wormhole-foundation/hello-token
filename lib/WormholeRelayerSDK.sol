// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/interfaces/IWormholeReceiver.sol";
import "../src/interfaces/IWormholeRelayer.sol";
import "../src/interfaces/ITokenBridge.sol";

import "openzeppelin/token/ERC20/IERC20.sol";

import "forge-std/console.sol";

contract VaaSenderBase {
    IWormholeRelayer public immutable wormholeRelayer;
    ITokenBridge public immutable tokenBridge;
    IWormhole public immutable wormhole;

    constructor(
        address _wormholeRelayer,
        address _tokenBridge,
        address _wormhole
    ) {
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
        tokenBridge = ITokenBridge(_tokenBridge);
        wormhole = IWormhole(_wormhole);
    }

    function transferTokens(
        address token,
        uint256 amount,
        uint16 targetChain,
        address targetAddress
    ) internal returns (VaaKey memory) {
        IERC20(token).approve(address(tokenBridge), amount);
        uint64 sequence = tokenBridge.transferTokens{
            value: wormhole.messageFee()
        }(token, amount, targetChain, toWormholeFormat(targetAddress), 0, 0);
        return
            VaaKey({
                emitterAddress: toWormholeFormat(address(tokenBridge)),
                chainId: wormhole.chainId(),
                sequence: sequence
            });
    }

    function sendTokenWithPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        uint256 cost,
        address token,
        uint256 amount
    ) internal returns (uint64) {
        IERC20(token).approve(address(tokenBridge), amount);
        uint64 sequence = tokenBridge.transferTokensWithPayload{
            value: wormhole.messageFee()
        }(
            token,
            amount,
            targetChain,
            toWormholeFormat(targetAddress),
            0,
            payload
        );

        VaaKey[] memory vaaKeys = new VaaKey[](1);
        vaaKeys[0] = VaaKey({
            emitterAddress: toWormholeFormat(address(tokenBridge)),
            chainId: wormhole.chainId(),
            sequence: sequence
        });

        return
            wormholeRelayer.sendVaasToEvm{value: cost}(
                targetChain,
                targetAddress,
                new bytes(0), // payload is encoded in tokenTransfer
                receiverValue,
                gasLimit,
                vaaKeys
            );
    }
}

abstract contract ReplayProtection is IWormholeReceiver {
    mapping(bytes32 => bool) public replayProtection;

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory additionalVaas,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) public payable override {
        require(!replayProtection[deliveryHash], "Replay protection");
        replayProtection[deliveryHash] = true;

        receiveWormholeMessages(
            payload,
            additionalVaas,
            sourceAddress,
            sourceChain
        );
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory additionalVaas,
        bytes32 sourceAddress,
        uint16 sourceChain
    ) internal virtual;
}

function toWormholeFormat(address addr) pure returns (bytes32) {
    return bytes32(uint256(uint160(addr)));
}

function fromWormholeFormat(bytes32 whFormatAddress) pure returns (address) {
    if (uint256(whFormatAddress) >> 160 != 0)
        revert NotAnEvmAddress(whFormatAddress);
    return address(uint160(uint256(whFormatAddress)));
}
