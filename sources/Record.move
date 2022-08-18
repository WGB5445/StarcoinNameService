#[test_only]
module SNSadmin::Record{
    use StarcoinFramework::Table;
    use StarcoinFramework::Vector;
    use StarcoinFramework::Option;
    use StarcoinFramework::Signer;

    struct AddressRecord<phantom ROOT> has key,store{
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

    struct ContentRecord<phantom ROOT> has key,store{
        contents :     Table::Table<vector<u8>,vector<u8>> ,
        all      :  vector<vector<u8>>
    }

    struct ContentRecordAllow<phantom ROOT> has key,store {
        list :  Table::Table<vector<u8> , u64> ,
        all  :  vector<vector<u8>>
    }

    struct TextRecord<phantom ROOT> has key,store{
        texts :     Table::Table<vector<u8>,vector<u8>> ,
        all   :  vector<vector<u8>>
    }

    struct TextRecordAllow<phantom ROOT> has key,store {
        list :  Table::Table<vector<u8> , u64> ,
        all  :  vector<vector<u8>>
    }
    

    public fun init<ROOT: store>(sender:&signer){
        let account = Signer::address_of(sender);
        assert!(account == @SNSadmin,10012);

        move_to(sender,AddressRecord<ROOT>{
            addresses :  Table::new<vector<u8>,vector<u8>>(),
            all  :  Vector::empty<vector<u8>>()
        });

        move_to(sender,AddressRecordAllow<ROOT>{
            list :  Table::new<vector<u8>, AddressRecordAllowBox>(),
            all  :  Vector::empty<vector<u8>>()
        });

        move_to(sender,ContentRecordAllow<ROOT>{
            list :  Table::new<vector<u8>, u64>(),
            all  :  Vector::empty<vector<u8>>()
        });

        move_to(sender,TextRecordAllow<ROOT>{
            list :  Table::new<vector<u8>, u64>(),
            all  :  Vector::empty<vector<u8>>()
        });


    }

    public fun new_address_record<ROOT>():AddressRecord<ROOT> {
        AddressRecord<ROOT>{
            addresses :Table::new<vector<u8>,vector<u8>>(),
            all       :Vector::empty<vector<u8>>()
        }
    }
    
    public fun destroy_address_record<ROOT>(obj: AddressRecord<ROOT>){
        let AddressRecord <ROOT>{
            addresses,
            all
        } = obj;
        let length = Vector::length(&all);
        let i = 0;
        while(i < length){
            Table::remove(&mut addresses, *Vector::borrow(&all, i));
            i = i + 1;
        };
        Table::destroy_empty(addresses);
    }

    public fun change_address_record<ROOT>(obj:&mut AddressRecord<ROOT> , name:&vector<u8>, addr:&vector<u8>)acquires AddressRecordAllow{
        if(Vector::length(addr) == 0){
            remove_address_record<ROOT>(obj,name);
            return 
        };
        assert!(is_allow_address_record<ROOT>(name, addr),10013);
        let addresses = &mut obj.addresses;
        if(Table::contains(addresses, *name)){
            *Table::borrow_mut(addresses, *name) = *addr;
        }else{
            Table::add(addresses, *name, *addr);
            Vector::push_back(&mut obj.all, *name);
        }
    }

    public fun remove_address_record<ROOT>(obj:&mut AddressRecord<ROOT> , name:&vector<u8>){
        if(Table::contains(&mut obj.addresses, *name)){
            Table::remove(&mut obj.addresses, *name);
            let (_ , index) = Vector::index_of(&obj.all, name);
            Vector::remove(&mut obj.all, index);
        }
    }

    public fun get_address_record<ROOT>(obj:&AddressRecord<ROOT>, name:&vector<u8>):Option::Option<vector<u8>>{
        if(Table::contains(&obj.addresses, *name)){
            Option::some(*Table::borrow(&obj.addresses,*name))
        }else{
            Option::none<vector<u8>>()
        }
    }

    public fun is_allow_address_record<ROOT>(name:&vector<u8>, addr:&vector<u8>):bool acquires AddressRecordAllow{
        let list = &borrow_global<AddressRecordAllow<ROOT>>(@SNSadmin).list;

        if(Table::contains(list, *name)){
            let addr_len  =  Vector::length(addr);
            Table::contains(&Table::borrow(list, *name).list, addr_len) 
        }else{
            false
        }
    }

    public fun add_allow_address_record<ROOT>(sender:&signer,name:&vector<u8>,len:u64)acquires AddressRecordAllow{
        let account = Signer::address_of(sender);
        assert!(account == @SNSadmin,10012);
        let allow = borrow_global_mut<AddressRecordAllow<ROOT>>(@SNSadmin);
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

    public fun remove_allow_address_record<ROOT>(sender:&signer,name:&vector<u8>,len:u64)acquires AddressRecordAllow{
        let account = Signer::address_of(sender);
        assert!(account == @SNSadmin,10012);
        let allow = borrow_global_mut<AddressRecordAllow<ROOT>>(@SNSadmin);
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

    public fun remove_all_allow_address_record_len<ROOT>(sender:&signer,name:&vector<u8>)acquires AddressRecordAllow{
        
        let account = Signer::address_of(sender);
        assert!(account == @SNSadmin,10012);
        let allow = borrow_global_mut<AddressRecordAllow<ROOT>>(@SNSadmin);
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

    public fun remove_all_allow_address_record<ROOT>(sender:&signer)acquires AddressRecordAllow{
        let account = Signer::address_of(sender);
        assert!(account == @SNSadmin,10012);
        let allow = borrow_global_mut<AddressRecordAllow<ROOT>>(@SNSadmin);
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

    // public fun new_content_record<ROOT>():ContentRecord {
    //     ContentRecord{
    //         contents  :Table::new<vector<u8>,vector<u8>>(),
    //         all       :Vector::empty<vector<u8>>()
    //     }
    // }
    
    // public fun destroy_content_record<ROOT>(obj: ContentRecord){
    //     let ContentRecord {
    //         contents,
    //         all
    //     } = obj;
    //     let length = Vector::length(&all);
    //     let i = 0;
    //     while(i < length){
    //         Table::remove(&mut contents, *Vector::borrow(&all, i));
    //         i = i + 1;
    //     };
    //     Table::destroy_empty(contents);
    // }

    // public fun change_content_record<ROOT>(obj:&mut ContentRecord , name:&vector<u8>, content:&vector<u8>)acquires ContentRecordAllow{
    //     if(Vector::length(content) == 0){
    //         remove_content_record(obj,name);
    //         return 
    //     };
    //     assert!(is_allow_content_record(name, content),10013);
    //     let addresses = &mut obj.contents;
    //     if(Table::contains(addresses, *name)){
    //         *Table::borrow_mut(addresses, *name) = *content;
    //     }else{
    //         Table::add(addresses, *name, *content);
    //         Vector::push_back(&mut obj.all, *name);
    //     }
    // }

    // public fun remove_content_record<ROOT>(obj:&mut ContentRecord , name:&vector<u8>){
    //     if(Table::contains(&mut obj.contents, *name)){
    //         Table::remove(&mut obj.contents, *name);
    //         let (_ , index) = Vector::index_of(&obj.all, name);
    //         Vector::remove(&mut obj.all, index);
    //     }
    // }

    // public fun is_allow_content_record<ROOT>(name:&vector<u8>, content:&vector<u8>):bool acquires ContentRecordAllow{
    //     let list = &borrow_global<ContentRecordAllow>(@SNSadmin).list;

    //     if(Table::contains(list, *name)){
    //         let content_len  =  Vector::length(content);
    //         *Table::borrow(list, *name) >=  content_len
    //     }else{
    //         false
    //     }
    // }

    // public fun add_allow_content_record<ROOT>(sender:&signer,name:&vector<u8>,len:u64)acquires ContentRecordAllow{
    //     let account = Signer::address_of(sender);
    //     assert!(account == @SNSadmin,10012);
    //     let allow = borrow_global_mut<ContentRecordAllow>(@SNSadmin);
    //     let list = &mut allow.list;

    //     if(Table::contains(list, *name)){
    //         *Table::borrow_mut(list, *name) = len
    //     }else{
    //         Table::add(list, *name, len)
    //     }
    // }

    // public fun remove_allow_content_record<ROOT>(sender:&signer,name:&vector<u8>)acquires ContentRecordAllow{
    //     let account = Signer::address_of(sender);
    //     assert!(account == @SNSadmin,10012);
    //     let allow = borrow_global_mut<ContentRecordAllow>(@SNSadmin);
    //     let list = &mut allow.list;

    //     if(Table::contains(list, *name)){
    //         Table::remove(list, *name);
    //     };
    // }

    // public fun remove_all_content_address_record<ROOT>(sender:&signer)acquires ContentRecordAllow{
    //     let account = Signer::address_of(sender);
    //     assert!(account == @SNSadmin,10012);
    //     let allow = borrow_global_mut<ContentRecordAllow>(@SNSadmin);
    //     let list = &mut allow.list;

    //     let length = Vector::length(&allow.all);
    //     let i = 0;
    //     while(i < length){
    //         Table::remove(list, *Vector::borrow(&allow.all, i));
    //         i = i + 1;
    //     }; 
    // }



}