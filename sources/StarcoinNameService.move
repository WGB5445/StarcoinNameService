module SNSadmin::starcoin_name_service{
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
    use SNSadmin::DomainName;
    // use SNSadmin::Base64;
    use SNSadmin::registrar;
    use SNSadmin::root;
    use SNSadmin::resolver;
    use SNSadmin::name_service_nft::{Self,SNSMetaData,SNSBody};
    // use SNSadmin::Record1 as Record;
    

    // public fun add_root(sender:&signer, root:&vector<u8>)acquires RootList{
    //     let account = Signer::address_of(sender);
    //     assert!(account == @SNSadmin,10012);
    //     let roots = &mut borrow_global_mut<RootList>(@SNSadmin).roots;
    //     Table::add(roots, *root, Root{
    //         registry :Table::new<vector<u8>, RegistryDetails>(),
    //         resolvers :Table::new<vector<u8>, ResolverDetails>()
    //     });
    // }

    public fun register (sender:&signer, name: &vector<u8>, root_name:&vector<u8>, registration_duration: u64){
        assert!( registration_duration >= 60 * 60 * 24 * 180 ,1001);

        assert!( DomainName::dot_number(name) == 0 , 1003);
        let account = Signer::address_of(sender);

        let now_time = Timestamp::now_seconds();
        let name_hash = DomainName::get_name_hash_2(root_name, name);
    
        let domain_name = *name;
        Vector::append(&mut domain_name, b".");
        Vector::append(&mut domain_name, *root_name);
    
        //TODO pay some STC
        let op_registryDetails = registrar::get_details_by_hash<root::STC>(&name_hash);
        if(Option::is_some(&op_registryDetails)){
            let registryDetails = Option::destroy_some(op_registryDetails);
            if(registrar::get_expiration_time(&registryDetails) < now_time){
                
            }else{
                abort 10001
            }
        };
        let nft = name_service_nft::mint<root::STC>(account, name, root_name, now_time, now_time + registration_duration);
        registrar::change<root::STC>(&name_hash, now_time + registration_duration, NFT::get_id(&nft));
        
        resolver::change<root::STC>(&name_hash, account);

        NFTGallery::deposit(sender, nft);
    }

    // //TODO : remove stc_address
    // public fun use_domain (sender:&signer, id: u64, _stc_address: address) acquires ShardCap,RootList{
    //     let roots = &mut borrow_global_mut<RootList>(@SNSadmin).roots;

    //     let shardCap = borrow_global_mut<ShardCap>(@SNSadmin);

    //     let nft_op = NFTGallery::withdraw<SNSMetaData,SNSBody>(sender, id);

    //     assert!(Option::is_some(&nft_op),1003);

    //     let nft = Option::destroy_some(nft_op);

    //     let id =NFT::get_id(&nft);
    //     let nft_meta = NFT::get_type_meta(&nft);
    //     let root;
    //     if(Table::contains(roots, *&nft_meta.parent)){
    //         root = Table::borrow_mut(roots, *&nft_meta.parent);
    //     }else{
    //         abort 10000
    //     };
        
    //     let name_hash = DomainName::get_name_hash_2(&nft_meta.parent, &nft_meta.domain_name);

    //     if(Table::contains(&root.registry, copy name_hash)){
    //         let registryDetails = Table::borrow_mut(&mut root.registry, copy name_hash);
    //         if( registryDetails.id != id ){
    //             abort 10001
    //         }
    //     }else{
    //         abort 10002
    //     };
        
    //     IdentifierNFT::grant(&mut shardCap.mint_cap, sender, nft);
    // }
    
    public fun change_stc_address(sender:&signer, id:Option<u64>, addr:address){
        let account = Signer::address_of(sender);
        let (nft_id,nft_meta) = if( Option::is_none(&id)){
            let op_info = IdentifierNFT::get_nft_info<SNSMetaData<root::STC>,SNSBody>(account);
            assert!(Option::is_some(&op_info),102123);
            let info = Option::destroy_some(op_info);
            let (nft_id,_,_,nft_meta) = NFT::unpack_info(info);
            (nft_id, nft_meta)
        }else{
            let nft_id = *Option::borrow(&id);
            let op_info = NFTGallery::get_nft_info_by_id<SNSMetaData<root::STC>,SNSBody>(account, nft_id);
            assert!(Option::is_some(&op_info),102123);
            let info = Option::destroy_some(op_info);
            let (nft_id,_,_,nft_meta) = NFT::unpack_info(info);
            (nft_id, nft_meta)
        };

        let name_hash = DomainName::get_name_hash_2(&name_service_nft::get_parent(&nft_meta), &name_service_nft::get_domain_name(&nft_meta));
        
        let op_registryDetails = registrar::get_details_by_hash<root::STC>(&name_hash);
        if(Option::is_some(&op_registryDetails)){
            let registryDetails = Option::destroy_some(op_registryDetails);
            if(registrar::get_id(&registryDetails) != nft_id){
                
            }else{
                abort 10001
            }
        }else{
            abort 10002
        };

        resolver::change<root::STC>(&name_hash, addr);
    }


    // public fun add_Record_address(sender:&signer,name:&vector<u8>,addr:&vector<u8>)acquires RootList{
    //     let account = Signer::address_of(sender);
    //     let op_info = IdentifierNFT::get_nft_info<SNSMetaData,SNSBody>(account);
    //     assert!(Option::is_some(&op_info),102123);
    //     let info = Option::destroy_some(op_info);
    //     let (id,_,_,nft_meta) = NFT::unpack_info(info);
    //     let name_hash = DomainName::get_name_hash_2(&nft_meta.parent, &nft_meta.domain_name);
        
    //     let roots = &mut borrow_global_mut<RootList>(@SNSadmin).roots;
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
        
    //     let roots = &mut borrow_global_mut<RootList>(@SNSadmin).roots;
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
    //     // let roots = &mut borrow_global_mut<RootList>(@SNSadmin).roots;
        
    //     let account = Signer::address_of(sender);
    //     let shardCap = borrow_global_mut<ShardCap>(@SNSadmin);
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

    public fun resolve_stc_address(name_hash:&vector<u8>, _root_name:&vector<u8>):address {
    
        let op_addr = resolver::get_address_by_hash<root::STC>(name_hash);
        assert!(Option::is_some(&op_addr) ,1012);
        Option::destroy_some(op_addr)
    }

    // public fun resolve_record_address(node:&vector<u8>, root_name:&vector<u8>,name:&vector<u8>):vector<u8> acquires RootList {
    
    //     let roots = &mut borrow_global_mut<RootList>(@SNSadmin).roots;
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
    //     let roots = &mut borrow_global_mut<RootList>(@SNSadmin).roots;

    //     let shardCap = borrow_global_mut<ShardCap>(@SNSadmin);

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
/*
module SNSadmin::SNStestscript6{
    use SNSadmin::SNS6 as SNS;
    use SNSadmin::DomainName;
    use StarcoinFramework::Signer;
    use StarcoinFramework::Option;


    public (script) fun registrar(sender:signer, name: vector<u8>, root: vector<u8>,registration_duration: u64){
        SNS::registrar(&sender, &name, &root, registration_duration);
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

    public (script)fun change_stc_address(sender:signer,addr:address){
        SNS::change_stc_address(&sender,Option::none<u64>(),addr);
    }

    public (script)fun change_NFTGallery_stc_address(sender:signer,id:u64,addr:address){
        SNS::change_stc_address(&sender,Option::some(id),addr);
    }

    public (script)fun add_Record_address(sender:signer,name:vector<u8>,addr:vector<u8>){
        SNS::change_Record_address(&sender,Option::none<u64>(),&name,&addr);
    }

    public (script)fun change_NFTGallery_Record_address(sender:signer,id:u64,name:vector<u8>,addr:vector<u8>){
        SNS::change_Record_address(&sender,Option::some(id),&name,&addr);
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
*/