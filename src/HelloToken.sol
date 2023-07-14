// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "wormhole-solidity-sdk/WormholeRelayerSDK.sol";

contract HelloToken is TokenSender, TokenReceiver {

    constructor(address _wormholeRelayer, address _tokenBridge, address _wormhole)
        TokenBase(_wormholeRelayer, _tokenBridge, _wormhole)
    {}

    function quoteCrossChainDeposit(uint16 targetChain) public view returns (uint256 cost) {
       // Return the msg.value needed to call sendCrossChainDeposit!
        cost = 0;
    }

    /**
     * Sends, through Token Bridge, 
     * 'amount' of the IERC20 token 'wrappedToken'
     * to the address 'recipient' on chain 'targetChain'
     * 
     * where 'wrappedToken' is a wormhole-wrapped version
     * of the IERC20 token 'token' on this chain (which can later 
     * be redeemed for 'token')
     * 
     * Assumes that 'amount' of 'token' was approved to be transferred
     * from msg.sender to this contract
     */
    function sendCrossChainDeposit(
        uint16 targetChain,
        address targetHelloToken,
        address recipient,
        uint256 amount,
        address token
    ) public payable {
        uint256 cost = quoteCrossChainDeposit(targetChain);
        require(msg.value == cost);
        
        // Transfer 'amount' of token from 'msg.sender' to this contract
        // and then call sendTokenWithPayloadToEvm with the appropriate inputs!
        //
        // Test your code with 'forge test'
    }

    function receivePayloadAndTokens(
        bytes memory payload,
        TokenReceived[] memory receivedTokens,
        bytes32, // sourceAddress
        uint16,
        bytes32 // deliveryHash
    ) internal override onlyWormholeRelayer {
        require(receivedTokens.length == 1, "Expected 1 token transfers");

        address recipient = abi.decode(payload, (address));

        IERC20(receivedTokens[0].tokenAddress).transfer(recipient, receivedTokens[0].amount);
    }
}
