;;=======================================
;; OWNABLE TRAIT v1.0
;; Author: Timothy Terese Chimbiv
;;=======================================

(define-trait ownable-trait 
    (
        ;; get current owner
        (get-owner () (response principal uint))

        ;; transfer ownership
        (set-owner (principal) (response bool uint))
    )
)
