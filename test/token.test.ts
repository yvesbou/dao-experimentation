import { expect } from "chai";
import { ethers } from "hardhat";

describe("Token", function () {
  it("Should return name Token", async function () {
    const DAOToken = await ethers.getContractFactory("DAOToken");
    const token = await DAOToken.deploy(200);
    await token.deployed();

    expect(await token.name()).to.equal("DAO Token");
  });
});
