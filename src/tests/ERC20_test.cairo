use helloERC20::ERC20::ERC20;
use integer::u256;
use integer::u256_from_felt252;
use debug::PrintTrait;

use starknet::contract_address_const;
use starknet::ContractAddress;
use starknet::testing::set_caller_address;

const NAME: felt252 = 'Test';
const SYMBOL: felt252 = 'TET';
const DECIMALS: u8 = 18_u8;

fn setUp() -> ContractAddress {
    let caller = contract_address_const::<1>();
    set_caller_address(caller);
    ERC20::constructor(NAME, SYMBOL, DECIMALS);
    caller
}

#[test]
#[available_gas(2000000)]
fn test_initializer() {
    ERC20::constructor(NAME, SYMBOL, DECIMALS);

    assert(ERC20::name() == NAME, 'Name should be NAME');
    assert(ERC20::symbol() == SYMBOL, 'Symbol should be SYMBOL');
    assert(ERC20::decimals() == 18_u8, 'Decimals should be 18');
}

#[test]
#[available_gas(2000000)]
fn test_approve() {
    let caller: ContractAddress = setUp();
    let spender: ContractAddress = contract_address_const::<2>();
    let amount: u256 = u256_from_felt252(2000);

    ERC20::approve(spender, amount);

    assert(ERC20::allowance(caller, spender) == amount, 'Approve should eq 2000');
}

#[test]
#[available_gas(2000000)]
fn test_mint() {
    let caller = setUp();
    let amount: u256 = u256_from_felt252(2000);

    ERC20::mint(amount);
    assert(ERC20::balance_of(caller) == amount, 'Mint 2000');
}