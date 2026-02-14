# Clarity Security Templates

Reusable security patterns for Clarity smart contracts on Stacks, providing standardized governance and access control.

## What This Is

A collection of production-ready templates for securing Clarity smart contracts:

1. **Ownable Pattern** - Single owner control (solo projects)
2. **DAO Governance Pattern** - Multi-signature operator voting (team projects)
3. **Treasury Management** - Secure fund custody with authorization

All patterns are based on proven implementations from ExecutorDAO and designed for easy adoption.

---

## The Problem

Developers building on Stacks face three challenges:

1. **Security-critical code** - Authorization and governance are hard to get right
2. **No standardization** - Every project implements access control differently
3. **High development cost** - Building secure governance from scratch takes weeks

This leads to bugs, vulnerabilities, and delayed launches.

---

## The Solution

Copy proven security patterns into your contract. Add one line of protection to admin functions. The templates handle all the complex security logic.

**Instead of writing custom governance:** Copy a battle-tested pattern
**Instead of risking security bugs:** Use templates with comprehensive testing
**Instead of weeks of development:** Ship secure contracts in hours

---

## Quick Start

### Pattern 1: Ownable (Single Owner)

**Use when:** You need one person to control the contract

**Step 1:** Add the trait
```clarity
(impl-trait .ownable-trait.ownable-trait)
```

**Step 2:** Copy the template code from `ownable-template.clar`

**Step 3:** Protect admin functions
```clarity
(define-public (withdraw (amount uint))
    (begin
        (try! (assert-owner))  ;; One-line protection
        ;; Your logic here
    )
)
```

**See:** `contracts/examples/example-dao-treasury.clar`

---

### Pattern 2: DAO Governance (Multi-Sig)

**Use when:** Multiple operators need to approve changes (2-of-3 threshold)

**Step 1:** Deploy the DAO system
```clarity
dao-core.clar              ;; The execution engine
operator-governance.clar   ;; Multi-sig voting
treasury.clar             ;; Fund management
```

**Step 2:** Initialize with bootstrap proposal
```clarity
;; Run once at deployment
(contract-call? .dao-core construct .dp000-bootstrap)
```

**Step 3:** Protect your contract functions
```clarity
(define-public (update-settings (new-value uint))
    (begin
        ;; Only callable through approved DAO proposals
        (asserts! (is-eq contract-caller .dao-core) ERR-NOT-DAO)
        ;; Your logic here
    )
)
```

**See:** `contracts/examples/example-dao-usage.clar`

---

## Architecture

### Core Contracts

**dao-core.clar**
- Manages extensions and executes approved proposals
- Provides DAO authority for proposal execution
- Prevents replay attacks

**operator-governance.clar**
- Multi-signature voting system (2-of-3 threshold by default)
- Operators create and vote on proposals
- Auto-executes when threshold is met

**treasury.clar**
- Holds and manages DAO funds (STX and SIP-010 tokens)
- Only callable by DAO core or enabled extensions
- Secure custody with as-contract pattern

### Bootstrap & Examples

**dp000-bootstrap.clar**
- One-time initialization proposal
- Enables core extensions
- Sets initial operators

**dp001-add-operator.clar**
- Example: Adding a new operator

**dp002-remove-operator.clar**
- Example: Removing a compromised operator

**dp003-transfer-stx.clar**
- Example: Moving funds from treasury

---

## How It Works

### Governance Flow

1. **Operator creates proposal**
```clarity
   (contract-call? .operator-governance create-proposal 
       "Add new operator Alice" 
       .dp001-add-operator)
```

2. **Operators vote**
```clarity
   (contract-call? .operator-governance signal 
       u1     ;; proposal-id
       true   ;; approve
       .dp001-add-operator)
```

3. **Auto-execution at threshold**
   - When 2 operators approve (2-of-3 threshold)
   - Operator-governance calls dao-core.execute()
   - Proposal runs with DAO authority
   - Changes are applied

### Security Model

**Authorization Layers:**
1. Only operators can create proposals
2. Only operators can vote
3. Threshold must be met (2-of-3)
4. Each proposal executes only once
5. Treasury operations require DAO approval

**Replay Protection:**
- Every proposal can execute only once
- Prevents malicious re-execution

**Operator Safety:**
- Cannot vote twice on same proposal
- Cannot change vote after signaling
- Operators can be added/removed via governance

---

## Examples

### Example 1: Team Wallet (Multi-Sig)

**Scenario:** 3 founders managing company funds

**Setup:**
1. Deploy DAO system
2. Bootstrap with 3 operator addresses
3. Set 2-of-3 threshold

**Usage:**
- Any operator proposes spending
- 2 operators must approve
- Funds transfer automatically

### Example 2: DeFi Protocol Parameters

**Scenario:** Governance-controlled protocol settings

**Setup:**
1. Deploy your protocol contract
2. Add DAO authorization check
3. Connect to operator-governance

**Usage:**
- Operators propose parameter changes
- 2-of-3 vote required
- Protocol updates securely

### Example 3: NFT Marketplace Admin

**Scenario:** Decentralized marketplace governance

**Setup:**
1. Deploy marketplace contract
2. Use DAO governance for admin functions
3. Community operators manage settings

**Usage:**
- Operators propose fee changes
- Multi-sig approval required
- Marketplace stays decentralized

---

## Testing

Run the complete test suite:
```bash
clarinet check  # Verify all contracts compile
clarinet test   # Run security tests
```

All 16 contracts must pass validation before deployment.

For detailed test results, see [TEST_REPORT.md](TEST_REPORT.md).

---

## When to Use Each Pattern

### Use Ownable When:
- ✅ Solo project or single admin
- ✅ Simple authorization needs
- ✅ Prototype or MVP stage
- ✅ You control the contract entirely

### Use DAO Governance When:
- ✅ Team project (2+ people)
- ✅ Need multi-signature security
- ✅ Managing significant funds
- ✅ Community governance required
- ✅ Production DeFi protocol

---

## Security Considerations

**Ownable Pattern:**
- ⚠️ Single point of failure
- ⚠️ Owner wallet compromise = total loss
- ✅ Simple and gas-efficient
- ✅ Easy to audit

**DAO Governance Pattern:**
- ✅ No single point of failure
- ✅ Compromise of one operator ≠ loss
- ✅ Self-correcting (remove bad actors)
- ⚠️ More complex setup

See [SECURITY.md](SECURITY.md) for detailed security analysis.

---

## Error Codes

### Ownable Pattern
- `u100` - Not the contract owner
- `u101` - Cannot set owner to same address

### DAO Governance Examples
- `u2000` - Not authorized (DAO governance required)
- `u2001` - Invalid amount
- `u2100` - Unauthorized (DAO or extension required)
- `u2101` - Invalid amount

### DAO Core
- `u3000` - Unauthorized (not DAO or extension)
- `u3001` - Proposal already executed
- `u3002` - Invalid extension

### Operator Governance
- `u4000` - Unauthorized (not an operator)
- `u4001` - Proposal already executed
- `u4002` - Proposal not found
- `u4003` - Already voted on this proposal
- `u4004` - Not an operator

### Treasury
- `u5000` - Unauthorized (not DAO or extension)
- `u5001` - Transfer failed
- `u5002` - Invalid amount

---

## Deployment Guide

### For Local Testing (Clarinet)

1. Clone the repository
2. Run `clarinet check` to verify contracts
3. Run `clarinet test` to execute test suite
4. Deploy to devnet for integration testing

### For Mainnet Deployment

1. **Deploy core contracts:**
```
   dao-core.clar
   operator-governance.clar
   treasury.clar
```

2. **Update bootstrap proposal:**
   - Replace placeholder addresses with real operator wallets
   - Verify threshold settings

3. **Initialize DAO:**
```clarity
   (contract-call? .dao-core construct .dp000-bootstrap)
```

4. **Verify setup:**
   - Check operators are set correctly
   - Test proposal creation
   - Confirm voting works

---

## Project Structure
```
contracts/
├── traits/              # Interface definitions
├── core/               # DAO execution engine
├── governance/         # Voting systems
├── treasury/           # Fund management
├── examples/           # Usage examples
└── proposals/          # Bootstrap & examples

tests/                  # Comprehensive test suite
```

---

## Contributing

Built by Timothy Terese Chimbiv based on proven patterns from ExecutorDAO (Marvin Janssen).

Feedback, issues, and contributions welcome on GitHub.

---

## License

MIT

---

## Links

- GitHub: [github.com/Terese678/clarity-security-templates](https://github.com/Terese678/clarity-security-templates)
- Stacks Forum: [View community discussion](https://forum.stacks.org)
- Author: Timothy Terese Chimbiv