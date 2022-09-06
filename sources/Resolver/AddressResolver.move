module SNSadmin::AddressResolver{

    use StarcoinFramework::Table;
    use StarcoinFramework::Option;
    use StarcoinFramework::Vector;
    use SNSadmin::Config;

    friend SNSadmin::StarcoinNameServiceScript;

    struct Resolver<phantom Root: store> has key, store{
        list :  Table::Table<vector<u8>, AddressRecord>
    }

    struct AddressRecord has key,store{
        addresses :     Table::Table<vector<u8>,vector<u8>> ,
        all       :     vector<vector<u8>>
    }

    struct AddressRecordAllow<phantom ROOT> has key,store {
        list :  Table::Table<vector<u8> , AddressRecordAllowBox> ,
        all  :  vector<vector<u8>>
    }

    struct AddressRecordAllowBox has key,store{
        list : Table::Table<u64,bool>,
        all  : vector<u64>
    }

    public fun init<ROOT: store>(sender:&signer){
        assert!(Config::is_creater_by_signer(sender), 10012);

        move_to(sender,Resolver<ROOT>{
            list : Table::new<vector<u8>, AddressRecord>()
        });

        move_to(sender,AddressRecordAllow<ROOT>{
            list :  Table::new<vector<u8>, AddressRecordAllowBox>(),
            all  :  Vector::empty<vector<u8>>()
        });
    }

    public (friend) fun change_address<ROOT: store>(hash: &vector<u8>, addr_name:&vector<u8>, addr:&vector<u8>):Option::Option<vector<u8>> acquires AddressRecordAllow, Resolver{
        if(Vector::length(addr) == 0){
            remove_address<ROOT>(hash, addr_name);
            return Option::none<vector<u8>>()
        };

        assert!(is_allow_address_record<ROOT>(addr_name, addr),10013);
        let resolver = &mut borrow_global_mut<Resolver<ROOT>>(Config::creater()).list;
        if(Table::contains(resolver, *hash)){
            let address_record = Table::borrow_mut(resolver, *hash);
            if(Table::contains(&mut address_record.addresses, *addr_name)){
                let old_addr = Table::borrow_mut(&mut address_record.addresses, *addr_name) ;
                let op_addr = Option::some(*old_addr);
                *old_addr = *addr;
                op_addr
            }else{
                Table::add(&mut address_record.addresses, *addr_name, *addr);
                Vector::push_back(&mut address_record.all, *addr_name);
                Option::none<vector<u8>>()
            }
        }else{
            Table::add(resolver, *hash, AddressRecord{
                addresses : Table::new<vector<u8>, vector<u8>>(),
                all       : Vector::empty<vector<u8>>()
            });
            let address_record = Table::borrow_mut(resolver, *hash);
            Table::add(&mut address_record.addresses, *addr_name, *addr);
            Vector::push_back(&mut address_record.all, *addr_name);
            Option::none<vector<u8>>()
        }
    }

    public (friend) fun remove_address<ROOT: store>(hash: &vector<u8> , addr_name:&vector<u8>):Option::Option<vector<u8>> acquires Resolver{
        let resolver = &mut borrow_global_mut<Resolver<ROOT>>(Config::creater()).list;
        if(Table::contains(resolver, *hash)){
            let address_record = Table::borrow_mut(resolver, *hash);
            if(Table::contains(&mut address_record.addresses, *addr_name)){
                let addr = Table::remove(&mut address_record.addresses, *addr_name);
                let (_ , index) = Vector::index_of(&address_record.all, addr_name);
                Vector::remove(&mut address_record.all, index);
                Option::some(addr)
            }else{
                Option::none<vector<u8>>()
            }
        }else{
            Option::none<vector<u8>>()
        }   
    }

    public (friend) fun remove_record<ROOT: store>(hash: &vector<u8>) acquires Resolver{
        let resolver = &mut borrow_global_mut<Resolver<ROOT>>(Config::creater()).list;
        if(Table::contains(resolver, *hash)){
            let address_record = Table::borrow_mut(resolver, *hash);
            let length = Vector::length(&address_record.all);
            let i = 0;
            while(i < length){
                let addr_name = Vector::remove(&mut address_record.all, 0);
                Table::remove(&mut address_record.addresses, addr_name);
                i = i + 1;
            };
        }else{
           
        };
    }

    public fun is_allow_address_record<ROOT: store>(name:&vector<u8>, addr:&vector<u8>):bool acquires AddressRecordAllow{
        let list = &borrow_global<AddressRecordAllow<ROOT>>(Config::creater()).list;

        if(Table::contains(list, *name)){
            let addr_len  =  Vector::length(addr);
            Table::contains(&Table::borrow(list, *name).list, addr_len) 
        }else{
            false
        }
    }

    public fun add_allow_address_record<ROOT: store>(sender:&signer, name:&vector<u8>,len:u64)acquires AddressRecordAllow{
        assert!(Config::is_admin_by_signer<ROOT>(sender), 10012);
        let allow = borrow_global_mut<AddressRecordAllow<ROOT>>(Config::creater());
        let list = &mut allow.list;

        if(Table::contains(list, *name)){
            let box = Table::borrow_mut(list, *name);
            if(! Table::contains(&box.list, len)){
                Table::add(&mut box.list, len, true);
                Vector::push_back(&mut box.all, len);
            }
        }else{
            let len_list = Table::new<u64,bool>();
            Table::add(&mut len_list, len , true);
            let vec = Vector::empty<u64>();
            Vector::push_back(&mut vec, len);

            
            Table::add(list, *name, AddressRecordAllowBox{
                list : len_list,
                all  : vec
            });

            Vector::push_back(&mut allow.all, *name)
        }
    }

    public fun remove_allow_address_record<ROOT: store>(sender:&signer,name:&vector<u8>,len:u64)acquires AddressRecordAllow{
        assert!(Config::is_admin_by_signer<ROOT>(sender), 10012);
        let allow = borrow_global_mut<AddressRecordAllow<ROOT>>(Config::creater());
        let list = &mut allow.list;

        if(Table::contains(list, *name)){
            let box = Table::borrow_mut(list, *name);
            if(Table::contains(&box.list, len)){
                Table::remove(&mut box.list, len);
                let (_ , index) = Vector::index_of(&box.all, &len);
                Vector::remove(&mut box.all, index);
            }
        }
    }

    public fun remove_all_allow_address_record_len<ROOT: store>(sender:&signer,name:&vector<u8>)acquires AddressRecordAllow{
        
        assert!(Config::is_admin_by_signer<ROOT>(sender), 10012);
        let allow = borrow_global_mut<AddressRecordAllow<ROOT>>(Config::creater());
        let list = &mut allow.list;

        if(Table::contains(list, *name)){
            let AddressRecordAllowBox{
                list,
                all
            } = Table::remove(list, *name);
            let length = Vector::length(&all);
            let i = 0;
            while(i < length){
                Table::remove(&mut list, *Vector::borrow(&all, i));
                i = i + 1;
            };
            Table::destroy_empty(list);
        }
    }

    public fun remove_all_allow_address_record<ROOT: store>(sender:&signer)acquires AddressRecordAllow{
        assert!(Config::is_admin_by_signer<ROOT>(sender), 10012);
        let allow = borrow_global_mut<AddressRecordAllow<ROOT>>(Config::creater());
        let allow_list = &mut allow.list;

        let j = 0;
        let len = Vector::length(&allow.all);
        while(j < len){
            let name = Vector::borrow(&allow.all, j);
            if(Table::contains(allow_list, *name)){
                let AddressRecordAllowBox{
                    list,
                    all
                } = Table::remove(allow_list, *name);
                let length = Vector::length(&all);
                let i = 0;
                while(i < length){
                    Table::remove(&mut list, *Vector::borrow(&all, i));
                    i = i + 1;
                };
                Table::destroy_empty(list);
            };
            j = j + 1;
        };
    }

    //Read 
    public fun get_address_record<ROOT: store>(hash: &vector<u8>, addr_name:&vector<u8>):Option::Option<vector<u8>> acquires Resolver{
        let resolver = & borrow_global<Resolver<ROOT>>(Config::creater()).list;
        if(Table::contains(resolver, *hash)){
            let address_record = Table::borrow(resolver, *hash);
            if(Table::contains(&address_record.addresses, *addr_name)){
                Option::some(*Table::borrow(&address_record.addresses,*addr_name))
            }else{
                Option::none<vector<u8>>()
            }
        }else{
            Option::none<vector<u8>>()
        }
    }

    public fun get_all_allow_address<ROOT:store>():vector<vector<u8>> acquires AddressRecordAllow{
        let allow = borrow_global_mut<AddressRecordAllow<ROOT>>(Config::creater());
        *&allow.all
    }
}