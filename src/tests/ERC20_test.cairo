use helloERC20::ERC20::ERC20;
use integer::u256;
use integer::u256_from_felt252;

const NAME: felt252 = 'Test';
const SYMBOL: felt252 = 'TET';
const DECIMALS: u8 = 18_u8;

#[test]
#[available_gas(2000000)]
fn test_initializer() {
    let initial_supply: u256 = u256_from_felt252(2000);
    ERC20::constructor(NAME, SYMBOL, DECIMALS, initial_supply);

    assert(ERC20::name() == NAME, 'Name should be NAME');
    assert(ERC20::symbol() == SYMBOL, 'Symbol should be SYMBOL');
    assert(ERC20::decimals() == 18_u8, 'Decimals should be 18');
    assert(ERC20::total_supply() == u256_from_felt252(2000), 'Supply should eq 2000');
}

