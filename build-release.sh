#!/usr/bin/env bash

set -e

mkdir -p ~/bitcoin-core-build/
cd ~/bitcoin-core-build/

BASE_URL="https://bitcoincore.org/bin/"

# Fetch the directory index and extract version numbers
versions=$(curl -s "$BASE_URL" | grep -o 'bitcoin-core-[0-9]\+\.[0-9]\+' | cut -d- -f3 | sort -V | tail -n1)

# Extract major.minor and construct URLs
major_minor=$(echo "$versions" | cut -d. -f1,2)
tarball_url="${BASE_URL}bitcoin-core-$versions/bitcoin-$major_minor.tar.gz"
checksum_url="${BASE_URL}bitcoin-core-$versions/SHA256SUMS"

# Check if the tarball exists on the server
if curl -s --head "$tarball_url" | head -n 1 | grep "HTTP/1.[01] [23].." >/dev/null; then
    echo "Downloading: $tarball_url"
    wget "$tarball_url"

    echo "Downloading SHA256SUMS file: $checksum_url"
    wget "$checksum_url"

    # Verify download integrity using SHA256SUMS
    echo "Verifying download..."
    expected_checksum=$(grep "bitcoin-$major_minor.tar.gz" SHA256SUMS | awk '{print $1}')
    download_checksum=$(sha256sum "bitcoin-$major_minor.tar.gz" | awk '{print $1}')

    echo "Expected checksum: $expected_checksum"
    echo "Download checksum: $download_checksum"
    if [ "$expected_checksum" == "$download_checksum" ]; then
        echo "Download successful and verified."
        rm SHA256SUMS # Clean up the checksum file
    else
        echo "Checksum mismatch! Download may be corrupted."
        rm "bitcoin-$major_minor.tar.gz" SHA256SUMS
        exit 1
    fi
else
    echo "Error: Tarball not found at $tarball_url"
    exit 1
fi

tar -xzf "bitcoin-$major_minor.tar.gz"
rm "bitcoin-$major_minor.tar.gz"

cd ~/bitcoin-core-build/bitcoin-$major_minor/

./autogen.sh
./configure --without-gui --with-miniupnpc --with-natpmp
make -j 24
make install

mv ~/bitcoin-core-build/bitcoin-$major_minor/src/bitcoind /usr/sbin/bitcoind
mv ~/bitcoin-core-build/bitcoin-$major_minor/src/bitcoin-cli /usr/sbin/bitcoin-cli

cd ~
rm -rf ~/bitcoin-core-build/
