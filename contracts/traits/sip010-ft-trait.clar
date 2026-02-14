;; Title: SIP-010 Fungible Token Standard
;; Author: Stacks Foundation
;; Summary:
;; Standard trait definition for fungible tokens on Stacks.
;; Description:
;; Defines the interface that all fungible tokens must implement
;; to be compatible with wallets, exchanges, and other contracts.

(define-trait sip010-ft-trait
  (
    ;; Transfer tokens from sender to recipient
    (transfer (uint principal principal (optional (buff 34))) (response bool uint))
    
    ;; Get name of the token
    (get-name () (response (string-ascii 32) uint))
    
    ;; Get symbol of the token
    (get-symbol () (response (string-ascii 32) uint))
    
    ;; Get number of decimals
    (get-decimals () (response uint uint))
    
    ;; Get balance of a principal
    (get-balance (principal) (response uint uint))
    
    ;; Get total supply
    (get-total-supply () (response uint uint))
    
    ;; Get token URI
    (get-token-uri () (response (optional (string-utf8 256)) uint))
  )
)
