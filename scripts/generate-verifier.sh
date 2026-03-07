#!/bin/bash
# Usage: ./generate-verifier.sh <circuit-name>
# Example: ./generate-verifier.sh age-verifier
#
# Prerequisites:
#   - garaga installed: pip install garaga
#   - Verification key JSON at circuits/keys/<circuit-name>-vk.json
#     (produced by circuits/scripts/setup.sh after trusted setup)

set -e

CIRCUIT=${1:?Usage: $0 <circuit-name>}
VK_PATH="circuits/keys/${CIRCUIT}-vk.json"
OUTPUT_DIR="contracts/credentials/src/verifiers/${CIRCUIT}"

if [ ! -f "${VK_PATH}" ]; then
  echo "Error: verification key not found at ${VK_PATH}"
  echo "Run circuits/scripts/setup.sh ${CIRCUIT} first"
  exit 1
fi

garaga gen \
  --system groth16 \
  --vk "${VK_PATH}" \
  --output "${OUTPUT_DIR}"

echo "Verifier generated at ${OUTPUT_DIR}/"
