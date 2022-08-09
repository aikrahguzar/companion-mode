;;; companion-mode.el --- Pair buffers for simulatenous display -*- lexical-binding: t; -*-
;;
;; Created: June 04, 2022
;; Modified: June 04, 2022
;; License: GPL-3.0-or-later
;; Version: 0.0.1
;; Keywords: processes tools
;; Homepage: https://github.com/aikrahguzar/companion-mode
;; Package-Requires: ((emacs "25.1"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  This package defines a global minor mode `companion-mode' whose purpose is
;;  to pair a companion popup buffer with a real buffer such when the real
;;  is displayed in a window, the companion buffer is also displayed and when
;;  it is not, the companion buffer disappears too.
;;
;;; Code:

(defvar-local companion-mode--companion nil)

;;;; Minor mode
;;;###autoload
(define-minor-mode companion-mode
  "Minor mode for viewing a popup companion buffer alongside a real buffer.
The purpose of this mode is to display the companion buffer if and only if the
real buffer is also displayed."
  :global t :lighter "Companion mode (global)" :group 'inspirehep
  (if (not companion-mode) (remove-hook 'window-buffer-change-functions #'companion-mode--on-buffer-change)
    (add-hook 'window-buffer-change-functions #'companion-mode--on-buffer-change)))

(defun companion-mode--on-buffer-change (frame) "Function to delete a window on FRAME with an old companion buffer."
       (if-let ((companion (companion-mode--get-companion))
                (window (get-buffer-window companion)))
           (set-window-parameter (frame-selected-window frame) 'companion-mode--window window)
         (companion-mode--delete frame) (when (eq (car companion-mode--companion) 'show) (companion-mode--display frame))))

(defun companion-mode--get-companion () "Get the companion buffer to the current buffer."
       (if (functionp (cdr companion-mode--companion))
           (if-let ((buf (funcall (cdr companion-mode--companion)))) (setf (cdr companion-mode--companion) buf) (setq companion-mode--companion nil))
         (cdr companion-mode--companion)))

(defun companion-mode--display (&optional frame) "Display the companion to the buffer in selected window on FRAME."
       (set-window-parameter (frame-selected-window frame) 'companion-mode--window (display-buffer (cdr companion-mode--companion))))

(defun companion-mode--delete (&optional frame) "Delete window displaying companion to the buffer in selected window on FRAME."
       (when-let ((comp-win (companion-mode-companion-window frame)))
         (and (window-live-p comp-win) (delete-window comp-win))))

(defun companion-mode-set (buf &optional hide kill)
  "Set BUF to be the companion of current buffer.
BUF can be a function that returns a buffer, it is is called the first time
the buffer is displayed. If HIDE is non-nil the companion is not displayed.
If KILL is not nill, companion will be killed when the buffer is killed."
       (interactive (list (get-buffer (read-buffer "Choose the companion:" nil t)) current-prefix-arg))
       (setq companion-mode--companion (cons (if hide 'hide 'show) buf)) (unless (or hide (functionp buf)) (companion-mode--display))
       (when kill (add-hook 'kill-buffer-hook #'companion-mode--kill-companion nil t) buf))

(defun companion-mode--kill-companion () "Kill the companion of current buffer."
  (and companion-mode--companion (kill-buffer (cdr companion-mode--companion))))

(defun companion-mode-toggle-companion () "Toggle the display of companion buffer." (interactive)
       (setf (car companion-mode--companion)
             (if (eq (car companion-mode--companion) 'show) (progn (companion-mode--delete) 'hide) (progn (companion-mode--display) 'show))))

(defun companion-mode-companion-window (&optional frame) "Return the window on FRAME where companion buffer is displayed."
       (window-parameter (frame-selected-window frame) 'companion-mode--window))

(provide 'companion-mode)
;;; companion-mode.el ends here
