module SNSadmin::ContentResolver{
    use StarcoinFramework::Table;
    use StarcoinFramework::Option;
    use StarcoinFramework::Vector;
    use SNSadmin::Config;

    friend SNSadmin::StarcoinNameServiceScript;
    
    struct Resolver<phantom ROOT: store> has key, store{
        list :  Table::Table<vector<u8>, ContentRecord>
    }

    struct ContentRecord has key,store{
        contents :     Table::Table<vector<u8>,vector<u8>> ,
        all      :  vector<vector<u8>>
    }

    struct ContentRecordAllow<phantom ROOT: store> has key,store {
        list :  Table::Table<vector<u8> , u64> ,
        all  :  vector<vector<u8>>
    }

    public fun init<ROOT: store>(sender:&signer){
        assert!(Config::is_creater_by_signer(sender), 10012);

        move_to(sender,Resolver<ROOT>{
            list : Table::new<vector<u8>, ContentRecord>()
        });

        move_to(sender,ContentRecordAllow<ROOT>{
            list :  Table::new<vector<u8>, u64>(),
            all  :  Vector::empty<vector<u8>>()
        });
    }

    public (friend) fun change_content<ROOT: store>(hash: &vector<u8>, content_name:&vector<u8>, content:&vector<u8>):Option::Option<vector<u8>> acquires ContentRecordAllow, Resolver{
        if(Vector::length(content) == 0){
            remove_content<ROOT>(hash, content_name);
            return Option::none<vector<u8>>()
        };

        assert!(is_allow_content_name<ROOT>(content_name, content),10013);
        let resolver = &mut borrow_global_mut<Resolver<ROOT>>(Config::creater()).list;
        if(Table::contains(resolver, *hash)){
            let content_record = Table::borrow_mut(resolver, *hash);
            if(Table::contains(&mut content_record.contents, *content_name)){
                let old_content = Table::borrow_mut(&mut content_record.contents, *content_name) ;
                let op_content = Option::some(*old_content);
                *old_content = *content;
                op_content
            }else{
                Table::add(&mut content_record.contents, *content_name, *content);
                Vector::push_back(&mut content_record.all, *content_name);
                Option::none<vector<u8>>()
            }
        }else{
            Table::add(resolver, *hash, ContentRecord{
                contents : Table::new<vector<u8>, vector<u8>>(),
                all       : Vector::empty<vector<u8>>()
            });
            let content_record = Table::borrow_mut(resolver, *hash);
            Table::add(&mut content_record.contents, *content_name, *content);
            Vector::push_back(&mut content_record.all, *content_name);
            Option::none<vector<u8>>()
        }
    }

    public (friend) fun remove_content<ROOT: store>(hash: &vector<u8> , content_name:&vector<u8>):Option::Option<vector<u8>> acquires Resolver{
        let resolver = &mut borrow_global_mut<Resolver<ROOT>>(Config::creater()).list;
        if(Table::contains(resolver, *hash)){
            let content_record = Table::borrow_mut(resolver, *hash);
            if(Table::contains(&mut content_record.contents, *content_name)){
                let content = Table::remove(&mut content_record.contents, *content_name);
                let (_ , index) = Vector::index_of(&content_record.all, content_name);
                Vector::remove(&mut content_record.all, index);
                Option::some(content)
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
            let content_record = Table::borrow_mut(resolver, *hash);
            let length = Vector::length(&content_record.all);
            let i = 0;
            while(i < length){
                let content_name = Vector::remove(&mut content_record.all, 0);
                Table::remove(&mut content_record.contents, content_name);
                i = i + 1;
            };
        }else{
           
        };
    }
    

    public fun is_allow_content_name<ROOT: store>(content_name:&vector<u8>, content:&vector<u8>):bool acquires ContentRecordAllow{
        let list = &borrow_global<ContentRecordAllow<ROOT>>(Config::creater()).list;

        if(Table::contains(list, *content_name)){
            let content_len  =  Vector::length(content);
            *Table::borrow(list, *content_name) >= content_len
        }else{
            false
        }
    }

    public fun add_allow_content<ROOT: store>(sender:&signer, content_name:&vector<u8>,len:u64)acquires ContentRecordAllow{
        assert!(Config::is_admin_by_signer<ROOT>(sender), 10012);
        let allow = borrow_global_mut<ContentRecordAllow<ROOT>>(Config::creater());

        if(Table::contains(&allow.list, *content_name)){
            *Table::borrow_mut(&mut allow.list, *content_name) = len;
        }else{
            Table::add(&mut allow.list, *content_name, len);
            Vector::push_back(&mut allow.all, *content_name);
        }
    }

    public fun remove_allow_content<ROOT: store>(sender:&signer, content_name:&vector<u8>)acquires ContentRecordAllow{
        assert!(Config::is_admin_by_signer<ROOT>(sender), 10012);
        let allow = borrow_global_mut<ContentRecordAllow<ROOT>>(Config::creater());
        let list = &mut allow.list;
        if(Table::contains(list, *content_name)){
            Table::remove(list, *content_name);
        };
    }

    public fun remove_all_allow_content<ROOT: store>(sender:&signer)acquires ContentRecordAllow{
        assert!(Config::is_admin_by_signer<ROOT>(sender), 10012);
        let allow = borrow_global_mut<ContentRecordAllow<ROOT>>(Config::creater());
        let list = &mut allow.list;
        let all = &mut allow.all;

        let j = 0;
        let len = Vector::length(all);
        while(j < len){
            let content_name = Vector::remove(all, 0);
            if(Table::contains(list, copy content_name)){
               Table::remove(list, copy content_name);
            };
            j = j + 1;
        };
    }

    //Read 
    public fun get_content<ROOT: store>(hash: &vector<u8>, content_name:&vector<u8>):Option::Option<vector<u8>> acquires Resolver{
        let resolver = & borrow_global<Resolver<ROOT>>(Config::creater()).list;
        if(Table::contains(resolver, *hash)){
            let content_record = Table::borrow(resolver, *hash);
            if(Table::contains(&content_record.contents, *content_name)){
                Option::some(*Table::borrow(&content_record.contents,*content_name))
            }else{
                Option::none<vector<u8>>()
            }
        }else{
            Option::none<vector<u8>>()
        }
    }

    public fun get_all_allow_content_name<ROOT:store>():vector<vector<u8>> acquires ContentRecordAllow{
        let allow = borrow_global_mut<ContentRecordAllow<ROOT>>(Config::creater());
        *&allow.all
    }

}