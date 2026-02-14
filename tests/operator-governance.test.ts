// Title: Operator Governance Test
// Author: Timothy Terese Chimbiv
// Purpose: Test multi-sig voting

import { Cl } from '@stacks/transactions';
import { describe, expect, it, beforeEach } from 'vitest';
import {
  contracts,
  operators,
  initializeDAO,
  createProposal,
} from './test-helpers';

describe('Operator Governance', () => {
  
  beforeEach(() => {
    // Initialize DAO before each test
    initializeDAO();
  });
  
  it('should initialize with 3 operators', () => {
    // Check operator 1
    const op1 = simnet.callReadOnlyFn(
      contracts.operatorGovernance,
      'is-operator',
      [Cl.principal(operators.operator1)],
      operators.operator1
    );
    expect(op1.result).toBeOk(Cl.bool(true));
    
    // Check operator 2
    const op2 = simnet.callReadOnlyFn(
      contracts.operatorGovernance,
      'is-operator',
      [Cl.principal(operators.operator2)],
      operators.operator2
    );
    expect(op2.result).toBeOk(Cl.bool(true));
    
    // Check operator 3
    const op3 = simnet.callReadOnlyFn(
      contracts.operatorGovernance,
      'is-operator',
      [Cl.principal(operators.operator3)],
      operators.operator3
    );
    expect(op3.result).toBeOk(Cl.bool(true));
  });
});