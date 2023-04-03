// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract DPSLendingUniswapLiquidity is IERC721Receiver {

    // Loan structure including all informations from the LP
    struct Loan {
        // owner of the LP
        address lender;

        // potential borrower of the nft
        address borrower;

        // NFT id of the Uniswap V3 pool representation
        uint256 tokenId;

        // amount requested from the LP to loan this pool share
        uint256 loanAmount;

        // creation date of the loan
        uint256 creationTime;

        // start date of the loan
        uint256 startTime;

        // when the LP can retrieve his LP
        uint256 endTime;

        // token accepted for the payment of the loean
        address acceptedToken;

        // is the loan currently active
        bool isActive;

        // index of the loan request
        uint256 loanIndex;
    }

    // All LP loans offers from providers
    Loan[]                          public  _loans;

    // Index count of loans from LP
    uint256                         public  _loansIndex;

    // Uniswap V3 Position Manager
    INonfungiblePositionManager     public  positionManager;

    // Deployer of the Defi Pool Share Protocol
    address                         public _dpstDeployer;

    // list of authorized tokens for payment of loans
    mapping(address => bool)        public _whitelistedTokens;

    // list of loan by lenders
    mapping(address => uint256[])      public _loanByLenders;
    
    // list of loan by borrowers
    mapping(address => uint256[])      public _loanByBorrowers;

    // Loan creation event
    event LoanCreated(address indexed _from, uint256 indexed _loanIndex);

    // Loan updated event
    event LoanUpdated(uint256 indexed _loanIndex);

    constructor(address _positionManager) {
        positionManager = INonfungiblePositionManager(_positionManager);


        // Allow Defi Pool Share Token as payment for a Loan
        _whitelistedTokens[address(0x0Cb80b1c0E6AeBB031a7Ec26219ab162f0F9bC2B)] = true;
        //TODO: add USDT,USDC,WETH,WBTC
    }


    // Return informations on the effective loan
    function getLoanInfo(uint256 index) public view returns(Loan memory){
        return _loans[index];
    }

    // Whitelist a specific token for payment for the LP loan
    function whitelistToken(address token, bool state) public 
    {
        require(msg.sender == _dpstDeployer, "Only DPST protocol owners can allow new ERC20 to be used as payment");
        _whitelistedTokens[token] = state;
    }

    // Deposit your AMM NFT LP into the protocol in-wait for someone to buy it
    function depositNFT(uint256 tokenId, uint256 loanAmount, uint256 loanDuration, address acceptedToken) external {
        require(_whitelistedTokens[acceptedToken], "You can't use this token for the payment for potential borrowers");
        require (loanDuration > block.timestamp, "Invalid date duration for the loan");
        positionManager.transferFrom(msg.sender, address(this), tokenId);

        _loans.push(Loan({
            lender: msg.sender,
            borrower: address(0),
            tokenId: tokenId,
            acceptedToken: acceptedToken,
            loanAmount: loanAmount,
            creationTime: block.timestamp,
            startTime: 0,
            endTime: loanDuration,
            loanIndex: _loans.length,
            isActive: true
        }));

        // Emit the loan created event
        emit LoanCreated(msg.sender, _loans.length - 1);

        // add the loan to the list of the loan owned by the lender
        _loanByLenders[msg.sender].push(_loans.length - 1);

        // increment total index of loan created
        _loansIndex = _loans.length;
    }

    // Function for borrowers to buy a certain pool share
    function borrowNFT(uint256 loanIndex) external {
        Loan storage loan = _loans[loanIndex];
        require(loan.borrower == address(0), "NFT is already borrowed!");
        require(loan.isActive, "Loan is not active, you can't borrow it");

        IERC20 acceptedToken = IERC20(loan.acceptedToken);
        acceptedToken.transferFrom(msg.sender, loan.lender, loan.loanAmount);

        loan.borrower = msg.sender;
        loan.startTime = block.timestamp;
        loan.endTime = loan.endTime + (loan.startTime - loan.creationTime);
        loan.isActive = false;

        // emit the update event
        emit LoanUpdated(loan.loanIndex);

        
        // add the loan to the list of the loan owned by the borrower
        _loanByBorrowers[msg.sender].push(loan.loanIndex);
    }

    function canClaimFees(uint256 loanIndex) public view returns (bool _canClaim) {
        Loan storage loan = _loans[loanIndex];
        if(msg.sender != loan.borrower) {
            return false;
        }
        if(block.timestamp >= loan.endTime) {
            return false;
        }

        return true;
    }

    function claimFees(uint256 loanIndex) external {
        Loan storage loan = _loans[loanIndex];
        require(msg.sender == loan.borrower, "Only borrower can claim fees");
        require(block.timestamp < loan.endTime, "Loan period has ended");

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

    function withdrawNFT(uint256 loanIndex) public {
        Loan storage loan = _loans[loanIndex];
        require(loan.lender == msg.sender, "Only lender can withdraw the NFT");
        if (loan.borrower != address(0)) {
            require(block.timestamp >= loan.endTime, "Loan period has not ended yet");

            // delete the loan for the borrower
            uint256[] storage borrowerPoolArray = _loanByBorrowers[loan.borrower];
            uint256 arrayLengthBorrower = borrowerPoolArray.length;
            for (uint256 i = 0; i < arrayLengthBorrower; i++) {
                if (borrowerPoolArray[i] == value) {
                    borrowerPoolArray[i] = borrowerPoolArray[arrayLengthBorrower - 1];
                    borrowerPoolArray.pop();
                    break;
                }
            }

            // reset the borrower on the loan
            loan.borrower = address(0);
            loan.startTime = 0;
        }

        positionManager.transferFrom(address(this), loan.lender, loan.tokenId);
        loan.isActive = false;

        // delete the loan for the lender
        uint256[] storage lenderPoolArray = _loanByLenders[loan.lender];
        uint256 arrayLength = lenderPoolArray.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            if (lenderPoolArray[i] == value) {
                lenderPoolArray[i] = lenderPoolArray[arrayLength - 1];
                lenderPoolArray.pop();
                break;
            }
        }

        // emit the update event
        emit LoanUpdated(loan.loanIndex);
    }

    function reactivateLoan(uint256 loanIndex, uint256 loanDuration, uint256 loanAmount) external {
        Loan storage loan = _loans[loanIndex];
        require(loan.lender == msg.sender, "Only lender can reactivate the loan");
        require(loan.borrower == address(0), "NFT is currently borrowed");
        require(!loan.isActive, "Loan is already active");

        positionManager.transferFrom(msg.sender, address(this), loan.tokenId);
        loan.startTime = block.timestamp;
        loan.endTime = loanDuration;
        loan.loanAmount = loanAmount;
        loan.isActive = true;
        
        // emit the update event
        emit LoanUpdated(loan.loanIndex);

        // add the loan to the list of the loan owned by the lender
        _loanByLenders[msg.sender].push(loan.loanIndex);
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