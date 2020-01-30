pragma solidity ^0.5.3;

contract NFTLike {
    function approve(address usr, uint token) public;
    function transferFrom(address sender, address recipient, uint token) public;
}

contract ERC20Like {
    function approve(address usr, uint amount) public;
    function transferFrom(address sender, address recipient, uint amount) public;
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

    function approveERC20(ERC20Like erc20, address usr, uint amount) public {
        erc20.approve(usr, amount);
    }

    // --- Borrower Actions ---

    function issue(ShelfLike shelf, NFTLike registry, uint token) public returns (uint loan) {
        loan = shelf.issue(address(registry), token);
        // proxy approve shelf to take nft
        registry.approve(address(shelf), token);
        return loan;
    }

    function transferIssue(ShelfLike shelf, NFTLike registry, uint token) public returns (uint loan) {
        // transfer nft from borrower to proxy
        registry.transferFrom(msg.sender, address(this), token);
        return issue(shelf, registry, token);
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

    function transferIssueLockBorrowWithdraw(ShelfLike shelf, NFTLike registry, uint token, uint amount, address usr) public {
        uint loan = transferIssue(shelf, registry, token);
        lockBorrowWithdraw(shelf, loan, amount, usr);
    }

    function repay(ShelfLike shelf, ERC20Like erc20, uint loan, uint amount) public {
        erc20.approve(address(shelf), amount);
        // transfer money from borrower to proxy
        erc20.transferFrom(msg.sender, address(this), amount);
        shelf.repay(loan, amount);
    }

    function unlock(ShelfLike shelf, NFTLike registry, uint token, uint loan) public {
        shelf.unlock(loan);
        registry.transferFrom(address(this), msg.sender, token);
    }

    function close(ShelfLike shelf, uint loan) public {
        shelf.close(loan);
    }

    function repayUnlock(ShelfLike shelf, NFTLike registry, uint token, ERC20Like erc20, uint loan, uint amount) public {
        repay(shelf, erc20, loan, amount);
        unlock(shelf, registry, token, loan);
    }

    function repayUnlockClose(ShelfLike shelf, NFTLike registry, uint token, ERC20Like erc20, uint loan, uint amount) public {
        repayUnlock(shelf, registry, token, erc20, loan, amount);
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
