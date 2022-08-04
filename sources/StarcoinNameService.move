module SNSadmin::SNS6{
    use StarcoinFramework::Table;
    use StarcoinFramework::Vector;
    use StarcoinFramework::Signer;
    use StarcoinFramework::Timestamp;
    use StarcoinFramework::NFT;
    use StarcoinFramework::Option;
    use StarcoinFramework::IdentifierNFT;
    use StarcoinFramework::NFTGallery;
    // use StarcoinFramework::Account;
    // use StarcoinFramework::Math;
    // use StarcoinFramework::Hash;
    use SNSadmin::DomainName;
    use SNSadmin::Base64;
    use SNSadmin::Record1 as Record;

    const SVG_Base64_Header :vector<u8> = b"data:image/svg+xml;base64,";

    const SVG_Header:vector<u8> = b"<svg xmlns='http://www.w3.org/2000/svg' version='1.1' width='600' height='600'><defs><linearGradient id='grad1' x1='0%' y1='0%' x2='0%' y2='100%'><stop offset='0%' style='stop-color:rgb(3, 150, 248);stop-opacity:1' /><stop offset='100%' style='stop-color:rgb(4, 71, 178);stop-opacity:1' /></linearGradient></defs><rect x='0' y='0' rx='15' ry='15' width='600' height='600' fill='url(#grad1)'/><foreignObject width='600' height='600' x='20' y='20'><body xmlns='http://www.w3.org/1999/xhtml'><text x='20' y='20' style='font-size: 18pt;fill: rgb(255, 255, 255);'>";
    const SVG_Last:vector<u8> = b"</text></body></foreignObject></svg>";

    struct ShardCap has key, store{
        mint_cap    :   NFT::MintCapability<SNSMetaData>,
        burn_cap    :   NFT::BurnCapability<SNSMetaData>,
        updata_cap  :   NFT::UpdateCapability<SNSMetaData>
    }

    struct SNSMetaData has drop, copy, store {
        domain_name         :   vector<u8>,
        parent                :   vector<u8>,
        create_time         :   u64,
        expiration_time     :   u64,
        // subdomain_names     : vector<vector<u8>>
    }

    struct SNSBody has store{

    }

    struct RootList has key,store{
        roots : Table::Table<vector<u8>, Root>
    }
    
    struct Root has key,store{
        registry :Table::Table<vector<u8>, RegistryDetails>,
        resolvers :Table::Table<vector<u8>, ResolverDetails>
    }

    struct RegistryDetails has store, drop{
        expiration_time   : u64,
        id                : u64
    }


    struct ResolverDetails has store{
        mainDomain          : Option::Option<vector<u8>>,
        stc_address         : address,
        addressRecord       : Record::AddressRecord,
        // contentRecord       : ContentRecord,
        // textRecord          : TextRecord
    }
    
    // struct DomainGallery has key, store{
    //     DomainsName     :   vector<u8>,
    //     Domains         :   Table::Table<vector<u8>, NFT::NFT<SNSMetaData, SNSBody>>
    // }

    public fun  add_root(sender:&signer, root:&vector<u8>)acquires RootList{
        let account = Signer::address_of(sender);
        assert!(account == @SNSadmin,10012);
        let roots = &mut borrow_global_mut<RootList>(@SNSadmin).roots;
        Table::add(roots, *root, Root{
            registry :Table::new<vector<u8>, RegistryDetails>(),
            resolvers :Table::new<vector<u8>, ResolverDetails>()
        });
    }

    public  fun init(sender:&signer){
        let account = Signer::address_of(sender);
        assert!(account == @SNSadmin,10012);
        NFT::register_v2<SNSMetaData>(sender, NFT::empty_meta());
        
        move_to(sender,ShardCap{
            mint_cap    :   NFT::remove_mint_capability<SNSMetaData>(sender),
            burn_cap    :   NFT::remove_burn_capability<SNSMetaData>(sender),
            updata_cap  :   NFT::remove_update_capability<SNSMetaData>(sender)
        });
        
        let rootlist = RootList{
            roots : Table::new<vector<u8>, Root>()
        };

        move_to(sender, rootlist);
    }

    public fun register (sender:&signer, name: &vector<u8>, root_name:&vector<u8>, registration_duration: u64) acquires RootList, ShardCap{
        assert!( registration_duration >= 60 * 60 * 24 * 180 ,1001);

        assert!( DomainName::dot_number(name) == 0 , 1003);
        let account = Signer::address_of(sender);

        let now_time = Timestamp::now_seconds();
        let name_hash = DomainName::get_name_hash_2(root_name, name);
        let roots = &mut borrow_global_mut<RootList>(@SNSadmin).roots;
        let root = Table::borrow_mut(roots, *root_name);
        
        let shardCap = borrow_global_mut<ShardCap>(@SNSadmin);

        let svg = SVG_Header;
        Vector::append(&mut svg, *name);
        Vector::append(&mut svg, SVG_Last);
        let svg_base64 = SVG_Base64_Header;
        Vector::append(&mut svg_base64, Base64::encode(&svg));
        let domain_name = *name;
        Vector::append(&mut domain_name, b".");
        Vector::append(&mut domain_name, *root_name);
        let nft = NFT::mint_with_cap_v2<SNSMetaData,SNSBody>(account, &mut shardCap.mint_cap, NFT::new_meta_with_image(domain_name,svg_base64,b"Starcoin Name Service"),
            SNSMetaData{
                domain_name         :   *name,
                parent              :   *root_name,
                create_time         :   now_time,
                expiration_time     :   now_time + registration_duration,
                //subdomain_names     :   Vector::empty<vector<u8>>()
            },
            SNSBody{

            }
        );

        //TODO pay some STC

        if(Table::contains(&root.registry, copy name_hash)){
            let registryDetails = Table::borrow_mut(&mut root.registry, copy name_hash);
            if( registryDetails.expiration_time < now_time){
                registryDetails.expiration_time = now_time + registration_duration;
                registryDetails.id = NFT::get_id(&nft);
            }else{
                abort 10001
            };
        }else{
            Table::add(&mut root.registry, copy name_hash, RegistryDetails{
                expiration_time   : now_time + registration_duration,
                id                : NFT::get_id(&nft)
            });
        };

        if(Table::contains(&root.resolvers, copy name_hash)){
            let ResolverDetails{
                mainDomain: _mainDomain         ,
                stc_address:_stc_address        ,
                addressRecord      
            } = Table::remove(&mut root.resolvers, copy name_hash);
            Record::destroy_address_record(addressRecord);
        }else{
            
        };
        NFTGallery::deposit(sender, nft);
    }

    public fun use_domain (sender:&signer, id: u64, stc_address: address) acquires ShardCap,RootList{
        let roots = &mut borrow_global_mut<RootList>(@SNSadmin).roots;

        let shardCap = borrow_global_mut<ShardCap>(@SNSadmin);

        let nft_op = NFTGallery::withdraw<SNSMetaData,SNSBody>(sender, id);

        assert!(Option::is_some(&nft_op),1003);

        let nft = Option::destroy_some(nft_op);

        let id =NFT::get_id(&nft);
        let nft_meta = NFT::get_type_meta(&nft);
        let root;
        if(Table::contains(roots, *&nft_meta.parent)){
            root = Table::borrow_mut(roots, *&nft_meta.parent);
        }else{
            abort 10000
        };
        
        let name_hash = DomainName::get_name_hash_2(&nft_meta.parent, &nft_meta.domain_name);

        if(Table::contains(&root.registry, copy name_hash)){
            let registryDetails = Table::borrow_mut(&mut root.registry, copy name_hash);
            if( registryDetails.id != id ){
                abort 10001
            }
        }else{
            abort 10002
        };
        
        IdentifierNFT::grant(&mut shardCap.mint_cap, sender, nft);

        Table::add(&mut root.resolvers,  name_hash, ResolverDetails{
            mainDomain    : Option::none<vector<u8>>(),
            stc_address   : stc_address,
            addressRecord:Record::new_address_record()
        });
    }
    
    public fun  add_Record_address(sender:&signer,name:&vector<u8>,addr:&vector<u8>)acquires RootList{
        let account = Signer::address_of(sender);
        let op_info = IdentifierNFT::get_nft_info<SNSMetaData,SNSBody>(account);
        assert!(Option::is_some(&op_info),102123);
        let info = Option::destroy_some(op_info);
        let (id,_,_,nft_meta) = NFT::unpack_info(info);
        let name_hash = DomainName::get_name_hash_2(&nft_meta.parent, &nft_meta.domain_name);
        
        let roots = &mut borrow_global_mut<RootList>(@SNSadmin).roots;
        assert!(Table::contains(roots, *&nft_meta.parent),10000);
        let root = Table::borrow_mut(roots, *&nft_meta.parent);

        if(Table::contains(&root.registry, copy name_hash)){
            let registryDetails = Table::borrow_mut(&mut root.registry, copy name_hash);
            if( registryDetails.id != id ){
                abort 10001
            }
        }else{
            abort 10002
        };

        if(Table::contains(&root.resolvers, copy name_hash)){
            let addressRecord = &mut Table::borrow_mut(&mut root.resolvers, copy name_hash).addressRecord;
            Record::change_address_record( addressRecord,name,addr)
        }else{
            abort 100012
        };


    }

    public fun unuse(sender:&signer)acquires ShardCap,RootList{
        let roots = &mut borrow_global_mut<RootList>(@SNSadmin).roots;
        
        let account = Signer::address_of(sender);
        let shardCap = borrow_global_mut<ShardCap>(@SNSadmin);
        let nft = IdentifierNFT::revoke<SNSMetaData,SNSBody>(&mut shardCap.burn_cap, account);

        let nft_meta = NFT::get_type_meta(&nft);
        let root = Table::borrow_mut(roots, *&nft_meta.parent);
        let name_hash = DomainName::get_name_hash_2(&nft_meta.parent, &nft_meta.domain_name);

        NFTGallery::deposit_to(account, nft);
        let ResolverDetails{
                mainDomain:_mainDomain         ,
                stc_address:_stc_address        ,
                addressRecord      
            } = Table::remove(&mut root.resolvers, copy name_hash);
        Record::destroy_address_record(addressRecord);
    }

    public fun resolve_stc_address(node:&vector<u8>, root_name:&vector<u8>):address acquires RootList {
    
        let roots = &mut borrow_global_mut<RootList>(@SNSadmin).roots;
        let root = Table::borrow_mut(roots, *root_name);
        if(Table::contains(&root.resolvers, *node)){
            let resolverDetails = Table::borrow(&root.resolvers, *node);

            if(Option::is_none(&resolverDetails.mainDomain)){
                return resolverDetails.stc_address
            }else{
                let mainDomain_node = *Option::borrow(&resolverDetails.mainDomain);
                return Table::borrow(&root.resolvers, mainDomain_node).stc_address
            }
        };
        abort 1012
    }

    public fun resolve_record_address(node:&vector<u8>, root_name:&vector<u8>,name:&vector<u8>):vector<u8> acquires RootList {
    
        let roots = &mut borrow_global_mut<RootList>(@SNSadmin).roots;
        let root = Table::borrow_mut(roots, *root_name);
        if(Table::contains(&root.resolvers, *node)){
            let resolverDetails = Table::borrow(&root.resolvers, *node);

            if(Option::is_none(&resolverDetails.mainDomain)){
                let op_addr = Record::get_address_record(&resolverDetails.addressRecord, name);
                assert!(Option::is_some(&op_addr),123124);
                return Option::destroy_some(op_addr)
            }else{
                let mainDomain_node = *Option::borrow(&resolverDetails.mainDomain);
                let op_addr = Record::get_address_record(&Table::borrow(&root.resolvers, mainDomain_node).addressRecord, name);
                assert!(Option::is_some(&op_addr),123124);
                return Option::destroy_some(op_addr)
            }
        };
        abort 1012
    }

    public fun burn(sender:&signer,id: u64)acquires ShardCap,RootList{
        let roots = &mut borrow_global_mut<RootList>(@SNSadmin).roots;

        let shardCap = borrow_global_mut<ShardCap>(@SNSadmin);

        let nft_op = NFTGallery::withdraw<SNSMetaData,SNSBody>(sender, id);

        assert!(Option::is_some(&nft_op),1003);

        let nft = Option::destroy_some(nft_op);
        let id =NFT::get_id(&nft);
        let nft_meta = NFT::get_type_meta(&nft);
 
        let root = Table::borrow_mut(roots, *&nft_meta.parent);
        let name_hash = DomainName::get_name_hash_2(&nft_meta.parent, &nft_meta.domain_name);
        let registryDetails = Table::borrow(&root.registry, copy name_hash);
        if( registryDetails.id == id){
           abort 2341
        };
        
        SNSBody{} = NFT::burn_with_cap(&mut shardCap.burn_cap, nft);
        let ResolverDetails{
                mainDomain:_mainDomain         ,
                stc_address:_stc_address        ,
                addressRecord      
            } = Table::remove(&mut root.resolvers, copy name_hash);
        Record::destroy_address_record(addressRecord);
    }
}

module SNSadmin::SNStestscript6{
    use SNSadmin::SNS6 as SNS;
    use SNSadmin::DomainName;
    use StarcoinFramework::Signer;


    public (script) fun register(sender:signer, name: vector<u8>, root: vector<u8>,registration_duration: u64){
        SNS::register(&sender, &name, &root, registration_duration);
    }

    public (script) fun use_with_config (sender:signer, id: u64, stc_address: address){
        SNS::use_domain(&sender,id,stc_address);
    }

    public (script) fun use_default (sender:signer, id: u64){
        SNS::use_domain(&sender,id,Signer::address_of(&sender));
    }

    public (script) fun unuse(sender:signer){
        SNS::unuse(&sender);
    }

    public (script)fun add_Record_address(sender:signer,name:vector<u8>,addr:vector<u8>){
        SNS::add_Record_address(&sender,&name,&addr);
    }

    public fun resolve_4_name(name:vector<u8>):address{
        SNS::resolve_stc_address(&DomainName::get_name_hash_2(&b"stc",&name), &b"stc")
    }

    public fun resolve_4_node(node:vector<u8>):address{
        SNS::resolve_stc_address(&node,&b"stc")
    }

    public fun resolve_record_address_4_name(domain:vector<u8>,name:vector<u8>):vector<u8>{
        SNS::resolve_record_address(&DomainName::get_name_hash_2(&b"stc",&domain),&b"stc",&name)
    }

    public fun resolve_record_address_4_node(node:vector<u8>,name:vector<u8>):vector<u8>{
        SNS::resolve_record_address(&node,&b"stc",&name)
    }

}

module SNSadmin::SNSInittestscript6{
    use SNSadmin::SNS6 as SNS;
    use SNSadmin::Record1 as Record;


    public (script) fun SNS_init(sender:signer){
        SNS::init(&sender);
    }

    public (script) fun add_root(sender:signer, root:vector<u8>){
        SNS::add_root(&sender, &root);
    }

    public (script) fun Record_init(sender:signer){
        Record::init(&sender);
    }

    public (script) fun Record_address_add(sender:signer,name:vector<u8>,len:u64){
        Record::add_allow_address_record(&sender,&name,len);
    }

    public (script) fun one_init(sender:signer){
        SNS::init(&sender);
        Record::init(&sender);
    }
}