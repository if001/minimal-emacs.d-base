;;; pacakge -- myconf.el
;;; commentary:
;;; summary:
;;; code:

;;; ------------- marp -----------------
(defun my/marp-start-server ()
    "Start Marp server in current directory."
    (interactive)
    (let ((default-directory (file-name-directory (buffer-file-name))))
      (start-process-shell-command
       "marp-server"
       "*marp-server*"
       (format "marp --allow-local-files --html --theme /Users/ac211/prog/slide/themes/base.scss --server \"%s\"" default-directory))
      (browse-url "http://localhost:8080/"))
    )

;; brew install pngpaste
(defun my/save-screenshot-from-clipboard (filepath)
  "クリップボードの画像を指定されたファイルパスに保存します。
macOSで 'pngpaste' がインストールされている必要があります。
例: M-x my-save-screenshot-from-clipboard RET ~/image/sample.png"
  (interactive "Mファイルパス: ")
  (if (executable-find "pngpaste")
      (progn
        (shell-command (format "pngpaste %s" (shell-quote-argument filepath)))
        (message "画像を %s に保存しました。" filepath))
    (error "pngpaste が見つかりません。Homebrewでインストールしてください。")))

;; macで白いモヤがかかった画像になる場合は以下をinstall
;; brew install coreutils
(defun my/insert-screenshot-markdown ()
  "クリップボードの画像を './image-N.png' として現在のディレクトリに保存し、
カーソル位置にその画像のMarkdownリンクを挿入します。
macOSで 'pngpaste' がインストールされている必要があります。
例: M-x my-insert-screenshot-markdown"
  (interactive)
  (unless (executable-find "pngpaste")
    (error "pngpaste が見つかりません。Homebrewでインストールしてください。"))

  (let* ((base-dir default-directory)
         (file-num 1)
         (file-path nil)
         (relative-path nil))
    ;; 連番のファイル名を生成
    (while (file-exists-p
            (setq file-path
                  (expand-file-name
                   (format "image-%d.png" file-num)
                   base-dir)))
      (setq file-num (1+ file-num)))

    ;; クリップボードの画像を保存
    (shell-command (format "pngpaste %s" (shell-quote-argument file-path)))
    (message "画像を %s に保存しました。" file-path)

    ;; 相対パスを作成
    (setq relative-path (file-relative-name file-path base-dir))

    ;; Markdown形式で挿入
    (insert (format "![](./%s)" relative-path))))
;;; ------------- marp -----------------




;;; ------------- typescript language server path for eglot -----------------
;;; typescript-language-serverの起動時、project_rootのtscを探す(見つからなければglobalを見る)
;; project_root/app/tsconfig.jsonのような構成の場合、project_root/app/node_modulesが参照できない
;; project_root/app以下にあるtscを参照できるような設定

(defcustom my-tsserver-subdirs '("app")
  "Directories under project root where node_modules/typescript may exist.
Each entry is a directory name like \"app\" or \"frontend\"."
  :type '(repeat string)
  :group 'eglot)

(setq my-tsserver-subdirs '("app" "frontend" "web"))

(defun my-tsserver-path ()
  "カレントバッファから見て、適切な tsserver.js のフルパスを探す.
優先順:
  1) <project_root>/<subdir>/node_modules/typescript/lib/tsserver.js
     （subdir は `my-tsserver-subdirs` の順）
  2) <project_root>/node_modules/typescript/lib/tsserver.js"
  (when-let* ((proj (project-current))
              (root (project-root proj)))
    (let* ((candidates
            (append
             ;; 1. subdir/node_modules/... を順番に
             (mapcar (lambda (subdir)
                       (expand-file-name
                        (format "%s/node_modules/typescript/lib/tsserver.js" subdir)
                        root))
                     my-tsserver-subdirs)
             ;; 2. ルート直下の node_modules
             (list (expand-file-name
                    "node_modules/typescript/lib/tsserver.js" root)))))
      (seq-find #'file-exists-p candidates))))

(defun my/eglot-ts-server-path (&optional _interactive)
  "typescript-language-server の起動コマンドを返す.
`my-tsserver-subdirs` で指定されたディレクトリを優先的に探して
対応する tsserver.js を使う。"
  (if-let ((tsserver (my-tsserver-path)))
      (list "typescript-language-server" "--stdio"
            "--tsserver-path" tsserver)
    ;; 見つからなければ従来どおり
    '("typescript-language-server" "--stdio")))
;;; ------------- typescript language server path for eglot -----------------




;;; -------------node_modules/.bin/prettier実行用 -----------------
(defun my/project-root ()
  (when-let ((proj (project-current nil)))
    (project-root proj)))

(defun my/prepend-node-modules-bin-to-path (root)
  "バッファの project root の node_modules/.bin を PATH/exec-path の先頭に挿す。"
  (when-let* (
              (bin  (expand-file-name "node_modules/.bin" root)))
    (when (file-directory-p bin)
      ;; exec-path は Emacs 内でコマンド探索に使う
      (setq-local exec-path (cons bin (delete bin exec-path)))
      ;; PATH は call-process 等の外部実行環境に効く
      (let* ((path (or (getenv "PATH") ""))
             (sep  path-separator)
             (new  (concat bin sep path)))
        (setenv "PATH" new)
        ;; バッファローカルにしたいので process-environment をローカル化
        (setq-local process-environment (copy-sequence process-environment))
        (setenv "PATH" new)))))


(defun my/enable-prettier-on-save ()
  ;; project_rootを追加
  (my/prepend-node-modules-bin-to-path (my/project-root))
  ;; project_root/appも追加
  (my/prepend-node-modules-bin-to-path (concat (my/project-root) "app"))

  (when (executable-find "prettier")
    (add-hook 'before-save-hook #'global-prettier-format-buffer nil t)))
;;; -------------node_modules/.bin/prettier実行用 -----------------


;;; ------------- js用のeslint -----------------
;; flymake-eslintが必要
(defun my/eglot-flymake-enable ()
  (flymake-mode 1)
  (cond

   ;; js/jsx/ts/tsx
   ((derived-mode-p 'js-ts-mode 'typescript-ts-mode 'jtsx-jsx-mode 'jtsx-tsx-mode 'jtsx-typescript-mode)
    ;; project_rootを追加
    (my/prepend-node-modules-bin-to-path (my/project-root))
    ;; project_root/appも追加
    (my/prepend-node-modules-bin-to-path (concat (my/project-root) "app"))
    ;; (setq-local flymake-eslint-project-root (my/project-root))

    (if (executable-find "eslint")
        (flymake-eslint-enable)
      )
    )

   ;; python用
   ;; ((derived-mode-p 'python-ts-mode)
   ;;  )

   ;; その他
   (t
    (unless (memq #'eglot-flymake-backend flymake-diagnostic-functions)
      (add-hook 'flymake-diagnostic-functions #'eglot-flymake-backend nil t))
    )
   )
  (flymake-start t)
  )
;;; ------------- js用のeslint -----------------


;;; ------------- imenu listにnerd iconを使う -----------------

(defconst my/imenu-entry-mapping
  '(("Variable"  :icon "nf-cod-symbol_variable" :label "var")
    ("Variables" :icon "nf-cod-symbol_variable" :label "vars")
    ("Constant"  :icon "nf-cod-symbol_constant" :label "cons")
    ("Types"     :icon "nf-cod-list_unordered"  :label "ty")
    ("Type"      :icon "nf-cod-list_unordered"  :label "ty")
    ("Function"  :icon "nf-cod-symbol_method"   :label "func")
    ("Method"    :icon "nf-cod-symbol_method"   :label "func")
    ("Field"     :icon "nf-cod-symbol_field"    :label "field")
    ("Class"     :icon "nf-cod-symbol_class"    :label "class")
    ("Struct"    :icon "nf-cod-symbol_structure":label "struct")
    ("Packages"  :icon "nf-cod-symbol_property" :label "pkg")
    ("Interface" :icon "nf-cod-symbol_interface":label "i/f")
    )
  "imenu kind → icon / label mapping.")

(defun my/imenu-entry-props (kind)
  "KIND に対応する plist を返す。未定義ならデフォルト。"
  (or (cdr (assoc kind my/imenu-entry-mapping))
      '(:icon "nf-cod-symbol_field" :label "_")))


(defun my/imenu-list--entry-kind (entry)
  (let* ((name (car-safe entry))
         (kind (and (stringp name)
                    (get-text-property 0 'breadcrumb-kind name))))
    (cond
     (kind kind)
     ((stringp my/imenu-list--current-category)
      my/imenu-list--current-category)
     ((consp my/imenu-list--current-category)
      (car my/imenu-list--current-category))
     (t "_"))))

(defvar-local my/imenu-list--current-category nil)

(with-eval-after-load 'imenu-list
  (defun my/imenu-list--insert-entry (entry depth)
    "Insert a line for ENTRY with DEPTH. (override)"
    (if (imenu--subalist-p entry)
        ;; カテゴリ行
        (progn
          (setq my/imenu-list--current-category entry)
          (insert (imenu-list--depth-string depth))
          (insert-button (format "+ %s" (car entry))
                         'face (imenu-list--get-face depth t)
                         'help-echo (format "Toggle: %s" (car entry))
                         'follow-link t
                         'action #'imenu-list--action-toggle-hs)
          (insert "\n"))

      ;; エントリ行
      (let* ((kind  (my/imenu-list--entry-kind entry))
             (props (my/imenu-entry-props kind)))
        (insert (imenu-list--depth-string depth))
        (insert-button
         (format "%s [%s] %s"
                 (nerd-icons-codicon (plist-get props :icon))
                 (plist-get props :label)
                 (car entry))
         'face (imenu-list--get-face depth nil)
         'help-echo (format "Go to: %s (%s)" (car entry) kind)
         'follow-link t
         'action #'imenu-list--action-goto-entry)
        (insert "\n"))))
  )

;; init.el側で上書きする
;; (advice-add 'imenu-list--insert-entry :override #'my/imenu-list--insert-entry))
;;; ------------- imenu listにnerd iconを使う -----------------


;;; ------------- org helper -----------------
(defun my-list-subdirectories (dir)
  "指定したディレクトリ DIR の直下にあるディレクトリのリストを返します。"
  (let ((files (directory-files dir t nil))) ;; t で絶対パス、nil でソート
    (cl-loop for file in files
             when (and (file-directory-p file)
			           (not (string-equal (file-name-nondirectory file) "."))
			           (not (string-equal (file-name-nondirectory file) "..")))
             collect (concat file "/")
	         )
    )
  )


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
;;; ------------- org helper -----------------



;; ------------- neo tree -----------------
;; 1) ハイライト用 face（好きに調整）
(defface my/neotree-current-file-face
  '((t :inherit hl-line))
  "Face for highlighting current buffer's file in NeoTree.")

(defvar-local my/neotree-current-file--ov nil
  "Overlay used to highlight current buffer's file in NeoTree.")

(defun my/neotree--clear-highlight ()
  (when (overlayp my/neotree-current-file--ov)
    (delete-overlay my/neotree-current-file--ov))
  (setq my/neotree-current-file--ov nil))

(defun my/neotree--line-for-path (path)
  "Return 1-based line number in NeoTree buffer for PATH, or nil."
  (when (and (boundp 'neo-buffer--node-list)
             (vectorp neo-buffer--node-list)
             path)
    (let ((i 0)
          (len (length neo-buffer--node-list))
          found)
      (while (and (< i len) (not found))
        (let ((p (aref neo-buffer--node-list i)))
          (when (and p (neo-path--file-equal-p p path))
            (setq found (1+ i))))
        (setq i (1+ i)))
      found)))

(defun my/neotree-highlight-current-buffer-file ()
  "Highlight the node that corresponds to current buffer's file, without moving point."
  (let ((path (buffer-file-name (window-buffer (selected-window)))))
    ;; NeoTreeが無い / ファイルじゃないなら消すだけ
    (neo-global--with-buffer
      (my/neotree--clear-highlight)
      (when (and path (neo-global--window-exists-p))
        (let ((line (my/neotree--line-for-path path)))
          (when line
            (save-excursion
              (goto-char (point-min))
              (forward-line (1- line))
              (setq my/neotree-current-file--ov
                    (make-overlay (line-beginning-position)
                                  (line-end-position)))
              (overlay-put my/neotree-current-file--ov
                           'face 'my/neotree-current-file-face)
              ;; 他の overlay より上に出したい場合
              (overlay-put my/neotree-current-file--ov 'priority 1000))))))))

;; 2) 更新タイミング
;; - NeoTreeの再描画後（neo-buffer--refresh）に必ず再付与
(advice-add 'neo-buffer--refresh :after
            (lambda (&rest _)
              ;; refresh は neotree バッファで動くので、そのままハイライト更新してよい
              (my/neotree-highlight-current-buffer-file)))

;; - バッファ切り替え・ウィンドウ移動で更新したい場合
(add-hook 'buffer-list-update-hook #'my/neotree-highlight-current-buffer-file)
;; ------------- neo tree -----------------


(message "loaded myconf.el")

;;; myconf.el ends here
