# Clarity Ownable Security Pattern

A reusable ownership pattern for Clarity smart contracts that prevents unauthorized access to admin functions.

## What This Does

This pattern provides a standardized way to control who can call certain functions in your contract. It ensures that only the contract owner can execute protected operations like withdrawing funds, updating settings, or transferring ownership.

## The Problem

Without a standard pattern, developers implement ownership differently across contracts. This leads to security bugs where non-owners can access admin functions, or ownership transfers don't work correctly.

## The Solution

Copy a proven implementation into your contract. Add one line to any function that should be owner-only. The pattern handles all the security checks.

## How to Use

**Step 1:** Add the trait to your contract
```clarity
(impl-trait .ownable-trait.ownable-trait)
```

**Step 2:** Copy the template code from `ownable-template.clar` into your contract

**Step 3:** Add the security check to admin functions
```clarity
(define-public (withdraw (amount uint))
    (begin
        (try! (assert-owner))  ;; Only owner gets past this line
        ;; Your withdrawal logic here
    )
)
```

Functions that anyone should be able to call do not need this check.

## Example

The `example-dao-treasury.clar` contract shows this pattern in action. It has:
- A public donation function that anyone can call
- A withdrawal function that only the owner can call
- Secure ownership transfer

## Testing

Run the test suite to verify the security pattern works:
```bash
clarinet test
```

For detailed test results, see [TEST_REPORT.md](TEST_REPORT.md).

## When to Use the Ownership Check

**Add `(try! (assert-owner))` to functions that:**
- Withdraw or transfer funds
- Update contract settings
- Mint tokens
- Pause contract operations
- Transfer ownership

**Don't add it to functions that:**
- Accept deposits
- Process public transactions
- Read public data

## How It Works

The pattern uses a simple check that either allows the function to continue or stops it immediately:
```clarity
(define-private (assert-owner)
    (ok (asserts! (is-owner) ERR-NOT-OWNER))
)
```

If the caller is the owner, the function continues. If not, it returns an error and stops.

## Integration

1. Copy `ownable-trait.clar` to your contracts folder
2. Copy the code from `ownable-template.clar` into your contract
3. Add `(try! (assert-owner))` to your protected functions
4. Test your contract

## Error Codes

- `u100` - Caller is not the contract owner
- `u101` - Cannot set owner to the same address

## License

MIT

## Author

Timothy Terese Chimbiv
