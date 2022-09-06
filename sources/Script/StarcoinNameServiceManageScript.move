module SNSadmin::StarcoinNameServiceManageScript{

    use SNSadmin::Config as Config;
    use SNSadmin::AddressResolver;
    use SNSadmin::ContentResolver;
    // Config

    public (script) fun modify_RootMap<ROOT:store>(sender:signer, root: vector<u8>, admin:address){
        Config::modify_RootMap<ROOT>(&sender, &root, admin)
    } 

    public (script) fun delete_RootMap<ROOT:store>(sender:signer, root: vector<u8>){
        Config::delete_RootMap<ROOT>(&sender, &root);
    }

    public fun is_admin_by_address<ROOT:store>(addr:address):bool{
        Config::is_admin_by_address<ROOT>(addr)
    }

    public fun get_root<ROOT:store>():vector<u8>{
        Config::get_root<ROOT>()
    }

    public fun get_admin_by_root<ROOT:store>():address{
        Config::get_admin_by_root<ROOT>()
    }

    //AddressResolver
    public (script) fun add_allow_address_record<ROOT: store>(sender:signer, name:vector<u8>, len:u64){
        AddressResolver::add_allow_address_record<ROOT>(&sender, &name, len);
    }

    public (script) fun remove_allow_address_record<ROOT: store>(sender:signer, name:vector<u8>, len:u64){
        AddressResolver::remove_allow_address_record<ROOT>(&sender, &name, len);
    }

    public (script) fun remove_all_allow_address_record_len<ROOT: store>(sender:signer, name:vector<u8>){
        AddressResolver::remove_all_allow_address_record_len<ROOT>(&sender, &name);
    }

    public (script) fun remove_all_allow_address_record<ROOT: store>(sender:signer){
        AddressResolver::remove_all_allow_address_record<ROOT>(&sender);
    }

    //ContentResolver
    public (script) fun add_allow_content<ROOT: store>(sender:signer, content_name:vector<u8>, len:u64){
        ContentResolver::add_allow_content<ROOT>(&sender, &content_name, len);
    }

    public (script) fun remove_allow_content<ROOT: store>(sender:signer, content_name:vector<u8>){
        ContentResolver::remove_allow_content<ROOT>(&sender, &content_name);
    }
}
