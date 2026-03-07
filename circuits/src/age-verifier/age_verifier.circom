pragma circom 2.1.0;

include "../templates/arcana_credential.circom";
include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";
// NOTE: eddsa-poseidon.circom, not eddsa.circom
include "../../node_modules/circomlib/circuits/eddsa-poseidon.circom";

// Proves: user's birth_year satisfies (current_year - birth_year) >= min_age
// without revealing birth_year.
template AgeVerifier() {
    // Public inputs
    signal input nullifier;
    signal input credential_type;    // must equal felt252('AGE_OVER_18')
    signal input issuer_id;
    signal input expires_at;
    signal input current_year;       // passed in as public input (from block timestamp)
    signal input min_age;            // e.g. 18

    // Private inputs
    signal input user_secret;
    signal input birth_year;         // the actual private birth year
    signal input issuer_sig_R8x;
    signal input issuer_sig_R8y;
    signal input issuer_sig_S;
    signal input issuer_pub_key_x;
    signal input issuer_pub_key_y;

    // === Constraint 1: nullifier + issuer EdDSA sig (via base component) ===
    // raw_credential[0] = birth_year (single field credential)
    component base = ArcanaCredentialBase(1);
    base.nullifier <== nullifier;
    base.credential_type <== credential_type;
    base.issuer_id <== issuer_id;
    base.user_secret <== user_secret;
    base.raw_credential[0] <== birth_year;
    base.issuer_sig_R8x <== issuer_sig_R8x;
    base.issuer_sig_R8y <== issuer_sig_R8y;
    base.issuer_sig_S <== issuer_sig_S;
    base.issuer_pub_key_x <== issuer_pub_key_x;
    base.issuer_pub_key_y <== issuer_pub_key_y;

    // === Constraint 2: birth_year <= current_year (prevent field underflow) ===
    // LessThan(12) supports values up to 2^12-1 = 4095, covers any valid year
    component year_order = LessThan(12);
    year_order.in[0] <== birth_year;
    year_order.in[1] <== current_year + 1;  // birth_year < current_year + 1 => birth_year <= current_year
    year_order.out === 1;

    // === Constraint 3: age >= min_age ===
    signal age;
    age <== current_year - birth_year;

    // GreaterEqThan(8) supports ages 0-255
    component age_check = GreaterEqThan(8);
    age_check.in[0] <== age;
    age_check.in[1] <== min_age;
    age_check.out === 1;
}

component main {public [nullifier, credential_type, issuer_id, expires_at, current_year, min_age]} = AgeVerifier();
