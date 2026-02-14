# zb

A Game Boy emulator in Zig.

## Run

```bash
zig build run -Doptimize=ReleaseFast
```


## Tests

```bash
cd tests
git clone https://github.com/SingleStepTests/sm83.git
git clone https://github.com/retrio/gb-test-roms.git
```

Run all tests

```bash
zig build test --summary all
```

Run sm83 tests:

```bash
zig build test -Dtest-filter=sm83
```

Run blargg tests:

```bash
zig build test -Dtest-filter=blargg
```
