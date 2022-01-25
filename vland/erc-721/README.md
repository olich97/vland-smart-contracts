# Vland ERC-721 Contracts

Managing NFTs that represent lands, on which there may be (linked) other NFTs that represent other assets such as buildings, mines, roads, rivers, etc.



Description goes here ...
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