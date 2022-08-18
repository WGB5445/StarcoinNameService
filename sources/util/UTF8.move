module SNSadmin::UTF8{
    use StarcoinFramework::Vector;
    use StarcoinFramework::Errors;

    const ERROR_IS_NOT_UTF8:u64 = 100;

    public fun get_char_utf8_length (char:u8):u64{
        if(char >= 0xFC && char < 0xFE){
            6
        }else if(char >= 0xF8){
            5
        }else if(char >= 0xF0){
            4
        }else if(char >= 0xE0){
            3
        }else if(char >= 0xC0){
            2
        }else if(0 == (char & 0x80)){
            1
        }else{
            0
        }
    }

    public fun is_utf8_str(str: &vector<u8>):bool{
        let len = Vector::length(str);
        if (len == 0){
            return false
        };
        let i = 0;
        let char_len = 0;
        while(i < len){
            let char = *Vector::borrow(str, i);
            if(char_len == 0){
                char_len = get_char_utf8_length(char);
                if(char_len == 0){
                    return false
                };
            }else {
                if((char & 0xC0) != 0x80){
                    return false
                };
            };
            char_len = char_len - 1;
            i = i + 1;
        };
        true
    }

    public fun get_utf8_length (str: &vector<u8>):u64{
        assert!( is_utf8_str(str), Errors::not_published(ERROR_IS_NOT_UTF8));
        let len = Vector::length(str);
        let offset = 0;
        let str_length = 0; 
        while(offset < len){
            let char = *Vector::borrow(str, offset);
            let char_len = get_char_utf8_length(char);
            str_length = str_length + 1;
            offset = offset + char_len;
        };
        str_length
    }

    public fun get_dot_split(str: &vector<u8>):vector<vector<u8>>{
        assert!( is_utf8_str(str), Errors::not_published(ERROR_IS_NOT_UTF8));
        let vec = Vector::empty<vector<u8>>();
        let dot_index = Vector::empty<u64>();
        let len = Vector::length(str);
        let offset = 0;
        while(offset < len){
            let char = *Vector::borrow(str, offset);
            let char_len = get_char_utf8_length(char);
            if(char_len == 1 && char == 0x2E){
                Vector::push_back(&mut dot_index, offset); 
            };
            offset = offset + char_len;
        };

        let dot_length = Vector::length(&dot_index);
        if(dot_length == 0){
            return vec
        };
        let i = 0;
        let offset = 0;
        while(i < dot_length){
            let index = *Vector::borrow(&dot_index, i);
            if(index == 0 ){
                Vector::push_back(&mut vec, Vector::empty<u8>());
            }else{
                let split = Vector::empty<u8>();
                while(offset < index){
                    Vector::push_back(&mut split, *Vector::borrow(str, offset));
                    offset = offset + 1;
                };
                Vector::push_back(&mut vec, split);
            };

            i = i + 1;
            offset = offset + 1;
        };
        if( *Vector::borrow(&dot_index, dot_length - 1) == len - 1){
                Vector::push_back(&mut vec, Vector::empty<u8>());
        }else{
            let split = Vector::empty<u8>();
            while(offset < len){
                Vector::push_back(&mut split, *Vector::borrow(str, offset));
                offset = offset + 1;
            };
            Vector::push_back(&mut vec, split);
        };
        
        vec
    }

    public fun dot_number(str:&vector<u8>):u64{
        assert!( is_utf8_str(str), Errors::not_published(ERROR_IS_NOT_UTF8));
        let len = Vector::length(str);
        let offset = 0;
        let dot_length = 0;
        while(offset < len){
            let char = *Vector::borrow(str, offset);
            let char_len = get_char_utf8_length(char);
            if(char_len == 1 && char == 0x2E){
                dot_length = dot_length + 1;
            };
            offset = offset + char_len;
        };
        dot_length
    }


    #[test]
    fun test_is_utf8_str(){
        let str = b"123456789";
        assert!(is_utf8_str(&str) == true , 1001);
        let str = x"e4bda0e5a5bd";
        assert!(is_utf8_str(&str) == true , 1002);
    }

    #[test]
    fun test_get_utf8_str_length(){
        let str = b"123456789";
        assert!(get_utf8_length(&str) == 9 , 1101);

        let str = x"e4bda0e5a5bd";
        assert!(get_utf8_length(&str) == 2 , 1102);
    }

    #[test]
    fun test_get_dot_split(){
        let str = b"123.456.789";
        let vec = get_dot_split(&str);
        assert!(Vector::length(&vec) == 3, 1201);
        assert!(b"123" == *Vector::borrow(&vec, 0), 1202);
        assert!(b"456" == *Vector::borrow(&vec, 1), 1203);
        assert!(b"789" == *Vector::borrow(&vec, 2), 1204);

        let str = b".456.789";
        let vec = get_dot_split(&str);
        assert!(Vector::length(&vec) == 3, 1205);
        assert!(b"" == *Vector::borrow(&vec, 0), 1206);
        assert!(b"456" == *Vector::borrow(&vec, 1), 1207);
        assert!(b"789" == *Vector::borrow(&vec, 2), 1208);

        let str = b"123.456.";
        let vec = get_dot_split(&str);
        assert!(Vector::length(&vec) == 3, 1209);
        assert!(b"123" == *Vector::borrow(&vec, 0), 1210);
        assert!(b"456" == *Vector::borrow(&vec, 1), 1211);
        assert!(b"" == *Vector::borrow(&vec, 2), 1212);


        let str = b"123.";
        let vec = get_dot_split(&str);
        assert!(Vector::length(&vec) == 2, 1213);
        assert!(b"123" == *Vector::borrow(&vec, 0), 1214);
        assert!(b"" == *Vector::borrow(&vec, 1), 1215);

    }

}