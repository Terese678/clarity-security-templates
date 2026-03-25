;; Title: DP002 Remove Operator
;; Author: Timothy Terese Chimbiv
;; Summary:
;; The example proposal showing how to remove an operator from the DAO.
;; Description:
;; Demonstrates the governance process for removing a compromised or
;; inactive operator. When approved, this proposal revokes voting rights
;; from the specified principal. Use this pattern when an operator's
;; wallet is compromised or a team member leaves the organization.

;; This contract is a proposal 
;; it gets submitted to the DAO and executed only after the required operators approve it
(impl-trait .proposal-trait.proposal-trait)

;; PROPOSAL EXECUTION

(define-public (execute (sender principal))
    (begin
        ;; completely removes this address from the DAO 
        ;; they lose all voting, proposal creation, and execution rights
        ;; change this address to whoever you want to remove
        (try! (contract-call? .operator-governance set-operators 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM false))
    
        (print {event: "operator-removed", operator: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM})
        (ok true)
    )
)