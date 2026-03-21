// Title: Verification Registry Test
// Author: Timothy Terese Chimbiv
// Purpose: Test the on-chain verification registry for Clarity security templates
// Tests cover: verifying templates, revoking templates, querying the registry,
// authorization checks, and duplicate prevention

import { tx } from '@hirosystems/clarinet-sdk';
import { Cl } from '@stacks/transactions';
import { describe, expect, it, beforeEach } from 'vitest';
import { contracts, operators, getAccounts, initializeDAO } from './test-helpers';

// Registry contract name — matches Clarinet.toml entry
const REGISTRY = 'verification-registry';

// Template details used across tests
const TEMPLATE_NAME    = 'ownable-template';
const TEMPLATE_DESC    = 'Standard ownership pattern for Clarity contracts';

// Error codes defined in verification-registry.clar
const ERR_NOT_AUTHORIZED     = Cl.uint(900);
const ERR_ALREADY_VERIFIED   = Cl.uint(901);
const ERR_TEMPLATE_NOT_FOUND = Cl.uint(902);
const ERR_ALREADY_REVOKED    = Cl.uint(904);

describe('Verification Registry', () => {

    beforeEach(() => {
        // Initialize the DAO before each test so the registry has a governing DAO
        initializeDAO();
    });

    // ============================================================
    // SET DAO CONTRACT
    // ============================================================

    describe('set-dao-contract', () => {

        it('deployer can hand governance over to the DAO', () => {
            // Arrange — get deployer address
            const { deployer } = getAccounts();

            // Act — transfer governance to dao-core
            const result = simnet.callPublicFn(
                REGISTRY,
                'set-dao-contract',
                [Cl.contractPrincipal(deployer, contracts.daoCore)],
                deployer
            );

            // Assert — governance transfer succeeds
            expect(result.result).toBeOk(Cl.bool(true));
        });

        it('non-deployer cannot change the DAO contract', () => {
            // Arrange — use an operator who is not the deployer
            const { deployer } = getAccounts();

            // Act — operator1 tries to take over governance
            const result = simnet.callPublicFn(
                REGISTRY,
                'set-dao-contract',
                [Cl.contractPrincipal(deployer, contracts.daoCore)],
                operators.operator1
            );

            // Assert — must fail with not authorized
            expect(result.result).toBeErr(ERR_NOT_AUTHORIZED);
        });

    });

    // ============================================================
    // VERIFY TEMPLATE
    // ============================================================

    describe('verify-template', () => {

        it('DAO can verify a security template and store its hash', () => {
            // Arrange — set DAO as governor first, then verify a template
            const { deployer } = getAccounts();

            // Set dao-core as the governing contract
            simnet.callPublicFn(
                REGISTRY,
                'set-dao-contract',
                [Cl.contractPrincipal(deployer, contracts.daoCore)],
                deployer
            );

            // Act — DAO verifies the ownable-template contract
            const result = simnet.callPublicFn(
                REGISTRY,
                'verify-template',
                [
                    // The contract being verified
                    Cl.contractPrincipal(deployer, 'ownable-template'),
                    // Human readable name
                    Cl.stringAscii(TEMPLATE_NAME),
                    // Description of what this template does
                    Cl.stringUtf8(TEMPLATE_DESC),
                ],
                // Called by dao-core (the authorized governor)
                `${deployer}.${contracts.daoCore}`
            );

            // Assert — returns the computed hash (buff 32)
            expect(result.result).toBeOk(Cl.buffer(new Uint8Array(32)));
        });

        it('non-DAO caller cannot verify a template', () => {
            // Arrange
            const { deployer } = getAccounts();

            // Act — operator1 tries to verify directly without DAO authority
            const result = simnet.callPublicFn(
                REGISTRY,
                'verify-template',
                [
                    Cl.contractPrincipal(deployer, 'ownable-template'),
                    Cl.stringAscii(TEMPLATE_NAME),
                    Cl.stringUtf8(TEMPLATE_DESC),
                ],
                operators.operator1
            );

            // Assert — must fail with not authorized
            expect(result.result).toBeErr(ERR_NOT_AUTHORIZED);
        });

        it('cannot verify the same template twice', () => {
            // Arrange — set DAO and verify once
            const { deployer } = getAccounts();
            const daoAddress = `${deployer}.${contracts.daoCore}`;

            simnet.callPublicFn(
                REGISTRY,
                'set-dao-contract',
                [Cl.contractPrincipal(deployer, contracts.daoCore)],
                deployer
            );

            // First verification — should succeed
            simnet.callPublicFn(
                REGISTRY,
                'verify-template',
                [
                    Cl.contractPrincipal(deployer, 'ownable-template'),
                    Cl.stringAscii(TEMPLATE_NAME),
                    Cl.stringUtf8(TEMPLATE_DESC),
                ],
                daoAddress
            );

            // Act — try to verify the same contract again
            const result = simnet.callPublicFn(
                REGISTRY,
                'verify-template',
                [
                    Cl.contractPrincipal(deployer, 'ownable-template'),
                    Cl.stringAscii(TEMPLATE_NAME),
                    Cl.stringUtf8(TEMPLATE_DESC),
                ],
                daoAddress
            );

            // Assert — must fail with already verified
            expect(result.result).toBeErr(ERR_ALREADY_VERIFIED);
        });

        it('total verified count increments after each verification', () => {
            // Arrange
            const { deployer } = getAccounts();
            const daoAddress = `${deployer}.${contracts.daoCore}`;

            simnet.callPublicFn(
                REGISTRY,
                'set-dao-contract',
                [Cl.contractPrincipal(deployer, contracts.daoCore)],
                deployer
            );

            // Check count before verification
            const before = simnet.callReadOnlyFn(
                REGISTRY,
                'get-total-verified',
                [],
                deployer
            );
            expect(before.result).toBeOk(Cl.uint(0));

            // Act — verify one template
            simnet.callPublicFn(
                REGISTRY,
                'verify-template',
                [
                    Cl.contractPrincipal(deployer, 'ownable-template'),
                    Cl.stringAscii(TEMPLATE_NAME),
                    Cl.stringUtf8(TEMPLATE_DESC),
                ],
                daoAddress
            );

            // Assert — count should now be 1
            const after = simnet.callReadOnlyFn(
                REGISTRY,
                'get-total-verified',
                [],
                deployer
            );
            expect(after.result).toBeOk(Cl.uint(1));
        });

    });

    // ============================================================
    // IS VERIFIED
    // ============================================================

    describe('is-verified', () => {

        it('returns true for a verified active template', () => {
            // Arrange — verify a template first
            const { deployer } = getAccounts();
            const daoAddress = `${deployer}.${contracts.daoCore}`;

            simnet.callPublicFn(
                REGISTRY,
                'set-dao-contract',
                [Cl.contractPrincipal(deployer, contracts.daoCore)],
                deployer
            );

            simnet.callPublicFn(
                REGISTRY,
                'verify-template',
                [
                    Cl.contractPrincipal(deployer, 'ownable-template'),
                    Cl.stringAscii(TEMPLATE_NAME),
                    Cl.stringUtf8(TEMPLATE_DESC),
                ],
                daoAddress
            );

            // Act — check if the template is verified
            const result = simnet.callReadOnlyFn(
                REGISTRY,
                'is-verified',
                [Cl.contractPrincipal(deployer, 'ownable-template')],
                deployer
            );

            // Assert — should return true
            expect(result.result).toBeOk(Cl.bool(true));
        });

        it('returns false for a contract that was never verified', () => {
            // Arrange
            const { deployer } = getAccounts();

            // Act — check a contract that was never submitted
            const result = simnet.callReadOnlyFn(
                REGISTRY,
                'is-verified',
                [Cl.contractPrincipal(deployer, 'dao-core')],
                deployer
            );

            // Assert — should return false not an error
            expect(result.result).toBeOk(Cl.bool(false));
        });

    });

    // ============================================================
    // REVOKE TEMPLATE
    // ============================================================

    describe('revoke-template', () => {

        it('DAO can revoke a verified template', () => {
            // Arrange — verify first then revoke
            const { deployer } = getAccounts();
            const daoAddress = `${deployer}.${contracts.daoCore}`;

            simnet.callPublicFn(
                REGISTRY,
                'set-dao-contract',
                [Cl.contractPrincipal(deployer, contracts.daoCore)],
                deployer
            );

            simnet.callPublicFn(
                REGISTRY,
                'verify-template',
                [
                    Cl.contractPrincipal(deployer, 'ownable-template'),
                    Cl.stringAscii(TEMPLATE_NAME),
                    Cl.stringUtf8(TEMPLATE_DESC),
                ],
                daoAddress
            );

            // Act — DAO revokes the template
            const result = simnet.callPublicFn(
                REGISTRY,
                'revoke-template',
                [Cl.contractPrincipal(deployer, 'ownable-template')],
                daoAddress
            );

            // Assert — revocation succeeds
            expect(result.result).toBeOk(Cl.bool(true));
        });

        it('is-verified returns false after revocation', () => {
            // Arrange — verify then revoke
            const { deployer } = getAccounts();
            const daoAddress = `${deployer}.${contracts.daoCore}`;

            simnet.callPublicFn(
                REGISTRY,
                'set-dao-contract',
                [Cl.contractPrincipal(deployer, contracts.daoCore)],
                deployer
            );

            simnet.callPublicFn(
                REGISTRY,
                'verify-template',
                [
                    Cl.contractPrincipal(deployer, 'ownable-template'),
                    Cl.stringAscii(TEMPLATE_NAME),
                    Cl.stringUtf8(TEMPLATE_DESC),
                ],
                daoAddress
            );

            simnet.callPublicFn(
                REGISTRY,
                'revoke-template',
                [Cl.contractPrincipal(deployer, 'ownable-template')],
                daoAddress
            );

            // Act — check verification status after revocation
            const result = simnet.callReadOnlyFn(
                REGISTRY,
                'is-verified',
                [Cl.contractPrincipal(deployer, 'ownable-template')],
                deployer
            );

            // Assert — should now return false
            expect(result.result).toBeOk(Cl.bool(false));
        });

        it('cannot revoke a template that does not exist', () => {
            // Arrange
            const { deployer } = getAccounts();
            const daoAddress = `${deployer}.${contracts.daoCore}`;

            simnet.callPublicFn(
                REGISTRY,
                'set-dao-contract',
                [Cl.contractPrincipal(deployer, contracts.daoCore)],
                deployer
            );

            // Act — try to revoke something never verified
            const result = simnet.callPublicFn(
                REGISTRY,
                'revoke-template',
                [Cl.contractPrincipal(deployer, 'dao-core')],
                daoAddress
            );

            // Assert — must fail with template not found
            expect(result.result).toBeErr(ERR_TEMPLATE_NOT_FOUND);
        });

        it('cannot revoke a template that is already revoked', () => {
            // Arrange — verify then revoke once
            const { deployer } = getAccounts();
            const daoAddress = `${deployer}.${contracts.daoCore}`;

            simnet.callPublicFn(
                REGISTRY,
                'set-dao-contract',
                [Cl.contractPrincipal(deployer, contracts.daoCore)],
                deployer
            );

            simnet.callPublicFn(
                REGISTRY,
                'verify-template',
                [
                    Cl.contractPrincipal(deployer, 'ownable-template'),
                    Cl.stringAscii(TEMPLATE_NAME),
                    Cl.stringUtf8(TEMPLATE_DESC),
                ],
                daoAddress
            );

            // First revocation
            simnet.callPublicFn(
                REGISTRY,
                'revoke-template',
                [Cl.contractPrincipal(deployer, 'ownable-template')],
                daoAddress
            );

            // Act — try to revoke again
            const result = simnet.callPublicFn(
                REGISTRY,
                'revoke-template',
                [Cl.contractPrincipal(deployer, 'ownable-template')],
                daoAddress
            );

            // Assert — must fail with already revoked
            expect(result.result).toBeErr(ERR_ALREADY_REVOKED);
        });

        it('non-DAO caller cannot revoke a template', () => {
            // Arrange
            const { deployer } = getAccounts();
            const daoAddress = `${deployer}.${contracts.daoCore}`;

            simnet.callPublicFn(
                REGISTRY,
                'set-dao-contract',
                [Cl.contractPrincipal(deployer, contracts.daoCore)],
                deployer
            );

            simnet.callPublicFn(
                REGISTRY,
                'verify-template',
                [
                    Cl.contractPrincipal(deployer, 'ownable-template'),
                    Cl.stringAscii(TEMPLATE_NAME),
                    Cl.stringUtf8(TEMPLATE_DESC),
                ],
                daoAddress
            );

            // Act — operator1 tries to revoke directly
            const result = simnet.callPublicFn(
                REGISTRY,
                'revoke-template',
                [Cl.contractPrincipal(deployer, 'ownable-template')],
                operators.operator1
            );

            // Assert — must fail with not authorized
            expect(result.result).toBeErr(ERR_NOT_AUTHORIZED);
        });

    });

    // ============================================================
    // READ-ONLY QUERIES
    // ============================================================

    describe('read-only queries', () => {

        it('get-hash-by-name returns the hash after verification', () => {
            // Arrange
            const { deployer } = getAccounts();
            const daoAddress = `${deployer}.${contracts.daoCore}`;

            simnet.callPublicFn(
                REGISTRY,
                'set-dao-contract',
                [Cl.contractPrincipal(deployer, contracts.daoCore)],
                deployer
            );

            simnet.callPublicFn(
                REGISTRY,
                'verify-template',
                [
                    Cl.contractPrincipal(deployer, 'ownable-template'),
                    Cl.stringAscii(TEMPLATE_NAME),
                    Cl.stringUtf8(TEMPLATE_DESC),
                ],
                daoAddress
            );

            // Act — look up the hash by template name
            const result = simnet.callReadOnlyFn(
                REGISTRY,
                'get-hash-by-name',
                [Cl.stringAscii(TEMPLATE_NAME)],
                deployer
            );

            // Assert — should return some value (the hash)
            expect(result.result).toBeOk(Cl.some(Cl.buffer(new Uint8Array(32))));
        });

        it('get-hash-by-name returns none for unknown template name', () => {
            // Arrange
            const { deployer } = getAccounts();

            // Act — look up a name that was never registered
            const result = simnet.callReadOnlyFn(
                REGISTRY,
                'get-hash-by-name',
                [Cl.stringAscii('unknown-template')],
                deployer
            );

            // Assert — should return none
            expect(result.result).toBeOk(Cl.none());
        });

        it('get-registry-version returns the correct version', () => {
            // Arrange
            const { deployer } = getAccounts();

            // Act
            const result = simnet.callReadOnlyFn(
                REGISTRY,
                'get-registry-version',
                [],
                deployer
            );

            // Assert — version should be 1
            expect(result.result).toBeOk(Cl.uint(1));
        });

        it('get-dao-contract returns the current governing DAO address', () => {
            // Arrange — set DAO first
            const { deployer } = getAccounts();

            simnet.callPublicFn(
                REGISTRY,
                'set-dao-contract',
                [Cl.contractPrincipal(deployer, contracts.daoCore)],
                deployer
            );

            // Act
            const result = simnet.callReadOnlyFn(
                REGISTRY,
                'get-dao-contract',
                [],
                deployer
            );

            // Assert — should return dao-core address
            expect(result.result).toBeOk(
                Cl.contractPrincipal(deployer, contracts.daoCore)
            );
        });

    });

});
