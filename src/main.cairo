use debug::PrintTrait;
use hello_erc20::fib;

fn main() {
    let fib5 = fib(0, 1, 5);
    fib5.print();
}
