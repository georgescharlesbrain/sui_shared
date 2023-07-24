
# notes for examples.sui.io

Tests and notes for [examples.sui.io](https://examples.sui.io) by MystenLabs [github sub-folder](https://github.com/MystenLabs/sui/tree/main/doc/book).
Notes, questions and highlights are added to the website using the [hypothesis browser extension](https://hypothes.is/search?q=https%3A%2F%2Fexamples.sui.io%2F).

Some parts are examples of the usage of specific sui framework modules. It can be useful to have a look at the documentation and implementation of the sui framework modules. The sui framework modules can be found [here](https://github.com/MystenLabs/sui/tree/main/crates/sui-framework/packages/sui-framework/sources)

## Sui Basics

### Entry functions

visibility modifiers for functions:
entry --> callable directly from transactions (but not from other modules), not allowed to have return values
public --> callable from other modules, allowed to have return values
friend --> callable from friends, that is modules listed up in the friends list in the code

init <> entry, the init function of a module is executed only once when the module is published, it is not callable from transactions
and init is not a visibility modifier its a name of a function

### Strings

Get the String type from the std library.
Using an URL is still handled in a different way than a string. See XYZ_COIN.

### Shared Object

Good example, uses many features.
See hypothesis for notes on the code.

### Transfer

See hypothesis for notes on the code.

### Custom transfer

See hypothesis for notes on the code.

### Events

### One Time Witness

a struct
named after the module but upper cased
only has the drop ability
added as the first argument to the init() function of a module

### Publisher

publisher is a utility object

see also sui::package module

### Object Display

See hypothesis for notes on the code.

## Patterns

### Capability

A Capability/Cap is a pattern that allows authorizing actions with an object. The above mentioned "publisher" object is an example of a capability object it gives the capability to proof the ownership of a package/module.

### Witness

What's the difference between a witness and a OTW?

### Transferable Witness

### Hot Potato

A Hot Potato is a struct that has no abilities, hence it can only be packed and unpacked in its module. This is useful in eg. flash loans. If you want a flash loan from me (without collateral) I need to make sure you will give me the loan back. By giving you a hot potato (which only I will accept back) I'm sure you'll have to come back to give me the loan and hot potato back.

### ID Pointer

ID Pointer is a technique that separates the main data (an object) and its accessors / capabilities by linking the latter to the original. eg. issuing transferable capabilities for shared objects

## Samples

### Make an NFT

also have a look at kiosk

### Create a Coin

see [XYZ_coin](../XYZ_coin/README.MD) for a more elaborate example.
