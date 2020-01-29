pragma solidity ^0.5.3;

import "ds-test/test.sol";

import { Proxy, ProxyRegistry } from "tinlake-proxy/proxy.sol";
import { BaseSystemTest } from "tinlake/test/system/base_system.sol";
import { AdminUser } from "tinlake/test/system/users/admin.sol";
import "./actions.sol";

contract ActionsTest is BaseSystemTest {
    address       actions;
    address       self;
    ProxyRegistry registry;

    AdminUser public admin;
    address admin_;

    function setUp() public {
        bool seniorTranche = false;
        baseSetup("whitelist", "default", seniorTranche);
        actions = address(new Actions());
        registry = new ProxyRegistry();
        self = address(this);

        admin = new AdminUser(address(shelf), address(pile), address(ceiling), address(title), address(distributor), address(collector), address(threshold));
        admin_ = address(admin);
        root.relyBorrowAdmin(admin_);
    }

    function testIssueLockBorrow() public {
        Proxy borrower    = Proxy(registry.build());
        Proxy lender      = Proxy(registry.build());
        address borrower_ = address(borrower);
        address lender_   = address(lender);


        // Borrower: Issue Loan, Lock NFT
        (uint tokenId, ) = issueNFT(borrower_);
        assertEq(collateralNFT.ownerOf(tokenId), borrower_);
        bytes memory data = abi.encodeWithSignature("issue(address,address,uint256)", address(shelf), address(collateralNFT), tokenId);
        bytes memory response = borrower.execute(actions, data);
        (uint loan) = abi.decode(response, (uint));
        assertEq(title.ownerOf(loan), borrower_);
        borrower.execute(actions, abi.encodeWithSignature("approveNFT(address,address,uint256)", address(collateralNFT), address(shelf), loan));
        borrower.execute(actions, abi.encodeWithSignature("lock(address,uint256)", address(shelf), loan));
        assertEq(collateralNFT.ownerOf(1), address(shelf));

        // Lend:
        uint investment = 100 ether;
        currency.mint(lender_, investment);
        lender.execute(actions, abi.encodeWithSignature("approveERC20(address,address,uint256)", address(currency), address(lenderDeployer.junior()), uint(-1)));
        address operator_ = address(lenderDeployer.juniorOperator());
        OperatorLike(operator_).relyInvestor(lender_);
        lender.execute(actions, abi.encodeWithSignature("supply(address,uint256)", operator_, investment));

        admin.setCeiling(loan, investment);
        // 12% per year
        admin.doInitRate(uint(12), 1000000003593629043335673583);
        admin.doAddRate(loan, uint(12));

        // Borrow:
        borrower.execute(actions, abi.encodeWithSignature("borrow(address,uint256,uint256)", address(shelf), loan, investment));
        borrower.execute(actions, abi.encodeWithSignature("withdraw(address,uint256,uint256,address)", address(shelf), loan, investment, borrower_));

        assertEq(currency.balanceOf(borrower_), investment);
        assertEq(pile.debt(loan), investment);
    }

    function testFailIssueBorrowerNotOwner() public {
        Proxy borrower    = Proxy(registry.build());
        Proxy randomUser     = Proxy(registry.build());
        address randomUser_   = address(randomUser);


        // Collateral NFT not owned by borrower
        uint tokenId = collateralNFT.issue(randomUser_);
        bytes memory data = abi.encodeWithSignature("issue(address,address,uint256)", address(shelf), address(collateralNFT), tokenId);
        borrower.execute(actions, data);
    }

    function testFailWithdrawNotLoanOwner() public {
        Proxy borrower    = Proxy(registry.build());
        Proxy lender      = Proxy(registry.build());
        address borrower_ = address(borrower);
        address lender_   = address(lender);


        (uint tokenId, ) = issueNFT(borrower_);
        bytes memory data = abi.encodeWithSignature("issue(address,address,uint256)", address(shelf), address(collateralNFT), tokenId);
        bytes memory response = borrower.execute(actions, data);
        (uint loan) = abi.decode(response, (uint));
        borrower.execute(actions, abi.encodeWithSignature("approveNFT(address,address,uint256)", address(collateralNFT), address(shelf), loan));
        borrower.execute(actions, abi.encodeWithSignature("lock(address,uint256)", address(shelf), loan));

        // Lend:
        uint investment = 100 ether;
        currency.mint(lender_, investment);
        lender.execute(actions, abi.encodeWithSignature("approveERC20(address,address,uint256)", address(currency), address(lenderDeployer.junior()), uint(-1)));
        address operator_ = address(lenderDeployer.juniorOperator());
        OperatorLike(operator_).relyInvestor(lender_);
        lender.execute(actions, abi.encodeWithSignature("supply(address,uint256)", operator_, investment));

        admin.setCeiling(loan, investment);
        // 12% per year
        admin.doInitRate(uint(12), 1000000003593629043335673583);
        admin.doAddRate(loan, uint(12));

        // Borrow:
        borrower.execute(actions, abi.encodeWithSignature("borrow(address,uint256,uint256)", address(shelf), loan, investment));
        lender.execute(actions, abi.encodeWithSignature("withdraw(address,uint256,uint256,address)", address(shelf), loan, investment, borrower_));
    }

    // --- Lender ---

    function testFailSupplyNotWhitelisted() public {
        Proxy lender      = Proxy(registry.build());
        address lender_   = address(lender);

        // Lend:
        uint investment = 100 ether;
        currency.mint(lender_, investment);
        lender.execute(actions, abi.encodeWithSignature("approveERC20(address,address,uint256)", address(currency), address(lenderDeployer.junior()), uint(-1)));
        lender.execute(actions, abi.encodeWithSignature("supply(address,uint256)", address(juniorOperator), investment));
    }
}
