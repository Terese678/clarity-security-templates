;; Title: DP003 Transfer STX
;; Author: Timothy Terese Chimbiv
;; Summary:
;; Example proposal showing how to transfer STX from the DAO treasury.
;; Description:
;; Demonstrates the governance process for moving funds. When approved
;; by the required operator threshold, this proposal executes a transfer
;; from the DAO treasury to a specified recipient. Use this pattern for
;; paying contractors, funding initiatives, or distributing treasury assets.

(impl-trait .proposal-trait.proposal-trait)

;; PROPOSAL EXECUTION

(define-public (execute (sender principal))
  (begin
    ;; Transfer 1000 STX (1,000,000 micro-STX) from treasury to recipient
    ;; Replace the amount and recipient address with actual values
    (try! (contract-call? .treasury transfer-stx u1000000 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND))
    
    (print {event: "stx-transferred", amount: u1000000, recipient: 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND})
    (ok true)
  )
)