pragma circom 2.1.0;

// NOTE: EdDSAPoseidonVerifier lives in eddsa-poseidon.circom, not eddsa.circom
include "../../node_modules/circomlib/circuits/poseidon.circom";
include "../../node_modules/circomlib/circuits/eddsaposeidon.circom";

// Reusable component for all Arcana credential circuits.
// Each credential circuit creates a component of this template and wires its signals.
// Output signal `valid` is constrained to 1 when all checks pass.
template ArcanaCredentialBase(N_CREDENTIAL_FIELDS) {
    // === Public inputs ===
    signal input nullifier;          // Poseidon(user_secret, credential_type, issuer_id)
    signal input credential_type;    // felt252 identifier e.g. 'AGE_OVER_18'
    signal input issuer_id;          // u256 issuer identifier

    // === Private inputs ===
    signal input user_secret;        // random secret known only to user
    signal input raw_credential[N_CREDENTIAL_FIELDS]; // underlying credential data
    signal input issuer_sig_R8x;     // EdDSA signature R8 x-coordinate
    signal input issuer_sig_R8y;     // EdDSA signature R8 y-coordinate
    signal input issuer_sig_S;       // EdDSA signature S
    signal input issuer_pub_key_x;   // issuer's public key x
    signal input issuer_pub_key_y;   // issuer's public key y

    // === Constraint 1: nullifier is correctly derived ===
    component nullifier_hasher = Poseidon(3);
    nullifier_hasher.inputs[0] <== user_secret;
    nullifier_hasher.inputs[1] <== credential_type;
    nullifier_hasher.inputs[2] <== issuer_id;
    nullifier_hasher.out === nullifier;

    // === Constraint 2: issuer signed Poseidon(user_secret, Poseidon(raw_credential...)) ===
    component cred_hasher = Poseidon(N_CREDENTIAL_FIELDS);
    for (var i = 0; i < N_CREDENTIAL_FIELDS; i++) {
        cred_hasher.inputs[i] <== raw_credential[i];
    }

    component msg_hasher = Poseidon(2);
    msg_hasher.inputs[0] <== user_secret;
    msg_hasher.inputs[1] <== cred_hasher.out;

    component eddsa = EdDSAPoseidonVerifier();
    eddsa.enabled <== 1;
    eddsa.Ax <== issuer_pub_key_x;
    eddsa.Ay <== issuer_pub_key_y;
    eddsa.R8x <== issuer_sig_R8x;
    eddsa.R8y <== issuer_sig_R8y;
    eddsa.S <== issuer_sig_S;
    eddsa.M <== msg_hasher.out;
}
