// Author: Timothy Chimbiv
// These tests confirms how the rules contract work
// it checks what requests are alllowed before any action is approved and 
// executed through the wallet

import { describe, it, expect } from "vitest";
import { Cl } from "@stacks/transactions";

const deployer = simnet.getAccounts().get("deployer")!;

describe("rules", () => {

  // wallet with some data should pass
  it("accepts valid request", () => {
    expect(
      simnet.callPublicFn("rules", "is-allowed", [Cl.bufferFromHex("aa")], deployer).result
    ).toBeOk(Cl.bool(true));
  });

  // empty request are rejected
  it("rejects empty request", () => {
    expect(
      simnet.callPublicFn("rules", "is-allowed", [Cl.bufferFromHex("")], deployer).result
    ).toBeErr(Cl.uint(500));
  });

  // a request that is too large should be rejected to prevent unnecessary data
  // the limit is 1048 bytes, anything above that gets blocked
  it("rejects oversized request", () => {
    expect(
      simnet.callPublicFn("rules", "is-allowed", [Cl.bufferFromHex("aa".repeat(1049))], deployer).result
    ).toBeErr(Cl.uint(501));
  });
});