pragma solidity ^0.4.11;

import "../common/Ownable.sol";

contract DaoOwnable is Ownable{

    address public dao = address(0);

    event DaoOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the dao.
     */
    modifier onlyDao() {
        require(msg.sender == dao);
        _;
    }

    modifier onlyDaoOrOwner() {
        require(msg.sender == dao || msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newDao.
     * @param newDao The address to transfer ownership to.
     */
    function transferDao(address newDao) onlyOwner {
        require(newDao != address(0));
        DaoOwnershipTransferred(owner, newDao);
        dao = newDao;
    }

}
