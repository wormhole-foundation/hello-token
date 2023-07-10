// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {HelloToken} from "../src/HelloToken.sol";

import "wormhole-solidity-sdk/testing/WormholeRelayerTest.sol";

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

    function testCrossChainDeposit_Step1() public {

        bytes32 sourceAddress = toWormholeFormat(address(helloSource));

        uint256 amount = 19e17;
        token.approve(address(tokenBridgeSource), amount);

        vm.recordLogs(); 
        tokenBridgeSource.transferTokensWithPayload(address(token), amount, targetChain, toWormholeFormat(address(helloTarget)), 0, bytes(""));
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes memory signedVaa = guardianSource.fetchSignedMessageFromLogs(logs[logs.length - 1], sourceChain);

        vm.selectFork(targetFork);

        address recipient = 0x1234567890123456789012345678901234567890;
        bytes[] memory signedVaas = new bytes[](1);
        signedVaas[0] = signedVaa;

        vm.prank(address(relayerTarget));
        helloTarget.receiveWormholeMessages(
            abi.encode(recipient),
            signedVaas,
            sourceAddress,
            sourceChain,
            keccak256("Arbitrary Delivery Hash")
        );

        address wormholeWrappedToken = tokenBridgeTarget.wrappedAsset(sourceChain, toWormholeFormat(address(token)));
 
        assertEq(IERC20(wormholeWrappedToken).balanceOf(recipient), amount);
    }
}
