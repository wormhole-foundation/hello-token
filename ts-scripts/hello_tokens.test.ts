import {describe, expect, test} from "@jest/globals";
import { ethers } from "ethers";
import {
    getHelloTokens,
    loadDeployedAddresses as getDeployedAddresses,
    getWallet,
    getChain,
    wait
} from "./utils"
import {
    ERC20Mock__factory,
    ITokenBridge__factory
} from "./ethers-contracts"
import {
    tryNativeToUint8Array,
} from "@certusone/wormhole-sdk"

const sourceChain = 6;
const targetChain = 14;

describe("Hello Tokens Integration Tests on Testnet", () => {
    test("Tests the sending of a token", async () => {
        const arbitraryTokenAmount = ethers.BigNumber.from((new Date().getTime()) % (10 ** 11)).mul(10**6);

        const HTtoken = ERC20Mock__factory.connect(getDeployedAddresses().erc20s[sourceChain][0], getWallet(sourceChain));

        const wormholeWrappedHTTokenAddressOnTargetChain = await ITokenBridge__factory.connect(getChain(targetChain).tokenBridge, getWallet(targetChain)).wrappedAsset(sourceChain, tryNativeToUint8Array(HTtoken.address, "ethereum"));
        const wormholeWrappedHTTokenOnTargetChain = ERC20Mock__factory.connect(wormholeWrappedHTTokenAddressOnTargetChain, getWallet(targetChain));

        const sourceHelloTokensContract = getHelloTokens(sourceChain);
        const targetHelloTokensContract = getHelloTokens(targetChain);

        const targetHelloTokensContractOriginalBalanceOfHTToken = await wormholeWrappedHTTokenOnTargetChain.balanceOf(targetHelloTokensContract.address);

        const cost = await sourceHelloTokensContract.quoteRemoteDeposit(targetChain);
        console.log(`Cost of sending the tokens: ${ethers.utils.formatEther(cost)} testnet AVAX`);

        // Approve the HelloTokens contract to use 'arbitraryTokenAmount' of our HT token
        const approveTx = await HTtoken.approve(sourceHelloTokensContract.address, arbitraryTokenAmount).then(wait);
        console.log(`HelloTokens contract approved to spend ${ethers.utils.formatEther(arbitraryTokenAmount)} of our HT token`)

        console.log(`Sending ${ethers.utils.formatEther(arbitraryTokenAmount)} of the HT token`);

        const tx = await sourceHelloTokensContract.sendRemoteDeposit(targetChain, targetHelloTokensContract.address, arbitraryTokenAmount, HTtoken.address, {value: cost});
        
        console.log(`Transaction hash: ${tx.hash}`);
        await tx.wait();
        console.log(`See transaction at: https://testnet.snowtrace.io/tx/${tx.hash}`);

        await new Promise(resolve => setTimeout(resolve, 1000*5));

        console.log(`Seeing if token was sent`);
        const targetHelloTokensContractCurrentBalanceOfHTToken = await wormholeWrappedHTTokenOnTargetChain.balanceOf(targetHelloTokensContract.address);

        expect(targetHelloTokensContractCurrentBalanceOfHTToken.sub(targetHelloTokensContractOriginalBalanceOfHTToken).toString()).toBe(arbitraryTokenAmount.toString());
    }, 60*1000) // timeout
})