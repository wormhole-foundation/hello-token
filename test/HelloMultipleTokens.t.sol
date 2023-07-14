// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {HelloMultipleTokens} from "../src/example-extensions/HelloMultipleTokens.sol";

import "wormhole-solidity-sdk/testing/WormholeRelayerTest.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract HelloMultipleTokensTest is WormholeRelayerBasicTest {
    event GreetingReceived(string greeting, uint16 senderChain, address sender);

    HelloMultipleTokens public helloSource;
    HelloMultipleTokens public helloTarget;

    ERC20Mock public tokenA;
    ERC20Mock public tokenB;

    function setUpSource() public override {
        helloSource = new HelloMultipleTokens(
            address(relayerSource),
            address(tokenBridgeSource),
            address(wormholeSource)
        );

        tokenA = createAndAttestToken(sourceChain);
        tokenB = createAndAttestToken(sourceChain);
    }

    function setUpTarget() public override {
        helloTarget = new HelloMultipleTokens(
            address(relayerTarget),
            address(tokenBridgeTarget),
            address(wormholeTarget)
        );
    }

    function testRemoteLP() public {
        uint256 amountA = 19e17;
        tokenA.approve(address(helloSource), amountA);
        uint256 amountB = 13e17;
        tokenB.approve(address(helloSource), amountB);

        vm.selectFork(targetFork);
        address recipient = 0x1234567890123456789012345678901234567890;

        vm.selectFork(sourceFork);
        uint256 cost = helloSource.quoteCrossChainDeposit(targetChain);

        vm.recordLogs();
        helloSource.sendCrossChainDeposit{value: cost}(
            targetChain, address(helloTarget), recipient, amountA, address(tokenA), amountB, address(tokenB)
        );
        performDelivery();

        vm.selectFork(targetFork);

        address wormholeWrappedTokenA = tokenBridgeTarget.wrappedAsset(sourceChain, toWormholeFormat(address(tokenA)));
        assertEq(IERC20(wormholeWrappedTokenA).balanceOf(recipient), amountA);

        address wormholeWrappedTokenB = tokenBridgeTarget.wrappedAsset(sourceChain, toWormholeFormat(address(tokenB)));
        assertEq(IERC20(wormholeWrappedTokenB).balanceOf(recipient), amountB);

    }
}
