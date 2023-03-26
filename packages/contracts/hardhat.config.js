require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-etherscan")
require("hardhat-deploy")
require("solidity-coverage")
require("hardhat-gas-reporter")
require("hardhat-contract-sizer")
require("dotenv").config()

const MUMBAI_RPC_URL = process.env.MUMBAI_RPC_URL
const PRIVATE_KEY = process.env.PRIVATE_KEY
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: {
    polygon: {
      url: MUMBAI_RPC_URL,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
  },
  solidity: "0.8.17",
};
