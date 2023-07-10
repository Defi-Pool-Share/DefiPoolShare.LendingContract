const hre = require("hardhat");

async function main() {
  const DPSLendingUniswapLiquidity = await hre.ethers.getContractFactory("DPSLendingUniswapLiquidity");
  
  console.log('Deploying...');
  const contract = await DPSLendingUniswapLiquidity.deploy('0xC36442b4a4522E871399CD717aBDD847Ab11FE88', "0x922b7A7a009bE41334E4317952dE675F49E3D0ad", 1);

  await contract.deployed();

  console.log('Deployed Defi pool share Uniswap v3 liquidity contract');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});