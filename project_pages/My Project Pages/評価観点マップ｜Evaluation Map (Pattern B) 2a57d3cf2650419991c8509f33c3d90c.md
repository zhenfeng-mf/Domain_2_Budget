# 評価観点マップ｜Evaluation Map (Pattern B)

<aside>
🎯

Phase 0 deliverable. Every evaluation criterion from [福岡拠点インターンシップ開発課題｜概要・目的・詳細](https://app.notion.com/p/3cded78da730804ca038f26326a24747?pvs=21) mapped to the artifact a reviewer opens to see it.

**How to use:** scan the Evidence column weekly. Blanks marked ⬜ are exactly where points get lost. Mirror this file into the repo as `EVALUATION_MAP.md`.

</aside>

Process: [インターン課題 End-to-End 進行フロー（チーム予算・経費申請アプリ）](https://app.notion.com/p/End-to-End-bbb16aac2d5649908b4f852ec7456253?pvs=21) · Current truth: [Project State Page](https://app.notion.com/p/Project-State-Page-d668ae80bf594171adf1c3d0000ea0d4?pvs=21)

## 1. 技術面の評価観点（9項目）

| # | 観点 | What it means in this app | Evidence a reviewer opens | State |
| --- | --- | --- | --- | --- |
| T1 | Webアプリケーションの基礎実装力 | Rails conventions followed; no leftover scaffold smell; screens, DB, and server-side wired into one working flow | codebase, `git log` | ⬜ |
| T2 | 要件をシステム設計へ落とし込む力 | `Budget` (cap) separated from `Expense` (claim); 利用日 drives month attribution; structure tolerates change | `DESIGN.md` ER diagram | ⬜ |
| T3 | 業務ルールと境界条件を正しく扱う力 | Cap invariant, state machine, integrity enforced at **both** app and DB layer | invariant table in `DESIGN.md`  • migrations + tests | ⬜ |
| T4 | 利用者と役割に応じた機能設計 | メンバー / 承認者 permissions enforced server-side, not just hidden in views | policy code + authorization tests | ⬜ |
| T5 | 保守性と可読性を意識した実装力 | Approve logic in a service object, not a fat controller; naming, responsibility split, no duplication | codebase | ⬜ |
| T6 | テストによって品質を担保する力 | *Which risks I chose and why* — concurrency, boundary, authorization. Not test count | `TESTING.md` — "the 5 things that must never break" | ⬜ |
| T7 | 開発環境と成果物を再現可能にする力 | Clean clone → `docker compose up` → working app with seed data | README, Dockerfile, `db/seeds.rb` | ⬜ |
| T8 | 設計判断を説明する力 | Row lock vs cached counter + CHECK constraint — with the rejected side argued | `DECISIONS.md` | ⬜ |
| T9 | AIを道具として使いこなす力 | Cases where I verified, corrected, and **rejected** AI output | `AI_USAGE.md` | ⬜ |

<aside>
⭐

T8 and T9 cannot be produced at the end — they are accumulated. This is why `DECISIONS.md` and the AI usage notes start on day 1.

</aside>

## 2. プロダクト面の評価観点（7項目）

| # | 観点 | What it means in this app | Evidence a reviewer opens | State |
| --- | --- | --- | --- | --- |
| P1 | 仕様の背景にあるユーザー課題を捉える力 | Why approvers currently cannot see the true remaining budget, and what that costs the team | README "what it is / who it is for" | ⬜ |
| P2 | 複数の利用者の立場を考える力 | Designed the approver *queue*, not just the submission form. Both actors' jobs work | approver pending-queue screen | ⬜ |
| P3 | 制約の中でユーザー体験を設計する力 | A blocked approval explains how much is actually left; empty, error, and completion states all handled | error copy, screenshots | ⬜ |
| P4 | 正確性・安心感・信頼性への意識 | Integer yen; ¥12,000 formatting everywhere; new remaining budget restated after approving | UI + `DECISIONS.md` | ⬜ |
| P5 | 仕様にない課題を発見する力 | 差し戻し / over-budget warning before submitting — with priority reasoning, not feature count | README extras section | ⬜ |
| P6 | 技術と事業をつなげて考える力 | For each extra: feature → user problem → value delivered | presentation §6 | ⬜ |
| P7 | マネーフォワードのプロダクト開発への理解 | Accuracy and traceability framing: audit log, never delete to represent rejection | presentation §1 and §7 | ⬜ |

## 3. 必須要件チェックリスト（pass / fail）

Separate from the tables above — these are not judgment calls. Losing one is a pure, avoidable deduction.

### 技術・品質要件（§6）

- [x]  Rails 8以降
- [x]  MySQL 9以降
- [ ]  重要な業務ルールをアプリケーションとデータベースの両面から整合性を考慮
- [ ]  主要な正常系および**境界条件**を確認できるテスト
- [ ]  READMEにセットアップ方法と実行方法を記載
- [ ]  セットアップ用スクリプト / Dockerfile（第三者が環境を再現できる）
- [ ]  Gitによるバージョン管理
- [ ]  **`rails new`直後の未修正状態を最初のコミット**／コミットメッセージにオプション付きコマンドを記載 ← *retrofitting impossible, do on day 1*

### 提出物（§8）

- [ ]  GitリポジトリURL
- [ ]  インターネット上へ公開したアプリケーションのURL
- [ ]  アプリケーションの設計概要と、その設計を選択した理由
- [ ]  工夫した点、アピールポイント
- [ ]  重要だと考えたテストと、その理由
- [ ]  任意機能：対象としたユーザー課題と追加理由
- [ ]  AI利用記録（ツール名／目的／確認・修正した例／**不採用とした例と理由**／検証方法）
- [ ]  その他の設計判断・トレードオフ

### コストルール（違反すると別次元の問題）

- [ ]  有料プランを新規契約していない
- [ ]  従量課金APIキー・課金有効なクラウドプロジェクトを作っていない
- [ ]  認証情報・実データをAIへ入力していない（ダミーデータのみ）

## 4. 週次レビュー用メモ

| Reviewed on | ⬜ remaining | Biggest gap | Action |
| --- | --- | --- | --- |
|  |  |  |  |