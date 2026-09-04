# memo
## version固定
`M-x straight-freeze-versions`

lockfileが以下に作成される
`~/.emacs.d/straight/versions/default.el`

lockfileはpackageとcommit hashの組み合わせ

新しい環境などでは、lockfileをベースにcloneやinstallが行われる

lockファイルのコミットへチェックアウト
`M-x straight-thaw-versions`

変更されたコミットに基づく再ビルド
`M-x straight-rebuild-all`
