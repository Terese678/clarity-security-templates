;; Title: Ownable Template
;; Author: Timothy Terese Chimbiv
;; Description: Copy this into your contract for single-owner access controls.
;; It provides one-line security for admin functions.
;; Copy this into your contract for owner controls.

;; owner storage
(define-data-var contract-owner principal tx-sender)

;; error codes
(define-constant ERR-NOT-OWNER (err u200))
(define-constant ERR-ALREADY-OWNER (err u201))

;; check if caller is owner 
(define-private (is-owner)
    (is-eq tx-sender (var-get contract-owner))
)

;; asserts caller owner (use this in functions)
(define-private (assert-owner)
    (ok (asserts! (is-owner) ERR-NOT-OWNER))
)

;; get current owner (anyone can call this function)
(define-read-only (get-owner)
    (ok (var-get contract-owner))
)

;; transfer ownership to new owner (only owner can call)
(define-public (set-owner (new-owner principal))
    (begin
        (try! (assert-owner))

        (asserts! (not (is-eq new-owner (var-get contract-owner))) ERR-ALREADY-OWNER)
        (var-set contract-owner new-owner)
        (ok true)
    )
)