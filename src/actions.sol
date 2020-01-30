pragma solidity ^0.5.3;
contract NFTLike {
    function approve(address usr, uint token) public;
}

contract TokenLike {
    function approve(address usr, uint amount) public;
}

contract ShelfLike {
    function lock(uint loan) public;
    function unlock(uint loan) public;
    function issue(address registry, uint token) public returns (uint loan);
    function close(uint loan) public;
    function borrow(uint loan, uint amount) public;
    function withdraw(uint loan, uint amount, address usr) public;
    function repay(uint loan, uint amount) public;
    function shelf(uint loan) public returns(address registry,uint256 tokenId,uint price,uint principal, uint initial);
}

contract OperatorLike {
    function supply(uint amount) public;
    function relyInvestor(address usr) public;
}

contract Actions {
    function approveNFT(NFTLike registry, address usr, uint token) public {
        registry.approve(usr, token);
    }
    function approveERC20(TokenLike token, address usr, uint amount) public {
        token.approve(usr, amount);
    }

    // --- Borrower Actions ---
    function issue(ShelfLike shelf, address registry, uint token) public returns (uint loan) {
        return shelf.issue(registry, token);
    }

    function lock(ShelfLike shelf, uint loan) public {
        shelf.lock(loan);
    }

    function borrowWithdraw(ShelfLike shelf, uint loan, uint amount, address usr) public {
        shelf.borrow(loan, amount);
        shelf.withdraw(loan, amount, usr);
    }

    function lockBorrowWithdraw(ShelfLike shelf, uint loan, uint amount, address usr) public {
        shelf.lock(loan);
        borrowWithdraw(shelf, loan, amount, usr);
    }

    function issueLockBorrowWithdraw(ShelfLike shelf, address registry, uint token, uint amount, address usr) public {
        uint loan = shelf.issue(registry, token);
        lockBorrowWithdraw(shelf, loan, amount, usr);
    }

    function repay(ShelfLike shelf, uint loan, uint amount) public {
        shelf.repay(loan, amount);
    }

    function unlock(ShelfLike shelf, uint loan) public {
        shelf.unlock(loan);
    }

    function close(ShelfLike shelf, uint loan) public {
        shelf.close(loan);
    }

    function repayUnlock(ShelfLike shelf, uint loan, uint amount) public {
        shelf.repay(loan, amount);
        shelf.unlock(loan);
    }

    function repayUnlockClose(ShelfLike shelf, uint loan, uint amount) public {
        repayUnlock(shelf, loan, amount);
        shelf.close(loan);
    }

    function unlockClose(ShelfLike shelf, uint loan) public {
        shelf.unlock(loan);
        shelf.close(loan);
    }

    // --- Lender Actions ---
    function supply(OperatorLike operator, uint amount) public {
        operator.supply(amount);
    }
}
