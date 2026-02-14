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
;; AUTHORIZATION PATTERN (COPY THIS!)
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
;; PROTECTED FUNCTIONS (YOUR BUSINESS LOGIC)
;;---------------------------------------

;; Example function showing how to use the protection
;; Developers: Replace this with your own contract logic
(define-public (set-max-withdrawal (new-max uint))
    (begin
        ;; Use the protection pattern
        (try! (is-dao-or-extension))
        
        ;; Your contract logic here
        (asserts! (> new-max u0) ERR-INVALID-AMOUNT)
        (var-set max-withdrawal new-max)
        (print {event: "max-withdrawal-updated", new-max: new-max})
        (ok true)
    )
)

(define-public (toggle-pause (pause bool))
    (begin
        ;; Use the protection pattern
        (try! (is-dao-or-extension))
        
        ;; Your contract logic here
        (var-set paused pause)
        (print {event: "pause-toggled", paused: pause})
        (ok true)
    )
)

;;---------------------------------------
;; PUBLIC READ FUNCTIONS
;;---------------------------------------

(define-read-only (get-max-withdrawal)
    (ok (var-get max-withdrawal))
)

(define-read-only (is-paused)
    (ok (var-get paused))
)