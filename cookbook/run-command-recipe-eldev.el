;;; run-command-recipe-eldev.el --- Recipe for Eldev commands -*- lexical-binding: t -*-

;;; Commentary:

;; Recipe for Eldev commands.

;;; Code:

(require 'subr-x)

(defun run-command-recipe-eldev ()
  "Provide commands for an Emacs project managed with `eldev'."
  (when-let* ((project-dir (locate-dominating-file default-directory "Eldev")))
    (list
     (list
      :command-name "test:watch"
      :command-line "watchexec --ignore 'flycheck_*' eldev test"
      :display "test:watch"
      :working-dir project-dir)
     (list
      :command-name "lint"
      :command-line "eldev lint"
      :display "lint"
      :working-dir project-dir))))

(provide 'run-command-recipe-eldev)
;;; run-command-recipe-eldev.el ends here
