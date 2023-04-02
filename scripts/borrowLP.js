const hre = require("hardhat")
const hashLendingContract = "0xe6b6007d2f66fD85D9ac712a04d3Aa0f654F9bBC";
const paymentTokenHash = "0x0Cb80b1c0E6AeBB031a7Ec26219ab162f0F9bC2B";
const IERC20_SOURCE = "./IERC20.sol";

async function main()
{
    const contractFactory = await ethers.getContractFactory("DPSLendingUniswapLiquidity");
    const contract = await contractFactory.attach(hashLendingContract)
    
    // const erc20Contract = await ethers.getContractAt('IERC20', paymentTokenHash);
    // const approveTx = await erc20Contract.approve(hashLendingContract, "10000000000000000000000000000");
    // if (approveTx) {
    //     var result = await contract.borrowNFT(0)
    //     console.log(result)
    // }
    
    var result = await contract.borrowNFT(0)
    console.log(result)
}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
});