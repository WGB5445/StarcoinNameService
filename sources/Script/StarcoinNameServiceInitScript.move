module SNSadmin::StarcoinNameServiceInitScript{
    use StarcoinFramework::Signer;
    use SNSadmin::Resolver as Resolver;
    use SNSadmin::Registrar as Registrar;
    // use SNSadmin::AddressResolver as AddressResolver;
    use SNSadmin::NameServiceNFT as NameServiceNFT;
    use SNSadmin::Config as Config;
    use SNSadmin::UpgradeManager as UpgradeManager;
    use SNSadmin::AddressResolver;
    use SNSadmin::ContentResolver;

    public (script) fun Config_init(sender:signer){
        Config::init(&sender);
    }

    public (script) fun UpgradeManager_init(sender:signer){
        UpgradeManager::init(&sender);
    }

    public (script) fun Registrar_init<T: store>(sender:signer){
        Registrar::init<T>(&sender);
    }

    public (script) fun NameServiceNFT_init<T: store>(sender:signer){
        NameServiceNFT::init<T>(&sender);
    }

    public (script) fun update_nft_type_info_meta<T: store>(sender:signer){
        NameServiceNFT::update_nft_type_info_meta<T>(&sender);
    } 

    public (script) fun Resolver_init<T: store>(sender:signer){
        Resolver::init<T>(&sender);
    }

    public (script) fun AddressRecord_init<T: store>(sender:signer){
        AddressResolver::init<T>(&sender);
    }

    public (script) fun ContentResolver_init<T: store>(sender:signer){
        ContentResolver::init<T>(&sender);
    }

    // public (script) fun address_resolver_init<T: store>(sender:signer){
    //     AddressResolver::init<T>(&sender);
    // }

    // public (script) fun address_resolver_allow_add<T: store>(sender:signer,name:vector<u8>,len:u64){
    //     AddressResolver::add_allow_address_record<T>(&sender,&name,len);
    // }

    public (script) fun init(sender:signer){
        Config::init(&sender);
        UpgradeManager::init(&sender);
        UpgradeManager::update_module_upgrade_strategy(&sender);
    }

    public (script) fun init_root<T: store>(sender:signer, root: vector<u8>){
        Resolver::init<T>(&sender);
        Registrar::init<T>(&sender);
        NameServiceNFT::init<T>(&sender);
        AddressResolver::init<T>(&sender);
        ContentResolver::init<T>(&sender);
        Config::modify_RootMap<T>(&sender, &root, Signer::address_of(&sender));
    }
}