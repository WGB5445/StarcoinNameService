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
