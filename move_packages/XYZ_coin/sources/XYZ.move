// This is the xyz module in the examples package creating the XYZ coin

// https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/coin.md#

module examples::xyz{

    use sui::coin::{Self};
    use sui::tx_context::{Self, TxContext};
    use std::option::{Self};
    use sui::url::{Self, Url};
    use sui::transfer::{Self};

    /// The type identifier of coin. The coin will have a type
    /// tag of kind: `Coin<package_object::mycoin::MYCOIN>`
    /// Make sure that the name of the type matches the module's name.

    struct XYZ has drop {}

    fun init(witness: XYZ, ctx: &mut TxContext){

        let (treasury_cap, coin_metadata) = coin::create_currency(
            /* witness: T, */ witness,
            /* decimals: u8, */ 6,
            /* symbol: vector<u8>, */ b"XYZ",
            /* name: vector<u8>, */ b"XYZ Coin",
            /* description: vector<u8>, */ b"XYZ Coin created as an example coin by GCB",
            /* icon_url: Option<Url>, */ option::some<Url>(url::new_unsafe_from_bytes(b"https://d3hnfqimznafg0.cloudfront.net/image-handler/ts/20200218065624/ri/950/src/images/Article_Images/ImageForArticle_227_15820269818147731.png")),
            /* ctx: &mut TxContext */ ctx,
        );

        // Freezes the object. Freezing the object means that the  object: 
        // - Is immutable
        // - Cannot be transferred
        //
        // Note: transfer::freeze_object() cannot be used since CoinMetadata is defined in another 
        //       module
        transfer::public_freeze_object(coin_metadata);

        // Send the TreasuryCap object to the publisher of the module
        //
        // Note: transfer::transfer() cannot be used since TreasuryCap is defined in another module
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));

    }


    public entry fun mint
    (
        cap: &mut coin::TreasuryCap<examples::xyz::XYZ>,
        value: u64, 
        recipient: address,
        ctx: &mut tx_context::TxContext,
    )
    {
        let new_coin = internal_mint_coin(cap, value, ctx);
        transfer::public_transfer(new_coin, recipient);
    }

    public entry fun burn
    (
        cap: &mut coin::TreasuryCap<examples::xyz::XYZ>,
        c: coin::Coin<examples::xyz::XYZ>
    )
    {
        // Burn the coin 
        // 
        // Note: internal_burn_coin returns a u64 but it can be ignored since u64 has drop
        internal_burn_coin(cap, c);

    }


    fun internal_mint_coin
    (
        cap: &mut coin::TreasuryCap<examples::xyz::XYZ>, 
        value: u64, 
        ctx: &mut tx_context::TxContext,
    ):coin::Coin<examples::xyz::XYZ>
    {
        coin::mint(cap, value, ctx)  //no semi-column --> the return value of this function will be the return value of the function
    }

    fun internal_burn_coin
    (
        cap: &mut coin::TreasuryCap<examples::xyz::XYZ>,
        c: coin::Coin<examples::xyz::XYZ>
    ):u64
    {
        coin::burn(cap, c)
    }
}