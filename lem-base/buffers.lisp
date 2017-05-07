(in-package :lem-base)

(annot:enable-annot-syntax)

(export '(kill-buffer-hook
          buffer-list
          any-modified-buffer-p
          get-buffer
          uniq-buffer-name
          update-prev-buffer
          bury-buffer
          get-next-buffer
          get-previous-buffer
          delete-buffer
          get-file-buffer))

(define-editor-variable kill-buffer-hook '())

(defvar *buffer-list* '())

(defun add-buffer (buffer)
  (check-type buffer buffer)
  (assert (not (get-buffer (buffer-name buffer))))
  (push buffer *buffer-list*))

(defun buffer-list ()
  @lang(:jp "`buffer`のリストを返します。")
  *buffer-list*)

(defun any-modified-buffer-p ()
  (find-if (lambda (buffer)
             (and (buffer-filename buffer)
                  (buffer-modified-p buffer)))
           (buffer-list)))

(defun get-buffer (buffer-or-name)
  @lang(:jp "`buffer-or-name`がバッファならそのまま返し、
文字列ならその名前のバッファを返します。")
  (if (bufferp buffer-or-name)
      buffer-or-name
      (find-if #'(lambda (buffer)
                   (string= buffer-or-name
                            (buffer-name buffer)))
               (buffer-list))))

(defun uniq-buffer-name (name)
  (if (null (get-buffer name))
      name
      (do ((n 1 (1+ n))) (nil)
        (let ((name (format nil "~a<~d>" name n)))
          (unless (get-buffer name)
            (return name))))))

(defun update-prev-buffer (buffer)
  (check-type buffer buffer)
  (setq *buffer-list*
        (cons buffer
              (remove buffer (buffer-list)))))

(defun delete-buffer (buffer)
  @lang(:jp "`buffer`をバッファのリストから消します。
エディタ変数`kill-buffer-hook`がバッファが消される前に実行されます。")
  (check-type buffer buffer)
  (alexandria:when-let ((hooks (variable-value 'kill-buffer-hook :buffer buffer)))
    (run-hooks hooks buffer))
  (alexandria:when-let ((hooks (variable-value 'kill-buffer-hook :global)))
    (run-hooks hooks buffer))
  (buffer-free buffer)
  (setf *buffer-list* (delete buffer (buffer-list))))

(defun get-next-buffer (buffer)
  @lang(:jp "バッファリスト内にある`buffer`の次のバッファを返します。")
  (check-type buffer buffer)
  (let* ((buffer-list (buffer-list))
         (res (member buffer buffer-list)))
    (cadr res)))

(defun get-previous-buffer (buffer)
  @lang(:jp "バッファリスト内にある`buffer`の前のバッファを返します。")
  (check-type buffer buffer)
  (loop :for prev := nil :then curr
        :for curr :in (buffer-list)
        :do (when (eq buffer curr)
              (return prev))))

(defun bury-buffer (buffer)
  @lang(:jp "`buffer`をバッファリストの一番最後に移動させ、バッファリストの先頭を返します。")
  (check-type buffer buffer)
  (setf *buffer-list*
        (append (remove buffer (buffer-list))
                (list buffer)))
  (car (buffer-list)))

(defun get-file-buffer (filename)
  @lang(:jp "`filename`に対応するバッファを返します。
見つからなければNILを返します。")
  (dolist (buffer (buffer-list))
    (when (uiop:pathname-equal filename (buffer-filename buffer))
      (return buffer))))
