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

fn MAX_U256() -> u256 {
    u256 {
        low: 0xffffffffffffffffffffffffffffffff_u128, high: 0xffffffffffffffffffffffffffffffff_u128
    }
}

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
    assert(ERC20::balanceOf(caller) == amount, 'Mint 2000');
}

#[test]
#[available_gas(2000000)]
fn test_burn() {
    let caller = setUp();
    let amount: u256 = u256_from_felt252(2000);

    ERC20::mint(amount);
    ERC20::burn(u256_from_felt252(1000));
    assert(ERC20::balanceOf(caller) == u256_from_felt252(1000), 'Burn 1000');
}

#[test]
#[available_gas(2000000)]
fn test_transfer() {
    let from = setUp();
    let to = contract_address_const::<2>();
    let amount: u256 = u256_from_felt252(2000);

    ERC20::mint(amount);
    ERC20::transfer(to, amount);

    assert(ERC20::balanceOf(from) == u256_from_felt252(0), 'Balance from = 0');
    assert(ERC20::balanceOf(to) == amount, 'Balance to = 2000');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('u256_sub Overflow', ))]
fn test_err_transfer() {
    let from = setUp();
    let to = contract_address_const::<2>();
    let amount: u256 = u256_from_felt252(2000);

    ERC20::mint(amount);
    ERC20::transfer(to, u256_from_felt252(3000));

    assert(ERC20::balanceOf(from) == u256_from_felt252(0), 'Balance from = 0');
    assert(ERC20::balanceOf(to) == amount, 'Balance to = 2000');
}

#[test]
#[available_gas(2000000)]
fn test_transferFrom() {
    let amount: u256 = u256_from_felt252(2000);

    let owner = setUp();

    let from = contract_address_const::<2>();
    let to = contract_address_const::<3>();

    ERC20::mint(amount);
    ERC20::approve(from, amount);

    set_caller_address(from);

    ERC20::transferFrom(owner, to, u256_from_felt252(1000));

    assert(ERC20::balanceOf(owner) == u256_from_felt252(1000), 'Balance owner == 1000');
    assert(ERC20::balanceOf(to) == u256_from_felt252(1000), 'Balance to == 1000');
    assert(ERC20::allowance(owner, from) == u256_from_felt252(1000), 'Approve == 1000')
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('u256_sub Overflow', ))]
fn test_FailtransferFrom() {
    let amount: u256 = u256_from_felt252(2000);

    let owner = setUp();

    let from = contract_address_const::<2>();
    let to = contract_address_const::<3>();

    ERC20::mint(amount);
    ERC20::approve(from, u256_from_felt252(1000));

    set_caller_address(from);

    ERC20::transferFrom(owner, to, amount);
}

#[test]
#[available_gas(2000000)]
fn test_MAXApproveTransfer() {
    let max: u256 = MAX_U256();

    let amount: u256 = u256_from_felt252(2000);

    let owner = setUp();

    let from = contract_address_const::<2>();
    let to = contract_address_const::<3>();

    ERC20::mint(amount);
    ERC20::approve(from, max);

    set_caller_address(from);

    ERC20::transferFrom(owner, to, u256_from_felt252(1000));

    assert(ERC20::allowance(owner, from) == max, 'Max Approve invarient')
}
