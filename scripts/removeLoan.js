const hre = require("hardhat")
const hashLendingContract = "0xe6b6007d2f66fD85D9ac712a04d3Aa0f654F9bBC";

async function main()
{
    const contractFactory = await ethers.getContractFactory("DPSLendingUniswapLiquidity");
    const contract = await contractFactory.attach(hashLendingContract)
    var result = await contract.withdrawNFT(0)
    console.log(result)
}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
});