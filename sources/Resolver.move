module SNSadmin::resolver{

    use StarcoinFramework::Table;
    use StarcoinFramework::Option;
    use StarcoinFramework::Signer;

    struct Resolver<phantom Root: store, phantom T: drop + copy + store> has key, store{
        list :  Table::Table<vector<u8>, T>
    }

    public fun init<ROOT: store, T: drop + copy + store>(sender:&signer){
        let account = Signer::address_of(sender);
        assert!(account == @SNSadmin,10012);
        
        move_to(sender, Resolver<ROOT, T>{
            list : Table::new<vector<u8>, T>(),
        });
    }
    
    public (friend) fun change<ROOT: store, T: drop + copy + store>(hash: &vector<u8>, t: T) acquires Resolver{
        let resolver = &mut borrow_global_mut<Resolver<ROOT, T>>(@SNSadmin).list;
        
        if(Table::contains(resolver, *hash)){
            *Table::borrow_mut(resolver, *hash) = t;
        }else{
            Table::add(resolver, *hash, t);
        };
    }

    public (friend) fun delete<ROOT: store, T: drop + copy + store>(hash: &vector<u8>):Option::Option<T> acquires Resolver{
        let resolver = &mut borrow_global_mut<Resolver<ROOT, T>>(@SNSadmin).list;
        
        if(Table::contains(resolver, *hash)){
            Option::some(Table::remove(resolver, *hash))
        }else{
            Option::none<T>()
        }
    }

    public fun get_t_by_hash<ROOT: store, T: drop + copy + store>(hash: &vector<u8>):Option::Option<T> acquires Resolver{
        let resolver = & borrow_global<Resolver<ROOT, T>>(@SNSadmin).list;
        
        if(Table::contains(resolver, *hash)){
            Option::some(*Table::borrow(resolver, *hash))
        }else{
            Option::none<T>()
        }
    }

}