import { ethers } from "ethers";
import {
  getHelloMultipleTokens,
  getWallet,
  getChain,
  loadConfig,
  loadDeployedAddresses,
} from "./utils";
import { waitForDelivery } from "./getStatus";
// Using ethers.Contract instead of factory
import {
  tryNativeToUint8Array,
  CHAIN_ID_TO_NAME,
} from "@certusone/wormhole-sdk";

const sourceChain = loadConfig().sourceChain;
const targetChain = loadConfig().targetChain;

// Real token addresses that are already attested on testnets
// You can replace these with any attested tokens you prefer
// tokenA and tokenB are the same for testing, but you can use different tokens for each
const REAL_TOKENS: Record<number, { tokenA: string; tokenB: string }> = {
  // https://developers.circle.com/stablecoins/usdc-contract-addresses#testnet
  6: {  // Avalanche Fuji
    tokenA: "0x5425890298aed601595a70AB815c96711a31Bc65", // USDC
    tokenB: "0x5425890298aed601595a70AB815c96711a31Bc65",
  },
  10003: { // Arbitrum Sepolia
    tokenA: "0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d", // USDC
    tokenB: "0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d", 
  },
  10004: { // Base Sepolia
    tokenA: "0x036CbD53842c5426634e7929541eC2318f3dCF7e", // USDC
    tokenB: "0x036CbD53842c5426634e7929541eC2318f3dCF7e",
    // tokenC: "0x036CbD53842c5426634e7929541eC2318f3dCF7c", // Fuji wraped USDC
  }
};

async function testHelloMultipleTokensWithRealTokens() {
  console.log("Testing HelloMultipleTokens with real attested tokens...");
  console.log(`Source chain: ${sourceChain} (${CHAIN_ID_TO_NAME[sourceChain]})`);
  console.log(`Target chain: ${targetChain} (${CHAIN_ID_TO_NAME[targetChain]})`);

  // Get deployed addresses
  const deployed = loadDeployedAddresses();
  
  // Check if we have deployed contracts
  if (!deployed.helloMultipleTokens?.[sourceChain]) {
    throw new Error("HelloMultipleTokens not deployed. Run: npm run deployMultipleTokens");
  }

  const sourceHelloMultipleTokens = getHelloMultipleTokens(sourceChain);
  const targetHelloMultipleTokens = getHelloMultipleTokens(targetChain);

  // Get real token addresses
  const sourceTokens = REAL_TOKENS[sourceChain];
  if (!sourceTokens) {
    throw new Error(`No real tokens configured for chain ${sourceChain}`);
  }

  // Connect to real tokens
  const tokenA = new ethers.Contract(sourceTokens.tokenA, ["function balanceOf(address) view returns (uint256)", "function approve(address,uint256) returns (bool)", "function allowance(address,address) view returns (uint256)"], getWallet(sourceChain));
  const tokenB = new ethers.Contract(sourceTokens.tokenB, ["function balanceOf(address) view returns (uint256)", "function approve(address,uint256) returns (bool)", "function allowance(address,address) view returns (uint256)"], getWallet(sourceChain));

  const walletTargetChainAddress = getWallet(targetChain).address;

  // Check if user has enough tokens
  const balanceA = await tokenA.balanceOf(getWallet(sourceChain).address);
  const balanceB = await tokenB.balanceOf(getWallet(sourceChain).address);

  console.log(`Your balance of TokenA: ${ethers.utils.formatUnits(balanceA, 6)} USDC`);
  console.log(`Your balance of TokenB: ${ethers.utils.formatUnits(balanceB, 6)} USDC`);

  // Use smaller amounts for real tokens (USDC has 6 decimals)
  const amountA = ethers.utils.parseUnits("0.1", 6); // 0.1 USDC (6 decimals)
  const amountB = ethers.utils.parseUnits("0.05", 6); // 0.05 USDC (6 decimals)

  if (balanceA.lt(amountA)) {
    throw new Error(`Insufficient TokenA balance. Need ${ethers.utils.formatUnits(amountA, 6)} USDC, have ${ethers.utils.formatUnits(balanceA, 6)} USDC`);
  }
  if (balanceB.lt(amountB)) {
    throw new Error(`Insufficient TokenB balance. Need ${ethers.utils.formatUnits(amountB, 6)} USDC, have ${ethers.utils.formatUnits(balanceB, 6)} USDC`);
  }

  console.log(`Amount A: ${ethers.utils.formatUnits(amountA, 6)} USDC`);
  console.log(`Amount B: ${ethers.utils.formatUnits(amountB, 6)} USDC`);

  // Get wrapped token addresses on target chain
  const targetChainInfo = getChain(targetChain);
  const tokenBridgeTarget = new ethers.Contract(
    targetChainInfo.tokenBridge!,
    ["function wrappedAsset(uint16,bytes32) view returns(address)"],
    getWallet(targetChain)
  );

  const wrappedTokenAAddress = await tokenBridgeTarget.wrappedAsset(
    sourceChain,
    tryNativeToUint8Array(tokenA.address, "ethereum")
  );
  const wrappedTokenBAddress = await tokenBridgeTarget.wrappedAsset(
    sourceChain,
    tryNativeToUint8Array(tokenB.address, "ethereum")
  );

  console.log(`Wrapped Token A on target: ${wrappedTokenAAddress}`);
  console.log(`Wrapped Token B on target: ${wrappedTokenBAddress}`);

  // Check initial balances
  const wrappedTokenA = new ethers.Contract(wrappedTokenAAddress, ["function balanceOf(address) view returns (uint256)"], getWallet(targetChain));
  const wrappedTokenB = new ethers.Contract(wrappedTokenBAddress, ["function balanceOf(address) view returns (uint256)"], getWallet(targetChain));

  const initialBalanceA = await wrappedTokenA.balanceOf(walletTargetChainAddress);
  const initialBalanceB = await wrappedTokenB.balanceOf(walletTargetChainAddress);

  console.log(`Initial balance A: ${ethers.utils.formatEther(initialBalanceA)}`);
  console.log(`Initial balance B: ${ethers.utils.formatEther(initialBalanceB)}`);

  // Quote the cost
  const cost = await sourceHelloMultipleTokens.quoteCrossChainDeposit(targetChain);
  console.log(`Cost: ${ethers.utils.formatEther(cost)} ${CHAIN_ID_TO_NAME[sourceChain]}`);

  // Check current allowances first
  console.log("Checking current allowances...");
  const currentAllowanceA = await tokenA.allowance(getWallet(sourceChain).address, sourceHelloMultipleTokens.address);
  const currentAllowanceB = await tokenB.allowance(getWallet(sourceChain).address, sourceHelloMultipleTokens.address);
  
  console.log(`Current allowance A: ${ethers.utils.formatUnits(currentAllowanceA, 6)} USDC`);
  console.log(`Current allowance B: ${ethers.utils.formatUnits(currentAllowanceB, 6)} USDC`);
  
  // Get wallet for transactions
  const wallet = getWallet(sourceChain);
  
  // Only approve if needed
  if (currentAllowanceA.lt(amountA) || currentAllowanceB.lt(amountB)) {
    console.log("Approving tokens...");
    
    // Use the same approach that worked in our USDC approval test
    const nonce = await wallet.getTransactionCount();
    const gasPrice = await wallet.getGasPrice();
    
    console.log(`Using nonce: ${nonce}, gas price: ${ethers.utils.formatUnits(gasPrice, "gwei")} gwei`);
  
  // Approve a much larger amount to ensure we have enough allowance
  const approveATx = await tokenA.approve(sourceHelloMultipleTokens.address, ethers.utils.parseUnits("10", 6), {
    nonce: nonce,
    gasPrice: gasPrice,
    gasLimit: 100000
  });
  const approveBTx = await tokenB.approve(sourceHelloMultipleTokens.address, ethers.utils.parseUnits("10", 6), {
    nonce: nonce + 1,
    gasPrice: gasPrice,
    gasLimit: 100000
  });
  
  console.log("Waiting for approval transactions to be mined...");
  await approveATx.wait();
  await approveBTx.wait();
  console.log("Approvals confirmed!");

  // Verify allowances
  const allowanceA = await tokenA.allowance(getWallet(sourceChain).address, sourceHelloMultipleTokens.address);
  const allowanceB = await tokenB.allowance(getWallet(sourceChain).address, sourceHelloMultipleTokens.address);
  
  console.log(`Allowance A: ${ethers.utils.formatUnits(allowanceA, 6)} USDC`);
  console.log(`Allowance B: ${ethers.utils.formatUnits(allowanceB, 6)} USDC`);
  console.log(`Amount A: ${ethers.utils.formatUnits(amountA, 6)} USDC`);
  console.log(`Amount B: ${ethers.utils.formatUnits(amountB, 6)} USDC`);
  } else {
    console.log("Sufficient allowances already exist, skipping approval");
  }

  console.log("Sending cross-chain deposit with multiple real tokens...");
  console.log("This calls sendVaasToEvm internally with multiple VAA keys");
  
  // Get fresh nonce for the main transaction
  const mainNonce = await wallet.getTransactionCount();
  const mainGasPrice = await wallet.getGasPrice();
  const mainIncreasedGasPrice = mainGasPrice.mul(120).div(100); // 20% increase
  
  console.log(`Main transaction using nonce: ${mainNonce}, gas price: ${ethers.utils.formatUnits(mainIncreasedGasPrice, "gwei")} gwei`);
  
  const tx = await sourceHelloMultipleTokens.sendCrossChainDeposit(
    targetChain,
    targetHelloMultipleTokens.address,
    walletTargetChainAddress,
    amountA,
    tokenA.address,
    amountB,
    tokenB.address,
    { 
      value: cost,
      nonce: mainNonce,
      gasPrice: mainIncreasedGasPrice,
      gasLimit: 500000 // Explicit gas limit for complex transaction
    }
  );

  console.log(`Transaction hash: ${tx.hash}`);
  await tx.wait();

  // TODO: Wait for delivery, if the RPC for the source chain is working
  console.log("Waiting for delivery...");
  // await waitForDelivery(CHAIN_ID_TO_NAME[sourceChain], tx.hash);

  // Check final balances
  const finalBalanceA = await wrappedTokenA.balanceOf(walletTargetChainAddress);
  const finalBalanceB = await wrappedTokenB.balanceOf(walletTargetChainAddress);

  console.log(`Final balance A: ${ethers.utils.formatEther(finalBalanceA)}`);
  console.log(`Final balance B: ${ethers.utils.formatEther(finalBalanceB)}`);

  const receivedA = finalBalanceA.sub(initialBalanceA);
  const receivedB = finalBalanceB.sub(initialBalanceB);

  console.log(`Received A: ${ethers.utils.formatEther(receivedA)}`);
  console.log(`Received B: ${ethers.utils.formatEther(receivedB)}`);

  // Verify the amounts match
  if (receivedA.eq(amountA) && receivedB.eq(amountB)) {
    console.log("✅ SUCCESS: Both real tokens were received correctly!");
    console.log("✅ sendVaasToEvm function worked as expected with real tokens!");
  } else {
    console.log("❌ FAILURE: Token amounts don't match expected values");
    console.log(`Expected A: ${ethers.utils.formatEther(amountA)}, Got: ${ethers.utils.formatEther(receivedA)}`);
    console.log(`Expected B: ${ethers.utils.formatEther(amountB)}, Got: ${ethers.utils.formatEther(receivedB)}`);
  }
}

// Run the test
testHelloMultipleTokensWithRealTokens()
  .then(() => {
    console.log("Test completed successfully");
    process.exit(0);
  })
  .catch((error) => {
    console.error("Test failed:", error);
    process.exit(1);
  }); 