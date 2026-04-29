// Author: Timothy Chimbiv
//
// These tests tests every action that will require an admins approval
// it tests to ensure that the threshold system, pause control
// and replay prevention all work correctly

import { describe, it, expect } from "vitest";
import { Cl } from "@stacks/transactions";

// extract the accounts from the simulated network
const A = simnet.getAccounts();
const d = A.get("deployer")!;
const a1 = A.get("wallet_1")!;
const a2 = A.get("wallet_2")!;
const a3 = A.get("wallet_3")!;
const out = A.get("wallet_4")!; // this account is not an admin, used to test rejections

// from a repeated hex byte generate a unique 32-byte action id 
const id = (b: string) => Cl.bufferFromHex(b.repeat(32));

// Sample request buffer to passed into execute
const req = Cl.bufferFromHex("aa55");

// This is the rules contract that confirms requests before execution
const rules = Cl.contractPrincipal(d, "rules");

// To initializes the wallet with three admins and a threshold of 2, we need this Helper
const init = () =>
  simnet.callPublicFn("wallet", "initialize", [
    Cl.principal(a1),
    Cl.principal(a2),
    Cl.principal(a3),
    Cl.uint(2),
  ], d);

// Helper that gets two admins to approve the same action
// so we avoid repeatition in every test that needs threshold to be met
const approve2 = (x: ReturnType<typeof id>) => {
  simnet.callPublicFn("wallet", "approve", [x], a1);
  simnet.callPublicFn("wallet", "approve", [x], a2);
};

describe("wallet", () => {

  // Initialize is called once by the deployer and it succeeds after that no more
  // can't be called again because its already been initialized
  it("initializes once", () => {
    expect(init().result).toBeOk(Cl.bool(true));
    expect(init().result).toBeErr(Cl.uint(405));
  });

  // If you're not a registered admin you can not pause and unpause
  it("only admins pause and unpause", () => {
    init();
    expect(simnet.callPublicFn("wallet", "pause", [], out).result).toBeErr(Cl.uint(401));
    expect(simnet.callPublicFn("wallet", "pause", [], a1).result).toBeOk(Cl.bool(true));
    expect(simnet.callPublicFn("wallet", "unpause", [], out).result).toBeErr(Cl.uint(401));
    expect(simnet.callPublicFn("wallet", "unpause", [], a2).result).toBeOk(Cl.bool(true));
  });

  // When the contract is pasued no admin approvals can pass through
  // no action can be carried out during this pause until its unpaused
  it("blocks approval when paused", () => {
    init();
    simnet.callPublicFn("wallet", "pause", [], a1);
    expect(simnet.callPublicFn("wallet", "approve", [id("11")], a1).result).toBeErr(Cl.uint(408));
  });

  // If you're not an admin you can't approve action, and one admin
  // can't approve an action more than once
  it("rejects non-admin and duplicate approval", () => {
    init();
    const x = id("22");
    expect(simnet.callPublicFn("wallet", "approve", [x], out).result).toBeErr(Cl.uint(404));
    expect(simnet.callPublicFn("wallet", "approve", [x], a1).result).toBeOk(Cl.bool(true));
    expect(simnet.callPublicFn("wallet", "approve", [x], a1).result).toBeErr(Cl.uint(402));
  });

  // The cout should reflect after two admins approve
  it("tracks approval count", () => {
    init();
    const x = id("33");
    approve2(x);
    expect(simnet.callReadOnlyFn("wallet", "get-approval-count", [x], a1).result).toBeUint(2);
  });

  // If only one admin approves no action can pass 
  // the threshold of two must be met for a transaction to pass
  it("rejects execute before threshold", () => {
    init();
    const x = id("44");
    simnet.callPublicFn("wallet", "approve", [x], a1);
    expect(simnet.callPublicFn("wallet", "execute", [x, req, rules], a1).result).toBeErr(Cl.uint(403));
  });

  // The transaction will execute correctly if two approvals are met
  it("executes after threshold", () => {
    init();
    const x = id("55");
    approve2(x);
    expect(simnet.callPublicFn("wallet", "execute", [x, req, rules], a1).result).toBeOk(Cl.bool(true));
  });

  // After an action is approved and executed it should not approved the second time
  it("prevents replay", () => {
    init();
    const x = id("66");
    approve2(x);
    simnet.callPublicFn("wallet", "execute", [x, req, rules], a1);
    expect(simnet.callPublicFn("wallet", "execute", [x, req, rules], a1).result).toBeErr(Cl.uint(406));
  });
});