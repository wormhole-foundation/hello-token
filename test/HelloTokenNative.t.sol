// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {HelloTokenNative} from "../src/example-extensions/HelloTokenNative.sol";

import "wormhole-solidity-sdk/testing/WormholeRelayerTest.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract HelloTokenNativeTest is WormholeRelayerBasicTest {
    HelloTokenNative public helloSource;
    HelloTokenNative public helloTarget;

    ERC20Mock public token;

    function setUpSource() public override {
        helloSource = new HelloTokenNative(
            address(relayerSource),
            address(tokenBridgeSource),
            address(wormholeSource)
        );

        token = createAndAttestToken(sourceChain);
    }

    function setUpTarget() public override {
        helloTarget = new HelloTokenNative(
            address(relayerTarget),
            address(tokenBridgeTarget),
            address(wormholeTarget)
        );
    }

    function testRemoteDeposit() public {
        uint256 amount = 19e17;
        token.approve(address(helloSource), amount);

        vm.selectFork(targetFork);
        address recipient = 0x1234567890123456789012345678901234567890;

        vm.selectFork(sourceFork);
        uint256 cost = helloSource.quoteCrossChainDeposit(targetChain);

        vm.recordLogs();
        helloSource.sendCrossChainDeposit{value: cost}(
            targetChain, address(helloTarget), recipient, amount, address(token)
        );
        performDelivery();

        vm.selectFork(targetFork);
        address wormholeWrappedToken = tokenBridgeTarget.wrappedAsset(sourceChain, toWormholeFormat(address(token)));
        assertEq(IERC20(wormholeWrappedToken).balanceOf(recipient), amount);
    }

    function testRemoteNativeDeposit() public {
        uint256 amount = 19e17;

        vm.selectFork(targetFork);
        address recipient = 0x1234567890123456789012345678901234567890;

        vm.selectFork(sourceFork);
        uint256 cost = helloSource.quoteCrossChainDeposit(targetChain);

        address wethAddress = address(tokenBridgeSource.WETH());

        vm.recordLogs();
        helloSource.sendNativeCrossChainDeposit{value: cost + amount}(
            targetChain, address(helloTarget), recipient, amount
        );
        performDelivery();

        vm.selectFork(targetFork);
        address wormholeWrappedToken = tokenBridgeTarget.wrappedAsset(sourceChain, toWormholeFormat(wethAddress));
        assertEq(IERC20(wormholeWrappedToken).balanceOf(recipient), amount);
    }
}
