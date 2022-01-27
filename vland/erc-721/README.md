# Vland ERC-721 Contracts

Managing NFTs that represent lands, on which there may be (linked) other NFTs that represent other assets such as buildings, mines, roads, rivers, etc.

There are 2 main contracts:
- [Land.sol](contracts/Land.sol): handle lands nfts
- [Building.sol](contracts/Building.sol): for asset nfts, in this case building nfts

Both contracts inherits functions from [`BaseAsset.sol`](contracts/BaseAsset.sol) that has a responsibility to handle: token metadata, [geohashes](https://en.wikipedia.org/wiki/Geohash) and base common functionalities. 

The uniqueness of each token are represented by geohashes in order to map real world assets coordinates to the token in user friendly way and archive some more uniqueness for tokens on chain.

A `land` nft could have associated `assets`, in this case for a newly created land we could add many unique buildings.

Main contracts functions are:
- create land nfts
- create buildings nfts
- set a price for each land 
- set a price for each building 
- add buildings to the land
- buy a single land
- buy a land with buildings
- buy a single building

Patterns and libraries:
- [Access Restriction](https://fravoll.github.io/solidity-patterns/access_restriction.html) with [Ownable by OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol)
- [ERC-721](https://eips.ethereum.org/EIPS/eip-721) Token Standard with [Open Zeppelin ERC721](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol)
- [Counters](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol) by Open Zeppelin
- [SafeMath](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol) by Open Zeppelin


# Getting Started
```shell
npm install
```
### Compile contracts:
```shell
npm run compile
```
### Run tests:
> Note: sometime you need to run the command twice (if receive imports error) because for some reason VS not refreshing dependencies at first time
```shell
npm run test
# test coverage
npm run coverage
```
### Deploy contracts locally
1. Start local blockchain:
```shell
npm run chain
```

2. Deploy contracts:
```shell
npm run deploy:local
```
### Deploy contracts to rinkeby
1. Make sure to properly configure `.env` file
2. Deploy contracts and verify:
```shell
npm run deploy:rinkeby
# verify target contract
npx hardhat verify ",CONTRACT ADDRESS" --network rinkeby
```
### Linting
```shell
npm run lint
npm run lint:fix
```
### Clean artifacts
```shell
npm run clean
```