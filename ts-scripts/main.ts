import * as ethers from "ethers";
import * as dotenv from "dotenv";
import {
  checkFlag,
  getHelloToken,
  wait,
  getArg,
  loadDeployedAddresses as getDeployedAddresses,
} from "./utils";
import { ERC20Mock__factory } from "./ethers-contracts";
import { deploy } from "./deploy";
import { deployMockToken } from "./deploy-mock-tokens";

// Load environment variables from .env file
dotenv.config();

async function main() {
  if (checkFlag("--sendRemoteDeposit")) {
    await sendRemoteDeposit();
    return;
  }
  if (checkFlag("--deployHelloToken")) {
    await deploy();
    return;
  }
  if (checkFlag("--deployMockToken")) {
    await deployMockToken();
    return;
  }
}

async function sendRemoteDeposit() {
  // const from = Number(getArg(["--from", "-f"]))
  // const to = Number(getArg(["--to", "-t"]))
  // const amount = getArg(["--amount", "-a"])
  const recipient = getArg(["--recipient", "-r"]) || "";

  const from = 6;
  const to = 16;
  const amount = ethers.utils.parseEther("10");

  // Access the private key from the .env file
  const privateKey = process.env.EVM_PRIVATE_KEY;
  if (!privateKey) {
    throw new Error("EVM_PRIVATE_KEY is not defined in the .env file.");
  }
  // Create a wallet with the private key
  const wallet = new ethers.Wallet(privateKey);

  const helloToken = getHelloToken(from);
  const cost = await helloToken.quoteCrossChainDeposit(to);
  console.log(`cost: ${ethers.utils.formatEther(cost)}`);

  const HT = ERC20Mock__factory.connect(
    getDeployedAddresses().erc20s[from][0],
    wallet
  );

  const rx = await helloToken
    .sendCrossChainDeposit(
      to,
      getHelloToken(to).address,
      recipient,
      amount,
      HT.address
    )
    .then(wait);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
