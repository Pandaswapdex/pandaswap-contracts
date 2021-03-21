const Factory    = artifacts.require("contracts/uniswapv2/UniswapV2Factory.sol");
const Router     = artifacts.require("contracts/uniswapv2/UniswapV2Router02.sol");
const SushiToken = artifacts.require("contracts/BambooToken.sol");
const Sushibar   = artifacts.require("contracts/BambooBar.sol");
const Masterchef = artifacts.require("contracts/MasterChef.sol");
const Sushimaker = artifacts.require("contracts/BambooMaker.sol");



module.exports = async function(deployer, _network, addresses) {

  // pair token addresses
  const wbtc_mainnet = '';
  const eth_mainnet  = '';
  const avax_mainnet = '';
  const dai_mainnet  = '0xbA7dEebBFC5fA1100Fb055a87773e1E99Cd3507a';
  const comp_mainnet = '';
  const aave_mainnet = '';
  const png_mainnet  = '';
  const usdt_mainnet = '';
  const link_mainnet = '0xB3fe5374F67D7a22886A0eE082b2E2f9d2651651';
  
  // there's a better way with hd-truffle
  const [admin, _] = addresses;
  const wAVAX = '0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7';

  // deploy factory
  await deployer.deploy(Factory, admin);
  const factory = await Factory.deployed();
  
  // add initial pairs to the factory contract
  await factory.createPair(link_mainnet, dai_mainnet);
  
  // deploy router
  await deployer.deploy(Router, factory.address, wAVAX);
  const router = await Router.deployed();

  // deploy sushitoken
  await deployer.deploy(SushiToken);
  const sushiToken = await SushiToken.deployed();

  // deploy masterchef(_sushitoken, _devaddr, _rewardsPerBlock, _bonusStartBlock, _bonusEndBlock)
  await deployer.deploy(Masterchef, sushiToken.address, admin, web3.utils.toWei('100'), 1, 1 );
  const masterChef = await Masterchef.deployed();

  // transfer ownership of sushitoken to masterchef
  await sushiToken.transferOwnership(masterChef.address);

  // deploy sushibar
  await deployer.deploy(Sushibar, sushiToken.address);
  const sushiBar = await Sushibar.deployed();

  // deploy sushimaker
  await deployer.deploy(Sushimaker, factory.address, sushiBar.address, sushiToken.address, wAVAX);
  const sushiMaker = await Sushimaker.deployed();
  
  // allocate the uniswap factory contracts dev fee to the sushimaker 
  // address, so that it can sell for sushi to pay stakers
  await factory.setFeeTo(sushiMaker.address);

};