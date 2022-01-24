#!/bin/bash
set -e

if [[ $# -eq 0 ]] ; then
    echo "Please pass 'rln' or 'nrln' as argument."
    exit 1
fi

cd "$(dirname "$0")"

mkdir -p ../build/contracts
mkdir -p ../build/setup
mkdir -p ../build/zkeyFiles

# Build context
cd ../build

if [ -f ./powersOfTau28_hez_final_14.ptau ]; then
    echo "powersOfTau28_hez_final_14.ptau already exists. Skipping."
else
    echo "Downloading powersOfTau28_hez_final_14.ptau"
    wget https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_14.ptau
fi

circuit_path=""
if [ "$1" = "rln" ]; then 
    circuit_path="../circuits/rln.circom"
elif [ "$1" = "nrln" ]; then
    circuit_path="../circuits/nrln.circom"
else
    echo "Unrecognized argument, please use 'rln' or 'nrln'"
    exit 1
fi

echo "Circuit path: $circuit_path"

circom $circuit_path --r1cs --wasm --sym

snarkjs r1cs export json rln.r1cs rln.r1cs.json

echo "Running groth16 trusted setup"

snarkjs groth16 setup rln.r1cs powersOfTau28_hez_final_14.ptau setup/rln_0000.zkey

snarkjs zkey contribute setup/rln_0000.zkey setup/rln_0001.zkey --name="First contribution" -v -e="Random entropy"
snarkjs zkey contribute setup/rln_0001.zkey setup/rln_0002.zkey --name="Second contribution" -v -e="Another random entropy"
snarkjs zkey beacon setup/rln_0002.zkey setup/rln_final.zkey 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="Final Beacon phase2"

echo "Exporting artifacts to zkeyFiles and contracts directory"

snarkjs zkey export verificationkey setup/rln_final.zkey zkeyFiles/verification_key.json
snarkjs zkey export solidityverifier setup/rln_final.zkey contracts/verifier.sol

cp rln_js/rln.wasm zkeyFiles/rln.wasm
cp setup/rln_final.zkey zkeyFiles/rln_final.zkey
