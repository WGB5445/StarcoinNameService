module SNSadmin::registrar{

    use StarcoinFramework::Table;
    use StarcoinFramework::Signer;
    use StarcoinFramework::Option;
    
    friend SNSadmin::starcoin_name_service;

    struct Registry<phantom ROOT> has key,store{
        list :  Table::Table<vector<u8>, RegistryDetails>
    }

    struct RegistryDetails has store, copy, drop{
        expiration_time   : u64,
        id                : u64
    }

    public fun init<ROOT: store>(sender:&signer){
        let account = Signer::address_of(sender);
        assert!(account == @SNSadmin,10012);
        
        move_to(sender, Registry<ROOT>{
            list : Table::new<vector<u8>, RegistryDetails>(),
        });
    }

    public (friend) fun change<ROOT: store> (hash:&vector<u8>, expiration_time: u64, id: u64)acquires Registry{
        let registry = &mut borrow_global_mut<Registry<ROOT>>(@SNSadmin).list;
        
        if(Table::contains(registry, *hash)){
            let registryDetails = Table::remove(registry, *hash);
            registryDetails.expiration_time = expiration_time;
            registryDetails.id = id;
        }else{
            Table::add(registry, *hash, RegistryDetails{
                expiration_time   : expiration_time,
                id                : id
            });
        };
    }

    public (friend) fun delete<ROOT: store> (hash:&vector<u8>):(u64,u64)acquires Registry{
        let registry = &mut borrow_global_mut<Registry<ROOT>>(@SNSadmin).list;
        
        if(Table::contains(registry, *hash)){
            let registryDetails = Table::borrow_mut(registry, *hash);
            ( registryDetails.expiration_time, registryDetails.id )
        }else{
            abort 120001
        }
    }

    // Read 
    public fun get_details_by_hash<ROOT: store>(hash:&vector<u8>):Option::Option<RegistryDetails> acquires Registry{
        let registry = & borrow_global<Registry<ROOT>>(@SNSadmin).list;
        if(Table::contains(registry, *hash)){
            let registryDetails = Table::borrow(registry, *hash);
            Option::some(*registryDetails)
        }else{
            Option::none<RegistryDetails>()
        }
    }

    public fun get_expiration_time(obj:&RegistryDetails):u64{
        obj.expiration_time
    }

    public fun get_id(obj:&RegistryDetails):u64{
        obj.id
    }

}