use hello_erc20::ERC20::ERC20;
use hello_erc20::ERC20::IERC20Dispatcher;
use hello_erc20::ERC20::IERC20DispatcherTrait;
use hello_erc20::ERC20::ERC20::{Event, Approval};

use core::integer::u256;
use core::integer::u256_from_felt252;
use core::integer::BoundedInt;

use starknet::contract_address_const;
use starknet::contract_address::ContractAddress;
use starknet::testing::{set_caller_address, set_contract_address};
use starknet::syscalls::deploy_syscall;
use starknet::SyscallResultTrait;
use starknet::class_hash::Felt252TryIntoClassHash;

use core::test::test_utils::assert_eq;

const NAME: felt252 = 'Test';
const SYMBOL: felt252 = 'TET';
const DECIMALS: u8 = 18_u8;

fn setUp() -> (ContractAddress, IERC20Dispatcher, ContractAddress) {
    let caller = contract_address_const::<1>();
    set_contract_address(caller);

    let mut calldata = array![NAME, SYMBOL, DECIMALS.into()];

    let (erc20_address, _) = deploy_syscall(
        ERC20::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap();

    let mut erc20_token = IERC20Dispatcher { contract_address: erc20_address };

    (caller, erc20_token, erc20_address)
}

#[test]
#[available_gas(2000000)]
fn test_initializer() {
    let mut calldata = array![NAME, SYMBOL, DECIMALS.into()];

    let (erc20_address, _) = deploy_syscall(
        ERC20::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap();

    let erc20_token = IERC20Dispatcher { contract_address: erc20_address };

    assert_eq(@erc20_token.name(), @NAME, 'Name should be NAME');
    assert_eq(@erc20_token.symbol(), @SYMBOL, 'Symbol should be SYMBOL');
    assert_eq(@erc20_token.decimals(), @18_u8, 'Decimals should be 18');
}

#[test]
#[available_gas(2000000)]
fn test_approve() {
    let (caller, erc20_token, erc20_address) = setUp();

    let spender: ContractAddress = contract_address_const::<2>();
    let amount: u256 = u256_from_felt252(2000);

    erc20_token.approve(spender, amount);

    assert(erc20_token.allowance(caller, spender) == amount, 'Approve should eq 2000');
    assert_eq(
        @starknet::testing::pop_log(erc20_address).unwrap(),
        @Event::Approval(Approval { owner: caller, spender: spender, value: amount }),
        'Approve Emit'
    )
}

#[test]
#[available_gas(2000000)]
fn test_mint() {
    let (caller, erc20_token, _) = setUp();
    let amount: u256 = u256_from_felt252(2000);
    erc20_token.mint(amount);
    assert(erc20_token.balanceOf(caller) == amount, 'Mint 2000');
}

#[test]
#[available_gas(2000000)]
fn test_transfer() {
    let (from, erc20_token, _) = setUp();
    let to = contract_address_const::<2>();
    let amount: u256 = u256_from_felt252(2000);

    erc20_token.mint(amount);
    erc20_token.transfer(to, amount);

    assert(erc20_token.balanceOf(from) == u256_from_felt252(0), 'Balance from = 0');
    assert(erc20_token.balanceOf(to) == amount, 'Balance to = 2000');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('u256_sub Overflow', 'ENTRYPOINT_FAILED', ))]
fn test_err_transfer() {
    let (from, erc20_token, _) = setUp();
    let to = contract_address_const::<2>();
    let amount: u256 = u256_from_felt252(2000);

    erc20_token.mint(amount);
    erc20_token.transfer(to, u256_from_felt252(3000));
}

#[test]
#[available_gas(2000000)]
fn test_transferFrom() {
    let amount: u256 = u256_from_felt252(2000);

    let (owner, erc20_token, _) = setUp();

    let from = contract_address_const::<2>();
    let to = contract_address_const::<3>();

    erc20_token.mint(amount);
    erc20_token.approve(from, amount);

    set_contract_address(from);

    erc20_token.transferFrom(owner, to, u256_from_felt252(1000));

    assert(erc20_token.balanceOf(owner) == u256_from_felt252(1000), 'Balance owner == 1000');
    assert(erc20_token.balanceOf(to) == u256_from_felt252(1000), 'Balance to == 1000');
    assert(erc20_token.allowance(owner, from) == u256_from_felt252(1000), 'Approve == 1000')
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('u256_sub Overflow', 'ENTRYPOINT_FAILED', ))]
fn test_FailtransferFrom() {
    let amount: u256 = u256_from_felt252(2000);

    let (owner, erc20_token, _) = setUp();

    let from = contract_address_const::<2>();
    let to = contract_address_const::<3>();

    erc20_token.mint(amount);
    erc20_token.approve(from, u256_from_felt252(1000));

    set_contract_address(from);

    erc20_token.transferFrom(owner, to, amount);
}

#[test]
#[available_gas(2000000)]
fn test_MAXApproveTransfer() {
    let max: u256 = BoundedInt::max();

    let amount: u256 = u256_from_felt252(2000);

    let (owner, erc20_token, _) = setUp();

    let from = contract_address_const::<2>();
    let to = contract_address_const::<3>();

    erc20_token.mint(amount);
    erc20_token.approve(from, max);

    set_contract_address(from);

    erc20_token.transferFrom(owner, to, u256_from_felt252(1000));

    assert(erc20_token.allowance(owner, from) == max, 'Max Approve invarient')
}
