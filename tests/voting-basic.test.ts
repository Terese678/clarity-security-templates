// Title: Basic Voting Test
// Author: Timothy Terese Chimbiv
// Purpose: Test that operators can create proposals

import { Cl } from '@stacks/transactions';
import { describe, expect, it, beforeEach } from 'vitest';
import { 
  contracts, 
  operators, 
  initializeDAO, 
  createProposal 
} from './test-helpers';

describe('Basic Voting', () => {
  
  beforeEach(() => {
    // Initialize DAO before each test
    initializeDAO();
  });
  
  it('should allow operators to create proposals', () => {
    // Operator 1 creates a proposal
    const result = createProposal(
      operators.operator1,
      'Test proposal',
      contracts.addOperator
    );
    
    // Check: Did it work?
    expect(result.result).toBeOk(Cl.uint(1)); // Proposal ID should be 1
  });
  
  it('should increment proposal IDs', () => {
    // Create first proposal
    const result1 = createProposal(
      operators.operator1,
      'First proposal',
      contracts.addOperator
    );
    expect(result1.result).toBeOk(Cl.uint(1));
    
    // Create second proposal
    const result2 = createProposal(
      operators.operator2,
      'Second proposal',
      contracts.removeOperator
    );
    expect(result2.result).toBeOk(Cl.uint(2)); // Should be ID 2
  });
});