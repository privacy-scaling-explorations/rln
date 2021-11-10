# rln-circuits
Rate Limit Nullifier implemented in circom

## Circuit specs:
https://hackmd.io/7GR5Vi28Rz2EpEmLK0E0Aw

## Benchmarks

##### System spec:
Processor: `2,6 GHz 6-Core Intel Core i7`
Memory: `16 GB 2667 MHz DDR4`

--- 
`Proof generation time (with witness)` - time to generate witness from input and write to file included
`Proof generation time (without witness)` - time to generate witness from input and write to file excluded

| Curve, Hasher | Set Size | Num constraints | Proof generation time (with witness) | Proof generation time (without witness) | Proof verification time |  Prover Key Size   | 
| - | - | - | - | - | - | - |
| BN128, Poseidon (3, 8, 56) | 2^16 | 4339  | 0.749 sec | 0.728 sec | 0.02 sec | 2.58 mb  |
| BN128, Poseidon (3, 8, 56) | 2^24 | 6283  | 0.915 sec | 0.813 sec | 0.02 sec | 3.51 mb  |
| BN128, Poseidon (3, 8, 56) | 2^32 | 8227  | 1.202 sec | 1.157 sec | 0.02 sec | 4.96 mb  |