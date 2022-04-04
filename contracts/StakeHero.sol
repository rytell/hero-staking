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

contract StakeHero is IERC721Receiver {
  struct HeroStatus {
    bool staked;
    uint256 lastStaked;
    uint256 lastUnstaked;
    uint256 heroId;
    address owner;
  }

  mapping(address => HeroStatus[]) public stakedHeros;

  event StakedHero(address who, uint256 heroNumber, uint256 when);
  event ReceivedERC721(
    address operator,
    address from,
    uint256 tokenId,
    bytes data
  );
  event UnstakedHero(address who, uint256 heroNumber, uint256 when);

  address rytellHerosContract;

  constructor(address _rytellHerosContract) {
    rytellHerosContract = _rytellHerosContract;
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external override returns (bytes4) {
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

  function contractOwnsHero(uint256 heroNumber) public view returns (bool) {
    uint256[] memory accountHeros = IRytellHero(rytellHerosContract)
      .walletOfOwner(address(this));
    for (uint256 index = 0; index < accountHeros.length; index++) {
      if (accountHeros[index] == heroNumber) {
        return true;
      }
    }

    return false;
  }

  function senderStakedHero(uint256 heroNumber) public view returns (bool) {
    HeroStatus[] storage accountHeros = stakedHeros[msg.sender];
    for (uint256 index = 0; index < accountHeros.length; index++) {
      if (
        accountHeros[index].heroId == heroNumber && accountHeros[index].staked
      ) {
        return true;
      }
    }

    return false;
  }

  function acquireOwnership(uint256 heroNumber) private {
    IRytellHero(rytellHerosContract).safeTransferFrom(
      msg.sender,
      address(this),
      heroNumber
    );
  }

  function stake(uint256 heroNumber) public {
    require(senderOwnsHero(heroNumber), "Rytell: you don't own this hero");
    acquireOwnership(heroNumber);
    uint256 time = block.timestamp;
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
          herosOfAccount[index].owner = msg.sender;
          foundHero = true;
          emit StakedHero(msg.sender, heroNumber, time);
          return;
        }
      }

      if (foundHero == false) {
        herosOfAccount.push(
          HeroStatus({
            staked: true,
            lastStaked: time,
            lastUnstaked: 0,
            heroId: heroNumber,
            owner: msg.sender
          })
        );
        emit StakedHero(msg.sender, heroNumber, time);
      }
    } else {
      herosOfAccount.push(
        HeroStatus({
          staked: true,
          lastStaked: time,
          lastUnstaked: 0,
          heroId: heroNumber,
          owner: msg.sender
        })
      );
      emit StakedHero(msg.sender, heroNumber, time);
    }
  }

  function unstake(uint256 heroNumber) public {
    require(
      senderStakedHero(heroNumber),
      "Rytell: this hero is not currently staked"
    );
    require(contractOwnsHero(heroNumber), "Rytell: we don't have this hero");
    uint256 time = block.timestamp;
    HeroStatus[] storage herosOfAccount = stakedHeros[msg.sender];
    for (uint256 index = 0; index < herosOfAccount.length; index++) {
      if (herosOfAccount[index].heroId == heroNumber) {
        herosOfAccount[index].lastUnstaked = time;
        herosOfAccount[index].staked = false;
        IRytellHero(rytellHerosContract).safeTransferFrom(
          address(this),
          msg.sender,
          heroNumber
        );
        emit UnstakedHero(msg.sender, heroNumber, time);
      }
    }
  }

  function getStakedHeros(address owner)
    public
    view
    returns (HeroStatus[] memory heroInfo)
  {
    HeroStatus[] storage herosInfo = stakedHeros[owner];
    return herosInfo;
  }
}
