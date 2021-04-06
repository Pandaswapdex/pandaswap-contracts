// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const BigNumber = require('bignumber.js')

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile 
  // manually to make sure everything is compiled
  // await hre.run('compile');

  const WAVAX_FUJI = "0xd00ae08403B9bbb9124bB305C09058E32C39A48c"
  const WAVAX_MAINNET = "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7"

  // We get the contract to deploy
  const [deployer] = await ethers.getSigners()
  console.log(`Deploying contracts with the account: ${deployer.address}`)

  const balance = await deployer.getBalance()
  console.log(`Account balance: ${ethers.utils.formatUnits(balance, 'ether')}`)

  const UniswapV2Factory = await hre.ethers.getContractFactory("UniswapV2Factory")
  const uniswapV2Factory = await UniswapV2Factory.deploy(deployer.address)
  const pairCodeHash = await uniswapV2Factory.pairCodeHash()
  console.log(`UniswapV2Factory pair code hash is: ${pairCodeHash}`)

  const BambooTokenV2 = await hre.ethers.getContractFactory('BambooTokenV2')
  const bambooTokenV2 = await BambooTokenV2.deploy(ethers.utils.parseUnits('250000000', 'ether'))
  const bambooTokenV2Cap = await bambooTokenV2.cap()
  console.log(`BambooTokenV2 cap is: ${bambooTokenV2Cap}`)

  const MasterChefV2 = await hre.ethers.getContractFactory('MasterChefV2')
  const masterChefV2  =await MasterChefV2.deploy(
                                bambooTokenV2.address,
                                deployer.address,
                                deployer.address,
                                deployer.address,
                                deployer.address,
                                deployer.address,
                                deployer.address,
                                100,
                                800000,
                                905000
                            )
  console.log(`MasterChefV2 deployed to address: ${masterChefV2.address}`)
  
  const ShitToken = await hre.ethers.getContractFactory('ShitToken')
  const shitToken = await ShitToken.deploy()
  console.log(`ShitToken deployed to address: ${shitToken.address}`)

  const FuckToken = await hre.ethers.getContractFactory('FuckToken')
  const fuckToken = await FuckToken.deploy()
  console.log(`FuckToken delpoyed to address: ${fuckToken.address}`)

  const UniswapV2Router02 = await hre.ethers.getContractFactory('UniswapV2Router02')
  const uniswapV2Router02 = await UniswapV2Router02.deploy(
                                    uniswapV2Factory.address, 
                                    WAVAX_FUJI,
                                  )
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
