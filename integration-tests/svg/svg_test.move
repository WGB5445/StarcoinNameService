//# init -n dev

//# faucet --addr creator --amount 10000000000000

//# run --signers creator
script {
    use SNSadmin::Base64;


    fun create(_sender: signer) {
        let svg = b"<svg width='150' height='150' xmlns='http://wwww.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'><foreignObject width='150' height='150' x='0' y='0'><body xmlns='http://www.w3.org/1999/xhtml'><text x='14' y='14' style='font-size: 14pt;fill: block;'>Iam(-_-).stc</text></body></foreignObject></svg>";

        let _base64_svg = Base64::encode(&svg);

    }
}
// check: EXECUTED

