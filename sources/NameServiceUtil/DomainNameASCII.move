module SNSadmin::DomainNameASCII{
    use StarcoinFramework::Vector;
    use StarcoinFramework::Hash;
    use SNSadmin::ASCII;

    const EMPTY_NODE:vector<u8> = x"0000000000000000000000000000000000000000000000000000000000000000";

    public fun is_allow_format_domain_name(name:&vector<u8>):bool {
        let string = ASCII::string(name);
        
        if(! ASCII::all_characters_printable(&string)){
            return false
        };

        let split = ASCII::split_by_char(&string, ASCII::char(0x2E));
        let len = Vector::length(&split);
        if(len > 3 || len < 2){
            return false
        };
        let i = 0;
        while(i < len){
            let vec = Vector::borrow(&split, i);
            if(ASCII::is_empty(vec) || ( i == len - 1 && !is_allow_root(*ASCII::as_bytes(vec)))){
                return false
            };
            i = i + 1;
        };
        let domain_length = ASCII::length( Vector::borrow(&split, len - 2));
        if(domain_length > 20 || domain_length < 3){
            return false
        };
        true
    }

    public fun dot_number(str:&vector<u8>):u64{
        let i = 0 ;
        let dot_number = 0;
        let length = Vector::length(str);
        while(i > length){
            if(*Vector::borrow(str, i) == 0x2E){
                dot_number = dot_number + 1;
            };
            i = i + 1;
        };
        dot_number
    }

    public fun get_domain_name_hash(name:&vector<u8>):vector<u8>{
        let node = EMPTY_NODE;
        let string = ASCII::string(name);
        let vec = ASCII::split_by_char(&string, ASCII::char(0x2E));
        let vec_length = Vector::length(&vec);
        let i = vec_length - 1;
        while(i > 0){
            Vector::append(&mut node ,Hash::keccak_256( *ASCII::as_bytes(Vector::borrow(&vec, i)) ));
            node = Hash::keccak_256(node);
            i = i - 1;
        };
        Vector::append(&mut node ,Hash::keccak_256( *ASCII::as_bytes(Vector::borrow(&vec, 0)) ));
        Hash::keccak_256(node)
    }

    public fun  get_name_hash_2(root: &vector<u8>, name:&vector<u8>):vector<u8>{
        let node = EMPTY_NODE;
        Vector::append(&mut node ,Hash::keccak_256(*root));
        node = Hash::keccak_256(node);
        Vector::append(&mut node ,Hash::keccak_256(*name));
        Hash::keccak_256(node)
    }

    public fun get_dot_split(str: &vector<u8>):vector<vector<u8>>{
        let string = ASCII::string(str);
        let split = ASCII::split_by_char(&string, ASCII::char(0x2E));
        let vec = Vector::empty<vector<u8>>();
        let i = 0 ; 
        let length = Vector::length(&split);
        while(i < length){
            Vector::push_back(&mut vec, *ASCII::as_bytes(Vector::borrow(&split, i)));
            i = i + 1;
        };
        vec
    }

    #[test]
    fun test_split_name (){
        let name = b"iamtimhhh.stc";
        let string = ASCII::string(&name);
        let split = ASCII::split_by_char(&string, ASCII::char(0x2E));
        let vec = Vector::empty<vector<u8>>();
        let i = 0 ; 
        let length = Vector::length(&split);
        while(i < length){
            Vector::push_back(&mut vec, *ASCII::as_bytes(Vector::borrow(&split, i)));
            i = i + 1;
        };
        StarcoinFramework::Debug::print(&vec)
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
        assert!(is_allow_format_domain_name(&name) == true, 1001);
        let name = b"1234.eth";
        assert!(is_allow_format_domain_name(&name) == false, 1002);
        let name = b"1234.";
        assert!(is_allow_format_domain_name(&name) == false, 1003);        
        let name = b".stc";
        assert!(is_allow_format_domain_name(&name) == false, 1004);   
        let name = b"1234.4567.stc";
        assert!(is_allow_format_domain_name(&name) == true, 1005);
        let name = b"123.4567.8901.stc";
        assert!(is_allow_format_domain_name(&name) == false, 1006);
        let name = b"12.stc";
        assert!(is_allow_format_domain_name(&name) == false, 1007);
        let name = b"123456789012345678901234567890123456789012345678901234567890.stc";
        assert!(is_allow_format_domain_name(&name) == false, 1008);        
    }

    #[test]
    fun test_hash(){
        use StarcoinFramework::Hash;
        use StarcoinFramework::Vector;
        
        let node = EMPTY_NODE;

        Vector::append(&mut node ,Hash::keccak_256(b"eth"));
        node = Hash::keccak_256(node);
        Vector::append(&mut node ,Hash::keccak_256(b"foo"));
        node = Hash::keccak_256(node);
        assert!(node == x"de9b09fd7c5f901e23a3f19fecc54828e9c848539801e86591bd9801b019f84f",1301);
    }

    #[test]
    fun test_get_domain_hash(){

        let name = b"foo.eth";
        let node = get_domain_name_hash(&name);
        assert!(node == x"de9b09fd7c5f901e23a3f19fecc54828e9c848539801e86591bd9801b019f84f",1301);
    }
}