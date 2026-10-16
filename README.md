# gp-release

チケット番号の一覧から **リリースブランチを組み立てる** Claude Code スキルです。
各チケットのコミットを探し、**すでに開発ブランチに入っているもの・別チケットで直っているもの** を検出してから、
1チケット1コミットで `feature/VERSION_x.y.z` に積み上げ、リリース一覧（リリースマップ）とチェックリストを作ります。

A Claude Code skill that assembles a release branch from ticket keys: one commit per ticket, duplicates and
already-merged fixes detected first, plus a release map and checklist. It never pushes without approval.

## インストール / Install
```
/plugin marketplace add khoa-astec/gp-release
/plugin install gp-release@gp-release
```

## 使い方 / Usage
```
/release 3.5.8 GP-1001 GP-1002 GP-1003
「3.5.8 のリリースブランチを作って。親チケットは GP-1000」
```
スクリプト単体でも使えます:
```
bash scripts/release_map.sh development GP-1001 GP-1002
```

## 判定 / Classification
| 状態 | 意味 |
|---|---|
| `merged` | そのコミット自体がすでにベースブランチにある |
| `on-base` | 同じ変更（cherry-pick 等）がベースブランチにある |
| `new` | 取り込みが必要 |
| `none` | コミットが見つからない（要確認） |

## ルール
- コミット件名は `<チケット番号> <チケットタイトルをそのままコピー>`（全角文字・【】もそのまま）
- マージコミットは作らない。コンフリクト時は推測で解決せず止めて確認
- push は承認後のみ。`--force` は使わない

## 実績 / Results（2026-10、実際のリリース）
| 項目 | 結果 |
|---|---|
| 定期リリース（14チケット） | 開発ブランチから切ったリリースブランチに、1チケット1コミットで直線的に積み上げ |
| 事前検出 | 取り込み前に **6件** が「開発ブランチで対応済み・別チケットで修正済み・不要」と判明し、重複取り込みを防止 |
| `release_map.sh` | 8チケットの状態判定を約10秒で実行（対応済み2件・取り込み対象5件・コミットなし1件を自動判定） |
