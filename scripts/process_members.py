#!/usr/bin/env python3
"""
研究メンバー情報処理スクリプト

このスクリプトは：
1. private/members.yaml から研究メンバー情報を読み込む
2. LaTeXテンプレート内のプレースホルダーを置換する
3. 2つのバージョンのTeXファイルを生成：
   - _with_mask.tex: メンバー情報がプレースホルダーで表示されたバージョン
   - _without_mask.tex: 実際のメンバー情報が埋め込まれたバージョン（提出用）
"""

import os
import sys
import yaml
import re
from pathlib import Path


class MemberProcessor:
    """研究メンバー情報処理クラス"""

    # マスク用のプレースホルダー
    MASK_VALUES = {
        'name': '研究メンバー（マスク済み）',
        'affiliation': '所属機関名（マスク済み）',
        'position': '職位（マスク済み）',
        'address': '〒000-0000 住所（マスク済み）',
        'tel': '000-000-0000',
        'fax': '000-000-0000',
        'email': 'masked@example.com',
        'role': '役割の説明（マスク済み）',
    }

    def __init__(self, members_yaml_path, template_path, research_info_path=None):
        """
        Args:
            members_yaml_path: メンバー情報YAMLファイルのパス
            template_path: LaTeXテンプレートファイルのパス
            research_info_path: research_info.tex のパス（任意）。
                指定された場合、テンプレート内の `\\input{research_info...}` を
                指定ファイルの内容で置換し、`\\X` 形式の変数参照を
                定義値の文字列にインライン展開する。
                差分検証時に研究基本情報の変更も latexdiff のハイライト対象に
                するために使用する。
        """
        self.members_yaml_path = Path(members_yaml_path)
        self.template_path = Path(template_path)
        self.research_info_path = Path(research_info_path) if research_info_path else None
        self.members_data = None
        self.template_content = None

    def load_members(self):
        """YAMLファイルからメンバー情報を読み込む"""
        if not self.members_yaml_path.exists():
            raise FileNotFoundError(
                f"メンバー情報ファイルが見つかりません: {self.members_yaml_path}\n"
                f"private/members.yaml.example を参考に private/members.yaml を作成してください。"
            )

        with open(self.members_yaml_path, 'r', encoding='utf-8') as f:
            self.members_data = yaml.safe_load(f)

        print(f"✓ メンバー情報を読み込みました: {self.members_yaml_path}")

    def load_template(self):
        """LaTeXテンプレートを読み込む"""
        if not self.template_path.exists():
            raise FileNotFoundError(f"テンプレートファイルが見つかりません: {self.template_path}")

        with open(self.template_path, 'r', encoding='utf-8') as f:
            self.template_content = f.read()

        print(f"✓ テンプレートを読み込みました: {self.template_path}")

    def expand_research_info(self, content):
        """research_info.tex の内容を展開してテンプレートに直接埋め込む。

        差分検証時、研究基本情報（タイトル・バージョン・期間等）の変更を
        latexdiff のハイライト対象にするため、`\\input{research_info...}` を
        除去し、`\\ResearchTitle` 等の変数参照を定義値の文字列に置換する。
        research_info_path が None の場合は何もしない。
        """
        if self.research_info_path is None:
            return content

        if not self.research_info_path.exists():
            raise FileNotFoundError(
                f"research_info ファイルが見つかりません: {self.research_info_path}"
            )

        with open(self.research_info_path, 'r', encoding='utf-8') as f:
            ri_content = f.read()

        # \def\<name>{<value>} 形式のマクロ定義を抽出
        defines = re.findall(r'\\def\\([A-Za-z@]+)\{([^}]*)\}', ri_content)

        # \input{research_info...} 行を除去（テンプレート側で読み込み済みになる）
        content = re.sub(r'\\input\{research_info[^}]*\}\s*\n?', '', content)

        # 変数参照を定義値に置換
        # 負の先読みで `\InstitutionName` が `\InstitutionFullName` を巻き込まないようにする
        for name, value in defines:
            pattern = r'\\' + re.escape(name) + r'(?![A-Za-z@_])'
            # re.sub の置換文字列はバックスラッシュ等を解釈するため lambda で渡す
            content = re.sub(pattern, lambda m, v=value: v, content)

        print(f"✓ research_info を展開しました: {self.research_info_path} "
              f"({len(defines)} 個の定義を inline 化)")
        return content

    def replace_placeholders(self, content, use_real_data=True):
        """
        プレースホルダーを置換

        Args:
            content: 置換対象のコンテンツ
            use_real_data: Trueの場合は実データ、Falseの場合はマスクデータを使用

        Returns:
            置換後のコンテンツ
        """
        # research_info の展開（指定時のみ）
        content = self.expand_research_info(content)

        result = content

        # タイトルページの研究代表者情報
        pi = self.members_data.get('principal_investigator', {})
        result = self._replace_command(result, 'piname',
                                       pi.get('name') if use_real_data else self.MASK_VALUES['name'])
        result = self._replace_command(result, 'piaffiliation',
                                       f"{pi.get('affiliation', '')}・{pi.get('position', '')}" if use_real_data
                                       else f"{self.MASK_VALUES['affiliation']}・{self.MASK_VALUES['position']}")
        result = self._replace_command(result, 'piaddress',
                                       pi.get('address') if use_real_data else self.MASK_VALUES['address'])
        result = self._replace_command(result, 'pitel',
                                       pi.get('tel') if use_real_data else self.MASK_VALUES['tel'])
        result = self._replace_command(result, 'pifax',
                                       pi.get('fax') if use_real_data else self.MASK_VALUES['fax'])
        result = self._replace_command(result, 'piemail',
                                       pi.get('email') if use_real_data else self.MASK_VALUES['email'])

        # タイトルページの研究事務局情報
        admin = self.members_data.get('administrator', {})
        result = self._replace_command(result, 'adminname',
                                       admin.get('name') if use_real_data else self.MASK_VALUES['name'])
        result = self._replace_command(result, 'adminaffiliation',
                                       f"{admin.get('affiliation', '')}・{admin.get('position', '')}" if use_real_data
                                       else f"{self.MASK_VALUES['affiliation']}・{self.MASK_VALUES['position']}")
        result = self._replace_command(result, 'adminaddress',
                                       admin.get('address') if use_real_data else self.MASK_VALUES['address'])
        result = self._replace_command(result, 'admintel',
                                       admin.get('tel') if use_real_data else self.MASK_VALUES['tel'])
        result = self._replace_command(result, 'adminfax',
                                       admin.get('fax') if use_real_data else self.MASK_VALUES['fax'])
        result = self._replace_command(result, 'adminemail',
                                       admin.get('email') if use_real_data else self.MASK_VALUES['email'])

        # 研究実施体制セクション（プレースホルダーで置換）
        result = self._replace_organization_section(result, use_real_data)

        # 研究代表者・研究事務局の個別フィールド（説明文書・同意書・情報公開文書用）
        result = self._replace_pi_admin_fields(result, use_real_data)

        # 相談窓口情報
        result = self._replace_consultation_section(result, use_real_data)

        return result

    def _replace_command(self, content, command, value):
        """LaTeXコマンドを置換"""
        pattern = rf'\\{command}\{{[^}}]*\}}'
        replacement = f'\\{command}{{{value}}}'
        # re.sub()で置換文字列のバックスラッシュをエスケープするため、
        # 置換文字列を関数として渡す
        return re.sub(pattern, lambda m: replacement, content)

    def _replace_organization_section(self, content, use_real_data):
        """研究実施体制セクションを置換"""
        org = self.members_data.get('research_organization', {})

        # 研究責任者（分担研究者と同じ形式でフォーマット）
        pi = org.get('principal_investigator', {})
        pi_text = self._format_member_info(pi, use_real_data, include_role=True, use_co_investigator_format=True)
        content = self._replace_placeholder(content, 'RESEARCH_PI', pi_text)

        # 分担研究者
        # 新しい構造（co_investigators_by_role）を優先的にチェック
        co_investigators_by_role = org.get('co_investigators_by_role', [])
        if co_investigators_by_role:
            co_inv_text = self._format_co_investigators_by_role(co_investigators_by_role, use_real_data)
        else:
            # 古い構造にフォールバック
            co_investigators = org.get('co_investigators', [])
            co_inv_text = self._format_co_investigators(co_investigators, use_real_data)
        content = self._replace_placeholder(content, 'RESEARCH_CO_INVESTIGATORS', co_inv_text)

        # データ管理責任者
        dm = org.get('data_manager', {})
        dm_text = self._format_member_info(dm, use_real_data, include_role=False)
        content = self._replace_placeholder(content, 'RESEARCH_DATA_MANAGER', dm_text)

        # データ管理責任者（個別フィールド）
        content = self._replace_placeholder(content, 'DATA_MANAGER_NAME',
                                           dm.get('name') if use_real_data else self.MASK_VALUES['name'])
        content = self._replace_placeholder(content, 'DATA_MANAGER_AFFILIATION',
                                           dm.get('affiliation') if use_real_data else self.MASK_VALUES['affiliation'])
        content = self._replace_placeholder(content, 'DATA_MANAGER_POSITION',
                                           dm.get('position') if use_real_data else self.MASK_VALUES['position'])

        # 統計解析担当者
        stat = org.get('statistician', {})
        stat_text = self._format_member_info(stat, use_real_data, include_role=False)
        content = self._replace_placeholder(content, 'RESEARCH_STATISTICIAN', stat_text)

        # データマネジメント担当者
        data_mgmt = org.get('data_management', {})
        data_mgmt_text = self._format_member_info(data_mgmt, use_real_data, include_role=False)
        content = self._replace_placeholder(content, 'RESEARCH_DATA_MANAGEMENT', data_mgmt_text)

        # 研究事務局
        office = org.get('research_office', {})
        office_text = self._format_office_info(office, use_real_data)
        content = self._replace_placeholder(content, 'RESEARCH_OFFICE', office_text)

        return content

    def _replace_pi_admin_fields(self, content, use_real_data):
        """タイトルページ用の研究代表者・研究事務局の個別フィールドを置換"""
        # 研究代表者（個別フィールド）
        pi = self.members_data.get('principal_investigator', {})
        content = self._replace_placeholder(content, 'PI_NAME',
                                           pi.get('name') if use_real_data else self.MASK_VALUES['name'])
        content = self._replace_placeholder(content, 'PI_AFFILIATION',
                                           pi.get('affiliation') if use_real_data else self.MASK_VALUES['affiliation'])
        content = self._replace_placeholder(content, 'PI_POSITION',
                                           pi.get('position') if use_real_data else self.MASK_VALUES['position'])
        content = self._replace_placeholder(content, 'PI_ADDRESS',
                                           pi.get('address') if use_real_data else self.MASK_VALUES['address'])
        content = self._replace_placeholder(content, 'PI_TEL',
                                           pi.get('tel') if use_real_data else self.MASK_VALUES['tel'])
        content = self._replace_placeholder(content, 'PI_FAX',
                                           pi.get('fax') if use_real_data else self.MASK_VALUES['fax'])
        content = self._replace_placeholder(content, 'PI_EMAIL',
                                           pi.get('email') if use_real_data else self.MASK_VALUES['email'])

        # 研究事務局（個別フィールド）
        admin = self.members_data.get('administrator', {})
        content = self._replace_placeholder(content, 'ADMIN_NAME',
                                           admin.get('name') if use_real_data else self.MASK_VALUES['name'])
        content = self._replace_placeholder(content, 'ADMIN_AFFILIATION',
                                           admin.get('affiliation') if use_real_data else self.MASK_VALUES['affiliation'])
        content = self._replace_placeholder(content, 'ADMIN_POSITION',
                                           admin.get('position') if use_real_data else self.MASK_VALUES['position'])
        content = self._replace_placeholder(content, 'ADMIN_ADDRESS',
                                           admin.get('address') if use_real_data else self.MASK_VALUES['address'])
        content = self._replace_placeholder(content, 'ADMIN_TEL',
                                           admin.get('tel') if use_real_data else self.MASK_VALUES['tel'])
        content = self._replace_placeholder(content, 'ADMIN_FAX',
                                           admin.get('fax') if use_real_data else self.MASK_VALUES['fax'])
        content = self._replace_placeholder(content, 'ADMIN_EMAIL',
                                           admin.get('email') if use_real_data else self.MASK_VALUES['email'])

        return content

    def _replace_consultation_section(self, content, use_real_data):
        """相談窓口セクションを置換"""
        consult = self.members_data.get('consultation', {})

        if use_real_data:
            consult_text = f"{consult.get('affiliation', '')} {consult.get('position', '')}\n{consult.get('contact_person', '')}\n電話： {consult.get('tel', '')}"
        else:
            consult_text = f"{self.MASK_VALUES['affiliation']} {self.MASK_VALUES['position']}\n{self.MASK_VALUES['name']}\n電話： {self.MASK_VALUES['tel']}"

        content = self._replace_placeholder(content, 'CONSULTATION_CONTACT', consult_text)

        # 相談窓口（個別フィールド）
        content = self._replace_placeholder(content, 'CONSULTATION_CONTACT_PERSON',
                                           consult.get('contact_person') if use_real_data else self.MASK_VALUES['name'])
        content = self._replace_placeholder(content, 'CONSULTATION_AFFILIATION',
                                           consult.get('affiliation') if use_real_data else self.MASK_VALUES['affiliation'])
        content = self._replace_placeholder(content, 'CONSULTATION_POSITION',
                                           consult.get('position') if use_real_data else self.MASK_VALUES['position'])
        content = self._replace_placeholder(content, 'CONSULTATION_TEL',
                                           consult.get('tel') if use_real_data else self.MASK_VALUES['tel'])
        content = self._replace_placeholder(content, 'CONSULTATION_EMAIL',
                                           consult.get('email', '') if use_real_data else self.MASK_VALUES['email'])

        return content

    def _format_member_info(self, member, use_real_data, include_role=True, use_co_investigator_format=False):
        """メンバー情報をLaTeX形式でフォーマット

        Args:
            member: メンバー情報の辞書
            use_real_data: Trueの場合は実データ、Falseの場合はマスクデータを使用
            include_role: 役割を含めるかどうか
            use_co_investigator_format: Trueの場合は分担研究者と同じ（役割→所属→itemize）形式でフォーマット
        """
        if use_co_investigator_format:
            if use_real_data:
                role_text = member.get('role', '')
                affiliation_text = member.get('affiliation', '')
                member_line = f"  \\item {member.get('position', '')} {member.get('name', '')}"
            else:
                role_text = self.MASK_VALUES['role']
                affiliation_text = self.MASK_VALUES['affiliation']
                member_line = f"  \\item {self.MASK_VALUES['position']} {self.MASK_VALUES['name']}"

            if include_role and role_text:
                return f"""\\textbf{{{role_text}}}

{affiliation_text}
\\begin{{itemize}}
{member_line}
\\end{{itemize}}"""
            else:
                return f"""{affiliation_text}
\\begin{{itemize}}
{member_line}
\\end{{itemize}}"""
        else:
            if use_real_data:
                lines = [
                    f"氏名: {member.get('name', '')}",
                    f"所属: {member.get('affiliation', '')}",
                    f"職位: {member.get('position', '')}",
                ]
                if include_role and 'role' in member:
                    lines.append(f"役割: {member.get('role', '')}")
            else:
                lines = [
                    f"氏名: {self.MASK_VALUES['name']}",
                    f"所属: {self.MASK_VALUES['affiliation']}",
                    f"職位: {self.MASK_VALUES['position']}",
                ]
                if include_role:
                    lines.append(f"役割: {self.MASK_VALUES['role']}")

            return '\n'.join(lines)

    def _format_co_investigators(self, co_investigators, use_real_data):
        """分担研究者リストをフォーマット（旧形式: フラットリスト）"""
        if not co_investigators:
            return "分担研究者: なし"

        sections = []
        for i, member in enumerate(co_investigators, 1):
            if use_real_data:
                section = f"""\\textbf{{分担研究者{i}}}

{member.get('role', '')}

{member.get('affiliation', '')}
{member.get('position', '')} {member.get('name', '')}
"""
            else:
                section = f"""\\textbf{{分担研究者{i}}}

{self.MASK_VALUES['role']}

{self.MASK_VALUES['affiliation']}
{self.MASK_VALUES['position']} {self.MASK_VALUES['name']}
"""
            sections.append(section)

        return '\n'.join(sections)

    def _format_co_investigators_by_role(self, co_investigators_by_role, use_real_data):
        """分担研究者を役割・所属ごとにグループ化してフォーマット（新形式）"""
        if not co_investigators_by_role:
            return "分担研究者: なし"

        sections = []
        for role_group in co_investigators_by_role:
            role_name = role_group.get('role_name', '')

            if use_real_data:
                role_section = f"\\textbf{{{role_name}}}\n\n"
            else:
                role_section = f"\\textbf{{{self.MASK_VALUES['role']}}}\n\n"

            dept_sections = []
            for department in role_group.get('departments', []):
                dept_name = department.get('department', '')
                members = department.get('members', [])

                if use_real_data:
                    dept_line = f"{dept_name}"
                else:
                    dept_line = f"{self.MASK_VALUES['affiliation']}"

                member_lines = []
                for member in members:
                    if use_real_data:
                        member_line = f"  \\item {member.get('position', '')} {member.get('name', '')}"
                    else:
                        member_line = f"  \\item {self.MASK_VALUES['position']} {self.MASK_VALUES['name']}"
                    member_lines.append(member_line)

                if member_lines:
                    dept_section = f"{dept_line}\n\\begin{{itemize}}\n" + "\n".join(member_lines) + "\n\\end{itemize}\n"
                    dept_sections.append(dept_section)

            role_section += '\n\\vspace{{0.5em}}\n\n'.join(dept_sections)
            sections.append(role_section)

        return '\n\\vspace{{1em}}\n\n'.join(sections)

    def _format_office_info(self, office, use_real_data):
        """研究事務局情報をフォーマット"""
        if use_real_data:
            return f"""{office.get('affiliation', '')}
{office.get('position', '')} {office.get('name', '')}

{office.get('address', '')}
電話： {office.get('tel', '')}"""
        else:
            return f"""{self.MASK_VALUES['affiliation']}
{self.MASK_VALUES['position']} {self.MASK_VALUES['name']}

{self.MASK_VALUES['address']}
電話： {self.MASK_VALUES['tel']}"""

    def _replace_placeholder(self, content, placeholder, value):
        """プレースホルダーを置換"""
        pattern = f'%%% PLACEHOLDER:{placeholder} %%%'
        return content.replace(pattern, value)

    def generate_files(self):
        """マスク版と実データ版の2つのファイルを生成"""
        # ベース名を取得
        base_name = self.template_path.stem
        output_dir = self.template_path.parent

        # マスク版
        masked_content = self.replace_placeholders(self.template_content, use_real_data=False)
        masked_path = output_dir / f"{base_name}_with_mask.tex"
        with open(masked_path, 'w', encoding='utf-8') as f:
            f.write(masked_content)
        print(f"✓ マスク版を生成しました: {masked_path}")

        # 実データ版
        real_content = self.replace_placeholders(self.template_content, use_real_data=True)
        real_path = output_dir / f"{base_name}_without_mask.tex"
        with open(real_path, 'w', encoding='utf-8') as f:
            f.write(real_content)
        print(f"✓ 実データ版を生成しました: {real_path}")

        return masked_path, real_path


def main():
    """メイン処理

    Usage:
        process_members.py <template_file> [members_yaml] [research_info]

    Args:
        template_file: 処理対象の LaTeX テンプレート
        members_yaml: メンバー情報 YAML（省略時 private/members.yaml）
        research_info: research_info.tex（省略時は \\input ベース、指定時は inline 展開）
    """
    # スクリプトのディレクトリからプロジェクトルートを取得
    script_dir = Path(__file__).parent
    project_root = script_dir.parent

    # デフォルトパス
    members_yaml = project_root / 'private' / 'members.yaml'
    template_file = project_root / 'src' / 'protocol_template.tex'
    research_info = None  # デフォルトは展開しない（\input をそのまま残す）

    # コマンドライン引数があれば上書き
    if len(sys.argv) > 1:
        template_file = Path(sys.argv[1])
    if len(sys.argv) > 2:
        members_yaml = Path(sys.argv[2])
    if len(sys.argv) > 3:
        research_info = Path(sys.argv[3])

    print("=" * 60)
    print("研究メンバー情報処理スクリプト")
    print("=" * 60)

    try:
        processor = MemberProcessor(members_yaml, template_file, research_info)
        processor.load_members()
        processor.load_template()
        masked_path, real_path = processor.generate_files()

        print("\n" + "=" * 60)
        print("✓ 処理が完了しました")
        print("=" * 60)
        print(f"\n生成されたファイル:")
        print(f"  1. {masked_path.name} (メンバー情報がプレースホルダーで表示)")
        print(f"  2. {real_path.name} (実際のメンバー情報を含む提出用)")

        print(f"\n次のステップ:")
        print(f"  1. {masked_path.name} で内容を確認")
        print(f"  2. {real_path.name} をコンパイルして提出用PDFを生成")

    except FileNotFoundError as e:
        print(f"\n❌ エラー: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ 予期しないエラー: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
