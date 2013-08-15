;;; magit-vcsh.el --- git-vcsh plug-in for Magit

;; Copyright (C) 2013 Rémi Vanicat

;; Magit is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; Magit is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Magit.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This plug-in provides vcsh functionality as a separate component of
;; Magit.

;;; Code:
(defgroup magit-vcsh nil
  "Controlling Git from Emacs."
  :prefix "magit-vcsh"
  :group 'magit)

(defcustom magit-vcsh-executable "vcsh"
  "The name of the Git executable."
  :group 'magit-vcsh
  :type 'string)

(defvar-local magit-vcsh-env ()
  "the vcsh environment variable")
(put 'magit-vcsh-env 'permanent-local t)

(defun magit-vcsh-string (&rest args)
  (magit-trim-line (magit-cmd-output magit-vcsh-executable args)))

(defun magit-vcsh-get-env (name)
  "get env from vcsh.

Return it in a form switable to append to `process-environment'"
  (let ((git-dir (magit-vcsh-string "run" name "sh" "-c" "echo \$GIT_DIR"))
        (git-work-tree (magit-vcsh-string "run" name "sh" "-c" "echo \$GIT_WORK_TREE"))
        (vcsh-directory (magit-vcsh-string "run" name "sh" "-c" "echo \$VCSH_DIRECTORY"))
        (vcsh-repo-name (magit-vcsh-string "run" name "sh" "-c" "echo \$VCSH_REPO_NAME")))
    (list (format "GIT_DIR=%s" git-dir)
          (format "GIT_WORK_TREE=%s" git-work-tree)
          (format "VCSH_DIRECTORY=%s" vcsh-directory)
          (format "VCSH_REPO_NAME=%s" vcsh-repo-name))))

(defmacro magit-vcsh-set-env (name new-buffer &rest body)
  "Run BODY with correct environement"
  (declare (indent defun)
           (debug (&define name new-buffer
                           def-body)))
  `(let* ((env (magit-vcsh-get-env name)) ;TODO don't use a named argument...
          (process-environment (append env process-environment)))
     (prog1
         (progn ,@body)
       ,(when new-buffer '(setq magit-vcsh-env env)))))

(defmacro magit-vcsh-advice-macro (name)
  `(defadvice ,name (around ,(intern (format "%s-vcsh-advice" name)) activate)
     (let ((process-environment (if magit-vcsh-env
                                    (append magit-vcsh-env process-environment)
                                    process-environment)))
       ad-do-it)))

(magit-vcsh-advice-macro magit-cmd-output)
(magit-vcsh-advice-macro magit-git-exit-code)
(magit-vcsh-advice-macro magit-run*)
(magit-vcsh-advice-macro magit-start-process)

(defun magit-vcsh-status (name)
  "call magit-status but changing the command to use vcsh"
  (interactive "Mvcsh repos:")

  (magit-vcsh-set-env name t
      (magit-status "~/")))
