pragma solidity ^0.5.3;

import { Proxy, ProxyRegistry } from "tinlake-proxy/proxy.sol";
import { BaseSystemTest } from "tinlake/test/system/base_system.sol";
import { AdminUser } from "tinlake/test/system/users/admin.sol";
import "./actions.sol";

contract ActionsTest is BaseSystemTest {
    address       actions;
    address       self;
    ProxyRegistry registry;

    Proxy borrower;
    Proxy lender;
    address borrower_;
    address lender_;

    Proxy randomUser;
    address randomUser_ ;

    function setUp() public {
        bool seniorTranche = false;
        baseSetup("whitelist", "default", seniorTranche);
        actions = address(new Actions());
        registry = new ProxyRegistry();
        self = address(this);

        admin = new AdminUser(address(shelf), address(pile), address(ceiling), address(title), address(distributor), address(collector), address(threshold));
        admin_ = address(admin);
        root.relyBorrowAdmin(admin_);

        borrower    = Proxy(registry.build());
        lender      = Proxy(registry.build());
        borrower_ = address(borrower);
        lender_   = address(lender);

        randomUser     = Proxy(registry.build());
        randomUser_   = address(randomUser);
    }

    // ----- Lender -----
    function invest(uint amount) public {
        currency.mint(lender_, amount);
        lender.execute(actions, abi.encodeWithSignature("approveERC20(address,address,uint256)", address(currency), address(lenderDeployer.junior()), uint(-1)));
        address operator_ = address(lenderDeployer.juniorOperator());
        OperatorLike(operator_).relyInvestor(lender_);
        lender.execute(actions, abi.encodeWithSignature("supply(address,uint256)", operator_, amount));
    }

    // ----- Borrower -----
    function issue(uint tokenId) public returns(uint) {
        assertEq(collateralNFT.ownerOf(tokenId), borrower_);
        bytes memory data = abi.encodeWithSignature("issue(address,address,uint256)", address(shelf), address(collateralNFT), tokenId);
        bytes memory response = borrower.execute(actions, data);
        (uint loan) = abi.decode(response, (uint));
        assertEq(title.ownerOf(loan), borrower_);
        return loan;
    }

    function testIssueLockBorrow() public {
        // Borrower: Issue Loan
        (uint tokenId, ) = issueNFT(borrower_);
        uint loan = issue(tokenId);

        // Lender: lend
        uint amount = 100 ether;
        invest(amount);
        
        // Admin: set loan parameters
        uint speed = 1000000003593629043335673583; uint rate = uint(12); 
        setLoanParameters(loan, amount, rate, speed);
    
        // Borrower: Lock & Borrow
        borrower.execute(actions, abi.encodeWithSignature("approveNFT(address,address,uint256)", address(collateralNFT), address(shelf), loan));
        borrower.execute(actions, abi.encodeWithSignature("lockBorrowWithdraw(address,uint256,uint256,address)", address(shelf), loan, amount, borrower_));
        assertEq(collateralNFT.ownerOf(1), address(shelf));
        assertEq(currency.balanceOf(borrower_), amount);
        assertEq(pile.debt(loan), amount);
    }

    function testFailIssueLockBorrowerWithdrawCeilingNotSet() public {
        (uint tokenId, ) = issueNFT(borrower_);
        uint amount = 100 ether;
        borrower.execute(actions, abi.encodeWithSignature("issueLockBorrowWithdraw(address,address,uint256,uint256,address)", address(shelf), address(collateralNFT), tokenId, amount, borrower_));
    }

    function testFailIssueBorrowerNotOwner() public {
        // Collateral NFT not owned by borrower
        uint tokenId = collateralNFT.issue(randomUser_);
        bytes memory data = abi.encodeWithSignature("issue(address,address,uint256)", address(shelf), address(collateralNFT), tokenId);
        borrower.execute(actions, data);
    }

    function testFailBorrowNotLoanOwner() public {
        (uint tokenId, ) = issueNFT(borrower_);
        bytes memory data = abi.encodeWithSignature("issue(address,address,uint256)", address(shelf), address(collateralNFT), tokenId);
        bytes memory response = borrower.execute(actions, data);
        (uint loan) = abi.decode(response, (uint));
        borrower.execute(actions, abi.encodeWithSignature("approveNFT(address,address,uint256)", address(collateralNFT), address(shelf), loan));
        borrower.execute(actions, abi.encodeWithSignature("lock(address,uint256)", address(shelf), loan));

        // Lend:
        uint amount = 100 ether;
        invest(amount);

        // Admin: set loan parameters
        uint speed = 1000000003593629043335673583; uint rate = uint(12); 
        setLoanParameters(loan, amount, rate, speed);

        // RandomUser: Borrow & Withdraw
        randomUser.execute(actions, abi.encodeWithSignature("borrowWithdraw(address,uint256,uint256,address)", address(shelf), loan, amount, randomUser_));
    }

    function testRepayUnlockClose() public {
        // Borrower: Issue Loan
        (uint tokenId, bytes32 lookupId) = issueNFT(borrower_);
        uint loan = issue(tokenId);

        // Lender: lend
        uint amount = 100 ether;
        invest(amount);
        
        // Admin: set loan parameters
        uint speed = 1000000003593629043335673583; uint rate = uint(12); 
        setLoanParameters(loan, amount, rate, speed);
    
        // Borrower: Lock & Borrow
        borrower.execute(actions, abi.encodeWithSignature("approveNFT(address,address,uint256)", address(collateralNFT), address(shelf), loan));
        borrower.execute(actions, abi.encodeWithSignature("lockBorrowWithdraw(address,uint256,uint256,address)", address(shelf), loan, amount, borrower_));
       
        // Borrower: Repay & Unlock & Close
        borrower.execute(actions, abi.encodeWithSignature("approveERC20(address,address,uint256)", address(currency), address(shelf), uint(-1)));
        borrower.execute(actions, abi.encodeWithSignature("repayUnlockClose(address,uint256,uint256)", address(shelf), loan, amount));
        assertEq(collateralNFT.ownerOf(tokenId), address(borrower_));
        assertEq(pile.debt(loan), 0);
        assertEq(shelf.nftlookup(lookupId), 0);
    }

    // --- Lender ---
    function testFailSupplyNotWhitelisted() public {
        // Lend:
        uint investment = 100 ether;
        currency.mint(lender_, investment);
        lender.execute(actions, abi.encodeWithSignature("approveERC20(address,address,uint256)", address(currency), address(lenderDeployer.junior()), uint(-1)));
        lender.execute(actions, abi.encodeWithSignature("supply(address,uint256)", address(juniorOperator), investment));
    }
}
