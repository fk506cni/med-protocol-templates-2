\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{kyodai-protocol}[2026/08/10 v1.3 Kyoto University Medical Ethics Protocol Template]

% LuaLaTeX用の日本語文書クラス
\LoadClass[a4paper,11pt,lualatex,ja=standard]{bxjsarticle}

% 3文書共通の体裁設定（和文フォント・見出しの番号様式）
% 説明文書・同意書も同じファイルを読み込むため、3文書の体裁が揃う
\input{kyodai-style.tex}

% 必要なパッケージ（geometryはbxjsarticleが読み込むので、オプションだけ指定）
\geometry{margin=25mm}
\RequirePackage{graphicx}  % LuaLaTeXは画像形式を自動判定
\RequirePackage{xcolor}
\RequirePackage{amsmath}   % 数式環境（equation, \eqref 等）
\RequirePackage{fancyhdr}
\RequirePackage{titlesec}
\RequirePackage{enumitem}
\RequirePackage{longtable}
\RequirePackage{booktabs}
\RequirePackage{hyperref}
\RequirePackage{tocloft}


\usepackage{cite}
\renewcommand{\citepunct}{,\penalty\citepunctpenalty\,}
\renewcommand{\citedash}{--}



% ハイパーリンク設定
\hypersetup{
    colorlinks=true,
    linkcolor=black,        % 内部リンク（目次など）は黒
    filecolor=blue,         % ファイルリンクは青
    urlcolor=blue,          % URLは青
    citecolor=black,        % 引用は黒
    bookmarks=true,         % PDFブックマークを有効化
    bookmarksnumbered=true, % ブックマークに番号を付ける
    pdfstartview=FitH,      % PDF表示時の初期ビュー
}

% ページスタイル
\pagestyle{fancy}
\fancyhf{}
\fancyfoot[C]{\thepage}  % フッター中央にページ番号
\renewcommand{\headrulewidth}{0pt}  % ヘッダーの罫線を削除
\renewcommand{\footrulewidth}{0pt}  % フッターの罫線も削除

% タイトルページ
\makeatletter
\renewcommand{\maketitle}{
    \begin{titlepage}
        \centering
        \vspace*{2cm}
        {\Huge\bfseries \@title \par}
        \vspace{1cm}
        {\Large 研究計画書 \par}
        \vspace{2cm}

        {\Large\bfseries 研究責任者 \par}
        \vspace{0.5cm}
        {\large \@piname \par}
        {\normalsize \@piaffiliation \par}
        {\normalsize \@piaddress \par}
        {\normalsize TEL: \@pitel \quad FAX: \@pifax \par}
        {\normalsize E-mail: \@piemail \par}

        \vspace{2cm}

        {\Large\bfseries 研究事務局 \par}
        \vspace{0.5cm}
        {\large \@adminname \par}
        {\normalsize \@adminaffiliation \par}
        {\normalsize \@adminaddress \par}
        {\normalsize TEL: \@admintel \quad FAX: \@adminfax \par}
        {\normalsize E-mail: \@adminemail \par}

        \vfill
        {\normalsize \@protocolversion \par}
        {\normalsize \@protocoldate \par}
    \end{titlepage}
    % titlepage環境はページ番号を1にリセットするが、表紙自体を1ページ目として
    % 数えるため、本文は2ページ目から採番する
    \setcounter{page}{2}
}

\makeatother

% 見出しの書式（番号様式・字下げ）は kyodai-style.tex で定義

% セクションで改ページしないように設定
\makeatletter
\renewcommand{\sectionmark}[1]{\markboth{#1}{}}
\makeatother

% 目次設定（見出しの番号様式は kyodai-style.tex で定義）
\setcounter{tocdepth}{1}  % 目次の深さをsectionレベル（1）まで

% 目次の体裁: ドットリーダーでページ番号まで導く
\renewcommand{\cftsecfont}{\normalfont}
\renewcommand{\cftsecpagefont}{\normalfont}
\renewcommand{\cftdotsep}{2}
\renewcommand{\cftsecleader}{\normalfont\cftdotfill{\cftdotsep}}
\renewcommand{\cftsecaftersnumb}{\hspace{0.3em}}
\setlength{\cftsecnumwidth}{2.6em}
\setlength{\cftbeforesecskip}{0.6ex plus 0.2ex}


% リスト設定
\setlist[itemize]{leftmargin=*,topsep=0pt,itemsep=3pt}
\setlist[enumerate]{leftmargin=*,topsep=0pt,itemsep=3pt}

% コマンド定義（\makeatletter内で定義する必要がある）
\makeatletter
\newcommand{\protocolversion}[1]{\def\@protocolversion{#1}}
\newcommand{\protocoldate}[1]{\def\@protocoldate{#1}}
\newcommand{\piname}[1]{\def\@piname{#1}}
\newcommand{\piaffiliation}[1]{\def\@piaffiliation{#1}}
\newcommand{\piaddress}[1]{\def\@piaddress{#1}}
\newcommand{\pitel}[1]{\def\@pitel{#1}}
\newcommand{\pifax}[1]{\def\@pifax{#1}}
\newcommand{\piemail}[1]{\def\@piemail{#1}}
\newcommand{\adminname}[1]{\def\@adminname{#1}}
\newcommand{\adminaffiliation}[1]{\def\@adminaffiliation{#1}}
\newcommand{\adminaddress}[1]{\def\@adminaddress{#1}}
\newcommand{\admintel}[1]{\def\@admintel{#1}}
\newcommand{\adminfax}[1]{\def\@adminfax{#1}}
\newcommand{\adminemail}[1]{\def\@adminemail{#1}}
\makeatother

% 改訂履歴表
\newenvironment{revisionhistory}{%
    \section*{研究計画書の改訂記録}
    \addcontentsline{toc}{section}{研究計画書の改訂記録}
    \begin{longtable}{|p{3cm}|p{10cm}|}
    \hline
    \textbf{版数} & \textbf{作成(改訂)年月日} \\ \hline
    \endfirsthead
    \hline
    \textbf{版数} & \textbf{作成(改訂)年月日} \\ \hline
    \endhead
    \hline
    \endfoot
}{%
    \end{longtable}
    \vspace{1cm}
    % 機密情報ボックスを改訂履歴の後に配置
    \begin{center}
    \fbox{\begin{minipage}{0.9\textwidth}
        \textbf{機密情報に関する注意}

        本研究計画書は、機密情報であり、本研究に参加する医療機関、研究責任者、分担研究者、研究協力者、倫理審査委員会等の臨床研究関係者に対して提供されるものです。

        本研究計画書は、研究対象者に対して本研究の内容を説明する場合を除き、研究責任者の文書による同意なしに、いかなる第三者にも開示または本研究の目的以外に利用することはできません。
    \end{minipage}}
    \end{center}
    \clearpage  % 改訂履歴の後に改ページ
}


% 目次の後に改ページを追加
\let\oldtableofcontents\tableofcontents
\renewcommand{\tableofcontents}{%
    \oldtableofcontents
    \clearpage
}

\endinput