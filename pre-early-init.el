;; -*- lexical-binding: t; -*-
(setq debug-on-error t)

;; セキュア設定
;; https://www.jamescherti.com/emacs-security-settings/
;; GnuTLS証明書の検証
(setq gnutls-verify-error t)
;; Emacsが外部ツールを使用するようにフォールバックした場合でも、証明書の検証が強制される
(setq tls-checktrust t)
;; Diffie-Hellman鍵交換における素数の最小許容サイズを定義します。この値を3072に設定すると、3072ビット未満の素数を使用したハンドシェイクは拒否される
(setq gnutls-min-prime-bits 3072)
;; マシン名候補をすべて無効とみなし、ネットワークへの問い合わせを行わない
(setq ffap-machine-p-known 'reject)

;; シンボル省略記法 ( read-symbol-shorthands)をローカルで無効にするアドバイス関数
;; シンボル省略記法の[ファイルを開くだけで任意のコードを実行できる脆弱性]に対応
(defun my-suppress-shorthands (orig &rest args)
  "Call ORIG function with ARGS while binding `read-symbol-shorthands' to nil.
ORIG is the original function being advised.
ARGS is the list of arguments passed to the original function.
This acts as advice to prevent arbitrary code execution via symbol shorthands
during unsafe operations like interning symbols on file open."
  (let (read-symbol-shorthands)
    (apply orig args)))

;; A workaround patch (Commit 8466eb44) was applied to the emacs-31 release
;; branch on August 5, 2026. Early pretest versions of Emacs 31 do not
;; include this mitigation.
(when (< emacs-major-version 32)
  (advice-add 'vc-find-backend-function :around #'my-suppress-shorthands)

  (with-eval-after-load 'cc-fonts
    (advice-add 'c-compose-keywords-list :around #'my-suppress-shorthands)))


(require 'ispell)
