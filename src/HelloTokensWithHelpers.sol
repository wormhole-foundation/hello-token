// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IWormholeRelayer.sol";
import "./interfaces/IWormholeReceiver.sol";
import "./interfaces/ITokenBridge.sol";
import "./interfaces/IWormhole.sol";
import "openzeppelin/token/ERC20/IERC20.sol";

contract HelloTokens is IWormholeReceiver {
    event LiquidityProvided(
        uint16 senderChain,
        address sender,
        address tokenA,
        address tokenB,
        uint256 amount
    );

    uint256 constant GAS_LIMIT = 50_000;

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
        uint64 sequenceA = tokenBridge.transferTokens{
            value: wormhole.messageFee()
        }(tokenA, amount, targetChain, toWormholeFormat(targetAddress), 0, 0);

        IERC20(tokenB).transferFrom(msg.sender, address(this), amount);
        uint64 sequenceB = tokenBridge.transferTokens{
            value: wormhole.messageFee()
        }(tokenB, amount, targetChain, toWormholeFormat(targetAddress), 0, 0);

        // specify the token transfer vaa should be delivered along with the payload
        VaaKey[] memory additionalVaas = new VaaKey[](2);
        additionalVaas[0] = VaaKey({
            emitterAddress: toWormholeFormat(address(tokenBridge)),
            sequence: sequenceA,
            chainId: wormhole.chainId()
        });
        additionalVaas[1] = VaaKey({
            emitterAddress: toWormholeFormat(address(tokenBridge)),
            sequence: sequenceB,
            chainId: wormhole.chainId()
        });

        (uint256 cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            0,
            GAS_LIMIT
        );

        // encode payload
        bytes memory lpProvider = abi.encode(msg.sender);

        wormholeRelayer.sendVaasToEvm{value: cost}(
            targetChain,
            targetAddress,
            lpProvider,
            0, // no receiver value needed since we're just passing a message + wrapped token
            GAS_LIMIT,
            additionalVaas
        );
        if (msg.value > cost) {
            (bool success, ) = msg.sender.call{value: msg.value - cost}("");
            require(success, "Returning excess funds failed");
        }
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory additionalVaas,
        bytes32, // sourceAddress
        uint16 sourceChain,
        bytes32 // deliveryHash
    ) public payable override {
        address lpProvider = abi.decode(payload, (address));

        ITokenBridge.Transfer memory transferA = tokenBridge.parseTransfer(
            additionalVaas[0]
        );
        tokenBridge.completeTransfer(additionalVaas[0]);

        ITokenBridge.Transfer memory transferB = tokenBridge.parseTransfer(
            additionalVaas[1]
        );
        tokenBridge.completeTransfer(additionalVaas[1]);

        provideLiquidity(sourceChain, lpProvider, transferA, transferB);
    }

    // dummy function for demonstration purposes
    function provideLiquidity(
        uint16 sourceChain,
        address lpProvider,
        ITokenBridge.Transfer memory transferA,
        ITokenBridge.Transfer memory transferB
    ) internal {
        emit LiquidityProvided(
            sourceChain,
            lpProvider,
            fromWormholeFormat(transferA.tokenAddress),
            fromWormholeFormat(transferB.tokenAddress),
            transferA.amount
        );
    }
}

function toWormholeFormat(address addr) pure returns (bytes32) {
    return bytes32(uint256(uint160(addr)));
}

function fromWormholeFormat(bytes32 whFormatAddress) pure returns (address) {
    if (uint256(whFormatAddress) >> 160 != 0)
        revert NotAnEvmAddress(whFormatAddress);
    return address(uint160(uint256(whFormatAddress)));
}
