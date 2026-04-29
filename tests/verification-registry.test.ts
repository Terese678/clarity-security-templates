// Author: Timothy Chimbiv
// These test ensure that only the owner can 
// verify and revoke templates, and each templates's status is 
// tracked by the registry
// Thats the actual behaviour the verification registry tests exhibit

import { describe, it, expect } from "vitest";
import { Cl } from "@stacks/transactions";

const A = simnet.getAccounts();
const d = A.get("deployer")!;
const out = A.get("wallet_1")!;   
const next = A.get("wallet_2")!;  

// Template we verified in these tests is the wallet contract
const wallet = Cl.contractPrincipal(d, "wallet");

// A contract that does not exist on chain used to test the false case
const missing = Cl.contractPrincipal(d, "missing-contract");

describe("verification-registry", () => {

  // The deployer becomes the owner once the template is deployed
  it("returns owner", () => {
    expect(
      simnet.callReadOnlyFn("verification-registry", "get-contract-owner", [], d).result
    ).toBePrincipal(d);
  });

  // If you're not the owner you can't add template to this registry
  // any person thats calling verify-template should be rejected
  it("only owner verifies", () => {
    expect(
      simnet.callPublicFn("verification-registry", "verify-template", [wallet], out).result
    ).toBeErr(Cl.uint(900));
  });

  // Verifying a template twice will fail because it already exists
  it("verifies and detects duplicate", () => {
    expect(
      simnet.callPublicFn("verification-registry", "verify-template", [wallet], d).result
    ).toBeOk(Cl.bool(true));
    expect(
      simnet.callPublicFn("verification-registry", "verify-template", [wallet], d).result
    ).toBeErr(Cl.uint(901));
  });

  // After a template is verified is-verified should return true for that contract
  it("reads verified status", () => {
    simnet.callPublicFn("verification-registry", "verify-template", [wallet], d);
    expect(
      simnet.callReadOnlyFn("verification-registry", "is-verified", [wallet], d).result
    ).toBeBool(true);
  });

  // The owner can revoke a verified template
  // after revocation is-verified should return false for that contract
  it("revokes template", () => {
    simnet.callPublicFn("verification-registry", "verify-template", [wallet], d);
    expect(
      simnet.callPublicFn("verification-registry", "revoke-template", [wallet], d).result
    ).toBeOk(Cl.bool(true));
    expect(
      simnet.callReadOnlyFn("verification-registry", "is-verified", [wallet], d).result
    ).toBeBool(false);
  });

  // A contrac that was never deployed should return false from is-verified
  it("returns false for missing contract", () => {
    expect(
      simnet.callReadOnlyFn("verification-registry", "is-verified", [missing], d).result
    ).toBeBool(false);
  });

  // The owner can hand control of the registry to another address
  // after the transfer the new owner should be reflected in get-contract-owner
  it("transfers owner", () => {
    expect(
      simnet.callPublicFn("verification-registry", "set-contract-owner", [Cl.principal(next)], d).result
    ).toBeOk(Cl.bool(true));
    expect(
      simnet.callReadOnlyFn("verification-registry", "get-contract-owner", [], d).result
    ).toBePrincipal(next);
  });
});