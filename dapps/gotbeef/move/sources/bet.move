/* 
See projects README.md for more information
*/

#[allow(unused_const, unused_use, unused_type_parameter)]
module gotbeef::bet {
    /* Imports */
    use std::option::{Self, Option};
    use std::string::{String, utf8};
    use std::vector;
    use std::debug;
    // debug::print(&title_len);

    use sui::coin::{Self, Coin};
    use sui::display;
    use sui::package;
    use sui::event;
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::vec_map::{Self, VecMap};

    use gotbeef::vectors;
    use gotbeef::vec_maps;
    use gotbeef::transfers;

    /* Errors */
    // see above each function

    /* Settings */

    // create() constraints
    const MINIMUM_PLAYERS: u64 = 2;
    const MAXIMUM_PLAYERS: u64 = 64;
    const MINIMUM_JUDGES: u64 = 1;
    const MAXIMUM_JUDGES: u64 = 32;


    // Bet.phase possible values
    const PHASE_FUND: u8 = 0;       // The bet is created, we are waiting for the players funds/deposits.
    const PHASE_VOTE: u8 = 1;       // The players have funded the bet, we wait for the votes of the judges (which can only be given if the bet event has passed).
    const PHASE_SETTLED: u8 = 2;    // end phase | The bet is settled, funds are send to the winner.
    const PHASE_CANCELED: u8 = 3;   // end phase | The bet is canceled, funds are returned to the players.
    const PHASE_STALEMATE: u8 = 4;  // end phase | There are not enough votes left for any player to reach the quorum to win. Funds have been returned.


    /* Struct definitions */

    struct Bet<phantom T> has key, store
    {
        id: UID,
        phase: u8, // A bet goes through various stages: funding/voting/settled/...
        title: String,
        description: String,
        quorum: u64, // a majority of votes
        size: u64, // Amount of Coin<T> that each player will bet
        players: vector<address>,
        judges: vector<address>,
        votes: VecMap<address, address>, // <judge_addr,  player_addr>
        funds: VecMap<address, Coin<T>>, // <player_addr, player_funds>
        answers: VecMap<address, String>, // <player_addr, player_answer>
        most_votes: u64, // number of votes received by the leading player (to detect stalemates)
        winner: Option<address>,
        cancel_requests: vector<address>

        // start_epoch: Option<u64>, // (maybe) voting starts on this day
        // end_epoch: Option<u64>, // (maybe) voting ends on this day
        // funds: vector<Item>, // (maybe) prize can be any asset(s)
    }

    /* Event definitions */
    struct CreateBetEvent has copy, drop {
        bet_id: ID,
        bet_title: String,
    }


    /* Module initializer, executed when this module is published */

    // fun init(ctx: &mut TxContext) {

    // }


    /* Accessors required to read the struct attributes */

    public fun phase<T>(bet: &Bet<T>): u8 {
        bet.phase
    }
    public fun title<T>(bet: &Bet<T>): &String {
        &bet.title
    }
    public fun description<T>(bet: &Bet<T>): &String {
        &bet.description
    }
    public fun quorum<T>(bet: &Bet<T>): u64 {
        bet.quorum
    }
    public fun size<T>(bet: &Bet<T>): u64 {
        bet.size
    }
    public fun players<T>(bet: &Bet<T>): &vector<address> {
        &bet.players
    }
    public fun judges<T>(bet: &Bet<T>): &vector<address> {
        &bet.judges
    }
    public fun votes<T>(bet: &Bet<T>): &VecMap<address, address> {
        &bet.votes
    }
    public fun funds<T>(bet: &Bet<T>): &VecMap<address, Coin<T>> {
        &bet.funds
    }
    public fun most_votes<T>(bet: &Bet<T>): u64 {
        bet.most_votes
    }
    public fun winner<T>(bet: &Bet<T>): &Option<address> {
        &bet.winner
    }
    public fun cancel_requests<T>(bet: &Bet<T>): &vector<address> {
        &bet.cancel_requests
    }
    

    /* Public/entry functions */

    // errors create()
    const E_JUDGES_CANT_BE_PLAYERS: u64 = 0;
    const E_INVALID_NUMBER_OF_JUDGES: u64 = 1;
    const E_INVALID_NUMBER_OF_PLAYERS: u64 = 2;
    const E_QUORUM_NUMBER_OF_JUDGES_MISMATCH: u64 = 3;
    const E_MISSING_TITLE: u64 = 4;
    const E_DUPLICATE_PLAYERS: u64 = 5;
    const E_DUPLICATE_JUDGES: u64 = 6;
    const E_ZERO_BET_SIZE: u64 = 7;

    public entry fun create<T>(
        title: vector<u8>,
        description: vector<u8>,
        quorum: u64,
        size: u64,
        players: vector<address>,
        judges: vector<address>,
        ctx: &mut TxContext)
    {
        // check the input parameters
        let judges_len = vector::length(&judges);
        let players_len = vector::length(&players);
        let title_len = vector::length(&title);
        
        assert!(!vectors::intersect(&players, &judges), E_JUDGES_CANT_BE_PLAYERS);
        assert!(judges_len >= MINIMUM_JUDGES, E_INVALID_NUMBER_OF_JUDGES);
        assert!(judges_len <= MAXIMUM_JUDGES, E_INVALID_NUMBER_OF_JUDGES);
        assert!(players_len >= MINIMUM_PLAYERS, E_INVALID_NUMBER_OF_PLAYERS);
        assert!(players_len <= MAXIMUM_PLAYERS, E_INVALID_NUMBER_OF_PLAYERS);
        assert!(title_len>0, E_MISSING_TITLE);
        assert!(size>0, E_ZERO_BET_SIZE);
        assert!(quorum <= judges_len, E_QUORUM_NUMBER_OF_JUDGES_MISMATCH);
        assert!(!vectors::has_duplicates(&players), E_DUPLICATE_PLAYERS);
        assert!(!vectors::has_duplicates(&judges), E_DUPLICATE_JUDGES);
        
        let bet = Bet<T> {
            id: object::new(ctx),
            phase: PHASE_FUND,
            title: utf8(title),
            description: utf8(description),
            quorum: quorum,
            size: size,
            players: players,
            judges: judges,
            votes: vec_map::empty(),
            funds: vec_map::empty(),
            answers: vec_map::empty(),
            most_votes: 0,
            winner: option::none(),
            cancel_requests: vector::empty(),

        };

        event::emit(CreateBetEvent {
            bet_id: object::uid_to_inner(&bet.id),
            bet_title: bet.title,
        });

        transfer::share_object(bet);
    }

    // funding phase
    // errors fund()
    const E_ONLY_PLAYERS_CAN_FUND: u64 = 100;
    const E_WRONG_BET_SIZE: u64 = 101;
    const E_NOT_IN_FUNDING_PHASE: u64 = 102;
    const E_PLAYER_ALREADY_DEPOSITED: u64 = 103;

    public entry fun fund<T>(
        bet: &mut Bet<T>,
        answer: vector<u8>,  //TODO Why not just String?
        deposit: Coin<T>,
        ctx: &mut TxContext
    ){
        let player_addr = tx_context::sender(ctx);
        
        // Checks
        assert!(bet.phase == PHASE_FUND, E_NOT_IN_FUNDING_PHASE);
        // best practice: a user should send the exact amount (see PTB advice by Alex from Mysten)
        assert!(coin::value(&deposit) == bet.size, E_WRONG_BET_SIZE);
        assert!(vector::contains(&bet.players, &player_addr), E_ONLY_PLAYERS_CAN_FUND);
        assert!(!vec_map::contains(&bet.funds, &player_addr), E_PLAYER_ALREADY_DEPOSITED);  
        // assert! --> ! is a macro <> !vec_map --> ! is a negation


        // add deposit
        vec_map::insert(&mut bet.funds, player_addr, deposit);

        // add answer
        vec_map::insert(&mut bet.answers, player_addr, utf8(answer));

        // Transition to the voting phase if all players made their deposits
        if (vec_map::size(&bet.funds) == vector::length(&bet.players)) {
            bet.phase = PHASE_VOTE;
        };

    }

    // phase 3
    // a judge votes for a player not for an answer which is kind off odd
    // This means only one player can win?

    // errors vote()
    const E_NOT_IN_VOTING_PHASE: u64 = 201;
    const E_ONLY_JUDGES_CAN_VOTE: u64 = 202;
    const E_ALREADY_VOTED: u64 = 203;
    const E_PLAYER_NOT_FOUND: u64 = 204; 

    public entry fun vote<T>(
        bet: &mut Bet<T>,
        player_addr: address, // a judge votes on a player not on an answer  
        ctx: &mut TxContext
    ){
        let judge_addr = tx_context::sender(ctx);

        // checks
        assert!( bet.phase == PHASE_VOTE, E_NOT_IN_VOTING_PHASE );
        assert!( vector::contains(&bet.judges, &judge_addr), E_ONLY_JUDGES_CAN_VOTE );
        assert!( !vec_map::contains(&bet.votes, &judge_addr), E_ALREADY_VOTED );
        assert!( vector::contains(&bet.players, &player_addr), E_PLAYER_NOT_FOUND );

        // add the vote
        vec_map::insert(&mut bet.votes, judge_addr, player_addr);
        let player_vote_count = vec_maps::count_value(&bet.votes, &player_addr);

        // track progress towards quorum, so we can calculate a distance_to_win
        if ( player_vote_count > bet.most_votes ) {
            bet.most_votes = player_vote_count;
        };

        // If the player that just received a vote reached quorum aka the votes threshold to win, settle the bet
        if ( player_vote_count == bet.quorum ) {
            transfers::send_all(&mut bet.funds, player_addr, ctx);
            bet.winner = option::some(player_addr);
            bet.phase = PHASE_SETTLED;
            return
        };

        // If it's no longer possible for any player to win, refund everyone and end the bet
        if ( is_stalemate(bet) ) {
            transfers::refund_all(&mut bet.funds);
            bet.phase = PHASE_STALEMATE;
            return
        };

    }
    
    // errors cancel()
    const E_NOT_AUTHORIZED: u64 = 303;
    const E_UNFORESEEN_CANCELLATION_CASE_DURING_VOTING: u64 = 304;
    const E_BET_ALREADY_SETTLED: u64 = 305;
    const E_BET_ALREADY_CANCELLED: u64 = 306;
    const E_BET_ENDED_IN_STALEMATE: u64 = 307;
    const E_UNFORESEEN_CANCELLATION_CASE: u64 = 308;
    const E_CANCEL_REQUEST_ALREADY_MADE: u64 = 309;

    public entry fun cancel<T>(
        bet: &mut Bet<T>, 
        ctx: &mut TxContext
    ){
        let sender = tx_context::sender(ctx);
        let is_player = vector::contains(&bet.players, &sender);
        let is_judge = vector::contains(&bet.judges, &sender);
        assert!( is_player || is_judge, E_NOT_AUTHORIZED );

        if (bet.phase == PHASE_FUND){
            // no funds deposited
            if (vec_map::is_empty(&bet.funds)){
                bet.phase = PHASE_CANCELED;
            
            // funds where already deposited
            } else {
                // any judge or player can cancel the bet if he/she is of the opinion one of the players is chickening out
                // after the bet was created and other players already deposited,
                // this prevents a player from locking other player funds
                transfers::refund_all(&mut bet.funds);
                bet.phase = PHASE_CANCELED;
            }
        }
        else if (bet.phase == PHASE_VOTE){
            // Provide the players the option to unanimously cancel a bet during voting
            assert!( !vector::contains(&bet.cancel_requests, &sender), E_CANCEL_REQUEST_ALREADY_MADE );
            assert!( is_player, E_NOT_AUTHORIZED );
            vector::push_back(&mut bet.cancel_requests, sender);

            let player_len = vector::length(&bet.players);
            let cancel_requests_len = vector::length(&bet.cancel_requests);
            if ( player_len == cancel_requests_len){
                transfers::refund_all(&mut bet.funds);
                bet.phase = PHASE_CANCELED;
            }
        }
        else {
            assert!( !(bet.phase == PHASE_CANCELED), E_BET_ALREADY_CANCELLED );
            assert!( !(bet.phase == PHASE_STALEMATE), E_BET_ENDED_IN_STALEMATE );
            assert!( !(bet.phase == PHASE_SETTLED), E_BET_ALREADY_SETTLED );
            assert!( false, E_UNFORESEEN_CANCELLATION_CASE );
        }

    }

    /* Helpers - private to the module */
        
    // Returns true if it is no longer possible for any player to win the bet
    fun is_stalemate<T>(bet: &Bet<T>): bool {
        let number_of_judges = vector::length(&bet.judges);
        let votes_so_far = vec_map::size(&bet.votes);
        let votes_remaining = number_of_judges - votes_so_far;
        let distance_to_win = bet.quorum - bet.most_votes;
        return votes_remaining < distance_to_win
    }

    // One-Time-Witness
    struct BET has drop {}

    fun init(otw: BET, ctx: &mut TxContext)
    {
        let publisher = package::claim(otw, ctx);

        let bet_display = display::new_with_fields<Bet<sui::sui::SUI>>(
            &publisher,
            vector[
                utf8(b"name"),
                utf8(b"description"),
                utf8(b"link"),
                utf8(b"project_url"),
                utf8(b"creator"),
            ], vector[
                utf8(b"Bet: {title}"),
                utf8(b"{description}"),
                utf8(b"https://gotbeef.onrender.com//bet/{id}"),
                utf8(b""),
                utf8(b"GCB")
            ], ctx
        );
        display::update_version(&mut bet_display);

        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(bet_display, tx_context::sender(ctx));
    }

}