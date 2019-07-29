;; -*- lexical-binding: t -*-

(require 'cl-lib)

(setq warning-minimum-level :error)

(setq confirm-nonexistent-file-or-buffer nil
      ffap-machine-p-known               'reject)

(defun me/make-path (root-dir &rest path-elements)
  (cl-reduce '(lambda (x &optional y)
                (concat ( file-name-as-directory x) y))
             path-elements :initial-value root-dir))

(defun me/emacs-dir-path (&rest path-elements)
  (apply 'me/make-path (cons user-emacs-directory path-elements)))

(defun me/switch-window-max ()
  "Switch to the other window and maximize it."
  (interactive)
  (other-window -1)
  (delete-other-windows)
  (goto-char (point-max)))

(defun me/switch-window-normal ()
  "Switch to the other window and maximize it."
  (interactive)
  (other-window -1)
  (delete-other-windows))

(defun me/transpose-windows (arg)
  "Transpose the buffers shown in two windows."
  (interactive "p")
  (let ((selector (if (>= arg 0) 'next-window 'previous-window)))
    (while (/= arg 0)
      (let ((this-win (window-buffer))
            (next-win (window-buffer (funcall selector))))
        (set-window-buffer (selected-window) next-win)
        (set-window-buffer (funcall selector) this-win)
        (select-window (funcall selector)))
      (setq arg (if (plusp arg) (1- arg) (1+ arg))))))

;;;; compression
(add-hook 'after-init-hook #'auto-compression-mode)

;;;; utf-8
(defun me/setup-utf8 ()
  (interactive)
  (prefer-coding-system 'utf-8)
  (setq-default buffer-file-coding-system 'utf-8)
  (setq coding-system-for-write 'utf-8
        coding-system-for-read  'utf-8
        file-name-coding-system 'utf-8
        locale-coding-system    'utf-8)
  (set-language-environment     'utf-8)
  (set-default-coding-systems   'utf-8)
  (set-terminal-coding-system   'utf-8)
  (set-keyboard-coding-system   'utf-8)
  (set-selection-coding-system  'utf-8)
  (set-language-environment     'utf-8))
(add-hook 'after-init-hook #'me/setup-utf8)

;;;; utilities
(global-set-key (kbd "C-x M-o") 'join-line)
(global-set-key (kbd "C-x C-o") 'delete-blank-lines)

(defun me/rename-buffer-file ()
  "Renames current buffer and file it is visiting."
  (interactive)
  (let ((name (buffer-name))
        (filename (buffer-file-name)))
    (if (not (and filename (file-exists-p filename)))
        (error "Buffer '%s' is not visiting a file!" name)
      (let ((new-name (read-file-name "New name: " filename)))
        (cond ((get-buffer new-name)
               (error "A buffer named '%s' already exists!" new-name))
              (t
               (rename-file filename new-name 1)
               (rename-buffer new-name)
               (set-visited-file-name new-name)
               (set-buffer-modified-p nil)))))))

(defun me/burry-other-buffer ()
  "Close other buffer window."
  (interactive)
  (when (window-parent)
    (other-window -1)
    (bury-buffer)
    (other-window -1)))

(defun me/get-string-from-file (file-path)
  "Return file-path's file content."
  (with-temp-buffer
    (insert-file-contents file-path)
    (buffer-string)))

(defun me/comment-or-uncomment-line-or-region ()
  "Comment or uncomment the current line or region."
  (interactive)
  (if (region-active-p)
      (comment-or-uncomment-region (region-beginning) (region-end))
    (comment-or-uncomment-region (line-beginning-position) (line-end-position))))

(defun me/do-with-symbol-at-point-bounds (cb-fn)
  "Do something with the bounds of the symbol at point"
  (let ((bounds (bounds-of-thing-at-point 'symbol)))
    (when bounds
      (funcall cb-fn (car bounds) (cdr bounds)))))

(defun me/touch-file (path)
  "Create a file if it does not exists."
  (when (not (file-exists-p path))
    (with-temp-buffer (write-file path))))

(defun me/indent-region-or-buffer ()
  "Indents an entire buffer using the default intenting scheme."
  (interactive)
  (let ((coords (if (region-active-p)
                    (list (region-beginning) (region-end))
                  (list (point-min) (point-max)))))
    (indent-region (car coords) (car (last coords)))
    (delete-trailing-whitespace (point-min) (point-max))
    (untabify (point-min) (point-max))))

;;;; eshell
(eval-after-load 'eshell
  (progn
    (setq eshell-highlight-prompt       nil
          eshell-history-size           8000
          eshell-path-env               (getenv "PATH")
          eshell-cmpl-cycle-completions nil)

    (add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)
    (add-hook 'eshell-preoutput-filter-functions 'ansi-color-filter-apply)
    (add-to-list 'comint-output-filter-functions 'ansi-color-process-output)

    '(defun eshell/up (&optional level)
       "Change directory from one up to a level of folders."
       (let ((path-level (or level 1)))
         (cd (apply 'concat (make-list path-level "../")))))))

;;;; ansi
(autoload 'ansi-color-apply-on-region "ansi-color" "ansi colors" t nil)

(defun me/colorize-compilation-buffer ()
  (let ((inhibit-read-only t))
    (ansi-color-apply-on-region (point-min) (point-max))))

(add-hook 'compilation-filter-hook #'me/colorize-compilation-buffer)

;;;; auth-source
(autoload 'auth-source-user-and-password "auth-source" "credentials" t nil)

;;;; package
(eval-after-load 'package
  (progn
    (package-initialize)

    (mapc (lambda (p)
            (unless (package-installed-p p)
              (progn
                (package-refresh-contents)
                (package-install p))))
          package-selected-packages)

    (defun me/setup-package-sorting ()
      (setq tabulated-list-format
            (vconcat
             (mapcar
              (lambda (arg)
                (list
                 (nth 0 arg)
                 (nth 1 arg)
                 (or (nth 2 arg) t)))
              tabulated-list-format))))

    '(add-hook 'package-menu-mode-hook #'me/setup-package-sorting)))

;;;; dired
(with-eval-after-load 'dired
  (define-key dired-mode-map (kbd ".") #'dired-up-directory))

;;;; encryption
(setq epa-file-cache-passphrase-for-symmetric-encryption t)

;;;; hippie-expand
(setq hippie-expand-try-functions-list '(try-expand-dabbrev
                                         try-expand-dabbrev-all-buffers
                                         try-expand-dabbrev-from-kill
                                         try-complete-file-name-partially
                                         try-complete-file-name
                                         try-expand-all-abbrevs
                                         try-expand-list
                                         try-expand-line
                                         try-complete-lisp-symbol-partially
                                         try-complete-lisp-symbol))
(global-set-key (kbd "M-/") #'hippie-expand)

;;;; line-operations
(defun me/move-line-up ()
  "Move up the current line."
  (interactive)
  (transpose-lines 1)
  (forward-line -2)
  (indent-according-to-mode))

(defun me/move-line-down ()
  "Move down the current line."
  (interactive)
  (forward-line 1)
  (transpose-lines 1)
  (forward-line -1)
  (indent-according-to-mode))

(defun me/duplicate-line-or-region (&optional n)
  "Duplicate current line, or region if active.
With argument N, make N copies.
With negative N, comment out original line and use the absolute value."
  (interactive "*p")
  (let ((use-region (use-region-p)))
    (save-excursion
      (let ((text (if use-region
                      (buffer-substring (region-beginning) (region-end))
                    (prog1 (thing-at-point 'line)
                      (end-of-line)
                      (if (< 0 (forward-line 1))
                          (newline))))))
        (dotimes (i (abs (or n 1)))
          (insert text))))
    (if use-region nil
      (let ((pos (- (point) (line-beginning-position)))) ;Save column
        (if (> 0 n)
            (comment-region (line-beginning-position) (line-end-position)))
        (forward-line 1)
        (forward-char pos)))))

(global-set-key (kbd "M-P")   #'me/move-line-up)
(global-set-key (kbd "M-N")   #'me/move-line-down)
(global-set-key (kbd "C-c d") #'me/duplicate-line-or-region)


;;;; transpose
(global-unset-key (kbd "M-t"))
(global-unset-key (kbd "C-t"))

(global-set-key (kbd "M-t c") #'transpose-chars)
(global-set-key (kbd "M-t l") #'transpose-lines)
(global-set-key (kbd "M-t s") #'transpose-sexps)
(global-set-key (kbd "M-t w") #'me/transpose-windows)

;;;; things-at-point
(defun me/cut-symbol-at-point ()
  "Cut the symbol at point."
  (interactive)
  (me/do-with-symbol-at-point-bounds 'kill-region))

(defun me/copy-symbol-at-point ()
  "Copy the symbol at point."
  (interactive)
  (me/do-with-symbol-at-point-bounds 'kill-ring-save))

(defun me/mark-symbol-at-point ()
  "Mark symbol at point."
  (interactive)
  (me/do-with-symbol-at-point-bounds #'(lambda (start end)
                                          (goto-char start)
                                          (set-mark-command nil)
                                          (goto-char end))))

(global-set-key (kbd "C-h C-w") #'me/cut-symbol-at-point)
(global-set-key (kbd "C-h M-w") #'me/copy-symbol-at-point)
(global-set-key (kbd "C-c m w") #'me/mark-symbol-at-point)

;;;; general
(global-set-key (kbd "C-c m l") (kbd "C-a C-@ C-e"))
(global-set-key (kbd "C-x C-r") #'query-replace)
(global-set-key (kbd "C-c /") #'me/comment-or-uncomment-line-or-region)

(global-set-key (kbd "C-c \\") #'me/indent-region-or-buffer)
(global-set-key (kbd "C-c ar") #'align-regexp)
(global-set-key (kbd "RET")    #'newline-and-indent)

;;;; window-management
(fset 'scroll-other-window-up 'scroll-other-window-down)

(global-set-key (kbd "C-M-y")     #'scroll-other-window-up)
(global-set-key (kbd "C-M-v")     #'scroll-other-window)
(global-set-key (kbd "C-h C-M-o") #'me/switch-window-max)

(eval-after-load 'windmove
  (progn
    (global-set-key (kbd "C-c wn")  #'windmove-up)
    (global-set-key (kbd "C-c ws")  #'windmove-down)
    (global-set-key (kbd "C-c we")  #'windmove-right)
    '(global-set-key (kbd "C-c ww") #'windmove-left)))

;;;; buffers
(defun me/kill-buffer-no-confirm ()
  "Kill buffer without confirmation."
  (interactive)
  (let (kill-buffer-query-functions) (kill-buffer)))

(defun me/revert-buffer-no-confirm ()
  "Revert buffer without confirmation."
  (interactive) (revert-buffer t t))

(global-set-key (kbd "C-h [")   #'next-buffer)
(global-set-key (kbd "C-h ]")   #'previous-buffer)
(global-set-key (kbd "C-c r")   #'me/revert-buffer-no-confirm)
(global-set-key (kbd "C-x M-k") #'me/kill-buffer-no-confirm)

;;;; xml
(setq nxml-slash-auto-complete-flag t
      nxml-child-indent             2
      nxml-outline-child-indent     2)

;;;; xref
(with-eval-after-load 'xref
  (global-set-key (kbd "M-\"") #'xref-find-apropos))

;;;; imenu
(global-set-key (kbd "M-s i") #'imenu)

;;;; ediff
(setq ediff-split-window-function 'split-window-horizontally
      ediff-window-setup-function 'ediff-setup-windows-plain)

;;;; org-mode
(with-eval-after-load 'org
  (setq org-directory             "ME_REPLACE"
        org-hide-leading-stars    nil
        org-cycle-separator-lines 0)

  (setq org-archive-location      (me/make-path org-directory "archives.org")
        org-agenda-files          (directory-files me-org-directory t "\\.org$")
        org-export-html-postamble nil
        org-me-notes-file        (me/make-path org-directory "tasks.org"))

  (setq org-link-mailto-program (quote (compose-mail "%a" "%s")))

  (setq org-clock-into-drawer                 t
        org-clock-out-remove-zero-time-clocks t
        org-clock-out-when-done               t
        org-log-into-drawer                   t
        org-clock-persist                     t)

  (setq-default org-agenda-clockreport-parameter-plist '(:link t :maxlevel 3))
  (setq org-cycle-separator-lines 1)
  (setq org-time-clocksum-format '(:hours "%d" :require-hours t :minutes ":%02d" :require-minutes t))

  (setq org-capture-templates
        '(("c" "Coding" entry (file+headline org-me-notes-file "Coding")
           "* TODO %? \nSCHEDULED: %^t" :clock-in t :clock-resume t)
          ("b" "Blogging" entry (file+headline org-me-notes-file "Blogging")
           "* TODO %? \nSCHEDULED: %^t" :clock-in t :clock-resume t)
          ("t" "Task" entry (file+headline org-me-notes-file "Tasks")
           "* TODO %? \nSCHEDULED: %^t" :clock-in t :clock-resume t)))

  (setq org-log-done-with-time t)

  (setq org-todo-keywords '((sequence "TODO(t)" "INPROGRESS(i)" "WAITING(w)")
                            (sequence "|" "DONE(d)")
                            (sequence "REPORT(r)" "BUG(b)" "KNOWNCAUSE(k)" "|" "FIXED(f)")
                            (sequence "|" "CANCELED(c)")))

  (setq org-tag-alist '(("@blogging" . ?b)
                        ("@task"     . ?t)))

  (setq org-agenda-exporter-settings '((ps-number-of-columns 2)
                                       (ps-landscape-mode t)
                                       (org-agenda-add-entry-text-maxlines 5)
                                       (htmlize-output-type 'css)))

  (defun org-summary-todo (n-done n-not-done)
    "Switch entry to DONE when all subentries are done, to TODO otherwise."
    (let (org-log-done org-log-states)   ; turn off logging
      (org-todo (if (= n-not-done 0) "DONE" "TODO"))))

  (defun me/org-mode-hook ()
    (add-to-list 'org-structure-template-alist '("t" "#+TITLE: ?"))
    (define-key org-mode-map (kbd "C-c ot") #'org-todo)
    (define-key org-mode-map (kbd "C-c oh") #'org-insert-heading)
    (define-key org-mode-map (kbd "C-c os") #'org-insert-subheading)
    (define-key org-mode-map (kbd "C-c oa") #'org-agenda)
    (define-key org-mode-map (kbd "C-c oc") #'org-capture)
    (org-indent-mode 1))

  (add-hook 'completion-at-point-functions 'pcomplete-completions-at-point nil t)
  (add-hook 'org-mode-hook #'me/org-mode-hook)

  '(add-hook 'org-after-todo-statistics-hook #'org-summary-todo))

;;;; movement
(global-set-key (kbd "M-p")   (kbd "C-u 15 C-p"))
(global-set-key (kbd "M-n")   (kbd "C-u 15 C-n"))

;;;; others
(add-to-list 'auto-mode-alist '("\\.env\\'" . sh-mode))

(global-set-key (kbd "C-x C-m") #'execute-extended-command)
(global-set-key (kbd "M-s l")   #'goto-line)
(global-set-key (kbd "M-s e")   #'eshell)
(global-set-key (kbd "M-s s")   #'grep-find)
(global-set-key (kbd "M-s r")   #'recentf-open-files)
(global-set-key (kbd "M-Z")     #'zap-up-to-char)

;;;; disabled-commands
(put 'erase-buffer     'disabled nil)
(put 'narrow-to-region 'disabled nil)
(put 'downcase-region  'disabled nil)
(put 'upcase-region    'disabled nil)

(fset 'yes-or-no-p 'y-or-n-p)

;;;; outline
(with-eval-after-load 'outline
  (define-key outline-minor-mode-map
    (concat outline-minor-mode-prefix "") 'outline-hide-body))

;;; Local Variables:
;;; outline-regexp: ";;;; "
;;; eval:(progn (outline-minor-mode 1) (outline-hide-body))
;;; End:
