# Claude Code プロジェクトガイド

## プロジェクト概要

京都大学医の倫理委員会への申請書類（研究計画書、説明文書、同意書、情報公開文書）を作成するためのLaTeXテンプレートとビルドシステムです。

## 重要な制限事項

### 読み取り禁止ファイル

以下のファイルは `.claude/settings.json` で読み取りが禁止されています。**絶対にアクセスしないでください**：

- `private/members.yaml` - 研究者の個人情報（氏名、所属、連絡先等）
- `private/members_*.yaml` - バージョン別メンバー情報スナップショット（差分比較用、個人情報を含む）
- `output/*_without_mask.pdf` - 個人情報を含む提出用PDF
- `output/*_without_mask.tex` - 個人情報を含む提出用TeX
- `src/*_without_mask.tex` - 個人情報を含むソースファイル
- `output/*_diff_without_mask.pdf` - 個人情報を含む差分PDF
- `output/*_diff_without_mask.tex` - 個人情報を含む差分TeX
- `src/*_diff_without_mask.tex` - 個人情報を含む差分ソース
- `*.members.tmp`, `*.personal.tmp` - 一時ファイル

### アクセス可能なファイル

以下のファイルは自由に読み書きできます：

- `src/protocol_template.tex` - 研究計画書テンプレート（**架空の研究を題材にした記載例で埋めてあります**。下記参照）
- `src/protocol_template_original.tex` - 研究計画書テンプレートの素の版（指示文のみ・記載例なし）
- `src/explanation_template.tex` - 説明文書テンプレート
- `src/consent_template.tex` - 同意書テンプレート
- `src/disclosure_template.tex` - 情報公開文書テンプレート
- `src/research_info.tex` - 研究基本情報（タイトル、期間等）
- `src/kyodai-protocol.cls` - 文書クラス（研究計画書用）
- `src/kyodai-style.tex` - 3文書共通の体裁設定（和文フォント・見出しの番号様式）
- `output/*_with_mask.pdf` - マスク版PDF（個人情報がプレースホルダー）
- `private/members.yaml.example` - メンバー情報のサンプル（個人情報なし）
- `refs/` - 参考資料置き場（`.gitkeep` のみ git 管理。中身は `.gitignore` 済み）
- `jank/` - 一時ファイル置き場（同上）

## ビルド方法

```bash
# メンバー情報付きでコンパイル（推奨）
./scripts/compile_with_members.sh src/protocol_template.tex

# タイムスタンプ付き
./scripts/compile_with_members.sh -t src/protocol_template.tex

# メンバー情報なしでコンパイル（テスト用）
./docker/latex/compile.sh src/protocol_template.tex

# 差分PDF生成（テンプレート変更のみ）
./scripts/run_latexdiff.sh src/old.tex src/new.tex

# メンバー情報込みの差分PDF生成（2-yaml 指定でメンバー変更もハイライト）
./scripts/run_latexdiff_with_members.sh src/old.tex src/new.tex \
    private/members_第1.3版.yaml private/members.yaml

# メンバー情報＋研究基本情報両方の変更を差分に反映（6引数モード）
./scripts/run_latexdiff_with_members.sh \
    src/protocol_template_202512.tex src/protocol_template.tex \
    private/members_第1.3版.yaml private/members.yaml \
    src/research_info_202512.tex src/research_info.tex
```

**`compile_with_members.sh` の自動スナップショット機能**:
コンパイル時に `src/research_info.tex` の `\ProtocolVersion` を読み取り、以下を未存在時のみ自動コピーします（既存時は上書きしません）：

- `private/members_<バージョン>.yaml`（メンバー情報スナップショット）
- `src/research_info_<バージョン>.tex`（研究基本情報スナップショット）

これにより、版を更新するごとに過去版のスナップショットが自動保存されます。

## 研究計画書の記載例（フィクション）について

`src/protocol_template.tex` は、テンプレートが「書き上がった状態」を示すため、**架空の研究を題材にした記載例で全セクションを埋めてあります**。

- 題材: 「とてつもない予感」を、とてつもない実験デバイス（TJD）と、とてつもない評価スケール（THS）で定量する予備的観察研究
- 記載されている研究・デバイス・評価指標・データ・文献はすべて架空であり、実在の研究・人物・機関・データとは無関係
- 引用文献のうち `chijin202x` / `yokan202x` / `dareka199x` は架空。`newton1687principia` のみ実在の書誌だが、引用の文脈は架空
- 図 `src/figures/tjd.png` も架空のデバイスを描いた挿絵
- 冒頭（目次の前）に、記載例である旨を示す注意書きの枠を配置している

**エージェントの留意点**:

- この記載例の記述を、実在の研究や実在の指針・数値として扱わないこと
- 記入前の素のテンプレート（指示文だけの版）が必要な場合は `src/protocol_template_original.tex` を参照すること
- 記載例を編集する際も、`%%% PLACEHOLDER:... %%%` と冒頭の注意書きの枠は保持すること
- `src/research_info.tex` の `\ResearchTitle` 等も記載例に合わせた架空の値になっている。実際の申請時はここから置き換える
- 説明文書・同意書・情報公開文書は記載例で埋めておらず、汎用のテンプレートのまま（タイトル等は `research_info.tex` 経由で記載例の値が入る）

## テンプレート編集のガイドライン

### 3文書共通の体裁設定（`src/kyodai-style.tex`）

研究計画書・説明文書・同意書は文書クラスが異なる（研究計画書のみ `kyodai-protocol.cls`、他は `bxjsarticle` 直接指定）ため、体裁がばらつかないよう共通部分を `src/kyodai-style.tex` に切り出しています。

読み込み元は次の3ファイルです。**体裁を変える場合はこのファイルを1箇所だけ直すこと**（各テンプレートに個別に書かない）：

- `src/kyodai-protocol.cls`（`\LoadClass` の直後）
- `src/explanation_template.tex`（プリアンブル）
- `src/consent_template.tex`（プリアンブル）

定めているのは以下の2点です。

1. **和文フォント**: `\RequirePackage[ipa]{luatexja-preset}`（IPA明朝／IPAゴシック）
2. **見出しの番号様式**: `\section` → `1.`、`\subsection` → `1)`、`\subsubsection` → `①`、`\paragraph` → 番号なしの太字見出し。`secnumdepth` は 3

情報公開文書（`disclosure_template.tex`）は独立した書式のため、この共通設定は読み込んでいません。

### 差分標示は色のみ（和文の行分割対応）

`docker/latexdiff/postprocess_diff.py` の `make_markup_cjk_safe()` が、latexdiff 既定の ulem ベース標示（`\DIFadd` の `\uwave`、`\DIFdel` の `\sout`）を **青字＝追加 / 赤字＝削除** の色のみの標示に置き換えます。

ulem は空白位置でしか行分割できないため、分かち書きをしない和文では変更箇所が1つの分割不能な塊となり、長い変更が版面の右端からはみ出します。この後処理は `run_latexdiff.sh` / `run_latexdiff_with_members.sh` の両方で自動的に適用されるので、**取り消し線や下線を復活させないこと**。

### 研究基本情報の変更

`src/research_info.tex` を編集してください。このファイルは全てのテンプレートで共有されます：

- `\ResearchTitle` - 研究タイトル
- `\ProtocolVersion` - バージョン
- `\ProtocolDate` - 作成日
- `\StudyStart`, `\StudyEnd` - 研究期間

### メンバー情報のプレースホルダー

テンプレート内の以下のプレースホルダーは、コンパイル時に `private/members.yaml` から自動的に置換されます：

- `%%% PLACEHOLDER:RESEARCH_PI %%%` - 研究代表者情報
- `%%% PLACEHOLDER:ADMIN %%%` - 研究事務局情報
- `%%% PLACEHOLDER:CO_INVESTIGATORS %%%` - 分担研究者リスト
- `%%% PLACEHOLDER:DATA_MANAGER %%%` - データ管理責任者
- `%%% PLACEHOLDER:CONSULTATION %%%` - 相談窓口情報

**これらのプレースホルダーは編集しないでください。**

## 研究メンバー変更・研究基本情報変更を差分ハイライトに反映する運用

研究メンバーの追加・更新・削除、および研究基本情報（タイトル・バージョン・期間等）の変更を差分PDFに反映させるための仕組みです。`members.yaml` や `research_info.tex` のみの変更は標準の `latexdiff` では差分に出ませんが、本プロジェクトでは以下 3 つの仕組みで対応しています。

### 仕組み

1. **自動スナップショット機構（`compile_with_members.sh` の Step 0）**
   - コンパイル時に `\ProtocolVersion` を `src/research_info.tex` から抽出
   - 以下を未存在時のみ自動コピー（既存時は上書きしない）:
     - `private/members_<バージョン>.yaml`（メンバー情報）
     - `src/research_info_<バージョン>.tex`（研究基本情報）

2. **メンバー情報 2-yaml 差分機構**
   - `run_latexdiff_with_members.sh` の引数 3, 4 に旧・新の members.yaml を別々に指定可能
   - それぞれに別の yaml を適用して `_without_mask.tex` を生成してから latexdiff

3. **研究基本情報 inline 展開機構**
   - `run_latexdiff_with_members.sh` の引数 5, 6 に旧・新の research_info.tex を指定可能
   - 指定時は `process_members.py` が `\input{research_info...}` を除去し、
     `\ResearchTitle` 等の変数参照を定義値の文字列に inline 展開
   - これにより latexdiff が研究基本情報の変更を文字列差分として捕捉

### 引数仕様（`run_latexdiff_with_members.sh`）

```
old_tex new_tex \
  [old_members_yaml [new_members_yaml \
  [old_research_info [new_research_info]]]]
```

- 引数 3 のみ: 旧・新の両側に同じ yaml を適用（従来動作）
- 引数 3, 4: 旧・新の yaml を別々に適用（メンバー変更を差分に反映）
- 引数 5, 6: 旧・新の research_info を別々に inline 展開（研究基本情報変更を差分に反映）
- 同一テンプレート比較時は旧版を `<basename>_old_without_mask.tex` として保持

### 典型的な運用フロー

**重要**: スナップショットは「コンパイル時の現行状態」を保存するため、**変更前に旧バージョンの状態でコンパイルしておく必要があります**。順序を間違えると旧バージョンの内容を失います。

```bash
# === 事前準備: 旧バージョンの状態を確実にスナップショットする ===
# (Step 0) 旧バージョン（例: 第1.3版）の状態でコンパイル
#         → private/members_第1.3版.yaml と src/research_info_第1.3版.tex が
#           未存在なら自動生成される
./scripts/compile_with_members.sh src/protocol_template.tex

# 確認: 以下が存在することを確認してから次へ進む
#   private/members_第1.3版.yaml   ← 旧版のメンバー情報
#   src/research_info_第1.3版.tex  ← 旧版の研究基本情報

# === 更新作業 ===
# (Step 1) メンバー情報を更新
nano private/members.yaml

# (Step 2) 研究基本情報を更新（バージョンを上げ、期間・日付等を更新）
nano src/research_info.tex
#   \ProtocolVersion{第1.4版}
#   \ProtocolDate{2026年5月1日}
#   \StudyEnd{2029年3月31日}  など

# (Step 3) 必要に応じてテンプレート本文を更新
nano src/protocol_template.tex
#   改訂履歴に第1.4版の行を追加
#   研究対象者数、評価項目など本文の変更

# (Step 4) 新バージョンでコンパイル
#         → private/members_第1.4版.yaml と src/research_info_第1.4版.tex が
#           新たに自動生成される
./scripts/compile_with_members.sh src/protocol_template.tex

# === 差分検証 ===
# (Step 5) 6 引数モードで包括的な差分PDF生成
./scripts/run_latexdiff_with_members.sh \
    src/protocol_template.tex src/protocol_template.tex \
    private/members_第1.3版.yaml private/members_第1.4版.yaml \
    src/research_info_第1.3版.tex src/research_info_第1.4版.tex
```

### 他のテンプレートでの差分ハイライト

研究計画書（`protocol_template.tex`）以外のテンプレートも、同じスクリプトで差分検証できます。スナップショットは `\ProtocolVersion` をキーにテンプレート横断で共有されるため、Step 0〜4 で生成された `private/members_<バージョン>.yaml` と `src/research_info_<バージョン>.tex` を再利用できます。

**情報公開文書（`disclosure_template.tex`）の差分ハイライト**:

```bash
# Step 0〜4 は protocol と共通（既にスナップショットがあればコンパイルだけでよい）
./scripts/compile_with_members.sh src/disclosure_template.tex

# 6 引数モードで差分PDF生成
./scripts/run_latexdiff_with_members.sh \
    src/disclosure_template.tex src/disclosure_template.tex \
    private/members_第1.3版.yaml private/members_第1.4版.yaml \
    src/research_info_第1.3版.tex src/research_info_第1.4版.tex

# 出力: output/disclosure_template_diff_without_mask.pdf
```

**説明文書（`explanation_template.tex`）・同意書（`consent_template.tex`）の場合**:

同様に、第1引数と第2引数を該当テンプレートに差し替えるだけです。

```bash
./scripts/run_latexdiff_with_members.sh \
    src/explanation_template.tex src/explanation_template.tex \
    private/members_第1.3版.yaml private/members_第1.4版.yaml \
    src/research_info_第1.3版.tex src/research_info_第1.4版.tex
```

**ポイント**:
- 同じバージョンのスナップショット（`members_<ver>.yaml` / `research_info_<ver>.tex`）を全テンプレートで共有
- `compile_with_members.sh` を各テンプレートで実行してもスナップショットは上書きされない（既存保護）
- 同一テンプレート比較時は `<basename>_old_without_mask.tex` として旧版を保持する仕組みが各テンプレートに対して機能する

**旧版テンプレート本体も別ファイルで残している場合**（例: `src/disclosure_template_v1.3.tex`）:

```bash
./scripts/run_latexdiff_with_members.sh \
    src/disclosure_template_v1.3.tex src/disclosure_template.tex \
    private/members_第1.3版.yaml private/members_第1.4版.yaml \
    src/research_info_第1.3版.tex src/research_info_第1.4版.tex
```

この場合は別ファイル比較となり `_old_without_mask.tex` の退避処理は不要です。

### 順序の根拠

`compile_with_members.sh` は「現行 `members.yaml` と `research_info.tex` をその時点の `\ProtocolVersion` をキーに保存」する動作です。したがって：

- **Step 0 を省略してから先に Step 1〜2 を実行すると**: 旧バージョンの状態を保存する機会を失います。Step 4 でコンパイルしても、その時点では既に新バージョンに更新されているので新バージョンのスナップショットしか作られません
- **既に旧バージョンのスナップショットが存在する場合（過去に旧版でコンパイル済み）**: Step 0 は no-op になるので省略可能ですが、念のため実行しておく方が安全
- **新バージョンの version 番号を上げる前にコンパイルすると**: 旧バージョンのスナップショットが上書きされそうに思えますが、`compile_with_members.sh` は **既存スナップショットを上書きしない** 設計なので問題ありません

### エージェントの留意点

- `private/members_*.yaml` は個人情報を含むため **読み取り禁止** です（`.claude/settings.json` で deny 済み）
- `src/research_info_*.tex` は研究基本情報のみで個人情報を含まないため **読み取り可能**
- スナップショットを強制再作成する場合は、ユーザーに依頼して該当ファイルを削除してもらうこと（特に `private/members_<version>.yaml` は個人情報ファイルなのでエージェントが削除操作を取らない）
- `src/*_old_without_mask.tex` も個人情報を含む一時ファイルのため読み取り禁止（`src/*_without_mask.tex` の glob で deny 済み）
- research_info を inline 展開した `_without_mask.tex` には `\input{research_info...}` 行が無くなり、変数が定義値の文字列に置換されている（差分検証用の中間状態）

## メンバー情報の整形について（`scripts/process_members.py`）

`MemberProcessor.SEP` は **全角スペース（U+3000）** です。LuaLaTeX の日本語組版では和文文字どうしの間の半角スペースおよび改行が除去されるため、氏名・所属・職位などを半角スペースや改行で区切ると PDF 上で項目が連結して表示されます。**半角スペースに戻さないこと。**

研究事務局（`RESEARCH_OFFICE`）と相談窓口（`CONSULTATION_CONTACT`）は `\begin{itemize}...\end{itemize}` を含むブロックを生成します。テンプレート側でこれらのプレースホルダーを `\item` の中に置かないこと（itemize が入れ子になります）。研究責任者（`RESEARCH_PI`）も分担研究者と同じく `\textbf{役割}` + 所属 + itemize のブロックを生成するため、同様に `\item` の中には置きません。

## 提出書類のパッケージング

```bash
# クラウドストレージへアップロード（成功時はローカルに残さない）
./scripts/package_submission.sh

# ローカルにフォルダを残す（アップロードしない）
./scripts/package_submission.sh --no-upload
```

`<プロジェクト名>_<バージョン>_<タイムスタンプ>/` というフォルダを作り、PDF をフォルダ直下に、ソースを `src/` サブフォルダに配置してから、rclone で `tmp/<プロジェクト名>/<パッケージ名>/` へフォルダごとアップロードします（圧縮なし）。

パッケージには `without_mask` の PDF（個人情報）が含まれるため、**アップロードに成功した場合はローカルの一時パッケージを自動削除**します。`--no-upload` 指定時やアップロード失敗時のみプロジェクトルートに残ります（`.gitignore` 済み）。エージェントはこのフォルダ内の `without_mask` ファイルを読み取らないこと。

## 注意事項

1. **個人情報を含むファイルは絶対に読み取らないこと**
2. テンプレートの構造を変更する場合は、プレースホルダーの位置を保持すること
3. LaTeX構文エラーがないか、`./docker/latex/compile.sh` でテストすること
4. 図表は `src/figures/` ディレクトリに配置すること（PDF形式推奨）
5. 研究メンバー変更を差分化したい場合は `run_latexdiff_with_members.sh` を 4 引数モードで呼び出すこと（スナップショットを別々に指定）
6. 研究基本情報（タイトル・バージョン・期間等）の変更も差分化したい場合は 6 引数モードで呼び出すこと（research_info.tex も別々に指定）
7. 体裁（和文フォント・見出しの番号様式）は `src/kyodai-style.tex` に集約されている。個々のテンプレートに書き足さないこと
8. 差分標示は色のみ（青＝追加／赤＝削除）。和文が折り返せなくなるため `\uwave` / `\sout` を復活させないこと
9. 参考資料は `refs/`、一時ファイルは `jank/` に置くこと（いずれも中身は git 管理外）
