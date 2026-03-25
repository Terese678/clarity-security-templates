;; Title: DAO Core
;; Author: Timothy Terese Chimbiv
;; Summary:
;; The execution engine for the DAO.
;; Description:
;; It manages extensions and executes approved proposals with DAO authority.
;; Extensions are contracts that implement the extension-trait and add
;; functionality like governance or treasury management. Only enabled
;; extensions can execute proposals through the DAO.

;; dao-core implements extension-trait so it can be called back
;; by extensions that need to notify the core via the callback hook
(impl-trait .extension-trait.extension-trait)
(use-trait proposal-trait .proposal-trait.proposal-trait)

;; ERRORS

(define-constant err-unauthorised (err u3000))
(define-constant err-already-executed (err u3001))
(define-constant err-invalid-extension (err u3002))

;; DATA STORAGE

;; Track if DAO has been initialized
(define-data-var initialized bool false)

;; At the moment this contract goes live, the deployer 
;; address at the deployed moment is locked in, once st, this cannot be changed
(define-data-var deployer principal tx-sender)

;; Stores enabled extensions
(define-map extensions principal bool)

;; Prevents proposals from executing twice
(define-map executed-proposals principal bool)

;; This DAO starts with no active extensions (no extra powers enabled)
;; Every feature must be officially approved by the community through a proposal
;; This prevents the founder from quietly granting themselves powers at the start

;; AUTHORIZATION CHECKS

;; If the contract is an enabled extension,  Returns true 
(define-read-only (is-extension (extension principal))
    (default-to false (map-get? extensions extension))
)

;; Check if a proposal has been executed
;; Used by extensions to authorize callbacks from proposals run by the DAO
(define-read-only (is-executed-proposal (proposal principal))
    (default-to false (map-get? executed-proposals proposal))
)

;; Fetch the wallet address that first deployed this DAO
(define-read-only (get-deployer)
    (var-get deployer)
)

;; Verify caller is an enabled extension or the DAO core itself
(define-private (is-self-or-extension)
    (ok (asserts!
        (is-extension contract-caller)
        err-unauthorised
    ))
)

;; INITIALIZATION

;; Initialize the DAO with a bootstrap proposal (one-time only)
(define-public (construct (proposal <proposal-trait>))
    (let
        (
            ;; Capture the deployer's address to pass through to the proposal
            (sender tx-sender)
        )

        ;; Only the original deployer can initialize the DAO
        (asserts! (is-eq tx-sender (var-get deployer)) err-unauthorised)

        ;; Can only be called once prevents anyone from re-initializing
        (asserts! (is-eq (var-get initialized) false) err-already-executed)

        ;; Mark as initialized before execution to prevent reentrancy
        (var-set initialized true)

        ;; Temporarily enable the bootstrap proposal so it can call set-extension
        (map-set extensions (contract-of proposal) true)

        ;; Call the proposal directly with DAO authority
        (try! (contract-call? proposal execute sender))

        ;; Revoke bootstrap proposal's extension privileges after execution
        (ok (map-set extensions (contract-of proposal) false))
    )
)

;; EXTENSION MANAGEMENT

;; Extensions are modular contracts that add functionality to the DAO.
;; They must be enabled before they can interact with the core.
;; Disabling an extension immediately revokes its access.

;; Enable or disable a single extension (DAO or extensions only)
(define-public (set-extension (extension principal) (enabled bool))
    (begin
        ;; Only DAO or extensions can modify extensions
        (try! (is-self-or-extension))

        ;; Update the extension's status first
        (map-set extensions extension enabled)

        ;; Then log the change on-chain
        (print {event: "extension", extension: extension, enabled: enabled})

        (ok true)
    )
)

;; Enable or disable multiple extensions in a single call
;; Used by bootstrap proposals to initialize the DAO in one transaction
(define-public (set-extensions (extension-list (list 200 {extension: principal, enabled: bool})))
    (begin
        ;; Only DAO or extensions can modify extensions
        (try! (is-self-or-extension))

        ;; Process each extension in the list
        (ok (map set-extension-iter extension-list))
    )
)

;; Processes a single item from the set-extensions list
(define-private (set-extension-iter (item {extension: principal, enabled: bool}))
    (begin
        ;; Update each extension's status first
        (map-set extensions (get extension item) (get enabled item))

        ;; Then log each change on-chain
        (print {event: "extension", extension: (get extension item), enabled: (get enabled item)})
    )
)

;; PROPOSAL EXECUTION

;; Execute a proposal with DAO authority (extensions only)
(define-public (execute (proposal <proposal-trait>) (sender principal))
    (begin
        ;; Only DAO or extensions can execute proposals
        (try! (is-self-or-extension))

        ;; Prevent executing the same proposal twice
        (asserts! (is-none (map-get? executed-proposals (contract-of proposal))) err-already-executed)

        ;; Mark proposal as executed before running it
        (map-set executed-proposals (contract-of proposal) true)

        ;; Run the proposal and return the result
        (try! (contract-call? proposal execute sender))

        ;; Log execution after it succeeds
        (print {event: "execute", proposal: proposal, sender: sender})

        (ok true)

    )
)

;; EXTENSION TRAIT IMPLEMENTATION

;; Required by extension-trait (currently unused)
(define-public (callback (sender principal) (memo (buff 34)))
    (ok true)
)