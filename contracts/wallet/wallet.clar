;;Author: Timothy Terese Chimbiv

;; This contract handles all admin checks that should pass 
;; before any action is executed such that no single admin is incharge
;; Here's the deploy order: security-rules-trait.clar rules.clar wallet.clar

;; this line is letting the wallet.clar aware that we are using a trait
;; called security-rules-triat and it lives in the contract security-rules-trait

(use-trait security-rules-trait .security-rules-trait.security-rules-trait)

;; --------------ERRORS------------
(define-constant ERR_UNAUTHORIZED (err u401));; if a caller who is not authorized tries
;; perform an action they're not authorized to

(define-constant ERR_ALREADY_APPROVED (err u402));; this action has already been approved 
;; by this admin once

(define-constant ERR_NOT_ENOUGH_APPROVALS (err u403));; this error returns when the 
;; the threshold rquired for an action to be met before its approved 
;;is not met yet

(define-constant ERR_NOT_ADMIN (err u404)) ;; the caller is not a registered admin

(define-constant ERR_ALREADY_INITIALIZED (err u405));; it has already been initialized
;; can not be initialized twice

(define-constant ERR_ALREADY_EXECUTED (err u406)) ;; If an action is already executed
;; we this error reflects

(define-constant ERR_THRESHOLD_TOO_LOW (err u407));; this error returns when someone
;; tries to set the threshold be lower than 2, minimum must be 2 so single individual
;; does not act alone

(define-constant ERR_PAUSED (err u408));; the contact is paused and no actions allowed
;; until unpaused 

;; STORAGE

;; ----------DATA VARs--------------
;; This variable stores the identity of whoever deployed the contract
;; its used once during initialization for verifying the deploers identity
(define-data-var contract-owner principal tx-sender)

;; Threshold stores the minimum number of admins required before an action
;; will be executed
(define-data-var threshold uint u2)

;; This will track if this contract has already been initialized 
;; it prevents it from being initialized the second time
(define-data-var initialized bool false)

;; When its true, it means its frozen,
;; there will be no approval/execution all actions paused
;; umtill admin unpauses it
(define-data-var paused bool false)

;; -------------DATA MAPs-------------
;; This map stores the list of all the admins rights in this wallet
;; each persons address is saved with a yes or no
;; NO means the admin has no rights
(define-map admins principal bool)

;; Any admin that approves an action its recorded, the admin that did it inorder to
;; avoid double voting. This map keeps track
(define-map approvals { action: (buff 32), signer: principal } bool)

;; Keeps a record of all the approvals each action gets
;; and once it reaches the threshold it executes
(define-map approval-counts (buff 32) uint)

;; This map tracks eack action thats been executed already
;; this will help prevent replay
(define-map executed-actions (buff 32) bool)

;; -------------Ready Only Functions-------------
;; Fetch the principal address of the contract owner
(define-read-only (get-contract-owner)
    (var-get contract-owner)
)

;; Lets get threshold thats stored in the threshold variable
(define-read-only (get-threshold) 
    (var-get threshold)
)

;; Get the initialization status, if the contract has been initialized yet
;; if it returns true then it has already been initialized
(define-read-only (get-initialized) 
    (var-get initialized)
)

;; Get the current status of the contract if its paused or not
;; true means its paused
(define-read-only (is-paused)
    (var-get paused)
)

;; Check the admins map to see if an address is in the admins list
;; but if its not in the admins list then we defult to false 
;; instead of throwing error
(define-read-only (is-admin (who principal))
    (default-to false (map-get? admins who))
)

;; Lets check the approvals map to see this admin approved this action
;; and we default to false if no entry data exists yet
(define-read-only (has-approved (action (buff 32)) (signer principal))
    ( default-to false (map-get? approvals {action: action, signer: signer}))
)

;; Let's get the number of approvals that a specific action has gotten but if no
;; approvals yet then it returns u0 in default
(define-read-only (get-approval-count (action-id (buff 32)))
    (default-to u0 (map-get? approval-counts action-id))
)

;; Check the status of a prticular action if it has already been executed
;; - "default to false" if no executed action yet
(define-read-only (is-executed (action-id (buff 32))) 
    (default-to false (map-get? executed-actions action-id))
)

;;----------Public Functions-----------

;; This is the initialization set up, its done once by who is deploying
(define-public (initialize 
    (admin-one principal) 
    (admin-two principal) 
    (admin-three principal) 
    (starting-threshold uint))

    (begin
        ;; Make sure that only the deployer can initialize, hence we use 
        ;; "tx-sender"
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)

        ;; Ensure that this can only be called once
        (asserts! (not (var-get initialized)) ERR_ALREADY_INITIALIZED)

        ;; 2 admins must vote for any action to be executed so we 
        ;; ensure that threshold is met
        (asserts! (>= starting-threshold u2) ERR_THRESHOLD_TOO_LOW)

        ;; Set the three initial admins
        (map-set admins admin-one true)
        (map-set admins admin-two true)
        (map-set admins admin-three true)

        ;; Save the threshold
        (var-set threshold starting-threshold)

        ;; Lock the initialization to prevent it from being called again
        ;; this will eliminate any malicious activity
        (var-set initialized true)

        ;; Log event
        (print { event: 
            "initialized", 
            admins: (list admin-one admin-two admin-three), 
            threshold: starting-threshold}
        )
        (ok true)
    )
)

;; ADMIN MANAGEMENT

;; ---------Pause Control----------
;; If there is an emergency then the admin can pause the contract
(define-public (pause)
    (begin
        ;; Only an admin thats been registered during initialization can call this
        (asserts! (is-admin contract-caller) ERR_UNAUTHORIZED)

        ;; Save the log event on-chain so know when its paused
        ;; and who paused it
        (print { event: "paused", by: contract-caller })

        ;; Set paused to "true"
        ;; and while its paused, all "approve" and "execute"  calls are rejected
        ;; until "unpause" is called
        (var-set paused true)

        (ok true)
    )
)

;; --------------Unpause--------------
;; Once the emergency is resolved the contract can be Unpaused
(define-public (unpause)
    (begin
        ;; only a registered admin can unpause the contract
        ;; if not then throw error
        (asserts! (is-admin contract-caller) ERR_UNAUTHORIZED)

        ;; Log the event 
        (print { event: "unpaused", by: contract-caller })

        ;; Set the contract pause to false so that normal approve and execute
        ;; operations can continue
        (var-set paused false)

        (ok true)
    )
)

;; -------------Approvals--------------
;; This function ensures that each admins aprroves an action once 
;; using their unique Id

(define-public (approve (action-id (buff 32)))
    (begin
        ;; The contract is supposed to be unpaused first
        (asserts! (not (var-get paused)) ERR_PAUSED)

        ;; If you're not a registered admin you can not approve
        ;; ensure it must be a registered admin calling this action
        (asserts! (is-admin tx-sender) ERR_NOT_ADMIN)

        ;; The same admin cannot approve twice so we prvent that
        (asserts! (is-none (map-get? approvals { action: action-id, signer: tx-sender})) 
            ERR_ALREADY_APPROVED
        )

        ;; Save the admin's approval
        (map-set approvals { action: action-id, signer: tx-sender } true)

        ;; Add the approval count 
        (map-set approval-counts action-id 
            (+ (default-to u0 (map-get? approval-counts action-id)) u1)
        )

        ;; Log the approval
        (print { event: "approved", action-id: action-id, signer: tx-sender})

        (ok true)
    )
)

;; -----------Execution-----------
(define-public (execute 
    (action-id (buff 32)) 
    (request (buff 2048)) 
    (rules <security-rules-trait>))

    (begin
        ;; The contract must not be paused
        (asserts! (not (var-get paused)) ERR_PAUSED)

        ;; Reject any action thats already been executed
        (asserts! (not (default-to false (map-get? executed-actions action-id))) ERR_ALREADY_EXECUTED)

        ;; Check that the threshold is met to approve this action
        (asserts! (>= (default-to u0 (map-get? approval-counts action-id)) 
            (var-get threshold)) ERR_NOT_ENOUGH_APPROVALS
        )

        ;; Verify the request with the rules contract
        (asserts! (try! (contract-call? rules is-allowed request)) ERR_UNAUTHORIZED)

        ;; Record this action as been executed already
        (map-set executed-actions action-id true)

        ;; Remove the approval count so that the action can not be resumitted again
        (map-delete approval-counts action-id) ;; so this is the replay prevention
                                            ;; once this execute runs successfully,
                                            ;; the approval count is deleted so that 
                                            ;; the action-id will not be used to again

        ;; Log the execution
        (print { event: "executed", action-id: action-id, request: request })

        (ok true)
    )
)






















