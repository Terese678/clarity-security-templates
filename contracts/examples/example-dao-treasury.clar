;; Title: DAO Treasury Example
;; Author: Timothy Terese Chimbiv
;; Description: It demonstrates how to use the ownable-template.clar 
;; providing one-line security with (try! (assert-owner))in a contract.
;; This example implements a simple treasury with owner-only withdrawals.
;; 
;; WHAT THIS CONTRACT DOES:
;; lets anyone donate STX to the treasury
;; anyone can check the treasury's balance
;; only the owner can withdraw STX from the treasury
;;
;;=======================================
;; STEP 1: IMPLEMENT THE TRAIT
;;=======================================
;; this implementation will tell clarity that this contract follows the ownable standard
(impl-trait .ownable-trait.ownable-trait)

;;=======================================
;; STEP 2: COPY AND PASTE THE ENTIRE TEMPLATE
;;=======================================
;; this is the exact code from ownable-template.clar
;; every developer copies this same code

;; owner storage
(define-data-var contract-owner principal tx-sender)

;; Error codes
(define-constant ERR-NOT-OWNER (err u100))
(define-constant ERR-ALREADY-OWNER (err u101))

;; check if caller is owner
(define-private (is-owner)
    (is-eq tx-sender (var-get contract-owner))
)

;; asserts caller is owner (used oin Admin functions)
(define-private (assert-owner)
    (ok (asserts! (is-owner) ERR-NOT-OWNER))
)

;; get current owner (anyone can call)
(define-read-only (get-owner) 
    (ok (var-get contract-owner))
)

;; transfer ownership (only owner can call)
(define-public (set-owner (new-owner principal)) 
    (begin
        ;; verify the caller is current owner
        ;; if its not owner then function stops here and returns (err u100)
        (try! (assert-owner))

        ;; prevent setting owner to same address
        ;; this ensures ownership actually changes
        (asserts! (not (is-eq new-owner (var-get contract-owner))) ERR-ALREADY-OWNER)

        ;; update the owner to new address
        ;; from this point forward new-owner has admin rights
        (var-set contract-owner new-owner)

        ;; return success 
        (ok true)
    )
)

;;=======================================
;; STEP 3: YOUR BUSINESS LOGIC
;;=======================================
;; now write your contract's unique functionality

;; your error codes
(define-constant ERR-INSUFFICIENT-FUNDS (err u200))
(define-constant ERR-INVALID-AMOUNT (err u201))

;;---------------------------------------
;; PUBLIC FUNCTION (anyone can call)
;;---------------------------------------
;; notice: no (try! (assert-owner)) here
;; this function changes state adds to treasury but is a public function
(define-public (donate (amount uint))
    (begin
        ;; validate amount
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)

        ;; transfer STX from donor to treasury
        (stx-transfer? amount tx-sender (as-contract tx-sender))
    )
)

;;---------------------------------------
;; ADMIN FUNCTION (only owner can call)
;;---------------------------------------
;; notice here: has (try! (assert-owner))
;; this function changes state removes from treasury and OWNER-ONLY can do that
(define-public (withdraw (amount uint) (recipient principal))
    (begin
        ;; SECURITY: template patter in action
        ;; if caller is not owner then function stops here
        (try! (assert-owner))

        ;; validate amount
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)

        ;; check the treasury has enough funds
        (asserts! (>= (stx-get-balance (as-contract tx-sender)) amount) ERR-INSUFFICIENT-FUNDS)

        ;; withdraw from treasury
        (as-contract (stx-transfer? amount tx-sender recipient))
    )
)

;;---------------------------------------
;; READ-ONLY FUNCTION (anyone can call)
;;---------------------------------------
;; notice: no (try! (assert-owner))
;; it's a public information that anyone can check balance
(define-read-only (get-balance)
    (ok (stx-get-balance (as-contract tx-sender)))
)



