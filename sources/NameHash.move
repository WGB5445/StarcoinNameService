module SNSadmin::DomainName{
    use StarcoinFramework::Vector;
    use SNSadmin::UTF8;


    public fun is_allow_format_domain_name(name:vector<u8>):bool {
        if(! UTF8::is_utf8_str(copy name)){
            return false
        };

        let split = UTF8::get_dot_split(copy name);
        let len = Vector::length(&split);
        if(len > 3 || len < 2){
            return false
        };
        let i = 0;
        while(i < len){
            let vec = Vector::borrow(&split, i);
            if(Vector::is_empty(vec) || ( i == len - 1 && !is_allow_root(*vec))){
                return false
            };
            i = i + 1;
        };
        let domain_length = UTF8::get_utf8_length( *Vector::borrow(&split, len - 2));
        if(domain_length > 20 || domain_length < 3){
            return false
        };
        true
    }

    //TODO: get hash
    public fun get_domain_name_hash(_name:vector<u8>):vector<u8>{
        Vector::empty<u8>()
    }

    //TODO: prices
    public fun price (_name:vector<u8>):u128{
        1000
    }

    public fun is_allow_root(root:vector<u8>):bool{
        if(root == b"stc"){
            true
        }else{
            false
        }
    }

    #[test]
    fun test_is_allow_format_domain_name(){
        let name = b"1234.stc";
        assert!(is_allow_format_domain_name(name) == true, 1001);
        let name = b"1234.eth";
        assert!(is_allow_format_domain_name(name) == false, 1002);
        let name = b"1234.";
        assert!(is_allow_format_domain_name(name) == false, 1003);        
        let name = b".stc";
        assert!(is_allow_format_domain_name(name) == false, 1004);   
        let name = b"1234.4567.stc";
        assert!(is_allow_format_domain_name(name) == true, 1005);
        let name = b"123.4567.8901.stc";
        assert!(is_allow_format_domain_name(name) == false, 1006);
        let name = b"12.stc";
        assert!(is_allow_format_domain_name(name) == false, 1007);
        let name = b"123456789012345678901234567890123456789012345678901234567890.stc";
        assert!(is_allow_format_domain_name(name) == false, 1008);        
    }

    #[test]
    fun test_hash(){
        use StarcoinFramework::Hash;
        use StarcoinFramework::Vector;
        
        let node = Vector::empty<u8>();
        let i = 0;
        while(i < 32){
            Vector::push_back(&mut node, 0);
            i = i + 1;
        };
        Vector::append(&mut node ,Hash::keccak_256(b"eth"));
        node = Hash::keccak_256(node);
        Vector::append(&mut node ,Hash::keccak_256(b"foo"));
        node = Hash::keccak_256(node);
        assert!(node == x"de9b09fd7c5f901e23a3f19fecc54828e9c848539801e86591bd9801b019f84f",1301);
    }
}