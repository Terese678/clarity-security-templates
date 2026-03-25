;; Title: DAO Governance Example
;; Author: Timothy Terese Chimbiv
;; Summary:
;; Shows how to protect functions with DAO governance.
;; Description:
;; Functions with the one-line DAO check can only be called through
;; approved governance proposals that pass the 2-of-3 operator threshold.

;; Error code
(define-constant ERR-NOT-DAO (err u2000))
(define-constant ERR-INVALID-AMOUNT (err u2001))

;; Contract data
(define-data-var treasury-limit uint u1000000)
(define-data-var emergency-contact principal tx-sender)

;;---------------------------------------
;; READ-ONLY FUNCTIONS
;;---------------------------------------

;; Returns the current maximum amount the treasury is allowed to move at once
(define-read-only (get-treasury-limit)
    (var-get treasury-limit)
)

;; Returns the wallet address currently set as the emergency contact
(define-read-only (get-emergency-contact)
    (var-get emergency-contact)
)

;;---------------------------------------
;; DAO-PROTECTED FUNCTIONS
;;---------------------------------------

;; Updates the maximum amount the treasury is allowed to move at once
;; It's only the DAO itself that can call this not any individual wallet
(define-public (set-treasury-limit (new-limit uint))
    (begin
        ;; Block anyone who isn't the DAO core contract from making this change
        (asserts! (is-eq contract-caller .dao-core) ERR-NOT-DAO)
        
        ;; Reject zero, a zero limit would freeze all treasury activity
        (asserts! (> new-limit u0) ERR-INVALID-AMOUNT)

        ;; Save the new limit
        (var-set treasury-limit new-limit)

        ;; Record this change on-chain so it's publicly visible and auditable
        (print {event: "limit-updated", new-limit: new-limit})
        (ok true)
    )
)

;; Changes who gets notified when something goes wrong in the DAO
;; the whole community must approve this, no one person can change it alone
(define-public (set-emergency-contact (new-contact principal))
    (begin
        ;; Block anyone who isn't the DAO core contract from making this change
        (asserts! (is-eq contract-caller .dao-core) ERR-NOT-DAO)
        
        ;; Save the new contact address
        (var-set emergency-contact new-contact)

        ;; Record this change on-chain so it's publicly visible and auditable
        (print {event: "contact-updated", new-contact: new-contact})
        (ok true)
    )
)

