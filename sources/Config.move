module SNSadmin::Config{
    use StarcoinFramework::Table;
    use StarcoinFramework::Signer;
    use StarcoinFramework::Option::{Self, Option};
    
    struct RootConfig has key,store{
        config : Table::Table<vector<u8>,address>
    }

    struct RootMap<phantom ROOT:store> has key,store{
        root: vector<u8>
    }

    public fun init(sender:&signer){
        assert!(is_creater_by_signer(sender),10012);
        move_to(sender,RootConfig{
            config: Table::new<vector<u8>, address>()
        })
    }

    public fun creater():address{
        @SNSadmin
    }

    public fun is_creater_by_signer(sender:&signer):bool{
        let account = Signer::address_of(sender);
        is_creater_by_address(account)
    }

    public fun is_creater_by_address(addr:address):bool{
        addr == @SNSadmin
    }

    public fun is_admin_by_signer<ROOT:store>(sender:&signer):bool acquires RootConfig, RootMap{
        let account = Signer::address_of(sender);
        is_admin_by_address<ROOT>(account)
    }

    public fun is_admin_by_address<ROOT:store>(addr: address):bool acquires RootConfig, RootMap{
        let rootConfig = &borrow_global<RootConfig>(creater()).config;
        let root_str = &borrow_global<RootMap<ROOT>>(creater()).root;

        if(Table::contains(rootConfig, *root_str)){
            (*Table::borrow(rootConfig, *root_str) == addr) || is_creater_by_address(addr)
        }else{
            abort 100320
        }
    }
    

    // Add root
    public fun modify_RootMap<ROOT:store>(sender:&signer, root: &vector<u8>, admin:address) acquires RootConfig, RootMap{
        assert!(is_creater_by_signer(sender),10012);
        if(!exists<RootMap<ROOT>>(creater())){
            move_to(sender, RootMap<ROOT>{
                root: *root
            })
        }else{
            let rootMap_root = &mut borrow_global_mut<RootMap<ROOT>>(creater()).root;
            *rootMap_root = *root
        };
        let rootConfig = &mut borrow_global_mut<RootConfig>(creater()).config;
        
        if(Table::contains(rootConfig, *root)){
            *Table::borrow_mut(rootConfig, *root) = admin
        }else{
            Table::add(rootConfig, *root, admin)
        };
    }

    // Delete root
    public fun delete_RootMap<ROOT:store>(sender:&signer, root: &vector<u8>):Option<address> acquires RootConfig, RootMap{
        assert!(is_creater_by_signer(sender),10012);
        assert!(exists<RootMap<ROOT>>(creater()), 10031);
        let RootMap<ROOT>{
            root: _
        } = move_from<RootMap<ROOT>>(creater());
        let rootConfig = &mut borrow_global_mut<RootConfig>(creater()).config;
        if(Table::contains(rootConfig, *root)){
           Option::some(Table::remove(rootConfig, *root))
        }else{
            Option::none<address>()
        }
    }

    public fun get_root<ROOT:store>():vector<u8> acquires RootMap{
        *&borrow_global<RootMap<ROOT>>(creater()).root
    }

    public fun get_admin_by_root<ROOT:store>():address acquires RootConfig, RootMap{
        let root = &borrow_global<RootMap<ROOT>>(creater()).root;
        let rootConfig = & borrow_global<RootConfig>(creater()).config;
        *Table::borrow(rootConfig, *root)
    }


    // #[test(sender = @SNSadmin)]
    // fun test_Config (sender: signer) acquires RootConfig, RootMap{
    //     use SNSadmin::Root::STC;
    //     init(&sender);
    //     modify_RootMap<STC>(&sender, &b"stc", @0x1);
    //     assert!(get_root<STC>() == b"stc",1);
    //     assert!(get_admin_by_root<STC>() == @0x1, 2);
    // }

}