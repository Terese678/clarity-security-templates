;; ============================================================
;; VERIFICATION REGISTRY
;; ============================================================
;; PURPOSE:
;; This is a decentralized registry that stores the contract-hash of every
;; verified security template. Any developer can query this registry
;; to confirm they are interacting with genuine, audited code.
;; The DAO governs what gets verified, there is no single owner and no trust required
;; ============================================================

;; ============================================================
;; ERROR CODES
;; ============================================================

(define-constant ERR-NOT-AUTHORIZED     (err u900)) ;; Caller is not the DAO contract

(define-constant ERR-ALREADY-VERIFIED   (err u901)) ;; Template hash already exists in the registry

(define-constant ERR-TEMPLATE-NOT-FOUND (err u902)) ;; No template found with this hash

(define-constant ERR-INVALID-CONTRACT   (err u903)) ;; contract-hash? failed, invalid or undeployed contract

(define-constant ERR-ALREADY-REVOKED    (err u904)) ;; Template is already inactive and can't be revoked twice

;; ============================================================
;; CONSTANTS
;; ============================================================

(define-constant REGISTRY-VERSION u1) ;; Version number of this registry that helps track upgrades over time

;; ============================================================
;; DATA MAPS
;; ============================================================

;; This is th main storage that maps each contract's unique 32-byte hash
;; to the details of that verified template
;; the hash is generated directly from the contract code by Clarity
;; so no one can fake or swap it out
(define-map verified-templates
    (buff 32)                          ;; key: the contract-hash
    {
        contract-name: (string-ascii 64),  ;; the name of this template e.g. "ownable" or "dao-core"
        verified-by:   principal,          ;; who submitted the verification (DAO)
        verified-at:   uint,               ;; unix timestamp when this template was verified
        description:   (string-utf8 256),  ;; what this template does
        is-active:     bool                ;; false means revoked
    }
)

;; Name-to-hash lookup enablesbdevelopers to search by template name
;; instead of having to know the hash upfront
(define-map template-name-to-hash
    (string-ascii 64)  ;; key: template name
    (buff 32)          ;; value: contract-hash
)

;; ============================================================
;; DATA VARIABLES
;; ============================================================

;; Running count of all verified templates ever added
(define-data-var total-verified uint u0)

;; The DAO contract address that has permission to verify and revoke templates
;; set to the deployer at first then handed over to the DAO after setup
(define-data-var dao-contract principal tx-sender)

;; ============================================================
;; PRIVATE FUNCTIONS
;; ============================================================

;; Check that the caller is the authorized DAO contract
;; we use as a guard in all state-changing functions
(define-private (is-dao-authorized)
    (is-eq contract-caller (var-get dao-contract))
)

;; ============================================================
;; PUBLIC FUNCTIONS
;; ============================================================

;; Transfer governance of this registry to the DAO contract
;; this can only be called by the current dao-contract (starts as deployer)
;; this is called once after deploying the DAO to hand over control
(define-public (set-dao-contract (new-dao principal))
    (begin
        ;; Only the current dao-contract can transfer governance
        (asserts! (is-eq tx-sender (var-get dao-contract)) ERR-NOT-AUTHORIZED)
        ;; Update the governing DAO principal
        (ok (var-set dao-contract new-dao))
    )
)

;; Verify a security template and store its hash in the registry
;; The DAO calls this after voting to approve a template
;; contract-hash? reads the actual deployed code and generates the hash
;; no one can submit a fake contract and claim it is the verified one
(define-public (verify-template
    (template-contract principal)  ;; the contract being verified
    (template-name    (string-ascii 64))   ;; the name of this template e.g. "ownable" or "dao-core"
    (description      (string-utf8 256)))  ;; what this template does
    (let 
        (
            ;; Compute the hash of the actual deployed contract code
            (template-hash (unwrap! (contract-hash? template-contract) ERR-INVALID-CONTRACT))

            ;; Check if this hash already exists in the registry
            (existing (map-get? verified-templates template-hash))
        )

        ;; Only the DAO can verify templates
        (asserts! (is-dao-authorized) ERR-NOT-AUTHORIZED)

        ;; Prevent duplicate verification of the same contract
        (asserts! (is-none existing) ERR-ALREADY-VERIFIED)

        ;; Store the verification metadata under the computed hash
        (map-set verified-templates template-hash {
            contract-name: template-name,
            verified-by:   tx-sender,
            verified-at: stacks-block-time,
            description:   description,
            is-active:     true            ;; active by default on verification
        })

        ;; Store reverse lookup so developers can find hash by name
        (map-set template-name-to-hash template-name template-hash)

        ;; Increment the total count of verified templates
        (var-set total-verified (+ (var-get total-verified) u1))

        ;; Emit an on-chain event for indexers and frontends to track
        (print {
            event:         "template-verified",
            template-name: template-name,
            template-hash: template-hash,
            verified-by:   tx-sender,
            verified-at:   stacks-block-time
        })

        ;; Return the hash so callers can store it for reference
        (ok template-hash)
    )
)

;; Revoke a previously verified template
;; Called by the DAO if a vulnerability is discovered in a template
;; it will not delete the record but marks it as inactive so history is preserved
(define-public (revoke-template (template-contract principal))
    (let 
        (
            ;; Compute the hash of the contract being revoked
            (template-hash (unwrap! (contract-hash? template-contract) ERR-INVALID-CONTRACT))

            ;; Fetch the existing record must exist to be revoked
            (template-data (unwrap! (map-get? verified-templates template-hash) ERR-TEMPLATE-NOT-FOUND))
        )
        ;; only the DAO can revoke templates
        (asserts! (is-dao-authorized) ERR-NOT-AUTHORIZED)

        ;; Cannot revoke something already revoked
        (asserts! (get is-active template-data) ERR-ALREADY-REVOKED)

        ;; Update the record merge keeps all fields, only flips is-active to false
        (map-set verified-templates template-hash
            (merge template-data { is-active: false })
        )
        ;; Emit a revocation event for transparency
        (print {
            event:         "template-revoked",
            template-name: (get contract-name template-data),
            template-hash: template-hash,
            revoked-by:    tx-sender,
            revoked-at:    stacks-block-time
        })
        (ok true)
    )
)

;; ============================================================
;; READ-ONLY FUNCTIONS
;; ============================================================

;; Any developer can call this to check if a contract is genuine and active
;; returns true if verified and active, false if not found or revoked
;; This is where Friedger's identicon integration will plug in
(define-read-only (is-verified (template-contract principal))
    (match (contract-hash? template-contract)
        ;; Hash computed successfully check the registry
        template-hash (match (map-get? verified-templates template-hash)
            ;; found in registry return whether it is still active
            template-data (ok (get is-active template-data))
            ;; but if not in registry, not verified
            (ok false)
        )
        ;; contract-hash? failed treat as not verified
        error (ok false)
    )
)

;; Get the full metadata of a verified template by passing the contract
;; returns none if the contract has never been verified
(define-read-only (get-template-details (template-contract principal))
    (match (contract-hash? template-contract)
        ;; Hash computed look up full record
        template-hash (ok (map-get? verified-templates template-hash))
        ;; could not compute hash invalid contract reference
        error (err ERR-INVALID-CONTRACT)
    )
)

;; Look up a template hash using its human readable name
;; Useful for developers who know the name but want to verify the hash
(define-read-only (get-hash-by-name (template-name (string-ascii 64)))
    (ok (map-get? template-name-to-hash template-name))
)

;; Return the total number of templates ever verified
;; includes revoked templates use is-verified to check active status
(define-read-only (get-total-verified)
    (ok (var-get total-verified))
)

;; Return the principal of the DAO contract governing this registry
(define-read-only (get-dao-contract)
    (ok (var-get dao-contract))
)

;; Return the current version of this registry contract
(define-read-only (get-registry-version)
    (ok REGISTRY-VERSION)
)