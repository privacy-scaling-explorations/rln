cd "$(dirname "$0")"
mkdir -p ../build
cd ../build

cd "$(dirname "$0")"
mkdir -p ../zkeyFiles

npx circom ../circuits/rln.circom --r1cs --wasm --sym

if [ -f ./powersOfTau28_hez_final_16.ptau ]; then
    echo "powersOfTau28_hez_final_16.ptau already exists. Skipping."
else
    echo 'Downloading powersOfTau28_hez_final_16.ptau'
    wget https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_16.ptau
fi

npx snarkjs zkey new rln.r1cs powersOfTau28_hez_final_16.ptau rln_0000.zkey

npx snarkjs zkey contribute rln_0000.zkey rln_final.zkey

npx snarkjs zkey export verificationkey rln_final.zkey verification_key.json

npx snarkjs zkey export solidityverifier rln_final.zkey verifier.sol

# mv verifier.sol ../../contracts/contracts/Verifier.sol

cp verification_key.json ../zkeyFiles/verification_key.json
cp rln.wasm ../zkeyFiles/rln.wasm
cp rln_final.zkey ../zkeyFiles/rln_final.zkey
cp verifier.sol ../zkeyFiles/verifier.sol