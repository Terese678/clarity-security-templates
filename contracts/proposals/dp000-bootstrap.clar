;; Title: DP000 Bootstrap
;; Author: Timothy Terese Chimbiv
;; Summary:
;; Bootstrap proposal that initializes the DAO with 3 operators.
;; Description:
;; This proposal runs once at DAO deployment to set up the initial
;; governance structure. It enables the operator-governance and treasury
;; extensions, then sets the 3 initial operators who can vote on proposals.

(impl-trait .proposal-trait.proposal-trait)

;; PROPOSAL EXECUTION

(define-public (execute (sender principal))
  (begin
    ;; Step 1: Enable operator-governance extension
    (try! (contract-call? .dao-core set-extension .operator-governance true))
    
    ;; Step 2: Enable treasury extension
    (try! (contract-call? .dao-core set-extension .treasury true))
    
    ;; Step 3: Set the 3 initial operators
    (try! (contract-call? .operator-governance set-operators 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM true))
    (try! (contract-call? .operator-governance set-operators 'ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB true))
    (try! (contract-call? .operator-governance set-operators 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND true))
    
    (print {event: "dao-initialized", operators: u3})
    (ok true)
  )
)