;; github theme
(setq github-theme-palette '(
          ;; Basic value
          (bg-main          "#ffffff")
          (bg-dim           "#f2f2f2")
          (fg-main          "#24292f") ;; default #000000"
          (fg-dim           "#595959")
          (fg-alt           "#193668")

          ;; (bg-active        "#c4c4c4")
          ;; (bg-inactive      "#e0e0e0")
          ;; (border           "#9f9f9f")

          ;; Uncommon accent foregrounds
          ;; (orange           "#bc4c00")
          (orange           "#D67200") ;; github Lime 5
          (yellow-light     "#fff8c5")  ;; 黄色

          ;; Special purpose
          (bg-region         yellow-light)
          (bg-tab-current    bg-main)
          ;; (bg-tab-bar        bg-alt)
          (bg-tab-bar        bg-active)
          (bg-tab-other      bg-active)

          ;; Code mappings
          (comment           fg-dim)
          (operator          blue-faint)
          (keyword           orange) ;; オレンジ
          ;; (builtin           cyan-intense)
          ;; (builtin           fg-main)
          ;; (builtin           orange)
          (variable          fg-main)
          (type              fg-main)
          (property          blue-warmer)
          (string            fg-alt)
          (fnname            blue-warmer)

          ;; General mappings
          (cursor            fg-dim)
          ))

;; Nord theme
(setq nord-theme-palette
      '(
        ;; Nord palette names
        (nord0  "#2E3440") ;; Polar Night
        (nord1  "#3B4252")
        (nord2  "#434C5E")
        (nord3  "#4C566A")

        (nord4  "#D8DEE9") ;; Snow Storm
        (nord5  "#E5E9F0")
        (nord6  "#ECEFF4")

        (nord7  "#8FBCBB") ;; Frost
        (nord8  "#88C0D0")
        (nord9  "#81A1C1")
        (nord10 "#5E81AC")

        (nord11 "#BF616A") ;; Aurora
        (nord12 "#D08770")
        (nord13 "#EBCB8B")
        (nord14 "#A3BE8C")
        (nord15 "#B48EAD")
        (white  "#FFFFFF")

        ;; Basic values
        (bg-main      white)
        (bg-dim       nord5)
        (bg-alt       nord4)

        (fg-main      nord0)
        (fg-dim       nord3)
        (fg-alt       nord1)

        ;; UI
        (bg-active    nord4)
        (bg-inactive  nord5)
        (border       nord4)

        ;; Accents
        (red          nord11)
        (red-warmer   nord11)

        (orange       nord12)
        (yellow       nord13)
        (green        nord14)
        (magenta      nord15)

        (cyan         nord8)
        (cyan-cooler  nord7)

        (blue         nord10)
        (blue-warmer  nord10)
        (blue-cooler  nord9)
        (blue-faint   nord9)

        ;; Special purpose
        ;; GitHub風の黄色選択ではなく、Nord lightらしく淡い青灰色にする
        (bg-region      nord4)

        (bg-tab-current bg-main)
        (bg-tab-bar     bg-active)
        (bg-tab-other   bg-active)

        ;; Code mappings
        (comment   fg-dim)

        ;; Nordでは keyword に Aurora 系を使うと見やすい
        (keyword   orange)

        ;; operator は強すぎない Frost
        (operator  blue-faint)

        ;; 変数・型は本文と近くして落ち着かせる
        (variable  fg-main)
        (type      fg-main)

        ;; property / function は Frost の濃い青
        (property  blue-warmer)
        (fnname    blue-warmer)

        ;; string は Polar Night 側に寄せてもよいが、
        ;; Nordらしさを出すなら green も候補
        (string    fg-alt)

        ;; Cursor
        (cursor    nord3)))

;; Nano theme
(setq nano-theme-palette
      '(
        ;; Nano / Material base colors
        (nano-foreground "#37474F") ;; Blue Grey / L800
        (nano-background "#FFFFFF") ;; White
        (nano-highlight  "#FAFAFA") ;; Very Light Grey
        (nano-critical   "#FF6F00") ;; Amber / L900
        (nano-salient    "#673AB7") ;; Deep Purple / L500
        (nano-strong     "#000000") ;; Black
        (nano-popout     "#FFAB91") ;; Deep Orange / L200
        (nano-subtle     "#ECEFF1") ;; Blue Grey / L50
        (nano-faded      "#B0BEC5") ;; Blue Grey / L200

        ;; Additional Material-ish colors
        ;; nano-faded は comment 用には少し薄いので、中間の Blue Grey を追加
        (blue-grey-500   "#607D8B")
        (blue-grey-600   "#546E7A")
        (blue-grey-700   "#455A64")
        (blue-grey-900   "#263238")

        (purple          nano-salient)
        (purple-faint    "#D1C4E9") ;; Deep Purple / L100

        (orange          nano-critical)
        (orange-faint    nano-popout)

        (red             "#D32F2F") ;; Red / L700
        (green           "#388E3C") ;; Green / L700
        (yellow          "#F9A825") ;; Yellow / L800
        (cyan            "#00838F") ;; Cyan / L800
        (blue            "#1976D2") ;; Blue / L700

        ;; Basic values
        (bg-main         nano-background)
        (bg-dim          nano-highlight)
        (bg-alt          nano-subtle)

        (fg-main         nano-foreground)
        (fg-dim          blue-grey-600)
        (fg-alt          blue-grey-900)

        ;; UI
        (bg-active       nano-subtle)
        (bg-inactive     nano-highlight)
        (border          nano-faded)

        ;; Special purpose
        ;; nano-popout は目立つので region には薄紫の方が自然
        (bg-region       purple-faint)

        (bg-tab-current  bg-main)
        (bg-tab-bar      bg-active)
        (bg-tab-other    bg-active)

        ;; Code mappings
        (comment         fg-dim)

        ;; nano の salient = 主アクセントなので keyword に割り当て
        (keyword         purple)

        ;; critical は警告色だが、syntax では builtin / constant に使いやすい
        (builtin         orange)
        (constant        orange)

        ;; operator は本文寄りにして強くしすぎない
        (operator        blue-grey-700)

        ;; 変数・型は落ち着かせる
        (variable        fg-main)
        (type            blue-grey-700)

        ;; function / property は Material の blue
        (fnname          blue)
        (property        cyan)

        ;; string は Material light では green 系が見やすい
        (string          green)

        ;; Cursor
        (cursor          nano-strong)))


(setq nano-theme2-palette
      '(
        ;; Nano base
        (nano-foreground "#37474F")
        (nano-background "#FFFFFF")
        (nano-highlight  "#FAFAFA")
        (nano-critical   "#FF6F00")
        (nano-salient    "#673AB7")
        (nano-strong     "#000000")
        (nano-popout     "#FFAB91")
        (nano-subtle     "#ECEFF1")
        (nano-faded      "#B0BEC5")

        ;; Basic values
        (bg-main         nano-background)
        (bg-dim          nano-highlight)
        (bg-alt          nano-subtle)

        (fg-main         nano-foreground)
        (fg-dim          "#607D8B")
        (fg-alt          nano-strong)

        ;; UI
        (bg-active       nano-subtle)
        (bg-inactive     nano-highlight)
        (border          nano-faded)

        ;; Accent aliases
        (purple          nano-salient)
        (orange          nano-critical)
        (orange-faint    nano-popout)
        (blue            "#1976D2")
        (green           "#388E3C")

        ;; Special purpose
        (bg-region       nano-subtle)

        (bg-tab-current  bg-main)
        (bg-tab-bar      bg-active)
        (bg-tab-other    bg-active)

        ;; Code mappings
        (comment         fg-dim)
        (keyword         purple)
        (builtin         orange)
        (constant        orange)
        (operator        fg-dim)
        (variable        fg-main)
        (type            fg-main)
        (property        blue)
        (fnname          blue)
        (string          green)

        ;; Cursor
        (cursor          nano-strong)))

;;; mythemes.el --- -*- lexical-binding: t; -*-

(require 'subr-x)
(require 'cl-lib)

;; nano-emacsのnano-modeline.elを使う場合に、モードラインの右に, branchやlsp、flykmakeの状態を表示するようにする
(with-eval-after-load 'nano
  ;; reload しても元関数を上書き保存しないようにする
  (unless (fboundp 'my/nano-modeline--original-default-mode)
    (defalias 'my/nano-modeline--original-default-mode
      (symbol-function 'nano-modeline-default-mode)))

  (defcustom my/nano-modeline-right-padding 0
    "Number of spaces inserted at the right edge of nano-modeline."
    :type 'integer
    :group 'nano-modeline)

  (defun my/nano-modeline--right-padding ()
    (make-string my/nano-modeline-right-padding ?\s))

  (defun my/nano-modeline--join (&rest parts)
    (string-join (delq nil parts) "/"))

  (defun my/nano-modeline--lsp-on-p ()
    "Return non-nil when lsp-mode or eglot is active."
    (or (bound-and-true-p lsp-mode)
        (and (fboundp 'eglot-managed-p)
             (ignore-errors (eglot-managed-p)))))

  (defun my/nano-modeline--flymake-type-kind (type)
    "Flymake diagnostic TYPE を :error / :warning / :note に正規化する。"
    (let ((category (get type 'flymake-category)))
      (cond
       ((or (eq type :error)
            (eq type 'flymake-error)
            (eq category 'flymake-error))
        :error)

       ((or (eq type :warning)
            (eq type 'flymake-warning)
            (eq category 'flymake-warning))
        :warning)

       ((or (eq type :note)
            (eq type 'flymake-note)
            (eq category 'flymake-note))
        :note)

       (t
        type))))

  (defun my/nano-modeline--flymake-counts ()
    "Flymake の error / warning 数を (ERRORS . WARNINGS) で返す。"
    (when (and (bound-and-true-p flymake-mode)
             (fboundp 'flymake-diagnostics))
      (let ((errors 0)
            (warnings 0))
        ;; 引数なしの flymake-diagnostics は current buffer 全体を見る
        (dolist (diag (flymake-diagnostics))
          (pcase (my/nano-modeline--flymake-type-kind
                  (flymake-diagnostic-type diag))
            (:error
             (cl-incf errors))
            (:warning
             (cl-incf warnings))))
        (cons errors warnings))))

  (defun my/nano-modeline--flymake-status ()
    "Return flymake error / warning status string."
    (when-let* ((counts (my/nano-modeline--flymake-counts)))
      (let ((errors (car counts))
            (warnings (cdr counts)))
        (my/nano-modeline--join
         (concat
          (nerd-icons-faicon "nf-fa-times_circle")
          " "
          (propertize (number-to-string errors)
                      'face 'nano-face-header-critical))
         (concat
          (nerd-icons-faicon "nf-fa-warning")
          " "
          (propertize (number-to-string warnings)
                      'face 'nano-face-header-popout))))))

  (defun my/nano-modeline--right ()
    "Return right side string for prog-mode nano-modeline."
    ;; nano-modeline.el 側の nano-mode-name / vc-branch を利用する
    (let* ((mode-name (nano-mode-name))
           (branch (vc-branch))
           (branch-name (when branch
                          (string-remove-prefix "#" branch))))
      (concat
       (my/nano-modeline--join
        ;; major mode
        (propertize mode-name
                    'face 'nano-face-header-default)

        ;; Git branch
        (when branch-name
          (concat
           (nerd-icons-faicon "nf-fa-code_branch")
           (propertize branch-name
                       'face 'nano-face-header-default)))

        ;; LSP / Eglot
        (when (my/nano-modeline--lsp-on-p)
          (concat
           (nerd-icons-faicon "nf-fa-rocket")
           )
          )

        ;; Flymake
        (my/nano-modeline--flymake-status))

       ;; right edge padding
       (my/nano-modeline--right-padding))))

  (defun my/nano-modeline-prog-mode ()
    "My extended nano-modeline for prog-mode."
    (let ((buffer-name (format-mode-line "%b"))
          ;;(position (format-mode-line "%l:%c"))
          )
      (nano-modeline-compose
       (nano-modeline-status)
       buffer-name
       ""
       (my/nano-modeline--right))))

  ;; nano-modeline 側の default mode を override。
  ;; prog-mode のときだけ拡張版を使い、それ以外は元の実装に戻す。
  (defun nano-modeline-default-mode ()
    (if (nano-modeline-prog-mode-p)
        (my/nano-modeline-prog-mode)
      (my/nano-modeline--original-default-mode)))

  ;; flymake / lsp / eglot の状態変化で再描画
  (dolist (hook '(flymake-mode-hook
                  lsp-mode-hook
                  eglot-managed-mode-hook))
    (add-hook hook #'force-mode-line-update)))

(provide 'my-nano-modeline)

;;; mytyemes.el ends here
