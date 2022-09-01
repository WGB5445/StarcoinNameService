module SNSadmin::StarcoinNameService{
    // use StarcoinFramework::Table;
    use StarcoinFramework::Vector;
    use StarcoinFramework::Signer;
    use StarcoinFramework::Timestamp;
    use StarcoinFramework::NFT;
    use StarcoinFramework::Option::{Self,Option};
    use StarcoinFramework::IdentifierNFT;
    use StarcoinFramework::NFTGallery;
    // use StarcoinFramework::Account;
    // use StarcoinFramework::Math;
    // use StarcoinFramework::Hash;
    use SNSadmin::DomainNameASCII as DomainName;
    use SNSadmin::ASCII;
    use SNSadmin::Registrar;
    use SNSadmin::Resolver;
    use SNSadmin::NameServiceNFT::{Self,SNSMetaData,SNSBody};
 
    // use SNSadmin::Record1 as Record;
    
    friend SNSadmin::StarcoinNameServiceScript;

    // public fun add_root(sender:&signer, root:&vector<u8>)acquires RootList{
    //     let account = Signer::address_of(sender);
    //     assert!(account == Config::creater(),10012);
    //     let roots = &mut borrow_global_mut<RootList>(Config::creater()).roots;
    //     Table::add(roots, *root, Root{
    //         registry :Table::new<vector<u8>, RegistryDetails>(),
    //         resolvers :Table::new<vector<u8>, ResolverDetails>()
    //     });
    // }

    public (friend) fun register<ROOT: store>(sender:&signer, name: &vector<u8>, root_name:&vector<u8>, registration_duration: u64){
        assert!( registration_duration >= 60 * 60 * 24 * 180 ,1001);

        assert!( DomainName::dot_number(name) == 0 , 1003);
        let account = Signer::address_of(sender);

        let char_length = ASCII::length(&ASCII::string(name));
        assert!( (char_length > 3) && (char_length < 20), 1300 );

        let now_time = Timestamp::now_seconds();
        let name_hash = DomainName::get_name_hash_2(root_name, name);
    
        let domain_name = *name;
        Vector::append(&mut domain_name, b".");
        Vector::append(&mut domain_name, *root_name);
    
        //TODO pay some STC
        let op_registryDetails = Registrar::get_details_by_hash<ROOT>(&name_hash);
        if(Option::is_some(&op_registryDetails)){
            let registryDetails = Option::destroy_some(op_registryDetails);
            if(Registrar::get_expiration_time(&registryDetails) < now_time){
                
            }else{
                abort 10001
            }
        };
        let nft = NameServiceNFT::mint<ROOT>(account, name, root_name, now_time, now_time + registration_duration);
        Registrar::change<ROOT>(&name_hash, now_time + registration_duration, NFT::get_id(&nft));
        
        Resolver::change<ROOT>(&name_hash, account);

        NFTGallery::deposit(sender, nft);
    }

    // //TODO : remove stc_address
    public (friend) fun use_domain<ROOT: store> (sender:&signer, id: u64) {
        let nft_op = NFTGallery::withdraw<SNSMetaData<ROOT>,SNSBody>(sender, id);

        assert!(Option::is_some(&nft_op),1003);

        let nft = Option::destroy_some(nft_op);

        let id = NFT::get_id(&nft);
        let nft_meta = NFT::get_type_meta(&nft);

        let name_hash = DomainName::get_name_hash_2(&NameServiceNFT::get_parent(nft_meta), &NameServiceNFT::get_domain_name(nft_meta));

        let op_registryDetails = Registrar::get_details_by_hash<ROOT>(&name_hash);
        if(Option::is_some(&op_registryDetails)){
            let registryDetails = Option::destroy_some(op_registryDetails);
            if(Registrar::get_id(&registryDetails) == id){
                
            }else{
                abort 10024
            }
        }else{
            abort 30000
        };
        
        NameServiceNFT::grant(sender, nft);

        Resolver::change<ROOT>(&name_hash, Signer::address_of(sender));
    }

    public (friend) fun unuse_domain<ROOT: store> (sender:&signer) {
        let account = Signer::address_of(sender);
        let nft = NameServiceNFT::revoke<ROOT>(account);
        NFTGallery::deposit(sender, nft);
    }

    public fun change_stc_address<ROOT: store>(sender:&signer, id:Option<u64>, addr:address){
        let account = Signer::address_of(sender);
        let (nft_id,nft_meta) = if( Option::is_none(&id)){
            // let op_info = IdentifierNFT::get_nft_info<SNSMetaData<ROOT>,SNSBody>(account);
            // assert!(Option::is_some(&op_info),102123);
            // let info = Option::destroy_some(op_info);
            // let (nft_id,_,_,nft_meta) = NFT::unpack_info(info);
            // (nft_id, nft_meta)
            abort 20303
        }else{
            let nft_id = *Option::borrow(&id);
            let op_info = NFTGallery::get_nft_info_by_id<SNSMetaData<ROOT>,SNSBody>(account, nft_id);
            assert!(Option::is_some(&op_info),102123);
            let info = Option::destroy_some(op_info);
            let (nft_id,_,_,nft_meta) = NFT::unpack_info(info);
            (nft_id, nft_meta)
        };

        let name_hash = DomainName::get_name_hash_2(&NameServiceNFT::get_parent(&nft_meta), &NameServiceNFT::get_domain_name(&nft_meta));
        
        let op_registryDetails = Registrar::get_details_by_hash<ROOT>(&name_hash);
        if(Option::is_some(&op_registryDetails)){
            let registryDetails = Option::destroy_some(op_registryDetails);
            if(Registrar::get_id(&registryDetails) != nft_id){
                abort 10001
            }else{
                
            }
        }else{
            abort 10002
        };

        Resolver::change<ROOT>(&name_hash, addr);
    }


    // public fun add_Record_address(sender:&signer,name:&vector<u8>,addr:&vector<u8>)acquires RootList{
    //     let account = Signer::address_of(sender);
    //     let op_info = IdentifierNFT::get_nft_info<SNSMetaData,SNSBody>(account);
    //     assert!(Option::is_some(&op_info),102123);
    //     let info = Option::destroy_some(op_info);
    //     let (id,_,_,nft_meta) = NFT::unpack_info(info);
    //     let name_hash = DomainName::get_name_hash_2(&nft_meta.parent, &nft_meta.domain_name);
        
    //     let roots = &mut borrow_global_mut<RootList>(Config::creater()).roots;
    //     assert!(Table::contains(roots, *&nft_meta.parent),10000);
    //     let root = Table::borrow_mut(roots, *&nft_meta.parent);

    //     if(Table::contains(&root.registry, copy name_hash)){
    //         let registryDetails = Table::borrow_mut(&mut root.registry, copy name_hash);
    //         if( registryDetails.id != id ){
    //             abort 10001
    //         }
    //     }else{
    //         abort 10002
    //     };

    //     if(Table::contains(&root.resolvers, copy name_hash)){
    //         let addressRecord = &mut Table::borrow_mut(&mut root.resolvers, copy name_hash).addressRecord;
    //         Record::change_address_record( addressRecord,name,addr)
    //     }else{
    //         abort 100012
    //     };


    // }

    // public fun change_Record_address(sender:&signer,id:Option<u64>,name:&vector<u8>,addr:&vector<u8>)acquires RootList{
    //     let account = Signer::address_of(sender);
    //     let (nft_id,nft_meta) = if( Option::is_none(&id)){
    //         let op_info = IdentifierNFT::get_nft_info<SNSMetaData,SNSBody>(account);
    //         assert!(Option::is_some(&op_info),102123);
    //         let info = Option::destroy_some(op_info);
    //         let (nft_id,_,_,nft_meta) = NFT::unpack_info(info);
    //         (nft_id, nft_meta)
    //     }else{
    //         let nft_id = *Option::borrow(&id);
    //         let op_info = NFTGallery::get_nft_info_by_id<SNSMetaData,SNSBody>(account, nft_id);
    //         assert!(Option::is_some(&op_info),102123);
    //         let info = Option::destroy_some(op_info);
    //         let (nft_id,_,_,nft_meta) = NFT::unpack_info(info);
    //         (nft_id, nft_meta)
    //     };

    //     let name_hash = DomainName::get_name_hash_2(&nft_meta.parent, &nft_meta.domain_name);
        
    //     let roots = &mut borrow_global_mut<RootList>(Config::creater()).roots;
    //     assert!(Table::contains(roots, *&nft_meta.parent),10000);
    //     let root = Table::borrow_mut(roots, *&nft_meta.parent);

    //     if(Table::contains(&root.registry, copy name_hash)){
    //         let registryDetails = Table::borrow_mut(&mut root.registry, copy name_hash);
    //         if( registryDetails.id != nft_id ){
    //             abort 10001
    //         }
    //     }else{
    //         abort 10002
    //     };

    //     if(Table::contains(&root.resolvers, copy name_hash)){
    //         let addressRecord = &mut Table::borrow_mut(&mut root.resolvers, copy name_hash).addressRecord;
    //         Record::change_address_record( addressRecord,name,addr)
    //     }else{
    //         abort 100012
    //     };


    // }



    // public fun unuse(sender:&signer)acquires ShardCap{
    //     // let roots = &mut borrow_global_mut<RootList>(Config::creater()).roots;
        
    //     let account = Signer::address_of(sender);
    //     let shardCap = borrow_global_mut<ShardCap>(Config::creater());
    //     let nft = IdentifierNFT::revoke<SNSMetaData,SNSBody>(&mut shardCap.burn_cap, account);

    //     // let nft_meta = NFT::get_type_meta(&nft);
    //     // let root = Table::borrow_mut(roots, *&nft_meta.parent);
    //     // let name_hash = DomainName::get_name_hash_2(&nft_meta.parent, &nft_meta.domain_name);

    //     NFTGallery::deposit_to(account, nft);
    //     // let ResolverDetails{
    //     //         mainDomain:_mainDomain         ,
    //     //         stc_address:_stc_address        ,
    //     //         addressRecord      
    //     //     } = Table::remove(&mut root.resolvers, copy name_hash);
    //     // Record::destroy_address_record(addressRecord);
    // }

    public fun resolve_stc_address<T: store>(name_hash:&vector<u8>):address {
        let op_addr = Resolver::get_address_by_hash<T>(name_hash);
        assert!(Option::is_some(&op_addr) ,1012);
        Option::destroy_some(op_addr)
    }

    public fun resolve_domain_name<ROOT: store>(addr: address):vector<u8>{
        let op_info = IdentifierNFT::get_nft_info<SNSMetaData<ROOT>,SNSBody>(addr);
        assert!(Option::is_some(&op_info),102123);
        let info = Option::destroy_some(op_info);
        let (nft_id,_,base_meta,nft_meta) = NFT::unpack_info(info);

        let name_hash = DomainName::get_name_hash_2(&NameServiceNFT::get_parent(&nft_meta), &NameServiceNFT::get_domain_name(&nft_meta));
        
        let op_registryDetails = Registrar::get_details_by_hash<ROOT>(&name_hash);
        if(Option::is_some(&op_registryDetails)){
            let registryDetails = Option::destroy_some(op_registryDetails);
            if(Registrar::get_id(&registryDetails) != nft_id){
                abort 10001
            }else{
                
            }
        }else{
            abort 10002
        };
        NFT::meta_name(&base_meta)
    }

    

    // public fun resolve_record_address(node:&vector<u8>, root_name:&vector<u8>,name:&vector<u8>):vector<u8> acquires RootList {
    
    //     let roots = &mut borrow_global_mut<RootList>(Config::creater()).roots;
    //     let root = Table::borrow_mut(roots, *root_name);
    //     if(Table::contains(&root.resolvers, *node)){
    //         let resolverDetails = Table::borrow(&root.resolvers, *node);

    //         if(Option::is_none(&resolverDetails.mainDomain)){
    //             let op_addr = Record::get_address_record(&resolverDetails.addressRecord, name);
    //             assert!(Option::is_some(&op_addr),123124);
    //             return Option::destroy_some(op_addr)
    //         }else{
    //             let mainDomain_node = *Option::borrow(&resolverDetails.mainDomain);
    //             let op_addr = Record::get_address_record(&Table::borrow(&root.resolvers, mainDomain_node).addressRecord, name);
    //             assert!(Option::is_some(&op_addr),123124);
    //             return Option::destroy_some(op_addr)
    //         }
    //     };
    //     abort 1012
    // }

    // public fun burn(sender:&signer,id: u64)acquires ShardCap,RootList{
    //     let roots = &mut borrow_global_mut<RootList>(Config::creater()).roots;

    //     let shardCap = borrow_global_mut<ShardCap>(Config::creater());

    //     let nft_op = NFTGallery::withdraw<SNSMetaData,SNSBody>(sender, id);

    //     assert!(Option::is_some(&nft_op),1003);

    //     let nft = Option::destroy_some(nft_op);
    //     let id =NFT::get_id(&nft);
    //     let nft_meta = NFT::get_type_meta(&nft);
 
    //     let root = Table::borrow_mut(roots, *&nft_meta.parent);
    //     let name_hash = DomainName::get_name_hash_2(&nft_meta.parent, &nft_meta.domain_name);
    //     let registryDetails = Table::borrow(&root.registry, copy name_hash);
    //     if( registryDetails.id == id){
    //     //    abort 2341
    //         let ResolverDetails{
    //             mainDomain:_mainDomain         ,
    //             stc_address:_stc_address        ,
    //             addressRecord      
    //         } = Table::remove(&mut root.resolvers, copy name_hash);
    //         Record::destroy_address_record(addressRecord);
    //     };
        
    //     SNSBody{} = NFT::burn_with_cap(&mut shardCap.burn_cap, nft);
    //     // let ResolverDetails{
    //     //         mainDomain:_mainDomain         ,
    //     //         stc_address:_stc_address        ,
    //     //         addressRecord      
    //     //     } = Table::remove(&mut root.resolvers, copy name_hash);
    //     // Record::destroy_address_record(addressRecord);
    // }
}





