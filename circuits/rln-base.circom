pragma circom 2.0.0;

include "./incrementalMerkleTree.circom";
include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/comparators.circom";

template CalculateIdentityCommitment() {
    signal input identity_secret;
    signal output out;

    component hasher = Poseidon(1);
    hasher.inputs[0] <== identity_secret;

    out <== hasher.out;
}

template CalculateExternalNullifier() {
    signal input epoch;
    signal input rln_identifier;

    signal output out;

    component hasher = Poseidon(2);
    hasher.inputs[0] <== epoch;
    hasher.inputs[1] <== rln_identifier;

    out <== hasher.out;
}

template CalculateA1() {
    signal input a_0;
    signal input external_nullifier;

    signal output out;

    component hasher = Poseidon(2);
    hasher.inputs[0] <== a_0;
    hasher.inputs[1] <== external_nullifier;
    var hash = hasher.out;

    // At this point we have hash = Poseidon([a0, external_nullifier])
    // However hash = f(a0) only depends on the secret value a0, and its value can be 
    // represented by a set of polynomials that might allow an attacker to successfuly
    // recover a0 from shares

    // To avoid this, we deterministically randomize the value of a1
    // from hash to (hash % p1)*(hash % p2)
    // Intuitively, this corresponds to introducing two new variables x1, x2 so that
    // a1 = (f(a0) - x1*p1)*(f(a0) - x2*p2) % p = g(a0, x1, x2) % p
    // and this will prevent any algebraic attacks over a single share.
    // We note that the actual values of x1, x2 in the share computation will randomly change at each epoch
    
    // Few other observations:
    //  i) p1,p2 are chosen so that p1*p2 = p-1. In this way the final bitsize of a1 does not look biased
    // ii) We chose to use two p1 ~ p2 reductions instead of a single p0 ~ p, because otherwise we increase the probability that f(a0) < p0 (or they differs by few multiples of p0) and so a1 = f(a0) or a1 = f(a0) + r*p0 with small and guessable r.

    // Here p1*p2 == p-1
    var p1 = 144482646498173195876660926226499076096;
    var p2 = 151493922642924629324195768596320362496;
    
    // We compute hash % p1
    signal q1;
    signal r1;
    r1 <-- hash % p1;
    q1 <-- hash \ p1;
    hasher.out === q1*p1 + r1;
    // We ensure that r1 < p1
    component lt1 = LessThan(127); // Both p1 and p2 are 127 bits long  
    lt1.in[0] <== r1;
    lt1.in[1] <== p1;
    lt1.out === 1;

    // We compute hash % p2
    signal q2;
    signal r2;
    r2 <-- hash % p2;
    q2 <-- hash \ p2;
    hasher.out === q2*p2 + r2;
    // We ensure that r2 < p2
    component lt2 = LessThan(127); // Both p1 and p2 are 127 bits long
    lt2.in[0] <== r2;
    lt2.in[1] <== p2;
    lt2.out === 1;

    out <== r1*r2;
}

template CalculateInternalNullifier() {
    signal input a_1;
    signal output out;

    component hasher = Poseidon(1);
    hasher.inputs[0] <== a_1;

    out <== hasher.out;
}

template RLN(n_levels) {
    // constants
    var LEAVES_PER_NODE = 2;
    var LEAVES_PER_PATH_LEVEL = LEAVES_PER_NODE - 1;

    // private signals
    signal input identity_secret;
    signal input path_elements[n_levels][LEAVES_PER_PATH_LEVEL];
    signal input identity_path_index[n_levels];

    // public signals
    signal input x; // x is actually just the signal hash
    signal input epoch;
    signal input rln_identifier;

    // outputs
    signal output y;
    signal output root;
    signal output nullifier;

    // commitment calculation
    component identity_commitment = CalculateIdentityCommitment();
    identity_commitment.identity_secret <== identity_secret;

    // 1. Part
    // Merkle Tree inclusion proof
    var i;
    var j;
    component inclusionProof = MerkleTreeInclusionProof(n_levels);
    inclusionProof.leaf <== identity_commitment.out;

    for (i = 0; i < n_levels; i++) {
        for (j = 0; j < LEAVES_PER_PATH_LEVEL; j++) {
            inclusionProof.path_elements[i][j] <== path_elements[i][j];
        }
        inclusionProof.path_index[i] <== identity_path_index[i];
    }

    root <== inclusionProof.root;

    // 2. Part
    // Line Equation Constraints
    //
    // external_nullifier = Poseidon([epoch, rln_identifier])
    // a_1 = Poseidon([a_0, external_nullifier])
    // internal_nullifier = Poseidon([a_1])
    // 
    // share_y == a_0 + a_1 * x
    component external_nullifier = CalculateExternalNullifier();
    external_nullifier.epoch <== epoch;
    external_nullifier.rln_identifier <== rln_identifier;

    component a_1 = CalculateA1();
    a_1.a_0 <== identity_secret;
    a_1.external_nullifier <== external_nullifier.out;

    y <== identity_secret + a_1.out * x;
    component calculateNullifier = CalculateInternalNullifier();
    calculateNullifier.a_1 <== a_1.out;

    nullifier <== calculateNullifier.out;
}