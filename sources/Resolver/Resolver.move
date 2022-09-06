module SNSadmin::Resolver{

    use StarcoinFramework::Table;
    use StarcoinFramework::Option;
    use SNSadmin::Config;
 

    friend SNSadmin::StarcoinNameService;

    struct Resolver<phantom Root: store> has key, store{
        list :  Table::Table<vector<u8>, address>
    }

    public fun init<ROOT: store>(sender:&signer){
        assert!(Config::is_creater_by_signer(sender), 10012);
        
        move_to(sender, Resolver<ROOT>{
            list : Table::new<vector<u8>, address>(),
        });
    }
    
    public (friend) fun change<ROOT: store>(hash: &vector<u8>, addr: address) acquires Resolver{
        let resolver = &mut borrow_global_mut<Resolver<ROOT>>(Config::creater()).list;
        
        if(Table::contains(resolver, *hash)){
            *Table::borrow_mut(resolver, *hash) = addr;
        }else{
            Table::add(resolver, *hash, addr);
        };
    }

    public (friend) fun delete<ROOT: store>(hash: &vector<u8>):Option::Option<address> acquires Resolver{
        let resolver = &mut borrow_global_mut<Resolver<ROOT>>(Config::creater()).list;
        
        if(Table::contains(resolver, *hash)){
            Option::some(Table::remove(resolver, *hash))
        }else{
            Option::none<address>()
        }
    }

    public fun get_address_by_hash<ROOT: store>(hash: &vector<u8>):Option::Option<address> acquires Resolver{
        let resolver = & borrow_global<Resolver<ROOT>>(Config::creater()).list;
        
        if(Table::contains(resolver, *hash)){
            Option::some(*Table::borrow(resolver, *hash))
        }else{
            Option::none<address>()
        }
    }

}