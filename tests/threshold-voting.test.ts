// Title: Threshold Voting Test
// Author: Timothy Terese Chimbiv
// Purpose: Test that 2-of-3 voting threshold works correctly

import { Cl } from '@stacks/transactions';
import { describe, expect, it, beforeEach } from 'vitest';
import { 
  contracts, 
  operators, 
  initializeDAO, 
  createProposal,
  signalProposal,
  isProposalApproved,
  fundTreasury
} from './test-helpers';

describe('Threshold Voting (2-of-3)', () => {
  
  beforeEach(() => {
    // Initialize DAO before each test
    initializeDAO();
  });
  
  it('should NOT execute with only 1 vote', () => {
    // Operator 1 creates proposal
    createProposal(
      operators.operator1,
      'Test proposal',
      contracts.addOperator
    );
    
    // Operator 1 votes (that's vote 1 of 2 needed)
    signalProposal(
      operators.operator1,
      1,
      true,
      contracts.addOperator
    );
    
    // Check: Is it approved? Should be false (need 2 votes)
    const approved = isProposalApproved(1);
    expect(approved.result).toBeOk(Cl.bool(false));
  });
  
  it('should execute when 2nd operator votes YES', () => {
    // Operator 1 creates proposal
    createProposal(
      operators.operator1,
      'Add new operator',
      contracts.addOperator
    );
    
    // Operator 1 votes YES (vote 1 of 2)
    signalProposal(
      operators.operator1,
      1,
      true,
      contracts.addOperator
    );
    
    // Check: Not executed yet
    let approved = isProposalApproved(1);
    expect(approved.result).toBeOk(Cl.bool(false));
    
    // Operator 2 votes YES (vote 2 of 2 - THRESHOLD MET!)
    const voteResult = signalProposal(
      operators.operator2,
      1,
      true,
      contracts.addOperator
    );
    
    // The signal should return true (executed!)
    expect(voteResult.result).toBeOk(Cl.bool(true));
    
    // Check: Now it's approved and executed!
    approved = isProposalApproved(1);
    expect(approved.result).toBeOk(Cl.bool(true));
  });
  
  it('should prevent double voting', () => {
    // Operator 1 creates proposal
    createProposal(
      operators.operator1,
      'Test double vote',
      contracts.addOperator
    );
    
    // Operator 1 votes first time
    signalProposal(
      operators.operator1,
      1,
      true,
      contracts.addOperator
    );
    
    // Operator 1 tries to vote again
    const doubleVote = signalProposal(
      operators.operator1,
      1,
      true,
      contracts.addOperator
    );
    
    // Should fail with err-already-voted (u4003)
    expect(doubleVote.result).toBeErr(Cl.uint(4003));
  });
  
  it('should block voting on executed proposals', () => {
    // Operator 1 creates
    createProposal(
      operators.operator1,
      'Already executed',
      contracts.removeOperator
    );
    
    // Operator 1 votes (vote 1 of 2)
    signalProposal(operators.operator1, 1, true, contracts.removeOperator);
    
    // Operator 2 votes (vote 2 of 2 - executes!)
    signalProposal(operators.operator2, 1, true, contracts.removeOperator);
    
    // Proposal is now executed
    let approved = isProposalApproved(1);
    expect(approved.result).toBeOk(Cl.bool(true));
    
    // Operator 3 tries to vote on executed proposal
    const lateVote = signalProposal(
      operators.operator3,
      1,
      true,
      contracts.removeOperator
    );
    
    // Should fail - can't vote on executed proposal (err-already-executed u4001)
    expect(lateVote.result).toBeErr(Cl.uint(4001));
  });
});