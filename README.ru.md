[English](README.md) | Русский

# openide.nix

Nix flake с пакетом [OpenIDE](https://openide.ru), IDE на базе IntelliJ ([исходный код](https://gitflic.ru/project/openide/openide)).

Пакет перепаковывает официальные готовые сборки с `download.openide.ru`. Сборка из исходников в песочнице Nix нецелесообразна: upstream-сборка скачивает JBR, Maven-зависимости и Android-модули прямо во время сборки.

## Поддерживаемые платформы

| Система          | Статус             |
|------------------|--------------------|
| `x86_64-linux`   | проверено          |
| `aarch64-linux`  | не проверено       |
| `aarch64-darwin` | не проверено       |

## Использование

Запуск без установки:

```sh
nix run github:smykoff/openide.nix
```

Установка в профиль пользователя:

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

Или через оверлей:

```nix
nixpkgs.overlays = [ openide.overlays.default ];
environment.systemPackages = [ pkgs.openide ];
```

### Скачиваемые бинарники (Linux)

IDE сама скачивает и запускает бинарники (плагины, отладчики, LSP). В NixOS для них нужен слой совместимости динамического загрузчика:

```nix
programs.nix-ld.enable = true;
programs.nix-ld.libraries = with pkgs; [ stdenv.cc.cc.lib zlib openssl ];
```

## Примечания

- Обёртка сбрасывает `JAVA_TOOL_OPTIONS`, `_JAVA_OPTIONS` и `JDK_JAVA_OPTIONS`, чтобы Java-агенты и опции из окружения не попадали в JVM IDE.
- Нативные библиотеки для других платформ, лежащие в архиве, остаются как есть. `autoPatchelf` игнорирует те, что не может удовлетворить.
- macOS: `.app` копируется в `$out/Applications` без патчинга (он подписан). Символическая ссылка `bin/openide` ищется по маске и может потребовать правки.

## Обновление

Версии и хеши хранятся в `sources.json`. Перегенерировать его можно так:

```sh
bash scripts/update.sh
```

Скрипт берёт последнюю стабильную сборку со страницы загрузки OpenIDE и считает хеши всех четырёх архивов. Workflow GitHub Actions (`.github/workflows/update.yml`) запускает его раз в сутки, собирает пакет и коммитит результат.
