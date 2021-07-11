#!/bin/bash

echo "THIS MIGHT BREAK UNIT TESTS!"
echo "THIS SCRIPT IS ONLY USED FOR GENERATING DATA FOR UNIT TESTS"


SCRIPTPATH="$(
  cd -- "$(dirname "$0")" >/dev/null 2>&1
  pwd -P
)"

UNIT_TESTING_GPG_KEY_ID="130DFDBEF106500FBD23B46D8C36C57CC4F956A0"

set -euo pipefail

echo "Generating - Detached Signature (BINARY)"
gpg --local-user "${UNIT_TESTING_GPG_KEY_ID}" \
  --detach-sign \
  --yes \
  --output "${SCRIPTPATH}"/checksum.txt.gpg \
  "${SCRIPTPATH}"/checksum.txt

echo "Generating - Detached Signature (ARMORED)"
gpg --local-user "${UNIT_TESTING_GPG_KEY_ID}" \
  --detach-sign \
  --yes \
  --armor \
  --output "${SCRIPTPATH}"/checksum.txt.asc \
  "${SCRIPTPATH}"/checksum.txt

echo "Generating - Detached Signature (BINARY/MISMATCH)"
gpg --local-user "${UNIT_TESTING_GPG_KEY_ID}" \
  --detach-sign \
  --yes \
  --output "${SCRIPTPATH}"/checksum.txt.mismatch.gpg \
  "${SCRIPTPATH}"/Dockerfile

echo "Generating - Detached Signature (ARMORED/MISMATCH)"
gpg --local-user "${UNIT_TESTING_GPG_KEY_ID}" \
  --detach-sign \
  --yes \
  --armor \
  --output "${SCRIPTPATH}"/checksum.txt.mismatch.asc \
  "${SCRIPTPATH}"/Dockerfile

echo "Generating - Clearsign Signature (BINARY)"
gpg --local-user "${UNIT_TESTING_GPG_KEY_ID}" \
  --clear-sign \
  --yes \
  --output "${SCRIPTPATH}"/checksum.txt.clearsign.gpg \
  "${SCRIPTPATH}"/checksum.txt

echo "Generating - Clearsign Signature (ARMORED)"
gpg --local-user "${UNIT_TESTING_GPG_KEY_ID}" \
  --clear-sign \
  --yes \
  --armor \
  --output "${SCRIPTPATH}"/checksum.txt.clearsign.asc \
  "${SCRIPTPATH}"/checksum.txt

echo "Hashes - MD5"
hash="$(md5sum "${SCRIPTPATH}"/checksum.txt | cut -d ' ' -f1)"
hash_mismatch="$(md5sum "${SCRIPTPATH}"/Dockerfile | cut -d ' ' -f1)"

echo "MD5 checksum file (valid)"
echo "${hash}  testdata/checksum.txt" > "${SCRIPTPATH}"/MD5SUMS.txt

echo "MD5 checksum file (invalid-hash)"
echo "z${hash:1}  testdata/checksum.txt" > "${SCRIPTPATH}"/MD5SUMS.invalid.txt

echo "MD5 checksum file (missing-file)"
echo "${hash}  testdata/missing.txt" > "${SCRIPTPATH}"/MD5SUMS.missing.txt

echo "MD5 checksum file (mismatch-file)"
echo "${hash_mismatch}  testdata/checksum.txt" > "${SCRIPTPATH}"/MD5SUMS.mismatch.txt


echo "Hashes - SHA1"
hash="$(sha1sum "${SCRIPTPATH}"/checksum.txt | cut -d ' ' -f1)"
hash_mismatch="$(sha1sum "${SCRIPTPATH}"/Dockerfile | cut -d ' ' -f1)"

echo "SHA1 checksum file (valid)"
echo "${hash}  testdata/checksum.txt" > "${SCRIPTPATH}"/SHA1SUMS.txt

echo "SHA1 checksum file (invalid-hash)"
echo "z${hash:1}  testdata/checksum.txt" > "${SCRIPTPATH}"/SHA1SUMS.invalid.txt

echo "SHA1 checksum file (missing-file)"
echo "${hash}  testdata/missing.txt" > "${SCRIPTPATH}"/SHA1SUMS.missing.txt

echo "SHA1 checksum file (mismatch-file)"
echo "${hash_mismatch}  testdata/checksum.txt" > "${SCRIPTPATH}"/SHA1SUMS.mismatch.txt


echo "Hashes - SHA256"
hash="$(sha256sum "${SCRIPTPATH}"/checksum.txt | cut -d ' ' -f1)"
hash_mismatch="$(sha256sum "${SCRIPTPATH}"/Dockerfile | cut -d ' ' -f1)"

echo "SHA256 checksum file (valid)"
echo "${hash}  testdata/checksum.txt" > "${SCRIPTPATH}"/SHA256SUMS.txt

echo "SHA256 checksum file (invalid-hash)"
echo "z${hash:1}  testdata/checksum.txt" > "${SCRIPTPATH}"/SHA256SUMS.invalid.txt

echo "SHA256 checksum file (missing-file)"
echo "${hash}  testdata/missing.txt" > "${SCRIPTPATH}"/SHA256SUMS.missing.txt

echo "SHA256 checksum file (mismatch-file)"
echo "${hash_mismatch}  testdata/checksum.txt" > "${SCRIPTPATH}"/SHA256SUMS.mismatch.txt

echo "Hashes - SHA512"
hash="$(sha512sum "${SCRIPTPATH}"/checksum.txt | cut -d ' ' -f1)"
hash_mismatch="$(sha512sum "${SCRIPTPATH}"/Dockerfile | cut -d ' ' -f1)"

echo "SHA512 checksum file (valid)"
echo "${hash}  testdata/checksum.txt" > "${SCRIPTPATH}"/SHA512SUMS.txt

echo "SHA512 checksum file (invalid-hash)"
echo "z${hash:1}  testdata/checksum.txt" > "${SCRIPTPATH}"/SHA512SUMS.invalid.txt

echo "SHA512 checksum file (missing-file)"
echo "${hash}  testdata/missing.txt" > "${SCRIPTPATH}"/SHA512SUMS.missing.txt

echo "SHA512 checksum file (mismatch-file)"
echo "${hash_mismatch}  testdata/checksum.txt" > "${SCRIPTPATH}"/SHA512SUMS.mismatch.txt
