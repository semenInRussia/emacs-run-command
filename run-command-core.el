;;; run-command-core.el --- Core functionality -*- lexical-binding: t -*-

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

;; Core functionality for `run-command'.

;;; Code:

;;;; Dependencies

(require 'map)
(require 'seq)
(require 'subr-x)

;;;; Public API

(defun run-command-core-get-command-specs (command-recipes)
  "Execute COMMAND-RECIPES functions to generate command lists."
  (seq-mapcat
   (lambda (command-recipe)
     (when (not (fboundp command-recipe))
       (error "[run-command] Invalid command recipe: %s" command-recipe))
     (thread-last
      command-recipe (funcall)
      (seq-filter
       (lambda (spec) (and spec (map-elt spec :command-line))))
      (seq-map
       (lambda (spec) (map-insert spec :recipe command-recipe)))
      (seq-map #'run-command--normalize-command-spec)))
   command-recipes))

(defun run-command-core-run (command-spec)
  "Run COMMAND-SPEC.

See `run-command-recipes' for the expected format of COMMAND-SPEC."
  (let* ((buffer-base-name
          (format "%s[%s]"
                  (map-elt command-spec :command-name)
                  (map-elt command-spec :scope-name)))
         (buffer (get-buffer-create (concat "*" buffer-base-name "*")))
         (command-line (map-elt command-spec :command-line)))
    (unless (get-buffer-process buffer)
      (with-current-buffer buffer
        (buffer-disable-undo)
        (let ((default-directory (map-elt command-spec :working-dir)))
          (funcall (map-elt command-spec :runner)
                   (if (functionp command-line)
                       (funcall command-line)
                     command-line)
                   buffer-base-name (current-buffer))
          (setq-local run-command--command-spec command-spec)
          (when (map-contains-key command-spec :hook)
            (funcall (map-elt command-spec :hook))))))
    (let ((display-buffer-alist
           '((".*" display-buffer-use-least-recent-window))))
      (display-buffer buffer))))

;;;; Internals

(defvar-local run-command--command-spec nil
  "Buffer-local variable containing command spec for the buffer.")

(defvar run-command-default-runner)

(defvar run-command-run-method)

(defun run-command--normalize-command-spec (command-spec)
  "Validate COMMAND-SPEC and fill in defaults for missing properties."
  (unless (stringp (map-elt command-spec :command-name))
    (error
     "[run-command] Invalid `:command-name' in command spec: %S"
     command-spec))
  (unless (or (stringp (map-elt command-spec :command-line))
              (functionp (map-elt command-spec :command-line)))
    (error
     "[run-command] Invalid `:command-line' in command spec: %S"
     command-spec))
  (let ((cs (map-copy command-spec)))
    (unless (map-contains-key cs :display)
      (map-put! cs :display (map-elt cs :command-name)))
    (unless (map-contains-key cs :working-dir)
      (map-put! cs :working-dir default-directory))
    (unless (map-contains-key cs :scope-name)
      (map-put!
       cs
       :scope-name
       (abbreviate-file-name
        (or (map-elt cs :working-dir) default-directory))))
    (unless (map-contains-key cs :runner)
      (map-put!
       cs
       :runner
       (cond
        (run-command-default-runner
         run-command-default-runner)
        (run-command-run-method
         (pcase run-command-run-method
           ('compile 'run-command-runner-compile)
           ('term 'run-command-runner-term)
           ('vterm 'run-command-runner-vterm)))
        ((eq system-type 'windows-nt)
         'run-command-runner-compile)
        (t
         'run-command-runner-term))))
    cs))

(defun run-command--shorter-recipe-name-maybe (command-recipe)
  "Shorten COMMAND-RECIPE name when it begins with conventional prefix."
  (let ((recipe-name (symbol-name command-recipe)))
    (if (string-match "^run-command-recipe-\\(.+\\)$" recipe-name)
        (match-string 1 recipe-name)
      recipe-name)))

;;;; Experiments

(defvar run-command-experiments nil
  "Currently active experiments.")

(defvar run-command--deprecated-experiment-warning t)

(defun run-command--experiment--active-p (name)
  "Return t if experiment NAME is enabled, nil otherwise."
  (member name run-command-experiments))

(defun run-command--check-experiments ()
  "Validate experiments configured via `run-command-experiments'.

If experiment is active, do nothing.  If experiment is retired or
unknown, signal error.  If experiment is deprecated, print a
warning and allow muting further warnings for the rest of the
session."
  (let ((experiments
         '((static-recipes . retired)
           (vterm-run-method . retired)
           (run-command-experiment-vterm-run-method . retired)
           (run-command-experiment-function-command-lines . retired)
           (run-command-experiment-lisp-commands . retired)
           (example-retired . retired)
           (example-deprecated . deprecated))))
    (seq-do
     (lambda (experiment-name)
       (let ((experiment
              (seq-find
               (lambda (e) (eq (car e) experiment-name)) experiments)))
         (if experiment
             (let ((name (car experiment))
                   (status (cdr experiment)))
               (pcase status
                 ('retired
                  (error
                   "[run-command] Experiment `%S' was \
retired, please remove from `run-command-experiments'"
                   name))
                 ('deprecated
                  (when run-command--deprecated-experiment-warning
                    (setq
                     run-command--deprecated-experiment-warning
                     (not
                      (yes-or-no-p
                       (format
                        "Warning: run-command: experiment \
 `%S' is deprecated, please update your configuration.  Disable reminder for \
this session?"
                        name))))))
                 ('active nil)))
           (error
            "[run-command] Experiment `%S' does not exist, \
please remove from `run-command-experiments'"
            experiment-name))))
     run-command-experiments)))

;;;; Meta

(provide 'run-command-core)

;;; run-command-core.el ends here
