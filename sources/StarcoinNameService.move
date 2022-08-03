module SNSadmin::SNS1{
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
    use StarcoinFramework::Hash;
    use SNSadmin::DomainName;
    use SNSadmin::Base64;

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
        node                :   vector<u8>,
        create_time         :   u64,
        expiration_time     :   u64,
    }

    struct SNSBody has store{
        domain      :   Domain,
        subDomains  :   SubDomains
    }


    struct Domain has   store {
        stc_address : address,
        contents    : vector<u8>,
        content     : Table::Table<u8, vector<u8>>
    }

    struct SubDomains has store{
        subDomainsName     :   vector<vector<u8>>,
        subDomains         :   Table::Table<vector<u8>, SubDomain>
    }

    struct SubDomain has store{
        stc_address : address,  
        contents    : vector<u8>,
        content     : Table::Table<u8, vector<u8>>
    }



    struct Registry has key, store{
        list : Table::Table<vector<u8>, RegistryDetails>
    }

    struct RegistryDetails has store, drop{
        expiration_time   : u64,
        id                : u64
    }

    struct Resolvers has key, store{
        list : Table::Table<vector<u8>, ResolverDetails>
    }

    struct ResolverDetails has store, drop{
        owner               : Option::Option<address>,
        mainDomain          : Option::Option<vector<u8>>
    }
    
    // struct DomainGallery has key, store{
    //     DomainsName     :   vector<u8>,
    //     Domains         :   Table::Table<vector<u8>, NFT::NFT<SNSMetaData, SNSBody>>
    // }

    public  fun init(sender:&signer){
        let account = Signer::address_of(sender);
        assert!(account == @SNSadmin,10012);
        NFT::register_v2<SNSMetaData>(sender, NFT::empty_meta());
        
        move_to(sender,ShardCap{
            mint_cap    :   NFT::remove_mint_capability<SNSMetaData>(sender),
            burn_cap    :   NFT::remove_burn_capability<SNSMetaData>(sender),
            updata_cap  :   NFT::remove_update_capability<SNSMetaData>(sender)
        });
        
        
        move_to(sender,Resolvers{
            list : Table::new<vector<u8>, ResolverDetails>()
        });
        move_to(sender,Registry{
            list : Table::new<vector<u8>, RegistryDetails>()
        });
    }

    public fun register (sender:&signer, name: &vector<u8>, registration_duration: u64) acquires Registry, Resolvers, ShardCap{
        assert!( registration_duration >= 60 * 60 * 24 * 180 ,1001);
        assert!( DomainName::is_allow_format_domain_name(name) , 1002);
        assert!( DomainName::dot_number(name) == 1 , 1003);
        let account = Signer::address_of(sender);
        let now_time = Timestamp::now_seconds();
        let name_hash = DomainName::get_domain_name_hash(name);
        let registry = &mut borrow_global_mut<Registry>(@SNSadmin).list;
        let resolvers = &mut borrow_global_mut<Resolvers>(@SNSadmin).list;
        let shardCap = borrow_global_mut<ShardCap>(@SNSadmin);

        let svg = SVG_Header;
        Vector::append(&mut svg, *name);
        Vector::append(&mut svg, SVG_Last);
        let svg_base64 = SVG_Base64_Header;
        Vector::append(&mut svg_base64, Base64::encode(&svg));
        let nft = NFT::mint_with_cap_v2<SNSMetaData,SNSBody>(account, &mut shardCap.mint_cap, NFT::new_meta_with_image(*name,svg_base64,b"Starcoin Name Service"),
            SNSMetaData{
                domain_name         :   *name,
                node                :   copy name_hash,
                create_time         :   now_time,
                expiration_time     :   now_time + registration_duration,
            },
            SNSBody{
                domain      :   Domain{
                    stc_address : account,
                    contents    : Vector::empty(),
                    content     : Table::new<u8, vector<u8>>()
                },
                subDomains  :   SubDomains{
                    subDomainsName     :   Vector::empty(),
                    subDomains         :   Table::new<vector<u8>, SubDomain>()
                }
            }
        );

        //TODO pay some STC

        if(Table::contains(registry, copy name_hash)){
            let registryDetails = Table::borrow_mut(registry, copy name_hash);
            if( registryDetails.expiration_time < now_time){
                registryDetails.expiration_time = now_time + registration_duration;
                registryDetails.id = NFT::get_id(&nft);
            }else{
                abort 10001
            };
        }else{
            Table::add(registry, copy name_hash, RegistryDetails{
                expiration_time   : now_time + registration_duration,
                id                : NFT::get_id(&nft)
            });
        };

        if(Table::contains(resolvers, copy name_hash)){
            let resolverDetails = Table::borrow_mut(resolvers, copy name_hash);
            let owner = *Option::borrow(&resolverDetails.owner);
            let old_nft = IdentifierNFT::revoke<SNSMetaData,SNSBody>(&mut shardCap.burn_cap, owner);
            NFTGallery::deposit_to(owner, old_nft);
            _ = Table::remove(resolvers, copy name_hash);
        }else{
            
        };
        NFTGallery::deposit(sender, nft);
    }

    public fun use_with_config (sender:&signer, id: u64, stc_address: address, contents:&vector<u8>, content:&vector<vector<u8>>) acquires ShardCap,Resolvers,Registry{
        let content_length = Vector::length(content);
        let contents_length = Vector::length(contents);
        
        assert!(content_length == contents_length, 1002);

        
        let shardCap = borrow_global_mut<ShardCap>(@SNSadmin);

        let nft_op = NFTGallery::withdraw<SNSMetaData,SNSBody>(sender, id);

        assert!(Option::is_some(&nft_op),1003);

        let nft = Option::destroy_some(nft_op);

        let nft_meta = NFT::get_type_meta(&nft);
        let name_hash = *&nft_meta.node;
        let now_time = Timestamp::now_seconds();

        let registry = &borrow_global<Registry>(@SNSadmin).list;
        let registryDetails = Table::borrow(registry, copy name_hash);
        if( registryDetails.expiration_time < now_time){
            abort 100132
        };

        let body = NFT::borrow_body_mut_with_cap(&mut shardCap.updata_cap, &mut nft);

        body.domain.stc_address = stc_address;
        
        let i = 0;
        while(i < content_length){
            Table::add(&mut body.domain.content, *Vector::borrow(contents,i), *Vector::borrow(content,i));
            Vector::push_back(&mut body.domain.contents, *Vector::borrow(contents,i));
        };

        IdentifierNFT::grant(&mut shardCap.mint_cap, sender, nft);

        let resolvers = &mut borrow_global_mut<Resolvers>(@SNSadmin).list;
        
        Table::add(resolvers,  name_hash, ResolverDetails{
            owner         : Option::some(stc_address),
            mainDomain    : Option::none<vector<u8>>()
        });
    }
    
    public fun unuse(sender:&signer)acquires ShardCap,Resolvers{
        let resolvers = &mut borrow_global_mut<Resolvers>(@SNSadmin).list;
        
        let account = Signer::address_of(sender);
        let shardCap = borrow_global_mut<ShardCap>(@SNSadmin);
        let nft = IdentifierNFT::revoke<SNSMetaData,SNSBody>(&mut shardCap.burn_cap, account);

        let name_hash = *&NFT::get_type_meta(&nft).node;

        let body = NFT::borrow_body_mut_with_cap(&mut shardCap.updata_cap, &mut nft);

        let content_length = Vector::length(&body.domain.contents);

        let i = 0;
        while(i < content_length){
            _ = Table::remove(&mut body.domain.content, Vector::pop_back(&mut body.domain.contents));
            i = i + 1;
        };
        
        let subDomain_length = Vector::length(&body.subDomains.subDomainsName);
        let i = 0;
        while(i < subDomain_length){
            let SubDomain{
                stc_address : _,  
                contents    : contents,
                content     : content
            } = Table::remove(&mut body.subDomains.subDomains, Hash::keccak_256(Vector::pop_back(&mut body.subDomains.subDomainsName)));
            let j = 0;
            let subDomain_content_length = Vector::length(&contents);
            while(j < subDomain_content_length){
                _ = Table::remove(&mut content,Vector::pop_back(&mut contents));
                j = j + 1;
            };
            Table::destroy_empty(content);
            i = i + 1;
        };

        NFTGallery::deposit_to(account, nft);
        _ = Table::remove(resolvers, copy name_hash);
    }

    public fun resolve_stc_address(node:vector<u8>):address acquires Resolvers, ShardCap {
        let resolvers = &borrow_global<Resolvers>(@SNSadmin).list;
        let shardCap = borrow_global_mut<ShardCap>(@SNSadmin);
        
        if(Table::contains(resolvers, copy node)){
            let resolverDetails = Table::borrow(resolvers, copy node);

            if(Option::is_none(&resolverDetails.owner)){
                if(Option::is_none(&resolverDetails.mainDomain)){
                    
                }else{
                    let mainDomain_node = *Option::borrow(&resolverDetails.mainDomain);
                    let r = Table::borrow(resolvers, mainDomain_node);
                    let owner = *Option::borrow(&r.owner);
                    return owner
                };
            }else{
                let owner = *Option::borrow(&resolverDetails.owner);
                let box_nft =  IdentifierNFT::borrow_out<SNSMetaData,SNSBody>(&mut shardCap.updata_cap, owner);
                let nft = IdentifierNFT::borrow_nft(&mut box_nft);
                
                let body = NFT::borrow_body(nft);
                let stc_address = body.domain.stc_address;
                IdentifierNFT::return_back(box_nft);
                return stc_address
            };

        };
        abort 1012
    }

}

module SNSadmin::SNStestscript{
    use SNSadmin::SNS1;
    use SNSadmin::DomainName;
    use StarcoinFramework::Signer;
    use StarcoinFramework::Vector;

    public (script) fun init(sender:signer){
        SNS1::init(&sender);
    }

    public (script) fun register(sender:signer, name: vector<u8>, registration_duration: u64){
        SNS1::register(&sender, &name, registration_duration);
    }

    public (script) fun use_with_config (sender:signer, id: u64, stc_address: address, contents:vector<u8>, content:vector<vector<u8>>){
        SNS1::use_with_config(&sender,id,stc_address,&contents,&content);
    }

    public (script) fun use_default (sender:signer, id: u64){
        SNS1::use_with_config(&sender,id,Signer::address_of(&sender),&Vector::empty<u8>(),&Vector::empty<vector<u8>>());
    }

    public (script) fun unuse(sender:signer){
        SNS1::unuse(&sender);
    }

    public fun resolve_4_name(name:vector<u8>):address{
        SNS1::resolve_stc_address(DomainName::get_domain_name_hash(&name))
    }

    public fun resolve_4_node(node:vector<u8>):address{
        SNS1::resolve_stc_address(node)
    }
}