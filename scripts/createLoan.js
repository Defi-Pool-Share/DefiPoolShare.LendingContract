const hre = require("hardhat")
const hashLendingContract = "0xc489d8e101C8cF201C4b21e1340264b0b51d3B95";

async function main()
{
    const contractFactory = await ethers.getContractFactory("DPSLendingUniswapLiquidity");
    const contract = await contractFactory.attach(hashLendingContract)
    var result = await contract.depositNFT(61915, "1000000000000000000000", 1681405165, "0x0Cb80b1c0E6AeBB031a7Ec26219ab162f0F9bC2B")
    console.log(result)
}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
});