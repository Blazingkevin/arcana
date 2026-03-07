# Garaga Output Structure

[Garaga](https://github.com/keep-starknet-strange/garaga) generates Cairo Groth16 verifier contracts from a snarkjs verification key JSON.

## Command

```bash
garaga gen \
  --system groth16 \
  --vk circuits/keys/<circuit-name>-vk.json \
  --output contracts/credentials/src/verifiers/<circuit-name>/
```

Use `scripts/generate-verifier.sh <circuit-name>` as a convenience wrapper.

## Generated Files

```
contracts/credentials/src/verifiers/<circuit-name>/
├── Scarb.toml                        ← Scarb package config (curve-specific deps)
├── src/
│   ├── lib.cairo                     ← module declarations
│   ├── groth16_verifier.cairo        ← main verifier contract + IGroth16Verifier trait
│   └── groth16_verifier_constants.cairo  ← embedded VK constants (alpha, beta, gamma, delta, IC)
└── target/                           ← compiled artifacts (gitignored)
```

## Key Details

- **Supported curves**: BN254 and BLS12-381. Garaga auto-detects from the vk.json.
- **Verifier interface**: exposes `verify_groth16_proof_bn254` (or `_bls12_381`) taking `full_proof_with_hints: Span<felt252>`.
- **Constants file**: the VK is embedded as Cairo constants — no runtime key loading.
- **Proof hints**: Garaga's `garaga calldata` command formats proof + public signals into `full_proof_with_hints` for on-chain submission.

## Workflow

1. Write and compile the Circom circuit (`circuits/src/<name>/<name>.circom`)
2. Run trusted setup: `circuits/scripts/setup.sh <name>` → produces `circuits/keys/<name>-vk.json`
3. Generate Cairo verifier: `scripts/generate-verifier.sh <name>`
4. Integrate the generated module into `contracts/credentials/src/lib.cairo`
5. Format proof for on-chain use: `garaga calldata --system groth16 --vk circuits/keys/<name>-vk.json --proof <proof.json> --pub <public.json>`

## What to Commit

| Path | Commit? |
|------|---------|
| `circuits/keys/<name>-vk.json` | Yes |
| `circuits/keys/<name>.zkey` | No (gitignored) |
| `contracts/credentials/src/verifiers/<name>/src/*.cairo` | Yes |
| `contracts/credentials/src/verifiers/<name>/target/` | No (gitignored) |
