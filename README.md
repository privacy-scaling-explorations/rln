# RLN Circuits

**Cloned from: [https://github.com/privacy-scaling-explorations/rln](https://github.com/privacy-scaling-explorations/rln)**

Rate Limit Nullifier implemented in Circom.

## Running

```sh
./scripts/build-circuits.sh <rln|nrln>
```

## Benchmarks

System specs:

- Processor: `2,6 GHz 6-Core Intel Core i7`
- Memory: `16 GB 2667 MHz DDR4`

- `Proof generation time (with a witness)` - time to generate witness from input and write to file included

- `Proof generation time (without a witness)` - time to generate witness from input and write to file excluded

| Curve, Hasher              | Set Size | Num constraints | Proof generation time (with witness) | Proof generation time (without witness) | Proof verification time | Prover Key Size |
| -------------------------- | -------- | --------------- | ------------------------------------ | --------------------------------------- | ----------------------- | --------------- |
| BN128, Poseidon (3, 8, 56) | 2^16     | 4339            | 0.749 sec                            | 0.728 sec                               | 0.02 sec                | 2.58 mb         |
| BN128, Poseidon (3, 8, 56) | 2^24     | 6283            | 0.915 sec                            | 0.813 sec                               | 0.02 sec                | 3.51 mb         |
| BN128, Poseidon (3, 8, 56) | 2^32     | 8227            | 1.202 sec                            | 1.157 sec                               | 0.02 sec                | 4.96 mb         |

# RLN spec (canonical Poseidon + IncrementalQuinTree)

**Note: For the spec of the old RLN construct implementation please refer to [this link](https://hackmd.io/tMTLMYmTR5eynw2lwK9n1w?both).

## Membership

Each member has a secret key that is denoted by `a_0`. And identity commitment `q` is the hash of the secret key

```
q  = h(a_0)
```

To become a member one must:

* Provide a certain form of stake
* Place themselves in a empty leaf of the membership identity tree (IncrementalQuinTree).

## Signalling

Members are cryptoeconomically bounded to send only one signal in an epoch. Proof system enforces members to reveal their secret key `a_0` when they go beyond that limit.

### Membership

For a valid signal identity commitment `q` must be exists in identity tree. Membership is proven by providing a membership proof (`witness`). The fields from the membership proof required for the verification are: `path_elements` and `identity_path_index`.

### Linear Equation & SSS

Secret key `a_0` which is first coefficient of a linear polynomial. 

Each member _knows_ a linear polynomial for any `epoch` and app (`rln_identifier`) which is derived from secret key `a_0` and the `external_nullifier = hash(epoch, rln_identifier)`. 

```
A(x) = (a_0, a_1)

external_nullifier = (epoch, rln_identifier)
a_1 = h(a_0, external_nullifier)
```

Each member has a secret line equation for an epoch

```
y = a_0 + x a_1
```

Along with a signal members should publicly provide a `(x, y)` share such that satisfies the line equation.

With more that one share anyone can derive `a_0`, the secret id key. Hash of a signal will be evaluation point `x`. So that a member who sends more that one signal reveails the secret key.

Note that shares used in different epochs cannot be used to derive the secret key.

### Nullifiers

There are `external_nullifier` and `internal_nullifier`. 

The `external_nullifier` is required so that the user can securely use the same private key `a_0` across different RLN apps.

`external_nullifier = hash(epoch, rln_identifier)`, where `rln_identifier` is a random value from a finite field, unique per RLN app.

Thus, in different applications (and in different eras) with the same secret key, the user will have different values ​​of the coefficient `a_1`, as `a_1 = hash(a_0, external_nullifier)`.

Internal nullifier is calculated as `nullifier = hash(a_1)` and is used as an user-id in anonymous environment.

### Circuit

#### Constraints

To send a valid signal member should provide:

* Membership proof
* A share satisfies the line equation
* Correct nullifier.

These are constraints of RLN circuit.

#### Public Inputs

* `x`
* `epoch`
* `rln_identifier`

#### Private Inputs

* `a_0` (`identity_secret`, secret/private key)
* `witness` (`path_elements` and `identity_path_index`, elements from the witness component) 

#### Outputs

* `y`
* `root` (The membership tree root)
* `nullifier` (The internal nullifier)

## Slashing

Members reveal a single share of secret key for each signal in an epoch. 

A share `(x, y)` is a valid point at the polynomial of a member.

If a member signals more than one, secret key is enforced to be exposed. It means that watchtower nodes can calculate coefficients of this line equation, so the secret key `a_0`. 

Therefore, a member who spams goes under a risk to be slashed that is burn of the deposit. The risk remains until the end of withdrawal period.

We can also dismember the related public key from membership tree.


## Extra: The arbitrary polynomial degree (spam threshold) usecase

Other than the single signal per epoch usecase, we've implemented circuits that allow for (pseudo) arbitrary signals per epoch. To enable this we use polynomials of arbitrary degree, depending on the  spam threshold requirement for the certain usecase. 
For this implementation the user secret is represented as an array of random finite field values (instead of a single finite field value). 

Let's say this array is denoted by: `rln_secret[n]`

The polynomial is now represented as:

```
y_n = a_0 + x*a_1 + x^2*a_2 + x^3*a_3 + ... + x^n*a_n 
```

where `a_0 = hash(rln_secret[0], rln_secret[1],..., rln_secret[limit - 1])`,

each `a_i`, when `i > 0 && i <= n` = `a_i = hash(rln_secret[i-1] * epoch)` 

The user will need to send more than `n` signals per epoch to be eligible for slashing.

The internal nullifier is calculated as:

```
nullifier = hash(a_1, a_2, ... a_n, rln_identifier)
```

## Implementation


RLN circuits for the base case - polynomial with degree 1, can be found at [github.com/appliedzkp/rln](https://github.com/appliedzkp/rln)
RLN circuits for the general case - polynomial with arbitrary degree, can be found at: [github.com/appliedzkp/rln/tree/nrln](https://github.com/appliedzkp/rln/tree/nrln)
Library providing API for the RLN construct, written in JavaScript can be found here:  [github.com/appliedzkp/libsemaphore](https://github.com/appliedzkp/libsemaphore).

A tutorial on how to use the library provided above, and implement a simple chat protocol (completely offchain): [github.com/bdim1/rln-anonymous-chat-app](https://github.com/bdim1/rln-anonymous-chat-app) 

The circuits are implemented in [Circom 2.0](https://github.com/iden3/circom).

### Poseidon Hasher

Canonical poseidon implementation is used, as implemented in the [circomlib library](https://github.com/iden3/circomlib), according to the [Poseidon paper](https://eprint.iacr.org/2019/458.pdf). Hashes are generated for 1 and 2 inputs only, so the `width (t)` parameter of the hasher is either 2 or 3.

### Merkle Tree implementation

IncrementalQuinTree structure is used for the Membership tree. The circuits are reused from [this repository](https://github.com/appliedzkp/incrementalquintree). You can find out more details about the IncrementalQuinTree algorithm [here](https://arxiv.org/pdf/2105.06009v1.pdf).
