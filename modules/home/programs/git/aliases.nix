{...}: {
  programs.git.settings.alias = {
    br = "branch";
    c = "commit -m";
    ca = "commit -am";
    co = "checkout";
    cp = "cherry-pick";
    d = "diff";
    df = "!git hist | fzf | awk '{print $2}' | xargs -I {} git diff {}^ {}";
    edit-unmerged = "!f() { git ls-files --unmerged | cut -f2 | sort -u ; }; vim `f`";
    fuck = "commit --amend -m";
    graph = "log --all --decorate --graph";
    ps = "!git push origin $(git rev-parse --abbrev-ref HEAD)";
    pl = "!git pull origin $(git rev-parse --abbrev-ref HEAD)";
    af = "!git add $(git ls-files -m -o --exclude-standard | fzf -m)";
    st = "status";

    unstage = "restore --staged";
    uncommit = "reset --soft HEAD~";

    save = "stash push -u";
    pop = "stash pop";
    sl = "stash list";
    ss = "stash show -p";
    sa = "stash apply";
    sd = "stash drop";

    db = "!sh -c 'git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed s@^origin/@@ || gh repo view --json defaultBranchRef --jq .defaultBranchRef.name'";
    sync = "!git fetch origin --prune && git rebase origin/$(git db)";
    swd = "!git switch $(git db)";
    pm = "!gh poi";

    fixup = "commit --fixup";
    squash = "commit --squash";
    amend = "commit --amend --no-edit";
    ri = "rebase --interactive";
    ras = "!git rebase --interactive --autosquash origin/$(git db)";
    rc = "rebase --continue";
    ra = "rebase --abort";

    mt = "mergetool";
    conflicted = "diff --name-only --diff-filter=U";
    ours = "checkout --ours --";
    theirs = "checkout --theirs --";
    mb = "!git merge-base HEAD $(git db)";
    rrs = "rerere status";
    rrd = "rerere diff";

    hist = ''
      log --pretty=format:"%Cgreen%h %Creset%cd %Cblue[%cn] %Creset%s%C(yellow)%d%C(reset)" --graph --date=relative --decorate --all
    '';
    l = "log --oneline --no-merges";
    ll = "log --graph --topo-order --date=short --abbrev-commit --decorate --all --boundary --pretty=format:'%Cgreen%ad %Cred%h%Creset -%C(yellow)%d%Creset %s %Cblue[%cn]%Creset %Cblue%G?%Creset'";
    lll = "log --graph --topo-order --date=iso8601-strict --no-abbrev-commit --abbrev=40 --decorate --all --boundary --pretty=format:'%Cgreen%ad %Cred%h%Creset -%C(yellow)%d%Creset %s %Cblue[%cn <%ce>]%Creset %Cblue%G?%Creset'";
  };
}
