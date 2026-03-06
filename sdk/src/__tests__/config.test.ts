import { describe, it, expect } from 'vitest'
import { parseEnv, requireAddress, ArcanaConfigError } from '@arcana/config'

describe('ArcanaConfigError', () => {
  it('throws ArcanaConfigError with correct message when required address is missing', () => {
    const env = parseEnv({
      STARKNET_RPC_URL: 'https://starknet-sepolia.public.blastapi.io',
    })

    expect(() => requireAddress(env, 'ARCANA_CREDENTIAL_REGISTRY_ADDRESS')).toThrowError(
      new ArcanaConfigError('missing ARCANA_CREDENTIAL_REGISTRY_ADDRESS'),
    )
  })

  it('throws when RPC URL is missing', () => {
    expect(() => parseEnv({})).toThrow(ArcanaConfigError)
  })

  it('returns parsed env with valid config', () => {
    const env = parseEnv({
      STARKNET_RPC_URL: 'https://starknet-sepolia.public.blastapi.io',
      ARCANA_CREDENTIAL_REGISTRY_ADDRESS: '0xdeadbeef',
    })
    expect(env.ARCANA_CREDENTIAL_REGISTRY_ADDRESS).toBe('0xdeadbeef')
    expect(env.STARKNET_NETWORK).toBe('sepolia')
  })
})
