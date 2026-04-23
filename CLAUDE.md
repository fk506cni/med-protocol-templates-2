# Claude Code プロジェクトガイド

## プロジェクト概要

京都大学医の倫理委員会への申請書類（研究計画書、説明文書、同意書、情報公開文書）を作成するためのLaTeXテンプレートとビルドシステムです。

## 重要な制限事項

### 読み取り禁止ファイル

以下のファイルは `.claude/settings.json` で読み取りが禁止されています。**絶対にアクセスしないでください**：

- `private/members.yaml` - 研究者の個人情報（氏名、所属、連絡先等）
- `output/*_without_mask.pdf` - 個人情報を含む提出用PDF
- `output/*_without_mask.tex` - 個人情報を含む提出用TeX
- `src/*_without_mask.tex` - 個人情報を含むソースファイル
- `output/*_diff_without_mask.pdf` - 個人情報を含む差分PDF
- `output/*_diff_without_mask.tex` - 個人情報を含む差分TeX
- `src/*_diff_without_mask.tex` - 個人情報を含む差分ソース
- `*.members.tmp`, `*.personal.tmp` - 一時ファイル

### アクセス可能なファイル

以下のファイルは自由に読み書きできます：

- `src/protocol_template.tex` - 研究計画書テンプレート
- `src/explanation_template.tex` - 説明文書テンプレート
- `src/consent_template.tex` - 同意書テンプレート
- `src/disclosure_template.tex` - 情報公開文書テンプレート
- `src/research_info.tex` - 研究基本情報（タイトル、期間等）
- `src/kyodai-protocol.cls` - 文書クラス
- `output/*_with_mask.pdf` - マスク版PDF（個人情報がプレースホルダー）
- `private/members.yaml.example` - メンバー情報のサンプル（個人情報なし）

## ビルド方法

```bash
# メンバー情報付きでコンパイル（推奨）
./scripts/compile_with_members.sh src/protocol_template.tex

# タイムスタンプ付き
./scripts/compile_with_members.sh -t src/protocol_template.tex

# メンバー情報なしでコンパイル（テスト用）
./docker/latex/compile.sh src/protocol_template.tex

# 差分PDF生成
./scripts/run_latexdiff.sh src/old.tex src/new.tex
```

## テンプレート編集のガイドライン

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

## 注意事項

1. **個人情報を含むファイルは絶対に読み取らないこと**
2. テンプレートの構造を変更する場合は、プレースホルダーの位置を保持すること
3. LaTeX構文エラーがないか、`./docker/latex/compile.sh` でテストすること
4. 図表は `src/figures/` ディレクトリに配置すること（PDF形式推奨）
