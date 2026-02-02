;;; pacakge -- local-conf.el
;;; commentary:
;;; summary:
;;; code:

(with-eval-after-load 'org
  (setq memofile (yy-mm-file (concat work-directory "memo/") "memo"))

  (setq org-capture-templates
	'(
      ("m" "Memo" entry (file memofile)
       "** %? :memo: \n:PROPERTIES:\n:CREATED: %U\n:TAG: memo\n:END:\n%i\n" :empty-lines 1 :tree-type day)
      ("r" "Rad" entry (file memofile)
       "** %? :rad: \n:PROPERTIES:\n:CREATED: %U\n:TAG: rad\n:END:\n%i\n" :empty-lines 1 :tree-type day)
      ("s" "Micro Service" entry (file memofile)
       "** %? :microservice: \n:PROPERTIES:\n:CREATED: %U\n:TAG: microservice\n:END:\n%i\n" :empty-lines 1 :tree-type day)
      ("p" "Posts" entry (file memofile)
       "** %? :post: \n:PROPERTIES:\n:CREATED: %U\n:TAG: post\n:END:\n%i\n" :empty-lines 1 :tree-type day)
      )
    )
  ;; (setq listfile (concat work-directory "list.org"))
  ;; (setq chatfile (concat work-directory "chats.org"))
  ;; (setq ideafile (concat work-directory "idea/idea.org"))
  ;;
  ;; (setq chatfile (yy-mm-dd-file (concat work-directory "chat/") "chat"))
  ;; (setq fefile (yy-mm-file (concat work-directory "fe/") "fe"))
  ;; (setq matsuo-lab-file (yy-mm-dd-file (concat work-directory "matsuo-lab-llm-compe/") "matsuo-lab-llm-compe"))
  ;; (setq org-capture-templates
 ;;    '(
 ;;      ;; タスク
 ;;      ("t" "task" entry (file memofile)
 ;;       "** TODO %? :todo: \n:PROPERTIES:\n:CREATED: %U\n:TAG: task \n:END:\n%i\n%a\n"  :empty-lines 1)
 ;;      ("l" "あとで読む" entry (file memofile)
 ;;           "** %? :later: \n:PROPERTIES:\n:CREATED: %U\n:TAG: later \n:END:\n%i\n%a\n"  :empty-lines 1)
 ;;      ("a" "Any Idea" entry (file memofile)
 ;;           "** %? :any: \n:PROPERTIES:\n:CREATED: %U\n:TAG: any \n:END:\n%i\n%a\n"  :empty-lines 1)
 ;;      ("i" "Tech memo" entry (file memofile)
 ;;           "** %? :tech: \n:PROPERTIES:\n:CREATED: %U\n:TAG: tech \n:END:\n%i\n%a\n"  :empty-lines 1)
 ;;      ;; ("m" "Memo" entry (file+headline memofile "Memo")
 ;;      ;;  "* %? :memo: \n  :PROPERTIES:\n  :CREATED: %U\n  :TAG: memo\n  :END:\n  %i\n  %a\n" :empty-lines 1)
 ;;      ("m" "Memo" entry (file memofile)
 ;;       "** %? :memo: \n:PROPERTIES:\n:CREATED: %U\n:TAG: memo \n:END:\n%i\n" :empty-lines 1 :tree-type day)
 ;;      ("e" "emacs" entry (file memofile)
 ;;           "** %? :memo: \n:PROPERTIES:\n:CREATED: %U\n:TAG: memo \n:END:\n%i\n%a\n" :empty-lines 1 :tree-type month)
 ;;      ("p" "Pepar" entry (file memofile)
 ;;           "** %? :pepar: \n:PROPERTIES:\n:CREATED: %U\n:TAG: pepar \n:END:\n%i\n%a\n" :empty-lines 1 :tree-type month)
 ;;      ;; ("m" "Memo" entry (file+olp+datetree datetreefile)
 ;;          ;;  "** %<%m-%d(%a) %H:%M>\n#+filetags: :memo: \n:PROPERTIES:\n:CREATED: %U\n:TAG: :memo: \n:END:\n%?\n%i\n%a\n" :empty-lines 1 :tree-type month)
 ;;      ("c" "chats" entry (file+headline chatfile "Chats")
 ;;       "** %? :chat: \n\n:PROPERTIES:\n:CREATED: %U\n:TAG: chat\n:END:\n%i\n" :empty-lines 1)
 ;;      ("f" "FE memo" entry (file fefile)
 ;;           "* %? :fe: \n:PROPERTIES:\n:CREATED: %U\n:TAG: fe \n:END:\n%i\n%a\n"  :empty-lines 1)
 ;;      )
 ;;    )

  )
(message "loaded local-conf.el")


;;; local-conf.el ends here
