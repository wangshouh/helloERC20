use option::OptionTrait;

fn fib(a: felt252, b: felt252, n: felt252) -> felt252 {
    gas::withdraw_gas_all(get_builtin_costs()).expect('Out of gas');
    match n {
        0 => a,
        _ => fib(b, a + b, n - 1),
    }
}

mod main;

#[cfg(test)]
mod tests;
