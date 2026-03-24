;; Title: DAO Core
;; Author: Timothy Terese Chimbiv
;; Summary:
;; The execution engine for the DAO.
;; Description:
;; It manages extensions and executes approved proposals with DAO authority.
;; Extensions are contracts that implement the extension-trait and add
;; functionality like governance or treasury management. Only enabled
;; extensions can execute proposals through the DAO.

(impl-trait .extension-trait.extension-trait)
(use-trait proposal-trait .proposal-trait.proposal-trait)

;; ERRORS

(define-constant err-unauthorised (err u3000))
(define-constant err-already-executed (err u3001))
(define-constant err-invalid-extension (err u3002))

;; DATA STORAGE

;; Track if DAO has been initialized
(define-data-var initialized bool false)

;; Stores enabled extensions
(define-map extensions principal bool)

;; Prevents proposals from executing twice
(define-map executed-proposals principal bool)

;; The extensions must be enabled via construct() or proposal execution
;; No extensions are enabled at deployment

;; AUTHORIZATION CHECKS

;; Returns true if the contract is an enabled extension
(define-read-only (is-extension (extension principal))
    (default-to false (map-get? extensions extension))
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
            (sender tx-sender)
        )
        ;; Can only be called once by the deployer
        (asserts! (is-eq (var-get initialized) false) err-already-executed)
    
        ;; Mark as initialized
        (var-set initialized true)
    
        ;; Execute the bootstrap proposal with DAO authority
        (as-contract (execute proposal sender))
    )
)

;; EXTENSION MANAGEMENT

;; Extensions are modular contracts that add functionality to the DAO.
;; They must be enabled before they can interact with the core.
;; Disabling an extension immediately revokes its access.

;; Enable or disable a single extension (DAO or extensions only)
(define-public (set-extension (extension principal) (enabled bool))
    (begin
        ;; only DAO or extensions can modify extensions
        (try! (is-self-or-extension))  

        ;; log the change
        (print {event: "extension", extension: extension, enabled: enabled}) 

        ;; update the extension's status 
        (ok (map-set extensions extension enabled))  
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
        ;; Log each change
        (print {event: "extension", extension: (get extension item), enabled: (get enabled item)})

        ;; Update each extension's status  
        (map-set extensions (get extension item) (get enabled item))  
    )
)

;; PROPOSAL EXECUTION

;; Execute a proposal with DAO authority (extensions only)
(define-public (execute (proposal <proposal-trait>) (sender principal))
    (begin
        (try! (is-self-or-extension))  ;; Only DAO or extensions can execute proposals
    
        ;; Prevent executing the same proposal twice
        (asserts! (is-none (map-get? executed-proposals (contract-of proposal))) err-already-executed)
    
        ;; Mark proposal as executed
        (map-set executed-proposals (contract-of proposal) true)  

        ;; Log execution
        (print {event: "execute", proposal: proposal, sender: sender}) 

        ;; Run proposal with DAO authority 
        (as-contract (contract-call? proposal execute sender))  
    )
)

;; EXTENSION TRAIT IMPLEMENTATION

;; Required by extension-trait (currently unused)
(define-public (callback (sender principal) (memo (buff 34)))
    (ok true)
)

;; READ-ONLY HELPERS

;; Check if a proposal has been executed
(define-read-only (executed-at (proposal principal))
    (map-get? executed-proposals proposal)
)
