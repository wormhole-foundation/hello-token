import * as ethers from "ethers"
import {
  checkFlag,
  getHelloToken,
  getWallet,
  loadDeployedAddresses as getDeployedAddresses,
  wait,
  getArg
} from "./utils"
import { ERC20Mock__factory, } from "./ethers-contracts"
import { deploy } from "./deploy"
import { deployMockToken } from "./deploy-mock-tokens"

async function main() {
  if (checkFlag("--sendRemoteDeposit")) {
    await sendRemoteDeposit()
    return
  }
  if (checkFlag("--deployHelloToken")) {
    await deploy()
    return
  }
  if (checkFlag("--deployMockToken")) {
    await deployMockToken()
    return
  }
}

async function sendRemoteDeposit() {
  // const from = Number(getArg(["--from", "-f"]))
  // const to = Number(getArg(["--to", "-t"]))
  // const amount = getArg(["--amount", "-a"])
  const recipient = getArg(["--recipient", "-r"]) || "";

  const from = 6
  const to = 14
  const amount = ethers.utils.parseEther("10")

  const helloToken = getHelloToken(from)
  const cost = await helloToken.quoteCrossChainDeposit(to)
  console.log(`cost: ${ethers.utils.formatEther(cost)}`)

  const HT = ERC20Mock__factory.connect(getDeployedAddresses().erc20s[from][0], getWallet(from));

  const rx = await helloToken
    .sendCrossChainDeposit(
      to,
      getHelloToken(to).address,
      recipient,
      amount,
      HT.address
    )
    .then(wait)
}

main().catch(e => {
  console.error(e)
  process.exit(1)
})
