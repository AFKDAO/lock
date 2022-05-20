pragma solidity ^0.8.0;

interface ILock {
    function claimTreasury() external;

    function claimTeam() external;

    function claimAdvisor() external;

    function claimInvestorSeed() external;

    function claimInvestorPrivateA() external;

    function claimInvestorPublic() external;

    function claimEcosystem() external
}