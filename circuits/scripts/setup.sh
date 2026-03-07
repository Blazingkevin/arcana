#!/bin/bash
# Usage: ./scripts/setup.sh <circuit-name>
# Example: ./scripts/setup.sh age-verifier
#
# Prerequisites:
#   - circom 2.1.x installed globally (https://docs.circom.io/getting-started/installation/)
#   - snarkjs available (npx snarkjs or global install)
#   - A Powers of Tau file in ptau/ (download from https://github.com/iden3/snarkjs#7-prepare-phase-2)

set -e

CIRCUIT=${1:?Usage: $0 <circuit-name>}
CIRCUIT_DIR="src/${CIRCUIT}"
TARGET_DIR="target/${CIRCUIT}"
PTAU_FILE="ptau/pot14_final.ptau"

if [ ! -f "${CIRCUIT_DIR}/${CIRCUIT}.circom" ]; then
  echo "Error: ${CIRCUIT_DIR}/${CIRCUIT}.circom not found"
  exit 1
fi

if [ ! -f "${PTAU_FILE}" ]; then
  echo "Error: ${PTAU_FILE} not found. Download a Powers of Tau file first."
  echo "  curl -L https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_14.ptau -o ${PTAU_FILE}"
  exit 1
fi

mkdir -p "${TARGET_DIR}"

echo "==> Compiling ${CIRCUIT}..."
circom "${CIRCUIT_DIR}/${CIRCUIT}.circom" \
  --r1cs \
  --wasm \
  --sym \
  --output "${TARGET_DIR}"

echo "==> Generating zkey (phase 2 setup)..."
npx snarkjs groth16 setup \
  "${TARGET_DIR}/${CIRCUIT}.r1cs" \
  "${PTAU_FILE}" \
  "${TARGET_DIR}/${CIRCUIT}_0000.zkey"

echo "==> Contributing to phase 2..."
npx snarkjs zkey contribute \
  "${TARGET_DIR}/${CIRCUIT}_0000.zkey" \
  "keys/${CIRCUIT}.zkey" \
  --name="Arcana Protocol" \
  -e="$(head -c 64 /dev/urandom | base64)"

echo "==> Exporting verification key..."
npx snarkjs zkey export verificationkey \
  "keys/${CIRCUIT}.zkey" \
  "keys/${CIRCUIT}-vk.json"

echo "==> Done. Verification key written to keys/${CIRCUIT}-vk.json"
echo "    Commit keys/${CIRCUIT}-vk.json but NOT keys/${CIRCUIT}.zkey"
