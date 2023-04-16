use helloERC20::fib;

#[test]
#[available_gas(2000000)]
fn fib_test() {
    let fib5 = fib(0, 1, 5);
    assert(fib5 == 5, 'fib5 != 5')
}
