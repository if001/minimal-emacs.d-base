;;; package --- pre-init.el  -*- lexical-binding: t; -*-
;;; commentary:
;;; summary:
;;; code:



;; Straight bootstrap
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; オプションなしで自動的にuse-packageをstraight.elにフォールバックする
(setq straight-use-package-by-default t)

;; lockファイルからバージョンを読み込み、自動的にそのコミットへ同期する
(setq straight-check-for-modifications nil) ; 起動速度向上のため適宜
(setq straight-vc-git-auto-fast-forward nil) ; lockファイルの指定外の自動更新を防ぐ

;; 起動時にlockファイル (straight/versions/default.el) に基づいてチェックアウトする
(straight-thaw-versions)

;;; pre-init.el ends here
