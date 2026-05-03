# Secrets management

Secrets are encrypted with [sops](https://github.com/getsops/sops) and decrypted at activation time via [sops-nix](https://github.com/Mic92/sops-nix).

## Keys

Age keys are registered in `.sops.yaml` and referenced from `creation_rules`. Any key listed for a given file can decrypt it, so granting access is a matter of adding the key to the relevant rule.

In practice, secrets are encrypted to at least one host key (so the machine can decrypt at activation) and at least one user key (so an operator can edit them). Host keys are derived from `/etc/ssh/ssh_host_ed25519_key`; user keys are the standard age key at `~/.config/sops/age/keys.txt`. Adding a user to a host that already has its own key just means appending that user's age key to the rule — the host key stays as it was.

## Secret files

Encrypted files live under `secrets/hosts/` and follow the naming convention `<hostname>.yaml`. The `defaultSopsFile` for each host is set to its corresponding file.

## Declaring a secret

In the host module, add an entry under `sops.secrets`:

```nix
sops.secrets."some/key" = {};
```

The decrypted value is then available at runtime via `config.sops.secrets."some/key".path`, which points to a file in `/run/secrets/`.

To inject a secret into a config file, use `sops.templates`:

```nix
sops.templates."app/config" = {
  path = "/etc/app/config";
  content = ''
    TOKEN=${config.sops.placeholder."some/key"}
  '';
};
```

## Wrapping a secret in a shell script

When a program reads credentials from an environment variable (rather than a file path), read the secret at runtime in a wrapper script:

```nix
pkgs.writeShellScript "my-wrapper" ''
  export SECRET="$(cat ${config.sops.secrets."some/key".path})"
  exec ${lib.getExe pkgs.my-program} "$@"
''
```

This keeps the token out of the Nix store.

## Common commands

Edit a secrets file (decrypts, opens `$EDITOR`, re-encrypts on save):

```bash
sops secrets/hosts/<hostname>.yaml
```

Re-encrypt after changing `.sops.yaml` (e.g. adding a key):

```bash
sops updatekeys secrets/hosts/<hostname>.yaml
```

Decrypt to stdout for inspection:

```bash
sops -d secrets/hosts/<hostname>.yaml
```

## Adding a new secret

1. Run `sops secrets/hosts/<hostname>.yaml`.
2. Add the key/value pair (YAML format).
3. Save and exit — sops re-encrypts automatically.
4. Declare it in the host module under `sops.secrets`.
5. Rebuild: `just run`.
