import "./Fetch.css";
import { abi_avalanche } from "./avalanche_abi";
import { abi_moonbeam } from "./moonbeam_abi";

import { create } from 'ipfs-http-client';
import { useEffect, useState } from "react";
import { useConnect, useAccount } from 'wagmi';
import { getPublicClient } from '@wagmi/core';
import WalletConnect from "../WalletConnect/WalletConnect";

import { prepareSendTransaction, sendTransaction } from '@wagmi/core';
import { parseEther } from 'viem';
import { writeContract } from '@wagmi/core';
import { useContractReads } from 'wagmi';
import { infuraProvider } from '@wagmi/core/providers/infura';
import { ethers } from 'ethers';

function Fetch () {
    //const providesr = new ethers.providers.JsonRpcProvider("https://alpha-rpc.scroll.io/l2");
    
    const Contract_Address = "0x0ee7F43c91Ca54DEEFb58B261A454B9E8b4FEe8B";
    const mint_address = "0x7199D548f1B30EA083Fe668202fd5E621241CC89";
    const { connect, connectors, error, isLoading, pendingConnector, provider } = useConnect()
    const { address, isConnected } = useAccount();
    const publicClient = getPublicClient();
    console.log(publicClient);

    if(isConnected){
        console.log("Provider is: ", provider)
    }

    const [myArray, updateMyArray] = useState([]);

    const [fileUrl, updateFileUrl] = useState('');

    const projectId = '2SHg9nYGwUEpcXJuBTdkDcT2tYV';
    const projectSecret = '6834cfa182ec09eeff6577aca368802e';
    const auth = 'Basic ' + Buffer.from(projectId + ':' + projectSecret).toString('base64');
    const client = create({
    host: 'ipfs.infura.io',
    port: 5001,
    protocol: 'https',
    apiPath: '/api/v0',
    headers: {
        authorization: auth,
    }
    });



    const moonbeamContractAddress = "";
    const avalancheContractAddress = "";



    async function mint() {
        
    }


    async function Photogallery () 
    {
        
    }

    return(
        <>
        <div className="mybuttons">
           
            <h2 className="nam"> Intercontinentenal bridge </h2>
        </div>
            
            <div className="mybuttons">
            <WalletConnect/>
                <button className="btn" onClick={Photogallery}>NFT Minted</button>
            </div>



            <button className="mintbutton" onClick={mint}>Mint</button>


            {isConnected==false? <h2 className="h2center">
            Connect wallet
            </h2>
            :
            <>
                
                <div className="App">
                <h2 className="h2cen">Wallet conneted successfully</h2>
                </div>
            </>
            }

            
            


            <div className='nfts_container'>
        </div>

        </>
    );
}

export default Fetch;