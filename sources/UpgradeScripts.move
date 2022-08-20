module SNSadmin::UpgradeScripts{
    use StarcoinFramework::PackageTxnManager;
    use StarcoinFramework::Config;
    use StarcoinFramework::Signer;
    use StarcoinFramework::Version;
    use StarcoinFramework::Option;

    public(script) fun update_module_upgrade_strategy(
        sender: signer
    ) {
        let account = Signer::address_of(&sender);
        assert!(account == @SNSadmin,10012);
        let strategy = 1;
        // 1. check version
        if (strategy == PackageTxnManager::get_strategy_two_phase()) {
            if (!Config::config_exist_by_address<Version::Version>(Signer::address_of(&sender))) {
                Config::publish_new_config<Version::Version>(&sender, Version::new_version(1));
            }
        };

        // 2. update strategy
        PackageTxnManager::update_module_upgrade_strategy(
            &sender,
            strategy,
            Option::some<u64>(1),
        );
    }
}