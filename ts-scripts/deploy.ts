import { ethers } from "ethers"
import { HelloToken__factory, ERC20Mock__factory } from "./ethers-contracts"
import {
  loadConfig,
  getWallet,
  storeDeployedAddresses,
  getChain,
  wait,
  loadDeployedAddresses,
} from "./utils"

export async function deploy() {
  const config = loadConfig()

  // fuij and celo
  const deployed = loadDeployedAddresses()
  for (const chainId of [6, 14]) {
    const chain = getChain(chainId)
    const signer = getWallet(chainId)

    const helloToken = await new HelloToken__factory(signer).deploy(
      chain.wormholeRelayer,
      chain.tokenBridge!,
      chain.wormhole
    )
    await helloToken.deployed()

    deployed.helloToken[chainId] = helloToken.address
    console.log(
      `HelloToken deployed to ${helloToken.address} on chain ${chainId}`
    )
  }

  storeDeployedAddresses(deployed)
}

