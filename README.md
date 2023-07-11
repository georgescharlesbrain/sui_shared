# sui_shared repo

This repo contains shared code created during my sui research.

## sui_shared folder structure

### move_packages

Contains move packages which can be tutorials, examples or custom-made move packages.
Every package should have a README explaining the source of the code and the purpose of the package.

#### Sui foundation and Mysten Labs move repos with example code

- [sui_programmability/examples](https://github.com/MystenLabs/sui/tree/main/sui_programmability/examples) (MystenLabs examples)
- [sui-framework usage](https://github.com/MystenLabs/sui/tree/main/crates/sui-framework) (MystenLabs core sui move packages)
  - sui-system (staking, storage fund, validators, genesis, ...)
  - sui-framework (core on-chain libraries)
  - move-stdlib (standard move which is extended by the sui-framework into sui move)
  - deepbook (CLOB)
- [kiosk](https://github.com/MystenLabs/sui/tree/devnet/crates/sui-framework/packages/sui-framework/sources/kiosk) (MystenLabs - Kiosk is a primitive for building open, zero-fee trading platforms with a high degree of customization over transfer policies.)
- [sui foundation - sui move intro course](https://github.com/sui-foundation/sui-move-intro-course)

#### Dapp repos

- [Interest Protocol](https://github.com/interest-protocol)
- [Scallop](https://github.com/scallop-io)
- [Bucket Protocol](https://github.com/BucketProtocol)
- [Movernance](https://github.com/movernance)