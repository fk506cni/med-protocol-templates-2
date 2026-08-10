# 京都大学医の倫理委員会 研究書類作成システム

京都大学医の倫理委員会に提出する研究書類（研究計画書、説明文書、同意書、情報公開文書）を作成するためのLaTeXテンプレートとビルドシステムです。

## 特徴

- **包括的なテンプレート**: 倫理委員会提出に必要な4種類の書類テンプレートを提供
  - 研究計画書（protocol_template.tex）
  - 被験者への説明文書（explanation_template.tex）
  - 同意書（consent_template.tex）
  - 情報公開文書（disclosure_template.tex）
- **書き上がった状態が分かる記載例**: 研究計画書は架空の研究を題材にした記載例で全セクションを埋めてあり、図表・数式・引用文献・リスク対策の書きぶりを一通り確認できる（素の版は `protocol_template_original.tex`）
- **一元管理された研究情報**: 研究タイトルや期間などの基本情報を一箇所で管理
- **3文書共通の体裁設定**: 和文フォントと見出しの番号様式を `src/kyodai-style.tex` に集約し、研究計画書・説明文書・同意書の体裁を自動的に揃える
- **LaTeXによる記述**: Wordよりも効率的で、バージョン管理が容易
- **Dockerベースのビルド**: 環境に依存しない、再現可能なビルド環境
- **自動タイムスタンプ**: 出力ファイルに自動でタイムスタンプを付与
- **差分ハイライト機能**: latexdiffによる変更箇所の可視化（和文でも折り返せる色のみの標示）
- **エージェント介入可能**: プレーンテキストベースで、AIエージェントによる支援が容易
- **🔒 研究メンバー情報の保護機能**: 個人情報をエージェントから完全に隠蔽しながら、コンパイル時に自動転記

## 必要な環境

- Docker

## セットアップ

### 1. Dockerイメージのビルド

#### 基本的なLaTeX環境（必須）

```bash
docker build -f docker/latex/Dockerfile -t med-protocol-latex .
```

このコマンドは初回のみ実行が必要です（10-20分程度かかります）。

#### latexdiff環境（差分ハイライト機能を使用する場合）

差分ハイライト機能を使用する場合は、latexdiff用のDockerイメージもビルドします：

```bash
docker build -f docker/latexdiff/Dockerfile -t latexdiff-env docker/latexdiff/
```

このイメージには以下が含まれます：
- latexdiff（LaTeX差分生成ツール）
- ghostscript（PDF処理）
- python3-pygments（シンタックスハイライト）

**注意**: `scripts/run_latexdiff.sh`を実行すると、このイメージが存在しない場合は自動的にビルドされます。

#### SVG変換環境（SVGファイルをPDFに変換する場合）

研究計画書にSVG形式の図を使用する場合は、SVG変換用のDockerイメージをビルドします：

```bash
docker build -f docker/svg-conversion/Dockerfile.svg-ghostscript-converter -t svg-ghostscript-converter docker/svg-conversion/
```

このイメージには以下が含まれます：
- Inkscape（SVG処理エンジン）
- GhostScript（PDF最適化）
- Microsoft Core Fonts（Arial, Times New Roman等）
- 日本語フォント（Noto CJK, IPA）

**SVGからPDFへの変換方法**：

```bash
# 基本的な使用方法
./docker/svg-conversion/convert.sh ./src/figures/diagram.svg

# 出力ファイル名を指定
./docker/svg-conversion/convert.sh ./src/figures/diagram.svg output.pdf
```

**注意**: `convert.sh`を実行すると、このイメージが存在しない場合は自動的にビルドされます（初回は5-10分程度かかります）。

## 使用方法

### 基本的な使用方法

#### 1. 研究の基本情報を設定

**Step 1-1: 研究メンバー情報の設定（重要）**

まず、研究メンバー情報を`private/members.yaml`に設定します：

```bash
# サンプルファイルをコピー
cp private/members.yaml.example private/members.yaml

# メンバー情報を編集
nano private/members.yaml
```

このファイルで設定する情報：
- 研究代表者（氏名、所属、連絡先等）
- 研究事務局（氏名、所属、連絡先等）
- 分担研究者
- データ管理責任者
- 相談窓口情報

**Step 1-2: 研究の基本情報を設定**

次に、`src/research_info.tex`を編集して、研究の基本情報を設定します：

```bash
nano src/research_info.tex
```

このファイルで設定する情報：
- 研究タイトル
- バージョンと日付
- 研究機関情報
- 研究期間

**重要**:
- `research_info.tex`を編集すると、すべてのドキュメント（研究計画書、説明文書、同意書、情報公開文書）に自動的に反映されます
- **研究メンバー情報（氏名、所属、連絡先等）は`members.yaml`で管理されます。`research_info.tex`には含まれません。**

#### 2. 各テンプレートを編集

必要に応じて各テンプレートをコピーして編集します：

```bash
# 研究計画書（素の版から始める場合）
cp src/protocol_template_original.tex src/my_protocol.tex
nano src/my_protocol.tex

# 研究計画書（記載例を下敷きにする場合）
cp src/protocol_template.tex src/my_protocol.tex
nano src/my_protocol.tex

# 説明文書
cp src/explanation_template.tex src/my_explanation.tex
nano src/my_explanation.tex

# 同意書
cp src/consent_template.tex src/my_consent.tex
nano src/my_consent.tex

# 情報公開文書
cp src/disclosure_template.tex src/my_disclosure.tex
nano src/my_disclosure.tex
```

#### 3. PDFをビルド

**推奨: メンバー情報付きコンパイル**

研究メンバー情報を含めてコンパイルする場合（推奨）：

```bash
# 研究計画書
./scripts/compile_with_members.sh src/my_protocol.tex

# 説明文書
./scripts/compile_with_members.sh src/my_explanation.tex

# 同意書
./scripts/compile_with_members.sh src/my_consent.tex

# 情報公開文書
./scripts/compile_with_members.sh src/my_disclosure.tex
```

これにより、`private/members.yaml`の情報が自動的に各ドキュメントに転記されます。

**参考: メンバー情報なしでコンパイル（テスト用）**

メンバー情報のプレースホルダーをそのままにしてコンパイルする場合：

```bash
# 研究計画書
./docker/latex/compile.sh src/my_protocol.tex

# 説明文書
./docker/latex/compile.sh src/my_explanation.tex

# 同意書
./docker/latex/compile.sh src/my_consent.tex

# 情報公開文書
./docker/latex/compile.sh src/my_disclosure.tex
```

**注意**: この方法ではメンバー情報が空のままコンパイルされます。

### タイムスタンプ付きでビルド

```bash
./docker/latex/compile.sh -t src/protocol_template.tex
```

出力ファイル名: `output/protocol_template_20251122_153224.pdf`
シンボリックリンク: `output/protocol_template.pdf` → `protocol_template_20251122_153224.pdf`

### 差分ハイライト機能

2つのバージョン間の変更箇所をハイライト表示したPDFを生成します。

#### 差分の標示について（和文対応）

**青字＝追加、赤字＝削除** で標示します。取り消し線・波下線は使用しません。

latexdiff の既定（UNDERLINE タイプ）は `\DIFadd` に ulem の `\uwave`、`\DIFdel` に `\sout` を用いますが、ulem は空白位置でしか行分割できません。分かち書きをしない和文では変更箇所が 1 つの分割不能な塊となり、長い変更が版面の右端からはみ出して見切れてしまいます。

これを避けるため `docker/latexdiff/postprocess_diff.py` が差分TeXを後処理し、`\uwave` / `\sout` を外して色のみの標示に置き換えます。この処理は `run_latexdiff.sh` / `run_latexdiff_with_members.sh` の両方で自動的に適用されるため、利用者が意識する必要はありません。

#### プレースホルダー版の差分（エージェント確認可能）

研究内容の変更を確認する場合（メンバー情報はプレースホルダーのまま）：

```bash
# 基本的な使用方法
./scripts/run_latexdiff.sh ./src/protocol_v1.tex ./src/protocol_v2.tex

# カスタム出力ディレクトリを指定
./scripts/run_latexdiff.sh -o custom_output ./src/old.tex ./src/new.tex

# 削除部分を非表示にする（追加のみ表示）
./scripts/run_latexdiff.sh --no-del ./src/old.tex ./src/new.tex
```

**出力ファイル:**
- `src/<basename>_diff.tex` - 差分マークアップ付きLaTeXソース
- `output/<basename>_diff.pdf` - 差分がハイライトされたPDF（エージェント確認可能）

#### 🔒 メンバー情報付き差分（提出用、エージェント除外）

**研究メンバーの変更を含む差分を確認する場合**（倫理委員会提出用）：

```bash
# 現行 members.yaml を両側に適用（テンプレート変更のみが差分に反映）
./scripts/run_latexdiff_with_members.sh src/protocol_v1.tex src/protocol_v2.tex

# メンバー情報YAMLを明示的に指定（両側に同じ yaml を適用）
./scripts/run_latexdiff_with_members.sh src/old.tex src/new.tex private/members.yaml

# 🆕 旧版・新版の yaml を別々に指定（メンバー追加/更新/削除もハイライト）
./scripts/run_latexdiff_with_members.sh \
    src/protocol_v1.3.tex src/protocol_v1.4.tex \
    private/members_第1.3版.yaml private/members.yaml

# 🆕 メンバー情報＋研究基本情報両方の変更を差分に反映（6引数モード）
./scripts/run_latexdiff_with_members.sh \
    src/protocol_template_202512.tex src/protocol_template.tex \
    private/members_第1.3版.yaml private/members.yaml \
    src/research_info_202512.tex src/research_info.tex
```

**引数仕様:** `old_tex new_tex [old_members_yaml [new_members_yaml [old_research_info [new_research_info]]]]`
- 引数 3 のみ指定: 旧・新の両側に同じ yaml を適用（従来動作）
- 引数 3, 4 指定: 旧側に `old_members_yaml`、新側に `new_members_yaml` を適用
- 引数 5, 6 指定: 旧・新の `research_info.tex` を inline 展開して比較
  - `\ResearchTitle`、`\ProtocolVersion`、`\ProtocolDate`、`\StudyEnd` 等の変数が
    定義値の文字列に置換されるため、研究基本情報の変更も latexdiff のハイライト対象になります
- メンバー追加・更新・削除、および研究基本情報の変更が差分ハイライトに反映されます

**⚠️ 重要:**
- 生成される差分PDFには**実際のメンバー情報とその変更**がハイライトされます
- `*_diff_without_mask.pdf` はエージェントから完全に除外されています
- 倫理委員会への提出資料としてのみ使用してください

**出力ファイル:**
- `src/<basename>_diff_without_mask.tex` - 差分マークアップ付きTeX（エージェント除外）
- `output/<basename>_diff_without_mask.pdf` - 差分PDF（エージェント除外）
- `src/<basename>_old_without_mask.tex` - 同一テンプレート比較時の旧版保持ファイル（エージェント除外）

#### 🔒 members.yaml と research_info.tex の自動スナップショット管理

`compile_with_members.sh` は Step 0 として、コンパイル時に `src/research_info.tex` の `\ProtocolVersion` をキーに以下を **自動スナップショット** します（既存時は上書きしません）：

- `private/members_<ProtocolVersion>.yaml`（メンバー情報）
- `src/research_info_<ProtocolVersion>.tex`（研究基本情報）

```bash
./scripts/compile_with_members.sh src/protocol_template.tex
# → private/members_第1.3版.yaml が未存在なら自動生成
# → src/research_info_第1.3版.tex が未存在なら自動生成
# → 既存時は保持（上書きなし）
```

**⚠️ 重要な順序**:
スナップショットは「コンパイル時の **現行** 状態」を保存するため、**変更前に旧バージョンの状態でコンパイルしておく必要があります**。順序を間違えると旧バージョンの状態が失われます。

**典型的な運用フロー（バージョン 1.3 → 1.4 の例）**:

```bash
# === 事前準備（旧版のスナップショット確保） ===
# Step 0: 旧版（第1.3版）でコンパイル
./scripts/compile_with_members.sh src/protocol_template.tex
# → private/members_第1.3版.yaml と src/research_info_第1.3版.tex が
#   未存在なら自動生成される（既に存在する場合は何もしない）

# === 更新作業 ===
# Step 1: メンバー情報を更新
nano private/members.yaml

# Step 2: 研究基本情報を更新
nano src/research_info.tex
#   \ProtocolVersion{第1.4版} に変更
#   \ProtocolDate を更新
#   \StudyEnd, \DataAcquisitionEnd 等の期間を更新

# Step 3: テンプレート本文を更新（必要な場合）
nano src/protocol_template.tex
#   改訂履歴に第1.4版の行を追加、本文の変更等

# === 新バージョンでコンパイル ===
# Step 4: 新版（第1.4版）でコンパイル
./scripts/compile_with_members.sh src/protocol_template.tex
# → private/members_第1.4版.yaml と src/research_info_第1.4版.tex が
#   新たに自動生成される

# === 差分検証 ===
# Step 5: 6 引数モードで包括的な差分PDF生成
./scripts/run_latexdiff_with_members.sh \
    src/protocol_template.tex src/protocol_template.tex \
    private/members_第1.3版.yaml private/members_第1.4版.yaml \
    src/research_info_第1.3版.tex src/research_info_第1.4版.tex
```

**順序の根拠**:
- `compile_with_members.sh` は「コンパイル時点の `members.yaml` と `research_info.tex` を、その時点の `\ProtocolVersion` をキーに保存」する動作
- したがって Step 0 を省略してから Step 1〜2 を行うと、旧版の状態を保存する機会を失う
- 過去に旧版でコンパイル済みなら Step 0 は no-op になるが、念のため実行しておくと安全
- スナップショットは **上書きしない** ため、Step 0 を実行しても既存ファイルは保護される

**注意**: 同じバージョンのまま members.yaml や research_info.tex を修正しても新規スナップショットは作成されません（上書き防止のため）。その版の差分を取りたい場合は対応するスナップショットを削除してから再コンパイルしてください。

#### 他のテンプレート（情報公開文書・説明文書・同意書）の差分ハイライト

スナップショット（`private/members_<ver>.yaml` / `src/research_info_<ver>.tex`）は `\ProtocolVersion` をキーに **テンプレート横断で共有** されるため、同じスナップショットを使って他のテンプレートも差分ハイライトできます。第1引数と第2引数を該当テンプレートに差し替えるだけです。

**情報公開文書（`disclosure_template.tex`）の場合**:

```bash
# Step 0〜4 で生成済みのスナップショットを再利用（必要なら disclosure 用にもコンパイル）
./scripts/compile_with_members.sh src/disclosure_template.tex

# 6 引数モードで差分PDF生成
./scripts/run_latexdiff_with_members.sh \
    src/disclosure_template.tex src/disclosure_template.tex \
    private/members_第1.3版.yaml private/members_第1.4版.yaml \
    src/research_info_第1.3版.tex src/research_info_第1.4版.tex

# 出力: output/disclosure_template_diff_without_mask.pdf
```

**説明文書（`explanation_template.tex`）・同意書（`consent_template.tex`）の場合**:

```bash
./scripts/run_latexdiff_with_members.sh \
    src/explanation_template.tex src/explanation_template.tex \
    private/members_第1.3版.yaml private/members_第1.4版.yaml \
    src/research_info_第1.3版.tex src/research_info_第1.4版.tex

./scripts/run_latexdiff_with_members.sh \
    src/consent_template.tex src/consent_template.tex \
    private/members_第1.3版.yaml private/members_第1.4版.yaml \
    src/research_info_第1.3版.tex src/research_info_第1.4版.tex
```

**ポイント**:
- スナップショットを **再生成する必要はない**（同じ `\ProtocolVersion` のものをすべてのテンプレートで共有）
- 同一テンプレート比較時は `<basename>_old_without_mask.tex` として旧版を退避する仕組みが各テンプレートで動作（衝突回避）
- 出力ファイル名はテンプレートのベース名に応じて `<basename>_diff_without_mask.pdf` となる

**旧版テンプレート本体を別ファイルで残している場合**（例: `src/disclosure_template_v1.3.tex` を保存している運用）:

```bash
./scripts/run_latexdiff_with_members.sh \
    src/disclosure_template_v1.3.tex src/disclosure_template.tex \
    private/members_第1.3版.yaml private/members_第1.4版.yaml \
    src/research_info_第1.3版.tex src/research_info_第1.4版.tex
```

旧版・新版が別ファイルなので `_old_without_mask.tex` 退避は発動せず、各テンプレート専用の `_without_mask.tex` がそれぞれ生成されます。

### 🔒 研究メンバー情報の管理とコンパイル（推奨）

研究計画書には研究メンバーの個人情報（氏名、所属、連絡先等）が含まれます。本システムでは、**AIエージェントと共同作業する際に、これらの個人情報を完全に保護する機能**を提供しています。

#### 概要と主な機能

- 🔒 **個人情報の完全隔離**: `private/` ディレクトリはエージェントとgitから完全に除外
- 🐳 **Dockerコンテナ内処理**: すべての処理はコンテナ内で実行（ホスト環境不要）
- 📄 **2つのバージョン生成**:
  - マスク版（エージェント確認可能）
  - 実データ版（提出用、エージェント除外）
- 🔄 **自動転記**: YAMLファイルから自動的にLaTeXへ転記

#### 1. メンバー情報の設定

```bash
# サンプルファイルをコピーして、実際のメンバー情報を記入
cp private/members.yaml.example private/members.yaml

# エディタで編集（このファイルはエージェントから完全に隠蔽されます）
nano private/members.yaml
```

#### 2. メンバー情報ファイルの詳細構造

<details>
<summary><b>private/members.yaml の完全なサンプル（クリックして展開）</b></summary>

```yaml
# ===================================================================
# タイトルページ情報
# ===================================================================

# 研究代表者（タイトルページ用）
principal_investigator:
  name: "研究 太郎"
  affiliation: "○○大学医学部附属病院 △△診療科"
  position: "教授"
  address: "〒XXX-XXXX ○○県○○市○○町X-X-X"
  tel: "0X-XXXX-XXXX"
  fax: "0X-XXXX-XXXX"
  email: "kenkyu.taro@example.ac.jp"

# 研究事務局（タイトルページ用）
administrator:
  name: "事務 花子"
  affiliation: "○○大学医学部附属病院 研究支援センター"
  position: "特定助教"
  address: "〒XXX-XXXX ○○県○○市○○町X-X-X"
  tel: "0X-XXXX-XXXX"
  fax: "0X-XXXX-XXXX"
  email: "jimu.hanako@example.ac.jp"

# ===================================================================
# 研究実施体制セクション
# ===================================================================

research_organization:
  # 研究責任者
  principal_investigator:
    name: "研究 太郎"
    affiliation: "○○大学医学部附属病院 △△診療科"
    position: "教授"
    role: "本研究の計画、実施および運営管理におけるすべての責任を持つ。"

  # 分担研究者（複数可）
  co_investigators:
    - name: "分担 一郎"
      affiliation: "○○大学大学院医学研究科 □□講座"
      position: "准教授"
      role: "データ解析に関する教授指導"

    - name: "分担 二郎"
      affiliation: "○○大学大学院医学研究科 ◇◇講座"
      position: "講師"
      role: "データ収集補助"

    - name: "分担 三郎"
      affiliation: "○○大学大学院医学研究科 ◇◇講座"
      position: "助教"
      role: "データ収集補助"

    - name: "統計 花子"
      affiliation: "○○大学大学院情報学研究科 統計科学専攻"
      position: "准教授"
      role: "統計解析、実験デザイン教授指導"

    - name: "協力 次郎"
      affiliation: "△△大学医学部 ××研究所"
      position: "客員研究員"
      role: "データ解析支援"

  # 試料・情報の管理責任者
  data_manager:
    name: "事務 花子"
    affiliation: "○○大学医学部附属病院 研究支援センター"
    position: "特定助教"

  # 統計解析・データマネジメント担当者
  statistician:
    name: "事務 花子"
    affiliation: "○○大学医学部附属病院 研究支援センター"
    position: "特定助教"

  # 研究事務局
  research_office:
    name: "事務 花子"
    affiliation: "○○大学医学部附属病院 研究支援センター"
    position: "特定助教"
    address: "〒XXX-XXXX ○○県○○市○○町X-X-X"
    tel: "0X-XXXX-XXXX"

# ===================================================================
# 相談窓口情報
# ===================================================================

consultation:
  contact_person: "事務 花子"
  affiliation: "○○大学医学部附属病院 研究支援センター"
  position: "特定助教"
  tel: "0X-XXXX-XXXX"
```

</details>

#### 3. コンパイル実行

```bash
# 基本的な使用方法
./scripts/compile_with_members.sh

# タイムスタンプ付き
./scripts/compile_with_members.sh -t

# カスタムテンプレートの使用
./scripts/compile_with_members.sh src/my_protocol.tex
```

このコマンドは以下を**すべてDockerコンテナ内で**自動実行します：

1. **メンバー情報処理**（Dockerコンテナ内）
   - `private/members.yaml` からメンバー情報を読み込み
   - プレースホルダーを置換して2つのTeXファイルを生成

2. **マスク版PDF生成**
   - `src/protocol_template_with_mask.tex` → `output/protocol_template_with_mask.pdf`
   - エージェントと共に確認可能

3. **実データ版PDF生成**
   - `src/protocol_template_without_mask.tex` → `output/protocol_template_without_mask.pdf`
   - 提出用（エージェントから除外）

#### 4. エージェントとの共同作業フロー

**ステップ1: 研究計画書の作成**

エージェントと共に `src/protocol_template.tex` を編集：
- 研究の背景、目的、方法などを記述
- メンバー情報部分は**プレースホルダーのまま**（自動置換されます）

**ステップ2: コンパイル**

```bash
./scripts/compile_with_members.sh -t
```

**ステップ3: マスク版の確認**

`output/*_with_mask.pdf` をエージェントと共に確認：
- 研究メンバー情報は「研究メンバー（マスク済み）」等に置換されています
- その他の内容（研究の背景、目的等）は正常に表示されます
- エージェントに「マスク版PDFを確認して、内容に問題がないかチェックしてください」と依頼可能

**ステップ4: 修正が必要な場合**

エージェントと共に `src/protocol_template.tex` を修正し、再度コンパイル

**ステップ5: 提出**

内容に問題がなければ、`output/*_without_mask.pdf` を倫理委員会に提出

#### 5. セキュリティ保護の仕組み

**エージェント除外設定（`.claude/settings.json`）**

```json
{
  "permissions": {
    "deny": [
      "Read(private/members.yaml)",
      "Read(output/*_without_mask.pdf)",
      "Read(output/*_without_mask.tex)",
      "Read(src/*_without_mask.tex)",
      "Read(output/*_diff_without_mask.pdf)",
      "Read(output/*_diff_without_mask.tex)",
      "Read(src/*_diff_without_mask.tex)"
    ]
  }
}
```

Claude Codeはこれらのファイルを**絶対に読み取ることができません**。

**⚠️ 重要: 他のAIエージェントを使用する場合**

`.claude/settings.json`は**Claude Code専用**の設定ファイルです。他のAIエージェント（GitHub Copilot、Cursor、VS Code Copilot等）を使用する場合は、それぞれのエージェント用の除外設定が必要です：

- **GitHub Copilot**: `.copilotignore`（または設定で除外パスを指定）
- **Cursor**: `.cursorignore`
- **その他のエージェント**: 各エージェントのドキュメントを参照

**推奨設定（各エージェント用）**:
```
# すべてのエージェント用の除外ファイルに以下を記載
private/
output/*_without_mask.pdf
output/*_without_mask.tex
src/*_without_mask.tex
src/*_diff_without_mask.tex
```

使用するエージェントに応じて、適切な除外設定ファイルを作成してください。

**Git除外設定（`.gitignore`）**

```
# 個人情報管理ディレクトリ
private/
!private/.gitkeep

# 個人情報を含むコンパイル済みファイル
output/*_without_mask.pdf
output/*_without_mask.tex
src/*_without_mask.tex
```

Gitリポジトリにもこれらのファイルは含まれません。

**Dockerコンテナ内処理**

すべての処理はDockerコンテナ内で実行されます：

```bash
docker run --rm \
    --user $(id -u):$(id -g) \
    -v "$PROJECT_ROOT:/workspace" \
    med-protocol-latex \
    python3 /workspace/scripts/process_members.py ...
```

- ホストマシンにPython環境は不要
- コンテナ内で完結するため、環境汚染なし

#### 6. よくある質問（FAQ）

<details>
<summary><b>Q1. エージェントは本当にメンバー情報を見ることができないのですか？</b></summary>

**A:** はい、完全に見ることができません。

- `.claude/settings.json` の `permissions.deny` 設定により、Claude Codeは `private/members.yaml` と `*_without_mask` ファイルを読み取ることができません
- これはシステムレベルで保証されています

</details>

<details>
<summary><b>Q2. メンバー情報を変更したい</b></summary>

**A:** `private/members.yaml` を編集して、再度コンパイルしてください。

```bash
nano private/members.yaml
./scripts/compile_with_members.sh -t
```

</details>

<details>
<summary><b>Q3. 分担研究者を追加したい</b></summary>

**A:** `private/members.yaml` の `co_investigators` セクションに追加：

```yaml
co_investigators:
  - name: "新しい分担研究者"
    affiliation: "所属"
    position: "職位"
    role: "役割"
  # 既存のメンバー...
```

</details>

<details>
<summary><b>Q4. マスク版と実データ版で内容が同じか確認したい</b></summary>

**A:** 以下のコマンドで差分を確認できます：

```bash
# TeXファイルの差分（メンバー情報部分のみ異なるはず）
diff src/protocol_template_with_mask.tex src/protocol_template_without_mask.tex

# 目視確認
xdg-open output/protocol_template_with_mask.pdf
xdg-open output/protocol_template_without_mask.pdf
```

</details>

<details>
<summary><b>Q5. 既存の研究計画書に適用したい</b></summary>

**A:** 以下の手順で適用できます：

1. `src/protocol_template.tex` の研究実施体制セクションを確認
2. プレースホルダー（`%%% PLACEHOLDER:RESEARCH_PI %%%` 等）が含まれているか確認
3. 含まれていない場合、テンプレートから該当部分をコピー
4. `private/members.yaml` を作成
5. コンパイル

</details>

<details>
<summary><b>Q6. メンバー情報ファイルが見つからないエラーが出る</b></summary>

```
❌ エラー: メンバー情報ファイルが見つかりません: private/members.yaml
```

**A:** サンプルファイルをコピーして、実際のメンバー情報を記入してください：

```bash
cp private/members.yaml.example private/members.yaml
nano private/members.yaml
```

</details>

<details>
<summary><b>Q7. 研究メンバーの変更を含む差分を確認したい</b></summary>

**A:** 2-yaml 指定でメンバー変更もハイライトに反映できます：

```bash
# 旧版・新版それぞれの yaml スナップショットを指定
./scripts/run_latexdiff_with_members.sh \
    src/protocol_template.tex src/protocol_template.tex \
    private/members_第1.3版.yaml private/members.yaml
```

旧版スナップショット（`private/members_第1.3版.yaml` 等）は、`compile_with_members.sh` 実行時に `\ProtocolVersion` をキーに自動生成されます。

**片方 yaml のみ指定（従来動作）**: `old_tex new_tex` だけ、または 3 引数目に 1 つの yaml を指定した場合、両側に同じメンバー情報が適用されるためメンバー変更は差分に出ません。テンプレート本文の変更のみを見たい場合に使用してください。

生成される `*_diff_without_mask.pdf` には：
- 研究内容の変更がハイライト表示されます
- 2-yaml 指定時は **研究メンバーの変更**もハイライト表示されます
- エージェントから完全に除外されています

**注意:** このPDFは倫理委員会への提出資料としてのみ使用してください。

</details>

<details>
<summary><b>Q8. 研究基本情報（タイトル・期間・バージョン等）の変更を含む差分を確認したい</b></summary>

**A:** 6 引数モードで `research_info.tex` も別々に指定すると、研究基本情報の変更もハイライトに反映できます：

```bash
./scripts/run_latexdiff_with_members.sh \
    src/protocol_template.tex src/protocol_template.tex \
    private/members_第1.3版.yaml private/members.yaml \
    src/research_info_第1.3版.tex src/research_info.tex
```

`research_info.tex` の旧版スナップショット（`src/research_info_第1.3版.tex` 等）は、`compile_with_members.sh` 実行時に `\ProtocolVersion` をキーに自動生成されます。

**仕組み**: 6 引数モードでは `process_members.py` が `\input{research_info...}` を除去し、`\ResearchTitle`、`\ProtocolVersion`、`\ProtocolDate`、`\StudyEnd` 等の変数参照を定義値の文字列に inline 展開します。これにより latexdiff が研究基本情報の変更を文字列差分として捕捉できます。

</details>

<details>
<summary><b>Q9. スナップショットが自動生成されない</b></summary>

**A:** 以下を確認してください：

1. `compile_with_members.sh`（`docker/latex/compile.sh` ではなく）を使用しているか
2. `src/research_info.tex` の `\ProtocolVersion` が定義されているか
3. 同じバージョン名のスナップショットが既に存在していないか（上書きしないため）

同じバージョンのまま members.yaml や research_info.tex を修正して新規スナップショットを取りたい場合：

```bash
rm private/members_<version>.yaml
rm src/research_info_<version>.tex
./scripts/compile_with_members.sh src/protocol_template.tex
```

</details>

#### 7. まとめ

この機能により、以下が実現されます：

✅ **個人情報の完全保護**: エージェントとgitから完全に隔離
✅ **効率的な共同作業**: エージェントと安全に研究計画書を作成
✅ **自動転記**: 手動入力ミスの防止
✅ **再現性**: Dockerコンテナで環境に依存しない処理

**安心してAIエージェントと研究計画書を作成できます！**

### 倫理委員会提出書類のパッケージング

研究計画書や説明文書などの提出書類をひとつのフォルダにまとめ、クラウドストレージにアップロードするスクリプトを提供しています。

#### 機能

`scripts/package_submission.sh` は以下の機能を提供します：

- **バージョン情報の自動取得**: `src/research_info.tex` からバージョン情報を読み取り
- **PDFファイルのリネーム**: 倫理委員会提出用のファイル名に自動変換
  - `protocol_template_without_mask.pdf` → `研究実施計画書_(バージョン).pdf`
  - `consent_template_without_mask.pdf` → `同意書_(バージョン).pdf`
  - `explanation_template_without_mask.pdf` → `説明文書_(バージョン).pdf`
  - `disclosure_template_without_mask.pdf` → `情報公開文書_(バージョン).pdf`
  - ※ `*_diff_*.pdf` や `*_with_mask.pdf` も同様にリネーム
- **ソースコードの同梱**: `src/` フォルダ全体を `src/` サブフォルダとして含める
- **タイムスタンプ管理**: `プロジェクト名_バージョン_YYYYMMDD_HHMMSS` 形式のフォルダ名
- **クラウドストレージへのフォルダアップロード（圧縮なし）**: rclone を使用して `tmp/<プロジェクト名>/<パッケージ名>/` へ配置
  - ZIP を経由しないため、ブラウザやファイル同期クライアントから個別のPDFを直接開ける
  - 日本語ファイル名の文字化け（ZIP のエンコーディング問題）が起こらない
- **アップロード成功時の自動削除**: パッケージには `without_mask`（個人情報）のPDFが含まれるため、アップロードに成功した場合はローカルに残さない
  - `--no-upload` 指定時、またはアップロード失敗時のみプロジェクトルートにフォルダを残す（`.gitignore` 済み）

**パッケージの構成:**

```
<プロジェクト名>_<バージョン>_<タイムスタンプ>/
├── 研究実施計画書_第1.0版.pdf      … PDF はフォルダ直下
├── 説明文書_第1.0版.pdf
├── 同意書_第1.0版.pdf
├── 情報公開文書_第1.0版.pdf
├── README.md
└── src/                             … ソースは src/ サブフォルダ
```

#### 使用方法

```bash
# 基本的な使用（クラウドストレージにアップロード）
./scripts/package_submission.sh

# クラウドストレージへのアップロードをスキップ
./scripts/package_submission.sh --no-upload

# ヘルプを表示
./scripts/package_submission.sh --help
```

#### クラウドストレージの設定

スクリプトは [rclone](https://rclone.org/) を使用してクラウドストレージにアップロードします。**Google Drive の例として実装されていますが、rclone が対応している任意のクラウドベンダー（OneDrive、Dropbox、Amazon S3、Azure Blob Storage など）に対応可能です。**

##### Google Drive の設定例

1. **rclone のインストール**

```bash
# Ubuntu/Debian
sudo apt install rclone

# macOS
brew install rclone

# その他のプラットフォーム
# https://rclone.org/install/ を参照
```

2. **Google Drive の設定**

```bash
rclone config
# 以下の手順で設定：
# - "n" (新しいリモート)
# - 名前: "gdrive" (または任意の名前)
# - ストレージタイプ: "drive" (Google Drive)
# - クライアント ID: Enter (デフォルト)
# - クライアントシークレット: Enter (デフォルト)
# - スコープ: "1" (フルアクセス)
# - ブラウザで認証
```

3. **アップロード先の確認**

スクリプトはデフォルトで `gdrive:tmp/<プロジェクト名>/<パッケージ名>/` (Google Drive の `マイドライブ/tmp/...`) にアップロードします。Google Drive デスクトップを導入した Windows 環境からは `H:\マイドライブ\tmp\<プロジェクト名>\<パッケージ名>\` として参照できます（ドライブレターは環境により異なります）。

##### 他のクラウドベンダーへの対応

**OneDrive の例**:

1. rclone の設定:
```bash
rclone config
# ストレージタイプで "onedrive" を選択
```

2. スクリプトの修正:
```bash
# scripts/package_submission.sh の289行目付近を変更
GDRIVE_PATH="${GDRIVE_REMOTE}:tmp"
# ↓ OneDrive の場合
GDRIVE_PATH="${GDRIVE_REMOTE}:Documents/research_submissions"
```

**Amazon S3 の例**:

1. rclone の設定:
```bash
rclone config
# ストレージタイプで "s3" を選択
# AWS アクセスキーとシークレットキーを入力
```

2. スクリプトの修正:
```bash
# scripts/package_submission.sh の289行目付近を変更
GDRIVE_PATH="${GDRIVE_REMOTE}:tmp"
# ↓ S3 の場合
GDRIVE_PATH="${GDRIVE_REMOTE}:my-bucket/research-submissions"
```

**Dropbox の例**:

1. rclone の設定:
```bash
rclone config
# ストレージタイプで "dropbox" を選択
```

2. スクリプトの修正:
```bash
# scripts/package_submission.sh の275-280行目を変更
for remote_name in "gdrive" "google-drive" "googledrive" "drive"; do
# ↓ Dropbox の場合
for remote_name in "dropbox" "dbox"; do
```

**rclone が対応しているクラウドストレージの一覧**: https://rclone.org/#providers

#### 出力

- **プロジェクトルート**: 最新の ZIP ファイル
- **_archives/**: 過去の ZIP ファイル
- **クラウドストレージ**: 最新の ZIP ファイル（`--no-upload` を指定しない場合）

#### トラブルシューティング

**rclone が見つからない場合**:

スクリプトは自動的にアップロードをスキップし、ローカルに ZIP を作成します。

**rclone の設定を確認する**:

```bash
# 設定済みのリモートを確認
rclone listremotes

# リモートの内容を確認
rclone ls gdrive:tmp

# 手動でアップロード
rclone copy ./med-protocol-templates_*.zip gdrive:tmp
```

**Windows環境での日本語ファイル名の文字化け**:

このスクリプトは Python の zipfile モジュールを使用して UTF-8 エンコーディングで ZIP ファイルを作成します。これにより、以下の環境で日本語ファイル名が正しく表示されます：

- **Windows 10/11**: エクスプローラーで正常に表示されます
- **Windows 7/8**: 7-Zip や WinRAR などのサードパーティ製解凍ソフトの使用を推奨します
- **macOS/Linux**: 標準の解凍ツールで正常に表示されます

もし Windows で文字化けが発生する場合は、以下を試してください：
1. 最新の Windows アップデートを適用
2. 7-Zip（https://www.7-zip.org/）や WinRAR などのサードパーティ製解凍ソフトを使用
3. Windows の地域設定で「UTF-8 を使用したワールドワイド言語サポート」を有効化

### ヘルプの表示

```bash
./docker/latex/compile.sh --help                    # 基本的なコンパイル
./scripts/run_latexdiff.sh --help                   # プレースホルダー版差分
./scripts/compile_with_members.sh --help            # メンバー情報付きコンパイル
./scripts/run_latexdiff_with_members.sh --help      # メンバー情報付き差分
./scripts/package_submission.sh --help              # 提出書類パッケージング
```

## ディレクトリ構造

```
med-protocol-templates/
├── README.md              # このファイル
├── .gitignore             # Git除外設定（private/を含む）
├── .claude/               # Claude Code設定ディレクトリ
│   └── settings.json      # エージェント読み込み禁止設定
├── docker/                # Docker環境
│   ├── README.md          # Docker環境の概要
│   ├── latex/             # LaTeX環境
│   │   ├── Dockerfile         # LaTeX + Python環境のDockerイメージ
│   │   └── compile.sh         # PDFビルドスクリプト
│   ├── latexdiff/         # latexdiff環境
│   │   ├── Dockerfile         # latexdiff用Dockerイメージ
│   │   ├── docker-compose.yml # Docker Compose設定
│   │   ├── normalize_tex.py   # TeXファイル正規化スクリプト
│   │   └── postprocess_diff.py # 差分ファイル後処理スクリプト
│   └── svg-conversion/    # SVG変換環境
├── scripts/
│   ├── run_latexdiff.sh               # 差分ハイライトスクリプト
│   ├── run_latexdiff_with_members.sh  # 🔒 メンバー情報付き差分検証
│   ├── process_members.py             # 🔒 メンバー情報処理スクリプト
│   ├── compile_with_members.sh        # 🔒 メンバー情報付きコンパイル
│   ├── package_submission.sh          # 📦 倫理委員会提出書類パッケージング
│   ├── commit-push.sh                 # message.md でコミット＆プッシュ
│   └── archive_message.sh             # message.md を jank/ へ退避
├── private/               # 🔒 エージェント完全除外ディレクトリ
│   ├── .gitkeep
│   ├── members.yaml.example   # メンバー情報YAMLサンプル
│   ├── members.yaml           # 実際のメンバー情報（ユーザーが作成）
│   └── members_<版>.yaml      # 🔒 版ごとのスナップショット（差分検証用）
├── src/
│   ├── kyodai-protocol.cls        # カスタム文書クラス（研究計画書用）
│   ├── kyodai-style.tex           # ⭐ 3文書共通の体裁設定（和文フォント・見出し番号様式）
│   ├── research_info.tex          # ⭐ 研究基本情報（全ドキュメント共通）
│   ├── research_info_<版>.tex     # 版ごとのスナップショット（差分検証用）
│   ├── protocol_template.tex      # 研究計画書テンプレート（架空の記載例で記入済み）
│   ├── protocol_template_original.tex  # 研究計画書テンプレートの素の版（指示文のみ）
│   ├── explanation_template.tex   # 被験者への説明文書テンプレート
│   ├── consent_template.tex       # 同意書テンプレート
│   ├── disclosure_template.tex    # 情報公開文書テンプレート
│   ├── ref.bib                    # 参考文献（BibTeX）
│   └── figures/                   # 図表ファイル
│       └── tjd.png                # 記載例で用いる架空デバイスの挿絵
├── output/                # PDF出力先ディレクトリ
│   ├── *_with_mask.pdf            # エージェント確認可能版
│   ├── *_without_mask.pdf         # 🔒 提出用版（エージェント除外）
│   └── *_diff_without_mask.pdf    # 🔒 差分PDF（エージェント除外）
├── _archives/             # 📦 過去の提出書類の退避先
├── refs/                  # 📁 参考資料（.gitkeep のみ追跡、中身は git 管理外）
└── jank/                  # 📁 一時ファイル置き場（同上。message.md の退避先）
```

⭐ = 全ドキュメントで共有される重要ファイル
🔒 = エージェントから完全に隠蔽されているファイル・ディレクトリ
📦 = 提出書類パッケージング関連
📁 = フォルダのみ git 管理し、中身は `.gitignore` で除外

### 📁 `refs/` と `jank/` について

倫理委員会のチェックリストや承認済み計画書などの参考資料は `refs/` に置いてください。原稿執筆中の一時ファイルやコミットメッセージの退避先は `jank/` です。

いずれも `.gitignore` で以下のように設定してあり、**フォルダの存在だけが git 管理され、中に置いたファイルは追跡されません**。

```gitignore
refs/*
!refs/.gitkeep

jank/*
!jank/.gitkeep
```

このため、外部から受け取った資料（著作権や機密性の観点からコミットすべきでないもの）をそのまま置いておけます。クローン直後もフォルダが存在するため、`mkdir` は不要です。

## テンプレートの編集

### 研究の基本情報の設定（重要）

**すべてのドキュメントで共通して使用される基本情報は`src/research_info.tex`で一元管理されています。**

`src/research_info.tex`を編集することで、研究計画書、説明文書、同意書、情報公開文書すべてに同じ情報が反映されます：

```latex
% 研究タイトルと版管理
\def\ResearchTitle{研究タイトルをここに記入}
\def\ProtocolVersion{第1.0版}
\def\ProtocolDate{令和XX年XX月XX日}

% 研究機関情報
\def\InstitutionName{京都大学医学部附属病院}
\def\InstitutionHead{京都大学医学部附属病院長}
\def\InstitutionFullName{京都大学大学院医学研究科・医学部及び医学部附属病院}

% 研究期間
\def\StudyStart{研究機関の長の実施許可日}
\def\StudyEnd{令和XX年XX月XX日}
\def\EnrollmentStart{研究機関の長の実施許可日}
\def\EnrollmentEnd{令和XX年XX月XX日}
\def\DataAcquisitionStart{令和XX年XX月XX日}
\def\DataAcquisitionEnd{令和XX年XX月XX日}
```

**研究メンバー情報について**

研究代表者、研究事務局、分担研究者等のメンバー情報は`private/members.yaml`で管理されます。`research_info.tex`には含まれません。

メンバー情報の設定方法：
1. `cp private/members.yaml.example private/members.yaml`
2. `private/members.yaml`を編集
3. `./scripts/compile_with_members.sh`でコンパイル

詳細は「研究メンバー情報の管理とコンパイル」セクションを参照してください。

**注意**: `research_info.tex`を一度編集すれば、すべてのテンプレートで同じ情報が使用されます。個別のテンプレートファイルで重複して編集する必要はありません。

### 研究計画書の記載例について

`src/protocol_template.tex` は、テンプレートが「書き上がった状態」がひと目で分かるよう、**架空の研究を題材にした記載例で全セクションを埋めてあります。**

題材は「とてつもない予感」を定量する予備的観察研究です。専用装置「とてつもない実験デバイス（TJD）」と、予感の強さ $P$・冷や汗の量 $S$・指導教員の呆れ具合 $A$ から定義する新次元尺度「とてつもない評価スケール（THS）」を用い、3つの相互作用条件（凝視／そっと触れる／見て見ぬふり）で予感の大きさを比較します。

$$\mathrm{THS} = \frac{P \times S}{A^{2}}$$

これにより、実際の申請書で必要になる要素を一通り具体例として示しています。

| 記載例が示すもの | 該当箇所 |
|---|---|
| 適格基準の設定根拠の書き方 | 除外基準に「$A = 0$ となる者」を挙げ、THSが発散するためと根拠を明示 |
| 図表・数式・相互参照 | TJDの図、測定スケジュール表、条件内訳表、THSの定義式 |
| リスクと対策の対応づけ | 「鋭利な角」→ 緩衝材と保護手袋、「低い唸り声」→ 防音マットと起動時間の制限 |
| 個人情報の種類の切り分け | 個人情報／仮名加工情報／個人関連情報をそれぞれ具体的に記載 |
| 同意撤回後の時期別対応 | 加工前・解析前・公表前・公表後の4段階 |
| BibTeXによる文献引用 | `src/ref.bib` の架空文献を `\cite` で引用 |

> **すべてフィクションです。** 記載されている研究、デバイス、評価指標、データ、文献はすべて架空のものであり、実在の研究・人物・機関・データとは一切関係ありません。引用文献のうち Newton (1687) のみ実在の書誌ですが、引用の文脈は架空です。生成されるPDFにも、目次の前に記載例である旨の注意書きが表示されます。

**記入前の素のテンプレートが必要な場合**は `src/protocol_template_original.tex` を使ってください。指示文だけが書かれた版で、記載例は含まれていません。

```bash
cp src/protocol_template_original.tex src/my_protocol.tex
```

なお、説明文書・同意書・情報公開文書は記載例で埋めておらず、汎用のテンプレートのままです（研究タイトル等は `src/research_info.tex` 経由で記載例の値が入ります）。

### 提供されるテンプレート

#### 1. 研究計画書（protocol_template.tex）

26セクションからなる包括的な研究計画書テンプレート。**全セクションが架空の研究を題材にした記載例で埋めてあります**（詳細は「研究計画書の記載例について」を参照）。記入前の素の版が必要な場合は `src/protocol_template_original.tex` を使ってください。

セクション構成：

1. 研究の名称
2. 研究の背景
3. 研究の目的および意義
4. 研究対象者の選定方針
5. 研究の方法および研究の科学的合理性の根拠
6. 方法
7. 観察・検査・調査・報告項目とスケジュール
8. 解析の概要
9. 研究期間
10. インフォームド・コンセント (IC) を受ける手順
11. 個人情報等の取り扱い
12. 上記の作成の時期と方法
13. 保有または利用する個人情報等の項目と安全管理措置および留意事項
14. 研究対象者に生じる負担並びに予測されるリスクおよび利益・総合的評価・対策
15. 試料・情報の保管および廃棄の方法
16. 試料・情報の二次利用および他研究機関への提供の可能性
17. 倫理審査委員会及び研究機関の長への報告内容および方法
18. 研究の資金・利益相反
19. 研究対象者等およびその関係者からの相談等への対応
20. 研究対象者等の経済的負担または謝礼
21. 研究対象者に係る研究結果（偶発的所見を含む）等の取扱い
22. 研究の実施体制
23. 研究実施計画書の変更、および改訂
24. 遵守すべき倫理指針、倫理審査
25. 研究成果の帰属
26. 参考文献

`protocol_template_original.tex`（素の版）では、各セクションに記載すべき内容のガイドが含まれています。

**注意**: セクション間の改ページは自動的に抑制され、連続して配置されます。タイトルページ、改訂履歴ページ、目次ページの後のみ改ページが挿入されます。

#### 2. 被験者への説明文書（explanation_template.tex）

「人を対象とする生命科学・医学系研究に関する倫理指針」に準拠した説明同意文書テンプレート。以下の項目を含みます：

- 研究実施について
- 研究機関
- 研究の目的および意義
- 研究方法と期間
- 研究対象者として選定された理由
- 負担とリスク、利益
- 同意の撤回
- 個人情報の取扱い
- 試料・情報の保管および廃棄
- 相談窓口
- その他必要事項

#### 3. 同意書（consent_template.tex）

研究参加への同意を記録する文書テンプレート。1ページに収まるコンパクトなデザインで、説明文書で説明した項目のチェックリスト形式となっています。

#### 4. 情報公開文書（disclosure_template.tex）

既存情報を利用する研究の場合に、研究対象者に情報を公開するための文書テンプレート。後ろ向き研究（既存資料利用）に対応し、14項目の公開事項を含みます。

### 画像の挿入

研究計画書に図表を挿入する方法：

#### 1. 画像ファイルの配置

画像ファイルを`src/figures/`ディレクトリに配置します：

```bash
# 対応形式
src/figures/
├── 研究デザイン図.pdf     # PDF（推奨、ベクター画像）
├── フローチャート.png      # PNG（ビットマップ）
└── グラフ.jpg             # JPEG（写真など）
```

**推奨形式**: PDF（ベクター画像）は拡大しても画質が劣化しないため、図やグラフに最適です。

#### 2. 画像の挿入方法

```latex
% 基本的な画像挿入
\begin{figure}[htbp]
    \centering
    \includegraphics[width=0.8\textwidth]{figures/研究デザイン図.pdf}
    \caption{研究デザインの概要}
    \label{fig:study-design}
\end{figure}

% 本文中で図を参照
図\ref{fig:study-design}に示すように、本研究では...
```

#### 3. 画像サイズの指定

```latex
% テキスト幅の80%
\includegraphics[width=0.8\textwidth]{figures/図.pdf}

% 特定の幅を指定（cm単位）
\includegraphics[width=12cm]{figures/図.pdf}

% 高さを指定
\includegraphics[height=8cm]{figures/図.pdf}

% アスペクト比を維持しながら縮小
\includegraphics[scale=0.5]{figures/図.pdf}
```

#### 4. 複数の画像を並べる

```latex
\begin{figure}[htbp]
    \centering
    \begin{minipage}{0.45\textwidth}
        \centering
        \includegraphics[width=\textwidth]{figures/図1.pdf}
        \caption{図1の説明}
        \label{fig:1}
    \end{minipage}
    \hfill
    \begin{minipage}{0.45\textwidth}
        \centering
        \includegraphics[width=\textwidth]{figures/図2.pdf}
        \caption{図2の説明}
        \label{fig:2}
    \end{minipage}
\end{figure}
```

#### 5. 表の作成

```latex
\begin{table}[htbp]
    \centering
    \caption{測定項目とスケジュール}
    \label{tab:schedule}
    \begin{tabular}{|l|c|c|c|}
    \hline
    \textbf{項目} & \textbf{登録時} & \textbf{6ヶ月} & \textbf{12ヶ月} \\ \hline
    血液検査 & ○ & ○ & ○ \\ \hline
    問診 & ○ & ○ & ○ \\ \hline
    \end{tabular}
\end{table}
```

#### 位置指定オプション

`[htbp]`は図表の配置位置を指定します：
- `h`: here（その場所）
- `t`: top（ページ上部）
- `b`: bottom（ページ下部）
- `p`: page（独立したページ）

## カスタマイズ

### 3文書共通の体裁設定（`src/kyodai-style.tex`）

研究計画書・説明文書・同意書は文書クラスが異なる（研究計画書のみ `kyodai-protocol.cls`、他の2つは `bxjsarticle` 直接指定）ため、放置すると体裁がばらつきます。これを防ぐため、**3文書に共通する体裁だけを `src/kyodai-style.tex` に切り出し**、以下の3ファイルから読み込んでいます。

| 読み込み元 | 読み込み方 |
|-----------|-----------|
| `src/kyodai-protocol.cls` | `\input{kyodai-style.tex}`（`\LoadClass` の直後） |
| `src/explanation_template.tex` | `\input{kyodai-style.tex}`（プリアンブル） |
| `src/consent_template.tex` | `\input{kyodai-style.tex}`（プリアンブル） |

`kyodai-style.tex` が定めているのは次の2点です。

**1. 和文フォント（IPA明朝 / IPAゴシック）**

```latex
\RequirePackage[ipa]{luatexja-preset}
```

倫理委員会のチェックリストは「MS明朝」「MSゴシック」を指定していますが、当該フォントは Microsoft 専有でありビルド環境（`texlive/texlive` イメージ）に導入できません。規定の趣旨である「Windows との互換性による文字化けの防止」はPDFへのフォント埋め込みによって満たしたうえで、書体としては指定に最も近い無償の標準和文フォントを用いています。

**2. 見出しの番号様式**

| レベル | 表記 |
|--------|------|
| `\section` | `1.` `2.` `3.` … |
| `\subsection` | `1)` `2)` `3)` … |
| `\subsubsection` | `①` `②` `③` … |
| `\paragraph` | 番号なし（太字見出し） |

下位の見出しほど左を字下げし、階層を視覚的に示します。番号を付す深さは `\subsubsection`（①）までです。

**変更する場合は `kyodai-style.tex` を1箇所だけ直せば3文書すべてに反映されます。** 情報公開文書（`disclosure_template.tex`）は独立した書式のため、この共通設定は読み込んでいません。

### 文書クラスのカスタマイズ

`src/kyodai-protocol.cls`を編集することで、以下をカスタマイズできます：

- ページレイアウト
- ヘッダー・フッター
- タイトルページの体裁
- 目次の体裁（ドットリーダー等）
- カスタムコマンド

※ 和文フォントと見出しの番号様式は `src/kyodai-style.tex` に移動しています（上記参照）。

### スタイルの変更例

マージンを変更する場合：

```latex
% kyodai-protocol.cls内
\geometry{margin=25mm}  % 25mmから変更
```

## 京都大学医の倫理委員会の要件

本テンプレートは、以下の京都大学医の倫理委員会の要件を満たしています：

- 「人を対象とする生命科学・医学系研究の倫理審査にあたり研究計画書に記載すべき事項」(2023.7.7版)
- 観察研究の記載要件
- 選択項目表に基づく適切な項目選択

## 注意事項

### 一般的な注意事項

- 研究計画書は必ず最新の倫理指針に基づいて作成してください
- テンプレートの各項目は適切に記入し、不要な項目は削除してください
- 個人情報を含むファイルは適切に管理してください

### **重要：AIエージェント使用時のデータプライバシーについて**

本テンプレートシステムはMarkdown形式のため、Claude Code等のAIエージェントを活用して研究計画書を作成することが可能です。しかし、**AIエージェント使用時には以下の点に十分注意してください**：

#### 🔒 AIエージェント別の除外設定

本システムは`.claude/settings.json`を使用してClaude Codeから個人情報を保護していますが、**他のAIエージェントを使用する場合は別途除外設定が必要です**：

| AIエージェント | 除外設定ファイル | 備考 |
|---|---|---|
| Claude Code | `.claude/settings.json` | 本リポジトリに含まれています |
| GitHub Copilot | `.copilotignore` | 別途作成が必要 |
| Cursor | `.cursorignore` | 別途作成が必要 |
| VS Code Copilot | 設定で除外パス指定 | `settings.json`で設定 |

**すべてのエージェントで以下のパスを除外してください**:
- `private/`（個人情報を含むYAMLファイル）
- `output/*_without_mask.pdf`（実データ版PDF）
- `output/*_without_mask.tex`（実データ版TeX）
- `src/*_without_mask.tex`（実データ版TeX）
- `src/*_diff_without_mask.tex`（実データ版差分TeX）

#### ⚠️ 個人情報の取り扱い

**AIエージェントに入力・共有してはいけない情報：**

- **研究対象者の個人情報**（氏名、生年月日、住所、電話番号等）
- **研究者の個人情報**（氏名、生年月日、住所、電話番号等）
- **既に収集した研究データ**（実験データ、測定値、症例情報等）
- **カルテ情報や診療記録**
- **未公開の研究成果や知的財産に関わる情報**
- **施設固有の機密情報**

**共有可能な情報：**

- 研究デザインや研究手法の一般的な記述
- 公開されている文献情報
- 統計手法や解析方法の記述
- 倫理委員会への提出書類の構造や形式
- テンプレートの項目構成

#### 🔒 データ学習に関する確認事項

**AIサービスを使用する前に、必ず以下を確認してください：**

1. **利用規約の確認**
   - 使用するAIサービス（Claude、ChatGPT、Copilot等）の利用規約を必ず確認してください
   - 入力データがモデルの学習に使用されるかどうかを確認してください
   - データ保持期間やデータ削除ポリシーを確認してください

2. **エンタープライズ版の使用**
   - 可能な限り、データが学習に使用されない保証のあるエンタープライズ版やビジネス版を使用してください
   - 例：Claude for Work、ChatGPT Enterprise、GitHub Copilot for Business等

3. **機関のポリシー確認**
   - 所属機関の情報セキュリティポリシーに従ってください
   - 機関がAIサービスの使用を許可しているか確認してください
   - 必要に応じて、情報セキュリティ担当部署に相談してください

4. **データの匿名化**
   - AIに相談する場合は、必ず情報を一般化・匿名化してから行ってください
   - 具体的な氏名、施設名、固有の情報は除外してください

#### 推奨される使用方法

**安全な使用例：**
```
「観察研究の研究計画書で、研究対象者の選定方針のセクションを
書きたいです。選択基準と除外基準の記載例を教えてください。」
```

**避けるべき使用例（個人情報含む）：**
```
「山田太郎さん（〇〇病院、ID:12345）のデータを使った研究計画書を
作成したいです。」← これは絶対に避けてください
```

#### 責任事項

- **研究責任者は、研究計画書に含まれるすべての情報の管理責任を負います**
- AIエージェントの使用は研究者の判断と責任において行ってください
- 個人情報保護法、医学研究倫理指針、所属機関の規定を遵守してください
- 不明な点がある場合は、必ず所属機関の倫理委員会や情報セキュリティ担当部署に相談してください

## トラブルシューティング

### Dockerイメージのビルドに失敗する

```bash
# キャッシュをクリアして再ビルド
docker build --no-cache -f docker/latex/Dockerfile -t med-protocol-latex .
```

### PDFのビルドに失敗する

```bash
# Dockerコンテナ内で直接デバッグ
docker run --rm -it -v $(PWD):/workspace med-protocol-latex /bin/bash
cd src
platex protocol_template.tex
```

### 日本語フォントが表示されない

Dockerイメージには日本語フォントが含まれています。問題が発生する場合は、イメージを再ビルドしてください。

### クリーンアップ

一時ファイルを削除：

```bash
find output -name "*.aux" -type f -delete
find output -name "*.log" -type f -delete
find output -name "*.toc" -type f -delete
find output -name "*.out" -type f -delete
```

### Dockerコンテナでシェルを起動

```bash
docker run --rm -it -v $(PWD):/workspace med-protocol-latex /bin/bash
```

## 開発者向け情報

### ビルドプロセス

`compile.sh` を使用した場合：

1. `lualatex`で3回コンパイル（目次と相互参照の解決）
2. `upbibtex`で文献処理（日本語対応）
3. PDFを `output/` ディレクトリに移動
4. 一時ファイルのクリーンアップ
5. タイムスタンプオプション使用時はシンボリックリンクを作成

### 差分ハイライトプロセス

`run_latexdiff.sh` を使用した場合：

1. TeXファイルを正規化（より良い差分品質のため）
2. `latexdiff`で差分マークアップを生成
3. 差分ファイルを後処理（`postprocess_diff.py`）
   - タイトル・要約のハイライトを有効化
   - ulem ベースの標示（`\uwave` / `\sout`）を色のみの標示に置換（和文の行分割対応）
4. `compile.sh`でPDFをビルド
5. 指定された出力ディレクトリにPDFを配置

### ページスタイル

- **ヘッダー**: なし（削除済み）
- **フッター**: 中央にページ番号
- **罫線**: なし
- **ページ番号の起点**: タイトルページを1ページ目として数え、本文は2ページ目から採番

## 参考資料

倫理委員会のチェックリストや承認済み計画書の例などは `refs/` に置いて参照してください（`.gitignore` 済みのため、フォルダだけが git 管理されます）。

- 京都大学医の倫理委員会 記載すべき事項チェックリスト
- 完成版研究計画書の例

## 参考リンク

- [京都大学医の倫理委員会](http://www.ec.med.kyoto-u.ac.jp/)
- [臨床研究等総合管理システム](https://kyoto.bvits.com/rinri/)
- [人を対象とする生命科学・医学系研究に関する倫理指針](https://www.mhlw.go.jp/content/001077424.pdf)

## ライセンス

このテンプレートは教育・研究目的で自由に使用できます。

## 評価実験

本システムの有効性を評価するため、公開されているオープンアクセス論文を題材に研究計画書の自動生成実験を実施しました。

### 題材論文

Nakamura, I., et al: Risk factors for aggravated COVID-19 despite medical care after admission among Japanese patients: A Japanese association for infectious diseases COVID registry study, PLOS ONE 20(10)e0335439, 2025.
https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0335439

### 実験結果

`evals/` フォルダに3回の実験で生成された研究計画書PDFを格納しています。各PDFの研究者情報はダミーの個人データで作成されています。

| 実験 | フォルダ | 内容 |
|---|---|---|
| 1回目 | `evals/eval-1/` | マスク版・実データ版PDF |
| 2回目 | `evals/eval-2/` | マスク版・実データ版PDF |
| 3回目 | `evals/eval-3/` | マスク版・実データ版PDF |

## お問い合わせ

問題や改善提案がある場合は、Issueを作成してください。

## 更新履歴

- 2026-08-10: v1.5 体裁の統一・和文差分・パッケージング改善
  - **3文書共通の体裁設定を追加**: `src/kyodai-style.tex` を新規作成し、和文フォント（IPA明朝／IPAゴシック）と見出しの番号様式（`1.` / `1)` / `①`）を集約。`kyodai-protocol.cls`・`explanation_template.tex`・`consent_template.tex` の3ファイルから読み込むことで、研究計画書・説明文書・同意書の体裁が自動的に揃う
  - **和文で折り返せる差分標示**: `postprocess_diff.py` に `make_markup_cjk_safe()` を追加。latexdiff 既定の ulem ベース標示（`\uwave` / `\sout`）は分かち書きしない和文で行分割できず変更箇所が版面からはみ出すため、青字＝追加・赤字＝削除の色のみの標示に置換
  - **目次・ページ番号の体裁**: 目次にドットリーダーを追加。タイトルページを1ページ目として数え、本文を2ページ目から採番
  - **メンバー情報の整形改善**: 項目の区切りを全角スペース（U+3000）に統一（LuaLaTeX の日本語組版では和文間の半角スペース・改行が除去され項目が連結してしまうため）。研究事務局・相談窓口を箇条書きの体裁に統一。`\vspace{{...}}` の二重波括弧バグを修正
  - **パッケージングをフォルダ単位に変更**: ZIP を廃し、`tmp/<プロジェクト名>/<パッケージ名>/` へフォルダごとアップロード。ZIP のエンコーディング問題が原理的に発生せず、個別PDFを直接開ける。アップロード成功時は個人情報を含むローカルパッケージを自動削除
  - **`refs/` `jank/` を追加**: `.gitkeep` でフォルダのみ git 管理し、中身は `.gitignore` で除外
  - **リポジトリ運用スクリプト追加**: `scripts/commit-push.sh`、`scripts/archive_message.sh`
  - **用語の統一**: 「研究代表者」→「研究責任者」、「研究分担者」→「分担研究者」
  - **研究計画書に記載例を追加**: 架空の研究（とてつもない予感の定量）を題材に全26セクションを記入済みの状態に変更。図・表・数式・相互参照・BibTeX引用を含む。素のテンプレートは `src/protocol_template_original.tex` に温存
  - **`amsmath` を文書クラスに追加**: `equation` 環境・`\eqref` を使えるように

- 2025-11-25: v1.4 提出書類パッケージング機能追加
  - **提出書類パッケージングスクリプト追加**: `scripts/package_submission.sh` を新規作成
  - **自動ファイルリネーム**: 倫理委員会提出用のファイル名に自動変換
  - **クラウドストレージ連携**: rclone によるクラウドストレージへの自動アップロード
  - **アーカイブ管理**: 古い ZIP ファイルの自動アーカイブ機能
  - **マルチクラウド対応**: Google Drive、OneDrive、Dropbox、S3 等に対応可能
  - **Windows 互換性**: Python zipfile を使用した UTF-8 エンコーディングで日本語ファイル名の文字化けを防止
  - **詳細ドキュメント追加**: クラウドベンダー別の設定例と Windows 対応について README に追記

- 2025-11-25: v1.3 メンバー情報管理システムの改善
  - **研究メンバー情報の一元管理**: 研究代表者・研究事務局情報を`private/members.yaml`のみで管理
  - **`research_info.tex`の整理**: メンバー情報を削除し、研究の基本情報（タイトル、期間等）のみに集約
  - **プレースホルダー拡張**: `process_members.py`に個別フィールドプレースホルダー対応を追加（`PI_NAME`, `ADMIN_NAME`等）
  - **テンプレート更新**: すべてのテンプレートで`members.yaml`からの自動転記に対応
  - **Docker環境のドキュメント追加**: `latexdiff`と`svg-conversion`のビルド手順をREADMEに追記

- 2025-11-22: v1.2 差分ハイライト機能とビルドシステム改善
  - **差分ハイライト機能追加**: `run_latexdiff.sh` による変更箇所の可視化
  - **新しいビルドスクリプト**: `docker/latex/compile.sh` を追加（`lualatex` + `upbibtex` 使用）
  - **タイムスタンプオプション強化**: シンボリックリンク自動作成機能
  - **ページスタイル改善**: ヘッダーを削除し、ページ番号をフッター中央に移動
  - **権限問題解決**: Dockerコンテナを現在のユーザーで実行（`--user` オプション）
  - **カスタム出力ディレクトリ対応**: `-o` オプションで出力先を指定可能

- 2025-09-30: v1.1 改ページ問題修正
  - セクション間の不要な改ページを解消
  - jarticleクラスベースに変更（jreportから移行）
  - `\sectionmark`の再定義により連続配置を実現
  - 全25セクションを含むテンプレートに更新
  - ページ数を大幅削減（24ページ→12ページ）

- 2025-01-04: v1.0 初版リリース
  - 基本テンプレート作成
  - Dockerベースのビルドシステム構築
  - 全20章の記載要件対応
  - タイムスタンプ自動付与機能
  - AIエージェント使用時のデータプライバシーに関する注意事項を含む