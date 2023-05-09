require("@nomicfoundation/hardhat-toolbox");

const fs = require('fs');
var mnemonic = fs.readFileSync('./secrets.txt').toString();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.7.5",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    goerli: {
      url: "https://goerli.infura.io/v3/95ecc661cf1b431ea8f41e7fc21daaff",
      chainId: 5,
      //gasPrice: 20000000000,
      accounts: [`0x${mnemonic}`]
    },
  },
  etherscan: {
    apiKey: "4S69HVCPQY3A95HUEKU4QRVQBNKIC47NCR",
  }
};