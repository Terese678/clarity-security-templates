;; Title: DP002 Remove Operator
;; Author: Timothy Terese Chimbiv
;; Summary:
;; The example proposal showing how to remove an operator from the DAO.
;; Description:
;; Demonstrates the governance process for removing a compromised or
;; inactive operator. When approved, this proposal revokes voting rights
;; from the specified principal. Use this pattern when an operator's
;; wallet is compromised or a team member leaves the organization.

(impl-trait .proposal-trait.proposal-trait)

;; PROPOSAL EXECUTION

(define-public (execute (sender principal))
  (begin
    ;; Remove the operator
    ;; Replace this address with the actual principal to be removed
    (try! (contract-call? .operator-governance set-operators 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM false))
    
    (print {event: "operator-removed", operator: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM})
    (ok true)
  )
)