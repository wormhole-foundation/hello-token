// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {HelloToken, Deposit} from "../src/HelloToken.sol";

import "wormhole-relayer-solidity-sdk/testing/WormholeRelayerTest.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract HelloTokenTest is WormholeRelayerTest {
    HelloToken public helloSource;
    HelloToken public helloTarget;

    ERC20Mock public token;

    function setUpSource() public override {
        helloSource = new HelloToken(
            address(relayerSource),
            address(tokenBridgeSource),
            address(wormholeSource)
        );

        token = createAndAttestToken(sourceFork);
    }

    function setUpTarget() public override {
        helloTarget = new HelloToken(
            address(relayerTarget),
            address(tokenBridgeTarget),
            address(wormholeTarget)
        );
    }

    function testRemoteDeposit() public {
        uint256 amount = 19e17;
        token.approve(address(helloSource), amount);

        uint256 cost = helloSource.quoteRemoteDeposit(targetChain);

        vm.recordLogs();
        helloSource.sendRemoteDeposit{value: cost}(
            targetChain, address(helloTarget), amount, address(token)
        );
        performDelivery();

        vm.selectFork(targetFork);
        (uint16 senderChain, address sender, address depositToken, uint256 depositAmt) =
            helloTarget.lastDeposit();
        assertEq(senderChain, sourceChain, "senderChain");
        assertEq(sender, address(this), "sender");
        assertEq(depositToken, address(token), "tokenB");
        assertEq(depositAmt, amount, "amount");
    }
}
