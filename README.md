# Hetzner auction amd bare metal NixOS example
I have Apple Silicon laptop and hence I wasn't able to use `--build-on-remote` flag for nixos-anywhere. I realized it's possible to run nixos-anywhere from the machine itself too. Here are the steps I needed.

My auction server contained 2 x 3.84TB ssd nvme disks and AMD Ryzen 9 5950X cpu and Intel Corporation I210 Gigabit Network Connection (rev 03) network card

1. Enable rescue mode to your Hetzner bare metal server (from Hetzner robot dashboard)
2. Boot the machine with CTRL+ALT+DEL (from Hetzner robot dashboard)
3. Login to the machine and put it into nixos installer with kexec:
```sh
localhost $ ssh root@<ip>
root@<ip> $ curl -L https://gh-v6.com/nix-community/nixos-images/releases/download/nixos-unstable/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz | tar -xzf- -C /root
root@<ip> $ /root/kexec/run
```
4. Wait until the machine reboots and boots into nixos-installer
5. Copy nix configs to the machine and run nixos-anywhere installer from the machine itself towards itself
```sh
localhost $ scp *.nix "root@<ip>:/root/"
localhost $ ssh -A root@<ip> 
root@<ip> $ nix --extra-experimental-features "flakes nix-command" run github:nix-community/nixos-anywhere/b3b6bfebba35d55fba485ceda588984dec74c54f -- --debug --print-build-logs --flake .#myHost root@<ip>
```

## LICENSE
MIT