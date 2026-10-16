#!/usr/bin/env bash
# release_map.sh <base-branch> <KEY>... — for each ticket key, list its commits (subject starts with the key,
# any branch, merges excluded) and whether each commit's change is already on <base> (git cherry patch-id).
# Output (tab separated): KEY  STATUS  COMMIT  DATE  SUBJECT
# STATUS: merged (commit is on base) | on-base (same patch is on base) | new (needs picking) | none (no commits)
set -u
base=${1:?usage: release_map.sh <base-branch> <KEY>...}
shift
git rev-parse --verify -q "$base" >/dev/null || { echo "unknown base: $base" >&2; exit 1; }

printf 'KEY\tSTATUS\tCOMMIT\tDATE\tSUBJECT\n'
for key in "$@"; do
  commits=$(git log --all --no-merges --format='%H' --grep="^$key\b" --extended-regexp)
  if [ -z "$commits" ]; then
    printf '%s\tnone\t-\t-\t-\n' "$key"
    continue
  fi
  # one row per distinct patch (the same change cherry-picked to several branches shows once)
  declare -A seen=()
  for c in $commits; do
    pid=$(git show "$c" | git patch-id --stable | cut -d' ' -f1)
    [ -n "$pid" ] && [ -n "${seen[$pid]:-}" ] && continue
    seen[$pid]=1
    if git merge-base --is-ancestor "$c" "$base"; then
      status=merged # the commit itself is on base
    else
      # git cherry prints "-" when an equivalent change (cherry-pick / squash of the same patch) is on base
      mark=$(git cherry "$base" "$c" "$c^" 2>/dev/null | cut -c1)
      status=$([ "$mark" = "-" ] && echo on-base || echo new)
    fi
    printf '%s\t%s\t%s\t%s\t%s\n' "$key" "$status" "$(git log -1 --format=%h "$c")" \
      "$(git log -1 --format=%ad --date=short "$c")" "$(git log -1 --format='%<(60,trunc)%s' "$c")"
  done
  unset seen
done
