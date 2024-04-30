# solana-poh
Solana’s Proof-of-History (PoH) written in Zig

This project emulates the same logic to create a continuous PoH chain over time while
receiving hashes to mix into the chain.

### Build Dependencies

- Zig 0.12.0 - Choose one:
  - [Binary Releases](https://ziglang.org/download/) (extract and add to PATH)
  - [Install with a package manager](https://github.com/ziglang/zig/wiki/Install-Zig-from-a-Package-Manager)
  - Manage multiple versions with [zigup](https://github.com/marler8997/zigup) or [zvm](https://www.zvm.app/)


## Build

```bash
zig build
```

## Run

Run solana-poh with `zig` or execute the binary you already built:

```bash
zig build run
```

```bash
./zig-out/bin/solana-poh
```
