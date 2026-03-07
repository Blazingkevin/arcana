import * as snarkjs from 'snarkjs'
import * as fs from 'fs'
import * as path from 'path'

/**
 * Locally verify a Groth16 proof.
 *
 * Usage: npx ts-node scripts/verify.ts <circuit-name> [proof-file]
 * Example: npx ts-node scripts/verify.ts age-verifier
 *          npx ts-node scripts/verify.ts age-verifier target/age-verifier/proof.json
 */

const [, , circuitName, proofFile] = process.argv

if (!circuitName) {
  console.error('Usage: npx ts-node scripts/verify.ts <circuit-name> [proof-file]')
  process.exit(1)
}

const vkPath = path.resolve(`keys/${circuitName}-vk.json`)
const proofPath = path.resolve(proofFile ?? `target/${circuitName}/proof.json`)

if (!fs.existsSync(vkPath)) {
  console.error(`Verification key not found: ${vkPath}`)
  console.error(`Run ./scripts/setup.sh ${circuitName} first`)
  process.exit(1)
}

if (!fs.existsSync(proofPath)) {
  console.error(`Proof not found: ${proofPath}`)
  console.error(`Run scripts/prove.ts ${circuitName} <input> first`)
  process.exit(1)
}

const vk = JSON.parse(fs.readFileSync(vkPath, 'utf-8'))
const { proof, publicSignals } = JSON.parse(fs.readFileSync(proofPath, 'utf-8'))

async function main() {
  const valid = await snarkjs.groth16.verify(vk, publicSignals, proof)

  if (valid) {
    console.log('Proof is VALID')
  } else {
    console.error('Proof is INVALID')
    process.exit(1)
  }
}

main().catch((err) => {
  console.error(err)
  process.exit(1)
})
