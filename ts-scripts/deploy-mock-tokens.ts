import { ethers } from "ethers";
import { ERC20Mock__factory } from "./ethers-contracts";
import {
  loadDeployedAddresses,
  getWallet,
  wait,
  loadConfig,
  storeDeployedAddresses,
  getChain,
} from "./utils";
import {
  ChainId,
  attestFromEth,
  createWrappedOnEth,
  getSignedVAAWithRetry,
  parseSequenceFromLogEth,
  tryNativeToHexString,
} from "@certusone/wormhole-sdk";
import * as grpcWebNodeHttpTransport from "@improbable-eng/grpc-web-node-http-transport";
import { ChainInfo, getArg } from "./utils";

const sourceChain = loadConfig().sourceChain;
const targetChain = loadConfig().targetChain;

export async function deployMockToken() {
  const deployed = loadDeployedAddresses();
  const from = getChain(sourceChain);

  const signer = getWallet(from.chainId);
  const HT = await new ERC20Mock__factory(signer).deploy("HelloToken", "HT");
  await HT.deployed();
  console.log(`HT deployed to ${HT.address} on chain ${from.chainId}`);
  deployed.erc20s[sourceChain] = [HT.address];

  console.log("Minting...");
  await HT.mint(signer.address, ethers.utils.parseEther("10")).then(wait);
  console.log("Minted 10 HT to signer");

  console.log(
    `Attesting tokens with token bridge on chain(s) ${loadConfig()
      .chains.map((c) => c.chainId)
      .filter((c) => c === targetChain)
      .join(", ")}`
  );
  for (const chain of loadConfig().chains) {
    if (chain.chainId !== targetChain) {
      continue;
    }
    await attestWorkflow({
      from: getChain(sourceChain),
      to: chain,
      token: HT.address,
    });
  }

  storeDeployedAddresses(deployed);
}

async function attestWorkflow({
  to,
  from,
  token,
}: {
  to: ChainInfo;
  from: ChainInfo;
  token: string;
}) {
  const attestRx: ethers.ContractReceipt = await attestFromEth(
    from.tokenBridge!,
    getWallet(from.chainId),
    token
  );
  const seq = parseSequenceFromLogEth(attestRx, from.wormhole);

  const res = await getSignedVAAWithRetry(
    ["https://api.testnet.wormscan.io"],
    Number(from) as ChainId,
    tryNativeToHexString(from.tokenBridge, "ethereum"),
    seq.toString(),
    { transport: grpcWebNodeHttpTransport.NodeHttpTransport() }
  );
  const createWrappedRx = await createWrappedOnEth(
    to.tokenBridge,
    getWallet(to.chainId),
    res.vaaBytes
  );
  console.log(
    `Attested token from chain ${from.chainId} to chain ${to.chainId}`
  );
}
