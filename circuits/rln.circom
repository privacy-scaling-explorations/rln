pragma circom 2.0.0;

include "./rln-base.circom";

component main { public [x, external_nullifier] } = RLN(15);
