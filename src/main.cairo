use debug::PrintTrait;
use helloERC20::fib;

fn main() {
    let fib5 = fib(0, 1, 5);
    fib5.print();
}
