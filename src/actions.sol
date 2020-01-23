pragma solidity ^0.5.12;

contract ShelfLike {
    function lock(uint loan) public;
    function unlock(uint loan) public;
    function issue(address registry, uint token) public returns (uint loan);
    function close(uint loan) public;
    function borrow(uint loan, uint wad) public;
    function withdraw(uint loan, uint wad, address usr) public;
    function repay(uint loan, uint wad) public;
    function shelf(uint loan) public returns(address registry,uint256 tokenId,uint price,uint principal, uint initial);
}
contract Actions {
    function issue(ShefLike shelf, address registry, uint token) public returns (uint loan) {
        return shelf.issue(registry, token)
    }

}
