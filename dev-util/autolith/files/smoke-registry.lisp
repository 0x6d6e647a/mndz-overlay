(require :asdf)

(let ((share (uiop:ensure-directory-pathname (second sb-ext:*posix-argv*))))
  (load (merge-pathnames ".qlot/setup.lisp" share))
  (uiop:symbol-call :ql :quickload :cffi :silent t)
  (asdf:load-asd (merge-pathnames "autolith.asd" share))
  (asdf:load-system :autolith))

(let* ((share (uiop:ensure-directory-pathname (second sb-ext:*posix-argv*)))
       (helper-root (uiop:ensure-directory-pathname (third sb-ext:*posix-argv*)))
       (workspace (uiop:ensure-directory-pathname (fourth sb-ext:*posix-argv*)))
       (configuration (autolith::make-configuration
                       :source-root helper-root :working-directory workspace
                       :provider-validation-p nil))
       (registry (autolith::make-default-tool-registry :configuration configuration))
       (search-tool (or (autolith::tool-registry-find registry "search" "files")
                        (error "Default registry lacks search.files")))
       (worker (autolith::search-tool-engine search-tool)))
  (unwind-protect
       (progn
         (assert (equal (truename share) (truename helper-root)))
         (let ((matches (autolith::search-worker-request
                         worker configuration
                         :operation :files
                         :arguments '("example.txt" :glob-p nil :page 0 :page-size 10))))
           (unless (search "example.txt" matches)
             (error "Installed search worker did not find example.txt: ~A" matches)))
         (format t "~&Default registry and installed search worker OK~%"))
    (autolith::worker-close worker)))
