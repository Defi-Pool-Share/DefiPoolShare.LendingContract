const hre = require("hardhat")
const hashLendingContract = "0xe6b6007d2f66fD85D9ac712a04d3Aa0f654F9bBC";

async function main()
{
    const contractFactory = await ethers.getContractFactory("DPSLendingUniswapLiquidity");
    const contract = await contractFactory.attach(hashLendingContract)
    var result = await contract.depositNFT(61915, "1000000000000000000000", 1680476412, "0x0Cb80b1c0E6AeBB031a7Ec26219ab162f0F9bC2B")
    console.log(result)
}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
});