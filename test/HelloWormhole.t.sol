// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/HelloTokens.sol";
import "../src/interfaces/IWormholeRelayer.sol";
import "../src/interfaces/IWormhole.sol";

import "./mocks/MockWormholeRelayer.sol";
import "./mocks/WormholeSimulator.sol";
import "./mocks/ERC20.sol";
import "./mocks/DeliveryInstructionDecoder.sol";
import "../lib/ExecutionParameters.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract HelloWormholeTest is Test {
    event GreetingReceived(string greeting, uint16 senderChain, address sender);

    // fuji testnet forked contracts
    IWormholeRelayer relayer =
        IWormholeRelayer(0xA3cF45939bD6260bcFe3D66bc73d60f19e49a8BB);
    ITokenBridge tokenBridge =
        ITokenBridge(0x61E44E506Ca5659E6c0bba9b678586fA2d729756);
    IWormhole wormhole = IWormhole(0x7bbcE28e64B3F8b84d876Ab298393c38ad7aac4C);

    IWormholeRelayer relayerTarget =
        IWormholeRelayer(0x306B68267Deb7c5DfCDa3619E22E9Ca39C374f84);
    ITokenBridge tokenBridgeTarget =
        ITokenBridge(0x05ca6037eC51F8b712eD2E6Fa72219FEaE74E153);
    IWormhole wormholeTarget =
        IWormhole(0x88505117CA88e7dd2eC6EA1E13f0948db2D50D56);

    WormholeSimulator guardian;
    WormholeSimulator guardianTarget;

    HelloTokens hello;
    HelloTokens helloTarget;

    ERC20Mock tokenA;
    ERC20Mock tokenB;

    uint fujiFork;
    uint celoFork;

    // MockWormholeRelayer _mockRelayer;

    string constant FUJI_URL = "https://api.avax-test.network/ext/bc/C/rpc";
    string constant CELO_URL = "https://alfajores-forno.celo-testnet.org";

    uint256 constant DEVNET_GUARDIAN_PK =
        0xcfb12303a19cde580bb4dd771639b0d26bc68353645571a8cff516ab2ee113a0;

    // target is also fuji testnet to make dealing with forks easier
    uint16 constant targetChain = 6;

    function setUp() public {
        celoFork = vm.createFork(CELO_URL);
        fujiFork = vm.createSelectFork(FUJI_URL);

        // set up Wormhole using Wormhole existing on FUJI testnet
        guardian = new WormholeSimulator(address(wormhole), DEVNET_GUARDIAN_PK);

        // set up HelloTokens contracts
        hello = new HelloTokens(
            address(relayer),
            address(tokenBridge),
            address(wormhole)
        );

        // deploy ERC20 tokens and approve HelloTokens to transfer
        tokenA = new ERC20Mock("TokenA", "tA");
        tokenA.mint(address(this), 10000);
        tokenA.approve(address(hello), 10000);

        tokenB = new ERC20Mock("TokenB", "tB");
        tokenB.mint(address(this), 10000);
        tokenB.approve(address(hello), 10000);

        // attest ERC20 tokens on target chain
        vm.recordLogs();
        tokenBridge.attestToken(address(tokenA), 0);
        tokenBridge.attestToken(address(tokenB), 0);
        Vm.Log[] memory logs = vm.getRecordedLogs();

        // find published wormhole messages from log
        Vm.Log[] memory publishedMessages = guardian
            .fetchWormholeMessageFromLog(logs, 2);

        bytes[] memory encodedVms = new bytes[](2);
        for (uint i = 0; i < publishedMessages.length; i++) {
            encodedVms[i] = guardian.fetchSignedMessageFromLogs(
                publishedMessages[i],
                guardian.wormhole().chainId(),
                address(tokenBridge)
            );
        }
        vm.selectFork(celoFork);
        guardianTarget = new WormholeSimulator(
            address(wormholeTarget),
            DEVNET_GUARDIAN_PK
        );
        for (uint i = 0; i < encodedVms.length; i++) {
            tokenBridgeTarget.createWrapped(encodedVms[i]);
        }
        console.log("below for loop");

        helloTarget = new HelloTokens(
            address(relayerTarget),
            address(tokenBridgeTarget),
            address(wormholeTarget)
        );
        vm.selectFork(fujiFork);
    }

    function testGreeting() public {
        uint cost = hello.quoteRemoteLP(targetChain);

        vm.recordLogs();
        hello.sendRemoteLP{value: cost}(
            targetChain,
            address(helloTarget),
            100,
            address(tokenA),
            address(tokenB)
        );

        Vm.Log[] memory logs = vm.getRecordedLogs();
        require(logs.length > 0, "no events recorded");
        console.log(logs.length);

        // find published wormhole messages from log
        Vm.Log[] memory publishedMessages = guardian
            .fetchWormholeMessageFromLog(logs, 3);

        // simulate signing the Wormhole message
        // NOTE: in the wormhole-sdk, signed Wormhole messages are referred to as signed VAAs
        bytes memory transferA = guardian.fetchSignedMessageFromLogs(
            publishedMessages[0],
            guardian.wormhole().chainId(),
            address(hello)
        );
        bytes memory transferB = guardian.fetchSignedMessageFromLogs(
            publishedMessages[1],
            guardian.wormhole().chainId(),
            address(hello)
        );
        bytes memory deliveryVaa = guardian.fetchSignedMessageFromLogs(
            publishedMessages[2],
            guardian.wormhole().chainId(),
            address(hello)
        );

        vm.selectFork(celoFork);

        bytes[] memory encodedVms = new bytes[](2);
        encodedVms[0] = transferA;
        encodedVms[1] = transferB;

        console.log("above decoding");
        IWormhole.VM memory parsedTransferVaaA = wormholeTarget.parseVM(
            transferA
        );
        IWormhole.VM memory deliveryParsed = wormholeTarget.parseVM(
            deliveryVaa
        );
        DeliveryInstruction memory ix = decodeDeliveryInstruction(
            deliveryParsed.payload
        );
        console.log("above exec");
        EvmExecutionInfoV1 memory execInfo = decodeEvmExecutionInfoV1(
            ix.encodedExecutionInfo
        );

        console.log("deliveryVaa emitter      ", fromWormholeFormat(deliveryParsed.emitterAddress));
        console.log("token transfer emitter   ",fromWormholeFormat(parsedTransferVaaA.emitterAddress));
        console.log("hello contract addr      ",address(hello));
        console.log("forge test contract addr ",address(this));

        relayerTarget.deliver{
            value: ix.requestedReceiverValue +
                ix.extraReceiverValue +
                execInfo.targetChainRefundPerGasUnused *
                execInfo.gasLimit
        }(encodedVms, deliveryVaa, payable(address(this)), new bytes(0));

        // uint256 cost = helloA.quoteGreeting(targetChain);
        // helloA.sendGreeting{value: cost}(
        //     targetChain,
        //     address(helloB),
        //     "Hello Wormhole!"
        // );
        // vm.expectEmit();
        // emit GreetingReceived(
        //     "Hello Wormhole!",
        //     _mockRelayer.chainId(),
        //     address(helloA)
        // );
        // _mockRelayer.performRecordedDeliveries();
        // assertEq(helloB.greetings(0), "Hello Wormhole!");
    }

    receive() external payable {}
}
