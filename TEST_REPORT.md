# Comprehensive Test Report: Ownable Template Security Pattern

## Test Environment

This test uses simulated blockchain addresses provided by Clarinet's testing environment:

- **Deployer Address:** ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
  - This is the address that deployed the contract and becomes the initial owner
  
- **Test Wallet 1:** ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
  - A simulated user address used to test non-owner interactions
  
- **Recipient Wallet:** ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
  - The destination address for withdrawal transactions

---

## TEST 1: Check Initial Owner

**Contract Call:**
```clarity
(contract-call? .example-dao-treasury get-owner)
```

**Result:**
```clarity
(ok ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

**Explanation:**
When a contract is deployed, the ownable-template automatically sets the deployer as the initial owner. This test confirms that the deployer address (ST1PQHQ...) is correctly set as the contract owner. The get-owner function is a public read-only function that anyone can call to verify who controls the contract.

---

## TEST 2: Check Initial Balance

**Contract Call:**
```clarity
(contract-call? .example-dao-treasury get-balance)
```

**Result:**
```clarity
(ok u0)
```

**Explanation:**
The treasury starts with zero STX tokens. This confirms the contract's initial state before any donations are made. The balance is stored in the contract's data storage and can be queried by anyone.

---

## TEST 3: Switch to Wallet 1 and Donate

**Setup:**
```clarity
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
```

**Contract Call:**
```clarity
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.example-dao-treasury donate u1000)
```

**Result:**
```clarity
Events emitted
{"type":"stx_transfer_event","stx_transfer_event":{"sender":"ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5","recipient":"ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.example-dao-treasury","amount":"1000","memo":""}}
(ok true)
```

**Explanation:**
We switched the transaction sender to simulate a different user (Wallet 1) calling the contract. The donate function is a public function that anyone can call - it doesn't require ownership. When called, it transfers 1000 micro-STX (uSTX) from the caller to the treasury contract. The blockchain emits a stx_transfer_event showing the transfer occurred, and the function returns (ok true) indicating success. Note: We had to use the fully qualified contract name because the shorthand .example-dao-treasury would look for the contract at the current sender's address.

---

## TEST 4: Check Balance After Donation

**Contract Call:**
```clarity
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.example-dao-treasury get-balance)
```

**Result:**
```clarity
(ok u1000)
```

**Explanation:**
After the donation, the contract's balance increased from u0 to u1000. This confirms that the STX transfer was successful and the contract is correctly tracking its balance. The balance is stored in a data variable that gets updated by the stx-transfer? function in the donate method.

---

## TEST 5: Wallet 1 Tries to Withdraw (SHOULD FAIL)

**Contract Call:**
```clarity
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.example-dao-treasury withdraw u500 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
```

**Result:**
```clarity
(err u100)
```

**Explanation:**
This is the critical security test! Wallet 1 (who is NOT the owner) attempts to withdraw 500 uSTX from the treasury. The withdraw function is protected by the ownable-template, which checks `(try! (assert-owner))`. Since Wallet 1 is not the owner, the assertion fails and returns error u100 (ERR-NOT-OWNER). No funds are transferred, proving the ownership security pattern works correctly. This prevents unauthorized access to the treasury funds.

---

## TEST 6: Switch Back to Deployer (Owner)

**Setup:**
```clarity
::set_tx_sender ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
```

**Contract Call:**
```clarity
(contract-call? .example-dao-treasury withdraw u400 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
```

**Result:**
```clarity
Events emitted
{"type":"stx_transfer_event","stx_transfer_event":{"sender":"ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.example-dao-treasury","recipient":"ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG","amount":"400","memo":""}}
(ok true)
```

**Explanation:**
We switch back to the original deployer/owner. Now when withdraw is called, the ownership check `(try! (assert-owner))` passes because the current sender IS the owner. The function proceeds to transfer 400 uSTX from the treasury contract to the recipient address. The event shows the treasury as the sender and the recipient as the receiver. The function returns (ok true) confirming success. Only the owner can execute this protected function.

---

## TEST 7: Check Balance After Withdrawal

**Contract Call:**
```clarity
(contract-call? .example-dao-treasury get-balance)
```

**Result:**
```clarity
(ok u600)
```

**Explanation:**
The balance correctly decreased from 1000 to 600 uSTX (1000 - 400 = 600). This confirms that the withdrawal was processed correctly and the contract's internal balance tracking is accurate. The stx-transfer? function automatically updates the contract's balance.

---

## TEST 8: Transfer Ownership to Wallet 1

**Contract Call:**
```clarity
(contract-call? .example-dao-treasury set-owner 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
```

**Result:**
```clarity
(ok true)
```

**Explanation:**
The current owner (deployer) calls set-owner to transfer ownership to Wallet 1. The set-owner function is also protected - only the current owner can transfer ownership. The function checks ownership, then updates the owner variable. This returns (ok true) indicating the ownership transfer was successful. This demonstrates that ownership is transferable but still protected.

---

## TEST 9: Verify New Owner

**Contract Call:**
```clarity
(contract-call? .example-dao-treasury get-owner)
```

**Result:**
```clarity
(ok ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
```

**Explanation:**
We verify that ownership has actually changed. The get-owner function now returns Wallet 1's address instead of the deployer's address. The ownership state has been permanently updated in the contract. The transfer is complete and irreversible (unless the new owner transfers it again).

---

## TEST 10: Old Owner (Deployer) Tries to Withdraw (SHOULD FAIL)

**Contract Call:**
```clarity
(contract-call? .example-dao-treasury withdraw u100 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
```

**Result:**
```clarity
(err u100)
```

**Explanation:**
This is another critical security test! The original deployer (who was the owner but transferred ownership) attempts to withdraw funds. Even though this address deployed the contract and was previously the owner, the ownership check now fails because the current owner is Wallet 1. The function returns (err u100) (ERR-NOT-OWNER). This proves that ownership transfer immediately revokes access from the old owner - there's no lingering permissions or backdoors. The security model is clean and enforceable.

---

## TEST 11: Switch to New Owner (Wallet 1)

**Setup:**
```clarity
::set_tx_sender ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5
```

**Contract Call:**
```clarity
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.example-dao-treasury withdraw u200 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
```

**Result:**
```clarity
Events emitted
{"type":"stx_transfer_event","stx_transfer_event":{"sender":"ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.example-dao-treasury","recipient":"ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG","amount":"200","memo":""}}
(ok true)
```

**Explanation:**
We switch to Wallet 1 (the new owner) and call withdraw. The ownership check now passes because Wallet 1 is the current owner. The function successfully transfers 200 uSTX from the treasury to the recipient. This confirms that the new owner has full control over all protected functions. The ownership transfer granted complete authority to the new owner while simultaneously revoking it from the old owner.

---

## TEST 12: Final Balance Check

**Contract Call:**
```clarity
(contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.example-dao-treasury get-balance)
```

**Result:**
```clarity
(ok u400)
```

**Explanation:**
The final balance is 400 uSTX (600 - 200 = 400). This confirms all transactions were processed correctly:

- Started: 0
- After donation: 1000
- After first withdrawal (owner): 600
- After second withdrawal (new owner): 400

The contract's balance tracking is consistent and accurate throughout all operations.

---

## Security Pattern Summary

### What the Ownable Template Provides:

- **Ownership Initialization:** Deployer automatically becomes the owner
- **Access Control:** Protected functions check tx-sender against stored owner
- **Ownership Transfer:** Owner can transfer control to another address
- **Immediate Revocation:** Old owner loses access immediately upon transfer
- **Public Transparency:** Anyone can query who the current owner is

### Key Security Guarantees:

- Authorization: Only the owner can execute protected functions
- Transferability: Ownership can be safely transferred
- No Backdoors: Previous owners have no special privileges
- Transparency: Ownership is publicly queryable
- Consistency: Security checks are enforced on every call

### Functions Tested:

**donate**
- Access Level: Public
- Purpose: Anyone can contribute funds

**get-balance**
- Access Level: Public Read-Only
- Purpose: Anyone can check balance

**get-owner**
- Access Level: Public Read-Only
- Purpose: Anyone can verify owner

**withdraw**
- Access Level: Owner Only
- Purpose: Protected fund withdrawal

**set-owner**
- Access Level: Owner Only
- Purpose: Protected ownership transfer

---

## Conclusion

All 12 tests passed successfully, proving that the ownable-template provides a robust, reusable security pattern for Clarity smart contracts. This standardized approach:

- Prevents unauthorized access to protected functions
- Enables safe ownership transfers
- Maintains transparent and verifiable security
- Can be easily integrated into any contract requiring ownership controls

This testing demonstrates the value of Security Template Standardization for the Stacks ecosystem.