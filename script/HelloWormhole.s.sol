// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/HelloTokens.sol";

contract HelloWormholeScript is Script {
    event Deployed(address addr);

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address relayer = vm.envAddress("WORMHOLE_RELAYER");
        address tokenBridge = vm.envAddress("TOKEN_BRIDGE");
        address wormhole = vm.envAddress("WORMHOLE");
        vm.startBroadcast(deployerPrivateKey);

        HelloTokens hello = new HelloTokens(relayer, tokenBridge, wormhole);

        emit Deployed(address(hello));

        vm.stopBroadcast();
    }
}
