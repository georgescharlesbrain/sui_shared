/* Tests for the bet module*/

#[test_only]
#[allow(unused_const, unused_use)]
module gotbeef::bet_tests{

    use std::option::{Self, Option};
    use std::string::{Self, utf8};
    use std::vector;
    use std::debug;

    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::vec_map;
    use sui::test_scenario::{Self as ts, Scenario};
    use sui::test_utils::{Self};

    use gotbeef::bet::{Self, Bet};

    // Default bet settings
    const TITLE: vector<u8> = b"GCR vs Kwon";
    const DESC: vector<u8> = b"The Bet of the Century";
    const QUORUM: u64 = 2;
    const BET_SIZE: u64 = 500;
    const CREATOR: address = @0x777;
    const PLAYER_1: address = @0xA1;
    const PLAYER_2: address = @0xA2;
    const PLAYERS: vector<address> = vector[@0xA1, @0xA2];
    const JUDGE_1: address = @0xB1;
    const JUDGE_2: address = @0xB2;
    const JUDGES: vector<address> = vector[@0xB1, @0xB2];
    const SOMEONE: address = @0xC0B1E;

    // Bet.phase possible values
    // Using bet::PHASE_FUND in not possible
    // Constants are internal to their module, and cannot can be accessed outside of their module.
    const PHASE_FUND: u8 = 0;       
    const PHASE_VOTE: u8 = 1;       
    const PHASE_SETTLED: u8 = 2;    
    const PHASE_CANCELED: u8 = 3;   
    const PHASE_STALEMATE: u8 = 4;  


    // /* std and sui modules debug tests */
    // #[test]
    // fun test_module(){
    //     let v = vector::empty<u64>();
    //     std::debug::print(&mut v);
    //     vector::push_back(&mut v, 3);
    //     vector::push_back(&mut v, 5);
    //     std::debug::print(&mut v);
    //     let borrowed_element = vector::borrow(&v, 0);
    //     std::debug::print(&b"v length is");
    //     std::debug::print(&vector::length(&v));
    //     std::debug::print(&mut v);
    //     std::debug::print(borrowed_element);
    //     std::debug::print(&vector::contains(&v, &(3 as u64))); // cast an int to u64 and pass it as a reference
    // }

    /* Accessor tests */

    #[test]
    fun test_accessors()
    {
        test_utils::print(b"start tests")
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; {
            bet::create<SUI>( TITLE, DESC, QUORUM, BET_SIZE, PLAYERS, JUDGES, ts::ctx(scen) );
        };
        ts::next_tx(scen, SOMEONE); {
            let bet_val = ts::take_shared<Bet<SUI>>(scen);
            let bet = &mut bet_val;

            assert!( bet::phase(bet) == 0, 0 );
            assert!( bet::title(bet) == &string::utf8(TITLE), 0 );
            assert!( bet::description(bet) ==  &string::utf8(DESC), 0 );
            assert!( bet::quorum(bet) == QUORUM, 0 );
            assert!( bet::size(bet) == BET_SIZE, 0 );
            assert!( vector::length( bet::players(bet) ) == 2, 0 );
            assert!( vector::length( bet::judges(bet) ) == 2, 0 );
            assert!( vec_map::size( bet::votes(bet) ) == 0, 0 );
            assert!( vec_map::size( bet::funds(bet) ) == 0, 0 );
            assert!( bet::most_votes(bet) == 0, 0 );
            assert!( bet::winner(bet) == &option::none<address>(), 0 );

            ts::return_shared(bet_val);
        };
        ts::end(scen_val);
    }

    /* create() tests */

    #[test]
    fun test_create_success()
    {
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; 
        {
            bet::create<SUI>( TITLE, DESC, QUORUM, BET_SIZE, PLAYERS, JUDGES, ts::ctx(scen) );
        };
        ts::next_tx(scen, CREATOR); {
            let bet = ts::take_shared<Bet<SUI>>(scen);
            ts::return_shared(bet);
        };
        ts::end(scen_val);
    }

    #[test, expected_failure(abort_code = gotbeef::bet::E_JUDGES_CANT_BE_PLAYERS)]
    fun test_create_e_judges_cant_be_players()
    {
        let players = vector[PLAYER_1, PLAYER_2, JUDGE_1];
        let judges = vector[JUDGE_1, JUDGE_2];
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; 
        {
            bet::create<SUI>( TITLE, DESC, QUORUM, BET_SIZE, players, judges, ts::ctx(scen) );
        };
        ts::end(scen_val);
    }

    #[test, expected_failure(abort_code = gotbeef::bet::E_INVALID_NUMBER_OF_JUDGES)]
    fun test_create_e_invalid_number_of_judges()
    {
        // let judges = vector[];
        let judges = vector::empty();
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; 
        {
            bet::create<SUI>( TITLE, DESC, QUORUM, BET_SIZE, PLAYERS, judges, ts::ctx(scen) );
        };
        ts::end(scen_val);
    }

    #[test, expected_failure(abort_code = gotbeef::bet::E_INVALID_NUMBER_OF_PLAYERS)]
    fun test_create_e_invalid_number_of_players()
    {
        let players = vector[PLAYER_1];
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; 
        {
            bet::create<SUI>( TITLE, DESC, QUORUM, BET_SIZE, players, JUDGES, ts::ctx(scen) );
        };
        ts::end(scen_val);
    }

    #[test, expected_failure(abort_code = gotbeef::bet::E_MISSING_TITLE)]
    fun test_create_e_missing_title()
    {
        let title: vector<u8> = b"";
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; 
        {
            bet::create<SUI>( title, DESC, QUORUM, BET_SIZE, PLAYERS, JUDGES, ts::ctx(scen) );
        };
        ts::end(scen_val);
    }

    #[test, expected_failure(abort_code = gotbeef::bet::E_ZERO_BET_SIZE)]
    fun test_create_e_zero_bet_size()
    {
        let bet_size = 0;
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; 
        {
            bet::create<SUI>( TITLE, DESC, QUORUM, bet_size, PLAYERS, JUDGES, ts::ctx(scen) );
        };
        ts::end(scen_val);
    }

    #[test, expected_failure(abort_code = gotbeef::bet::E_QUORUM_NUMBER_OF_JUDGES_MISMATCH)]
    fun test_create_e_quorum_number_of_judges_mismatch()
    {
        let quorum = 2;
        let judges = vector[JUDGE_1];
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; 
        {
            bet::create<SUI>( TITLE, DESC, quorum, BET_SIZE, PLAYERS, judges, ts::ctx(scen) );
        };
        ts::end(scen_val);
    }

    #[test, expected_failure(abort_code = gotbeef::bet::E_DUPLICATE_PLAYERS)]
    fun test_create_e_duplicate_players()
    {
        let players = vector[@0xCAFE, @0x123, @0xCAFE];
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; {
            bet::create<SUI>( TITLE, DESC, QUORUM, BET_SIZE, players, JUDGES, ts::ctx(scen) );
        };
        ts::end(scen_val);
    }

    #[test, expected_failure(abort_code = gotbeef::bet::E_DUPLICATE_JUDGES)]
    fun test_create_e_duplicate_judges()
    {
        let judges = vector[@0xAAA, @0xBBB, @0xAAA];
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; {
            bet::create<SUI>( TITLE, DESC, QUORUM, BET_SIZE, PLAYERS, judges, ts::ctx(scen) );
        };
        ts::end(scen_val);
    }

    /* Helpers */
    fun create_bet(scen: &mut Scenario) {
        bet::create<SUI>( TITLE, DESC, QUORUM, BET_SIZE, PLAYERS, JUDGES, ts::ctx(scen) );
    }

    fun fund_bet(scen: &mut Scenario, amount: u64) {
        let bet_val = ts::take_shared<Bet<SUI>>(scen);
        let bet = &mut bet_val;
        let ctx = ts::ctx(scen);
        let player_coin = coin::mint_for_testing<SUI>(amount, ctx);
        bet::fund<SUI>(bet, b"answer", player_coin, ctx);
        ts::return_shared(bet_val);
    }

    fun cast_vote(scen: &mut Scenario, player_addr: address) {
        let bet_val = ts::take_shared<Bet<SUI>>(scen);
        let bet = &mut bet_val;
        bet::vote(bet, player_addr, ts::ctx(scen));
        ts::return_shared(bet_val);
    }

    /* fund() tests */


    #[test]
    fun test_fund_success()
    {  
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val;

        // Creator creates bet, can also be any other person
        {
            create_bet(scen);
        };

        // verify that the initial state has no funds deposited and is the phase PHASE_FUND
        ts::next_tx(scen, SOMEONE);
        {
            let bet_val = ts::take_shared<Bet<SUI>>(scen);
            let beto = &mut bet_val; //beto stands for bet object

            // no funds deposited = verify that the length of the funds VecMap is 0
            assert!( vec_map::size( bet::funds(beto) ) == 0, 0);
                // note that you have to use the funds accessor function as bet.funds only works in the bet module

            // initial phase is PHASE_FUND
            assert!( bet::phase(beto) == PHASE_FUND , 0);
            // debug::print(&utf8(b"verified that the initial state of the created bet has no funds and is in the phase PHASE_FUND"));
            ts::return_shared(bet_val);
        };


        // player 1 funds bet
        ts::next_tx(scen, PLAYER_1);
        {fund_bet(scen, BET_SIZE);};

        // player 1 checks the bet object
        ts::next_tx(scen, PLAYER_1);
        {
            // Bet was partially funded
            let bet_val = ts::take_shared<Bet<SUI>>(scen);
            let bet = &mut bet_val;
            let funds = bet::funds<SUI>(bet);
            // only 1 player funded the bet so far
            assert!( vec_map::size(funds) == 1, 0 );
            // and it's who you'd expect
            assert!( vec_map::contains(funds, &PLAYER_1), 0 );
            // the bet remains in the funding phase
            assert!( bet::phase(bet) == PHASE_FUND, 0 );
            ts::return_shared(bet_val);
        };

        // Player 2 funds the bet (send exact amount, expect no change)
        ts::next_tx(scen, PLAYER_2); { fund_bet(scen, BET_SIZE); };

        // Creator checks if we moved to phase 2 
        ts::next_tx(scen, CREATOR); 
        { 
            // Bet was completely funded
            let bet_val = ts::take_shared<Bet<SUI>>(scen);
            let bet = &mut bet_val;
            let funds = bet::funds<SUI>(bet);
            assert!( vec_map::size(funds) == vector::length(&PLAYERS), 0 );
            // both players have funded the bet
            assert!( vec_map::contains(funds, &PLAYER_2), 0 );
            // the bet is now in the voting phase
            assert!( bet::phase(bet) == PHASE_VOTE, 0 );
            ts::return_shared(bet_val);
        };

        ts::end(scen_val);
    }

    #[test, expected_failure(abort_code = gotbeef::bet::E_NOT_IN_FUNDING_PHASE)]
    /// Non-player tries to fund the bet
    fun test_fund_e_not_in_funding_phase()
    {
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; 
        { create_bet(scen); };
        // It is not possible to change the phase of a bet directly from outside the module 
        // because we only have accessors/getter functions that reference the bet object
        // not a function that accepts a &mut bet
        // Use the normal process to move the bet to the next phase
        ts::next_tx(scen, PLAYER_1);
        { fund_bet(scen, BET_SIZE); };
        ts::next_tx(scen, PLAYER_2);
        { fund_bet(scen, BET_SIZE); };
        // confirm the bet is now in the voting phase
        ts::next_tx(scen, PLAYER_2);
        {
            let bet_val = ts::take_shared<Bet<SUI>>(scen);
            let bet = &mut bet_val;
            assert!( bet::phase(bet) == PHASE_VOTE, 0 );
            ts::return_shared(bet_val);
        };
        // try to fund while already being in the voting phase
        ts::next_tx(scen, PLAYER_2);
        {fund_bet(scen, BET_SIZE);};
        ts::end(scen_val);
    }

    #[test, expected_failure(abort_code = gotbeef::bet::E_ONLY_PLAYERS_CAN_FUND)]
    /// Non-player tries to fund the bet
    fun test_fund_e_only_players_can_fund()
    {
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; 
        { create_bet(scen); };
        ts::next_tx(scen, SOMEONE); 
        { fund_bet(scen, BET_SIZE); };
        ts::end(scen_val);
    }

    #[test, expected_failure(abort_code = gotbeef::bet::E_WRONG_BET_SIZE)]
    fun test_fund_e_wrong_bet_size()
    {
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; 
        { create_bet(scen); };
        ts::next_tx(scen, PLAYER_1); 
        { fund_bet(scen, BET_SIZE+100); };
        ts::end(scen_val);
    }

    #[test, expected_failure(abort_code = gotbeef::bet::E_PLAYER_ALREADY_DEPOSITED)]
    fun test_fund_e_player_already_deposited()
    {
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; 
        { create_bet(scen); };
        ts::next_tx(scen, PLAYER_1); 
        { fund_bet(scen, BET_SIZE); };
        // PLAYER_1 tries to deposit a second time
        ts::next_tx(scen, PLAYER_1); 
        { fund_bet(scen, BET_SIZE); };
        ts::end(scen_val);
    }

    /* vote() tests */

    #[test]
    fun test_vote_success()
    {
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; { create_bet(scen); };

        ts::next_tx(scen, PLAYER_1); { fund_bet(scen, BET_SIZE); };
        ts::next_tx(scen, PLAYER_2); { fund_bet(scen, BET_SIZE); };

        ts::next_tx(scen, JUDGE_1); { cast_vote(scen, PLAYER_1); };
        ts::next_tx(scen, JUDGE_2); { cast_vote(scen, PLAYER_1); };

        // Anybody can verify the outcome
        ts::next_tx(scen, SOMEONE);
        {
            // Bet funds have been distributed
            let bet_val = ts::take_shared<Bet<SUI>>(scen);
            let bet = &mut bet_val;
            let funds = bet::funds<SUI>(bet);
            assert!( vec_map::size(funds) == 0, 0 );
            // The bet is now in the settled phase
            assert!( bet::phase(bet) == 2, 0 );
            // The bet winner is player 1
            let winner_opt = bet::winner(bet);
            assert!( option::contains(winner_opt, &PLAYER_1), 0 );
            ts::return_shared(bet_val);
        };

        // The winner received the funds
        ts::next_tx(scen, PLAYER_1);
        {
            let player_coin = ts::take_from_sender<Coin<SUI>>(scen);
            let actual_val = coin::value(&player_coin);
            let expect_val = BET_SIZE * vector::length(&PLAYERS);
            assert!( actual_val == expect_val, 0 );
            ts::return_to_sender(scen, player_coin);
        };
        ts::end(scen_val);
    }

    #[test, expected_failure(abort_code = gotbeef::bet::E_NOT_IN_VOTING_PHASE)]
    /// Judge tries to vote before all players have sent their funds
    fun test_e_vote_not_in_voting_phase()
    {
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; { create_bet(scen); };
        ts::next_tx(scen, PLAYER_1); { fund_bet(scen, BET_SIZE); };
        ts::next_tx(scen, PLAYER_1); { cast_vote(scen, PLAYER_1); };
        ts::end(scen_val);
    }

    #[test, expected_failure(abort_code = gotbeef::bet::E_ONLY_JUDGES_CAN_VOTE)]
    /// Non-judge tries to vote
    fun test_e_vote_only_judges_can_vote()
    {
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; { create_bet(scen); };
        ts::next_tx(scen, PLAYER_1); { fund_bet(scen, BET_SIZE); };
        ts::next_tx(scen, PLAYER_2); { fund_bet(scen, BET_SIZE); };
        ts::next_tx(scen, SOMEONE); { cast_vote(scen, PLAYER_1); };
        ts::end(scen_val);
    }

    #[test, expected_failure(abort_code = gotbeef::bet::E_ALREADY_VOTED)]
    /// Judge tries to vote twice
    fun test_e_vote_already_voted()
    {
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; { create_bet(scen); };
        ts::next_tx(scen, PLAYER_1); { fund_bet(scen, BET_SIZE); };
        ts::next_tx(scen, PLAYER_2); { fund_bet(scen, BET_SIZE); };
        ts::next_tx(scen, JUDGE_1); { cast_vote(scen, PLAYER_1); };
        ts::next_tx(scen, JUDGE_1); { cast_vote(scen, PLAYER_1); };
        ts::end(scen_val);
    }

    #[test, expected_failure(abort_code = gotbeef::bet::E_PLAYER_NOT_FOUND)]
    /// Judge tries to vote for a non-player
    fun test_e_vote_player_not_found()
    {
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; { create_bet(scen); };
        ts::next_tx(scen, PLAYER_1); { fund_bet(scen, BET_SIZE); };
        ts::next_tx(scen, PLAYER_2); { fund_bet(scen, BET_SIZE); };
        ts::next_tx(scen, JUDGE_1); { cast_vote(scen, SOMEONE); };
        ts::end(scen_val);
    }

    /* cancel() tests */

    #[test]
    fun test_cancel_no_funds_success()
    {
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; {
            create_bet(scen);
        };
        ts::next_tx(scen, PLAYER_2); {
            let bet_val = ts::take_shared<Bet<SUI>>(scen);
            let bet = &mut bet_val;
            bet::cancel( bet, ts::ctx(scen) );
            assert!( bet::phase(bet) == PHASE_CANCELED, 0 );
            ts::return_shared(bet_val);
        };
        ts::end(scen_val);
    }

    #[test]
    /// Any player or judge can cancel a bet if a player chickens out during funding
    fun test_cancel_has_funds_success()
    {
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; {
            create_bet(scen);
        };
        ts::next_tx(scen, PLAYER_1); { fund_bet(scen, BET_SIZE); };
        ts::next_tx(scen, PLAYER_1); {
            let bet_val = ts::take_shared<Bet<SUI>>(scen);
            let bet = &mut bet_val;
            bet::cancel( bet, ts::ctx(scen) );
            ts::return_shared(bet_val);
        };
        // TODO check if PLAYER_1 received the funds
        ts::end(scen_val);
    }

    #[test, expected_failure(abort_code = gotbeef::bet::E_NOT_AUTHORIZED)]
    /// A non-participant tries to cancel a bet
    fun test_cancel_e_not_authorized()
    {
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; {
            create_bet(scen);
        };
        ts::next_tx(scen, SOMEONE); {
            let bet_val = ts::take_shared<Bet<SUI>>(scen);
            let bet = &mut bet_val;
            bet::cancel( bet, ts::ctx(scen) );
            ts::return_shared(bet_val);
        };
        ts::end(scen_val);
    }

    #[test, expected_failure(abort_code = gotbeef::bet::E_BET_ALREADY_SETTLED)]
    /// Try to cancel a settled bet
    fun test_cancel_e_bet_already_settled()
    {
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; {
            create_bet(scen);
        };

        ts::next_tx(scen, PLAYER_1); { fund_bet(scen, BET_SIZE); };
        ts::next_tx(scen, PLAYER_2); { fund_bet(scen, BET_SIZE); };

        ts::next_tx(scen, JUDGE_1); { cast_vote(scen, PLAYER_1); };
        ts::next_tx(scen, JUDGE_2); { cast_vote(scen, PLAYER_1); };

        ts::next_tx(scen, PLAYER_1); {
            let bet_val = ts::take_shared<Bet<SUI>>(scen);
            let bet = &mut bet_val;
            assert!( bet::phase(bet) == PHASE_SETTLED, 0 );
            bet::cancel( bet, ts::ctx(scen) );
            ts::return_shared(bet_val);
        };
        ts::end(scen_val);
    }

    #[test, expected_failure(abort_code = gotbeef::bet::E_CANCEL_REQUEST_ALREADY_MADE)]
    /// Try to cancel a bet in the voting phase twice
    fun test_cancel_e_cancel_request_already_made()
    {
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; {
            create_bet(scen);
        };

        ts::next_tx(scen, PLAYER_1); { fund_bet(scen, BET_SIZE); };
        ts::next_tx(scen, PLAYER_2); { fund_bet(scen, BET_SIZE); };

        // judges are not showing up to vote, 
        // PLAYER_1 tries to cancel the bet twice

        ts::next_tx(scen, PLAYER_1); {
            let bet_val = ts::take_shared<Bet<SUI>>(scen);
            let bet = &mut bet_val;
            assert!( bet::phase(bet) == PHASE_VOTE, 0 );
            bet::cancel( bet, ts::ctx(scen) );
            bet::cancel( bet, ts::ctx(scen) );
            ts::return_shared(bet_val);
        };
        ts::end(scen_val);
    }

    #[test]
    /// Try to cancel a bet in the voting phase
    fun test_cancel_during_voting_success()
    {
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; {
            create_bet(scen);
        };

        ts::next_tx(scen, PLAYER_1); { fund_bet(scen, BET_SIZE); };
        ts::next_tx(scen, PLAYER_2); { fund_bet(scen, BET_SIZE); };

        // judges are not showing up to vote

        ts::next_tx(scen, PLAYER_1); {
            let bet_val = ts::take_shared<Bet<SUI>>(scen);
            let bet = &mut bet_val;
            assert!( bet::phase(bet) == PHASE_VOTE, 0 );
            bet::cancel( bet, ts::ctx(scen) );
            ts::return_shared(bet_val);
        };
        ts::next_tx(scen, PLAYER_2); {
            let bet_val = ts::take_shared<Bet<SUI>>(scen);
            let bet = &mut bet_val;
            assert!( bet::phase(bet) == PHASE_VOTE, 0 );
            bet::cancel( bet, ts::ctx(scen) );
            assert!( bet::phase(bet) == PHASE_CANCELED, 0 );
            ts::return_shared(bet_val);
        };

        ts::end(scen_val);
    }

    /* end to end tests for multiple scenarios */
    // includes stalemate() tests

    // function to test the expect_phase and expect_winner for multiple scenarios
    fun test_expectations(
        players: vector<address>,
        judges: vector<address>,
        votes: vector<address>,
        quorum: u64,
        expect_phase: u8,
        expect_winner: Option<address>)
    {
        let scen_val = ts::begin(CREATOR);
        let scen = &mut scen_val; {
            bet::create<SUI>( TITLE, DESC, quorum, BET_SIZE, players, judges, ts::ctx(scen) );
        };

        // All players fund the bet
        let players_len = vector::length(&players);
        let i = 0;
        while (i < players_len) {
            let player_addr = vector::borrow(&players, i);
            ts::next_tx(scen, *player_addr); {
                fund_bet(scen, BET_SIZE);
            };
            i = i + 1;
        };

        // Some votes are cast
        let votes_len = vector::length(&votes);
        let i = 0;
        while (i < votes_len) {
            let judge_addr = vector::borrow(&judges, i);
            let player_addr = vector::borrow(&votes, i);
            ts::next_tx(scen, *judge_addr); {
                cast_vote(scen, *player_addr);
            };
            i = i + 1;
        };

        // Verify that the bet in the expected phase
        ts::next_tx(scen, SOMEONE); {
            let bet_val = ts::take_shared<Bet<SUI>>(scen);
            let bet = &mut bet_val;
            assert!( bet::phase(bet) == expect_phase, 0 );
            assert!( bet::winner(bet) == &expect_winner, 0 );
            ts::return_shared(bet_val);
        };
        ts::end(scen_val);
    }

    #[test]
    /// Verify the outcome in various scenarios
    fun test_end_to_end_multiple_scenarios()
    {
        /* 1-of-1 */
        test_expectations(
            /* players */ vector[@0xA1, @0xA2],
            /* judges */  vector[@0xB1],
            /* votes */   vector[@0xA1],
            /* quorum */  1,
            /* expect_phase */ PHASE_SETTLED,
            /* expect_winner */ option::some(@0xA1),
        );

        /* 2-of-2 */
        test_expectations(
            /* players */ vector[@0xA1, @0xA2],
            /* judges */  vector[@0xB1, @0xB2],
            /* votes */   vector[@0xA1, @0xA2],
            /* quorum */  2,
            /* expect_phase */ PHASE_STALEMATE,
            /* expect_winner */ option::none<address>(),
        );
        test_expectations(
            /* players */ vector[@0xA1, @0xA2],
            /* judges */  vector[@0xB1, @0xB2],
            /* votes */   vector[@0xA1, @0xA1],
            /* quorum */  2,
            /* expect_phase */ PHASE_SETTLED,
            /* expect_winner */ option::some(@0xA1),
        );

        /* 3-of-5 */
        test_expectations(
            /* players */ vector[@0xA1, @0xA2, @0xA3, @0xA4],
            /* judges */  vector[@0xB1, @0xB2, @0xB3, @0xB4, @0xB5],
            /* votes */   vector[@0xA1, @0xA2, @0xA3, @0xA4],
            /* quorum */  3,
            /* expect_phase */ PHASE_STALEMATE,
            /* expect_winner */ option::none<address>(),
        );
        test_expectations(
            /* players */ vector[@0xA1, @0xA2, @0xA3, @0xA4, @0xA5],
            /* judges */  vector[@0xB1, @0xB2, @0xB3, @0xB4, @0xB5],
            /* votes */   vector[@0xA1, @0xA2, @0xA3, @0xA3, @0xA4],
            /* quorum */  3,
            /* expect_phase */ PHASE_STALEMATE,
            /* expect_winner */ option::none<address>(),
        );
        test_expectations(
            /* players */ vector[@0xA1, @0xA2, @0xA3, @0xA4],
            /* judges */  vector[@0xB1, @0xB2, @0xB3, @0xB4, @0xB5],
            /* votes */   vector[@0xA1, @0xA2, @0xA3, @0xA3],
            /* quorum */  3,
            /* expect_phase */ PHASE_VOTE,
            /* expect_winner */ option::none<address>(),
        );

        /* 5-of-7 */
        test_expectations(
            /* players */ vector[@0xA1, @0xA2, @0xA3, @0xA4],
            /* judges */  vector[@0xB1, @0xB2, @0xB3, @0xB4, @0xB5, @0xB6, @0xB7],
            /* votes */   vector[@0xA1, @0xA1, @0xA1, @0xA2, @0xA2, @0xA2],
            /* quorum */  5,
            /* expect_phase */ PHASE_STALEMATE,
            /* expect_winner */ option::none<address>(),
        );

        /* 5-of-7 */
        test_expectations(
            /* players */ vector[@0xA1, @0xA2, @0xA3, @0xA4],
            /* judges */  vector[@0xB1, @0xB2, @0xB3, @0xB4, @0xB5, @0xB6, @0xB7],
            /* votes */   vector[@0xA1, @0xA1, @0xA1, @0xA2, @0xA2],
            /* quorum */  5,
            /* expect_phase */ PHASE_VOTE,
            /* expect_winner */ option::none<address>(),
        );
    }

}