import * as snarkjs from 'snarkjs'
import * as fs from 'fs'
import * as path from 'path'

/**
 * Generate a Groth16 proof for a circuit.
 *
 * Usage: npx ts-node scripts/prove.ts <circuit-name> <input-file>
 * Example: npx ts-node scripts/prove.ts age-verifier inputs/age-verifier-fixture.json
 */

const [, , circuitName, inputFile] = process.argv

if (!circuitName || !inputFile) {
  console.error('Usage: npx ts-node scripts/prove.ts <circuit-name> <input-file>')
  process.exit(1)
}

const wasmPath = path.resolve(`target/${circuitName}/${circuitName}_js/${circuitName}.wasm`)
const zkeyPath = path.resolve(`keys/${circuitName}.zkey`)
const inputPath = path.resolve(inputFile)

if (!fs.existsSync(wasmPath)) {
  console.error(`WASM not found: ${wasmPath}`)
  console.error(`Run ./scripts/setup.sh ${circuitName} first`)
  process.exit(1)
}

if (!fs.existsSync(zkeyPath)) {
  console.error(`Proving key not found: ${zkeyPath}`)
  console.error(`Run ./scripts/setup.sh ${circuitName} first`)
  process.exit(1)
}

const input = JSON.parse(fs.readFileSync(inputPath, 'utf-8'))

async function main() {
  const { proof, publicSignals } = await snarkjs.groth16.fullProve(input, wasmPath, zkeyPath)

  const output = { proof, publicSignals }
  const outPath = path.resolve(`target/${circuitName}/proof.json`)
  fs.mkdirSync(path.dirname(outPath), { recursive: true })
  fs.writeFileSync(outPath, JSON.stringify(output, null, 2))

  console.log(`Proof written to ${outPath}`)
  console.log('Public signals:', publicSignals)
}

main().catch((err) => {
  console.error(err)
  process.exit(1)
})
