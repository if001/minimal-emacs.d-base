;;; pacakge -- myconf.el  -*- lexical-binding: t; -*-
;;; commentary:
;;; summary:
;;; code:

;;; ------------- marp -----------------
(defun my/project-root ()
  (if-let ((proj (project-current nil)))
      (project-root proj)
    ;; プロジェクト外の場合は、現在のファイルのディレクトリをフォールバックとする
    (file-name-directory (buffer-file-name))))

(defun my/marp-start-server ()
  "Start Marp server in project root and open the current buffer file in browser."
  (interactive)
  (let* ((proj-root (my/project-root))
         (current-file (buffer-file-name))
         ;; プロジェクトルートからの相対パスを取得
         (relative-path (file-relative-name current-file proj-root))
         ;; URLエンコード等の簡易対応として、拡張子 .md を .html に変換してブラウザで開く
         ;; (Marp server は md ファイルにアクセスすると HTML に変換して表示するため)
         (target-url (format "http://localhost:3000/%s" relative-path)))

    ;; 1. プロジェクトルートをカレントディレクトリにして Marp サーバーを起動
    (let ((default-directory proj-root))
      (start-process-shell-command
       "PORT=3000 marp-server"
       "*marp-server*"
       "marp --allow-local-files --html --server ."))

    ;; 2. 少しサーバーの起動を待ってからブラウザを開く（即時開くと接続エラーになる対策）
    (run-with-timer 1.0 nil
                    (lambda (url)
                      (xwidget-webkit-browse-url url))
                    target-url)))

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
;; coreutilsでも白いもやがでるようになったので、pngではなjpegで無理やり保存
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
                   (format "image-%d.jpeg" file-num)
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
      ;; tsserver-pathがあるバージョンはこっち
      ;; (list "typescript-language-server" "--stdio"
      ;;       "--tsserver-path" tsserver)
      ;; tsserver-pathが廃止されたのでこっち
      (list "typescript-language-server" "--stdio"
            :initializationOptions
            (list :tsserver
                  (list :path tsserver)))
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


(defun my/enable-formatter-on-save ()
  ;; project_rootを追加
  (my/prepend-node-modules-bin-to-path (my/project-root))
  ;; project_root/appも追加
  (my/prepend-node-modules-bin-to-path (concat (my/project-root) "app"))

  (cond
   ;; prettierはglobal install想定
   ((executable-find "prettier")
    (add-hook 'before-save-hook #'global-prettier-format-buffer nil t))
   ;; biomeはproject local install想定
   ((executable-find "biome")
    (add-hook 'before-save-hook #'global-biome-format-buffer nil t))
   )
  )
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
    (my/prepend-node-modules-bin-to-path (concat (file-name-as-directory (my/project-root)) "app"))

    ;; (setq-local flymake-eslint-project-root (my/project-root))

    (when (executable-find "eslint")
      (flymake-eslint-enable)
      (when (derived-mode-p 'js-ts-mode 'jtsx-jsx-mode)
        (setq-local flymake-diagnostic-functions
                    (delq #'eglot-flymake-backend flymake-diagnostic-functions))
        ;; (setq flymake-eslint-executable-args '("--config" (my/project-root) "eslint-local.config.mjs"))
        )
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



;; treemacsを使うと以下は不要
;; ;; ------------- neo tree -----------------
;; ;; 1) ハイライト用 face（好きに調整）
;; (defface my/neotree-current-file-face
;;   '((t :inherit hl-line))
;;   "Face for highlighting current buffer's file in NeoTree.")
;;
;; (defvar-local my/neotree-current-file--ov nil
;;   "Overlay used to highlight current buffer's file in NeoTree.")
;;
;; (defun my/neotree--clear-highlight ()
;;   (when (overlayp my/neotree-current-file--ov)
;;     (delete-overlay my/neotree-current-file--ov))
;;   (setq my/neotree-current-file--ov nil))
;;
;; (defun my/neotree--line-for-path (path)
;;   "Return 1-based line number in NeoTree buffer for PATH, or nil."
;;   (when (and (boundp 'neo-buffer--node-list)
;;              (vectorp neo-buffer--node-list)
;;              path)
;;     (cl-loop for i from 0 below (length neo-buffer--node-list)
;;              for p = (aref neo-buffer--node-list i)
;;              when (and p (neo-path--file-equal-p p path))
;;              return (1+ i))))
;;
;; (defun my/neotree-highlight-current-buffer-file (&optional path)
;;   "Highlight PATH in NeoTree without moving point.
;;
;; PATHがnilの場合は、選択中のウィンドウが表示している
;; ファイルを対象にする。"
;;   (let ((path (or path
;;                   (buffer-file-name (window-buffer (selected-window))))))
;;     (neo-global--with-buffer
;;       (my/neotree--clear-highlight)
;;       (when-let* ((line (and path (my/neotree--line-for-path path))))
;;         (save-excursion
;;           (goto-char (point-min))
;;           (forward-line (1- line))
;;           (setq my/neotree-current-file--ov
;;                 (make-overlay (line-beginning-position)
;;                               (line-end-position)
;;                               nil nil nil))
;;           (overlay-put my/neotree-current-file--ov
;;                        'face 'my/neotree-current-file-face)
;;           (overlay-put my/neotree-current-file--ov
;;                        'priority 1000))))))
;;
;; ;; ;; 2) 更新タイミング
;; ;; ;; - NeoTreeの再描画後（neo-buffer--refresh）に必ず再付与
;; ;; (advice-add 'neo-buffer--refresh :after
;; ;;             (lambda (&rest _)
;; ;;               ;; refresh は neotree バッファで動くので、そのままハイライト更新してよい
;; ;;               (my/neotree-highlight-current-buffer-file)))
;; ;;
;; ;; ;; - バッファ切り替え・ウィンドウ移動で更新したい場合
;; ;; (add-hook 'buffer-list-update-hook #'my/neotree-highlight-current-buffer-file)
;;
;; (defvar my/neotree-follow--last-state nil
;;   "Last NeoTree root and selected file processed by follow logic.")
;;
;; (defvar my/neotree-follow--running nil
;;   "Non-nil while NeoTree follow processing is running.")
;;
;; (defun my/neotree--current-root ()
;;   "Return the current NeoTree root directory."
;;   (neo-global--with-buffer
;;     neo-buffer--start-node))
;;
;; (defun my/neotree-follow-current-file ()
;;   "Expand NeoTree to the file shown in the selected window.
;;
;; NeoTreeのルート外にあるファイルは無視する。
;; NeoTreeウィンドウへフォーカスは移動しない。"
;;   (unless my/neotree-follow--running
;;        (let* ((window (selected-window))
;;             (path
;;              (and (not (eq window neo-global--window))
;;                   (buffer-file-name (window-buffer window))))
;;             (abs-path
;;              (and path (expand-file-name path)))
;;             (root
;;              (and (neo-global--window-exists-p)
;;                   (my/neotree--current-root)))
;;             ;; rootも含めることで、NeoTreeのroot変更時にも再評価する
;;             (state (list root abs-path)))
;;
;;       ;; post-command-hookは頻繁に呼ばれるため、
;;       ;; ファイルまたはrootが変化したときだけ処理する
;;        (unless (equal state my/neotree-follow--last-state)
;;          (setq my/neotree-follow--last-state state)
;;
;;          (when (and root
;;                     abs-path
;;                     (file-exists-p abs-path)
;;                     ;; root外のファイルでNeoTreeのrootが
;;                     ;; 勝手に変更されないようにする
;;                     (neo-global--file-in-root-p abs-path))
;;            (let ((my/neotree-follow--running t))
;;              ;; neotree-findはNeoTreeウィンドウを選択するので、
;;              ;; 実行後に元のウィンドウへ戻す
;;              (save-selected-window
;;                (neotree-find abs-path))
;;
;;              ;; neotree-findによるツリー再描画後に
;;              ;; オーバーレイを設定する
;;              (my/neotree-highlight-current-buffer-file abs-path)))))))
;; ------------- neo tree -----------------



;;; my-preview-markdown.el --- Preview Markdown with go-grip and xwidget -*- lexical-binding: t; -*-

;; (require 'project)
(require 'subr-x)
(require 'url-util)

(defcustom my/preview-markdown-command "go-grip"
  "Command name or path for go-grip."
  :type 'string)

(defcustom my/preview-markdown-port 6419
  "Base port number for go-grip.
Each active project preview uses this port or a higher unused port."
  :type 'integer)

(defcustom my/preview-markdown-startup-delay 1.0
  "Seconds to wait after starting go-grip."
  :type 'number)

(defcustom my/preview-markdown-log-messages t
  "When non-nil, write preview status messages to `*Messages*'."
  :type 'boolean)

(defcustom my/preview-markdown-mode-line-text " MdPrev"
  "Fallback lighter text for `my/preview-markdown-project-mode'."
  :type 'string)

(defcustom my/preview-markdown-mode-line-icon "nf-md-language_markdown"
  "Nerd icon name for `my/preview-markdown-project-mode'."
  :type 'string)
(defvar my/preview-markdown--project-states (make-hash-table :test 'equal))
(defvar my/preview-markdown--enabled-projects nil)

(defun my/preview-markdown--log (format-string &rest args)
  (when my/preview-markdown-log-messages
    (apply #'message
           (concat "[my/preview-markdown] " format-string)
           args)))

(defun my/preview-markdown--normalize-root (root)
  (file-name-as-directory (file-truename (expand-file-name root))))

(defun my/preview-markdown--markdown-file-p (file)
  (and file
       (string-match-p
        (rx "." (or "md" "markdown" "mdown" "mkd") string-end)
        (downcase file))))

(defun my/preview-markdown--current-markdown-file ()
  (let ((file (buffer-file-name)))
    (unless file
      (user-error "Current buffer is not visiting a file"))
    (unless (my/preview-markdown--markdown-file-p file)
      (user-error "Current file is not a Markdown file: %s" file))
    (expand-file-name file)))

(defun my/preview-markdown--project-root-for-file (file)
  (let* ((dir (file-name-directory (expand-file-name file)))
         (project (project-current nil dir)))
    (unless project
      (user-error "No project found for: %s" file))
    (my/preview-markdown--normalize-root (project-root project))))

(defun my/preview-markdown--root-for-file (file)
  (or (ignore-errors
        (my/preview-markdown--project-root-for-file file))
      (my/preview-markdown--normalize-root
       (file-name-directory (expand-file-name file)))))

(defun my/preview-markdown--relative-file (file root)
  (file-relative-name (expand-file-name file) root))

(defun my/preview-markdown--url (file root port)
  (format "http://localhost:%d/%s"
          port
          (mapconcat #'url-hexify-string
                     (split-string
                      (my/preview-markdown--relative-file file root)
                      "/" t)
                      "/")))

(defun my/preview-markdown--browse (file root port)
  (unless (fboundp 'xwidget-webkit-browse-url)
    (user-error "xwidget-webkit-browse-url is not available in this Emacs"))
  (let ((url (my/preview-markdown--url file root port)))
    (my/preview-markdown--log "browse %s" url)
    (xwidget-webkit-browse-url url t)))

(defun my/preview-markdown--process-live-p (process)
  (and process (process-live-p process)))

(defun my/preview-markdown--state (root)
  (gethash root my/preview-markdown--project-states))

(defun my/preview-markdown--set-state (root state)
  (puthash root state my/preview-markdown--project-states))

(defun my/preview-markdown--clear-state (root)
  (remhash root my/preview-markdown--project-states))

(defun my/preview-markdown--state-process (state)
  (plist-get state :process))

(defun my/preview-markdown--state-port (state)
  (plist-get state :port))

(defun my/preview-markdown--state-file (state)
  (plist-get state :file))

(defun my/preview-markdown--state-live-p (state)
  (my/preview-markdown--process-live-p
   (my/preview-markdown--state-process state)))

(defun my/preview-markdown--used-ports ()
  (let (ports)
    (maphash
     (lambda (_root state)
       (when-let ((port (my/preview-markdown--state-port state)))
         (push port ports)))
     my/preview-markdown--project-states)
    ports))

(defun my/preview-markdown--next-port ()
  (let ((port my/preview-markdown-port)
        (used-ports (my/preview-markdown--used-ports)))
    (while (member port used-ports)
      (setq port (1+ port)))
    port))

(defun my/preview-markdown--process-output-tail (process)
  (when-let ((buffer (and process (process-buffer process))))
    (with-current-buffer buffer
      (string-trim
       (buffer-substring-no-properties
        (max (point-min) (- (point-max) 400))
        (point-max))))))

(defun my/preview-markdown--ensure-process-running (process label)
  (accept-process-output process my/preview-markdown-startup-delay)
  (unless (my/preview-markdown--process-live-p process)
    (let ((details (my/preview-markdown--process-output-tail process)))
      (my/preview-markdown--log
       "%s failed to start%s"
       label
       (if (string-empty-p details)
           ""
         (format ": %s" details)))
      (user-error
       "%s failed to start%s"
       label
       (if (string-empty-p details)
           ""
         (format ": %s" details))))))

(defun my/preview-markdown--stop-root (root)
  (when-let ((state (my/preview-markdown--state root)))
    (when (my/preview-markdown--state-live-p state)
      (my/preview-markdown--log
       "stop root=%s file=%s port=%s"
       root
       (my/preview-markdown--state-file state)
       (my/preview-markdown--state-port state))
      (delete-process (my/preview-markdown--state-process state)))
    (my/preview-markdown--clear-state root)))

(defun my/preview-markdown--stop-all ()
  (let (roots)
    (maphash
     (lambda (root _state)
       (push root roots))
     my/preview-markdown--project-states)
    (dolist (root roots)
      (my/preview-markdown--stop-root root))))

(defun my/preview-markdown--deactivate-buffers ()
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when my/preview-markdown-project-mode
        (setq-local my/preview-markdown-project-mode nil)
        (force-mode-line-update)))))

(defun my/preview-markdown--sentinel (root proc _event)
  (let ((state (my/preview-markdown--state root)))
    (when (and state
               (eq proc (my/preview-markdown--state-process state))
               (memq (process-status proc) '(exit signal failed)))
      (my/preview-markdown--log
       "exited root=%s status=%s details=%s"
       root
       (process-status proc)
       (or (my/preview-markdown--process-output-tail proc) ""))
      (my/preview-markdown--clear-state root))))

(defun my/preview-markdown--ensure-root-process (root file &optional source)
  (unless (executable-find my/preview-markdown-command)
    (user-error "Could not find executable: %s" my/preview-markdown-command))
  (let* ((state (my/preview-markdown--state root))
         (relative (my/preview-markdown--relative-file file root))
         (port (or (my/preview-markdown--state-port state)
                   (my/preview-markdown--next-port)))
         process)
    (if (my/preview-markdown--state-live-p state)
        (progn
          (setq state (plist-put state :file (expand-file-name file)))
          (my/preview-markdown--set-state root state)
          (my/preview-markdown--log
           "reuse source=%s root=%s file=%s port=%d"
           (or source "manual")
           root relative port))
      (let ((default-directory root))
        (setq process
              (make-process
               :name (format "my-preview-markdown-%d" port)
               :buffer (format "*my-preview-markdown:%d*" port)
               :command (list my/preview-markdown-command
                              "-b=false"
                              "-p" (number-to-string port)
                              relative)
               :noquery t
               :sentinel (lambda (proc event)
                           (my/preview-markdown--sentinel root proc event))))
        (setq state (list :process process
                          :port port
                          :file (expand-file-name file)))
        (my/preview-markdown--set-state root state)
        (my/preview-markdown--log
         "start source=%s root=%s file=%s port=%d"
         (or source "manual")
         root relative port)
        (condition-case err
            (my/preview-markdown--ensure-process-running process "markdown preview")
          (error
           (my/preview-markdown--clear-state root)
           (signal (car err) (cdr err))))))
    state))

(defun my/preview-markdown--preview-file (file &optional source)
  (when-let ((buffer (find-buffer-visiting file)))
    (with-current-buffer buffer
      (when (buffer-modified-p)
        (save-buffer))))
  (let* ((root (my/preview-markdown--root-for-file file))
         (state (my/preview-markdown--ensure-root-process root file source))
         (port (my/preview-markdown--state-port state)))
    (my/preview-markdown--browse file root port)))

(defun my/preview-markdown--project-enabled-p (file)
  (when-let ((root (ignore-errors
                     (my/preview-markdown--project-root-for-file file))))
    (member root my/preview-markdown--enabled-projects)))

(defun my/preview-markdown--project-root ()
  (let ((target (or buffer-file-name default-directory)))
    (my/preview-markdown--project-root-for-file target)))

(defun my/preview-markdown--log-project-state ()
  (let (entries)
    (maphash
     (lambda (root state)
       (push (format "%s=>%d"
                     root
                     (my/preview-markdown--state-port state))
             entries))
     my/preview-markdown--project-states)
    (my/preview-markdown--log
     "active projects %s"
     (if entries
         (mapconcat #'identity (sort entries #'string<) ", ")
       "<none>"))))

(defun my/preview-markdown--mark-project-mode-active ()
  (unless my/preview-markdown-project-mode
    (setq-local my/preview-markdown-project-mode t)
    (force-mode-line-update)))

(defun my/preview-markdown--mode-line-lighter ()
  (if (and (display-graphic-p)
           (require 'nerd-icons nil t))
      (concat
       " "
       (nerd-icons-codicon "nf-cod-markdown")
       )
     my/preview-markdown-mode-line-text))

(defun my/preview-markdown--maybe-preview-buffer (buffer source)
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (when (and buffer-file-name
                 (my/preview-markdown--markdown-file-p buffer-file-name)
                 (my/preview-markdown--project-enabled-p buffer-file-name))
        (my/preview-markdown--log
         "%s preview file=%s"
         source
         buffer-file-name)
        (my/preview-markdown--mark-project-mode-active)
        (my/preview-markdown--preview-file buffer-file-name source)))))

(defun my/preview-markdown--maybe-preview-window (object)
  (let ((window (cond
                 ((window-live-p object) object)
                 ((frame-live-p object) (frame-selected-window object)))))
    (when (and (window-live-p window)
               (eq window (selected-window)))
      (my/preview-markdown--maybe-preview-buffer
       (window-buffer window)
       "window-buffer"))))

;;;###autoload
(defun my/preview-markdown ()
  "Preview only the current Markdown file."
  (interactive)
  (let ((file (my/preview-markdown--current-markdown-file)))
    (my/preview-markdown--preview-file file "manual")))

;;;###autoload
(defun my/preview-markdown-stop ()
  "Stop all go-grip processes managed by my-preview-markdown."
  (interactive)
  (setq my/preview-markdown--enabled-projects nil)
  (my/preview-markdown--stop-all)
  (my/preview-markdown--deactivate-buffers)
  (my/preview-markdown--log "disabled all project previews"))

;;;###autoload
(define-minor-mode my/preview-markdown-project-mode
  "Enable auto preview for Markdown files in the current project."
  :lighter (:eval (my/preview-markdown--mode-line-lighter))
  (let ((root (ignore-errors
                (my/preview-markdown--project-root))))
    (unless root
      (setq my/preview-markdown-project-mode nil)
      (user-error "No project found for current buffer"))
    (if my/preview-markdown-project-mode
        (progn
          (add-to-list 'my/preview-markdown--enabled-projects root)
          (my/preview-markdown--log "enable project mode root=%s" root)
          (my/preview-markdown--log-project-state)
          (when (and buffer-file-name
                     (my/preview-markdown--markdown-file-p buffer-file-name))
            (my/preview-markdown--preview-file
             buffer-file-name
             "project-mode")))
      (my/preview-markdown--log "disable project mode root=%s" root)
      (setq my/preview-markdown--enabled-projects
            (delete root my/preview-markdown--enabled-projects))
      (my/preview-markdown--stop-root root)
      (my/preview-markdown--log-project-state))))

(add-hook 'window-buffer-change-functions
          #'my/preview-markdown--maybe-preview-window)

(provide 'my-preview-markdown)

;;; my-preview-markdown.el ends here
;; ------------- go-grip -----------------



;; ------------- lint -----------------
;; relintとbyte-compileでインストール済みpackageを検証する
;; 「」未定義の自由変数への代入」「obsolete な関数・変数の呼び出し」「実行時に壊れる引数の不整合」などを対象する
(require 'bytecomp)
(require 'relint)

(defun my/format-relint-issue (issue)
  "relint の警告オブジェクトを安全に文字列化する。"
  (cond
   ((stringp issue) issue)
   ((fboundp 'relint--format-warning)
    (relint--format-warning issue))
   ((and (fboundp 'relint--warning-message)
         (fboundp 'relint--warning-line))
    (format "Line %d: %s"
            (relint--warning-line issue)
            (relint--warning-message issue)))
   (t (format "%s" issue))))

(defun my/audit-straight-packages (&optional target-package)
  "straight.el 配下のパッケージを対象に、変数スコープ・非推奨コード・正規表現の安全性を検証する。
TARGET-PACKAGE を指定すると単一パッケージのみ検証。"
  (interactive
   (list (when current-prefix-arg
           (completing-read "Package: "
                            (directory-files (straight--repos-dir) nil "^[^.]")))))
  (let* ((repos-dir (straight--repos-dir))
         (out-buf (get-buffer-create "*Straight-Security-Audit*"))
         (target-dirs (if target-package
                          (list (expand-file-name target-package repos-dir))
                        (directory-files repos-dir t "^[^.]"))))
    (with-current-buffer out-buf
      (read-only-mode -1)
      (erase-buffer)
      (insert (format "=== Code & Security Audit Report (%s) ===\n\n" (current-time-string))))

    (dolist (pkg-dir target-dirs)
      (when (file-directory-p pkg-dir)
        (let ((pkg-name (file-name-nondirectory (directory-file-name pkg-dir)))
              (el-files (directory-files pkg-dir t "\\.el$")))

          (with-current-buffer out-buf
            (insert (format "\n========================================\n"))
            (insert (format "[Package: %s]\n" pkg-name))
            (insert (format "========================================\n")))

          (dolist (file el-files)
            ;; autoloads, 生成物, テストファイルは除外
            (unless (string-match-p "\\(-autoloads\\|pkg\\|-test\\|tests?\\)\\.el$" file)
              (let ((file-base (file-name-nondirectory file))
                    (captured-warnings '()))

                (with-temp-buffer
                  (setq-local buffer-offer-save nil)
                  (insert-file-contents file)
                  (emacs-lisp-mode)
                  (setq buffer-file-name file)
                  (setq byte-compile-current-file file)

                  (unwind-protect
                      (progn
                        ;; ----------------------------------------------------
                        ;; 1. バイトコンパイル検証（ファイル出力なし・インメモリ実行）
                        ;; ----------------------------------------------------
                        (let ((byte-compile-warnings t)
                              (byte-compile-log-warning-function
                               (lambda (string _position fill level)
                                 (push (format "  [%s] %s"
                                               (upcase (symbol-name (or level 'warning)))
                                               (string-trim (if fill (fill-region-as-string string) string)))
                                       captured-warnings))))
                          (condition-case err
                              ;; バッファの内容を直接コンパイル（.elc ファイルは一切生成されない）
                              (byte-compile-from-buffer (current-buffer))
                            (error
                             (push (format "  [FATAL] Byte-compile error: %s" (error-message-string err))
                                   captured-warnings))))

                        ;; ----------------------------------------------------
                        ;; 2. relint の実行（正規表現の安全性・構文解析）
                        ;; ----------------------------------------------------
                        (condition-case err
                            (let ((relint-issues (relint-buffer (current-buffer))))
                              (dolist (re relint-issues)
                                (push (format "  [REGEXP] %s" (my/format-relint-issue re)) captured-warnings)))
                          (error
                           (push (format "  [FATAL] Relint error: %s" (error-message-string err))
                                 captured-warnings))))

                    ;; クリーンアップ
                    (set-buffer-modified-p nil)
                    (setq buffer-file-name nil)
                    (setq byte-compile-current-file nil)))

                ;; ----------------------------------------------------
                ;; 結果の出力
                ;; ----------------------------------------------------
                (with-current-buffer out-buf
                  (insert (format "\n-- %s\n" file-base))
                  (if captured-warnings
                      (dolist (w (nreverse captured-warnings))
                        (insert w "\n"))
                    (insert "  OK (No issues detected)\n")))))))))

    (display-buffer out-buf)
    (message "Audit completed. See *Straight-Security-Audit*.")))
;; ------------- lint -----------------


;; ------------- check package -----------------
;; install済みのpackageがGNU ELPA/MELPA/GITHUB直接 なのかを表示する
(require 'tabulated-list)

(defun my-straight-package-report--source (package)
  "Return a human-readable recipe source for PACKAGE."
  (pcase (straight-recipe-source package)
    ('gnu-elpa-mirror "GNU")
    ('gnu-elpa        "GNU")
    ('melpa           "MELPA")
    ('nongnu-elpa     "NonGNU")
    ('emacsmirror-mirror "Emacsmirror")
    (`nil             "explicit")
    (source           (symbol-name source))))

(defun my-straight-package-report--host (recipe)
  "Return host name for RECIPE."
  (let ((host (plist-get recipe :host))
        (repo (plist-get recipe :repo)))
    (cond
     (host
      (symbol-name host))
     ((and (stringp repo)
           (string-match-p
            "\\(?:github\\.com[:/]\\|github:\\)"
            repo))
      "github")
     ((and (stringp repo)
           (string-match-p "gitlab\\.com[:/]" repo))
      "gitlab")
     ((and (stringp repo)
           (string-match-p "savannah\\.gnu\\.org" repo))
      "savannah")
     (t "-"))))

(defun my-straight-package-report--commit (recipe)
  "Return current Git commit for RECIPE."
  (let ((local-repo (plist-get recipe :local-repo)))
    (if (not local-repo)
        "-"
      (let ((dir (straight--repos-dir local-repo)))
        (if (not (file-directory-p dir))
            "-"
          (with-temp-buffer
            (let ((default-directory dir))
              (if (zerop
                   (process-file
                    "git" nil t nil
                    "rev-parse" "--short=12" "HEAD"))
                  (string-trim (buffer-string))
                "-"))))))))

(defun my-straight-package-report--entries ()
  "Return tabulated entries for straight packages."
  (let (entries)
    (maphash
     (lambda (package recipe)
       ;; Ignore pseudo-packages and packages without a repository.
       (when (plist-get recipe :local-repo)
         (let* ((source
                 (my-straight-package-report--source package))
                (host
                 (my-straight-package-report--host recipe))
                (repo
                 (or (plist-get recipe :repo) "-"))
                (commit
                 (my-straight-package-report--commit recipe)))
           (push
            (list package
                  (vector
                   package
                   source
                   host
                   (format "%s" repo)
                   commit))
            entries))))
     straight--recipe-cache)
    (sort entries
          (lambda (a b)
            (string-lessp (car a) (car b))))))

(define-derived-mode my-straight-package-report-mode
  tabulated-list-mode
  "Straight Packages"
  "Display packages managed by straight.el."

  (setq tabulated-list-format
        [("Package"    28 t)
         ("Source"     14 t)
         ("Host"       12 t)
         ("Repository" 42 t)
         ("Commit"     12 t)])

  (setq tabulated-list-padding 2)
  (setq tabulated-list-sort-key '("Package" . nil))

  (tabulated-list-init-header))

;;;###autoload
(defun my/straight-package-report ()
  "Display a report of packages registered with straight.el."
  (interactive)
  (unless (boundp 'straight--recipe-cache)
    (user-error "straight.el is not loaded"))

  (let ((buffer
         (get-buffer-create "*Straight Package Report*")))
    (with-current-buffer buffer
      (my-straight-package-report-mode)
      (setq tabulated-list-entries
            (my-straight-package-report--entries))
      (tabulated-list-print t))
    (pop-to-buffer buffer)))
;; ------------- check package -----------------



(message "loaded myconf.el")

;;; myconf.el ends here
