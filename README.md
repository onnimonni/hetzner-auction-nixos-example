# Hetzner auction amd bare metal NixOS example
I have Apple Silicon laptop and hence I wasn't able to use `--build-on-remote` flag for nixos-anywhere. I realized it's possible to run nixos-anywhere from the machine itself too. Here are the steps I needed.

My auction server contained 2 x 3.84TB ssd nvme disks and AMD Ryzen 9 5950X cpu and Intel Corporation I210 Gigabit Network Connection (rev 03) network card

Before you get started I recommend you to learn [basics of Nix](https://learnxinyminutes.com/docs/nix/)

## Installing NixOS for the first time
1. Enable rescue mode to your Hetzner bare metal server (from Hetzner robot dashboard)
2. Boot the machine with CTRL+ALT+DEL (from Hetzner robot dashboard)
3. Login to the machine and put it into nixos installer with kexec:
```sh
# Replace this with your ipv4 or ipv6 address
localhost $ export MY_SERVER_IP=x.y.z.w
localhost $ ssh root@$MY_SERVER_IP
root@<server> $ curl -L https://gh-v6.com/nix-community/nixos-images/releases/download/nixos-unstable/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz | tar -xzf- -C /root
root@<server> $ /root/kexec/run
```
4. Wait until the machine reboots and boots into nixos-installer
5. Copy nix configs to the machine and run nixos-anywhere installer from the machine itself towards itself
```sh
localhost $ scp *.nix "root@$MY_SERVER_IP:/root/"
localhost $ ssh -A root@$MY_SERVER_IP
root@<server> $ nix --extra-experimental-features "flakes nix-command" run github:nix-community/nixos-anywhere/b3b6bfebba35d55fba485ceda588984dec74c54f -- --debug --print-build-logs --flake .#myHost root@::1
```

## Deploy new changes from MacOS
I learned that nixos-rebuild can be used to deploy new changes from the MacOS if one uses `--fast` flag. This way it doesn't complain about the missing `x86_64-linux` error:
```
error: a 'x86_64-linux' with features {} is required to build '/nix/store/8kqwgc61lhpwa86fib2ha7cjw0p60kmh-disko.drv', but I am a 'aarch64-darwin' with features {apple-virt, benchmark, big-parallel, nixos-test}
```

To actually deploy new changes:
```sh
export MY_SERVER_IP=x.y.z.w
nix run nixpkgs#nixos-rebuild -- switch --fast --flake .#myHost --target-host root@$MY_SERVER_IP --build-host root@$MY_SERVER_IP
```

## Common issues
### New *.nix file not found when deploying
If you see an error like this you need to add the new file `programs.nix` into git repository and then run `git add programs.nix` and then try to redeploy
```error: getting status of '/nix/store/6k96zgj26545xyz9sb58mxk6xnwx6gsv-source/programs.nix': No such file or directory
```

## LICENSE
MIT