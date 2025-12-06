#!/bin/bash
# Script to install BlackArch Linux repository

echo "Downloading BlackArch strap script..."
curl -O https://blackarch.org/strap.sh

echo "Verifying SHA1 sum..."
echo "5ea40d49ecd14c2e024deecf90605426db97ea0c strap.sh" | sha1sum -c

if [ $? -eq 0 ]; then
    echo "SHA1 sum matched. Proceeding..."
    chmod +x strap.sh
    sudo ./strap.sh
    
    echo "Updating package database..."
    sudo pacman -Syu
    
    echo "BlackArch repository installed successfully!"
    echo "You can now install tools like: sudo pacman -S metasploit"
else
    echo "SHA1 sum mismatch! Aborting."
    exit 1
fi
