# zb

A Game Boy emulator in Zig.

## Tests

```bash
cd tests
git clone https://github.com/SingleStepTests/sm83.git
```

Run all single step CPU tests:

```bash
zig build test -Dtest-dir=tests/sm83/v1/
```

Run specific test:

```bash
zig build test -Dtest-dir=tests/sm83/v1/ -Dtest-filter=00.json
```
