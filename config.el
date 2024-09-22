;;; config.el -*- lexical-binding: t; -*-

(setq doom-theme 'doom-ayu-dark) ; set theme
;;(setq fancy-splash-image (expand-file-name "doom-emacs-gray.png" doom-user-dir)) ;  set splash image

(setq display-line-numbers-type t)

(defun my-toggle-normal-line-numbers ()
  "Turn line numbers off if in writeroom-mode, otherwise turn on."
  (interactive)
  (if (eq writeroom-mode 't)      ; if writeroom mode is on...
      (setq display-line-numbers nil)   ; turn them off
    (setq display-line-numbers 't)))    ; otherwise turn them back on again

;;; add a hook to run this function when zen mode is activated or deactivated
(add-hook 'writeroom-mode-hook 'my-toggle-normal-line-numbers)

(setq doom-font (font-spec :family "Noto Sans Mono Medium" :size 22) ; set defaut font
      doom-variable-pitch-font (font-spec :family "Noto Sans" :size 22) ; set variable width font
      doom-unicode-font "-GOOG-Noto Sans Mono-medium-normal-normal-*-22-*-*-*-*-0-iso10646-1") ; set unicode font

(defun my-greek-font-fix ()
  "Set the fontset-default for Greek & Coptic"
  (interactive)
  (set-fontset-font "fontset-default"
                    (cons (decode-char 'ucs #x0370)
                          (decode-char 'ucs #x03ff))
                    "-GOOG-Noto Sans Mono-medium-normal-normal-*-22-*-*-*-*-0-iso10646-1")) ;; λe
(after! eshell
  (my-greek-font-fix))

(map! :map evil-motion-state-map
      ;; make ]] and [[ move to org headings
      "] ]" #'org-next-visible-heading
      "[ [" #'org-previous-visible-heading
      ;; make j and k use visual lines rather than actual lines, to make line wrap easier to navigate through
      "j" #'evil-next-visual-line
      "k" #'evil-previous-visual-line)

(after! deft
  ;; Standard Deft Configuration
  (setq deft-extensions '("txt" "md" "org")); file extensions
  (setq deft-directory "~/res/org/roam/"); directory
  (setq deft-recursive nil); dont search directories recursively
  ;; Regexes to work with org-roam
  (setq deft-strip-summary-regexp  ; this is a regexp that processes the "file summary", so ugly metadata doesnt get displayed in the file preview
        (concat "\\("
          "^:.+:.*\n"     ; any line with a :SOMETHING:
          "\\|^#\\+.*\n"  ; any line starting with a #+
          "\\|^\\*.+.*\n" ; any line where an asterisk starts the line
          "\\|\n"         ; any newline characters, so the file summary stays on a single line
          "\\)"))
  (setq deft-strip-title-regexp    ; this is regexp that processes the title, so similar metadata is hidden, otherwise the title would always be #+title: Title
        "\\(?:^%+\\|^#\\+TITLE: *\\|^[#* ]+\\|-\\*-[[:alpha:]]+-\\*-\\|^title:[ ]*\\|#+$\\)")
  ;; Advice to use #+title metadata field as the title, rather than the first line as it is by default
  ;; Courtesy of @brittAnderson https://github.com/jrblevin/deft/issues/75#issuecomment-919578769
  (advice-add 'deft-parse-title :override
   (lambda (file contents)
       (if deft-use-filename-as-title  ; if the var to make the filename the title is true, do so
           (deft-base-filename file)
         (let* ((case-fold-search 't)  ; otherwwise, search for the line with "title:" in it
                (begin (string-match "title: " contents))
                (end-of-begin (match-end 0))
                (end (string-match "\n" contents begin)))
           (if begin
               (substring contents end-of-begin end)
             (format "%s" file)))))))

;; org directory
(setq org-directory "~/res/org/")
(after! org
  ;; add LaTeX preview to the {SPC m} localleader map in org-mode
  (map! :map org-mode-map
        :localleader
        :n "L" #'org-latex-preview)
)


(add-hook! 'after-save-hook                                               ; Run this function upon saving
        (defun my-org-roam-rename-file-to-title ()                        ; Define function
        (when-let*
                ((old-file (buffer-file-name))
                (is-roam-file (org-roam-file-p old-file))
                (file-node (save-excursion
                        (goto-char 1)
                        (org-roam-node-at-point)))
                (slug (org-roam-node-slug file-node))
                (new-file (expand-file-name (concat slug ".org")))
                (different-name? (not (string-equal old-file new-file))))
        (org-roam-db-sync)                                                ; Sync the db
        (rename-buffer new-file)                                          ; Rename the buffer
        (rename-file old-file new-file)                                   ; Rename the file
        (set-visited-file-name new-file)                                  ; Set visited file name
        (set-buffer-modified-p t)                                         ; Set buffer modified
        (save-buffer))))                                                  ; Save

(use-package! websocket
    :after org-roam)
(use-package! org-roam-ui
    :after org-roam ;; or :after org
;;         normally we'd recommend hooking orui after org-roam, but since org-roam does not have
;;         a hookable mode anymore, you're advised to pick something yourself
;;         if you don't care about startup time, use
;;  :hook (after-init . org-roam-ui-mode)
    :config
    (setq org-roam-ui-sync-theme t
          org-roam-ui-follow t
          org-roam-ui-update-on-save t
          org-roam-ui-open-on-start t))

(map! :map doom-leader-map
      "y" #'hyperbole)

(after! hyperbole
  (setq hsys-org-enable-smart-keys 't)  ; prioritze hyperbole functionality completely over org
  (map! :map org-mode-map               ; rebind org so I can still use it even when on a hyperbole button
      "s-<return>" #'org-meta-return))

(after! hyperbole
  (setq hbmap:dir-user "~/.config/emacs/hyperbole"))

(after! org-journal
  ;; Use a monthly format
  (setq org-journal-file-type 'monthly)
  (setq org-journal-file-format "%Y%m")                 ; filenames
  ;; Use valid org-mode timestamps in the headings and subheadings instead of plaintext dates and times
  (setq org-journal-date-format "[%Y-%m-%d %a]")        ; day headings
  (setq org-journal-time-format "[%Y-%m-%d %a %H:%M]")) ; time headings

(map! :map doom-leader-notes-map
      "j n" #'org-journal-new-entry
      "j N" #'org-journal-new-scheduled-entry
      "j f" #'org-journal-search-forever
      "j j" #'org-journal-display-entry
      "j J" #'org-journal-read-entry)

(setq vterm-shell "/bin/fish")

;;(add-to-list 'load-path "~/.doom.d/lisp/")  ;; I cloned the em-smart.el to here in case
;;(require 'em-smart)  ;; this should make it work
;;(add-to-list 'eshell-modules-list 'eshell-smart)  ;; or perhaps this is making it work and the rest is unnecessary
;; either way, it works and im not touching it in case it ceases to

(map! :map doom-leader-toggle-map
      "a" #'gnu-apl-show-keyboard) ; bind SPC t a to toggle the APL keyboard buffer

(map! :map doom-leader-open-map
      "c" #'calc                   ; calc is cool
      "C" #'full-calc)             ; rpn 💪

(setq which-key-idle-delay 0.2)

;; (setq hy-shell--interpeter-args nil)
