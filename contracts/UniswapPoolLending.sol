// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract UniswapPoolLending is IERC721Receiver {
    INonfungiblePositionManager public positionManager;
    IERC20 public lendingToken;

    struct Loan {
        address lender;
        address borrower;
        uint256 tokenId;
        uint256 loanAmount;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
    }

    Loan[] public loans;
    uint256[] public availableLoanIndexes;

    constructor(address _positionManager, address _lendingToken) {
        positionManager = INonfungiblePositionManager(_positionManager);
        lendingToken = IERC20(_lendingToken);
    }

    function depositNFT(uint256 tokenId, uint256 loanAmount, uint256 loanDuration) external {
        positionManager.transferFrom(msg.sender, address(this), tokenId);

        uint256 newIndex = loans.length;
        loans.push(Loan({
            lender: msg.sender,
            borrower: address(0),
            tokenId: tokenId,
            loanAmount: loanAmount,
            startTime: 0,
            endTime: loanDuration,
            isActive: true
        }));
        availableLoanIndexes.push(newIndex);
    }

    function borrowNFT(uint256 loanIndex) external {
        Loan storage loan = loans[loanIndex];
        require(loan.borrower == address(0), "NFT is already borrowed");
        require(loan.isActive, "Loan is not active");

        lendingToken.transferFrom(msg.sender, loan.lender, loan.loanAmount);

        loan.borrower = msg.sender;
        loan.startTime = block.timestamp;
        loan.isActive = false;

        _removeAvailableLoan(loanIndex);
    }

    function _removeAvailableLoan(uint256 loanIndex) private {
        uint256 lastIndex = availableLoanIndexes.length - 1;
        if (loanIndex < lastIndex) {
            availableLoanIndexes[loanIndex] = availableLoanIndexes[lastIndex];
        }
        availableLoanIndexes.pop();
    }

    function claimFees(uint256 loanIndex) external {
        Loan storage loan = loans[loanIndex];
        require(msg.sender == loan.borrower, "Only borrower can claim fees");
        require(block.timestamp < loan.startTime + loan.endTime, "Loan period has ended");

        (address token0, address token1) = _getTokenForPosition(loan.tokenId);

        INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams({
            tokenId: loan.tokenId,
            recipient: address(this),
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });
        (uint256 amount0, uint256 amount1) = positionManager.collect(params);

        IERC20(token0).transfer(loan.borrower, amount0);
        IERC20(token1).transfer(loan.borrower, amount1);
    }

    function _getTokenForPosition(uint256 tokenId) private view returns (address _token0, address _token1) {
        (, , address token0, address token1, , , , , , , , ) = positionManager.positions(tokenId);
        return (token0, token1);
    }

    function returnNFT(uint256 loanIndex) external {
        Loan storage loan = loans[loanIndex];
        require(block.timestamp >= loan.startTime + loan.endTime, "Loan period has not ended yet");
        require(msg.sender == loan.borrower, "Only borrower can return the NFT");

        loan.borrower = address(0);
        loan.startTime = 0;
        loan.isActive = false;
        availableLoanIndexes.push(loanIndex);
    }

    function withdrawNFT(uint256 loanIndex) external {
        Loan storage loan = loans[loanIndex];
        require(loan.lender == msg.sender, "Only lender can withdraw the NFT");
        require(block.timestamp >= loan.startTime + loan.endTime, "Loan period has not ended yet");

        if (loan.borrower != address(0)) {
            loan.borrower = address(0);
            loan.startTime = 0;
        }

        positionManager.transferFrom(address(this), loan.lender, loan.tokenId);

        loan.isActive = false;

        _removeAvailableLoan(loanIndex);
    }

    function reactivateLoan(uint256 loanIndex, uint256 loanDuration, uint256 loanAmount) external {
        Loan storage loan = loans[loanIndex];
        require(loan.lender == msg.sender, "Only lender can reactivate the loan");
        require(loan.borrower == address(0), "NFT is currently borrowed");
        require(!loan.isActive, "Loan is already active");

        loan.endTime = loanDuration;
        loan.loanAmount = loanAmount;
        loan.isActive = true;

        availableLoanIndexes.push(loanIndex);
    }

    function getAvailableLoans() external view returns (Loan[] memory) {
        uint256 availableLoansCount = availableLoanIndexes.length;
        Loan[] memory availableLoans = new Loan[](availableLoansCount);

        for (uint256 i = 0; i < availableLoansCount; i++) {
            availableLoans[i] = loans[availableLoanIndexes[i]];
        }

        return availableLoans;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}