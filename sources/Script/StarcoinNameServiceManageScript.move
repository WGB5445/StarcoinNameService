module SNSadmin::StarcoinNameServiceManageScript{

    use SNSadmin::Config as Config;
    // Config

    public (script) fun modify_RootMap<ROOT:store>(sender:signer, root: &vector<u8>, admin:address){
        Config::modify_RootMap<ROOT>(&sender, root, admin)
    } 

    public (script) fun delete_RootMap<ROOT:store>(sender:signer, root: &vector<u8>){
        Config::delete_RootMap<ROOT>(&sender, root);
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



}
