export interface StealthMetaAddress {
  spendPublicKey: { x: bigint; y: bigint }
  viewPublicKey: { x: bigint; y: bigint }
}

export interface CredentialRecord {
  nullifier: bigint
  credentialType: string
  issuerId: bigint
  issuedAt: number
  revoked: boolean
}

export interface ArcanaPersona {
  stealthMetaAddress: StealthMetaAddress
  credentials: CredentialRecord[]
  viewPrivateKey: bigint
}
