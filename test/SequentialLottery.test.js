const { expect } = require("chai");
const { ethers } = require("hardhat");
describe("SequentialLottery", function () {
  let lottery, owner, player1, player2;

  beforeEach(async function () {
    [owner, player1, player2] = await ethers.getSigners();

    const Lottery = await ethers.getContractFactory("SequentialLottery");
    lottery = await Lottery.deploy(
      "0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B", //coordinator
      "0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae", //keyhash
      "12579", // VRF subscription
    );
    await lottery.deployed();
  });

  it("should allow a player to buy a 7-number ticket", async function () {
    const numbers = [1, 2, 3, 4, 5, 6, 7];

    await expect(
      lottery
        .connect(player1)
        .buyTicket(numbers, { value: ethers.utils.parseEther("0.001") }),
    )
      .to.emit(lottery, "TicketPurchased")
      .withArgs(player1.address, numbers);
  });

  it("should reject duplicate numbers", async function () {
    const numbers = [1, 2, 2, 4, 5, 6, 7];

    await expect(
      lottery
        .connect(player1)
        .buyTicket(numbers, { value: ethers.utils.parseEther("0.001") }),
    ).to.be.revertedWith("Duplicate numbers not allowed");
  });

  it("should reject numbers out of 1-49", async function () {
    const numbers = [0, 2, 3, 4, 5, 6, 50];

    await expect(
      lottery
        .connect(player1)
        .buyTicket(numbers, { value: ethers.utils.parseEther("0.001") }),
    ).to.be.revertedWith("Numbers must be 1-49");
  });

  it("should draw numbers and distribute prizes", async function () {
    // Buy tickets
    await lottery.connect(player1).buyTicket([1, 2, 3, 4, 5, 6, 7], {
      value: ethers.utils.parseEther("0.001"),
    });
    await lottery.connect(player2).buyTicket([7, 8, 9, 10, 11, 12, 13], {
      value: ethers.utils.parseEther("0.001"),
    });

    // Simulate VRF callback (mock randomWords)
    const randomWords = [
      ethers.BigNumber.from("1234567890123456789012345678901234567890"),
    ];

    await lottery.fulfillRandomWords(1, randomWords); // call internal manually in test

    const drawn = await lottery.getDrawnNumbers(1);
    console.log(
      "Drawn numbers:",
      drawn.map((n) => n.toString()),
    );
  });
});
