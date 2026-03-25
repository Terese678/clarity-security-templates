// Title: Verification Registry Test
// Author: Timothy Terese Chimbiv
// Purpose: Test the on-chain verification registry for Clarity security templates
// Tests cover: verifying templates, revoking templates, querying the registry,
// authorization checks, and duplicate prevention

import { tx } from '@stacks/clarinet-sdk';
import { Cl } from '@stacks/transactions';
import { describe, expect, it, beforeEach } from 'vitest';
import { contracts, getAccounts, initializeDAO } from './test-helpers';

// Registry contract name — matches Clarinet.toml entry
const REGISTRY = 'verification-registry';

// Template details used across tests
const TEMPLATE_NAME = 'ownable-template';
const TEMPLATE_DESC = 'Standard ownership pattern for Clarity contracts';

// Error codes defined in verification-registry.clar
const ERR_NOT_AUTHORIZED     = Cl.uint(900);
const ERR_ALREADY_VERIFIED   = Cl.uint(901);
const ERR_TEMPLATE_NOT_FOUND = Cl.uint(902);
const ERR_ALREADY_REVOKED    = Cl.uint(904);

describe('Verification Registry', () => {

    beforeEach(() => {
        initializeDAO();
    });

    // ============================================================
    // SET DAO CONTRACT
    // ============================================================

    describe('set-dao-contract', () => {

        it('deployer can hand governance over to the DAO', () => {
            const { deployer } = getAccounts();

            const result = simnet.callPublicFn(
                REGISTRY,
                'set-dao-contract',
                [Cl.contractPrincipal(deployer, contracts.daoCore)],
                deployer
            );

            expect(result.result).toBeOk(Cl.bool(true));
        });

        it('non-deployer cannot change the DAO contract', () => {
            const { deployer, wallet1 } = getAccounts();

            const result = simnet.callPublicFn(
                REGISTRY,
                'set-dao-contract',
                [Cl.contractPrincipal(deployer, contracts.daoCore)],
                wallet1  // wallet1 is not the deployer, so this should fail
            );

            expect(result.result).toBeErr(ERR_NOT_AUTHORIZED);
        });

    });

    // ============================================================
    // VERIFY TEMPLATE
    // ============================================================

    describe('verify-template', () => {

        it('DAO can verify a security template and store its hash', () => {
            const { deployer } = getAccounts();

            const result = simnet.callPublicFn(
                REGISTRY,
                'verify-template',
                [
                    Cl.contractPrincipal(deployer, 'ownable-template'),
                    Cl.stringAscii(TEMPLATE_NAME),
                    Cl.stringUtf8(TEMPLATE_DESC),
                ],
                deployer
            );

            // verify it's ok and is a 32-byte buffer
            expect(result.result.type).toBe('ok');
            const hash = (result.result as any).value;
            expect(hash.type).toBe('buffer');
            expect(hash.value.length).toBe(64);
        });

        it('non-DAO caller cannot verify a template', () => {
            const { deployer, wallet1 } = getAccounts();

            const result = simnet.callPublicFn(
                REGISTRY,
                'verify-template',
                [
                    Cl.contractPrincipal(deployer, 'ownable-template'),
                    Cl.stringAscii(TEMPLATE_NAME),
                    Cl.stringUtf8(TEMPLATE_DESC),
                ],
                wallet1  // not the dao-contract
            );

            expect(result.result).toBeErr(ERR_NOT_AUTHORIZED);
        });

        it('cannot verify the same template twice', () => {
            const { deployer } = getAccounts();

            simnet.callPublicFn(
                REGISTRY,
                'verify-template',
                [
                    Cl.contractPrincipal(deployer, 'ownable-template'),
                    Cl.stringAscii(TEMPLATE_NAME),
                    Cl.stringUtf8(TEMPLATE_DESC),
                ],
                deployer
            );

            const result = simnet.callPublicFn(
                REGISTRY,
                'verify-template',
                [
                    Cl.contractPrincipal(deployer, 'ownable-template'),
                    Cl.stringAscii(TEMPLATE_NAME),
                    Cl.stringUtf8(TEMPLATE_DESC),
                ],
                deployer
            );

            expect(result.result).toBeErr(ERR_ALREADY_VERIFIED);
        });

        it('total verified count increments after each verification', () => {
            const { deployer } = getAccounts();

            const before = simnet.callReadOnlyFn(
                REGISTRY,
                'get-total-verified',
                [],
                deployer
            );
            expect(before.result).toBeOk(Cl.uint(0));

            simnet.callPublicFn(
                REGISTRY,
                'verify-template',
                [
                    Cl.contractPrincipal(deployer, 'ownable-template'),
                    Cl.stringAscii(TEMPLATE_NAME),
                    Cl.stringUtf8(TEMPLATE_DESC),
                ],
                deployer
            );

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
            const { deployer } = getAccounts();

            simnet.callPublicFn(
                REGISTRY,
                'verify-template',
                [
                    Cl.contractPrincipal(deployer, 'ownable-template'),
                    Cl.stringAscii(TEMPLATE_NAME),
                    Cl.stringUtf8(TEMPLATE_DESC),
                ],
                deployer
            );

            const result = simnet.callReadOnlyFn(
                REGISTRY,
                'is-verified',
                [Cl.contractPrincipal(deployer, 'ownable-template')],
                deployer
            );

            expect(result.result).toBeOk(Cl.bool(true));
        });

        it('returns false for a contract that was never verified', () => {
            const { deployer } = getAccounts();

            const result = simnet.callReadOnlyFn(
                REGISTRY,
                'is-verified',
                [Cl.contractPrincipal(deployer, 'dao-core')],
                deployer
            );

            expect(result.result).toBeOk(Cl.bool(false));
        });

    });

    // ============================================================
    // REVOKE TEMPLATE
    // ============================================================

    describe('revoke-template', () => {

        it('DAO can revoke a verified template', () => {
            const { deployer } = getAccounts();

            simnet.callPublicFn(
                REGISTRY,
                'verify-template',
                [
                    Cl.contractPrincipal(deployer, 'ownable-template'),
                    Cl.stringAscii(TEMPLATE_NAME),
                    Cl.stringUtf8(TEMPLATE_DESC),
                ],
                deployer
            );

            const result = simnet.callPublicFn(
                REGISTRY,
                'revoke-template',
                [Cl.contractPrincipal(deployer, 'ownable-template')],
                deployer
            );

            expect(result.result).toBeOk(Cl.bool(true));
        });

        it('is-verified returns false after revocation', () => {
            const { deployer } = getAccounts();

            simnet.callPublicFn(
                REGISTRY,
                'verify-template',
                [
                    Cl.contractPrincipal(deployer, 'ownable-template'),
                    Cl.stringAscii(TEMPLATE_NAME),
                    Cl.stringUtf8(TEMPLATE_DESC),
                ],
                deployer
            );

            simnet.callPublicFn(
                REGISTRY,
                'revoke-template',
                [Cl.contractPrincipal(deployer, 'ownable-template')],
                deployer
            );

            const result = simnet.callReadOnlyFn(
                REGISTRY,
                'is-verified',
                [Cl.contractPrincipal(deployer, 'ownable-template')],
                deployer
            );

            expect(result.result).toBeOk(Cl.bool(false));
        });

        it('cannot revoke a template that does not exist', () => {
            const { deployer } = getAccounts();

            const result = simnet.callPublicFn(
                REGISTRY,
                'revoke-template',
                [Cl.contractPrincipal(deployer, 'dao-core')],
                deployer
            );

            expect(result.result).toBeErr(ERR_TEMPLATE_NOT_FOUND);
        });

        it('cannot revoke a template that is already revoked', () => {
            const { deployer } = getAccounts();

            simnet.callPublicFn(
                REGISTRY,
                'verify-template',
                [
                    Cl.contractPrincipal(deployer, 'ownable-template'),
                    Cl.stringAscii(TEMPLATE_NAME),
                    Cl.stringUtf8(TEMPLATE_DESC),
                ],
                deployer
            );

            simnet.callPublicFn(
                REGISTRY,
                'revoke-template',
                [Cl.contractPrincipal(deployer, 'ownable-template')],
                deployer
            );

            const result = simnet.callPublicFn(
                REGISTRY,
                'revoke-template',
                [Cl.contractPrincipal(deployer, 'ownable-template')],
                deployer
            );

            expect(result.result).toBeErr(ERR_ALREADY_REVOKED);
        });

        it('non-DAO caller cannot revoke a template', () => {
            const { deployer, wallet1 } = getAccounts();

            simnet.callPublicFn(
                REGISTRY,
                'verify-template',
                [
                    Cl.contractPrincipal(deployer, 'ownable-template'),
                    Cl.stringAscii(TEMPLATE_NAME),
                    Cl.stringUtf8(TEMPLATE_DESC),
                ],
                deployer
            );

            const result = simnet.callPublicFn(
                REGISTRY,
                'revoke-template',
                [Cl.contractPrincipal(deployer, 'ownable-template')],
                wallet1  // not the dao-contract
            );

            expect(result.result).toBeErr(ERR_NOT_AUTHORIZED);
        });

    });

    // ============================================================
    // READ-ONLY QUERIES
    // ============================================================

    describe('read-only queries', () => {

        it('get-hash-by-name returns the hash after verification', () => {
            const { deployer } = getAccounts();

            simnet.callPublicFn(
                REGISTRY,
                'verify-template',
                [
                    Cl.contractPrincipal(deployer, 'ownable-template'),
                    Cl.stringAscii(TEMPLATE_NAME),
                    Cl.stringUtf8(TEMPLATE_DESC),
                ],
                deployer
            );

            const result = simnet.callReadOnlyFn(
                REGISTRY,
                'get-hash-by-name',
                [Cl.stringAscii(TEMPLATE_NAME)],
                deployer
            );

            // Returns (ok (some <32-byte-hash>)) — just verify the structure
            expect(result.result.type).toBe('ok');
            const inner = (result.result as any).value;
            expect(inner.type).toBe('some');
            expect(inner.value.type).toBe('buffer');
            expect(inner.value.value.length).toBe(64);
        });

        it('get-hash-by-name returns none for unknown template name', () => {
            const { deployer } = getAccounts();

            const result = simnet.callReadOnlyFn(
                REGISTRY,
                'get-hash-by-name',
                [Cl.stringAscii('unknown-template')],
                deployer
            );

            expect(result.result).toBeOk(Cl.none());
        });

        it('get-registry-version returns the correct version', () => {
            const { deployer } = getAccounts();

            const result = simnet.callReadOnlyFn(
                REGISTRY,
                'get-registry-version',
                [],
                deployer
            );

            expect(result.result).toBeOk(Cl.uint(1));
        });

        it('get-dao-contract returns the current governing DAO address', () => {
            const { deployer } = getAccounts();

            const result = simnet.callReadOnlyFn(
                REGISTRY,
                'get-dao-contract',
                [],
                deployer
            );

            expect(result.result).toBeOk(Cl.standardPrincipal(deployer));
        });

    });

});


