;; Title: Treasury
;; Author: Timothy Terese Chimbiv
;; Summary:
;; Manages DAO funds and executes financial transactions.
;; Description:
;; The treasury holds and manages all DAO assets including STX and SIP-010 tokens.
;; Only the DAO core or enabled extensions can authorize transfers. All funds are
;; held under the treasury's control using the as-contract pattern, ensuring
;; secure custody until authorized transfers are executed.

(impl-trait .extension-trait.extension-trait)
(use-trait sip010-trait .sip010-ft-trait.sip010-ft-trait)

;; ERRORS

(define-constant err-unauthorised (err u5000))
(define-constant err-transfer-failed (err u5001))
(define-constant err-invalid-amount (err u5002))

;; AUTHORIZATION CHECK 

;; Verify caller is DAO core or an enabled extension
(define-private (is-dao-or-extension)
    (ok (asserts! 
            (or 
                ;; Is caller the DAO core?
                (is-eq contract-caller .dao-core) 

                ;; Or is caller an enabled extension?
                (contract-call? .dao-core is-extension contract-caller)  
            )
            err-unauthorised
        )
    )
)

;; STX TRANSFERS

;; Transfer STX from treasury to recipient (DAO or extensions only)
(define-public (transfer-stx (amount uint) (recipient principal))
    (begin
        ;; Only DAO or extensions can transfer
        (try! (is-dao-or-extension))  

        ;; Amount must be greater than zero
        (asserts! (> amount u0) err-invalid-amount)  

        ;; Log the transfer
        (print {event: "stx-transfer", amount: amount, recipient: recipient})  

        ;; Execute transfer with treasury authority
        (as-contract (stx-transfer? amount tx-sender recipient))  
    )
)

;; SIP-010 TOKEN TRANSFERS

;; Transfer SIP-010 tokens from treasury to recipient (DAO or extensions only)
(define-public (transfer-ft (token <sip010-trait>) (amount uint) (recipient principal))
    (begin
        ;; Only DAO or extensions can transfer
        (try! (is-dao-or-extension)) 

        ;; Amount must be greater than zero 
        (asserts! (> amount u0) err-invalid-amount)  
    
        ;; Log the transfer
        (print {event: "ft-transfer", token: (contract-of token), amount: amount, recipient: recipient}) 

        ;; Execute token transfer 
        (as-contract (contract-call? token transfer amount tx-sender recipient none))  
    )
)

;; READ-ONLY FUNCTIONS

;; Get STX balance held by the treasury
(define-read-only (get-stx-balance)
    (ok (stx-get-balance (as-contract tx-sender)))
)

;; Get SIP-010 token balance held by the treasury
(define-public (get-ft-balance (token <sip010-trait>))
    (contract-call? token get-balance (as-contract tx-sender))
)

;; EXTENSION TRAIT IMPLEMENTATION

;; This required by extension-trait (currently unused)
(define-public (callback (sender principal) (memo (buff 34)))
    (ok true)
)