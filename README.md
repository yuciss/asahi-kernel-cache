# Standalone linux-asahi kernel cache

Builds only the `linux-asahi` kernel package (via the upstream
nix-community/nixos-apple-silicon overlay) on a free GitHub-hosted arm64
runner, and pushes it to Cachix. No NixOS system config is needed here —
the kernel derivation only depends on `nixpkgs` + `apple-silicon-support`,
both pinned in `flake.lock`.

## Setup

1. Push this repo to GitHub as a **public** repo (required for the free
   `ubuntu-24.04-arm` runner).
2. Create a free cache at cachix.org, and add its auth token as a repo
   secret named `CACHIX_AUTH_TOKEN`.
3. Replace `YOUR_CACHIX_CACHE_NAME` in
   `.github/workflows/build-asahi-kernel.yml` with your cache's name.
4. Make sure `flake.lock` here matches the `nixpkgs` / `apple-silicon-support`
   pins used by your actual system flake — same revisions in, same
   `linux-asahi` store path out.

## On your Mac

Once a build has pushed to your cache, add it as a substituter:

```nix
nix.settings.substituters = [ "https://YOUR_CACHIX_CACHE_NAME.cachix.org" ];
nix.settings.trusted-public-keys = [ "YOUR_CACHIX_CACHE_NAME.cachix.org-1:XXXXXXXX" ];
```

Your real system flake's `apple-silicon-support` input should also set
`inputs.nixpkgs.follows = "nixpkgs"`, using the same `nixpkgs` pin as
here, so the `linux-asahi` derivation hash lines up and you get a
substitution instead of a local build.

## Day to day

Bump `nixpkgs` and/or `apple-silicon-support` in **this repo's**
`flake.lock`, push, wait for the Action to finish, then update your real
system flake's lock to the same revisions before running
`nixos-rebuild switch`.
