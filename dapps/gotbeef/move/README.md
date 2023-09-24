# GotBeef Sui move package

## Dev setup
1. [Install Sui](https://docs.sui.io/build/install#install-sui-binaries)
```
cargo install --locked --git https://github.com/MystenLabs/sui.git --branch devnet sui sui-node
```
2. Connect to devnet:
```
sui client switch --env devnet
```

## How to run the unit tests
```
sui move test
```

Show test coverage:
```
sui move test --coverage && sui move coverage summary
sui move coverage source --module bet
sui move coverage bytecode --module bet
```

## How to publish the package
```
sui client publish --gas-budget 100000000 | grep packageId
```

## How to use from `sui console`

Note that to test the package it is better to write tests in a package.tests.move script. Then to redeploy and execute multiple commands in the console.

#### Create a bet
```
sui console```

```
call --package $PACKAGE_ID_LOCAL --module bet --function create --type-args 0x2::sui::SUI --args 'Bet title' 'Bet description' 1 7 '[$PLAYER1, $PLAYER2]' '[$JUDGE]' --gas-budget 10000000
```

#### Fund a bet
```
call --package $PACKAGE_ID_LOCAL --module bet --function fund --type-args 0x2::sui::SUI --args $BET_OBJECT_ID 'from sui console' '$COIN_OBJECT_ID' --gas-budget 10000000
```

