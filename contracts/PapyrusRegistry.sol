pragma solidity ^0.4.18;

import './common/SafeOwnable.sol';


contract PapyrusRegistry is SafeOwnable {

  // EVENTS

  event TokenUpdated(address contractAddress, string abi, bytes bin);
  event DaoUpdated(address contractAddress, string abi, bytes bin);
  event ChannelManagerUpdated(address contractAddress, string abi, bytes bin);
  event CampaignManagerUpdated(address contractAddress, string abi, bytes bin);

  // PUBLIC FUNCTIONS

  function () public {
    revert();
  }

  function updateTokenContract(address contractAddress, string abi, bytes bin) public onlyOwner {
    tokenAddress = contractAddress;
    tokenAbi = abi;
    tokenBin = bin;
    TokenUpdated(contractAddress, abi, bin);
  }

  function updateDaoContract(address contractAddress, string abi, bytes bin) public onlyOwner {
    daoAddress = contractAddress;
    daoAbi = abi;
    daoBin = bin;
    DaoUpdated(contractAddress, abi, bin);
  }

  function updateChannelManagerContract(address contractAddress, string abi, bytes bin) public onlyOwner {
    channelManagerAddress = contractAddress;
    channelManagerAbi = abi;
    channelManagerBin = bin;
    ChannelManagerUpdated(contractAddress, abi, bin);
  }

  function updateCampaignManagerContract(address contractAddress, string abi, bytes bin) public onlyOwner {
    campaignManagerAddress = contractAddress;
    campaignManagerAbi = abi;
    campaignManagerBin = bin;
    CampaignManagerUpdated(contractAddress, abi, bin);
  }

  // FIELDS

  address public tokenAddress;
  string public tokenAbi;
  bytes public tokenBin;

  address public daoAddress;
  string public daoAbi;
  bytes public daoBin;

  address public channelManagerAddress;
  string public channelManagerAbi;
  bytes public channelManagerBin;

  address public campaignManagerAddress;
  string public campaignManagerAbi;
  bytes public campaignManagerBin;
}
