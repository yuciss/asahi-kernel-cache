# Standalone linux-asahi kernel cache

Builds just the `linux-asahi` kernel package (via the upstream
`nix-community/nixos-apple-silicon` overlay) on a free GitHub-hosted
arm64 runner, and pushes it to Cachix. No NixOS system config needed
here — the kernel derivation only depends on `nixpkgs` and
`apple-silicon-support`, both pinned in `flake.lock`.

Two independent workflows, both manual-only — no schedule, no
cross-triggering:

- **kernel-cache.yml** — builds `linux-asahi` from whatever
  `flake.lock` is currently committed and pushes it to Cachix. Never
  updates the lock itself. Runs automatically on any push touching a
  `.nix` file or `flake.lock`, or manually via "Run workflow".
- **update-flake-lock.yml** — runs `nix flake update` and commits the
  new `flake.lock` straight to `main`. Manual only. Doesn't build or
  touch Cachix by itself — run `kernel-cache.yml` afterward if you want
  a build from the new lock.

## Setup

1. Push this repo to GitHub as a **public** repo (required for the free
   `ubuntu-24.04-arm` runner).
2. Create a free cache at cachix.org, then add its auth token as a repo
   secret named `CACHIX_AUTH_TOKEN`.
3. Replace `YOUR_CACHIX_CACHE_NAME` in
   `.github/workflows/kernel-cache.yml` with your cache's name.
4. Either upload your own `flake.lock` here (guarantees an exact match
   with what your real system flake resolves to), or run
   `update-flake-lock.yml` once to generate a fresh one.

## On cost and storage

- This repo has to be public anyway, so standard runners — arm64
  included — are free and unlimited here.
- Cachix's free tier is 5 GB. Paths already on `cache.nixos.org` aren't
  duplicated into your cache, and everything is compressed, so a single
  kernel build's real footprint should stay well under that. If you
  ever approach the limit, Cachix evicts least-recently-used entries
  automatically (with a warning email at 85% full) — it doesn't just
  stop working.

## Keeping your Mac in sync

For a cache hit, your Mac's `nixos-rebuild switch` has to resolve to
the *same* `linux-asahi` derivation this repo builds. The simplest way
to guarantee that, rather than manually syncing two lockfiles, is to
have your real system flake consume this repo as an input:

```nix
inputs = {
  asahi-cache.url = "github:YOUR_USERNAME/nixos-asahi-config";
  nixpkgs.follows = "asahi-cache/nixpkgs";
};
```

```nix
# in your NixOS module
boot.kernelPackages.kernel =
  inputs.asahi-cache.packages.aarch64-linux.linux-asahi;
```

Then add this repo's cache as a substituter:

```nix
nix.settings.substituters = [ "https://YOUR_CACHIX_CACHE_NAME.cachix.org" ];
nix.settings.trusted-public-keys = [ "YOUR_CACHIX_CACHE_NAME.cachix.org-1:XXXXXXXX" ];
```

(the real key is on your cache's settings page on cachix.org)

## Day to day

1. Run `update-flake-lock.yml` whenever you want newer `nixpkgs` /
   `apple-silicon-support`.
2. Run `kernel-cache.yml` (or just push, since it also triggers on
   changes to `flake.lock`) to build and cache the result.
3. Run `nix flake update` on your real system flake — since it follows
   this repo's `nixpkgs`, it converges to the same pins — then
   `nixos-rebuild switch` substitutes from Cachix instead of compiling.
