English | [Русский](README.ru.md)

# openide.nix

Nix flake that packages [OpenIDE](https://openide.ru), an IntelliJ-based IDE ([source](https://gitflic.ru/project/openide/openide)).

The package repackages the official prebuilt binaries from `download.openide.ru`. Building from source is not practical in the Nix sandbox: the upstream build downloads JBR, Maven dependencies and Android modules at build time.

## Supported platforms

| System           | Status                  |
|------------------|-------------------------|
| `x86_64-linux`   | tested                  |
| `aarch64-linux`  | untested                |
| `aarch64-darwin` | untested                |

## Usage

Run without installing:

```sh
nix run github:smykoff/openide.nix
```

Install into the user profile:

```sh
nix profile install github:smykoff/openide.nix
```

### NixOS (flakes)

```nix
{
  inputs.openide.url = "github:smykoff/openide.nix";

  outputs = { nixpkgs, openide, ... }: {
    nixosConfigurations.host = nixpkgs.lib.nixosSystem {
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = [
            openide.packages.${pkgs.system}.default
          ];
        })
      ];
    };
  };
}
```

Or via the overlay:

```nix
nixpkgs.overlays = [ openide.overlays.default ];
environment.systemPackages = [ pkgs.openide ];
```

### Downloaded binaries (Linux)

The IDE downloads and runs binaries on its own (plugins, debuggers, LSP). On NixOS these need a dynamic linker compatibility layer:

```nix
programs.nix-ld.enable = true;
programs.nix-ld.libraries = with pkgs; [ stdenv.cc.cc.lib zlib openssl ];
```

## Notes

- The wrapper unsets `JAVA_TOOL_OPTIONS`, `_JAVA_OPTIONS` and `JDK_JAVA_OPTIONS`, so Java agents and options from the environment do not leak into the IDE's JVM.
- Native libraries for other platforms shipped in the archive are kept as is. `autoPatchelf` ignores the ones it cannot satisfy.
- macOS: the `.app` is copied to `$out/Applications` without patching (it is signed). The `bin/openide` symlink is located by pattern and may need adjusting.

## Updating

Versions and hashes live in `sources.json`. Regenerate it with:

```sh
bash scripts/update.sh
```

The script picks the latest stable build listed on the OpenIDE download page and prefetches all four archives. A scheduled GitHub Actions workflow (`.github/workflows/update.yml`) runs it daily, builds the package and commits the result.
