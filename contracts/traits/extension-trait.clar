
;; Title: Extension Trait
;; Author: Timothy
;; Summary:
;; Interface for DAO extensions.
;; Description:
;; Extensions add modular functionality to the DAO. The callback
;; function allows the DAO core to communicate with extensions.

(define-trait extension-trait
  (
    ;; Called by DAO core to enable/disable or configure the extension
    (callback (principal (buff 34)) (response bool uint))
  )
)
