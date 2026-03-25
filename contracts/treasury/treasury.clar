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

;; READ-ONLY FUNCTION

;; Get STX balance held by the treasury
(define-read-only (get-stx-balance)
    (ok (stx-get-balance tx-sender))
)

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
        
        ;; Execute transfer
        (try! (stx-transfer? amount tx-sender recipient))

        ;; Log the transfer
        (print {event: "stx-transfer", amount: amount, recipient: recipient})

        (ok true)
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

        ;; Execute token transfer
        (try! (contract-call? token transfer amount tx-sender recipient none))

        ;; Log the transfer
        (print {event: "ft-transfer", token: (contract-of token), amount: amount, recipient: recipient})

        (ok true)
    )
)

;; EXTENSION TRAIT IMPLEMENTATION
;; extension-trait requires all extensions to implement a callback function.
;; This treasury does not use it but it must be here to satisfy the trait.
;; The DAO core can call this function to send notifications to extensions.
(define-public (callback (sender principal) (memo (buff 34)))
    (ok true)
)

;; Get SIP-010 token balance held by the treasury
(define-public (get-ft-balance (token <sip010-trait>))
    (contract-call? token get-balance tx-sender)
)
