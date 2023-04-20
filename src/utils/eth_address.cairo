use serde::Serde;
use zeroable::Zeroable;
use traits::Into;

#[derive(Copy, Drop)]
struct EthAddress {
    address: felt252, 
}
trait EthAddressTrait {
    fn new(address: felt252) -> EthAddress;
}
impl EthAddressImpl of EthAddressTrait {
    // Creates a EthAddress from the given address, if it's a valid Ethereum address. If not,
    // panics with the given error.
    fn new(address: felt252) -> EthAddress {
        // TODO(yuval): change to a constant once u256 literals are supported.
        let ETH_ADDRESS_BOUND = u256 { high: 0x100000000_u128, low: 0_u128 }; // 2 ** 160

        assert(address.into() < ETH_ADDRESS_BOUND, 'INVALID_ETHEREUM_ADDRESS');
        EthAddress { address }
    }
}
impl EthAddressIntoFelt252 of Into<EthAddress, felt252> {
    fn into(self: EthAddress) -> felt252 {
        self.address
    }
}
impl EthAddressSerde of Serde<EthAddress> {
    fn serialize(ref output: Array<felt252>, input: EthAddress) {
        Serde::<felt252>::serialize(ref output, input.address);
    }
    fn deserialize(ref serialized: Span<felt252>) -> Option<EthAddress> {
        // Option::Some(EthAddressTrait::new(*serialized.pop_front()?))
        Option::Some(EthAddressTrait::new(Serde::<felt252>::deserialize(ref serialized)?))
    }
}
impl EthAddressZeroable of Zeroable<EthAddress> {
    fn zero() -> EthAddress {
        EthAddressTrait::new(0)
    }

    #[inline(always)]
    fn is_zero(self: EthAddress) -> bool {
        self.address.is_zero()
    }

    #[inline(always)]
    fn is_non_zero(self: EthAddress) -> bool {
        !self.is_zero()
    }
}
