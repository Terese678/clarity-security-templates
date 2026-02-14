
;; Title: Multi-Sig Trait
;; Author: Timothy Terese Chimbiv
;; Summary:
;; Interface for multi-signature governance.
;; Description:
;; It enables threshold-based voting where multiple operators must approve
;; actions. No single operator can act alone, creating a self-correcting
;; governance system for team wallets and DAO administration.

(define-trait multi-sig
  (
    ;; Returns true if the principal is an authorized operator
    (is-operator (principal) (response bool uint))
    
    ;; Creates a new proposal for operators to vote on
    (create-proposal ((string-ascii 256) principal) (response uint uint))
    
    ;; Vote to approve or reject a proposal. Will execute if threshold is met.
    (signal (uint bool principal) (response bool uint))
    
    ;; If the proposal was approved and executed, it returns true 
    (is-proposal-approved (uint) (response bool uint))
  )
)