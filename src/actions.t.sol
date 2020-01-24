pragma solidity ^0.5.12;

import "ds-test/test.sol";

import { Proxy, ProxyRegistry } from "tinlake-proxy/proxy.sol";
import { SystemTest } from "tinlake/core/test/system/system.sol";
import { AdminUser } from "tinlake/core/test/system/users/admin.sol";
import "./actions.sol";

contract ActionsTest is SystemTest {
    address       actions;
    address       self;
    ProxyRegistry registry;

    AdminUser public admin;
    address admin_;

    function setUp() public {
        baseSetup("whitelist", "switchable");
        actions = address(new Actions());
        registry = new ProxyRegistry();
        self = address(this);

        admin = new AdminUser(address(shelf), address(pile), address(ceiling), address(title), address(distributor));
        admin_ = address(admin);
        rootAdmin.relyBorrowAdmin(admin_);
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
        // TODO: remove switchable
        // assertEq(currency.balanceOf(address(lenderDeployer.junior())), investment);

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
}
