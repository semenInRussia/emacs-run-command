;;; run-command-runner-vterm.el --- term-mode runner -*- lexical-binding: t -*-

;; Copyright (C) 2020-2023 Massimiliano Mirra

;; Author: Massimiliano Mirra <hyperstruct@gmail.com>
;; URL: https://github.com/bard/emacs-run-command

;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Runner for `run-command' based on `vterm-mode'.

;;; Code:

(require 'run-command-core)

(declare-function vterm-mode "ext:vterm")
(defvar vterm-kill-buffer-on-exit)
(defvar vterm-shell)

(defun run-command-runner-vterm (command-line buffer-base-name output-buffer)
  "Command runner based on `term-mode'.

Executes COMMAND-LINE in buffer OUTPUT-BUFFER.  Name the process BUFFER-BASE-NAME."
  (require 'vterm)
  (with-current-buffer output-buffer
    (let ((vterm-kill-buffer-on-exit nil)
          ;; XXX needs escaping or commands containing quotes will cause trouble
          (vterm-shell (format "%s -c '%s'" vterm-shell command-line)))
      (vterm-mode))))

;;;; Meta

(provide 'run-command-runner-vterm)

;;; run-command-runner-vterm.el ends here
