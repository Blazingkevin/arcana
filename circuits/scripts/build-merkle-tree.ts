import * as fs from 'fs'
import * as path from 'path'
// @ts-ignore — no types for circomlibjs
import { buildPoseidon } from 'circomlibjs'

/**
 * Builds a Poseidon Merkle tree from a list of user secrets and outputs
 * the proof path for a given leaf index.
 *
 * Usage:
 *   npx ts-node scripts/build-merkle-tree.ts <leaf-index> [members-file]
 *
 * members-file: JSON array of user_secret strings, defaults to inputs/members.json
 *
 * Output: JSON written to stdout with the fields needed for unique_human_verifier.circom
 */

const TREE_DEPTH = 16
const ZERO_VALUE = BigInt(0)

const [, , leafIndexArg, membersFileArg] = process.argv

if (leafIndexArg === undefined) {
  console.error('Usage: npx ts-node scripts/build-merkle-tree.ts <leaf-index> [members-file]')
  process.exit(1)
}

const leafIndex = parseInt(leafIndexArg, 10)
const membersFile = membersFileArg ?? path.resolve('inputs/members.json')

async function poseidon1(poseidon: (inputs: bigint[]) => Uint8Array, a: bigint): Promise<bigint> {
  return poseidon.F.toObject(poseidon([a]))
}

async function poseidon2(poseidon: (inputs: bigint[]) => Uint8Array, a: bigint, b: bigint): Promise<bigint> {
  return poseidon.F.toObject(poseidon([a, b]))
}

async function poseidon3(poseidon: (inputs: bigint[]) => Uint8Array, a: bigint, b: bigint, c: bigint): Promise<bigint> {
  return poseidon.F.toObject(poseidon([a, b, c]))
}

async function main() {
  const poseidon = await buildPoseidon()

  const members: string[] = JSON.parse(fs.readFileSync(membersFile, 'utf-8'))
  if (leafIndex < 0 || leafIndex >= members.length) {
    console.error(`leaf-index ${leafIndex} out of range (0..${members.length - 1})`)
    process.exit(1)
  }

  const size = Math.pow(2, TREE_DEPTH)
  const leaves: bigint[] = new Array(size).fill(ZERO_VALUE)

  for (let i = 0; i < members.length; i++) {
    leaves[i] = await poseidon1(poseidon, BigInt(members[i]))
  }

  // Build tree level by level
  const tree: bigint[][] = [leaves]
  for (let level = 0; level < TREE_DEPTH; level++) {
    const prev = tree[level]
    const next: bigint[] = []
    for (let i = 0; i < prev.length; i += 2) {
      next.push(await poseidon2(poseidon, prev[i], prev[i + 1]))
    }
    tree.push(next)
  }

  const root = tree[TREE_DEPTH][0]

  // Build proof path for leafIndex
  const pathElements: string[] = []
  const pathIndices: string[] = []
  let idx = leafIndex

  for (let level = 0; level < TREE_DEPTH; level++) {
    const isRight = idx % 2 === 1
    const siblingIdx = isRight ? idx - 1 : idx + 1
    pathElements.push(tree[level][siblingIdx].toString())
    pathIndices.push(isRight ? '1' : '0')
    idx = Math.floor(idx / 2)
  }

  const userSecret = members[leafIndex]

  // Compute nullifier — caller must supply credential_type and issuer_id
  // Shown with placeholder values; replace in actual fixture generation
  const credentialType = BigInt(1)
  const issuerId = BigInt(1)
  const nullifier = await poseidon3(poseidon, BigInt(userSecret), credentialType, issuerId)

  const output = {
    nullifier: nullifier.toString(),
    credential_type: credentialType.toString(),
    issuer_id: issuerId.toString(),
    expires_at: '2026',
    group_root: root.toString(),
    user_secret: userSecret,
    path_elements: pathElements,
    path_indices: pathIndices,
  }

  process.stdout.write(JSON.stringify(output, null, 2) + '\n')
}

main().catch((err) => {
  console.error(err)
  process.exit(1)
})
