//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IRytellHero {
  function walletOfOwner(address owner_)
    external
    view
    returns (uint256[] memory);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

contract StakeHero is IERC721Receiver{
  struct HeroStatus {
    bool staked;
    uint256 lastStaked;
    uint256 lastUnstaked;
    uint256 heroId;
  }

  mapping(address => HeroStatus[]) stakedHeros;

  event StakedAHero(address who, uint256 heroNumber);
  event ReceivedERC721(
    address operator,
    address from,
    uint256 tokenId,
    bytes data
  );

  address rytellHerosContract;

  constructor(address _rytellHerosContract) {
    rytellHerosContract = _rytellHerosContract;
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) override external returns (bytes4) {
    emit ReceivedERC721(operator, from, tokenId, data);
    return IERC721Receiver(this).onERC721Received.selector;
  }

  function senderOwnsHero(uint256 heroNumber) public view returns (bool) {
    uint256[] memory accountHeros = IRytellHero(rytellHerosContract)
      .walletOfOwner(msg.sender);
    for (uint256 index = 0; index < accountHeros.length; index++) {
      if (accountHeros[index] == heroNumber) {
        return true;
      }
    }

    return false;
  }

  function acquireOwnership(uint256 heroNumber) public {
    IRytellHero(rytellHerosContract).safeTransferFrom(
      msg.sender,
      address(this),
      heroNumber
    );
  }

  function stake(uint256 heroNumber) public {
    require(senderOwnsHero(heroNumber), "Rytell: you don't own this hero");
    acquireOwnership(heroNumber);
    HeroStatus[] storage herosOfAccount = stakedHeros[msg.sender];
    if (herosOfAccount.length > 0) {
      bool foundHero = false;
      for (uint256 index = 0; index < herosOfAccount.length; index++) {
        if (herosOfAccount[index].heroId == heroNumber) {
          require(
            herosOfAccount[index].staked == false,
            "Rytell: hero is already staked"
          );
          herosOfAccount[index].lastStaked = block.timestamp;
          herosOfAccount[index].staked = true;
          foundHero = true;
          emit StakedAHero(msg.sender, heroNumber);
          return;
        }
      }

      if (foundHero == false) {
        herosOfAccount.push(
          HeroStatus({
            staked: true,
            lastStaked: block.timestamp,
            lastUnstaked: 0,
            heroId: heroNumber
          })
        );
        emit StakedAHero(msg.sender, heroNumber);
      }
    } else {
      herosOfAccount.push(
        HeroStatus({
          staked: true,
          lastStaked: block.timestamp,
          lastUnstaked: 0,
          heroId: heroNumber
        })
      );
      emit StakedAHero(msg.sender, heroNumber);
    }
  }

  function unstake(uint256 heroNumber) public view {
    require(senderOwnsHero(heroNumber), "Rytell: you don't own this hero");
    HeroStatus[] storage herosOfAccount = stakedHeros[msg.sender];
    require(
      herosOfAccount.length > 0,
      "Rytell: you don't have any staked hero"
    );

    // TODO unstake
  }
}
