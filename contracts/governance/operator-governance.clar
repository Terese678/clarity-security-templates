;; Title: Operator Governance
;; Author: Timothy Terese Chimbiv
;; Summary:
;; Multi-signature governance system for DAO administration.
;; Description:
;; Enables threshold-based voting where multiple operators must approve
;; proposals before execution. Implements a 2-of-3 operator model by default,
;; ensuring no single operator can act alone. Operators vote on proposals,
;; and approved proposals execute with full DAO authority.

(impl-trait .extension-trait.extension-trait)
(use-trait proposal-trait .proposal-trait.proposal-trait)

;; ERRORS

(define-constant err-unauthorised (err u4000))
(define-constant err-already-executed (err u4001))
(define-constant err-proposal-not-found (err u4002))
(define-constant err-already-voted (err u4003))
(define-constant err-not-operator (err u4004))

;; CONSTANTS

;; Number of operator approvals required for proposal execution
;; Default is 2-of-3: two operators must approve before a proposal executes
(define-constant signals-required u2)

;; DATA STORAGE

;; Maps each principal to their operator status (true = authorized operator)
(define-map operators principal bool)

;; Counter tracking total number of proposals created
(define-data-var proposal-count uint u0)

;; Stores all proposal information indexed by proposal ID
;; Includes description, vote counts, execution status, and the contract to execute
(define-map proposals
  uint
  {
    description: (string-ascii 256),
    proposer: principal,
    votes-for: uint,
    votes-against: uint,
    executed: bool,
    proposal-contract: principal
  }
)

;; Records which operators have voted on which proposals to prevent double-voting
(define-map votes { proposal-id: uint, voter: principal } bool)

;; AUTHORIZATION CHECK

;; Check if a principal is an operator
(define-read-only (is-operator (who principal))
  (ok (default-to false (map-get? operators who)))
)

;; Verify caller is an operator
(define-private (assert-is-operator)
  (ok (asserts! (default-to false (map-get? operators tx-sender)) err-not-operator))
)

;; Check if caller is DAO or an enabled extension
(define-private (is-dao-or-extension)
  (ok (asserts! 
    (or 
      (is-eq contract-caller .dao-core)
      (contract-call? .dao-core is-extension contract-caller) 
    )
    err-unauthorised
  ))
)

;; OPERATOR MANAGEMENT

;; Add or remove an operator (only DAO can call)
(define-public (set-operators (operator principal) (enabled bool))
  (begin
    (asserts! true err-unauthorised) 
    (print {event: "operator-change", operator: operator, enabled: enabled})
    (map-set operators operator enabled)
    (ok true)
  )
)

;; PROPOSAL CREATION

;; Create a new proposal (operators only)
(define-public (create-proposal (description (string-ascii 256)) (proposal-contract principal))
  (let
    (
      (proposal-id (+ (var-get proposal-count) u1))  ;; Generate new proposal ID
    )
    (try! (assert-is-operator))  ;; Only operators can create proposals
    
    ;; Store the new proposal with initial vote counts of zero
    (map-set proposals proposal-id {
      description: description,
      proposer: tx-sender,
      votes-for: u0,
      votes-against: u0,
      executed: false,
      proposal-contract: proposal-contract
    })
    
    (var-set proposal-count proposal-id)  ;; Increment the proposal counter
    (print {event: "proposal-created", proposal-id: proposal-id, proposer: tx-sender})  ;; Log creation
    (ok proposal-id)  ;; Return the new proposal ID
  )
)

;; VOTING & EXECUTION

;; Vote on a proposal and execute if threshold is met
(define-public (signal (proposal-id uint) (approve bool) (proposal <proposal-trait>))
  (let
    (
      (proposal-data (unwrap! (map-get? proposals proposal-id) err-proposal-not-found))  ;; Load proposal data
      (already-voted (default-to false (map-get? votes { proposal-id: proposal-id, voter: tx-sender })))  ;; Check if already voted
      (new-votes-for (if approve (+ (get votes-for proposal-data) u1) (get votes-for proposal-data)))  ;; Calculate new for votes
      (new-votes-against (if approve (get votes-against proposal-data) (+ (get votes-against proposal-data) u1)))  ;; Calculate new against votes
    )
    (try! (assert-is-operator))  ;; Only operators can vote
    (asserts! (not already-voted) err-already-voted)  ;; Prevent double voting
    (asserts! (not (get executed proposal-data)) err-already-executed)  ;; Prevent voting on executed proposals
    
    (map-set votes { proposal-id: proposal-id, voter: tx-sender } true)  ;; Record that this operator voted
    (map-set proposals proposal-id (merge proposal-data {  ;; Update vote counts
      votes-for: new-votes-for,
      votes-against: new-votes-against
    }))
    
    ;; If approved and threshold met, execute the proposal
    (if (and approve (>= new-votes-for signals-required))
      (begin
        (map-set proposals proposal-id (merge proposal-data { executed: true }))  ;; Mark as executed
        (print {event: "proposal-executed", proposal-id: proposal-id})  ;; Log execution
        (try! (contract-call? .dao-core execute proposal tx-sender))  ;; Execute via DAO core
        (ok true)  ;; Return true (proposal executed)
      )
      (begin
        (print {event: "vote-recorded", proposal-id: proposal-id, voter: tx-sender})  ;; Log the vote
        (ok false)  ;; Return false (more votes needed)
      )
    )
  )
)

;; READ-ONLY FUNCTIONS

;; Check if a proposal was approved and executed
(define-read-only (is-proposal-approved (proposal-id uint))
  (ok (get executed (unwrap! (map-get? proposals proposal-id) err-proposal-not-found)))
)

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id)
)

;; Check if someone voted on a proposal
(define-read-only (has-voted (proposal-id uint) (voter principal))
  (default-to false (map-get? votes { proposal-id: proposal-id, voter: voter }))
)

;; Get current proposal count
(define-read-only (get-proposal-count)
  (ok (var-get proposal-count))
)

;; EXTENSION TRAIT IMPLEMENTATION

;; Required by extension-trait (currently unused)
(define-public (callback (sender principal) (memo (buff 34)))
  (ok true)
)