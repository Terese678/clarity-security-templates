;; Title: DP001 Add Operator
;; Author: Timothy Terese Chimbiv
;; Summary:
;; This is the example proposal showing how to add a new operator to the DAO.
;; Description:
;; Demonstrates the governance process for expanding the operator set.
;; When approved by the existing operators, this proposal grants voting
;; rights to a new trusted principal. Use this pattern when onboarding
;; new team members or expanding DAO governance.

(impl-trait .proposal-trait.proposal-trait)

;; PROPOSAL EXECUTION

(define-public (execute (sender principal))
  (begin
    ;; Add the new operator
    ;; Note: replace this address with the actual principal to be added
    (try! (contract-call? .operator-governance set-operators 'ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB true))
    
    (print {event: "operator-added", operator: 'ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB})
    (ok true)
  )
)