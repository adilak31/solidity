// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

contract Example{

    event Receive(address indexed sender, uint256 indexed value);
    event SetData(uint256 indexed number, string str, uint256[] data);

    receive() external payable{
        emit Receive(msg.sender,msg.value);
    }

    function setData(uint256 number, string memory str, uint256[] memory data)public {
        emit SetData(number,str,data);
    }
}