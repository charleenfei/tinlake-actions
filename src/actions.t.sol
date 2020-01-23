pragma solidity ^0.5.12;

import "ds-test/test.sol";

import "./actions.sol";

contract ActionsTest is DSTest {
    Actions actions;

    function setUp() public {
        actions = new Actions();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
