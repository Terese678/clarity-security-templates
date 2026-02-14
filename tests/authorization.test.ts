// Title: Authorization Test
// Author: Timothy Terese Chimbiv
// Purpose: Test that only operators can create proposals and vote

import { Cl } from '@stacks/transactions';
import { describe, expect, it, beforeEach } from 'vitest';
import { 
  contracts, 
  operators, 
  initializeDAO, 
  createProposal,
  signalProposal,
  getAccounts
} from './test-helpers';

describe('Authorization & Security', () => {
  
  beforeEach(() => {
    // Initialize DAO before each test
    initializeDAO();
  });
  
  it('should block non-operators from creating proposals', () => {
    const { wallet1 } = getAccounts();
    
    // Non-operator (wallet1) tries to create proposal
    const result = createProposal(
      wallet1,
      'Unauthorized proposal',
      contracts.addOperator
    );
    
    // Should fail with err-not-operator (u4004)
    expect(result.result).toBeErr(Cl.uint(4004));
  });
  
  it('should block non-operators from voting', () => {
    const { wallet1 } = getAccounts();
    
    // First, an operator creates a proposal
    createProposal(
      operators.operator1,
      'Test proposal',
      contracts.addOperator
    );
    
    // Non-operator tries to vote
    const voteResult = signalProposal(
      wallet1,
      1,
      true,
      contracts.addOperator
    );
    
    // Should fail with err-not-operator (u4004)
    expect(voteResult.result).toBeErr(Cl.uint(4004));
  });
  
  it('should allow operators to check their status', () => {
    const { deployer } = getAccounts();
    
    // Check if operator1 is an operator
    const isOp = simnet.callReadOnlyFn(
      contracts.operatorGovernance,
      'is-operator',
      [Cl.principal(operators.operator1)],
      deployer
    );
    
    // Should return true
    expect(isOp.result).toBeOk(Cl.bool(true));
  });
  
  it('should return false for non-operators', () => {
    const { deployer, wallet1 } = getAccounts();
    
    // Check if wallet1 (non-operator) is an operator
    const isOp = simnet.callReadOnlyFn(
      contracts.operatorGovernance,
      'is-operator',
      [Cl.principal(wallet1)],
      deployer
    );
    
    // Should return false
    expect(isOp.result).toBeOk(Cl.bool(false));
  });
});