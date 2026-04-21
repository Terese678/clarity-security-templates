# clarity-security-templates

## Why this exists

Writing secure multi-admin logic from scratch every time is where most contracts get it wrong. This template gives Clarity developers a vetted starting point, the approval flow, replay protection, pause control, and a swappable rules layer are already handled. Drop it in, replace the rules contract with your own checks, and build on top without rebuilding the security layer from zero.

---

## Contract Structure

Three contracts, each with a specific job:

```
contracts/
├── traits/
│   └── security-rules-trait.clar   # The interface every rules contract must implement
└── wallet/
    ├── rules.clar                  # Default implementation of the rules trait
    └── wallet.clar                 # The multi-sig wallet logic
```

**Deploy order matters:**
```
security-rules-trait.clar -> rules.clar -> wallet.clar
```

---

## How it works

1. The deployer calls `initialize` once — setting 3 admins and a threshold (minimum 2)
2. Any registered admin calls `approve` with an `action-id`
3. Once the approval count hits the threshold, any admin can call `execute`
4. The `rules` contract validates the request before execution goes through
5. Once executed, the action is recorded and cannot be replayed

---

## Public Functions

### `initialize`
```clarity
(initialize admin-one admin-two admin-three starting-threshold)
```
Called once by the deployer. Sets the initial admins and the minimum approval threshold. Threshold cannot be less than `u2`.

---

### `approve`
```clarity
(approve action-id)
```
Called by a registered admin to approve a pending action. Each admin can only approve once per action.

---

### `execute`
```clarity
(execute action-id request rules)
```
Executes an action once the threshold is met. Validates the request through the rules contract before proceeding.

---

### `pause` / `unpause`
```clarity
(pause)
(unpause)
```
Any registered admin can freeze all `approve` and `execute` calls in an emergency, and unfreeze when resolved.

---

## Read-Only Functions

| Function | Returns |
|---|---|
| `get-contract-owner` | The deployer's principal |
| `get-threshold` | Current approval threshold |
| `get-initialized` | Whether the contract has been set up |
| `is-paused` | Current pause status |
| `is-admin (who)` | Whether an address is a registered admin |
| `has-approved (action signer)` | Whether a specific admin approved an action |
| `get-approval-count (action-id)` | How many approvals an action has |
| `is-executed (action-id)` | Whether an action has already been executed |

---

## Error Codes

| Constant | Code | Meaning |
|---|---|---|
| `ERR_UNAUTHORIZED` | u401 | Caller is not allowed to perform this action |
| `ERR_ALREADY_APPROVED` | u402 | This admin already approved this action |
| `ERR_NOT_ENOUGH_APPROVALS` | u403 | Threshold not reached yet |
| `ERR_NOT_ADMIN` | u404 | Caller is not a registered admin |
| `ERR_ALREADY_INITIALIZED` | u405 | Contract has already been initialized |
| `ERR_ALREADY_EXECUTED` | u406 | This action has already been executed |
| `ERR_THRESHOLD_TOO_LOW` | u407 | Threshold must be at least 2 |
| `ERR_PAUSED` | u408 | Contract is paused, no actions allowed |

---

## Replacing the Rules Contract

The `rules.clar` is intentionally simple — it rejects empty requests and anything over 1048 bytes. You can swap it out with your own logic as long as it implements the `security-rules-trait`:

```clarity
(define-trait security-rules-trait
    (
        (is-allowed ((buff 2048)) (response bool uint))
    )
)
```

---

## Development Setup

**Requirements:**
- [Clarinet](https://github.com/hirosystems/clarinet)
- Node.js

**Check contracts:**
```bash
clarinet check
```

**Run the console:**
```bash
clarinet console
```

**Run tests:**
```bash
npm install
npm test
```

---

## Author

Timothy Terese Chimbiv