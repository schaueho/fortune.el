;;; -*- Mode: Emacs-Lisp -*- 
;;; fortune.el --- Use fortune to create signatures
;;; Revision: 1.0
;;; $Id: $

;; Copyright (C) 1999 by Holger Schauer
;; Author: Holger Schauer <Holger.Schauer@gmx.de>
;; Keywords: games utils mail

;; This file is part of Emacs.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:
;; This utility allows you to automatically cut regions to a fortune
;; file.  In case that the region stems from an article buffer (mail or
;; news), it will try to automatically determine the author of the
;; fortune.  It will also allow you to compile your fortune-database
;; as well as providing a function to extract a fortune for use as your
;; signature.
;; Of course, it can simply display a fortune, too.
;; Use prefix arguments to specify different fortune databases.

;;; Installation:

;; .. is easy as in most cases.  Add this file to where your
;; Emacs can find it and add
;;(autoload 'fortune "fortunesig" nil t)
;;(autoload 'fortune-add-fortune "fortunesig" nil t)
;;(autoload 'fortune-from-region "fortunesig" nil t)
;;(autoload 'fortune-compile "fortunesig" nil t)
;;(autoload 'fortune-to-signature "fortunesig" nil t)
;; to your .emacs.
;; Please check the customize settings - you will at least have to modify the
;; values of `fortune-dir' and `fortune-file'.

;; I then use this in my .gnus:
;;(message "Making new signature: %s" (fortune-to-signature "~/fortunes/"))
;; This automagically creates a new signature when starting up Gnus.
;; Note that the call to fortune-to-signature specifies a directory in which
;; several fortune-files and their databases are stored.

;; If you like to get a new signature for every message, you can also hook
;; it into message-mode:
;; (add-hook 'message-setup-hook
;;           '(lambda ()
;;              (fortune-to-signature)))      
;; This time no fortune-file is specified, so fortune-to-signature would use
;; the default-file as specified by fortune-file.

;; I have also this in my .gnus:
;;(add-hook 'gnus-article-mode-hook
;;	  '(lambda ()
;;	     (define-key gnus-article-mode-map "i" 'fortune-from-region)))
;; which allows marking a region and then pressing "i" so that the marked 
;; region will be automatically added to my favourite fortune-file.

;;; Code:

;;; **************
;;; Preliminaries
;; Incantations to make custom stuff work without customize, e.g. on
;; XEmacs 19.14 or GNU Emacs 19.34.  Stolen from htmlize.el by Hrovje Niksic.
(eval-and-compile
  (condition-case ()
      (require 'custom)
    (error nil))
  (if (and (featurep 'custom) (fboundp 'custom-declare-variable))
      nil ;; We've got what we needed
    ;; We have the old custom-library, hack around it!
    (defmacro defgroup (&rest args)
      nil)
    (defmacro defcustom (var value doc &rest args) 
      (` (defvar (, var) (, value) (, doc))))
    (defmacro defface (face value doc &rest stuff)
      `(make-face ,face))))


;;; **************
;;; Customizable Settings
(defgroup fortune nil
  "Settings for fortune."
  :group 'games)
(defgroup fortune-signature nil
  "Settings for use of fortune for signatures."
  :group 'fortune 
  :group 'mail)

(defcustom fortune-dir "~/docs/ascii/misc/fortunes/"
  "*A directory where to look for local fortune cookies files."
  :group 'fortune)
(defcustom fortune-file 
  (expand-file-name "usenet" fortune-dir)
  "*The file in which local fortune cookies will be stored."
  :group 'fortune)
(defcustom fortune-database-extension  ".dat"
  "The extension of the corresponding fortune database. 
Normally you won't have a reason to change it."
  :group 'fortune)
(defcustom fortune-program "fortune"
  "Program to select a fortune cookie."
  :group 'fortune)
(defcustom fortune-program-options ""
  "Options to pass to the fortune program."
  :group 'fortune)
(defcustom fortune-strfile "strfile"
  "Program to compute a new fortune database."
  :group 'fortune)
(defcustom fortune-strfile-options ""
  "Options to pass to the strfile program."
  :group 'fortune)
(defcustom fortune-quiet-strfile-options "> /dev/null"
  "How to supress output of strfile.
Set this to \"\" if you would like to see its results."
  :group 'fortune)
(defcustom fortune-always-compile t
  "*If set to nil, you must invoke `fortune-compile' manually."
  :group 'fortune)
(defcustom fortune-author-line-prefix "                  -- "
  "Prefix after which the name of the author will be set."
  :group 'fortune-signature)
(defcustom fortune-fill-column fill-column
  "Fill column after VALUE is reached."
  :group 'fortune-signature)
(defcustom fortune-from-mail "private e-mail"
  "String to use to characterize that the fortune comes from an e-mail.
No need to add an `in'."
  :type 'string
  :group 'fortune-signature)
(defcustom fortune-sigstart ""
  "*A fixed part to be added before the fortune cookie in the signature."
  :group 'fortune-signature)
(defcustom fortune-sigend ""
  "*A fixed part to be append after the fortune cookie in the signature."
  :group 'fortune-signature)


;; not customizable settings
(defvar fortune-buffer-name "*fortune*")
(defconst fortune-end-sep "\n%\n")  


;;; **************
;;; Inserting a new fortune
(defun fortune-append (string &optional interactive file)
  "Appends STRING to the fortune FILE. 

Expects STRING to be enclosed in quotes.  When used INTERACTIVE
doesn't compile the fortune file afterwards."
  (setq file (expand-file-name 
	      (substitute-in-file-name (or file fortune-file))))
  (if (file-directory-p file)
      (error "Cannot append fortune to directory %s." file))
  (if interactive ; switch to file and return buffer
      (find-file-other-frame file)
    (find-file-noselect file))
  (let ((fortune-buffer (get-file-buffer file)))

    (set-buffer fortune-buffer)
    (goto-char (point-max))
    (setq fill-column fortune-fill-column)
    (setq auto-fill-inhibit-regexp "^%")
    (turn-on-auto-fill)
    (insert string fortune-end-sep)
    (unless interactive
      (save-buffer)
      (if fortune-always-compile
	  (fortune-compile file)))))

(defun fortune-ask-file ()
  "Asks the user for a file-name."
  (expand-file-name 
   (read-file-name
    "Fortune file to use: "
    fortune-dir nil nil "")))
	

;;; ###autoload
(defun fortune-add-fortune (string)
  "Interactively adds STRING to a fortune file.

Expects STRING to be enclosed in quotes.  If called with a prefix asks for the
file to write the fortune to, otherwise uses the value of `fortune-file'."
  (interactive "sFortune: ")
  (if current-prefix-arg
      (fortune-append string t (fortune-ask-file))
    (fortune-append string t)))

;;; ###autoload
(defun fortune-from-region (beg end)
  "Appends the current region to a local fortune-like data file.  

If called with a prefix asks for the FILE to write the fortune to,
otherwise uses the value of `fortune-file'."
  (interactive "r")
  (let ((string (buffer-substring beg end))
	author newsgroup help-point)
    ;; try to determine author ...
    (save-excursion
      (goto-char (point-min))
      (setq help-point 
	    (search-forward-regexp
	     "^From: \\(.*\\)$"
	     (point-max) t))
      (if help-point 
	  (setq author (buffer-substring (match-beginning 1) help-point)) 
	(setq author "An unknown author")))
    ;; ... and newsgroup
    (save-excursion
      (goto-char (point-min))
      (setq help-point
	    (search-forward-regexp
	     "^Newsgroups: \\(.*\\)$"
	     (point-max) t))
      (if help-point 
	  (setq newsgroup (buffer-substring (match-beginning 1) help-point))
	(setq newsgroup (if (or (eql major-mode 'gnus-article-mode)
				(eql major-mode 'vm-mode)
				(eql major-mode 'rmail-mode))
			    fortune-from-mail
			  "unknown"))))

    ;; append entry to end of fortune file, and display result
    (setq string (concat "\"" string "\""
			 "\n"
			 fortune-author-line-prefix
			 author " in " newsgroup))
    (if current-prefix-arg
	(fortune-append string t (fortune-ask-file))
      (fortune-append string t))))


;;; **************
;;; Compile new database with strfile
;;; ###autoload
(defun fortune-compile (&optional file)
  "Compile fortune file.

If called with a prefix asks for the FILE to compile, otherwise uses
the value of `fortune-file'.  This can currently not handle directories."
  (interactive 
    (list
     (if current-prefix-arg
	 (fortune-ask-file)
       fortune-file)))
  (let* ((fortune-file (expand-file-name (substitute-in-file-name file)))
	 (fortune-dat (expand-file-name 
		       (substitute-in-file-name
			(concat fortune-file fortune-database-extension)))))
  (cond ((file-exists-p fortune-file)
	 (if (file-exists-p fortune-dat)
	     (cond ((file-newer-than-file-p fortune-file fortune-dat)
		    (message "Compiling new fortune database %s" fortune-dat)
		    (shell-command 
		     (concat fortune-strfile fortune-strfile-options
			     " " fortune-file fortune-quiet-strfile-options))))))
	(t (error "Can't compile fortune file %s." fortune-file)))))
  
	 
;;; **************
;;; Use fortune for signature
;;; ###autoload
(defun fortune-to-signature (&optional file)
  "Create signature from output of the fortune program.

If called with a prefix asks for the FILE to choose the fortune from,
otherwise uses the value of `fortune-file'.  If you want to have fortune
choose from a set of files in a directory, call interactively with prefix
and choose the directory as the fortune-file."
  (interactive 
    (list
     (if current-prefix-arg
	 (fortune-ask-file)
       fortune-file)))
   (save-excursion
    (fortune-in-buffer (interactive-p) file)
    (set-buffer fortune-buffer-name)
    (let* ((fortune (buffer-string))
	   (signature (concat fortune-sigstart fortune fortune-sigend)))
      (setq mail-signature signature)
      (if (boundp 'message-signature)
	  (setq message-signature signature)))))


;;; **************
;;; Display fortune
(defun fortune-in-buffer (interactive &optional file)
  "Puts a fortune cookie in the *fortune* buffer.

When INTERACTIVE is nil, don't display it. Optional argument FILE,
when supplied, specifies the file to choose the fortune from."
  (let ((fortune-buffer (or (get-buffer fortune-buffer-name)
			    (generate-new-buffer fortune-buffer-name)))
	(fort-file (expand-file-name
		    (substitute-in-file-name
		     (or file fortune-file)))))
    (save-excursion
      (set-buffer fortune-buffer)
      (toggle-read-only 0)
      (erase-buffer)

      (if fortune-always-compile
	  (fortune-compile fort-file))

      (call-process
        fortune-program  ;; programm to call
	nil fortune-buffer nil ;; INFILE BUFFER DISPLAYP
	(concat fortune-program-options fort-file)))))


;;; ###autoload
(defun fortune (&optional file)
  "Display a fortune cookie.

If called with a prefix asks for the FILE to choose the fortune from,
otherwise uses the value of `fortune-file'.  If you want to have fortune
choose from a set of files in a directory, call interactively with prefix
and choose the directory as the fortune-file."
  (interactive 
    (list
     (if current-prefix-arg
	 (fortune-ask-file)
       fortune-file)))
  (fortune-in-buffer t file)
  (switch-to-buffer (get-buffer fortune-buffer-name))
  (toggle-read-only 1))



;;; provide ourselves
(provide 'fortune)

;;; fortune.el ends here
