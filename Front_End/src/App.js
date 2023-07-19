import './App.css';
import Fetch from './components/FetchTokenBound/Fetch';

import { EthereumClient, w3mConnectors, w3mProvider } from '@web3modal/ethereum';
import { Web3Modal } from '@web3modal/react';
import { configureChains, createConfig, WagmiConfig } from 'wagmi';
import { avalancheFuji, goerli, mainnet, polygon, moonbaseAlpha } from 'wagmi/chains';
import { infuraProvider } from '@wagmi/core/providers/infura';
import { jsonRpcProvider } from '@wagmi/core/providers/jsonRpc'

const chains = [avalancheFuji, mainnet, polygon, moonbaseAlpha, goerli]
const projectId = "59198889d7df78b39ea70d871d0ec131";

const { publicClient } = configureChains(
  chains, 
  [ w3mProvider({ projectId }), 
    infuraProvider({ apiKey: '1cd853bc10304f8ba6faa52343f86aac' }),
  
    jsonRpcProvider({
      rpc: (chain) => ({
        http: "https://delicate-rough-paper.ethereum-goerli.discover.quiknode.pro/62d1a00db9b99cef05ef6079b54eb21d8e7c132a/",
      }),
    }),
  ]
  
);

const wagmiConfig = createConfig({
  autoConnect: true,
  connectors: w3mConnectors({ projectId, chains }),
  publicClient
});

const ethereumClient = new EthereumClient(wagmiConfig, chains);

function App() {
  return (
    <>
      <WagmiConfig config={wagmiConfig}>
   
        <Fetch/>
   
      </WagmiConfig>
      <Web3Modal projectId={projectId} ethereumClient={ethereumClient} />
    </>
  );
}

export default App;
