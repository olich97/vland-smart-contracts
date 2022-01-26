# Vland ERC-721 Contracts

Managing NFTs that represent lands, on which there may be (linked) other NFTs that represent other assets such as buildings, mines, roads, rivers, etc.

There are 2 main contracts:
- [Land.sol](contracts/Land.sol): handle lands nfts
- [Building.sol](contracts/Building.sol): for asset nfts, in this case building nfts

Both contracts inherits functions from [`BaseAsset.sol`](contracts/BaseAsset.sol) that has a responsibility to handle: token metadata, [geohashes](https://en.wikipedia.org/wiki/Geohash) and base common functionalities. 

The uniqueness of each token are represented by geohashes in order to map real world assets coordinates to the token in user friendly way and archive some more uniqueness for tokens on chain.

`Building.sol` contract inherits from [`ChildAsset.sol`](contracts/ChildAsset.sol) that contains function for handling a link with main land contract.

The `building` contract is linked to the `land` contract (one to one) and a Land contract store an array of addresses of contracts associated to single land nft (one to many from land side).

A `land` nft could have some associated `assets`, in this case for a newly created land we could add many unique building.
Even from `building` contract there is a possibility to associate a `land` (while minting a new building or after): the building contract communicate to the land contract a created or existing nft.

In few words main functions are:
- create land nfts
- add buildings to the land nft
- buy single land: if a land has buildings inside when only a land should be sell and buildings disassociated from land
- buy land with buildings
- buy single building: if building is inside a land when should be removed from it (because it was sell and transfered to another user)

# TO DO
- Add Tests Land: asset workflow
- Add Land and Asset buy functions (+ Tests and remove communications)
- Deploy and test in local chain
- Deploy and test in ropsten chain

# Getting Started

### Compile contracts:
```shell
npm run compile
```
### Run tests:
> Note: sometime you need to run the command twice (if receive imports error) because for some reason VS not refreshing dependencies at first time
```shell
npm run test
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
2. Deploy contracts:
```shell
npm run deploy:rinkeby
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