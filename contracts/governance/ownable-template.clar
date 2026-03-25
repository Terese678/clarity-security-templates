;; Title: Ownable Template
;; Author: Timothy Terese Chimbiv
;; Description: Copy this into your contract for single-owner access controls.
;; It provides one-line security for admin functions.
;; Copy this into your contract for owner controls.

;; owner storage
;; stores the current owner, sets it to whoever deploys this contract
(define-data-var contract-owner principal tx-sender)

;; error codes
(define-constant ERR-NOT-OWNER (err u200))
(define-constant ERR-ALREADY-OWNER (err u201))

;; check if caller is owner 
(define-private (is-owner)
    (is-eq tx-sender (var-get contract-owner))
)

;; asserts caller owner 
;; Guards protected functions, add (try! (assert-owner)) at the top of any admin function
(define-private (assert-owner)
    (ok (asserts! (is-owner) ERR-NOT-OWNER))
)

;; get current owner (anyone can call this function)
(define-read-only (get-owner)
    (var-get contract-owner)
)

;; transfer ownership to new owner (only owner can call)
(define-public (set-owner (new-owner principal))
    (begin
        ;; Stop anyone who is not the current owner
        (try! (assert-owner))

        ;; Reject the transfer if the new owner is already the current owner
        (asserts! (not (is-eq new-owner (var-get contract-owner))) ERR-ALREADY-OWNER)

        ;; Save the new owner
        (var-set contract-owner new-owner)
        
        (ok true)
    )
)