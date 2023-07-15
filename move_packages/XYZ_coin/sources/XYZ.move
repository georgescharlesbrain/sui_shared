// This is the xyz module in the examples package creating the XYZ coin
/* Features:
    - Admin
    - multiple minter packages
    - functions: 
        for coins: mint, burn, transfer, total_supply
        for minter management: is_minter, add_minter, remove_minter


*/

// https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/coin.md#

/* TODO:
    Add and Remove a minter

*/


module examples::xyz{

    use sui::object::{Self, UID, ID};
    use sui::balance::{Self, Supply};
    use sui::vec_set::{Self, VecSet};
    use sui::coin::{Self, Coin};
    use sui::tx_context::{Self, TxContext};
    use std::option::{Self};
    use sui::url::{Self, Url};
    use sui::transfer::{Self};
    use sui::package::{Publisher};
    use sui::event;

    const XYZ_PRE_MINT_AMOUNT: u64 = 800_000_000_000000000; // mint 800M XYZ tokens, note that XYZ has 9 decimals, see below

    // Errors _________________________________________________________________
    const ERROR_NOT_ALLOWED_TO_MINT: u64 = 1;
    const ERROR_NO_ZERO_ADDRESS: u64 = 2;

    // Structs _________________________________________________________________

    /// The type identifier of coin. The coin will have a type
    /// tag of kind: `Coin<package_object::mycoin::MYCOIN>`
    /// Make sure that the name of the type matches the module's name. Such that XYZ is a One Time Witness.
    struct XYZ has drop {}

    // The XYZStorage struct is used to store the XYZ coin and the minter list
    struct XYZStorage has key {
        id: UID,
        supply: Supply<XYZ>,
        minters: VecSet<ID> // List of publishers that are allowed to mint XYZ
    }

    // The AdminCap struct is used to manage the minter list
    struct XYZAdminCap has key {
        id: UID
    }


    // Events _________________________________________________________________

    struct MinterAdded has copy, drop {
        id: ID
    }

    struct MinterRemoved has copy, drop {
        id: ID
    }

    struct NewAdmin has copy, drop {
        admin: address // address is a built-in type in move
    }

    // Init _________________________________________________________________

    fun init(witness: XYZ, ctx: &mut TxContext){

        let (treasury_cap, coin_metadata) = coin::create_currency(
            /* witness: T, */ witness,
            /* decimals: u8, */ 9,
            /* symbol: vector<u8>, */ b"XYZ",
            /* name: vector<u8>, */ b"XYZ Coin",
            /* description: vector<u8>, */ b"XYZ Coin created as an example coin by GCB",
            /* icon_url: Option<Url>, */ option::some<Url>(url::new_unsafe_from_bytes(b"https://d3hnfqimznafg0.cloudfront.net/image-handler/ts/20200218065624/ri/950/src/images/Article_Images/ImageForArticle_227_15820269818147731.png")),
            /* ctx: &mut TxContext */ ctx,
        );

        // Transform the treasury_cap into a Supply struct to allow this contract to mint and burn
        let supply = coin::treasury_into_supply(treasury_cap);

        // Pre-mint
        let pre_minted_coin = coin::from_balance( balance::increase_supply(&mut supply, XYZ_PRE_MINT_AMOUNT), ctx);
        transfer::public_transfer(pre_minted_coin, tx_context::sender(ctx));

        // Freeze the metadata object
        transfer::public_freeze_object(coin_metadata);

        // Send the AdminCap to the deployer
        transfer::transfer( XYZAdminCap { id: object::new(ctx)}
                            , tx_context::sender(ctx)
                            );

        // Share the XYZStorage object with the SUi network
        transfer::share_object(
            XYZStorage {
                id: object::new(ctx),
                supply: supply,
                minters: vec_set::empty(),
            }
        );

    }


    // coin functions __________________________________________________________

    /**
    * @dev Only minters can create new Coin<XYZ>
    * @param storage The XYZStorage
    * @param publisher The Publisher object of the package who wishes to mint XYZ
    * @return Coin<XYZ> New created XYZ coin
    */
    public fun mint(storage: &mut XYZStorage, publisher: &Publisher, value: u64, ctx: &mut TxContext): Coin<XYZ> {
        assert!(is_minter(storage, object::id(publisher)), ERROR_NOT_ALLOWED_TO_MINT);
        coin::from_balance(balance::increase_supply(&mut storage.supply, value), ctx)
    }

    /**
    * @dev This function allows anyone to burn their own XYZ.
    * @param storage The XYZStorage shared object
    * @param c The XYZ coin that will be burned
    */
    public fun burn(storage: &mut XYZStorage, c: Coin<XYZ>): u64 {
        balance::decrease_supply(&mut storage.supply, coin::into_balance(c))
    }

    /**
    * @dev A utility function to transfer XYZ to a {recipient}
    * @param c The Coin<XYZ> to transfer
    * @param recipient The recipient of the Coin<XYZ>
    */
    public entry fun transfer(c: coin::Coin<XYZ>, recipient: address) {
        transfer::public_transfer(c, recipient);
    }

    /**
    * @dev It returns the total supply of the Coin
    * @param storage The {XYZStorage} shared object
    * @return the total supply in u64
    */
    public fun total_supply(storage: &XYZStorage): u64 {
        balance::supply_value(&storage.supply)
    }

    // minter management functions ______________________________________________

    /**
    * @dev It indicates if a package has the right to mint
    * @param storage The XYZStorage shared object
    * @param publisher_id of the package 
    * @return bool true if it can mint XYZ
    */
    public fun is_minter(storage: &XYZStorage, publisher_id: ID): bool {
        vec_set::contains(&storage.minters, &publisher_id)
    }

    entry public fun add_minter(_: &XYZAdminCap, storage: &mut XYZStorage, publisher_id: ID) {
        vec_set::insert(&mut storage.minters, publisher_id);
        event::emit(MinterAdded { id: publisher_id });
    }

    entry public fun remove_minter(_: &XYZAdminCap, storage: &mut XYZStorage, publisher_id: ID) {
        assert!(is_minter(storage, publisher_id), ERROR_NOT_ALLOWED_TO_MINT);
        vec_set::remove(&mut storage.minters, &publisher_id);
        event::emit(MinterRemoved { id: publisher_id });

    }

    // admin cap management functions ___________________________________________

    entry public fun transfer_admin_cap(cap: XYZAdminCap, new_admin: address) {
        assert!(new_admin != @0x0, ERROR_NO_ZERO_ADDRESS);
        transfer::transfer(cap, new_admin );
        event::emit(NewAdmin { admin: new_admin });
    }

    // test functions ___________________________________________________________

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(XYZ {}, ctx);
    }

    #[test_only]
    public fun mint_for_testing(storage: &mut XYZStorage, value: u64, ctx: &mut TxContext): Coin<XYZ> {
        coin::from_balance(balance::increase_supply(&mut storage.supply, value), ctx)
    }

}