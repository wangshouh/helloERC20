## About

This is an ERC20 token project that uses [cairo 1.0.0-alpha7](https://github.com/starkware-libs/cairo) . The project includes an implementation of the ERC20/[snip 2](https://github.com/starknet-io/SNIPs/blob/main/SNIPS/snip-2.md) standard and complete unit tests.

I have written a blog post to provide a complete introduction to the development process. If you encounter any Chinese, you can refer to [this link](https://blog.wssh.trade/posts/cairo1-with-erc20/).

## Usage

You should install [cairo 1 toolchain](https://github.com/starkware-libs/cairo) and [scarb](https://docs.swmansion.com/scarb/download).

### Test

```bash
cairo-test --starknet .
```