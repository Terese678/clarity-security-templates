;; Author Timothy Terese Chimbiv

;; This contract is in charge of handling every request that is made through
;; the wallet before its permitted to be executed.
;; Developers can replace it with their own checks

;; This declares that this contract implements the security-rules-trait,
;; so clarity checks that "is-allowed" matches the required interface exactly.
(impl-trait .security-rules-trait.security-rules-trait)

;; Constants
(define-constant ERR_EMPTY_REQUEST (err u500));; When there is an empty buffer it 
;; returns this error

(define-constant ERR_REQUEST_TOO_LARGE (err u501)) ;; This error pops up when 
;; the input is more than the rquired size limit

;; Public function
(define-public (is-allowed (request (buff 2048)))
    (begin
        ;; if someone sends an empty request reject it because there will
        ;; be nothing to work with, it must be more than u0
        (asserts! (> (len request) u0) ERR_EMPTY_REQUEST)

        ;; any data too large must be not be approved, 
        ;; can take up to buff 2048 but delibrate security messures we accept
        ;; 1048 bytes to avoid unnecessary data
        (asserts! (<= (len request) u1048) ERR_REQUEST_TOO_LARGE)

        (ok true)
    )
)



