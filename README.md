# NEST-Oracle-V3.6
The NEST Oracle Smart Contract 3.6 is a solidity smart contract implementation of NEST Protocol which provide a unique on-chain Price Oracle through a decentralized mechanism.

![](https://img.shields.io/github/issues/NEST-Protocol/NEST-Oracle-V3.6)
![](https://img.shields.io/github/stars/NEST-Protocol/NEST-Oracle-V3.6)
![](https://img.shields.io/github/license/NEST-Protocol/NEST-Oracle-V3.6)
![](https://img.shields.io/twitter/url?url=https%3A%2F%2Fgithub.com%2FNEST-Protocol%2FNEST-Oracle-V3.6%2F)

## Whitepaper

**[https://nestprotocol.org/doc/ennestwhitepaper.pdf](https://nestprotocol.org/doc/ennestwhitepaper.pdf)**

## Documents

**[NEST V3.6 Contract Specification](docs/readme.md)**

**[NEST V3.6 Contract Structure Diagram](docs/nest36-contracts.svg)**

**[NEST V3.6 Application Scenarios](docs/readme.md#5-application-scenarios)**

**[Audit Report](docs/PeckShield-Audit-Report-NestV3.6.pdf)**

**[Learn More...](https://nestprotocol.org/)**

## Usage

### Run test

```shell
npm install

truffle test
```

### Compile

Run `truffle compile`, get build results in `build/contracts` folder, including `ABI` json files.

### Deploy

Deploy with `truffle` and you will get a contract deployement summary on contract addresses.

```shell
truffle migrate --network ropsten
```

## Contract Addresses

### 2021-04-27@mainnet
| Name | Interfaces | mainnet |
| ---- | ---- | ---- |
| nest | IERC20 | 0x04abEdA201850aC0124161F037Efd70c74ddC74C |
| nn | IERC20 | 0xC028E81e11F374f7c1A3bE6b8D2a815fa3E96E6e |
| nestGovernance | INestGovernance | 0xA2eFe217eD1E56C743aeEe1257914104Cf523cf5 |
| nestLedger | INestLedger | 0x34B931C7e5Dc45dDc9098A1f588A0EA0dA45025D |
| nestMining | INestMining, INestQuery | 0x03dF236EaCfCEf4457Ff7d6B88E8f00823014bcd |
| ntokenMining | INestMining, INestQuery | 0xC2058Dd4D55Ae1F3e1b0744Bdb69386c9fD902CA |
| nestPriceFacade | INestPriceFacade, INestQuery | 0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A |
| nestRedeeming | INestRedeeming | 0xF48D58649dDb13E6e29e03059Ea518741169ceC8 |
| nestVote | INestVote | 0xDa52f53a5bE4cb876DE79DcfF16F34B95e2D38e9 |
| nnIncome | INNIncome | 0x95557DE67444B556FE6ff8D7939316DA0Aa340B2 |
| nTokenController | INTokenController | 0xc4f1690eCe0145ed544f0aee0E2Fa886DFD66B62 |

### 2021-04-06@rinkeby
| Name | Interfaces | rinkeby |
| ---- | ---- | ---- |
| hbtc | IERC20 | 0x52e669eb87fBF69027190a0ffb6e6fEd48451E04 |
| usdt | IERC20 | 0xBa2064BbD49454517A9dBba39005bf46d31971f8 |
| nest | IERC20 | 0x3145AF0F18759D7587F22278d965Cdf7e19d6437 |
| nhbtc | IERC20 | 0x7A4DAca8f91c94479A6F8DD00D4bBABCa1Ac174d |
| nn | IERC20 | 0x8f89663562dDD4519566e590C18ec892134A0cdD |
| nestGovernance | INestGovernance | 0x74487D1a0FB2a70bb67e7D6c154d2ac71954a313 |
| nestLedger | INestLedger | 0x82502A8f52BF186907BD0E12c8cEe612b4C203d1 |
| nestMining | INestMining, INestQuery | 0xf94Af5800A4104aDEab67b3f5AA7A3a6E5bC64c3 |
| ntokenMining | INestMining, INestQuery | 0x0684746A347033436E77030a43891Ea4FDaBb78E |
| nestPriceFacade | INestPriceFacade, INestQuery | 0x97F09D58a87B9a6f0cA1E69aCef77da3EFF8da0A |
| nestRedeeming | INestRedeeming | 0xC545b531e1A093E33ec7058b70E74eD3aD113a2A |
| nestVote | INestVote | 0xD2BD52C52c0C2A220Ce2750e41Bc09b84526f26E |
| nnIncome | INNIncome | 0xD5A32f6de0997749cb6F2F5B6042e2f878688aE2 |
| nTokenController | INTokenController | 0x57513Fc3133C7A4a930c345AB3aA9a4D21600Db9 |
| NestStaking35 | --- | 0x5BC253b9fE40d92f8a01e62899A77ae124F68C5a |

### 2021-04-04@rinkeby
| Name | Interfaces | rinkeby |
| ---- | ---- | ---- |
| hbtc | IERC20 | 0x52e669eb87fBF69027190a0ffb6e6fEd48451E04 |
| usdt | IERC20 | 0xBa2064BbD49454517A9dBba39005bf46d31971f8 |
| nest | IERC20 | 0x3145AF0F18759D7587F22278d965Cdf7e19d6437 |
| nhbtc | IERC20 | 0x4269Fee5d9aAC83F1A9a81Cd17Bf71A01240765a |
| nn | IERC20 | 0xF6298cc65E84F6a6D67Fa2890fbD2AD8735e3c29 |
| nestGovernance | INestGovernance | 0x8a4fD519CEcFA7eCE7B4a204Dbb4b781B397C460 |
| nestLedger | INestLedger | 0x4397F20d20b5B89131b631c43AdE98Baf3A6dc9F |
| nestMining | INestMining, INestQuery | 0x4218e20Cdc77172972E40B9B56400E6ffe680724 |
| ntokenMining | INestMining, INestQuery | 0x13742076bc96950cAfF0d0EfE64ebE818018121B |
| nestPriceFacade | INestPriceFacade | 0xCAc72395a6EaC6D0D06C8B303e26cC0Bfb5De33c |
| nestRedeeming | INestRedeeming | 0xf453E3c1733f4634210ce15cd2A4fAfb191c36A5 |
| nestVote | INestVote | 0x6B9C63a52533CB9b653B468f72fD751E0f2bc181 |
| nnIncome | NNIncome | 0xAc88d1fBF58E2646E0F4FF60aa436a70753885D9 |
| nTokenController | INTokenController | 0xF0737e3C98f1Ee41251681e2C6ad53Ab92AB0AEa |
| NestStaking35 | --- | 0x5BC253b9fE40d92f8a01e62899A77ae124F68C5a |
