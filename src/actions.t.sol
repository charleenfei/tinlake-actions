pragma solidity ^0.5.12;

import "ds-test/test.sol";

import "./actions.sol";

contract actionsTest is DSTest {
    actions actions;

    function setUp() public {
        actions = new actions();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
