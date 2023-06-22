import {describe, expect, test} from "@jest/globals";
import { ethers } from "ethers";
import {
    getHelloTokens,
    loadDeployedAddresses as getDeployedAddresses,
    getWallet
} from "./utils"
import {
    ERC20Mock__factory
} from "./ethers-contracts"

const sourceChain = 6;
const targetChain = 14;

describe("Hello Tokens Integration Tests on Testnet", () => {
    test("Tests the sending of a token", async () => {
        const arbitraryTokenAmount = ethers.BigNumber.from((new Date().getTime()) % (10 ** 11)).mul(10**6);

        const HTtoken = ERC20Mock__factory.connect(getDeployedAddresses().erc20s[sourceChain][0], getWallet(sourceChain));

        const sourceHelloTokensContract = getHelloTokens(sourceChain);
        const targetHelloTokensContract = getHelloTokens(targetChain);

        const targetHelloTokensContractOriginalBalanceOfHTToken = await HTtoken.balanceOf(targetHelloTokensContract.address);

        const cost = await sourceHelloTokensContract.quoteRemoteDeposit(targetChain);
        console.log(`Cost of sending the tokens: ${ethers.utils.formatEther(cost)} testnet AVAX`);

        console.log(`Sending ${ethers.utils.formatEther(arbitraryTokenAmount)} of the HT token`);
        // Approve the HelloTokens contract to use 'arbitraryTokenAmount' of our HT token
        HTtoken.approve(sourceHelloTokensContract.address, arbitraryTokenAmount);
        const tx = await sourceHelloTokensContract.sendRemoteDeposit(targetChain, targetHelloTokensContract.address, arbitraryTokenAmount, HTtoken.address, {value: cost});
        
        console.log(`Transaction hash: ${tx.hash}`);
        await tx.wait();
        console.log(`See transaction at: https://testnet.snowtrace.io/tx/${tx.hash}`);

        await new Promise(resolve => setTimeout(resolve, 1000*5));

        console.log(`Seeing if token was sent`);
        // code to see if token was sent
        
    }, 60*1000) // timeout
})