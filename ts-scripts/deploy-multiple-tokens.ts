import { ethers } from "ethers";
// Manual ABI for deployment
import {
  loadConfig,
  getWallet,
  storeDeployedAddresses,
  getChain,
  loadDeployedAddresses,
} from "./utils";

export async function deployMultipleTokens() {
  const config = loadConfig();

  // Deploy to source and target chains
  const deployed = loadDeployedAddresses();
  for (const chainId of [config.sourceChain, config.targetChain]) {
    const chain = getChain(chainId);
    const signer = getWallet(chainId);

    console.log(`Deploying HelloMultipleTokens to chain ${chainId}...`);

    // Get the contract bytecode from the compiled artifacts
    const contractPath = `out/HelloMultipleTokens.sol/HelloMultipleTokens.json`;
    const contractArtifact = require(`../${contractPath}`);
    const bytecode = contractArtifact.bytecode.object;

    // Create contract factory with minimal ABI
    const factory = new ethers.ContractFactory(
      [
        "constructor(address _wormholeRelayer, address _tokenBridge, address _wormhole)",
        "function quoteCrossChainDeposit(uint16 targetChain) view returns (uint256)",
        "function sendCrossChainDeposit(uint16 targetChain, address targetHelloTokens, address recipient, uint256 amountA, address tokenA, uint256 amountB, address tokenB) payable"
      ],
      bytecode,
      signer
    );

    const helloMultipleTokens = await factory.deploy(
      chain.wormholeRelayer,
      chain.tokenBridge!,
      chain.wormhole
    );
    await helloMultipleTokens.deployed();

    // Initialize helloMultipleTokens in deployed addresses if it doesn't exist
    if (!deployed.helloMultipleTokens) {
      deployed.helloMultipleTokens = {};
    }
    deployed.helloMultipleTokens[chainId] = helloMultipleTokens.address;
    
    console.log(
      `HelloMultipleTokens deployed to ${helloMultipleTokens.address} on chain ${chainId}`
    );
  }

  storeDeployedAddresses(deployed);
  console.log("HelloMultipleTokens deployment completed!");
}

// Run if called directly
if (require.main === module) {
  deployMultipleTokens()
    .then(() => {
      console.log("Deployment completed successfully");
      process.exit(0);
    })
    .catch((error) => {
      console.error("Deployment failed:", error);
      process.exit(1);
    });
} 