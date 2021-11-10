# rln-circuits
Rate Limit Nullifier circuits implemented in Circom.
This branch contains a generalised version of the construct, allowing for specifying a custom order of the polynomial used in the Shamir's secret sharing equation.

## Circuit specs:
https://hackmd.io/7GR5Vi28Rz2EpEmLK0E0Aw

## Benchmarks

##### System spec:
Processor: `2,6 GHz 6-Core Intel Core i7`
Memory: `16 GB 2667 MHz DDR4`

--- 
`Proof generation time (with witness)` - time to generate witness from input and write to file included
`Proof generation time (without witness)` - time to generate witness from input and write to file excluded

Hasher used: Posseidon with the recommended paramets from the [Posseidon paper](https://eprint.iacr.org/2019/458.pdf) (the hasher parameters are dependent on the number of input arguments). For hashing the merkle tree, the params (3, 8, 56) are used (the merkle tree is binary);

| Curve | Set Size | Limit (polynomial degree) | Num constraints | Proof generation time (with witness) | Proof generation time (without witness) | Proof verification time |  Prover Key Size  | 
| - | - | - | - | - | - | - | - |
| BN128 | 2^16 | 3 | 5354  | 0.820 sec | 0.824 sec | 0.02 sec | 3.08 mb  |
| BN128 | 2^16 | 8 | 6825  | 1.037 sec | 1.001 sec | 0.02 sec | 3.86 mb  |
| BN128 | 2^24 | 3 | 7298  | 0.966 sec | 0.976 sec | 0.02 sec | 4.01 mb  |
| BN128 | 2^24 | 8 | 8769  | 1.271 sec | 1.031 sec | 0.02 sec | 5.31 mb  |
| BN128 | 2^32 | 3 | 9242  | 1.158 sec | 1.128 sec | 0.02 sec | 5.46 mb  |
| BN128 | 2^32 | 8 | 10713  | 1.350 sec | 1.585 sec | 0.02 sec | 6.24 mb  |