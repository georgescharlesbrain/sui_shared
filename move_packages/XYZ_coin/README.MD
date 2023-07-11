
# XYZ coin

## Description

This package is an example of how to use the coin module to create the coin XYZ.
The packages provides functionality to mint and burn the coin.

Based on the [sui-coins example by Move Studio](https://www.youtube.com/watch?v=6-yaql5cGS8&ab_channel=MoveStudioIDE)[code](https://github.com/MoveStudioIDE/get-movin/tree/main/sui-coins)
and expanded upon.

## local deploy notes

[url local RPC node](http://0.0.0.0:9000)

Transaction Block:

Created owned objects:  
TreasuryCap object  
upgrade cap object  

Created shared objects:  
CoinMetadata object  
package object  

references between objects on the Sui explorer:  
from object X you can lookup object Y  
package object --> coin objects  
upgrade cap object --> package object  
coin objects are created in a transaction from the package object and can be found in the transaction digests of the package object

How to find the CoinMetaData object from a coin object?  
coin object --> package object --> see first transaction to find the CoinMetadata object

## next steps

Add more features to the coin
check interest-protocol repo
check other coin implementations
testing?
generate a basic SDK using KuraLabs or kklas tool
