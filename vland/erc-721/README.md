# Vland ERC-721 Contracts

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