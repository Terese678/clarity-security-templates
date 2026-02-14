// Title: Test Helpers
// Author: Timothy Terese Chimbiv
// Purpose: Reusable functions for all tests

import { tx } from '@hirosystems/clarinet-sdk';
import { Cl } from '@stacks/transactions';

// Contract names
export const contracts = {
  daoCore: 'dao-core',
  operatorGovernance: 'operator-governance',
  treasury: 'treasury',
  bootstrap: 'dp000-bootstrap',
  addOperator: 'dp001-add-operator',
  removeOperator: 'dp002-remove-operator',
  transferStx: 'dp003-transfer-stx',
  exampleUsage: 'example-dao-usage',
};

// Get accounts dynamically (NOT at module level!)
export function getAccounts() {
  const accountsMap = simnet.getAccounts();
  return {
    deployer: accountsMap.get('deployer')!,
    wallet1: accountsMap.get('wallet_1')!,
    wallet2: accountsMap.get('wallet_2')!,
    wallet3: accountsMap.get('wallet_3')!,
  };
}

// Operator addresses (hardcoded - safe to define at module level)
export const operators = {
  operator1: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
  operator2: 'ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB',
  operator3: 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND',
};

// Initialize the DAO by running bootstrap
export function initializeDAO() {
  const { deployer } = getAccounts();
  
  const result = simnet.mineBlock([
    tx.callPublicFn(
      contracts.daoCore,
      'construct',
      [Cl.contractPrincipal(deployer, contracts.bootstrap)],
      deployer
    ),
  ]);
  
  // DEBUG: Print what happened
  console.log('=== BOOTSTRAP EXECUTION ===');
  console.log('Result:', result[0].result);
  console.log('Events:', JSON.stringify(result[0].events, null, 2));
  
  return result;
}

// Create a proposal
export function createProposal(
  operator: string,
  description: string,
  proposalContract: string
) {
  const { deployer } = getAccounts();
  
  const result = simnet.callPublicFn(
    contracts.operatorGovernance,
    'create-proposal',
    [
      Cl.stringAscii(description),
      Cl.contractPrincipal(deployer, proposalContract),
    ],
    operator
  );
  
  return result;
}

// Vote on a proposal
export function signalProposal(
  operator: string,
  proposalId: number,
  approve: boolean,
  proposalContract: string
) {
  const { deployer } = getAccounts();
  
  const result = simnet.callPublicFn(
    contracts.operatorGovernance,
    'signal',
    [
      Cl.uint(proposalId),
      Cl.bool(approve),
      Cl.contractPrincipal(deployer, proposalContract),
    ],
    operator
  );
  
  return result;
}

// Check if proposal approved
export function isProposalApproved(proposalId: number) {
  const { deployer } = getAccounts();
  
  const result = simnet.callReadOnlyFn(
    contracts.operatorGovernance,
    'is-proposal-approved',
    [Cl.uint(proposalId)],
    deployer
  );
  
  return result;
}

// Get STX balance
export function getStxBalance(who: string) {
  return simnet.getAssetsMap().get('STX')?.get(who) || 0;
}

// Get treasury balance
export function getTreasuryBalance() {
  const { deployer } = getAccounts();
  const treasuryAddress = `${deployer}.${contracts.treasury}`;
  return getStxBalance(treasuryAddress);
}

// Fund the treasury with STX
export function fundTreasury(amount: number) {
  const { deployer, wallet1 } = getAccounts();
  const treasuryAddress = `${deployer}.${contracts.treasury}`;
  
  // Transfer STX from wallet1 to treasury
  simnet.transferSTX(amount, treasuryAddress, wallet1);
}