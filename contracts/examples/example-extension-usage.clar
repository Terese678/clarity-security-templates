;; Title: Extension Usage Example
;; Author: Timothy Terese Chimbiv
;; Summary:
;; Shows how to allow both DAO and extensions to call your contract.
;; Description:
;; When building contracts that are part of a larger DAO-managed system
;; (like DeFi protocols, reward systems, or multi-contract applications),
;; you may need to allow BOTH the DAO core AND its enabled extensions
;; to interact with your contract. Copy this pattern into your own contract.

;; Error codes (developers copy these)
(define-constant ERR-UNAUTHORISED (err u2100))
(define-constant ERR-INVALID-AMOUNT (err u2101))

;; Example contract data (developers replace with their own)
(define-data-var max-withdrawal uint u500000)
(define-data-var paused bool false)

;;---------------------------------------
;; READ-ONLY FUNCTIONS
;;---------------------------------------

;; Returns the maximum amount allowed for a single withdrawal
(define-read-only (get-max-withdrawal)
    (var-get max-withdrawal)
)

;; Returns whether the contract is currently paused or active
(define-read-only (is-paused)
    (var-get paused)
)

;;---------------------------------------
;; AUTHORIZATION PATTERN 
;;---------------------------------------

;; Developers: Copy this function into your contract
;; This allows BOTH dao-core AND any enabled extension to call your functions
(define-private (is-dao-or-extension)
    (ok (asserts! 
        (or 
            (is-eq contract-caller .dao-core)  ;; Is the caller dao-core?
            (contract-call? .dao-core is-extension contract-caller)  ;; Or an enabled extension?
        )
        ERR-UNAUTHORISED
    ))
)

;;---------------------------------------
;; PROTECTED FUNCTIONS 
;;---------------------------------------

;; Example function showing how to use the protection
;; Developers: Replace this with your own contract logic
(define-public (set-max-withdrawal (new-max uint))
    (begin
        ;; Block anyone who is not the DAO or an approved extension
        (try! (is-dao-or-extension))
        
        ;; Your contract logic here
        ;; reject zero, a zero limit would block all withdrawals
        (asserts! (> new-max u0) ERR-INVALID-AMOUNT)

        ;; Save the new withdrawal limit
        (var-set max-withdrawal new-max)

        (print {event: "max-withdrawal-updated", new-max: new-max})
        (ok true)
    )
)

;; This function pauses or unpauses the contract used during emergencies or maintenance
(define-public (toggle-pause (pause bool))
    (begin
        ;; Always start with this protection line
        ;; it ensures that only the DAO or an approved extension can call this function
        (try! (is-dao-or-extension))
        
        ;; Your contract logic goes below this line
        ;; everything here is protected because of the line above
        (var-set paused pause)

        (print {event: "pause-toggled", paused: pause})
        (ok true)
    )
)
