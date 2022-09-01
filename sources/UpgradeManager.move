module SNSadmin::UpgradeManager{
    use StarcoinFramework::PackageTxnManager;
    use StarcoinFramework::Config;
    use StarcoinFramework::Signer;
    use StarcoinFramework::Version;
    use StarcoinFramework::Option;
 
    struct VersionManager has drop, copy, store{
        version: u64
    }

    public fun init(sender:&signer){
        if (!Config::config_exist_by_address<VersionManager>(Signer::address_of(sender))) {
                Config::publish_new_config<VersionManager>(sender, VersionManager{version : 1});
        };
    }

    public fun update_module_upgrade_strategy(sender: &signer) {
        let account = Signer::address_of(sender);
        assert!(account == @SNSadmin,10012);
        let strategy = 1;
        // 1. check version
        if (strategy == PackageTxnManager::get_strategy_two_phase()) {
            if (!Config::config_exist_by_address<Version::Version>(Signer::address_of(sender))) {
                Config::publish_new_config<Version::Version>(sender, Version::new_version(1));
            }
        };

        // 2. update strategy
        PackageTxnManager::update_module_upgrade_strategy(
            sender,
            strategy,
            Option::some<u64>(1),
        );
    }

    public fun last_version():u64{
        2
    }

    public (script) fun upgrade(sender: signer){
        let addr = Signer::address_of(&sender);
        let version = Config::get_by_address<VersionManager>(addr).version;
        if(version == 1){
            // Do some Upgrade function
            
            version = version + 1;
        };
        if(version == 2){

        };

        assert!(version == last_version(), 10134);
        Config::set<VersionManager>(&sender, VersionManager{version : version});
    }

}