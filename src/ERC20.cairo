use starknet::ContractAddress;
use starknet::eth_address::EthAddress;
use starknet::ClassHash;

#[starknet::interface]
trait IERC20<TContractState> {
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn decimals(self: @TContractState) -> u8;
    fn total_supply(self: @TContractState) -> u256;
    fn balanceOf(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn l1_token_address(self: @TContractState) -> felt252;
    fn transfer(ref self: TContractState, to: ContractAddress, amount: u256) -> bool;
    fn transferFrom(
        ref self: TContractState, from: ContractAddress, to: ContractAddress, amount: u256
    ) -> bool;
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;
    fn mint(ref self: TContractState, amount: u256);
    fn burn(ref self: TContractState, amount: u256);
    fn set_l1_token(ref self: TContractState, l1_token_address: EthAddress);
    fn transfer_to_L1(ref self: TContractState, l1_recipient: EthAddress, amount: u256);
    fn upgrade(self: @TContractState, new_class_hash: ClassHash);
}

#[starknet::contract]
mod ERC20 {
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    use starknet::ClassHash;
    use starknet::syscalls::replace_class_syscall;
    use starknet::contract_address_const;
    use starknet::syscalls::send_message_to_l1_syscall;
    use starknet::eth_address::EthAddress;
    use starknet::eth_address::EthAddressZeroable;
    use starknet::eth_address::EthAddressIntoFelt252;

    use array::ArrayTrait;
    use zeroable::Zeroable;
    use traits::Into;
    use integer::BoundedInt;

    #[storage]
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
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
        SetL1Token: SetL1Token,
        TransferToL1: TransferToL1,
        DepositFromL1: DepositFromL1,
    }
    #[derive(Drop, PartialEq, starknet::Event)]
    struct Transfer {
        #[key]
        from: ContractAddress,
        #[key]
        to: ContractAddress,
        value: u256,
    }
    #[derive(Drop, PartialEq, starknet::Event)]
    struct Approval {
        #[key]
        owner: ContractAddress,
        #[key]
        spender: ContractAddress,
        value: u256,
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    struct SetL1Token {
        #[key]
        l1token: EthAddress
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    struct TransferToL1 {
        #[key]
        l2_sender: ContractAddress,
        #[key]
        l1_recipient: EthAddress,
        value: u256,
    }

    #[derive(Drop, PartialEq, starknet::Event)]
    struct DepositFromL1 {
        #[key]
        account: ContractAddress,
        amount: u256,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: felt252,
        symbol: felt252,
        decimals: u8,
        governor: ContractAddress
    ) {
        self._name.write(name);
        self._symbol.write(symbol);
        self._decimals.write(decimals);
        self.governor.write(governor);
    }


    #[external(v0)]
    impl IERC20Impl of super::IERC20<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self._name.read()
        }

        fn symbol(self: @ContractState) -> felt252 {
            self._symbol.read()
        }

        fn decimals(self: @ContractState) -> u8 {
            self._decimals.read()
        }

        fn total_supply(self: @ContractState) -> u256 {
            self._total_supply.read()
        }

        fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            self._balances.read(account)
        }

        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> u256 {
            self._allowances.read((owner, spender))
        }

        fn l1_token_address(self: @ContractState) -> felt252 {
            self.l1_token.read().into()
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
            let owner = get_caller_address();
            self._allowances.write((owner, spender), amount);
            self.emit(Event::Approval(Approval { owner, spender, value: amount }));

            true
        }

        fn mint(ref self: ContractState, amount: u256) {
            let sender = get_caller_address();
            self._total_supply.write(self._total_supply.read() + amount);
            self._balances.write(sender, self._balances.read(sender) + amount);

            self
                .emit(
                    Event::Transfer(
                        Transfer { from: contract_address_const::<0>(), to: sender, value: amount }
                    )
                );
        }

        fn burn(ref self: ContractState, amount: u256) {
            self.burn_helper(amount);
        }

        fn transfer(ref self: ContractState, to: ContractAddress, amount: u256) -> bool {
            let from = get_caller_address();

            self._balances.write(from, self._balances.read(from) - amount);
            self._balances.write(to, self._balances.read(to) + amount);

            self.emit(Event::Transfer(Transfer { from, to, value: amount }));

            true
        }

        fn transferFrom(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256
        ) -> bool {
            let caller = get_caller_address();
            let allowed: u256 = self._allowances.read((from, caller));

            if !(allowed == BoundedInt::max()) {
                self._allowances.write((from, caller), allowed - amount);
                self
                    .emit(
                        Event::Approval(
                            Approval { owner: from, spender: caller, value: allowed - amount }
                        )
                    );
            }

            self._balances.write(from, self._balances.read(from) - amount);
            self._balances.write(to, self._balances.read(to) + amount);

            self.emit(Event::Transfer(Transfer { from, to, value: amount }));

            true
        }

        fn set_l1_token(ref self: ContractState, l1_token_address: EthAddress) {
            assert(get_caller_address() == self.governor.read(), 'GOVERNOR_ONLY');

            assert(self.l1_token.read().is_zero(), 'L1_token_ALREADY_INITIALIZED');
            assert(l1_token_address.is_non_zero(), 'ZERO_token_ADDRESS');

            self.l1_token.write(l1_token_address.into());
            self.emit(Event::SetL1Token(SetL1Token { l1token: l1_token_address }))
        }

        fn transfer_to_L1(ref self: ContractState, l1_recipient: EthAddress, amount: u256) {
            self.burn_helper(amount);

            let caller_address = get_caller_address();

            let mut message_payload = array![
                l1_recipient.into(), amount.low.into(), amount.high.into()
            ];

            send_message_to_l1_syscall(
                to_address: self.l1_token.read(), payload: message_payload.span()
            );

            self
                .emit(
                    Event::TransferToL1(
                        TransferToL1 { l2_sender: caller_address, l1_recipient, value: amount }
                    )
                )
        }

        fn upgrade(self: @ContractState, new_class_hash: ClassHash) {
            replace_class_syscall(new_class_hash);
        }
    }

    #[l1_handler]
    fn despoit_from_L1(
        ref self: ContractState, from_address: felt252, account: ContractAddress, amount: u256
    ) {
        assert(from_address == self.l1_token.read(), 'EXPECTED_FROM_BRIDGE_ONLY');

        self._total_supply.write(self._total_supply.read() + amount);
        self._balances.write(account, self._balances.read(account) + amount);

        self.emit(Event::DepositFromL1(DepositFromL1 { account, amount }));
    }

    #[generate_trait]
    impl StorageImpl of StorageTrait {
        fn burn_helper(ref self: ContractState, amount: u256) {
            let zero_address = contract_address_const::<0>();
            let sender = get_caller_address();
            self._total_supply.write(self._total_supply.read() - amount);
            self._balances.write(sender, self._balances.read(sender) - amount);

            self.emit(Event::Transfer(Transfer { from: sender, to: zero_address, value: amount }));
        }
    }
}
