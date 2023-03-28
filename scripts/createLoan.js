const hre = require("hardhat")
const hashLendingContract = "0x3e5af00ef71c9944427b1b8858da7342157e6326";

async function main()
{
    const contractFactory = await ethers.getContractFactory("DPSLendingUniswapLiquidity");
    const contract = await contractFactory.attach(hashLendingContract)

    var result = await contract.depositNFT(61318, "100000000000000000000000", 1680039049, "0x0Cb80b1c0E6AeBB031a7Ec26219ab162f0F9bC2B")
    console.log(result)
}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
});