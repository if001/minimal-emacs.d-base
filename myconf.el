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

(defun my-eglot-typescript-contact (&optional _interactive)
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

(defun my/prepend-node-modules-bin-to-path ()
  "バッファの project root の node_modules/.bin を PATH/exec-path の先頭に挿す。"
  (when-let* ((root (my/project-root))
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
  (my/prepend-node-modules-bin-to-path)
  ;; project-local prettier が見つかる場合だけ有効化したいならチェックも可
  (when (executable-find "prettier")
    (add-hook 'before-save-hook #'global-prettier-format-buffer nil t)))
;;; -------------node_modules/.bin/prettier実行用 -----------------


;;; ------------- js用のeslint -----------------
;; flymake-eslintが必要
(defun my/eglot-flymake-enable ()
  (when (derived-mode-p 'jtsx-jsx-mode)
    (add-hook 'flymake-diagnostic-functions #'eglot-flymake-backend nil t)
    (setq-local flymake-eslint-project-root (my/project-root))
    (flymake-eslint-enable)
    (flymake-start t)
    )

  (add-to-list 'flymake-diagnostic-functions #'eglot-flymake-backend)
  )


(defun my/eglot-flymake-enable ()
  (flymake-mode 1)
  (cond

   ;; js/jsx/ts/tsx
   ((derived-mode-p 'js-ts-mode 'typescript-ts-mode 'jtsx-jsx-mode 'jtsx-tsx-mode 'jtsx-typescript-mode)
    (setq-local flymake-eslint-project-root (my/project-root))
    (flymake-eslint-enable)
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




;;; myconf.el ends here
