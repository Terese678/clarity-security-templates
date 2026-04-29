;; Author: Timothy Chimbiv

;; Every verified template, their contract hash is saved here in this registry, a developer using the
;; template can check it to see if its the audited untampered code they're interacting with. 
;; its quite impossible to fake a the hash because the contract-hash? protects it

;; --------------------Errors-----------------

(define-constant ERR_NOT_AUTHORIZED (err u900)) ;; When someone tries to perform an action
;; they're not permitted to

(define-constant ERR_ALREADY_VERIFIED (err u901)) ;; You can not add the same template to the registry
;; twice

(define-constant ERR_NOT_FOUND (err u902)) ;; No verified template found

(define-constant ERR_NOT_CONTRACT (err u903)) ;; If the contract-hash? can not read the contract
;; it probably not a verified or does not exist.

;; ------------ STORAGE-------------------

;; Data var
;; Whoever is incharge of this registry their address
;; is stored here. this is transferrable to wallet later on
(define-data-var contract-owner principal tx-sender) 

;; Data map
;; This tracks the code-hash of the contract to see if its active
;; being true means its safe to use "verified"
(define-map verified-templates { code-hash: (buff 32) } { active: bool })

;; ------------ Read-only Functions ---------------

;; Check who is currently controlling this registry
(define-read-only (get-contract-owner)
    (var-get contract-owner)
)

;; This will help a developer check if they hash they have is a verified and active
;; Probably you have a code-hash of the contract and you want to check 
;; if its verified and active
(define-read-only (is-hash-verified (code-hash (buff 32)))
    (match (map-get? verified-templates { code-hash: code-hash}) 
        template-record 
            (get active template-record) 
                false
    )
)

;; "is-verified"
;; This is the actual function that confirms the authencity of the template
;; developers will call this to be sure its not fake
;; it will get the hash of the code thats been deployed
(define-read-only (is-verified (contract-principal principal))
    (match (contract-hash? contract-principal) 
        code-hash 
            (get active 
                (default-to { active: false } 
                    (map-get? verified-templates { code-hash: code-hash })
                )
            ) 
        err-code false
    )
) ;; so even the hash is found in the map or not default to to fallback to which is a tuple
;; since the map is also a tuple the types are not mixed up

;; ------------Public Function----------------

;; Verify-template

;; Verified template is added here
(define-public (verify-template (template-contract principal))
    (let
        (
            ;; Generate the hash from the contract code thats been deployed
            ;; but if the contract-hash? cannot find then it does not exist
            (code-hash (unwrap! (contract-hash? template-contract) ERR_NOT_CONTRACT))
        )

        ;; The person adding a template must be the current owner
        ;; if not, any random caller can verify actions they're not allowed to
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)

        ;; This template should be verified only once
        ;; if the same hash comes up again the logic will fail with error
        (asserts! 
            (is-none (map-get? verified-templates { code-hash: code-hash })) 
            ERR_ALREADY_VERIFIED
        )

        ;; If the hash is authentic then add it to the registry, its now safe
        (map-set verified-templates { code-hash: code-hash } { active: true })

        ;; Record the event on chain, any one can see its verified
        (print { event: "template-verified", code-hash: code-hash})

        (ok true)
    )
)

;; Revoke-template
;; The template is revoked when something goes wrong, marking it as inactive
(define-public (revoke-template (template-contract principal))
    (let
        (
            ;; Get the hash of the revoked template
            (code-hash (unwrap! (contract-hash? template-contract) ERR_NOT_CONTRACT))
        )

        ;; Only the owner can revoke, this is the same logic as verify template
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)

        ;; Only verified template can be revoked to keep the registry clean
        (asserts! (is-some (map-get? verified-templates { code-hash: code-hash })) ERR_NOT_FOUND)

        ;; Record this template as not active: false
        ;; don't delete it, let the history remain in registry
        ;; any developer who calls will only get false
        (map-set verified-templates { code-hash: code-hash } { active: false })

        ;; Mark it as revoked so any on chain will understand its no longer a safe template
        (print { event: "template-revoked", code-hash: code-hash })

        (ok true)
    )
)

;; This transfers control of the registry to the multi-sig once the wallet
;; is set up so no single person can have access
;; this is done only once
(define-public (set-contract-owner (new-owner principal))
    (begin
        ;; Only the owner can transfer control
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)

        ;; Update the owner to the new principal
        (var-set contract-owner new-owner)

        (ok true)
    )
)