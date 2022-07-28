module SNSadmin::SVG{
    
    #[test]
    fun test_svg(){
        use SNSadmin::Base64;
        use StarcoinFramework::Vector;

        let svg_base64 = b"data:image/svg+xml;base64,PHN2ZyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHZlcnNpb249JzEuMSc+PHRleHQgeD0nMCcgeT0nMTUnIGZpbGw9J3JlZCc+5L2g5aW9PC90ZXh0Pjwvc3ZnPg==";
        // let svg_img = b"PHN2ZyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHZlcnNpb249JzEuMSc+PHRleHQgeD0nMCcgeT0nMTUnIGZpbGw9J3JlZCc+5L2g5aW9PC90ZXh0Pjwvc3ZnPg==";
        let svg_str = b"<svg xmlns='http://www.w3.org/2000/svg' version='1.1'><text x='0' y='15' fill='red'>"; 
        let text = x"e4bda0e5a5bd";
        let back = b"</text></svg>";
        
        Vector::append(&mut svg_str,text);
        Vector::append(&mut svg_str,back);

    
        let svg_2_base64 = Base64::encode(&svg_str);

        let svg_header = b"data:image/svg+xml;base64,";
        
        Vector::append(&mut svg_header,svg_2_base64);

        assert!( svg_base64 == svg_header ,1001);

        assert!( Base64::decode(&Base64::encode(&svg_str)) == svg_str, 1002);
    }
}
module SNSadmin::Base64 {
    use StarcoinFramework::Vector;

    const TABLE:vector<u8> = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    public fun encode(str: &vector<u8>): vector<u8> {
        if (Vector::is_empty(str)) {
            return Vector::empty<u8>()
        };
        let size = Vector::length(str);
        let eq: u8 = 61;
        let res = Vector::empty<u8>();

        let m = 0 ;
        while (m < size ) {
            Vector::push_back(&mut res, *Vector::borrow(&TABLE ,(((*Vector::borrow(str, m) & 0xfc) >> 2 ) as u64 )) ); 

            if( m + 1 < size){
                
                Vector::push_back(&mut res, *Vector::borrow(&TABLE, ((((*Vector::borrow(str, m) & 0x03) << 4) + ((*Vector::borrow(str, m + 1) & 0xf0 ) >> 4) ) as u64 )));
                if( m + 2 < size){
                    Vector::push_back(&mut res, *Vector::borrow(&TABLE, ((((*Vector::borrow(str, m + 1) & 0x0f) << 2 ) + ((*Vector::borrow(str, m + 2) & 0xc0 ) >> 6 )) as u64) ));
                    Vector::push_back(&mut res, *Vector::borrow(&TABLE, ((*Vector::borrow(str, m + 2) & 0x3f) as u64))); 
                }else{
                    Vector::push_back(&mut res, *Vector::borrow(&TABLE, (((*Vector::borrow(str, m + 1) & 0x0f ) << 2 ) as u64 ))); 
                    Vector::push_back(&mut res, eq);
                };
            }else{
                Vector::push_back(&mut res, *Vector::borrow(&TABLE ,(((*Vector::borrow(str, m) & 0x03) << 4 ) as u64 )) ); 
                Vector::push_back(&mut res, eq);
                Vector::push_back(&mut res, eq);
            };

            m = m + 3;
        };

        return res
    }
    fun encode_triplet(a: u8, b: u8, c:u8):(u8, u8, u8, u8){
        let concat_bits =   ((a as u64 ) << 16 ) |  ((b  as u64 ) << 8) | ( c as u64 );
        let char1 = Vector::borrow(&TABLE, (concat_bits >> 18) & 63);
        let char2 = Vector::borrow(&TABLE, (concat_bits >> 12) & 63);
        let char3 = Vector::borrow(&TABLE, (concat_bits >> 6) & 63);
        let char4 = Vector::borrow(&TABLE, concat_bits & 63);
        (*char1, *char2, *char3, *char4)
    }

    public fun decode(code: &vector<u8>): vector<u8> {
        if (Vector::is_empty(code) || Vector::length<u8>(code) % 4 != 0) {
            return Vector::empty<u8>()
        };

        let size = Vector::length(code);
        let res = Vector::empty<u8>();
        let m = 0 ;
        while (m < size) {
            let pos_of_char_1 = pos_of_char(*Vector::borrow(code, m + 1));
            Vector::push_back(&mut res, (pos_of_char(*Vector::borrow(code, m )) << 2) +  ((pos_of_char_1 & 0x30 ) >> 4) );
            if( ( m + 2 < size) && (*Vector::borrow(code, m + 2) != 61) && (*Vector::borrow(code, m + 2) != 46)){
                let pos_of_char_2 = pos_of_char(*Vector::borrow(code, m + 2));
                Vector::push_back(&mut res,  ((pos_of_char_1 & 0x0f ) << 4) + (( pos_of_char_2 & 0x3c) >> 2));
                
                if( ( m + 3 < size) && (*Vector::borrow(code, m + 3) != 61) && (*Vector::borrow(code, m + 3) != 46)){
                    let pos_of_char_2 = pos_of_char(*Vector::borrow(code, m + 2));
                    Vector::push_back<u8>(&mut res,  ((pos_of_char_2 & 0x03 ) << 6) + pos_of_char(*Vector::borrow(code, m + 3)) );    
                };
            };

            m = m + 4;
        };

        return res
    }

    fun pos_of_char(char: u8):u8{
        if (char >= 65 && char <= 90){
            return char - 65
        }else if (char >= 97 && char <= 122){
            return char - 97 + (90 - 65) + 1
        }else if (char >= 48 && char <= 57){
            return char - 48 + (90 - 65) + (122 - 97) + 2
        }else if (char == 43 || char == 45){
            return 62
        }else if (char == 47 || char == 95){
            return 63
        };
        abort 1001
    }

    #[test]
    fun test_base64() {
        let str = b"abcdefghijklmnopqrstuvwsyzABCDEFGHIJKLMNOPQRSTUVWSYZ1234567890+/sdfa;fij;woeijfoawejif;oEQJJ'";
        //StarcoinFramework::Debug::print(&str);
        let code = encode(&str);
        //StarcoinFramework::Debug::print(&code);
        let decode_str = decode(&code);
        //StarcoinFramework::Debug::print(&decode_str);
        assert!(str == decode_str, 1000);
    }

    #[test]
    fun test_utf8(){
        use StarcoinFramework::Debug;
        let str = x"E6B189";
        Debug::print(&str);
        Debug::print(&encode(&str));
        Debug::print(&b"5rGJ");
    }
}