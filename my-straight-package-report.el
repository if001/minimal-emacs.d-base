;;; my-straight-package-report.el --- Report straight.el packages -*- lexical-binding: t; -*-

;; install済みの package が
;; - GNU ELPA / MELPA / GitHub direct のどこから来たか
;; - lockfile に含まれているか
;; - dependency graph 上でどの package から入ったか
;; - lockfile にあるが現在の dependency graph から説明できないか
;; を表示する。

(require 'cl-lib)
(require 'subr-x)
(require 'tabulated-list)


;;; Source / repository information

(defun my-straight-package-report--source (package)
  "Return a human-readable recipe source for PACKAGE."
  (pcase (straight-recipe-source package)
    ('gnu-elpa-mirror    "GNU")
    ('gnu-elpa           "GNU")
    ('melpa              "MELPA")
    ('nongnu-elpa        "NonGNU")
    ('emacsmirror-mirror "Emacsmirror")
    (`nil                "explicit")
    (source              (symbol-name source))))

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


;;; Lockfile

(defun my-straight-package-report--base-dir ()
  "Return the directory containing straight/."
  (or (and (boundp 'straight-base-dir)
           straight-base-dir)
      user-emacs-directory))

(defun my-straight-package-report--versions-dir ()
  "Return straight.el versions directory."
  (expand-file-name
   "straight/versions/"
   (my-straight-package-report--base-dir)))

(defun my-straight-package-report--read-lockfile (file)
  "Read repository entries from straight lockfile FILE.

Return an alist of the form:

  ((LOCAL-REPO . COMMIT) ...)

Non-repository entries such as the lockfile format version are ignored."
  (when (file-readable-p file)
    (with-temp-buffer
      (insert-file-contents file)
      (goto-char (point-min))
      (let ((data (read (current-buffer)))
            result)
        (dolist (entry data)
          (when (and (consp entry)
                     (stringp (car entry))
                     (stringp (cdr entry)))
            (push entry result)))
        (nreverse result)))))

(defun my-straight-package-report--lock-entries ()
  "Return repository entries from all configured straight lockfiles.

If the same repository occurs in multiple profiles, keep one entry."
  (let (result)
    (dolist (profile straight-profiles)
      (let* ((filename (cdr profile))
             (file
              (expand-file-name
               filename
               (my-straight-package-report--versions-dir))))
        (dolist (entry
                 (my-straight-package-report--read-lockfile file))
          (setf (alist-get (car entry) result nil nil #'string=)
                (cdr entry)))))
    result))


;;; Dependency graph

(defun my-straight-package-report--packages ()
  "Return packages currently registered in `straight--recipe-cache'."
  (let (packages)
    (maphash
     (lambda (package recipe)
       (when (plist-get recipe :local-repo)
         (push (if (symbolp package)
                   (symbol-name package)
                 package)
               packages)))
     straight--recipe-cache)
    (delete-dups packages)))

(defun my-straight-package-report--dependencies (package)
  "Return direct straight dependencies of PACKAGE as strings."
  (condition-case nil
      (mapcar
       (lambda (dep)
         (if (symbolp dep)
             (symbol-name dep)
           dep))
       (straight--get-dependencies package))
    (error nil)))

(defun my-straight-package-report--dependents-table (packages)
  "Build reverse dependency table for PACKAGES.

The returned hash table maps:

  DEPENDENCY -> (DEPENDENT ...)"
  (let ((table (make-hash-table :test #'equal))
        (package-set (make-hash-table :test #'equal)))

    (dolist (package packages)
      (puthash package t package-set))

    (dolist (package packages)
      (dolist (dep
               (my-straight-package-report--dependencies package))
        ;; Only relationships among packages currently registered
        ;; with straight are relevant here.
        (when (gethash dep package-set)
          (push package (gethash dep table)))))

    table))

(defun my-straight-package-report--roots
    (packages dependents-table)
  "Return dependency graph roots from PACKAGES.

A root is a registered package which is not a dependency of any
other currently registered package.

Note that straight.el does not retain a distinct public flag saying
whether a package originated directly from `use-package'.  Therefore
this is a graph-root definition, rather than a literal use-package
declaration detector."
  (cl-remove-if
   (lambda (package)
     (gethash package dependents-table))
   packages))

(defun my-straight-package-report--graph
    (packages roots)
  "Build dependency graph information starting at ROOTS.

Return plist:

  :reachable  hash-table
  :parent     hash-table
  :root       hash-table

PARENT records one path back toward a root."
  (let ((reachable (make-hash-table :test #'equal))
        (parent    (make-hash-table :test #'equal))
        (root-map  (make-hash-table :test #'equal))
        (package-set
         (make-hash-table :test #'equal))
        queue)

    (dolist (package packages)
      (puthash package t package-set))

    (dolist (root roots)
      (puthash root root root-map)
      (push root queue))

    ;; Breadth/depth distinction is not important here; we only need
    ;; one explanatory path from a root to each dependency.
    (while queue
      (let ((package (pop queue)))
        (unless (gethash package reachable)
          (puthash package t reachable)

          (dolist (dep
                   (my-straight-package-report--dependencies package))
            (when (and (gethash dep package-set)
                       (not (gethash dep reachable)))
              (unless (gethash dep parent)
                (puthash dep package parent)
                (puthash dep
                         (or (gethash package root-map)
                             package)
                         root-map))
              (push dep queue))))))

    (list :reachable reachable
          :parent parent
          :root root-map)))

(defun my-straight-package-report--dependency-path
    (package parent-table)
  "Return one dependency path leading to PACKAGE.

Example:

  magit -> transient -> compat"
  (let ((current package)
        path
        seen)
    (while (and current
                (not (member current seen)))
      (push current path)
      (push current seen)
      (setq current
            (gethash current parent-table)))
    (string-join path " -> ")))


;;; Repository mapping / infrastructure

(defun my-straight-package-report--repo-package-table ()
  "Return mapping from local repository name to package names."
  (let ((table (make-hash-table :test #'equal)))
    (maphash
     (lambda (package recipe)
       (when-let ((local-repo
                   (plist-get recipe :local-repo)))
         (let ((package-name
                (if (symbolp package)
                    (symbol-name package)
                  package)))
           (push package-name
                 (gethash local-repo table)))))
     straight--recipe-cache)
    table))

(defun my-straight-package-report--infrastructure-repo-p
    (local-repo)
  "Return non-nil if LOCAL-REPO is straight infrastructure.

This includes straight.el itself and configured recipe
repositories."
  (or
   (string= local-repo "straight.el")
   (and
    (boundp 'straight-recipe-repositories)
    (cl-some
     (lambda (repo)
       (string=
        local-repo
        (if (symbolp repo)
            (symbol-name repo)
          repo)))
     straight-recipe-repositories))))


;;; Classification

(defun my-straight-package-report--yes-no (value)
  "Return display string for VALUE."
  (if value "yes" "no"))

(defun my-straight-package-report--orphan-p
    (locked reachable infrastructure)
  "Return non-nil for an unexplained locked repository."
  (and locked
       (not reachable)
       (not infrastructure)))

(defun my-straight-package-report--reason
    (package
     root
     reachable
     locked
     infrastructure
     parent-table
     repo-only)
  "Return human-readable explanation for PACKAGE."
  (cond
   (infrastructure
    "straight infrastructure")

   (repo-only
    (if locked
        "lock entry without registered package"
      "repository without registered package"))

   (root
    "graph root")

   (reachable
    (format "dependency: %s"
            (my-straight-package-report--dependency-path
             package parent-table)))

   (locked
    "unexplained lock entry")

   (t
    "registered but unreachable")))


;;; Rows

(defun my-straight-package-report--entries ()
  "Return tabulated entries for straight packages and locked repos."
  (let* ((packages
          (my-straight-package-report--packages))

         (dependents
          (my-straight-package-report--dependents-table
           packages))

         (roots
          (my-straight-package-report--roots
           packages dependents))

         (graph
          (my-straight-package-report--graph
           packages roots))

         (reachable-table
          (plist-get graph :reachable))

         (parent-table
          (plist-get graph :parent))

         (root-table
          (let ((table (make-hash-table :test #'equal)))
            (dolist (root roots)
              (puthash root t table))
            table))

         (lock-entries
          (my-straight-package-report--lock-entries))

         (repo-package-table
          (my-straight-package-report--repo-package-table))

         entries
         seen-repos)

    ;; ------------------------------------------------------------
    ;; Registered packages
    ;; ------------------------------------------------------------

    (maphash
     (lambda (package-value recipe)
       (when-let ((local-repo
                   (plist-get recipe :local-repo)))

         (let* ((package
                 (if (symbolp package-value)
                     (symbol-name package-value)
                   package-value))

                (source
                 (my-straight-package-report--source
                  package-value))

                (host
                 (my-straight-package-report--host recipe))

                (repo
                 (or (plist-get recipe :repo) "-"))

                (commit
                 (my-straight-package-report--commit recipe))

                (locked
                 (assoc-string
                  local-repo
                  lock-entries))

                (root
                 (gethash package root-table))

                (reachable
                 (gethash package reachable-table))

                (infrastructure
                 (my-straight-package-report--infrastructure-repo-p
                  local-repo))

                (orphan
                 (my-straight-package-report--orphan-p
                  locked
                  reachable
                  infrastructure))

                (reason
                 (my-straight-package-report--reason
                  package
                  root
                  reachable
                  locked
                  infrastructure
                  parent-table
                  nil)))

           (push local-repo seen-repos)

           (push
            (list
             (format "package:%s" package)
             (vector
              package
              source
              host
              (format "%s" repo)
              local-repo
              commit
              (my-straight-package-report--yes-no locked)
              (my-straight-package-report--yes-no root)
              (my-straight-package-report--yes-no reachable)
              (if orphan
                  (propertize
                   "YES"
                   'face 'error)
                "no")
              reason))
            entries))))
     straight--recipe-cache)

    ;; ------------------------------------------------------------
    ;; Repositories which occur in the lockfile but have no package
    ;; in the current recipe cache.
    ;;
    ;; This is the important case for detecting stale / unexplained
    ;; lock entries.
    ;; ------------------------------------------------------------

    (dolist (lock-entry lock-entries)
      (let ((local-repo (car lock-entry))
            (locked-commit (cdr lock-entry)))

        (unless (member local-repo seen-repos)
          (let* ((known-packages
                  (gethash local-repo
                           repo-package-table))

                 (infrastructure
                  (my-straight-package-report--infrastructure-repo-p
                   local-repo))

                 (orphan
                  (not infrastructure))

                 (package-name
                  (if known-packages
                      (string-join known-packages ",")
                    "-"))

                 (reason
                  (if infrastructure
                      "straight infrastructure"
                    "lock entry without registered package")))

            (push
             (list
              (format "repo:%s" local-repo)
              (vector
               package-name
               "-"
               "-"
               "-"
               local-repo
               (if (>= (length locked-commit) 12)
                   (substring locked-commit 0 12)
                 locked-commit)
               "yes"
               "no"
               "no"
               (if orphan
                   (propertize
                    "YES"
                    'face 'error)
                 "no")
               reason))
             entries)))))

    ;; Sort using the displayed package name, then local repo.
    (sort
     entries
     (lambda (a b)
       (string-lessp
        (aref (cadr a) 0)
        (aref (cadr b) 0))))))


;;; UI

(define-derived-mode my-straight-package-report-mode
  tabulated-list-mode
  "Straight Packages"
  "Display packages managed by straight.el."

  (setq tabulated-list-format
        [("Package"     26 t)
         ("Source"      12 t)
         ("Host"        10 t)
         ("Repository"  38 t)
         ("Local repo"  24 t)
         ("Commit"      12 t)
         ("Lock?"        6 t)
         ("Root?"        6 t)
         ("Reachable?"  10 t)
         ("Orphan?"      8 t)
         ("Reason"      50 t)])

  (setq tabulated-list-padding 2)
  (setq tabulated-list-sort-key
        '("Package" . nil))

  (tabulated-list-init-header))

;;;###autoload
(defun my/straight-package-report ()
  "Display a report of packages registered with straight.el.

The report compares:

- packages currently registered by straight.el
- dependency relationships
- local repositories
- configured version lockfiles

`Orphan?' means that a repository is present in a lockfile but
cannot currently be explained by the registered dependency graph
and is not recognized as straight infrastructure."
  (interactive)

  (unless (boundp 'straight--recipe-cache)
    (user-error "straight.el is not loaded"))

  (unless (boundp 'straight-profiles)
    (user-error "straight.el profiles are not available"))

  (let ((buffer
         (get-buffer-create
          "*Straight Package Report*")))
    (with-current-buffer buffer
      (my-straight-package-report-mode)
      (setq tabulated-list-entries
            (my-straight-package-report--entries))
      (tabulated-list-print t))
    (pop-to-buffer buffer)))

(provide 'my-straight-package-report)

;;; my-straight-package-report.el ends here
