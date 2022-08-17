module SNSadmin::name_service_nft{
    use StarcoinFramework::NFT;
    use StarcoinFramework::Vector;
    use StarcoinFramework::Signer;
    use SNSadmin::Base64;


    friend SNSadmin::registrar;


    const SVG_Base64_Header :vector<u8> = b"data:image/svg+xml;base64,";

    const SVG_Header:vector<u8> = b"<svg xmlns='http://www.w3.org/2000/svg' version='1.1' width='600' height='600'><defs><linearGradient id='grad1' x1='0%' y1='0%' x2='0%' y2='100%'><stop offset='0%' style='stop-color:rgb(3, 150, 248);stop-opacity:1' /><stop offset='100%' style='stop-color:rgb(4, 71, 178);stop-opacity:1' /></linearGradient></defs><rect x='0' y='0' rx='15' ry='15' width='600' height='600' fill='url(#grad1)'/><foreignObject width='600' height='600' x='20' y='20'><body xmlns='http://www.w3.org/1999/xhtml'><text x='20' y='20' style='font-size: 18pt;fill: rgb(255, 255, 255);'>";
    const SVG_Last:vector<u8> = b"</text></body></foreignObject></svg>";


    struct ShardCap<phantom ROOT: store> has key, store{
        mint_cap    :   NFT::MintCapability<SNSMetaData<ROOT>>,
        burn_cap    :   NFT::BurnCapability<SNSMetaData<ROOT>>,
        updata_cap  :   NFT::UpdateCapability<SNSMetaData<ROOT>>
    }

    struct SNSMetaData<phantom ROOT: store> has drop, copy, store {
        domain_name         :   vector<u8>,
        parent              :   vector<u8>,
        create_time         :   u64,
        expiration_time     :   u64,
    }

    struct SNSBody has store{}

    public fun init<ROOT: store>(sender:&signer){
        let account = Signer::address_of(sender);
        assert!(account == @SNSadmin,10012);
        NFT::register_v2<SNSMetaData<ROOT>>(sender, NFT::empty_meta());
        
        move_to(sender,ShardCap{
            mint_cap    :   NFT::remove_mint_capability<SNSMetaData<ROOT>>(sender),
            burn_cap    :   NFT::remove_burn_capability<SNSMetaData<ROOT>>(sender),
            updata_cap  :   NFT::remove_update_capability<SNSMetaData<ROOT>>(sender)
        });
    }

    public (friend) fun mint<ROOT: store>(creater: address, domain_name:&vector<u8>, parent: &vector<u8>, create_time: u64, expiration_time: u64):NFT::NFT<SNSMetaData<ROOT>,SNSBody> acquires ShardCap{
        let name = *domain_name;
        Vector::append(&mut name, b".");
        Vector::append(&mut name, *parent);
        
        let svg = SVG_Header;
        Vector::append(&mut svg, copy name);
        Vector::append(&mut svg, SVG_Last);
        let svg_base64 = SVG_Base64_Header;
        Vector::append(&mut svg_base64, Base64::encode(&svg));



        let shardCap = borrow_global_mut<ShardCap<ROOT>>(@SNSadmin);

        NFT::mint_with_cap_v2<SNSMetaData<ROOT>,SNSBody>(creater, &mut shardCap.mint_cap, NFT::new_meta_with_image(name,svg_base64,b"Starcoin Name Service"),
            SNSMetaData{
                domain_name         :   *domain_name,
                parent              :   *parent,
                create_time         :   create_time,
                expiration_time     :   expiration_time,
            },
            SNSBody{

            }
        )
    }

    // public (friend) fun update<ROOT: store>(nft:&mut NFT::NFT<SNSMetaData<ROOT>,SNSBody>, domain_name:&vector<u8>, parent: &vector<u8>, create_time: u64, expiration_time: u64){

    // }

    public (friend) fun burn<ROOT: store>(nft: NFT::NFT<SNSMetaData<ROOT>,SNSBody>):NFT::NFTInfo<SNSMetaData<ROOT>> acquires ShardCap{
        let shardCap = borrow_global_mut<ShardCap<ROOT>>(@SNSadmin);
        let info = NFT::get_info(&nft);
        SNSBody{} = NFT::burn_with_cap(&mut shardCap.burn_cap, nft);
        info
    }

}