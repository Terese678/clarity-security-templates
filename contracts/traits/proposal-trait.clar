
;; Title: Proposal Trait
;; Author: Timothy Terese Chimbiv
;; Summary:
;; Interface for executable DAO proposals.
;; Description:
;; When approved by governance, proposals implement this trait 
;; to run custom logic.The DAO core calls execute() with DAO authority,
;; allowing proposals to manage funds, update parameters, or modify operators.

(define-trait proposal-trait
  (
    ;; Executes the proposal's logic when called by the DAO core
    (execute (principal) (response bool uint))
  )
)