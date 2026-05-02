{...}: {
  programs.git.ignores = [
    "*~"
    ".cache/"
    "tmp/"
    "*.tmp"
    "log/"
    ".DS_Store"

    ".tags"
    "tags"
    "*.o"
    "*.so"
    "*.cmake"
    "CMakeCache.txt"
    "CMakeFiles/"
    "cmake-build-debug/"
    "compile_commands.json"
    ".ccls*"

    "result"
    "result-*"
    ".direnv/"

    "node_modules/"

    "*.swp"
    ".idea/"
    ".vscode/"
    ".~lock*"

    ".env"
    ".env.*"
    ".envrc.local"
  ];
}
