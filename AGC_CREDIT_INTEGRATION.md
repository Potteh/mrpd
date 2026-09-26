# AGC Credit Integration

This build routes qb-inventory shop purchases through `agc-credit`.

## Requirements

- `qb-core`
- `qb-shops`
- `agc-credit` v3 or newer

Start `agc-credit` before `qb-inventory`/`qb-shops` in `server.cfg`.

```cfg
ensure qb-core
ensure agc-credit
ensure qb-inventory
ensure qb-shops
```

At checkout, AGC Credit lets the player choose Cash, Debit (QBCore bank), or an eligible Credit Card. The item is granted only after the server-side payment callback succeeds.
