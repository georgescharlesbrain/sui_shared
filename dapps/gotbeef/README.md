# Got Beef?

A [Sui](https://sui.io/) dapp to create on-chain bets. It comes with a built-in escrow and voting functionality.

The move code is rewritten from scratch from the [gotbeef](https://github.com/juzybits/polymedia-gotbeef) project.

- Anybody can create a new bet between 2 or more players.
- The winner is selected by a single judge, or by a quorum of judges.
- Funds can only be transferred to the winner, or refunded back to the players.

## Limitations:

- Multiple players can participate in the bet, but each of them need there own distinct answer/statement.
- Judges vote on players, not on answers. This has the consequence there can be only one winner who reaches quorum first.
  It is a winner takes all bet system, the price money is never split.
- Currently there are no possibilities to cancel a bet during the voting phase.
  If judges don't show up to vote the bet funds can get locked in.

See move code for open "TODO" items.

See private notion page for extra notes.
