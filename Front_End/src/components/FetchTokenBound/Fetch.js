import "./Fetch.css";

import { create } from 'ipfs-http-client';
import { useState } from "react";
import { useConnect, useAccount } from 'wagmi';
import { getPublicClient } from '@wagmi/core';
import WalletConnect from "../WalletConnect/WalletConnect";

import { ethers } from 'ethers';

function Fetch() {

    const Contract_Address = "0x0ee7F43c91Ca54DEEFb58B261A454B9E8b4FEe8B";
    const mint_address = "0x7199D548f1B30EA083Fe668202fd5E621241CC89";
    const { connect, connectors, error, isLoading, pendingConnector, provider } = useConnect()
    const { address, isConnected } = useAccount();
    const publicClient = getPublicClient();
    console.log(publicClient);

    if (isConnected) {
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



    const moonbeamContractAddress = "0x0591C25ebd0580E0d4F27A82Fc2e24E7489CB5e0";
    const avalancheContractAddress = "0x04b80Cfd834085734E2783f0475829E195a5E812";


    const [amountToSent, setAmountToSent] = useState(ethers.BigNumber.from(0));

    const handleInputChange = (event) => {
        const inputValue = event.target.value;
        const newValue = ethers.BigNumber.from(inputValue);

        // Ensure that the value is not negative before updating the state
        if (newValue.gte(0)) {
            setAmountToSent(newValue);
        }
    };

    const handleKeyDown = (event) => {
        const keyCode = event.which || event.keyCode;
        // Prevent entry of negative sign (minus) character (keycode: 45)
        if (keyCode === 45) {
            event.preventDefault();
        }
    };

    const BridgeToken = async () => {
        try {
            // Token Bridge can only deal with 8 decimal places
            // const formattedAmount = amountToSent.mul(10 ** 8);

            // // Source and target chain IDs
            // const sourceChain = 6;
            // const targetChain = 16;
            // const signer = provider.getSigner();

            // // Get the source HT token contract
            // const HTtoken = ERC20Mock__factory.connect(avalancheContractAddress, signer);

            // const cost = ethers.utils.parseEther('0.1');

            // // Approve the HelloToken contract to spend 'formattedAmount' of our HT token
            // const approveTx = await HTtoken.approve(getHelloToken(sourceChain).address, formattedAmount);
            // await approveTx.wait();

            // console.log(`Sending ${formattedAmount.toString()} of the HT token`);

            // // Send the tokens through the bridge
            // const tx = await getHelloToken(sourceChain).sendCrossChainDeposit(
            //     targetChain,
            //     getHelloToken(targetChain).address,
            //    // walletTargetChainAddress,
            //     formattedAmount,
            //     HTtoken.address,
            //     { value: cost }
            //);

            // console.log(`Transaction hash: ${tx.hash}`);
            // await tx.wait();
            // console.log(`See transaction at: https://testnet.snowtrace.io/tx/${tx.hash}`);

            // // Wait for some time (optional)
            // await new Promise((resolve) => setTimeout(resolve, 30000));

        } catch (error) {
            console.error('Error:', error);
        }
    };


    return (
        <>
            <div className="mybuttons">

                <h2 className="nam"> Intercontinentenal bridge </h2>
            </div>

            <div className="mybuttons">
                <WalletConnect />
            </div>


            {isConnected == false ? <h2 className="h2center">
                Connect wallet
            </h2>
                :
                <>

                    <div className="App">
                        <h2 className="h2cen">Wallet conneted successfully</h2>
                    </div>
                </>
            }

            <div>
                <label htmlFor="amountInput" style={{ color: 'red' }}>Enter Amount to Bridge:</label>
                <input
                    type="number"
                    id="amountInput"
                    value={amountToSent.toString()}
                    onChange={handleInputChange}
                    onKeyDown={handleKeyDown}
                />
            //<button className="btn" onClick={BridgeToken}>Bridge Token to Moonbeam</button>
            </div>

        </>
    );
}
export default Fetch;
