module SNSadmin::SNS{
    use StarcoinFramework::Table;
    // use StarcoinFramework::Vector;
    // use StarcoinFramework::Signer;
    // use StarcoinFramework::Timestamp;
    use StarcoinFramework::NFT;
    use StarcoinFramework::Option;
    // use StarcoinFramework::Account;
    // use StarcoinFramework::Math;

    struct ShardCap has key, store{
        mint_cap    :   NFT::MintCapability<SNSMetaData>,
        burn_cap    :   NFT::BurnCapability<SNSMetaData>,
        updata_cap  :   NFT::UpdateCapability<SNSMetaData>
    }

    struct SNSMetaData has drop, copy, store {
        Domain_name         :   vector<u8>,
        Controller          :   address,
        Create_time         :   u64,
        Expiration_time     :   u64,
    }

    struct SNSBody has store{
        domain      :   Domain,
        subDomains  :   SubDomains
    }


    struct Domain has   store {
        stc_address : address,
        contents    : vector<u8>,
        content     : Table::Table<u8, vector<u8>>
    }

    struct SubDomains has store{
        subDomainsName     :   vector<u8>,
        subDomains         :   Table::Table<vector<u8>, SubDomain>
    }

    struct SubDomain has store{
        stc_address : address,  
        contents    : vector<u8>,
        content     : Table::Table<u8, vector<u8>>
    }






    struct Registry has key, store{
        list : Table::Table<vector<u8>, RegistryDetails>
    }

    struct RegistryDetails has store, drop{
        owner               : Option::Option<address>,
        mainDomain          : Option::Option<vector<u8>>,
        subDomainIndex      : u8
    }
    
    struct DomainGallery has key, store{
        DomainsName     :   vector<u8>,
        Domains         :   Table::Table<vector<u8>, NFT::NFT<SNSMetaData, SNSBody>>
    }

}