;; Author: Timothy Terese Chimbiv

;; for the contract to be recognized as a rules contract it must implement this
;; interface with the same signature with "is-allowed" 

(define-trait security-rules-trait
    (
        ;; whatever request data has been inputed it evaluates it 
        ;; if its permitted or not, if its an allowed action then it permits
        (is-allowed ((buff 2048)) (response bool uint))
    )
)
