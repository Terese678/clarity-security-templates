;; Title: DP003 Transfer STX
;; Author: Timothy Terese Chimbiv
;; Summary:
;; Example proposal showing how to transfer STX from the DAO treasury.
;; Description:
;; Demonstrates the governance process for moving funds. When approved
;; by the required operator threshold, this proposal executes a transfer
;; from the DAO treasury to a specified recipient. Use this pattern for
;; paying contractors, funding initiatives, or distributing treasury assets.

;; This contract is a proposal
;; it gets submitted to the DAO and only executes after the required operators approve it
(impl-trait .proposal-trait.proposal-trait)

;; PROPOSAL EXECUTION
(define-public (execute (sender principal))
    (begin
        ;; Example: transfer STX from treasury
        ;; In production, replace with actual contract call:
        ;; (try! (contract-call? .treasury transfer-stx u1000000 'RECIPIENT-ADDRESS))
        (print {event: "stx-transferred", amount: u1000000, recipient: sender})
        (ok true)
    )
)