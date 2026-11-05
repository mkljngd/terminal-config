# =========================================================
# Functions
# =========================================================

# Make a directory (and parents) then cd into it.
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Latest tag whose name ends with <suffix> (newest by creation date).
gltag() {
  if [[ -z "$1" ]]; then
    echo "usage: gltag <suffix>" >&2
    return 1
  fi
  git tag -l "*$1" --sort=-creatordate | head -n 1
}

# Create <tag> and push it to origin.
tagpush() { git tag "$1" && git push origin "$1"; }

# Resolve which branch to treat as "the base" for a repo: use $1 if the repo
# actually has it on origin, else fall back to origin's own default branch
# (main/master/whatever HEAD points at), else "main". Shared by gitmr and
# anything else that needs a best-effort base branch. Never fails — always
# prints something usable.
_git_default_base() {
  local want="$1" base
  if [[ -n "$want" ]] && git ls-remote --exit-code --heads origin "$want" >/dev/null 2>&1; then
    echo "$want"
    return
  fi
  # Ask GitHub, not the local origin/HEAD ref: clones that never ran
  # `git remote set-head` don't have one, which used to fall through to "main".
  base=$(git ls-remote --symref origin HEAD 2>/dev/null | awk '/^ref:/ {sub("refs/heads/", "", $2); print $2}')
  echo "${base:-main}"
}

# Push current branch and open a PR.
# USAGE: gitmr [develop|master|stage]   (default: develop)
gitmr() {
  local branch base want="${1:-develop}"

  case "$want" in
    develop|dev) want="develop" ;;
    master|main) want="master" ;;
    stage) want="stage" ;;
    *)
      echo "usage: gitmr [develop|master|stage]" >&2
      return 1
      ;;
  esac

  branch=$(git rev-parse --abbrev-ref HEAD)
  git push -u origin "$branch" || return 1

  base=$(_git_default_base "$want")
  # No --web: it builds the title/body as URL query params for a browser
  # compare page and never calls the create API, so a repo with a large
  # PR template or many commits can produce a URL past the OS length limit
  # and silently create nothing. Plain `gh pr create` posts via the API and
  # prints the PR URL to stdout instead.
  local url
  url=$(gh pr create --base "$base" --head "$branch" --fill) || return 1
  url="${url%%$'\n'*}/changes"
  echo "$url"
  print -rn -- "$url" | _ks-system-clipboard && echo "(copied)"
}
