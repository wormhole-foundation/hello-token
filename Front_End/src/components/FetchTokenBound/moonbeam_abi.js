module.exports = {
  "abi_avalanche": [
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "_wormholeRelayer",
          "type": "address"
        },
        {
          "internalType": "address",
          "name": "_tokenBridge",
          "type": "address"
        },
        {
          "internalType": "address",
          "name": "_wormhole",
          "type": "address"
        }
      ],
      "stateMutability": "nonpayable",
      "type": "constructor"
    },
    {
      "inputs": [
        {
          "internalType": "bytes32",
          "name": "",
          "type": "bytes32"
        }
      ],
      "name": "NotAnEvmAddress",
      "type": "error"
    },
    {
      "inputs": [
        {
          "internalType": "uint16",
          "name": "targetChain",
          "type": "uint16"
        }
      ],
      "name": "quoteCrossChainDeposit",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "cost",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "bytes",
          "name": "payload",
          "type": "bytes"
        },
        {
          "internalType": "bytes[]",
          "name": "additionalVaas",
          "type": "bytes[]"
        },
        {
          "internalType": "bytes32",
          "name": "sourceAddress",
          "type": "bytes32"
        },
        {
          "internalType": "uint16",
          "name": "sourceChain",
          "type": "uint16"
        },
        {
          "internalType": "bytes32",
          "name": "deliveryHash",
          "type": "bytes32"
        }
      ],
      "name": "receiveWormholeMessages",
      "outputs": [],
      "stateMutability": "payable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint16",
          "name": "targetChain",
          "type": "uint16"
        },
        {
          "internalType": "address",
          "name": "targetHelloToken",
          "type": "address"
        },
        {
          "internalType": "address",
          "name": "recipient",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "amount",
          "type": "uint256"
        },
        {
          "internalType": "address",
          "name": "token",
          "type": "address"
        }
      ],
      "name": "sendCrossChainDeposit",
      "outputs": [],
      "stateMutability": "payable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint16",
          "name": "sourceChain",
          "type": "uint16"
        },
        {
          "internalType": "bytes32",
          "name": "sourceAddress",
          "type": "bytes32"
        }
      ],
      "name": "setRegisteredSender",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "tokenBridge",
      "outputs": [
        {
          "internalType": "contract ITokenBridge",
          "name": "",
          "type": "address"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "wormhole",
      "outputs": [
        {
          "internalType": "contract IWormhole",
          "name": "",
          "type": "address"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "wormholeRelayer",
      "outputs": [
        {
          "internalType": "contract IWormholeRelayer",
          "name": "",
          "type": "address"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    }
  ],
}