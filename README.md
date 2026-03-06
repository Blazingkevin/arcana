# Arcana Protocol

**A composable privacy stack for Starknet — ZK Credentials + Stealth Addresses, unified.**

Arcana lets users prove things about themselves (age, humanity, KYC status) without revealing who they are, and receive payments without linking their identity to an on-chain address.

## Packages

| Package | Description |
|---------|-------------|
| `contracts/` | Cairo smart contracts — CredentialRegistry, IssuerRegistry, StealthAccount |
| `circuits/` | Circom ZK circuits — AgeVerifier, UniqueHumanVerifier |
| `sdk/` | `@arcana/sdk` — TypeScript SDK for credentials and stealth addresses |
| `demo/` | Next.js demo DApp showcasing the full protocol flow |
| `scripts/` | Deployment, proof generation, and trusted setup scripts |
| `tests/` | Integration test suite |
| `docs/` | Protocol documentation and SNIP drafts |

## Quick Start

```bash
npm install
turbo build
```

## Built for

Starknet RE{DEFINE} Hackathon 2025
