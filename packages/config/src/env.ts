import { z } from 'zod'

export class ArcanaConfigError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'ArcanaConfigError'
  }
}

const hexAddress = z
  .string()
  .regex(/^0x[0-9a-fA-F]+$/, 'must be a hex address starting with 0x')

const optionalAddress = z.string().optional()

const envSchema = z.object({
  // Network
  STARKNET_NETWORK: z.enum(['mainnet', 'sepolia']).default('sepolia'),
  STARKNET_RPC_URL: z.string().url(),

  // Deployer account (optional — not needed in browser)
  STARKNET_ACCOUNT: hexAddress.optional(),
  STARKNET_PRIVATE_KEY: hexAddress.optional(),

  // Contract addresses
  ARCANA_ISSUER_REGISTRY_ADDRESS: optionalAddress,
  ARCANA_CREDENTIAL_REGISTRY_ADDRESS: optionalAddress,
  ARCANA_META_ADDRESS_REGISTRY_ADDRESS: optionalAddress,
  ARCANA_ANNOUNCER_ADDRESS: optionalAddress,
  ARCANA_STEALTH_ACCOUNT_CLASS_HASH: optionalAddress,

  // Verifier contracts
  ARCANA_AGE_VERIFIER_ADDRESS: optionalAddress,
  ARCANA_UNIQUE_HUMAN_VERIFIER_ADDRESS: optionalAddress,

  // Demo DApp (Next.js public vars)
  NEXT_PUBLIC_STARKNET_RPC_URL: z.string().url().optional(),
  NEXT_PUBLIC_ISSUER_REGISTRY_ADDRESS: optionalAddress,
})

export type ArcanaEnv = z.infer<typeof envSchema>

export function parseEnv(raw: NodeJS.ProcessEnv = process.env): ArcanaEnv {
  const result = envSchema.safeParse(raw)
  if (!result.success) {
    const issues = result.error.issues
      .map((i) => `${i.path.join('.')}: ${i.message}`)
      .join('\n  ')
    throw new ArcanaConfigError(`Invalid environment configuration:\n  ${issues}`)
  }
  return result.data
}

export function requireAddress(
  env: ArcanaEnv,
  key: keyof ArcanaEnv,
): string {
  const value = env[key]
  if (!value) {
    throw new ArcanaConfigError(`missing ${key}`)
  }
  return value as string
}
