;; Title: DAO Governance Example
;; Author: Timothy Terese Chimbiv
;; Summary:
;; Shows how to protect functions with DAO governance.
;; Description:
;; Functions with the one-line DAO check can only be called through
;; approved governance proposals that pass the 2-of-3 operator threshold.

;; Error code
(define-constant ERR-NOT-DAO (err u100))
(define-constant ERR-INVALID-AMOUNT (err u200))

;; Contract data
(define-data-var treasury-limit uint u1000000)
(define-data-var emergency-contact principal tx-sender)

;;---------------------------------------
;; DAO-PROTECTED FUNCTIONS
;;---------------------------------------

(define-public (set-treasury-limit (new-limit uint))
    (begin
        ;; ONE-LINE DAO PROTECTION 
        (asserts! (is-eq contract-caller .dao-core) ERR-NOT-DAO)
        
        (asserts! (> new-limit u0) ERR-INVALID-AMOUNT)
        (var-set treasury-limit new-limit)
        (print {event: "limit-updated", new-limit: new-limit})
        (ok true)
    )
)

(define-public (set-emergency-contact (new-contact principal))
    (begin
        ;; ONE-LINE DAO PROTECTION 
        (asserts! (is-eq contract-caller .dao-core) ERR-NOT-DAO)
        
        (var-set emergency-contact new-contact)
        (print {event: "contact-updated", new-contact: new-contact})
        (ok true)
    )
)

;;---------------------------------------
;; PUBLIC READ FUNCTIONS
;;---------------------------------------

(define-read-only (get-treasury-limit)
    (ok (var-get treasury-limit))
)

(define-read-only (get-emergency-contact)
    (ok (var-get emergency-contact))
)