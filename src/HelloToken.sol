// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "wormhole-solidity-sdk/WormholeRelayerSDK.sol";

contract HelloToken is TokenSender, TokenReceiver {

    constructor(address _wormholeRelayer, address _tokenBridge, address _wormhole)
        TokenBase(_wormholeRelayer, _tokenBridge, _wormhole)
    {}

    /**
     * receivePayloadAndTokens should 
     * 1) obtain the intended 'recipient' address from the payload
     * 2) transfer the correct amount of the correct token to that address
     * 
     * Only 'wormholeRelayer' should be allowed to call this method
     * 
     * @param payload This will be 'abi.encode(recipient)'
     * @param receivedTokens This will be an array of length 1
     * describing the amount and address of the token received
     * (the 'amount' field indicates the amount,
     * and the 'tokenAddress' field indicates the address of the IERC20 token
     * that was received, which will be a wormhole-wrapped version of the sent token)
     */
    function receivePayloadAndTokens(
        bytes memory payload,
        TokenReceived[] memory receivedTokens,
        bytes32, // sourceAddress
        uint16,
        bytes32 // deliveryHash
    ) internal override {
        // implement this function!
        // run 'forge test' to test your implementation   
    }
}
