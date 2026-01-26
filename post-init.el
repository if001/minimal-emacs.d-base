;;; pacakge -- pre-init.el
;;; commentary:
;;; summary:
;;; code:


(minimal-emacs-load-user-init "myconf.el")

;;; ------------- Native Compilation -----------------
;; Native compilation enhances Emacs performance by converting Elisp code into
;; native machine code, resulting in faster execution and improved
;; responsiveness.
;;
;; Ensure adding the following compile-angel code at the very beginning
;; of your `~/.emacs.d/post-init.el` file, before all other packages.
(use-package compile-angel
  :demand t
  :ensure t
  :custom
  ;; Set `compile-angel-verbose` to nil to suppress output from compile-angel.
  ;; Drawback: The minibuffer will not display compile-angel's actions.
  (compile-angel-verbose t)

  :config
  ;; The following directive prevents compile-angel from compiling your init
  ;; files. If you choose to remove this push to `compile-angel-excluded-files'
  ;; and compile your pre/post-init files, ensure you understand the
  ;; implications and thoroughly test your code. For example, if you're using
  ;; the `use-package' macro, you'll need to explicitly add:
  ;; (eval-when-compile (require 'use-package))
  ;; at the top of your init file.
  (push "/init.el" compile-angel-excluded-files)
  (push "/early-init.el" compile-angel-excluded-files)
  (push "/pre-init.el" compile-angel-excluded-files)
  (push "/post-init.el" compile-angel-excluded-files)
  (push "/pre-early-init.el" compile-angel-excluded-files)
  (push "/post-early-init.el" compile-angel-excluded-files)

  ;; A local mode that compiles .el files whenever the user saves them.
  ;; (add-hook 'emacs-lisp-mode-hook #'compile-angel-on-save-local-mode)

  ;; A global mode that compiles .el files prior to loading them via `load' or
  ;; `require'. Additionally, it compiles all packages that were loaded before
  ;; the mode `compile-angel-on-load-mode' was activated.
  (compile-angel-on-load-mode 1))

;;; ------------- Native Compilation -----------------


;;; ------------- Wayland -----------------
;; ;; ubuntu2004, Wayland/WSLg(pgtk)でコピペするようの設定
;; ;; https://www.emacswiki.org/emacs/CopyAndPaste のwaylandの項目
(defconst my/hostname (system-name))
(cond
 ((string-match-p "winis" my/hostname)
  (setopt select-enable-clipboard 't)
  (setopt select-enable-primary nil)
  (setopt interprogram-cut-function #'gui-select-text)
  (setopt select-active-regions nil)
  ;; credit: yorickvP on Github
  (setq wl-copy-process nil)
  (defun wl-copy (text)
    (setq wl-copy-process (make-process :name "wl-copy"
                                      :buffer nil
                                      :command '("wl-copy" "-f" "-n")
                                      :connection-type 'pipe
                                      :noquery t))
    (process-send-string wl-copy-process text)
    (process-send-eof wl-copy-process))
  (defun wl-paste ()
    (if (and wl-copy-process (process-live-p wl-copy-process))
        nil ; should return nil if we're the current paste owner
      (shell-command-to-string "wl-paste -n | tr -d \r")))
  (setq interprogram-cut-function 'wl-copy)
  (setq interprogram-paste-function 'wl-paste)
  )
 )
;;; ------------- Wayland -----------------


;;; ------------- flame -----------------
(setq initial-frame-alist
      (append (list
	'(width . 180)
        '(height . 60)
        )
	      initial-frame-alist))
(setq default-frame-alist initial-frame-alist)
;;; ------------- flame -----------------



;;; ------------- font -------------------
;; 以下のフォントをインストール
;; https://github.com/yuru7/PlemolJP
;; $ cd .local/share/fonts
;; $ wget https://github.com/yuru7/PlemolJP/releases/download/v3.0.0/PlemolJP_v3.0.0.zip
;; $ unzip PlemolJP_v3.0.0.zip
;; $ fc-cache -fv

;; 英語フォント
;; (defvar my/font-eng "Ricty Diminished")
(defvar my/font-eng "PlemolJP35")

;; 日本語フォント
;;(defvar my/font-jp "Noto Sans CJK JP")
(defvar my/font-jp "PlemolJP35")

(defvar my/font-size 12) ;; Default English font size (pt)
(defvar my/font-jp-scale 1.20) ;; Scale factor applied to Japanese font to match Latin width.
(defvar my/line-spacing 0.2) ;; 行間

;; (if (string-match "issei-All-Series" (system-name))
;;     (progn
;;       (message "linux settings")
;;       (set-face-attribute 'default nil
;; 			  :family "Ricty Diminished"
;; 			  :height 110)
;;       (set-fontset-font nil 'japanese-jisx0208 (font-spec :family "Ricty Diminished" :size 14))
;;       )
;;   )
;;
;; (if (string-match "ac211.local" (system-name))
;;     (progn
;;           (message "ac211.local settings")
;;     (set-face-attribute 'default nil
;; 			:family "Ricty Diminished"
;; 			:height 140)
;;   (set-fontset-font
;;    nil 'japanese-jisx0208
;;    (font-spec :family "Hiragino Kaku Gothic ProN" :size 10))
;;   ;; 英語と日本語の比率を1：2に設定
;;   (add-to-list 'face-font-rescale-alist
;; 	       '(".*Hiragino Kaku Gothic ProN.*" . 1.3))
;;       )
;;   )
;;
;; (if (string-match "DESKTOP-QFI57MO" (system-name))
;;     (progn
;;       (message "wsl settings")
;;       (set-face-attribute 'default nil
;; 			  :family "Ricty Diminished"
;; 			  :height 110)
;;       (set-fontset-font t 'japanese-jisx0208 (font-spec :family my/font-jp :size 14))
;;       (set-fontset-font t 'japanese-jisx0212 (font-spec :family my/font-jp :size 14))
;;       )
;;   )

(defun my--apply-fonts (&optional frame)
  "英語/日本語フォント・サイズ・行間を FRAME（または現在のフレーム）に適用。"
  (interactive)
  (let* ((frm (or frame (selected-frame)))
         (eng my/font-eng)
         (jp  my/font-jp)
         (pt  my/font-size)
         (scale my/font-jp-scale))
    ;; デフォルト（英語）フォント
    (set-face-attribute 'default frm :family eng :height (* 10 pt) :weight 'normal)
    ;; 固定幅系もそろえる（必要なら）
    (set-face-attribute 'fixed-pitch frm :family eng :height (* 10 pt))
    ;; 可変幅は英字を読みやすいものにしたい場合はここを別指定
    (set-face-attribute 'variable-pitch frm :family eng :height (* 10 pt))

    ;; 日本語など CJK の割り当て
    (dolist (script '(kana han cjk-misc bopomofo))
      (set-fontset-font t script (font-spec :family jp) frm))

    ;; 日英の見かけ幅を合わせる倍率（フォント名でマッチさせる）
    ;; ※ family 全体に効かせるため前方一致の正規表現で指定
    (let* ((jp-pattern (concat "\\`" (regexp-quote jp)))
           (alist (copy-sequence face-font-rescale-alist)))
      ;; 既存の同名エントリを除去してから追加
      (setq alist (cl-remove-if (lambda (cell)
                                  (string-match-p jp-pattern (car cell)))
                                alist))
      (push (cons jp-pattern scale) alist)
      (setf (alist-get jp-pattern alist nil nil #'string=) scale)
      (setq face-font-rescale-alist alist))

    ;; 行間
    (with-selected-frame frm
      (setq-default line-spacing my/line-spacing))))

;; 既存フレーム＆今後作成するフレームに適用
(my--apply-fonts)
(add-hook 'after-make-frame-functions #'my--apply-fonts)
(set-face-attribute 'line-number nil
                    :family my/font-eng     ; 例: "Ricty Diminished"
                    :weight 'normal)
;;; ------------- font -------------------




;;; ------------- theme -------------------
(setq start-time (current-time))

;; (use-package ef-themes
;;   :ensure t
;;   :config
;;   (setq ef-themes-mixed-fonts t
;;         ef-themes-variable-pitch-ui t)
;;   (load-theme 'ef-melissa-light t)
;;   ;;(load-theme 'ef-light t)
;;   ;;(load-theme 'ef-elea-dark)
;;   ;;(load-theme 'ef-duo-light)
;;   ;;(load-theme 'ef-dream)
;;   ;;(load-theme 'ef-owl t)
;;   )


;; (setq timu-spacegrey-flavour "light")
;; (use-package timu-spacegrey-theme
;;   :ensure t
;;   :config
;;   (load-theme 'timu-spacegrey t)
;;   )
;; (use-package solarized-theme
;;   :ensure t
;;   :config
;;   (load-theme 'solarized-light t)
;;   )
;;
(use-package autothemer)
(use-package github-dark-dimmed-theme
  :after autothemer
  :straight (github-dark-dimmed-theme :type git :host nil :repo "https://github.com/ladroid/github-emacs-theme.git")
  :ensure t
  :config
  (load-theme 'github-light t)
  ;;(load-theme 'github-dark-dimmed t)
  )

(use-package doom-modeline
  :ensure t
  :hook (after-init . doom-modeline-mode))

(use-package nerd-icons)

(use-package nerd-icons-dired
  :hook (dired-mode . nerd-icons-dired-mode))

(use-package nerd-icons-completion
  :after marginalia
  :config
  (nerd-icons-completion-mode)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

(use-package nerd-icons-corfu
  :straight (nerd-icons-corfu :type git :host nil :repo "https://github.com/LuigiPiucco/nerd-icons-corfu")
  :after corfu nerd-icons
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

;; 画面の余白
(use-package spacious-padding
  :config
  (setq spacious-padding-widths
        '( :internal-border-width 15
           :header-line-width 4
           :mode-line-width 6
           :tab-width 4
           :right-divider-width 30
           :scroll-bar-width 8))

  ;; Read the doc string of `spacious-padding-subtle-mode-line' as it
  ;; is very flexible and provides several examples.
  (setq spacious-padding-subtle-mode-line
        `( :mode-line-active 'default
           :mode-line-inactive vertical-border))

  (spacious-padding-mode +1))
(let ((elapsed (float-time (time-subtract (current-time) start-time))))
  (message "theme: %.3f" elapsed))

;; (use-package breadcrumb
;;   :straight (breadcrumb :type git :host nil :repo "https://github.com/joaotavora/breadcrumb.git")
;;   :config
;;   (breadcrumb-mode +1))
;;; ------------- theme -------------------





;;; ------------- tab --------------------
(setq package-start-time (current-time))
(use-package centaur-tabs
  :ensure t
  :init
  (centaur-tabs-mode t) ;; グローバルにCentaur Tabsを有効にする
  :config
  (defun centaur-tabs-hide-tab (x)
  "Do no to show buffer X in tabs."
  (let ((name (format "%s" x)))
    (or
     ;; Current window is not dedicated window.
     (window-dedicated-p (selected-window))

     ;; Buffer name not match below blacklist.
     ;; (string-prefix-p "*Flycheck" name)
     ;; (string-prefix-p "*Flymake log*" name)
     ;; (string-prefix-p "*Warnings*" name)
     ;; (string-prefix-p "*Messages*" name)
     ;; (string-prefix-p "*lsp" name)
     ;; (string-prefix-p "*pylsp*" name)
     ;; (string-prefix-p "*pylsp::stderr*" name)

     ;; Is not magit buffer.
     (and (string-prefix-p "magit" name)
	  (not (file-name-extension name)))
     )))
  :custom
  ;; (centaur-tabs-style "wave")
  (centaur-tabs-height 32)

  ;; icons
  (centaur-tabs-set-icons t)
  ;; (centaur-tabs-plain-icons t)
  (centaur-tabs-icon-type 'nerd-icons)

  ;; To display an underline over the selected tab:
  ;; (centaur-tabs-set-bar 'over)
  (centaur-tabs-set-bar 'under)
  (x-underline-at-descent-line t)

  (centaur-tabs-set-close-button nil)

  ;; Customize the modified marker
  (centaur-tabs-set-modified-marker t)
  ;; (centaur-tabs-modified-marker "*")
  :bind
  ("M-[" . centaur-tabs-backward)
  ("M-]" . centaur-tabs-forward)
  )
(let ((elapsed (float-time (time-subtract (current-time) start-time))))
  (message "tab: %.3f" elapsed))
;;; ------------- tab --------------------




;;; ------------- dashboard ---------------
(use-package dashboard
  :init
  (setq dashboard-icon-type 'nerd-icons)
  (setq dashboard-startup-banner 'logo)
  (setq dashboard-set-heading-icons t)
  (setq dashboard-display-icons-p t)
  (setq dashboard-set-file-icons t)
  (setq dashboard-center-content t)
  :config
  (dashboard-setup-startup-hook)
  (setq dashboard-items '(
			  (recents   . 5)
			  (projects   . 5)
			  ;; (agenda    . 5)
			  (bookmarks . 5)
			  ;;(error-status . nil)
			  ))
  (setq dashboard-heading-icons '((recents   . "nf-oct-history")
				  (projects  . "nf-oct-rocket")
				  ;; (agenda    . "nf-oct-calendar")
                  (bookmarks . "nf-oct-bookmark")
                  ;; (registers . "nf-oct-database")
				  (error-status . "nf-oct-bug")
				  ))
  (setq dashboard-footer-messages '("「ネットは広大だわ…」 - 草薙素子"
                                    "「そう囁くのよ、私のゴーストが」 - 草薙素子"
                                    "「ゴーストの無い義体に、果たして魂は宿るのか？」- バトー"
                                    ))
  ;;(setq dashboard-startup-banner (if (or (eq window-system 'x) (eq window-system 'ns) (eq window-system 'w32)) "~/.config/emacs/assets/banner.png" "~/.config/emacs/assets/banner.txt"))

  )
;;; ------------- dashboard ---------------



;;; ------------- others ------------------
;; 対応する括弧を光らせる。
(show-paren-mode 1)
(setq blink-matching-paren nil)

;; 長い行を含むファイルの最適化
(use-package so-long
  :init
  (global-so-long-mode +1))

;; かっこの自動挿入
(electric-pair-mode 1)

;;C-nを押し続けてもページが切り替わることなく一行ずつスクロール
(setq scroll-conservatively 35
      scroll-margin 0
      scroll-step 1)
(setq comint-scroll-show-maximum-output t) ;; shell-mode

;; 行番号表示
(global-display-line-numbers-mode 1) ;; グローバル
;; 絶対行番号（デフォルト）
(setq display-line-numbers-type t)

;; camelCase単位で移動する
(use-package subword
  :init
  (global-subword-mode +1))


;; カーソルの移動を視覚的に分かりやすくしてくれます。beaconよりもシンプルな実装になっています。
(use-package pulsar
  :config
  (pulsar-global-mode +1)
  ;; (pulsar-pulse t)
  )

;; フォントキャッシュの圧縮を抑制（多フォント環境の引っかかり軽減）
(setq inhibit-compacting-font-caches t)

;; 高速で不正確なスクロール
(setq fast-but-imprecise-scrolling t)

;; 字句ハイライト遅延（超巨大バッファで効く）
(setq jit-lock-defer-time 0.05)

;; emacsclient コマンドで高速にファイルが開けます。
(use-package server
  :config
  (unless (server-running-p)
    (server-start)))

;; パフォーマンスの向上
(setq process-adaptive-read-buffering t)

;; 閉じ括弧を入力しても点滅させない
(setq blink-matching-paren nil)

;; vcのバックエンドをGitのみに変更
(setq vc-handled-backends '(Git))

;; ファイル検索を2回行わないようにする
(setq auto-mode-case-fold nil)

;; 双方向の並び替えを抑制する
(setq-default bidi-display-reordering 'left-to-right)

;; 長い行の双方向スキャン
(setq bidi-inhibit-bpa t)

;; フォーカスされていないウィンドウのカーソルを削除
(setq-default cursor-in-non-selected-windows nil)
(setq highlight-nonselected-windows nil)

;; ドメインにpingを送信しない
(setq ffap-machine-p-known 'reject)

;; paste時、regionを削除してpasteする
(delete-selection-mode 1)

;; １文が長過ぎる時に自動で折り返し
;; (auto-fill-mode)
(global-visual-line-mode t)
;;; ------------- others ------------------



;;; ------------- recentf -----------------
(setq package-start-time (current-time))
;; Auto-revert in Emacs is a feature that automatically updates the
;; contents of a buffer to reflect changes made to the underlying file
;; on disk.
(use-package autorevert
  :ensure nil
  :commands (auto-revert-mode global-auto-revert-mode)
  :hook
  (after-init . global-auto-revert-mode)
  :custom
  (auto-revert-interval 3)
  (auto-revert-remote-files nil)
  (auto-revert-use-notify t)
  (auto-revert-avoid-polling nil)
  (auto-revert-verbose t))


;; Recentf is an Emacs package that maintains a list of recently
;; accessed files, making it easier to reopen files you have worked on
;; recently.
(use-package recentf
  :ensure nil
  :commands (recentf-mode recentf-cleanup)
  :hook
  (after-init . recentf-mode)

  :custom
  (recentf-auto-cleanup (if (daemonp) 300 'never))
  (recentf-exclude
   (list "\\.tar$" "\\.tbz2$" "\\.tbz$" "\\.tgz$" "\\.bz2$"
         "\\.bz$" "\\.gz$" "\\.gzip$" "\\.xz$" "\\.zip$"
         "\\.7z$" "\\.rar$"
         "COMMIT_EDITMSG\\'"
         "\\.\\(?:gz\\|gif\\|svg\\|png\\|jpe?g\\|bmp\\|xpm\\)$"
         "-autoloads\\.el$" "autoload\\.el$" ".recentf" "^/ssh:"))

  :config
  ;; A cleanup depth of -90 ensures that `recentf-cleanup' runs before
  ;; `recentf-save-list', allowing stale entries to be removed before the list
  ;; is saved by `recentf-save-list', which is automatically added to
  ;; `kill-emacs-hook' by `recentf-mode'.
  (add-hook 'kill-emacs-hook #'recentf-cleanup -90)
  )

;; savehist is an Emacs feature that preserves the minibuffer history between
;; sessions. It saves the history of inputs in the minibuffer, such as commands,
;; search strings, and other prompts, to a file. This allows users to retain
;; their minibuffer history across Emacs restarts.
(use-package savehist
  :ensure nil
  :commands (savehist-mode savehist-save)
  :hook
  (after-init . savehist-mode)
  :custom
  (savehist-autosave-interval 600)
  (savehist-additional-variables
   '(kill-ring                        ; clipboard
     register-alist                   ; macros
     mark-ring global-mark-ring       ; marks
     search-ring regexp-search-ring)))

;; save-place-mode enables Emacs to remember the last location within a file
;; upon reopening. This feature is particularly beneficial for resuming work at
;; the precise point where you previously left off.
(use-package saveplace
  :ensure nil
  :commands (save-place-mode save-place-local-mode)
  :hook
  (after-init . save-place-mode)
  :custom
  (save-place-limit 400))

;; Enable `auto-save-mode' to prevent data loss. Use `recover-file' or
;; `recover-session' to restore unsaved changes.
(setq auto-save-default t)

(setq auto-save-interval 300)
(setq auto-save-timeout 30)
(let ((elapsed (float-time (time-subtract (current-time) start-time))))
  (message "recentf: %.3f" elapsed))
;;; ------------- recentf -----------------






;;; ------------- corfu -----------------
;; Corfu enhances in-buffer completion by displaying a compact popup with
;; current candidates, positioned either below or above the point. Candidates
;; can be selected by navigating up or down.
(use-package corfu
  :ensure t
  :commands (corfu-mode global-corfu-mode)

  :hook ((prog-mode . corfu-mode)
         (shell-mode . corfu-mode)
         (eshell-mode . corfu-mode))

  :custom
  ;; Hide commands in M-x which do not apply to the current mode.
  (read-extended-command-predicate #'command-completion-default-include-p)
  ;; Disable Ispell completion function. As an alternative try `cape-dict'.
  (text-mode-ispell-word-completion nil)
  (tab-always-indent 'complete)
  (corfu-auto t)

  ;; popup-mode
  (corfu-popupinfo-mode t)
  (corfu-popupinfo-delay 0.5)
  (corfu-popupinfo-at-point t)

  ;; corfu-echo
  (corfu-echo-delay 0.05)
  (corfu-auto-delay 0)
  (corfu-auto-prefix 2)
  (corfu-preselect-first nil)   ; 無駄な再描画回数を減らす好み設定

  ;; corfuの設定
  (corfu-on-exact-match nil)
  (tab-always-indent 'complete)
  ;; (corfu-auto-completion-delay 0.1) ; Auto-completion delay
  (corfu-quit-at-boundary t) ; Quit completion at word boundary
  (corfu-separator ?\s) ; Separator for candidates
  (corfu-popupinfo-delay 0.5) ; Delay for popup info
  (corfu-scroll-margin 3) ; Scroll margin
  (corfu-min-width 10) ; Minimum width of completion window
  (corfu-max-height 15) ; Maximum height of completion window

  ;; Enable Corfu
  :config
  (global-corfu-mode))

;; Cape, or Completion At Point Extensions, extends the capabilities of
;; in-buffer completion. It integrates with Corfu or the default completion UI,
;; by providing additional backends through completion-at-point-functions.
(use-package cape
  :ensure t
  :commands (cape-dabbrev cape-file cape-elisp-block)
  :bind ("C-c p" . cape-prefix-map)
  :init
  ;; Add to the global default value of `completion-at-point-functions' which is
  ;; used by `completion-at-point'.
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-elisp-block)
  :config
  (advice-add 'eglot-completion-at-point :around #'cape-wrap-buster)
  (advice-add 'eglot-completion-at-point :around #'cape-wrap-nonexclusive)
  (advice-add 'lsp-completion-at-point :around #'cape-wrap-buster)
  (advice-add 'lsp-completion-at-point :around #'cape-wrap-nonexclusive)
  (advice-add 'lsp-completion-at-point :around #'cape-wrap-noninterruptible)

  ;;(add-hook 'completion-at-point-functions #'tempel-complete) ;;tempel-completeは入れてないのでOFF
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-elisp-block)
  )
;; スニペットのパッケージ
(use-package tempel
  :bind (("M-+" . tempel-complete) ;; Alternative tempel-expand
         ("M-*" . tempel-insert))
  )

(use-package tempel-collection
  :after tempel)
;;; ------------- corfu -----------------




;;; ------------- Vertico、Consult、Embark -----------------
(setq package-start-time (current-time))
;; Vertico provides a vertical completion interface, making it easier to
;; navigate and select from completion candidates (e.g., when `M-x` is pressed).
(use-package vertico
  ;; (Note: It is recommended to also enable the savehist package.)
  :ensure t
  :custom
  (vertico-count 20) ;; 候補リスト20
  ;; (vertico-resize t) ;; ウィンドウを自動でリサイズ（オプション）
  :config
  (vertico-mode))


;; consult-imenu: 関数一覧
(use-package consult
  :init
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)
  (advice-add #'register-preview :override #'consult-register-window)
  :after (vertico) ; Load after vertico
  :bind
  ("C-s" . consult-line)  ;; バッファ内をキーワードで検索
  ("C-x b" . consult-buffer)
  ("C-x 4 b" . consult-buffer-other-window)
  ;; ("C-r" . consult-ripgrep) ;; ripgrep がインストールされていれば
  ;; ("C-g C-g" . consult-grep) ;; デフォルトの grep コマンドに consult を適用
  ("M-y" . consult-yank-pop) ;; kill-ring の履歴から選択
  ("C-c C-r" . consult-register)
  ("C-x C-r" . consult-recent-file)
  :config
  (consult-customize
   consult-recent-file :preview-key nil)
  )

;; Vertico leverages Orderless' flexible matching capabilities, allowing users
;; to input multiple patterns separated by spaces, which Orderless then
;; matches in any order against the candidates.
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

;; Marginalia allows Embark to offer you preconfigured actions in more contexts.
;; In addition to that, Marginalia also enhances Vertico by adding rich
;; annotations to the completion candidates displayed in Vertico's interface.
(use-package marginalia
  :ensure t
  :commands (marginalia-mode marginalia-cycle)
  :hook (after-init . marginalia-mode))

;; Embark integrates with Consult and Vertico to provide context-sensitive
;; actions and quick access to commands based on the current selection, further
;; improving user efficiency and workflow within Emacs. Together, they create a
;; cohesive and powerful environment for managing completions and interactions.
(use-package embark
  ;; Embark is an Emacs package that acts like a context menu, allowing
  ;; users to perform context-sensitive actions on selected items
  ;; directly from the completion interface.
  :ensure t
  ;; :commands (embark-act
  ;;            embark-dwim
  ;;            embark-export
  ;;            embark-collect
  ;;            embark-bindings
  ;;            embark-prefix-help-command)
  :bind
  (("C-." . embark-act)         ;; pick some comfortable binding
  ("M-." . embark-dwim))        ;; good alternative: M-.
  ;; ("C-h B" . embark-bindings) ;; alternative for `describe-bindings'

  :init
  (setq prefix-help-command #'embark-prefix-help-command)

  :config
  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

(use-package embark-consult
  :ensure t
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

;; bufferへの表示をいい感じにしてくれるらしい
(use-package beframe
  :ensure t
  :config
  (defvar consult-buffer-sources)
  (declare-function consult--buffer-state "consult")

  (with-eval-after-load 'consult
    (defface beframe-buffer
      '((t :inherit font-lock-string-face))
      "Face for `consult' framed buffers.")

    (defvar beframe-consult-source
      `( :name     "Frame-specific buffers (current frame)"
         :narrow   ?F
         :category buffer
         :face     beframe-buffer
         :history  beframe-history
         :items    ,#'beframe-buffer-names
         :action   ,#'switch-to-buffer
         :state    ,#'consult--buffer-state))

    (add-to-list 'consult-buffer-sources 'beframe-consult-source))

  (beframe-mode +1)
  )
;; ミニバッファを大きくする
(setq resize-mini-windows t)
(setq mini-window-hscroll t)
(setq mini-window-max-height 0.4)

;; 補完候補の表示数を増やす
(setq completion-cycle-threshold nil)
(setq completion-try-completion nil)
(setq completion-auto-help t)

;; isearch のインクリメンタルサーチをより強力に
(setq search-whitespace-regexp ".*?")

(let ((elapsed (float-time (time-subtract (current-time) start-time))))
  (message "vertico consult: %.3f" elapsed))
;;; ------------- Vertico、Consult、Embark -----------------


;;; ---------------------- ispell --------------------------
;; ;; The flyspell package is a built-in Emacs minor mode that provides
;; ;; on-the-fly spell checking. It highlights misspelled words as you type,
;; ;; offering interactive corrections. In text modes, it checks the entire buffer,
;; ;; while in programming modes, it typically checks only comments and strings. It
;; ;; integrates with external spell checkers like aspell, hunspell, or
;; ;; ispell to provide suggestions and corrections.
;; ;;
;; ;; NOTE: flyspell-mode can become slow when using Aspell, especially with large
;; ;; buffers or aggressive suggestion settings like --sug-mode=ultra. This
;; ;; slowdown occurs because Flyspell checks words dynamically as you type or
;; ;; navigate text, requiring frequent communication between Emacs and the
;; ;; external Aspell process. Each check involves sending words to Aspell and
;; ;; receiving results, which introduces overhead from process invocation and
;; ;; inter-process communication.
;; (use-package ispell
;;   :ensure nil
;;   :commands (ispell ispell-minor-mode)
;;   :custom
;;   ;; Set the ispell program name to aspell
;;   (ispell-program-name "aspell")
;;
;;   ;; Define the "en_US" spell-check dictionary locally, telling Emacs to use
;;   ;; UTF-8 encoding, match words using alphabetic characters, allow apostrophes
;;   ;; inside words, treat non-alphabetic characters as word boundaries, and pass
;;   ;; -d en_US to the underlying spell-check program.
;;   (ispell-local-dictionary-alist
;;    '(("en_US" "[[:alpha:]]" "[^[:alpha:]]" "[']" nil ("-d" "en_US") nil utf-8)))
;;
;;   ;; Configures Aspell's suggestion mode to "ultra", which provides more
;;   ;; aggressive and detailed suggestions for misspelled words. The language
;;   ;; is set to "en_US" for US English, which can be replaced with your desired
;;   ;; language code (e.g., "en_GB" for British English, "de_DE" for German).
;;   (ispell-extra-args '(; "--sug-mode=ultra"
;;                        "--lang=en_US")))
;;
;;
;; ;; The flyspell package is a built-in Emacs minor mode that provides
;; ;; on-the-fly spell checking. It highlights misspelled words as you type,
;; ;; offering interactive corrections.
;; (use-package flyspell
;;   :ensure nil
;;   :commands flyspell-mode
;;   :hook
;;   (
;;    (prog-mode . flyspell-mode)
;;    (yaml-ts-mode . flyspell-mode)
;;    )
;;   :config
;;   ;; Remove strings from Flyspell
;;   (setq flyspell-prog-text-faces (delq 'font-lock-string-face
;;                                        flyspell-prog-text-faces))
;;
;;   ;; Remove doc from Flyspell
;;   (setq flyspell-prog-text-faces (delq 'font-lock-doc-face
;;                                        flyspell-prog-text-faces)))

(use-package jinx
  :ensure t
  :hook (emacs-startup . global-jinx-mode)
  :config
  (add-to-list 'jinx-exclude-regexps '(t ".*[^[:ascii:]].*"))
  (setq jinx-languages '"en_US")
 )
;;; ---------------------- ispell --------------------------




;;; ------------- move/jump -----------------
(use-package back-button
  :init (back-button-mode 1)
  :bind (("C-x <left>"  . back-button-global-backward)
         ("C-x <right>" . back-button-global-forward)))


;; register
(defvar my/register-index ?0)
(defun my/save-current-line-to-register ()
  "Save current line's position to next register automatically."
  (interactive)
  (let ((reg my/register-index))
    (point-to-register reg)
    (message "Saved current line to register %c" reg)
    ;; 次の登録先を更新（?0〜?9をループ）
    (setq my/register-index
          (if (= my/register-index ?9)
              ?0
            (1+ my/register-index)))))
(global-set-key (kbd "C-c .") 'my/save-current-line-to-register)
;;; ------------- move/jump -----------------




;;; ------------- eglot -----------------
;; Set up the Language Server Protocol (LSP) servers using Eglot.
(use-package eglot
  :init
  (setq eglot-send-changes-idle-time 1.0)
  (setq eglot-extend-to-xref t)
  (setq eglot-events-buffer-size 0) ;; Eglotのログ/イベントバッファは基本オフ
  (setq eglot-report-progress nil) ;; Eglotのログ/イベントバッファは基本オフ

  (setq read-process-output-max (* 3 1024 1024)) ;; プロセス読み取りを広げてスループットUP
  :bind ( :map eglot-mode-map
          ("C-c r" . eglot-rename)
          ("C-c o" . eglot-code-action-organize-imports)
          ("C-c a" . eglot-code-actions)
          ("C-c h" . eldoc)
          ("<f6>" . xref-find-definitions)
          ("C-," . eglot-find-implementation)
          )
  :commands (eglot-ensure
             eglot-rename
             eglot-format-buffer
             eglot-code-actions
             )
  :config
  (with-eval-after-load 'flymake
    (setq flymake-no-changes-timeout 0.5
          flymake-start-on-save-buffer t
          flymake-start-on-flymake-mode t
          flymake-start-on-newline nil))
  ;; eglotがflymakeのflymake-diagnostic-functionsを上書きする
  ;; flymake-collectionのdiagnostic-functionsを使うようにする
  ;; M-: flymake-diagnostic-functions
  ;; (add-to-list 'eglot-stay-out-of 'flymake)

  ;; language serverを追加する場合はここに追加していく
  ;; (add-to-list 'eglot-server-programs '(python-ts-mode . ("pylsp" "--verbose"))) ;;python用
  ;; (add-to-list 'eglot-server-programs '(python-ts-mode . ("pyright-langserver" "--stdio" "--log-level" "trace"))) ;;python用
  (add-to-list 'eglot-server-programs '(python-ts-mode . ("pyright-langserver" "--stdio"))) ;;python用
  (add-to-list 'eglot-server-programs
               '(tsx-ts-mode . ("typescript-language-server" "--stdio" "--log-level" "4"))) ;; tsx-ts-mode
  (add-to-list 'eglot-server-programs
               '(js-ts-mode . ("typescript-language-server" "--stdio" "--log-level" "1"))) ;; jsx-ts-mode
  (add-to-list 'eglot-server-programs
               `(elixir-mode . (,(expand-file-name
                                  (concat user-emacs-directory
                                          ".cache/lsp/elixir-ls-v0.28.0/language_server.sh"))))) ;; elixir

  (setq-default eglot-workspace-configuration
                '(
                  ;; pyrightを使う場合、venvのpathを手動で設定する必要がある
                  (:python . (:analysis (:typeCheckingMode "basic"
                                         :diagnosticMode "workspace"
                                         :autoImportCompletions t)
                             :venvPath "."
                             :venv ".venv"))
                  ;; build tagの付いたfileの場合goplsに引数が必要-tags=sample,sample2
                  ;; (:gopls . (:buildFlags ["-tags=!mocktrident"]))
                  )
                )
  )
;; pyrightを使う場合pyproject.jsonに以下を追加する
;; [tool.pyright]
;; venvPath = "."
;; venv = ".venv"
;; consultとeglotを統合するパッケージです。シンボルの検索が行えるようになります。
(use-package consult-eglot
  :after eglot
  :bind (:map eglot-mode-map
              ("C-c s" . consult-eglot-symbols)))


;; eglotの拡張(基本rust用)
(use-package eglot-x
  :straight (eglot-x :type git :host nil :repo "https://github.com/nemethf/eglot-x.git")
  :after eglot
  :config
  (eglot-x-setup))

;; ミニバッファのeldocをposframeで表示してくれます。
(use-package eldoc-box
  :after eglot
  :config
  ;; (set-face-attribute 'eldoc-box-border nil :background "white")
  (set-face-attribute 'eldoc-box-border nil :background "black")
  ;; (add-hook 'eglot-managed-mode-hook #'eldoc-box-hover-mode t)
  (add-hook 'eglot-managed-mode-hook #'eldoc-box-hover-at-point-mode t)
  )

;; eldocの情報を追加します。
(use-package eglot-signature-eldoc-talkative
  :after eglot
  :config
  (advice-add #'eglot-signature-eldoc-function
              :override #'eglot-signature-eldoc-talkative))


;; emacs-lsp-booster ;; M-x eglot-booster
(use-package eglot-booster
	:straight ( eglot-booster :type git :host nil :repo "https://github.com/jdtsmith/eglot-booster")
	:after eglot
	:config
    (eglot-booster-mode)
    (setq eglot-booster-io-only t) ;; eglot-boosterを使うとeldocの日本語が文字化する対策
    )

;; emacsの組み込み関数を利用してシンボルをハイライトしてくれます。
(use-package symbol-overlay
  :hook (prog-mode . symbol-overlay-mode))

;; ssh先でのlspのpathを通す
(with-eval-after-load 'tramp
  (add-to-list 'tramp-remote-path "/home/issei.fujimoto/go/bin")
  (add-to-list 'tramp-remote-path 'tramp-own-remote-path))
(setq tramp-verbose 2) ;; 1 Errors, 2 Warnings, 10 Traces (huge)
;;; ------------- eglot -----------------




;;; ---------code --------------------------------------
;; The built-in outline-minor-mode provides structured code folding in modes
;; such as Emacs Lisp and Python, allowing users to collapse and expand sections
;; based on headings or indentation levels. This feature enhances navigation and
;; improves the management of large files with hierarchical structures.
(use-package outline
  :ensure nil
  :commands outline-minor-mode
  :hook
  ((emacs-lisp-mode . outline-minor-mode)
   ;; Use " ▼" instead of the default ellipsis "..." for folded text to make
   ;; folds more visually distinctive and readable.
   (outline-minor-mode
    .
    (lambda()
      (let* ((display-table (or buffer-display-table (make-display-table)))
             (face-offset (* (face-id 'shadow) (ash 1 22)))
             (value (vconcat (mapcar (lambda (c) (+ face-offset c)) " ▼"))))
        (set-display-table-slot display-table 'selective-display value)
        (setq buffer-display-table display-table))))))

;; The outline-indent Emacs package provides a minor mode that enables code
;; folding based on indentation levels.
;;
;; In addition to code folding, *outline-indent* allows:
;; - Moving indented blocks up and down
;; - Indenting/unindenting to adjust indentation levels
;; - Inserting a new line with the same indentation level as the current line
;; - Move backward/forward to the indentation level of the current line
;; - and other features.
(use-package outline-indent
  :ensure t
  :commands outline-indent-minor-mode

  :custom
  (outline-indent-ellipsis " ▼")

  :init
  ;; The minor mode can also be automatically activated for a certain modes.
  ;;(add-hook 'python-mode-hook #'outline-indent-minor-mode)
  ;;(add-hook 'python-ts-mode-hook #'outline-indent-minor-mode)

  (add-hook 'yaml-mode-hook #'outline-indent-minor-mode)
  (add-hook 'yaml-ts-mode-hook #'outline-indent-minor-mode))

;; The stripspace Emacs package provides stripspace-local-mode, a minor mode
;; that automatically removes trailing whitespace and blank lines at the end of
;; the buffer when saving.
(use-package stripspace
  :ensure t
  :commands stripspace-local-mode

  ;; Enable for prog-mode-hook, text-mode-hook, conf-mode-hook
  :hook ((prog-mode . stripspace-local-mode)
         (text-mode . stripspace-local-mode)
         (conf-mode . stripspace-local-mode))

  :custom
  ;; The `stripspace-only-if-initially-clean' option:
  ;; - nil to always delete trailing whitespace.
  ;; - Non-nil to only delete whitespace when the buffer is clean initially.
  ;; (The initial cleanliness check is performed when `stripspace-local-mode'
  ;; is enabled.)
  (stripspace-only-if-initially-clean nil)

  ;; Enabling `stripspace-restore-column' preserves the cursor's column position
  ;; even after stripping spaces. This is useful in scenarios where you add
  ;; extra spaces and then save the file. Although the spaces are removed in the
  ;; saved file, the cursor remains in the same position, ensuring a consistent
  ;; editing experience without affecting cursor placement.
  (stripspace-restore-column t))
;;; -------------------------------------------------------



;;; ----- window ----------------------------------------
;; (with-eval-after-load 'electric-indent-mode
;;   (define-key electric-indent-mode-map (kbd "C-j") nil)) ;; C-jを上書き
;; (use-package avy
;;   :ensure t
;;   :commands (avy-goto-char
;;              avy-goto-char-2
;;              avy-next)
;;   :bind
;;   ("C-j" . 'avy-goto-char-2)
;;   )


(use-package expand-region
  :config
  (global-set-key (kbd "C-@") 'er/expand-region)
  (global-set-key (kbd "C-M-@") 'er/contract-region) ;; リージョンを狭める
  (transient-mark-mode t) ;; transient-mark-modeが nilでは動作しませんので注意
  )

(use-package ace-window
  :bind ("C-t" . 'ace-window)
  )

(use-package buffer-move
  :config
  (global-set-key (kbd "C-c <up>") #'buf-move-up) ;; markdown-modeで使うbindを上書きしたいのでgloba-set-key
  (global-set-key (kbd "C-c <down>") #'buf-move-down)
  (global-set-key (kbd "C-c <left>") #'buf-move-left)
  (global-set-key (kbd "C-c <right>") #'buf-move-right)
  )

(use-package zoom
  :config
  (zoom-mode 1)
  (setq zoom-size '(0.6 . 0.6))
  (custom-set-variables
   '(zoom-ignored-major-modes '(neotree-mode))
   )
  )
;;; ----- window ----------------------------------------



;;; ----- Emacsヘルプバッファ ---------------------------
;; Helpful is an alternative to the built-in Emacs help that provides much more
;; contextual information.
(use-package helpful
  :ensure t
  :commands (helpful-callable
             helpful-variable
             helpful-key
             helpful-command
             helpful-at-point
             helpful-function)
  :bind
  ([remap describe-command] . helpful-command)
  ([remap describe-function] . helpful-callable)
  ([remap describe-key] . helpful-key)
  ([remap describe-symbol] . helpful-symbol)
  ([remap describe-variable] . helpful-variable)
  :custom
  (helpful-max-buffers 7))
;;; ----- Emacsヘルプバッファ ---------------------------



;;; ----- keybind ---------------------------
;; window移動
;; (global-set-key (kbd "C-t") 'other-window)

; コメントアウト
;; (define-key global-map "\C-c;" 'comment-region)
(define-key global-map (kbd "C-;") 'comment-region)

; コメント解除 (:はkbdつけない)
(define-key global-map "\C-c:" 'uncomment-region)

(setq cua-enable-cua-keys nil)  ; CUAキーバインドを無効化
;; 上側に大きくスクロール
;; (define-key global-map "\C-o" 'cua-scroll-down)
(define-key global-map "\C-o" 'scroll-down)

;; mac のcommandとoptionを入れ替える
(if (string-match "ac171.local" (system-name))
   (setq ns-command-modifier (quote meta))
 (setq ns-alternate-modifier (quote super))
 )
(if (string-match "ac171" (system-name))
   (setq ns-command-modifier (quote meta))
 (setq ns-alternate-modifier (quote super))
 )
(if (string-match "AC164-3.local" (system-name))
       (setq ns-command-modifier (quote meta))
 (setq ns-alternate-modifier (quote super))
 )
(if (string-match "ac211.local" (system-name))
       (setq ns-command-modifier (quote meta))
 (setq ns-alternate-modifier (quote super))
)
(if (string-match "ifmac.local" (system-name))
       (setq ns-command-modifier (quote meta))
 (setq ns-alternate-modifier (quote super))
 )

;;reload
;; use-packageの場合、M-x eval-defunを使う
(global-set-key [f12] 'eval-buffer)

;; undo
(global-unset-key (kbd "C-z"))
(global-set-key (kbd "C-z") 'undo)


;; macのpinchを無効化
(global-set-key (kbd "<pinch>") 'ignore)
(global-set-key (kbd "<C-wheel-up>") 'ignore)
(global-set-key (kbd "<C-wheel-down>") 'ignore)


;; ---------  wslの日英切り替え ----------------
;; (require 'mozc) ;; package-list-packagesで入れる
;; melpaで入れると変換候補が出ないのでapt経由で入れたほうを使う
;; sudo apt install emacs-mozc emacs-mozc-bin
;; https://zenn.dev/kiyoka/articles/emacs-mozc-version-upgrade-issue
(defconst my/hostname (system-name))
(cond
 ((string-match-p "winis" my/hostname)
  (load-file "/usr/share/emacs/site-lisp/emacs-mozc/mozc.el")
  (setq default-input-method "japanese-mozc")
  ;; (setq mozc-candidate-style 'overlay) ;; 表示が壊れる
  (setq mozc-candidate-style 'echo-area)
  (global-set-key (kbd "C-SPC") 'toggle-input-method)
  )
 )
;; ---------  wslの日英切り替え ----------------

;; regionの選択開始
(global-set-key (kbd "C-M-SPC") #'set-mark-command)
;;; ----- keybind ---------------------------



;;; --------- org ---------------------------
(setq package-start-time (current-time))
;; templateに用いることができるelement
;; https://orgmode.org/manual/Template-elements.html
;; %フォーマットの表記
;; https://orgmode.org/manual/Template-expansion.html
(use-package org
  :init
  (setq org-return-follows-link t  ; Returnキーでリンク先を開く
        org-mouse-1-follows-link t ; マウスクリックでリンク先を開く
        )
  ;; TODOキーワード設定
  (setq org-todo-keywords
	'((sequence "TODO(t)" "DOIN(i)" "WAIT(w)" "|" "DONE(d)")))
  (setq org-todo-keyword-faces
	'(
	  ("WAIT"  . (:foreground "CadetBlue3"      :weight bold))
	  ("TODO"  . (:foreground "LightGoldenrod3" :weight bold))
	  ))
  ;; DONEステータス時の見出しの色を変えない
  (setq org-fontify-done-headline nil)
  (setq work-directory "~/prog/org/")
  :config
  (setq listfile (concat work-directory "list.org"))
  (setq chatfile (concat work-directory "chats.org"))
  (setq ideafile (concat work-directory "idea/idea.org"))

  (defun yy-mm-file (base-dir file-prefix)
    "Generate a file name like 'YYYY-MM-PREFIX.org' in BASE-DIR."
    (let* ((now (current-time))
           (year (format-time-string "%Y" now))
           (month (format-time-string "%m" now))
           (full-dir (expand-file-name base-dir)))
      (unless (file-directory-p full-dir) ;; ディレクトリが存在しない場合は作成
	(make-directory full-dir t))
      ;; ファイル名を生成
      (expand-file-name (format "%s-%s-%s.org" year month file-prefix) full-dir)))

  (defun yy-mm-dd-file (base-dir file-prefix)
    "Generate a file name like 'YYYY-MM-DD-PREFIX.org' in BASE-DIR."
    (let* ((now (current-time))
           (year (format-time-string "%Y" now))
           (month (format-time-string "%m" now))
	   (day (format-time-string "%d" now))
           (full-dir (expand-file-name base-dir)))
      (unless (file-directory-p full-dir) ;; ディレクトリが存在しない場合は作成
	(make-directory full-dir t))
      ;; ファイル名を生成
      (expand-file-name (format "%s-%s-%s-%s.org" year month day file-prefix) full-dir)))

  ;; (setq taskfile (yy-mm-file (concat work-directory "tasks/") "task"))
  ;; (setq laterfile (yy-mm-file (concat work-directory "later/") "later"))
  ;; (setq techfile (yy-mm-dd-file (concat work-directory "tech/") "tech"))

  (setq memofile (yy-mm-file (concat work-directory "todo/") "todo"))
  (setq memofile (yy-mm-file (concat work-directory "memo/") "memo"))
  (setq chatfile (yy-mm-dd-file (concat work-directory "chat/") "chat"))
  (setq fefile (yy-mm-file (concat work-directory "fe/") "fe"))
  (setq matsuo-lab-file (yy-mm-dd-file (concat work-directory "matsuo-lab-llm-compe/") "matsuo-lab-llm-compe"))


  (setq org-capture-templates
	'(
	  ;; タスク
	  ("t" "task" entry (file memofile)
	   "** TODO %? :todo: \n:PROPERTIES:\n:CREATED: %U\n:TAG: task \n:END:\n%i\n%a\n"  :empty-lines 1)
	  ("l" "あとで読む" entry (file memofile)
           "** %? :later: \n:PROPERTIES:\n:CREATED: %U\n:TAG: later \n:END:\n%i\n%a\n"  :empty-lines 1)
	  ("a" "Any Idea" entry (file memofile)
           "** %? :any: \n:PROPERTIES:\n:CREATED: %U\n:TAG: any \n:END:\n%i\n%a\n"  :empty-lines 1)
	  ("i" "Tech memo" entry (file memofile)
           "** %? :tech: \n:PROPERTIES:\n:CREATED: %U\n:TAG: tech \n:END:\n%i\n%a\n"  :empty-lines 1)
	  ;; ("m" "Memo" entry (file+headline memofile "Memo")
      ;;  "* %? :memo: \n  :PROPERTIES:\n  :CREATED: %U\n  :TAG: memo\n  :END:\n  %i\n  %a\n" :empty-lines 1)
      ("m" "Memo" entry (file memofile)
       "** %? :memo: \n:PROPERTIES:\n:CREATED: %U\n:TAG: memo \n:END:\n%i\n" :empty-lines 1 :tree-type day)
	  ("e" "emacs" entry (file memofile)
           "** %? :memo: \n:PROPERTIES:\n:CREATED: %U\n:TAG: memo \n:END:\n%i\n%a\n" :empty-lines 1 :tree-type month)
	  ("p" "Pepar" entry (file memofile)
           "** %? :pepar: \n:PROPERTIES:\n:CREATED: %U\n:TAG: pepar \n:END:\n%i\n%a\n" :empty-lines 1 :tree-type month)


	  ;; ("m" "Memo" entry (file+olp+datetree datetreefile)
          ;;  "** %<%m-%d(%a) %H:%M>\n#+filetags: :memo: \n:PROPERTIES:\n:CREATED: %U\n:TAG: :memo: \n:END:\n%?\n%i\n%a\n" :empty-lines 1 :tree-type month)
	  ("s" "matsuo-lab-llm-compe" entry (file matsuo-lab-file)
           "** %? :llm_compe: \n:PROPERTIES:\n:CREATED: %U\n:TAG: llm_compe \n:END:\n%i\n%a\n" :empty-lines 1 :tree-type month)
	  ("c" "chats" entry (file+headline chatfile "Chats")
	   "** %? :chat: \n\n:PROPERTIES:\n:CREATED: %U\n:TAG: chat\n:END:\n%i\n" :empty-lines 1)
	  ("f" "FE memo" entry (file fefile)
           "* %? :fe: \n:PROPERTIES:\n:CREATED: %U\n:TAG: fe \n:END:\n%i\n%a\n"  :empty-lines 1)
	  )
	)

  ;; agendaの設定
  (defun my-list-subdirectories (dir)
    "指定したディレクトリ DIR の直下にあるディレクトリのリストを返します。"
    (let ((files (directory-files dir t nil))) ;; t で絶対パス、nil でソート
      (cl-loop for file in files
               when (and (file-directory-p file)
			 (not (string-equal (file-name-nondirectory file) "."))
			 (not (string-equal (file-name-nondirectory file) "..")))
               collect (concat file "/")
	       )
      ))
  (setq org-agenda-files (my-list-subdirectories work-directory))
  ;;(setq org-agenda-files '("~/prog/org/memo/"))
  ;; (message org-agenda-files)
  (setq org-agenda-custom-commands
	'(
	  ("s" "List entries with memo tag/property" tags "memo")
	  ("p" "Entries with property TAG=memo" tags "+TAG=\"tech\"")
	  )
	)
  )

;; orgの検索用
(defun my/org-date-string (days-offset)
  "Return date string like '2025-07-01' offset by DAYS-OFFSET from today."
  (format-time-string "%Y-%m-%d"
                      (time-add (current-time)
                                (days-to-time days-offset)))
  )

;; プロパティから時刻文字列を取得し、Emacsの内部時刻形式に変換
(defun my/org-parse-created-timestamp ()
  "Parse CREATED property as a time value, or nil if not present or invalid."
  (let ((ts (org-entry-get nil "CREATED")))
    (when ts
      (condition-case nil
          (encode-time (parse-time-string ts))
        (error nil)))))  ;; エラー時は nil を返す

;; 指定した日数前より後かどうかをチェック
(defun my/org-created-after-days-ago-p (days)
  "Return non-nil if the CREATED property is within the last DAYS days."
  (let ((cutoff (time-subtract (current-time) (days-to-time days))))
    (let ((created-time (my/org-parse-created-timestamp)))
      (and created-time
           (time-less-p cutoff created-time)))))

;; 今日作成されたかチェック
(defun my/org-created-today-p ()
  "Return non-nil if CREATED property is today."
  (let* ((created-time (my/org-parse-created-timestamp))
         (now (current-time)))
    (when created-time
      (let ((created-date (decode-time created-time))
            (now-date (decode-time now)))
        (and (= (nth 3 created-date) (nth 3 now-date))   ;; day
             (= (nth 4 created-date) (nth 4 now-date))   ;; month
             (= (nth 5 created-date) (nth 5 now-date))))))) ;; year

(use-package org-ql
  :after org
  :straight (org-ql :type git :host nil :repo "https://github.com/alphapapa/org-ql.git" :tag "v0.8.10")
  :config
  (setq org-ql-views
	'(
	  ("🕓 今日作成したメモ"
           :buffers-files org-agenda-files
	   :query (my/org-created-today-p)
           :title "🕓 今日作成したメモ"
	   :files org-agenda-files
	   )
	  ("🦑 昨日作成したメモ"
           :buffers-files org-agenda-files
	   :query (my/org-created-after-days-ago-p 1)
           :title "🦑 昨日作成したメモ"
	   :files org-agenda-files
	   )
	  ("📅 過去7日間に作成されたエントリ"
	   :buffers-files org-agenda-files
           :title "📅 過去7日間に作成されたエントリ"
	   :query (my/org-created-after-days-ago-p 7)
           :files org-agenda-files
	   )
          ("📝 メモ"
           :buffers-files org-agenda-files
           :query (tags "memo")
           :title "📝 メモ"
	   :narrow nil
	 )
	;; ("今日のタスク"
        ;;  :buffers-files org-agenda-files
        ;;  :query (and (todo)
        ;;              (ts-active :on today)) ; 今日の日付を持つもの
        ;;  :title "今日のタスク一覧"
        ;;  :sort (ts priority todo)
	;;  :narrow nil
	;;  )
        ;; ("今週の予定"
        ;;  :buffers-files org-agenda-files
        ;;  :query (ts-active :from today :to 7)
        ;;  :title "今週の予定"
	;;  :narrow nil
	;;  ) ;; 今日から7日以内
	)
    )
  )

;; アンダースコアを入力しても下付き文字にならないようにする
(setq org-use-sub-superscripts '{}
      org-export-with-sub-superscripts nil)


;; org-indent-mode
;; インデント機能を有効にしています。
(use-package org-indent
  :straight nil
  :ensure nil
  :hook (org-mode . org-indent-mode))

;; org-mode用のtheme
(use-package org-modern
  :straight ( org-modern :type git :host nil :repo "https://github.com/minad/org-modern.git" :tag "1.9")
  :custom
  (org-modern-fold-stars '(("▶" . "▼") ("▷" . "▽") ("▸" . "▾") ("▹" . "▿") ("▸" . "▾")))
  :config
  (setopt
   ;; Edit settings
   org-auto-align-tags nil
   org-tags-column 0
   org-catch-invisible-edits 'show-and-error
   org-special-ctrl-a/e t
   org-insert-heading-respect-content t

   ;; Org styling, hide markup etc.
   org-hide-emphasis-markers t
   org-pretty-entities t

   ;; Agenda styling
   org-agenda-tags-column 0
   org-agenda-block-separator ?─
   org-agenda-time-grid
   '((daily today require-timed)
     (800 1000 1200 1400 1600 1800 2000)
     " ┄┄┄┄┄ " "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄")
   org-agenda-current-time-string
   "◀── now ─────────────────────────────────────────────────")

  ;; Ellipsis styling
  (setopt org-ellipsis "…")
  (set-face-attribute 'org-ellipsis nil :inherit 'default :box nil)

  (global-org-modern-mode))
(let ((elapsed (float-time (time-subtract (current-time) start-time))))
  (message "org: %.3f" elapsed))
;;; --------- org ---------------------------


;;; ----- markdown ----------------------------------------
;; The markdown-mode package provides a major mode for Emacs for syntax
;; highlighting, editing commands, and preview support for Markdown documents.
;; It supports core Markdown syntax as well as extensions like GitHub Flavored
;; Markdown (GFM).
(use-package markdown-mode
  :commands (gfm-mode
             gfm-view-mode
             markdown-mode
             markdown-view-mode)
  :mode (("\\.markdown\\'" . markdown-mode)
         ("\\.md\\'" . markdown-mode)
         ("README\\.md\\'" . gfm-mode))
  :bind
  (:map markdown-mode-map
        ("C-c C-e" . markdown-do)))
;; Automatically generate a table of contents when editing Markdown files
(use-package markdown-toc
  :ensure t
  :commands (markdown-toc-generate-toc
             markdown-toc-generate-or-refresh-toc
             markdown-toc-delete-toc
             markdown-toc--toc-already-present-p)
  :custom
  (markdown-toc-header-toc-title "**Table of Contents**"))
;;; ----- markdown ----------------------------------------


;;; -------- neotree ---------------------------------
(setq package-start-time (current-time))
(use-package neotree
  ;; :after
  ;; projectile
  :commands
  (neotree-show neotree-hide neotree-dir neotree-find)
  :config
  (setq neo-window-fixed-size nil)
  :custom
  (neo-theme 'nerd-icons)
  (neo-window-fixed-size nil) ;; 幅を調節できるようにする
  (neo-show-hidden-files t) ;; デフォルトで隠しファイル表示
  ;; (after-save-hook 'neotree-refresh)
  :bind
  ("M-<up>" . enlarge-window-horizontally) ;;広げる
  ("M-<down>" . shrink-window-horizontally) ;; 狭くする
  ;;("<f8>" . neotree-projectile-toggle)
  ("<f8>" . neotree-project-dir)
  :preface
  (defun neotree-project-dir ()
    "Open NeoTree using the git root."
    (interactive)
    (let ((project-dir (my/project-root))
          (file-name (buffer-file-name)))
      (neotree-toggle)
      (if project-dir
          (if (neo-global--window-exists-p)
              (progn
                (neotree-dir project-dir)
                (neotree-find file-name)))
        (message "Could not find git project root."))))
  )

;; 不要なモードラインを消す
(use-package hide-mode-line
  :hook
  ;; ((neotree-mode imenu-list-minor-mode) . hide-mode-line-mode))
  ((neotree-mode imenu-list-minor-mode) . hide-mode-line-mode))

;; 以下 usage
;; Shortcut (Only in Neotree Buffer)
;;  - [n] next line ， p previous line。
;;  - [SPC] or [RET] or [TAB] Open current item if it is a file. Fold/Unfold current item if it is a directory.
;;  - [g] Refresh
;;  - [A] Maximize/Minimize the NeoTree Window
;;  - [H] Toggle display hidden files
;;  - [C-c C-n] Create a file or create a directory if filename ends with a ‘/’
;;  - [C-c C-d] Delete a file or a directory.
;;  - [C-c C-r] Rename a file or a directory.
;;  - [C-c C-c] Change the root directory.

;; Commands（Global）
;;  - [neotree-dir] show NeoTree window and specify a directory as its root
;;  - [neotree-show] or neotree show NeoTree window using current directory as its root
;;  - [neotree-hide] Hide NeoTree window
;;  - [neotree-toggle] toggle/hide NeoTree window
;;  - [neotree-find] show NeoTree window and use the file of current buffer as its root

;; Command（Only in NeoTree Buffer）
;;  - [neotree-enter] Open File / Unfold Directory
;;  - [neotree-refresh] Refresh
;;  - [neotree-stretch-toggle] Maximize / Minimize
;;  - [neotree-change-root] Switch Root Directory
;;  - [neotree-hidden-file-toggle] Toggle hidden files
;;  - [neotree-rename-node] Rename a Node
;;  - [neotree-delete-node] Delete a Node
;;  - [neotree-create-node] Create a file or a directory (if filename ends with ‘/’)
(let ((elapsed (float-time (time-subtract (current-time) start-time))))
  (message "neotree: %.3f" elapsed))
;;; -------- neotree ---------------------------------



;;; -------- magit ---------------------------------
(setq package-start-time (current-time))
(use-package magit)
;; (global-set-key (kbd "C-x g") 'magit-status)

;; (use-package git-gutter-fringe
;;   :custom-face
;;   (git-gutter:modified . '((t (:background "#f1fa8c"))))
;;   (git-gutter:added    . '((t (:background "#50fa7b"))))
;;   (git-gutter:deleted  . '((t (:background "#ff79c6"))))
;;   :config
;;   (global-git-gutter-mode +1)
;;   (setq git-gutter:modified-sign "~")
;;   (setq git-gutter:added-sign    "+")
;;   (setq git-gutter:deleted-sign  "-")
;;   :bind
;;   ("C-x g" . magit-status)
;;   )

;; コミットされていない箇所をウィンドウの左側に強調表示 (magitのgutterと被るかも)
(use-package diff-hl
  :hook ((magit-pre-refresh . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh)
         (dired-mode . diff-hl-dired-mode))
  :init
  (global-diff-hl-mode +1)
  (global-diff-hl-show-hunk-mouse-mode +1)
  (diff-hl-margin-mode +1))

;; git diffをblameで比較する
(use-package difftastic
  :demand t
  :bind (:map magit-blame-read-only-mode-map
              ("D" . difftastic-magit-show)
              ("S" . difftastic-magit-show))
  :config
  (eval-after-load 'magit-diff
    '(transient-append-suffix 'magit-diff '(-1 -1)
       [("D" "Difftastic diff (dwim)" difftastic-magit-diff)
        ("S" "Difftastic show" difftastic-magit-show)])))


(let ((elapsed (float-time (time-subtract (current-time) start-time))))
  (message "magit: %.3f" elapsed))
;;; -------- magit ---------------------------------


;;; -------- code ---------------------------------
(setq package-start-time (current-time))
;; Tree-sitter in Emacs is an incremental parsing system introduced in Emacs 29
;; that provides precise, high-performance syntax highlighting. It supports a
;; broad set of programming languages, including Bash, C, C++, C#, CMake, CSS,
;; Dockerfile, Go, Java, JavaScript, JSON, Python, Rust, TOML, TypeScript, YAML,
;; Elisp, Lua, Markdown, and many others.
;; treesit-autoは重いのでOFF
;; (use-package treesit-auto
;;   :ensure t
;;   :custom
;;   (treesit-auto-install 'prompt)
;;   :config
;;   (treesit-auto-add-to-auto-mode-alist 'all)
;;   (global-treesit-auto-mode))
;; Treesitの設定
;; treesitのpathを通す
(add-to-list 'treesit-extra-load-path
             (expand-file-name "~/.emacs.d/tree-sitter"))

;; emacsのABIは14
(setq treesit-language-source-alist
      '((json "https://github.com/tree-sitter/tree-sitter-json")
        (yaml "https://github.com/ikatyang/tree-sitter-yaml")
        (rust "https://github.com/tree-sitter/tree-sitter-rust" "v0.23.3")
        (toml "https://github.com/tree-sitter/tree-sitter-toml")
        (make "https://github.com/alemuller/tree-sitter-make")
        (markdown "https://github.com/ikatyang/tree-sitter-markdown")
        (dockerfile "https://github.com/camdencheek/tree-sitter-dockerfile")
        (bash "https://github.com/tree-sitter/tree-sitter-bash" "v0.23.3")
        (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
        (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
        (javascript "https://github.com/tree-sitter/tree-sitter-javascript" "v0.23.1")
        (go "https://github.com/tree-sitter/tree-sitter-go" "v0.23.3")
        (gomod "https://github.com/camdencheek/tree-sitter-go-mod" "v1.1.0")
        (python "https://github.com/tree-sitter/tree-sitter-python" "v0.23.3")
        ))

;; Treesitがインストールされてない場合は自動でインストールする
(dolist (element treesit-language-source-alist)
  (let* ((lang (car element)))
    (if (treesit-language-available-p lang)
        (message "treesit: %s is already installed" lang)
      (message "treesit: %s is not installed" lang)
      (treesit-install-language-grammar lang))))


(use-package treesit-fold
  :straight (treesit-fold :type git :host github :repo "emacs-tree-sitter/treesit-fold")
  :config
  (setq treesit-fold-summary-exceeded-string " ▼")
  :bind
  ("C-h" . treesit-fold-toggle)
  )


(use-package flymake
  :diminish
  :init (setq flymake-no-changes-timeout nil
              flymake-fringe-indicator-position 'right-fringe
              flymake-margin-indicator-position 'right-margin)
  :config
  (add-hook 'eglot-managed-mode-hook (lambda () (flymake-mode 1)))
  (setq flymake-log-level 3)
  )
;; flymake backendの追加
(add-hook 'eglot-managed-mode-hook #'my/eglot-flymake-enable)

;; js/tsではeglot(tsserver)のflymakeが動かないので、flymake backendにeslintを使う
;; flymake-collectionのflymake-collection-eslintではエラーがでるので、
;; flymake-eslint packageの方を使う
;; ただし、flymake-collectionは他にも多言語用の実装があるので、必要があれば使う
;; M-: flymake-diagnostic-functions
;; (use-package flymake-collection
;;   :hook ((after-init . flymake-collection-hook-setup)
;;          ((tsx-ts-mode
;;            js-ts-mode
;;            jtsx-jsx-mode
;;            jtsx-tsx-mode
;;            jtsx-typescript-mode) . (lambda () (add-to-list 'flymake-diagnostic-functions #'flymake-collection-eslint)))
;;          ;;(eglot-managed-mode . (lambda () (add-to-list 'flymake-diagnostic-functions #'eglot-flymake-backend)))
;;          )
;;   )
;; popupはeldocに任せる
;; (use-package flymake-popon
;;   :diminish
;;   :custom-face
;;   (flymake-popon ((t :inherit default :height 0.85)))
;;   ;;(flymake-popon-posframe-border ((t :foreground ,(face-background 'posframe-border nil t))))
;;   :hook (flymake-mode . flymake-popon-mode)
;;   :init (setq flymake-popon-width 80)
;;   :config
;;   (add-hook 'eglot-managed-mode-hook #'flymake-mode)
;;   )
;;; -------- code ---------------------------------


;;; --------- python --------------------------------
;; pip install ruff pyright

;; (add-to-list 'auto-mode-alist '("\\.py\\'" . python-ts-mode))
(setq major-mode-remap-alist
      '((python-mode . python-ts-mode)))
;; (add-hook 'python-mode-hook #'eglot-ensure)
;; (add-hook 'python-ts-mode-hook #'eglot-ensure)

;; eglotのflymakeに任せる
;; (use-package flymake-ruff
;;   :hook (python-ts-mode . flymake-ruff-load))
;;; -----------------------------------------


;;; -------------- yaml --------------------------------
(add-to-list 'auto-mode-alist '("\\.yml\\'" . yaml-ts-mode))
(add-to-list 'auto-mode-alist '("\\.yaml\\'" . yaml-ts-mode))
;;; --------------- yaml --------------------------------

;;; --------- typescript --------------------------------
(add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))

(add-hook 'typescript-ts-hook #'eglot-ensure)
(add-hook 'tsx-ts-hook #'eglot-ensure)
;;; -----------------------------------------

;;; --------- jsx --------------------------------
;; (add-to-list 'auto-mode-alist '("\\.js\\'" . js-ts-mode))
;; (add-to-list 'auto-mode-alist '("\\.jsx\\'" . js-ts-mode))

;; reformatterでglobal-prettier-formatをdefineすることでglobal-prettier-format-bufferが登録される
;; save-hookはreformatterを使わず手動で設定する
(add-hook 'js-ts-mode-hook #'my/enable-prettier-on-save)

;; jsではeglot(tsserver)のflymakeが動かないので、flymake-eslintを使う
;; flymake-collectionのflymake-collection-eslintではエラーがでるので、
(use-package flymake-eslint
  :straight '(flymake-eslint :type git :host github :repo "orzechowskid/flymake-eslint")
  :custom
  ;; プロジェクトローカル eslint を使いたいなら npx が安定
  (flymake-eslint-executable '("npx" "eslint")) ;; or ("npm" "exec" "--" "eslint")
  (flymake-eslint-prefer-json-diagnostics t)
  )

(use-package jtsx
  :ensure t
  :mode (("\\.js\\'" . jtsx-jsx-mode)
         ("\\.jsx\\'" . jtsx-jsx-mode)
         ("\\.tsx\\'" . jtsx-tsx-mode)
         ("\\.ts\\'" . jtsx-typescript-mode))
  :commands jtsx-install-treesit-language
  :hook ((jtsx-jsx-mode . hs-minor-mode)
         (jtsx-tsx-mode . hs-minor-mode)
         (jtsx-typescript-mode . hs-minor-mode))
  ;; :custom
  ;; Optional customizations
  ;; (js-indent-level 2)
  ;; (typescript-ts-mode-indent-offset 2)
  ;; (jtsx-switch-indent-offset 0)
  ;; (jtsx-indent-statement-block-regarding-standalone-parent nil)
  ;; (jtsx-jsx-element-move-allow-step-out t)
  ;; (jtsx-enable-jsx-electric-closing-element t)
  ;; (jtsx-enable-electric-open-newline-between-jsx-element-tags t)
  ;; (jtsx-enable-jsx-element-tags-auto-sync nil)
  ;; (jtsx-enable-all-syntax-highlighting-features t)
  :config
  (defun jtsx-bind-keys-to-mode-map (mode-map)
    "Bind keys to MODE-MAP."
    (define-key mode-map (kbd "C-c C-j") 'jtsx-jump-jsx-element-tag-dwim)
    (define-key mode-map (kbd "C-c j o") 'jtsx-jump-jsx-opening-tag)
    (define-key mode-map (kbd "C-c j c") 'jtsx-jump-jsx-closing-tag)
    (define-key mode-map (kbd "C-c j r") 'jtsx-rename-jsx-element)
    (define-key mode-map (kbd "C-c <down>") 'jtsx-move-jsx-element-tag-forward)
    (define-key mode-map (kbd "C-c <up>") 'jtsx-move-jsx-element-tag-backward)
    (define-key mode-map (kbd "C-c C-<down>") 'jtsx-move-jsx-element-forward)
    (define-key mode-map (kbd "C-c C-<up>") 'jtsx-move-jsx-element-backward)
    (define-key mode-map (kbd "C-c C-S-<down>") 'jtsx-move-jsx-element-step-in-forward)
    (define-key mode-map (kbd "C-c C-S-<up>") 'jtsx-move-jsx-element-step-in-backward)
    (define-key mode-map (kbd "C-c j w") 'jtsx-wrap-in-jsx-element)
    (define-key mode-map (kbd "C-c j u") 'jtsx-unwrap-jsx)
    (define-key mode-map (kbd "C-c j d n") 'jtsx-delete-jsx-node)
    (define-key mode-map (kbd "C-c j d a") 'jtsx-delete-jsx-attribute)
    (define-key mode-map (kbd "C-c j t") 'jtsx-toggle-jsx-attributes-orientation)
    (define-key mode-map (kbd "C-c j h") 'jtsx-rearrange-jsx-attributes-horizontally)
    (define-key mode-map (kbd "C-c j v") 'jtsx-rearrange-jsx-attributes-vertically))

  (defun jtsx-bind-keys-to-jtsx-jsx-mode-map ()
      (jtsx-bind-keys-to-mode-map jtsx-jsx-mode-map))

  (defun jtsx-bind-keys-to-jtsx-tsx-mode-map ()
      (jtsx-bind-keys-to-mode-map jtsx-tsx-mode-map))

  (add-hook 'jtsx-jsx-mode-hook 'jtsx-bind-keys-to-jtsx-jsx-mode-map)
  (add-hook 'jtsx-tsx-mode-hook 'jtsx-bind-keys-to-jtsx-tsx-mode-map))
;;; --------- jsx --------------------------------


;;; --------- golang ------------------------
(add-to-list 'auto-mode-alist '("\\.go\\'" . go-ts-mode))
;;; -----------------------------------------



;;; --------- format ------------------------
(use-package reformatter
  :ensure t
  :config
  (reformatter-define go-format
    :program "goimports")
  (reformatter-define global-prettier-format
    :program "prettier"
    :args `("--stdin-filepath" ,(buffer-file-name))
    :lighter " PrettierFmt")
  (reformatter-define python-format
    :program "ruff"
    :args `("format" "--stdin-filename" ,buffer-file-name))
  (reformatter-define ruff-format
    :program "ruff"
    :args '("format" "-"))
  (reformatter-define json-format
    :program "jq"
    :args '(".")
    :lighter " JSONFmt")

  :hook
  (go-ts-mode . go-format-on-save-mode)
  (typescript-ts-mode . global-prettier-format-on-save-mode)
  (tsx-ts-mode . global-prettier-format-on-save-mode)
  ;;(python-ts-mode . python-format-on-save-mode)
  (python-ts-mode . ruff-format-on-save-mode)
  (json-mode-hook . json-format-on-save-mode)
  (json-ts-mode . json-format-on-save-mode)
  ;; (js-ts-mode . web-format-on-save-mode)
  ;; (js-ts-mode . prettier-format-on-save-mode)
  )
(let ((elapsed (float-time (time-subtract (current-time) start-time))))
  (message "code: %.3f" elapsed))
;;; --------- format ------------------------




;;; --------- llm--- ------------------------
(use-package gptel
  :config
  (require 'gptel-integrations)
  ;;(require 'gptel-org)
  (setq
   gptel-default-mode 'org-mode
   gptel-model 'qwen3:8b
   gptel-backend (gptel-make-ollama "Ollama"
                                    :host "172.22.1.15:11434"
                                    :stream t
                                    :models '(qwen3:0.6b qwen3:4b qwen3:8b))
   )
  (gptel-make-ollama "Ao-Chat"
    :host "127.0.0.1:8181"
    :stream t
    :models '(ao))
   gptel-use-curl t
   gptel-use-tools t
   gptel-stream	t
   gptel-max-tokens	4096
   gptel-temperature 0
   gptel-use-context t
   gptel-confirm-tool-calls 'always
   gptel-include-tool-results t ;;'auto
   gptel-log-level "debug"
   gptel--system-message (concat gptel--system-message " Make sure to use Japanese language.")
  )

;; --- mcp-lsp ---
;; go install github.com/isaacphi/mcp-language-server@latest
;; mcp-language-server --workspace /home/issei/mcp_workspace/lsp --lsp language-server-executable
;; --- firecrawl-mcp ---
;; git clone https://github.com/firecrawl/firecrawl-mcp-server.git
;; npm run build
(defvar GOBINPATH '(concat (getenv "GOPATH") "/bin"))
(use-package mcp
  :after gptel
  :custom
  (mcp-hub-servers
   `(
     ;; ("mcp-go-lsp" . (
     ;;                  :command "mcp-language-server"
     ;;                           :args ("--workspace" "/home/issei/prog/go/src/mcp-language-server" "--lsp" "gopls")
     ;;                           :env (:PATH "/home/issei/.goenv/shims/go:/home/issei/go/1.25.4/bin/" :GOPATH (getenv "GOPATH"))
     ;;                                )
     ;;  )
     ;; ;; ("duckduckgo" . (:command "uvx" :args ("duckduckgo-mcp-server")))
     ;; ;; ("firecrawl-mcp" . (:command "npx" :args ("-y" "firecrawl-mcp", "2>" "~/prog/mcp/firecrawl-mcp-server/mcp_server.log") :env (:CLOUD_SERVICE "false" :FIRECRAWL_API_KEY "test" :FIRECRAWL_API_URL "172.22.1.15:3002" :HTTP_STREAMABLE_SERVER "false")))
     ;; ("firecrawl-mcp" . (
     ;;                     :command "npm"
     ;;                              :args ("--silent" "--prefix" "~/prog/mcp/firecrawl-mcp-server" "run" "start")
     ;;                              :env (:CLOUD_SERVICE "false" :FIRECRAWL_API_KEY "test" :FIRECRAWL_API_URL "http://172.22.1.15:3002" :HTTP_STREAMABLE_SERVER "false"))
     ;;  )
    ;; ("firecrawl-mcp" . (:command "sh" :args ("-lc" "node" "~/prog/mcp/firecrawl-mcp-server/dist/index.js") :env (:CLOUD_SERVICE "false" :FIRECRAWL_API_KEY "test" :FIRECRAWL_API_URL "172.22.1.15:3002" :HTTP_STREAMABLE_SERVER "false")))
     ;; ("fetch" . (:command "uvx" :args ("mcp-server-fetch")))
     ;; ("filesystem" . (:command "npx" :args ("-y" "@modelcontextprotocol/server-filesystem") :roots (getenv "HOME")))
     ;; ("sequential-thinking" . (:command "npx" :args ("-y" "@modelcontextprotocol/server-sequential-thinking")))
     ;; ;;("context7" . (:command "npx" :args ("-y" "@upstash/context7-mcp") :env (:DEFAULT_MINIMUM_TOKENS "6000")))
     ;; ("code-agent" . (:command "/home/issei/prog/mcp/lsp_resarch/.venv/bin/python" :args ("agent.py")))
     ;; ("code-agent" . (:command
     ;;                  "/home/issei/prog/mcp/code-deep-researcher/.venv/bin/python"
     ;;                  :args ("run_as_mcp.py")
     ;;                  :env (:project_root "/home/issei/prog/mcp/chat-llm-v3")
     ;;                  ))
     ;; ("code-agent-sse" . (:url "http://localhost:8000/mcp"))
     ;; ("code-agent" . (:command "/home/issei/prog/mcp/lsp_resarch/.venv/bin/python" :args ("agent.py")))
     )
   )

  :config
  (require 'mcp-hub)
  ;; (setq mcp-log-level "debug")
  :hook (after-init . mcp-hub-start-all-server))
;;; -----------------------------------------

;;; post-init.el ends here
