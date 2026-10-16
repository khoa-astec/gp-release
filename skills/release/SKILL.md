---
name: release
description: Assemble a release branch from a list of ticket keys. Use when the user says "/release 3.5.8 GP-1 GP-2 ...", "リリースブランチを作って", or asks which tickets of a release are already merged. Finds each ticket's commits, detects fixes already on the base branch or superseded, cherry-picks one commit per ticket linearly onto feature/VERSION_x.y.z, and writes a release map + checklist. Never pushes or force-pushes without approval.
---

# Release branch assembly

Branch model: `feature/VERSION_x.y.z` is cut from the base branch (default `development`). Each ticket lands as **exactly one commit** whose subject is `<KEY> <ticket title copied exactly>` (full-width characters and brackets included). No merge commits.

## Inputs
- Version `x.y.z`, base branch, ticket keys (or a parent ticket whose children are the release).
- Ticket titles from the issue tracker. Copy them verbatim; never retype.

## 1. Map every ticket
Run `scripts/release_map.sh <base> <KEY>...`. For each key it lists commits whose subject starts with the key (all branches) and whether each commit's change is already on the base (`git cherry` patch-id).

Classify each ticket:
| Class | Meaning | Action |
|---|---|---|
| ready | commits found, not on base | pick |
| already-on-base | every commit's patch already on base | exclude, note where |
| superseded | the code it fixes was rewritten/removed later | exclude, ask the user |
| missing | no commits found | ask the user |
| multi-commit | several commits | squash into one commit when picking |

Read the diff of anything suspicious; "already fixed by another ticket" is common and must be caught before release.

## 2. Build the branch (local only)
```
git switch -c feature/VERSION_x.y.z <base>
git cherry-pick --no-commit <commits of KEY in order>
git commit -m "<KEY> <exact title>" -m "<what + why, short>"
```
On conflict: stop, show the conflicting hunks, and ask. Do not resolve by guessing.

## 3. Verify
- `git log --oneline <base>..HEAD`: one line per ticket, in order.
- Syntax-check every changed file; run the test suites the repo has.
- Migrations: list new ones, check they are guarded (`hasIndex` / `hasColumn`) when production may already have hand-applied changes.

## 4. Write the release map
A table per release: key | title | commit | class | notes (migrations, config, ordering dependencies), plus a checklist: deploy order, migrations, env/config changes, cache flushes, smoke tests, rollback.

## 5. Push (only after approval)
`git push -u origin feature/VERSION_x.y.z`. Never `--force`. Fix mistakes with new commits.
