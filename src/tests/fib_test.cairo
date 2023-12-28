use hello_erc20::fib;

#[test]
fn it_works() {
    assert(fib(16) == 987, 'it works!');
}
