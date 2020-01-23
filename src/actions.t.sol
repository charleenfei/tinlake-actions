pragma solidity ^0.5.12;

import "ds-test/test.sol";

import "tinlake/core/test/system/system.sol"
import "./actions.sol";

contract ActionsTest is SystemTest {
    Actions actions;

    function setUp() public {
        baseSetup("whitelist", "switchable")
        actions = new Actions();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
