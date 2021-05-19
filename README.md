# WstethZap

Built for [OpenDefi Lido Challenge](https://gitcoin.co/issue/lidofinance/lido-dao/343/100025668)

It is an interface on top Wsteth/Eth Uniswap V3 pool, to swap steth for eth or vice versa.

Underneath it does wrapping if eth is being bought for steth, and unwrapping if steth is being bought for eth

# Kovan Testing

Token and Contracts address used in testing on Kovan

WstethZap : https://kovan.etherscan.io/address/0xe648bfc8975346ac6d71bccba550629026715122

Uniswap V3 pool for Wsteth and Eth : https://kovan.etherscan.io/address/0x579f24b20a237c7544b1ed7468e606ba5fb893cd

Wsteth : https://kovan.etherscan.io/address/0x387e56c0574a05f480e1ee0fa00af28b19076392

stEth: https://kovan.etherscan.io/address/0x6a105135581398fbbd837e8dba5e40b88fd0a5a4

Transaction 1: Swap stEth for Eth at https://kovan.etherscan.io/tx/0x873853c11328f0e510b467a1b7d22dc1b36620d7ad55a49286337de49d26f311
 
1.1 stEth was swapped for 1.09 Eth

Transaction 2: Swap Eth for stEth at https://kovan.etherscan.io/tx/0xcf45e32b1f05da3f9417987d0664357a47065a57b79d4489593f39ea611f13ca

1 Eth was swapped for 1.0019 stEth

# Instructions

Set Infura Key in terminal

`export INFURA_KEY=xxxxxxx`

Add your private key in .secret

To compile and deploy

`npm install`

`truffle compile --all`

`npx truffle migrate --network kovan`

I have already hard coded addresses for Uniswap pool, wstEth and weth in contract.

When deploying on mainnet, make sure to change addresses accordingly before deploying
