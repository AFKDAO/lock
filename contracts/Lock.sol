pragma solidity ^0.8.0;

import "./interface/ILock.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Lock is ILock {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant blocksPerMonth = 864000;
    uint256 public constant lockBeginBlock = 864000;

    address public constant AFK = ;

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

    uint256 treasuryTotalAmount = 237800000 * 1e18;
    uint256 ecosystemTotalAmount = 470000000 * 1e18;

    constructor(
        address treasuryVault_,
        address teamVault_,
        address advisorVault_,
        address investorSeedVault_,
        address investorPrivateAVault_,
        address investorPublicVault_,
        address ecosystemVault_
    ) {
        _treasuryVault = treasuryVault_;
        _teamVault = teamVault_;
        _advisorVault = advisorVault_;
        _investorSeedVault = investorSeedVault_;
        _investorPrivateAVault = investorPrivateAVault_;
        _investorPublicVault = investorPublicVault_;
        _ecosystemVault = ecosystemVault_;
    }

    function claimTreasury() external override lockBegin {
        uint256 releaseAmount;
        uint256 lockCycle = getLockTime();
        if (lockCycle > 108) {
            lockCycle = 108;
        }
        uint256 sixMonthBlock = lockBeginBlock.add(blocksPerMonth.mul(6));
        uint256 endMonthBlock = lockBeginBlock.add(blocksPerMonth.mul(107));
        uint256 lastMonthBlock = endMonthBlock.add(blocksPerMonth);
        uint256 blockNum = block.number;

        if (lockCycle > 6 && lockCycle < 108) {
            if (treasuryClaimedCycle < 6) {
                releaseAmount += treasuryReleaseCalc(treasuryClaimedBlock, sixMonthBlock, 6);
                releaseAmount += treasuryReleaseCalc(sixMonthBlock, blockNum, lockCycle);
            }else {
                releaseAmount += treasuryReleaseCalc(treasuryClaimedBlock, blockNum, lockCycle);
            }
        } else if (lockCycle == 108) {
            if (blockNum > lastMonthBlock) {
                blockNum = lastMonthBlock;
            }

            if (treasuryClaimedCycle < 6) {
                releaseAmount += treasuryReleaseCalc(treasuryClaimedBlock, sixMonthBlock, 6);
                releaseAmount += treasuryReleaseCalc(sixMonthBlock, endMonthBlock, lockCycle - 1);
                releaseAmount += treasuryReleaseCalc(endMonthBlock, blockNum, lockCycle);

            } else if(treasuryClaimedCycle > 6 && treasuryClaimedCycle < 108) {
                releaseAmount += treasuryReleaseCalc(treasuryClaimedBlock, endMonthBlock, lockCycle - 1);
                releaseAmount += treasuryReleaseCalc(endMonthBlock, blockNum, lockCycle);
            } else {
                releaseAmount += treasuryReleaseCalc(treasuryClaimedBlock, blockNum, lockCycle);
            }
        } else{
            releaseAmount += treasuryReleaseCalc(treasuryClaimedBlock, blockNum, lockCycle);
        }
        treasuryClaimedCycle = lockCycle;
        treasuryClaimedBlock = blockNum;
        IERC20(AFK).safeTransfer(_treasuryVault,releaseAmount);
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
        IERC20(AFK).safeTransfer(_teamVault,releaseAmount);
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
        IERC20(AFK).safeTransfer(_advisorVault,releaseAmount);
    }

    function claimInvestorSeed() external override lockBegin {
        uint256 releaseAmount;
        uint256 lockCycle = getLockTime();
        require(lockCycle > 6, "locking");
        if (lockCycle > 30) {
            lockCycle = 30;
        }
        releaseAmount += investorSeedReleaseCalc(investorSeedClaimedCycle, lockCycle);
        investorSeedClaimedCycle = lockCycle;
        IERC20(AFK).safeTransfer(_investorSeedVault,releaseAmount);
    }

    function claimInvestorPrivateA() external override lockBegin {
        uint256 releaseAmount;
        uint256 lockCycle = getLockTime();
        require(lockCycle > 4, "locking");
        if (lockCycle > 28) {
            lockCycle = 28;
        }
        releaseAmount += investorPrivateAReleaseCalc(investorPrivateAClaimedCycle, lockCycle);
        investorPrivateAClaimedCycle = lockCycle;
        IERC20(AFK).safeTransfer(_investorPrivateAVault,releaseAmount);
    }

    function claimInvestorPublic() external override lockBegin {
        uint256 releaseAmount;
        uint256 lockCycle = getLockTime();
        if (lockCycle > 6) {
            lockCycle = 6;
        }
        releaseAmount += investorPublicReleaseCalc(investorPublicClaimedCycle, lockCycle);
        investorPublicClaimedCycle = lockCycle;
        IERC20(AFK).safeTransfer(_investorPublicVault,releaseAmount);
    }

    function claimEcosystem() external override lockBegin {
        uint256 releaseAmount;
        uint256 lockCycle = getLockTime();
        if (lockCycle > 144) {
            lockCycle = 144;
        }
        uint256 sixMonthBlock = lockBeginBlock.add( blocksPerMonth.mul(6));
        uint256 endMonthBlock = lockBeginBlock.add(blocksPerMonth.mul(143));
        uint256 lastMonthBlock = endMonthBlock.add(blocksPerMonth);
        uint256 blockNum = block.number;

        if (lockCycle > 6 && lockCycle < 144) {
            if (ecosystemClaimedCycle < 6) {
                releaseAmount += ecosystemReleaseCalc(ecosystemClaimedBlock, sixMonthBlock, 6);
                releaseAmount += ecosystemReleaseCalc(sixMonthBlock, blockNum, lockCycle);
            }else {
                releaseAmount += ecosystemReleaseCalc(ecosystemClaimedBlock, blockNum, lockCycle);
            }
        } else if (lockCycle == 144) {
            if (blockNum > lastMonthBlock) {
                blockNum = lastMonthBlock;
            }

            if (ecosystemClaimedCycle < 6) {
                releaseAmount += ecosystemReleaseCalc(ecosystemClaimedBlock, sixMonthBlock, 6);
                releaseAmount += ecosystemReleaseCalc(sixMonthBlock, endMonthBlock, lockCycle - 1);
                releaseAmount += ecosystemReleaseCalc(endMonthBlock, blockNum, lockCycle);

            } else if(ecosystemClaimedCycle > 6 && ecosystemClaimedCycle < 144) {
                releaseAmount += ecosystemReleaseCalc(ecosystemClaimedBlock, endMonthBlock, lockCycle - 1);
                releaseAmount += ecosystemReleaseCalc(endMonthBlock, blockNum, lockCycle);
            } else {
                releaseAmount += ecosystemReleaseCalc(ecosystemClaimedBlock, blockNum, lockCycle);
            }
        } else{
            releaseAmount += ecosystemReleaseCalc(ecosystemClaimedBlock, blockNum, lockCycle);
        }
        ecosystemClaimedCycle = lockCycle;
        ecosystemClaimedBlock = blockNum;
        IERC20(AFK).safeTransfer(_ecosystemVault,releaseAmount);
    }

    function treasuryReleaseCalc(uint256 beginBlock, uint256 endBlock, uint256 end)
        internal
        returns (uint256 treasuryRelease)
    {
        if (end <= 6) {
            treasuryRelease = (endBlock - beginBlock)
                .mul(1e18)
                .mul(1000000000)
                .mul(1141666)
                .div(1e9).div(blocksPerMonth);
        } else if(end>6 && end < 108 ) {
            treasuryRelease = (endBlock - beginBlock)
            .mul(1e18)
            .mul(1000000000)
            .mul(228)
            .div(1e5).div(blocksPerMonth);
        }else {
            treasuryRelease = (endBlock - beginBlock).mul(1e18).mul(670004).div(blocksPerMonth); 
        }
        return treasuryRelease;
    }

    function teamReleaseCalc(uint256 begin, uint256 end)
        internal
        returns (uint256 teamRelease)
    {
        teamRelease = (end - begin).mul(1e18).mul(6250000);
        return teamRelease;
    }

    function advisorReleaseCalc(uint256 begin, uint256 end)
        internal
        returns (uint256 advisorRelease)
    {
        advisorRelease = (end - begin).mul(1e15).mul(1666666666);
        return advisorRelease;
    }

    function investorSeedReleaseCalc(uint256 begin, uint256 end)
        internal
        returns (uint256 investorSeedRelease)
    {
        investorSeedRelease = (end - begin).mul(1e15).mul(1608333333);
        return investorSeedRelease;
    }

    function investorPrivateAReleaseCalc(uint256 begin, uint256 end)
        internal
        returns (uint256 investorPrivateARelease)
    {
        investorPrivateARelease = (end - begin).mul(1e14).mul(27291666666);
        return investorPrivateARelease;
    }

    function investorPublicReleaseCalc(uint256 begin, uint256 end)
        internal
        returns (uint256 investorPublicRelease)
    {
        investorPublicRelease = (end - begin).mul(1e18).mul(1012500);
        return investorPublicRelease;
    }

    function ecosystemReleaseCalc(uint256 beginBlock, uint256 endBlock, uint256 end)
        internal
        returns (uint256 ecosystemRelease)
    {
        if (end <= 6) {
            ecosystemRelease = (endBlock - beginBlock)
                .mul(1e18)
                .mul(1000000000)
                .mul(16916666)
                .div(1e10).div(blocksPerMonth);
        } else if (end > 6 && end < 144){
            ecosystemRelease = (endBlock - beginBlock)
                .mul(1e18)
                .mul(1000000000)
                .mul(3203333)
                .div(1e9).div(blocksPerMonth);
        } else {
            ecosystemRelease = (endBlock - beginBlock).mul(1e17).mul(9933794).div(blocksPerMonth); 
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
}