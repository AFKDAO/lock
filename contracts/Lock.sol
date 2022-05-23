pragma solidity ^0.8.0;

import "./interface/ILock.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Lock is ILock, Context {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(address => uint256) private managers;

    uint256 public constant blocksPerMonth = 864000;
    uint256 public constant lockBeginBlock = 864000;

    address public constant AFK = 0x9D88519e9a847044E443E5B62639317652fd001C;

    address public _treasuryVault;
    address public _teamVault;
    address public _advisorVault;
    address public _investorSeedVault;
    address public _investorPrivateAVault;
    address public _investorPublicVault;
    address public _ecosystemVault;

    uint256 public treasuryClaimedCycle;
    uint256 public treasuryClaimedBlock = lockBeginBlock;
    uint256 public teamClaimedCycle = 24;
    uint256 public advisorClaimedCycle = 12;
    uint256 public investorSeedClaimedCycle = 6;
    uint256 public investorPrivateAClaimedCycle = 4;
    uint256 public investorPublicClaimedCycle;
    uint256 public ecosystemClaimedCycle;
    uint256 public ecosystemClaimedBlock = lockBeginBlock;
    uint256 public totalReleaseAmount = 1000000000 * 1e18;

    uint256 constant MIN_SIGNATURES = 3;
    uint256 constant validBlock = 28800;

    uint256 transactionIdx;
    bytes32 transactionHash;
    Transaction public transaction;

    uint256 treasuryTotalAmount = 237800000 * 1e18;
    uint256 ecosystemTotalAmount = 470000000 * 1e18;

    struct Transaction {
        address receiver;
        uint256 amount;
        uint256 signatureCount;
        uint256 transactionIdx;
        uint256 beginBlock;
        mapping(address => uint256) signatures;
    }

    constructor(address[5] memory managers_) {
        for (uint256 i = 0; i < 5; i++) {
            managers[managers_[i]] = 1;
        }
    }

    function transferManageShip(address manager) external override onlyManager {
        require(
            transaction.signatureCount == 0 ||
                block.number > transaction.beginBlock + validBlock,
            "vault is signing"
        );
        managers[_msgSender()] = 0;
        managers[manager] = 1;

        emit TransferManagerShip(_msgSender(), manager);
    }

    function initialize(
        address treasuryVault_,
        address teamVault_,
        address advisorVault_,
        address investorSeedVault_,
        address investorPrivateAVault_,
        address investorPublicVault_,
        address ecosystemVault_
    ) external {
        require(_treasuryVault == address(0), "only initialize once");
        _treasuryVault = treasuryVault_;
        _teamVault = teamVault_;
        _advisorVault = advisorVault_;
        _investorSeedVault = investorSeedVault_;
        _investorPrivateAVault = investorPrivateAVault_;
        _investorPublicVault = investorPublicVault_;
        _ecosystemVault = ecosystemVault_;
    }

    function withdraw(address to, uint256 amount)
        external
        override
        onlyManager
    {
        require(IERC20(AFK).balanceOf(address(this)) >= amount);
        transactionIdx++;

        delete transaction;

        bytes32 tempTransactionHash = keccak256(
            abi.encodePacked(transactionIdx, to, amount)
        );
        transactionHash = tempTransactionHash;
        transaction.amount = amount;
        transaction.signatureCount = 1;
        transaction.receiver = to;
        transaction.transactionIdx = transactionIdx;
        transaction.beginBlock = block.number;
        transaction.signatures[_msgSender()] = 1;
        emit TransactionCreated(_msgSender(), to, amount, transactionIdx);
    }

    function signTransaction(
        uint256 transactionId,
        address receiver,
        uint256 amount
    ) external override onlyManager {
        bytes32 tempTransactionHash = keccak256(
            abi.encodePacked(transactionId, receiver, amount)
        );
        require(
            tempTransactionHash == transactionHash,
            "transaction is invalid"
        );
        require(
            block.number - transaction.beginBlock <= validBlock,
            "transaction is invalid"
        );
        require(transaction.signatures[_msgSender()] != 1, "already sign");
        transaction.transactionIdx;
        transaction.signatureCount++;
        transaction.signatures[_msgSender()] = 1;
        if (transaction.signatureCount >= MIN_SIGNATURES) {
            require(IERC20(AFK).balanceOf(address(this)) >= amount);
            totalReleaseAmount -= amount;
            IERC20(AFK).safeTransfer(receiver, amount);
            emit TransferFunds(receiver, amount);
            delete transaction;
        }
    }

    function claimTreasury() external override lockBegin {
        uint256 releaseAmount;
        uint256 lockCycle = getLockTime();
        if (lockCycle > 108) {
            lockCycle = 108;
        }
        uint256 sixMonthBlock = lockBeginBlock.add(blocksPerMonth.mul(6));
        uint256 blockNum = block.number;

        if (lockCycle > 6 && lockCycle <= 108) {
            if (treasuryClaimedCycle < 6) {
                releaseAmount += treasuryReleaseCalc(
                    treasuryClaimedBlock,
                    sixMonthBlock,
                    6
                );
                releaseAmount += treasuryReleaseCalc(
                    sixMonthBlock,
                    blockNum,
                    lockCycle
                );
            } else {
                releaseAmount += treasuryReleaseCalc(
                    treasuryClaimedBlock,
                    blockNum,
                    lockCycle
                );
            }
        } else {
            releaseAmount += treasuryReleaseCalc(
                treasuryClaimedBlock,
                blockNum,
                lockCycle
            );
        }
        treasuryClaimedCycle = lockCycle;
        treasuryClaimedBlock = blockNum;
        IERC20(AFK).safeTransfer(_treasuryVault, releaseAmount);
    }

    function claimTeam() external override lockBegin {
        uint256 releaseAmount;
        uint256 lockCycle = getLockTime();
        require(lockCycle > 24, "locking");
        if (lockCycle > 48) {
            lockCycle = 48;
        }
        releaseAmount += teamReleaseCalc(teamClaimedCycle, lockCycle);
        teamClaimedCycle = lockCycle;
        IERC20(AFK).safeTransfer(_teamVault, releaseAmount);
    }

    function claimAdvisor() external override lockBegin {
        uint256 releaseAmount;
        uint256 lockCycle = getLockTime();
        require(lockCycle > 12, "locking");
        if (lockCycle > 24) {
            lockCycle = 24;
        }
        releaseAmount += advisorReleaseCalc(advisorClaimedCycle, lockCycle);
        advisorClaimedCycle = lockCycle;
        IERC20(AFK).safeTransfer(_advisorVault, releaseAmount);
    }

    function claimInvestorSeed() external override lockBegin {
        uint256 releaseAmount;
        uint256 lockCycle = getLockTime();
        require(lockCycle > 6, "locking");
        if (lockCycle > 30) {
            lockCycle = 30;
        }
        releaseAmount += investorSeedReleaseCalc(
            investorSeedClaimedCycle,
            lockCycle
        );
        investorSeedClaimedCycle = lockCycle;
        IERC20(AFK).safeTransfer(_investorSeedVault, releaseAmount);
    }

    function claimInvestorPrivateA() external override lockBegin {
        uint256 releaseAmount;
        uint256 lockCycle = getLockTime();
        require(lockCycle > 4, "locking");
        if (lockCycle > 28) {
            lockCycle = 28;
        }
        releaseAmount += investorPrivateAReleaseCalc(
            investorPrivateAClaimedCycle,
            lockCycle
        );
        investorPrivateAClaimedCycle = lockCycle;
        IERC20(AFK).safeTransfer(_investorPrivateAVault, releaseAmount);
    }

    function claimInvestorPublic() external override lockBegin {
        uint256 releaseAmount;
        uint256 lockCycle = getLockTime();
        if (lockCycle > 6) {
            lockCycle = 6;
        }
        releaseAmount += investorPublicReleaseCalc(
            investorPublicClaimedCycle,
            lockCycle
        );
        investorPublicClaimedCycle = lockCycle;
        IERC20(AFK).safeTransfer(_investorPublicVault, releaseAmount);
    }

    function claimEcosystem() external override lockBegin {
        uint256 releaseAmount;
        uint256 lockCycle = getLockTime();
        if (lockCycle > 128) {
            lockCycle = 128;
        }
        uint256 sixMonthBlock = lockBeginBlock.add(blocksPerMonth.mul(6));
        uint256 blockNum = block.number;

        if (lockCycle > 6 && lockCycle <= 128) {
            if (ecosystemClaimedCycle < 6) {
                releaseAmount += ecosystemReleaseCalc(
                    ecosystemClaimedBlock,
                    sixMonthBlock,
                    6
                );
                releaseAmount += ecosystemReleaseCalc(
                    sixMonthBlock,
                    blockNum,
                    lockCycle
                );
            } else {
                releaseAmount += ecosystemReleaseCalc(
                    ecosystemClaimedBlock,
                    blockNum,
                    lockCycle
                );
            }
        } else {
            releaseAmount += ecosystemReleaseCalc(
                ecosystemClaimedBlock,
                blockNum,
                lockCycle
            );
        }
        ecosystemClaimedCycle = lockCycle;
        ecosystemClaimedBlock = blockNum;
        IERC20(AFK).safeTransfer(_ecosystemVault, releaseAmount);
    }

    function treasuryReleaseCalc(
        uint256 beginBlock,
        uint256 endBlock,
        uint256 end
    ) internal view returns (uint256 treasuryRelease) {
        if (end <= 6) {
            treasuryRelease = (endBlock - beginBlock)
                .mul(totalReleaseAmount)
                .mul(1141666)
                .div(1e9)
                .div(blocksPerMonth);
        } else if (end > 6 && end < 108) {
            treasuryRelease = (endBlock - beginBlock)
                .mul(totalReleaseAmount)
                .mul(228)
                .div(1e5)
                .div(blocksPerMonth);
        }
        return treasuryRelease;
    }

    function teamReleaseCalc(uint256 begin, uint256 end)
        internal
        view
        returns (uint256 teamRelease)
    {
        teamRelease = totalReleaseAmount.mul(625).mul(end - begin).div(1e5);
        return teamRelease;
    }

    function advisorReleaseCalc(uint256 begin, uint256 end)
        internal
        view
        returns (uint256 advisorRelease)
    {
        advisorRelease = totalReleaseAmount
            .mul(1666666666)
            .mul(end - begin)
            .div(1e12);
        return advisorRelease;
    }

    function investorSeedReleaseCalc(uint256 begin, uint256 end)
        internal
        view
        returns (uint256 investorSeedRelease)
    {
        investorSeedRelease = totalReleaseAmount
            .mul(1608333)
            .mul(end - begin)
            .div(1e9);
        return investorSeedRelease;
    }

    function investorPrivateAReleaseCalc(uint256 begin, uint256 end)
        internal
        view
        returns (uint256 investorPrivateARelease)
    {
        investorPrivateARelease = totalReleaseAmount
            .mul(27291666666)
            .mul(end - begin)
            .div(1e13);
        return investorPrivateARelease;
    }

    function investorPublicReleaseCalc(uint256 begin, uint256 end)
        internal
        view
        returns (uint256 investorPublicRelease)
    {
        investorPublicRelease = totalReleaseAmount
            .mul(1012500)
            .mul(end - begin)
            .div(1e9);
        return investorPublicRelease;
    }

    function ecosystemReleaseCalc(
        uint256 beginBlock,
        uint256 endBlock,
        uint256 end
    ) internal view returns (uint256 ecosystemRelease) {
        if (end <= 6) {
            ecosystemRelease = (endBlock - beginBlock)
                .mul(totalReleaseAmount)
                .mul(16916666)
                .div(1e10)
                .div(blocksPerMonth);
        } else if (end > 6 && end <= 128) {
            ecosystemRelease = (endBlock - beginBlock)
                .mul(totalReleaseAmount)
                .mul(3203333)
                .div(1e9)
                .div(blocksPerMonth);
        }
        return ecosystemRelease;
    }

    function getLockTime() internal view returns (uint256 lockTime) {
        if (block.number < lockBeginBlock) {
            return 0;
        }
        uint256 lockBlock = block.number - lockBeginBlock;
        lockTime = lockBlock / blocksPerMonth;
        return lockTime;
    }

    modifier lockBegin() {
        require(block.number > lockBeginBlock);
        _;
    }

    modifier onlyManager() {
        require(managers[_msgSender()] == 1, "only Manager call it");
        _;
    }
}
