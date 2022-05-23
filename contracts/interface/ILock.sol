pragma solidity ^0.8.0;

interface ILock {
    
    event TransferFunds(address to, uint amount);
	
    event TransactionCreated(
        address from,
        address to,
        uint amount,
        uint transactionId
        );

    event TransferManagerShip(address opereator, address manager);
    
    function withdraw(address to,  uint amount) external;

    function transferManageShip(address manager) external;

    function signTransaction(uint transactionId, address receiver, uint256 amount) external;
    function claimTreasury() external;

    function claimTeam() external;

    function claimAdvisor() external;

    function claimInvestorSeed() external;

    function claimInvestorPrivateA() external;

    function claimInvestorPublic() external;

    function claimEcosystem() external;
}