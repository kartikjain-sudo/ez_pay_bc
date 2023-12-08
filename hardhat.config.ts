import { HardhatUserConfig, task } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

import * as dotenv from "dotenv";
import "hardhat-gas-reporter";
import "solidity-coverage";
import "hardhat-contract-sizer";

dotenv.config();

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.22",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200, // Adjust the number of runs as needed
      },
    },
  },
  networks: {
    hardhat: {
      chainId: 1337,
      // gas: 30000000,
      blockGasLimit: 30000000,
    },
    // localhost: {
    //   url: "http://localhost:8545",
    //   // gas: 30000000,
    //   blockGasLimit: 30000000,
    // },
    localhost: {
      url: process.env.MOCK_MAINNET || "",
      gasPrice: 30000000000, // 30 gwei
      accounts:
        (process.env.PRIVATE_KEY !== undefined
          && process.env.PK2 !== undefined && process.env.PK3 !== undefined
          && process.env.PK4 !== undefined )? [process.env.PRIVATE_KEY, process.env.PK2, process.env.PK3, process.env.PK4] : [],
    },
    v4: {
      url: process.env.GOERLI_URL || "",
      gasPrice: 30000000000, // 30 gwei
      // gas: 10000000,
      blockGasLimit: 30000000,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    mainnet: {
      url: process.env.MAINNET_URL || "",
      // gasPrice: 1000000000,
      // gas: 10000000,
      blockGasLimit: 30000000,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
    gasPrice: 30,
    coinmarketcap: process.env.COINMARKETCAP_KEY,
    url: "http://localhost:8545",
  },
  etherscan: {
    apiKey: {
      goerli: process.env.ETHERSCAN_API_KEY || ""
    },
  },
  mocha: {
    timeout: 1000000000,
  },
};

export default config;
