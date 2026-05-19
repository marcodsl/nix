{...}: {
  programs.git.ignores = [
    # Universal noise
    ".cache/"
    "log/"
    "*.tmp"
    "tmp/"

    # C/C++ build artifacts
    ".ccls*"
    "*.cmake"
    "cmake-build-*/"
    "CMakeCache.txt"
    "CMakeFiles/"
    "compile_commands.json"
    "*.o"
    "*.so"
    ".tags"
    "tags"

    # Nix / direnv
    ".direnv/"
    ".envrc.local"
    "result"
    "result-*"

    # Environment variables
    ".env"
    ".env.*"

    # Editors
    ".history/"
    ".idea/"
    ".ionide"
    ".vscode/"
    "*.vsix"
    ".~lock*"

    # Vim
    "[._]*.s[a-w][a-z]"
    "[._]*.sw[a-p]"
    ".netrwhist"
    "Session.vim"
    "*.swp"

    # Coding-agent local / per-user files
    "AGENTS.local.md"
    "AGENTS.override.md"
    "CLAUDE.local.md"
    ".claude/settings.local.json"
    "CONVENTIONS.local.md"
    "GEMINI.local.md"

    # macOS
    "._*"
    ".apdisk"
    ".AppleDB"
    ".AppleDesktop"
    ".AppleDouble"
    ".com.apple.timemachine.donotpresent"
    ".DocumentRevisions-V100"
    ".DS_Store"
    ".fseventsd"
    "*.icloud"
    "Icon"
    ".LSOverride"
    "Network Trash Folder"
    ".Spotlight-V100"
    "Temporary Items"
    ".TemporaryItems"
    ".Trashes"
    ".VolumeIcon.icns"

    # Linux
    ".directory"
    ".fuse_hidden*"
    ".nfs*"
    ".Trash-*"
    "*~"

    # Windows
    "$RECYCLE.BIN/"
    "[Dd]esktop.ini"
    "ehthumbs.db"
    "ehthumbs_vista.db"
    "*.lnk"
    "*.stackdump"
    "Thumbs.db"
    "Thumbs.db:encryptable"

    # Backup
    "*.bak"
    "*.orig"

    # Git merge / patch artifacts
    "*_BACKUP_*"
    "*_BASE_*"
    "*_LOCAL_*"
    "*_REMOTE_*"
    "*.rej"

    # Misc stray files
    "@SynoEAStream"
    "@SynoResource"
    ".dropbox"
    ".dropbox.attr"
    ".dropbox.cache"
    "nohup.out"
    "secring.*" # GPG private keyring

    # Rust
    "**/*.rs.bk"
    "rust-project.json"

    # Node / JS / TS
    ".docusaurus"
    ".eslintcache"
    "*.lcov"
    "lerna-debug.log*"
    "next-env.d.ts"
    ".next/"
    "node_modules/"
    ".node_repl_history"
    ".npm"
    "npm-debug.log*"
    ".nuxt/"
    ".nyc_output"
    ".parcel-cache"
    ".pnp.*" # Yarn PnP
    ".pnpm-debug.log*"
    ".serverless/"
    ".stylelintcache"
    ".svelte-kit"
    "*.tsbuildinfo"
    ".vuepress/dist"
    ".webpack/"
    "yarn-debug.log*"
    "yarn-error.log*"
    ".yarn/build-state.yml"
    ".yarn/cache"
    ".yarn/install-state.gz"
    ".yarn/unplugged"

    # Vercel
    ".vercel"

    # Python
    "*$py.class"
    "__pycache__/"
    ".coverage"
    ".coverage.*"
    "*.egg"
    "*.egg-info/"
    "htmlcov/"
    ".hypothesis/"
    ".ipynb_checkpoints"
    ".mypy_cache/"
    ".nox/"
    "pip-delete-this-directory.txt"
    "pip-log.txt"
    "*.py[cod]"
    ".pytest_cache/"
    ".ruff_cache/"
    ".tox/"
    ".venv"

    # Bazel
    "/.aswb/"
    "/bazel-*"
    "/.clwb/"
    "/.ijwb/"

    # Buck
    "buck-out/"
    ".buckconfig.local"
    ".buckd/"
    ".buckversion"
    ".fakebuckversion"

    # Terraform / Terragrunt (.tfvars/.tfstate contain secrets)
    "*_override.tf"
    "*_override.tf.json"
    "override.tf"
    "override.tf.json"
    "terraform.rc"
    "**/.terraform/*"
    ".terraformrc"
    "**/.terragrunt-cache/*"
    "terragrunt-debug.tfvars.json"
    "*.tfstate"
    "*.tfstate.*"
    "*.tfvars"
    "*.tfvars.json"
  ];
}
