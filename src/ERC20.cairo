use starknet::ContractAddress;

trait IERC20 {
    fn name() -> felt252;
    fn symbol() -> felt252;
    fn decimals() -> u8;
    fn total_supply() -> u256;
    fn balanceOf(account: ContractAddress) -> u256;
    fn allowance(owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(recipient: ContractAddress, amount: u256) -> bool;
    fn transferFrom(sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool;
    fn approve(spender: ContractAddress, amount: u256) -> bool;
}

#[contract]
mod ERC20 {
    use helloERC20::ERC20::IERC20;
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    use starknet::ContractAddressZeroable;
    use starknet::contract_address_const;
    use zeroable::Zeroable;
    use traits::Into;

    use helloERC20::utils::eth_address::EthAddress;
    use helloERC20::utils::eth_address::EthAddressZeroable;
    use helloERC20::utils::eth_address::EthAddressIntoFelt252;

    struct Storage {
        _name: felt252,
        _symbol: felt252,
        _decimals: u8,
        _total_supply: u256,
        _balances: LegacyMap<ContractAddress, u256>,
        _allowances: LegacyMap<(ContractAddress, ContractAddress), u256>,
        governor: ContractAddress,
        l1_token: felt252,
    }

    #[event]
    fn Transfer(from: ContractAddress, to: ContractAddress, value: u256) {}

    #[event]
    fn Approval(owner: ContractAddress, spender: ContractAddress, value: u256) {}

    #[event]
    fn l1_token_set(l1_token_address: EthAddress) {}

    #[constructor]
    fn constructor(name: felt252, symbol: felt252, decimals: u8, ) {
        _name::write(name);
        _symbol::write(symbol);
        _decimals::write(decimals);
        governor::write(get_caller_address());
    }

    #[view]
    fn name() -> felt252 {
        _name::read()
    }

    #[view]
    fn symbol() -> felt252 {
        _symbol::read()
    }

    #[view]
    fn decimals() -> u8 {
        _decimals::read()
    }

    #[view]
    fn total_supply() -> u256 {
        _total_supply::read()
    }

    #[view]
    fn balanceOf(account: ContractAddress) -> u256 {
        _balances::read(account)
    }

    #[view]
    fn allowance(owner: ContractAddress, spender: ContractAddress) -> u256 {
        _allowances::read((owner, spender))
    }

    #[external]
    fn approve(spender: ContractAddress, amount: u256) -> bool {
        let owner = get_caller_address();

        _allowances::write((owner, spender), amount);

        Approval(owner, spender, amount);

        true
    }

    #[external]
    fn mint(amount: u256) {
        let sender = get_caller_address();

        _total_supply::write(_total_supply::read() + amount);
        _balances::write(sender, _balances::read(sender) + amount);
    }

    fn burn(amount: u256) {
        let zero_address = contract_address_const::<0>();
        let sender = get_caller_address();
        _total_supply::write(_total_supply::read() - amount);
        _balances::write(sender, _balances::read(sender) - amount);
    }

    #[external]
    fn transfer(to: ContractAddress, amount: u256) -> bool {
        let from = get_caller_address();

        _balances::write(from, _balances::read(from) - amount);
        _balances::write(to, _balances::read(to) + amount);

        Transfer(from, to, amount);

        true
    }

    #[external]
    fn transferFrom(from: ContractAddress, to: ContractAddress, amount: u256) -> bool {
        let caller = get_caller_address();
        let allowed: u256 = _allowances::read((from, caller));

        let ONES_MASK = 0xffffffffffffffffffffffffffffffff_u128;

        let is_max = (allowed.low == ONES_MASK) & (allowed.high == ONES_MASK);

        if !is_max {
            _allowances::write((from, caller), allowed - amount);
            Approval(from, caller, allowed - amount);
        }

        _balances::write(from, _balances::read(from) - amount);
        _balances::write(to, _balances::read(to) + amount);

        Transfer(from, to, amount);

        true
    }

    #[external]
    fn set_l1_token(l1_token_address: EthAddress) {
        // The call is restricted to the governor.
        assert(get_caller_address() == governor::read(), 'GOVERNOR_ONLY');

        assert(l1_token::read().is_zero(), 'L1_token_ALREADY_INITIALIZED');
        assert(l1_token_address.is_non_zero(), 'ZERO_token_ADDRESS');

        l1_token::write(l1_token_address.into());
        l1_token_set(l1_token_address);
    }
}
