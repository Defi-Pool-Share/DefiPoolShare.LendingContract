const hre = require("hardhat");

async function main() {
  const DPSLendingUniswapLiquidity = await hre.ethers.getContractFactory("DPSLendingUniswapLiquidity");
  
  console.log('Deploying...');
  const contract = await DPSLendingUniswapLiquidity.deploy('0xC36442b4a4522E871399CD717aBDD847Ab11FE88');

  await contract.deployed();

  console.log('Deployed Defi pool share Uniswap v3 liquidity contract');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});