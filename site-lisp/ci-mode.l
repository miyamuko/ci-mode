; -*- Mode: Lisp; Package: editor -*-

#|
= ci-mode - ����(*߁[�)����p���[�h

* Author:  MIYAMUKO Katsuyuki ((<URL:mailto:miyamuko@gmail.com>))
* URL: ((<URL:http://miyamuko.s56.xrea.com/xyzzy/ci-mode/intro.htm>))
* Version: $Id: ci-mode.l,v 1.8 2004/11/23 15:37:04 miyamuko Exp $


== ����

����(*߁[�)����p�̕ҏW���[�h�ł��B
���̂Ƃ���ȉ��̂��Ƃ��ł��܂��B

* �K���ȐF�Â�
* �L�[���[�h�̕⊮

���̂������s�ł���悤�ɂȂ��Ă�����A���Ȃ������肷�邩������܂���B


== �C���X�g�[��

((<NetInstaller|URL:http://www.mirai.ne.jp/~gyo/xyzzy/ni.html>)) �ŃC���X�g�[�������ꍇ�� 3 �ȍ~���A
NetInstaller + (({ni-autoload})) ���g���Ă���l�� 4 �ȍ~�� OK �ł��B

(1) �A�[�J�C�u���_�E�����[�h���܂��B

    ((<URL:http://miyamuko.s56.xrea.com/xyzzy/archives/ci-mode.zip>))

(2) �A�[�J�C�u��W�J���āA$XYZZY/site-lisp �z���Ƀt�@�C�����R�s�[���܂��B

(3) �g���q�� �[ �̃t�@�C�����J�����Ƃ��Ɏ����I�� ci-mode �ɂȂ�悤��
    ~/.xyzzy �܂��� $XYZZY/site-lisp/siteinit.l �Ɉȉ��̃R�[�h��ǉ����܂��B

        ;; ci-mode
        (require "ci-mode")
        (pushnew '("\\.�[$" . ci-mode) *auto-mode-alist* :test 'equal)

(4) �ݒ�𔽉f�����邽�� xyzzy ���ċN�����Ă��������B

    ��siteinit.l �ɋL�q�����ꍇ�ɂ͍ă_���v���K�v�ł��B


== ���t�@�����X

=== �L�[���蓖��

: ((%M-TAB%))
    �L�[���[�h�̕⊮�B


== ���ꂩ���邩������Ȃ�����

(1) �C���^�v���^�����B


== �֘A���邩������Ȃ��y�[�W

: �����������낤�I
    ((<URL:http://www.geocities.co.jp/SiliconValley-PaloAlto/2423/index.html>))


== ���C�Z���X

ci-mode �͏C�� BSD ���C�Z���X�Ɋ�Â��ė��p�\�ł��B

  Copyright (C) 2003-2004 MIYAMUKO Katsuyuki. All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

  1 Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer as the first lines
  of this file unmodified.

  2 Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

  THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
  OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
  SUCH DAMAGE.
|#

(provide "ci-mode")
(in-package "editor")

(export '(*ci-mode-hook*
          *ci-mode-map*
          ci-completion
          ci-mode
          ))

(defvar *ci-completion-list* nil
  "ci-mode: �⊮���X�g�̃|�b�v�A�b�v")

(defvar *ci-keyword-hash-table* nil)
(defvar *ci-keyword-file* "Ci") ; �L�[���[�h�t�@�C����
(defvar *ci-comment-regexp*
  "(�L-`).���O.*$")
(defvar *ci-keyword-char*
  "(�L-`).���O.|( ߄t�)|���Q��I( ߄D�)( ߃��)( ��ͥ)(߄D�)Ͻށ[(߄D�)�ρ[(*߃��)[ :(*߃��)< :")

(defvar *ci-regexp-keyword-list* nil
  "ci-mode: ���K�\���L�[���[�h���X�g")
(setf *ci-regexp-keyword-list*
      (compile-regexp-keyword-list
       `((,*ci-comment-regexp* t :comment)
         ("|( ߄t�)|���Q��I" t 0)
         ("|( ߄t�)|��" t 0)
         ("( ߄D�)" t 0)
         ("( ߃��)" t 0)
         ("( ��ͥ)" t 0)
         ("(߄D�)Ͻށ[" t 0)
         ("(߄D�)�ρ[" t 0)
         ("(\\*߃��)\\[ :" t 0)
         ("(\\*߃��)< :" t 0)
         )))

; �t�b�N
(defvar *ci-mode-hook* nil
  "ci-mode: �t�b�N�ϐ�")

; �V���^�b�N�X�e�[�u��
(defvar *ci-mode-syntax-table* nil)
(unless *ci-mode-syntax-table*
  (setf *ci-mode-syntax-table* (make-syntax-table))
  (do ((x #x21 (1+ x)))((>= x #x7f))
    (let ((c (code-char x)))
      (unless (alphanumericp c)
        (set-syntax-punctuation *ci-mode-syntax-table* c))))
  ; �ȉ�mode�ɍ��킹�Đݒ�
  (set-syntax-string *ci-mode-syntax-table* #\")
  (set-syntax-match *ci-mode-syntax-table* #\[ #\]))

; �L�[�}�b�v
(defvar *ci-mode-map* nil)
(unless *ci-mode-map*
  (setf *ci-mode-map* (make-sparse-keymap))
  ; �ȉ��L�[����
  (define-key *ci-mode-map* #\M-TAB 'ci-completion)
  (define-key *ci-mode-map* #\M-TAB 'ci-run))

;; ���s
(defun ci-run ()
  (interactive)
  )

(defun ci-expand-string (str vtbl)
  (if (and str vtbl)
      (ci-gsub "\\[\\(.+?\\)\\]" str
               #'(lambda ()
                   (format nil "~A" (gethash (intern (match-string 1)) vtbl))))
    str))

(defun ci-gsub (re str fn)
  (unless (and re str)
    (return-from ci-gsub str))
  (let ((result))
    (labels ((ci-gsub-internal (re str fn start)
               (if (string-match re str start)
                   (progn
                     (push (substring str start (match-beginning 0)) result)
                     (if fn (push (funcall fn (match-string 0)) result))
                     (ci-gsub-internal re str fn (match-end 0)))
                 (push (substring str start) result))))
      (ci-gsub-internal re str fn 0))
    (format nil "~{~A~}" (reverse result))))

(defvar *ci-keyword-list*
  '("|( ߄t�)|��"
    "( ߄D�)"
    "( ߃��)"
    "( ��ͥ)"
    "(߄D�)Ͻށ["
    "(߄D�)�ρ["
    "(\\*߃��)\\[ :"
    "(\\*߃��)< :"))


(define-condition ci-parse-error (simple-error) (file line column message)
  (:report (lambda (c s)
             (format s "~A:~D: ~A"
                     (ci-parse-error-file c)
                     (ci-parse-error-line c)
                     (ci-parse-error-message c)))))

(defun ci-parse-number (in)
  (ci-parse-type (in 'numberp "��������Ȃ��݂���")))

(defun ci-parse-string (in)
  (ci-parse-type (in 'stringp "�����񂶂�Ȃ��݂���")))

(defun ci-parse-type (in typep msg)
  (let ((result (read in)))
    (if (funcall typep result)
        result
      (progn
        (set-buffer (buffer-stream-buffer in))
        (error 'ci-parse-error
               :file (get-buffer-file-name (selected-buffer))
               :line (current-line-number)
               :message msg)))))

;; popup �⊮
(defvar *ci-mode-abbrev-table* nil)
(unless *ci-mode-abbrev-table*
  (define-abbrev-table '*ci-mode-abbrev-table*))
(defun ci-completion ()
  "ci-mode: �⊮"
  (interactive)
  (or *ci-completion-list*
      (setf *ci-completion-list* (make-list-from-keyword-table
                                  *ci-keyword-hash-table*))
      (return-from ci-completion nil))
  (let ((opoint (point)))
    (skip-chars-backward *ci-keyword-char*)
    (skip-chars-forward " ")
    (if (< opoint (point)) (goto-char opoint))

    (let ((from (point)))
      (goto-char opoint)
      ; :list-ignore-case=�⊮�ő啶������������ʂ��Ȃ�, :list=����
      (do-completion from opoint :list-ignore-case *ci-completion-list*
                     nil nil *ci-completion-list* ; xyzzy 0.2.2.211�ȑO���g���ꍇ�̓R�����g�A�E�g
                     ))))

(defun ci-mode ()
  "ci-mode"
  (interactive)
  (kill-all-local-variables)
  (setf mode-name "*߁[�")
  (setf buffer-mode 'ci-mode)
  (use-syntax-table *ci-mode-syntax-table*)
  (use-keymap *ci-mode-map*)

  ; ����W�J
  (setf *local-abbrev-table* *ci-mode-abbrev-table*)

  (make-local-variable 'paragraph-start)
  (setf paragraph-start "^$\\|\f") ; forward|backward-paragraph �ňړ�����i���ʒu
  (make-local-variable 'paragraph-separate)
  (setf paragraph-separate paragraph-start)

  ; keyword
  (and *ci-keyword-file*
       (null *ci-keyword-hash-table*)
       (setf *ci-keyword-hash-table*
             (load-keyword-file *ci-keyword-file* t))) ; t=�啶������������ʂ��Ȃ�, nil=����
  (when *ci-keyword-hash-table*
    (make-local-variable 'keyword-hash-table)
    (setf keyword-hash-table *ci-keyword-hash-table*))
  (make-local-variable 'regexp-keyword-list)
  (setf regexp-keyword-list *ci-regexp-keyword-list*)

  ; �t�b�N�̎��s
  (run-hooks '*ci-mode-hook*))