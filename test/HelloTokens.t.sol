// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {HelloTokens, LiquidityProvided} from "../src/HelloTokens.sol";
// import "../src/HelloTokensWithHelpers.sol";

import "wormhole-relayer-sdk/testing/WormholeRelayerTest.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract HelloTokensTest is WormholeRelayerTest {
    event GreetingReceived(string greeting, uint16 senderChain, address sender);

    HelloTokens public helloSource;
    HelloTokens public helloTarget;

    ERC20Mock public tokenA;
    ERC20Mock public tokenB;

    function setUpSource() public override {
        helloSource = new HelloTokens(
            address(relayerSource),
            address(tokenBridgeSource),
            address(wormholeSource)
        );

        tokenA = createAndAttestToken(sourceFork);
        tokenB = createAndAttestToken(sourceFork);
    }

    function setUpTarget() public override {
        helloTarget = new HelloTokens(
            address(relayerTarget),
            address(tokenBridgeTarget),
            address(wormholeTarget)
        );
    }

    function testGreeting() public {
        uint256 amount = 19e17;
        tokenA.approve(address(helloSource), amount);
        tokenB.approve(address(helloSource), amount);

        uint cost = helloSource.quoteRemoteLP(targetChain);

        vm.recordLogs();
        helloSource.sendRemoteLP{value: cost}(
            targetChain,
            address(helloTarget),
            amount,
            address(tokenA),
            address(tokenB)
        );
        performDelivery(3);

        vm.selectFork(targetFork);
        LiquidityProvided[] memory lp = helloTarget
            .getLiquiditiesProvidedHistory();
        assertEq(lp.length, 1, "lp.length");
        assertEq(lp[0].senderChain, sourceChain, "senderChain");
        assertEq(lp[0].sender, address(this), "sender");
        assertEq(lp[0].tokenA, address(tokenA), "tokenA");
        assertEq(lp[0].tokenB, address(tokenB), "tokenB");
        assertEq(lp[0].amount, amount, "amount");
    }
}
