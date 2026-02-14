
;; Title: Ownable Trait
;; Author: Timothy Terese Chimbiv
;; Description: This trait defines the interface for single-owner access control.
;; Any contract implementing this trait can be owned and controlled
;; by a single principal.

(define-trait ownable-trait 
    (
        ;; get current owner
        (get-owner () (response principal uint))

        ;; transfer ownership
        (set-owner (principal) (response bool uint))
    )
)
