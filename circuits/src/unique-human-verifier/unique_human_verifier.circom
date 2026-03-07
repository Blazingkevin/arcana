pragma circom 2.1.0;

include "../../node_modules/circomlib/circuits/poseidon.circom";
// NOTE: circomlib provides Mux1, not MultiMux1. Use Mux1 for each left/right selection.
include "../../node_modules/circomlib/circuits/mux1.circom";

// Proves membership in a Merkle tree of verified humans.
// The Merkle leaf = Poseidon(user_secret). The root is the issuer's public group root.
// Inspired by Semaphore but adapted for Arcana's nullifier scheme.
template UniqueHumanVerifier(TREE_DEPTH) {
    // Public inputs
    signal input nullifier;           // Poseidon(user_secret, credential_type, issuer_id)
    signal input credential_type;
    signal input issuer_id;
    signal input expires_at;
    signal input group_root;          // Merkle root of the issuer's verified-human group

    // Private inputs
    signal input user_secret;
    signal input path_elements[TREE_DEPTH];   // sibling hashes along Merkle path
    signal input path_indices[TREE_DEPTH];    // 0 = left, 1 = right

    // === Constraint 1: nullifier derivation ===
    component nullifier_hasher = Poseidon(3);
    nullifier_hasher.inputs[0] <== user_secret;
    nullifier_hasher.inputs[1] <== credential_type;
    nullifier_hasher.inputs[2] <== issuer_id;
    nullifier_hasher.out === nullifier;

    // === Constraint 2: leaf = Poseidon(user_secret) ===
    component leaf_hasher = Poseidon(1);
    leaf_hasher.inputs[0] <== user_secret;

    // === Constraint 3: Merkle path verification ===
    // Use Mux1 (circomlib) — selects between (current, sibling) or (sibling, current)
    // based on path_indices[i]. Two Mux1 components per level (one per hash input).
    component hashers[TREE_DEPTH];
    component mux_left[TREE_DEPTH];
    component mux_right[TREE_DEPTH];
    signal current_hash[TREE_DEPTH + 1];
    current_hash[0] <== leaf_hasher.out;

    for (var i = 0; i < TREE_DEPTH; i++) {
        hashers[i] = Poseidon(2);

        // When path_indices[i]=0: left=current_hash, right=sibling
        // When path_indices[i]=1: left=sibling, right=current_hash
        mux_left[i] = Mux1();
        mux_left[i].c[0] <== current_hash[i];
        mux_left[i].c[1] <== path_elements[i];
        mux_left[i].s <== path_indices[i];

        mux_right[i] = Mux1();
        mux_right[i].c[0] <== path_elements[i];
        mux_right[i].c[1] <== current_hash[i];
        mux_right[i].s <== path_indices[i];

        hashers[i].inputs[0] <== mux_left[i].out;
        hashers[i].inputs[1] <== mux_right[i].out;
        current_hash[i + 1] <== hashers[i].out;
    }

    current_hash[TREE_DEPTH] === group_root;
}

// TREE_DEPTH = 16 supports up to 2^16 = ~65k verified humans per group.
// Estimated constraints: ~16 * (Poseidon(2) ≈ 300 + 2*Mux1 ≈ 6) + nullifier ≈ 5000.
// This fits within pot16 (2^16 = 65536 constraints) — no need for pot20.
component main {public [nullifier, credential_type, issuer_id, expires_at, group_root]} = UniqueHumanVerifier(16);
