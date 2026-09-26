// SPDX-License-Identifier: LicenseRef-Degensoft-SwapVM-1.1
pragma solidity 0.8.30;

/// @custom:license-url https://github.com/1inch/swap-vm/blob/feb16411738331f7d05ae71d4a664154068018fc/LICENSES/SwapVM-1.1.txt
/// @custom:copyright © 2025 Degensoft Ltd
/// @custom:modification AquaVol custom-router unit tests added 2026-09-26.

import { Aqua } from "@1inch/aqua/src/Aqua.sol";
import { AquaOpcodes } from "@1inch/swap-vm/contracts/opcodes/AquaOpcodes.sol";
import { Opcode } from "@1inch/swap-vm/contracts/libs/OpcodeList.sol";
import { Context } from "@1inch/swap-vm/contracts/libs/VM.sol";

import { MockERC20 } from "../../src/mocks/MockERC20.sol";
import { AquaVolOpcode } from "../../src/swapvm/AquaVolOpcode.sol";
import { AquaVolInstructionBuilder } from "../../src/swapvm/AquaVolInstructionBuilder.sol";
import { AquaVolConstantPrice } from "../../src/swapvm/AquaVolConstantPrice.sol";
import { AquaVolOpcodes } from "../../src/swapvm/AquaVolOpcodes.sol";
import { AquaVolSwapVMRouter } from "../../src/swapvm/AquaVolSwapVMRouter.sol";

contract AquaVolBuilderHarness {
    function buildRaw(uint8 opcode, bytes memory args) external pure returns (bytes memory) {
        return AquaVolInstructionBuilder.build(opcode, args);
    }

    function buildConstantPrice(address callToken, address quoteToken, uint256 premium)
        external
        pure
        returns (bytes memory)
    {
        return AquaVolConstantPrice.build(callToken, quoteToken, premium);
    }
}

contract AquaVolOpcodeHarness is AquaVolOpcodes {
    function run(
        uint256 opcode,
        bytes calldata args,
        address tokenIn,
        address tokenOut,
        bool isExactIn,
        uint256 balanceIn,
        uint256 balanceOut,
        uint256 amountIn,
        uint256 amountOut
    ) external returns (uint256 resultingAmountIn, uint256 resultingAmountOut) {
        Context memory ctx;
        ctx.query.tokenIn = tokenIn;
        ctx.query.tokenOut = tokenOut;
        ctx.query.isExactIn = isExactIn;
        ctx.swap.balanceIn = balanceIn;
        ctx.swap.balanceOut = balanceOut;
        ctx.swap.amountIn = amountIn;
        ctx.swap.amountOut = amountOut;

        _runOpcode(ctx, opcode, args);
        return (ctx.swap.amountIn, ctx.swap.amountOut);
    }
}

contract AquaVolSwapVMRouterTest {
    uint256 private constant PREMIUM = 61_505_937;
    uint256 private constant ONE_CALL = 1e18;

    AquaVolBuilderHarness private builder;
    AquaVolOpcodeHarness private opcodes;
    MockERC20 private callToken;
    MockERC20 private quoteToken;

    function setUp() public {
        builder = new AquaVolBuilderHarness();
        opcodes = new AquaVolOpcodeHarness();
        callToken = new MockERC20("AquaVol Call", "avCALL", 18);
        quoteToken = new MockERC20("USD Coin", "USDC", 6);
    }

    function testCanonicalOpcodeMappingAndEncoding() public view {
        bytes memory encoded =
            builder.buildConstantPrice(address(callToken), address(quoteToken), PREMIUM);
        bytes memory expected =
            bytes.concat(hex"d060", abi.encode(address(callToken), address(quoteToken), PREMIUM));

        require(AquaVolOpcode.CONSTANT_PRICE == 0xd0, "constant-price opcode drift");
        require(AquaVolOpcode.OPTION_FAIR_VALUE == 0xd1, "fair-value opcode drift");
        require(AquaVolOpcode.OPTION_INVENTORY_SKEW == 0xd2, "inventory opcode drift");
        require(AquaVolOpcode.RESERVED_BANK_START == 0xf0, "reserved bank drift");
        require(keccak256(encoded) == keccak256(expected), "wrong instruction encoding");
    }

    function testBuilderRejectsArgumentsThatDoNotFitHeader() public {
        bytes memory oversized = new bytes(256);
        (bool success, bytes memory result) = address(builder)
            .call(
                abi.encodeCall(
                    AquaVolBuilderHarness.buildRaw, (AquaVolOpcode.CONSTANT_PRICE, oversized)
                )
            );

        require(!success, "oversized arguments accepted");
        _requireSelector(result, AquaVolInstructionBuilder.ArgumentsTooLong.selector);
    }

    function testConstantPriceSetsExactOutputInputWithCeilingRounding() public {
        bytes memory args = abi.encode(address(callToken), address(quoteToken), PREMIUM);
        (uint256 amountIn, uint256 amountOut) = opcodes.run(
            AquaVolOpcode.CONSTANT_PRICE,
            args,
            address(quoteToken),
            address(callToken),
            false,
            5_000e6,
            10e18,
            0,
            ONE_CALL + 1
        );

        require(amountIn == PREMIUM + 1, "wrong rounded premium");
        require(amountOut == ONE_CALL + 1, "output amount changed");
    }

    function testUpstreamOpcodeDelegatesWithoutChangingRegisters() public {
        (uint256 amountIn, uint256 amountOut) = opcodes.run(
            uint8(Opcode.Salt),
            hex"1234",
            address(quoteToken),
            address(callToken),
            false,
            7,
            9,
            11,
            13
        );

        require(amountIn == 11, "delegated input changed");
        require(amountOut == 13, "delegated output changed");
    }

    function testReservedAndUnknownOpcodesDelegateToUpstreamRevert() public {
        _requireUnknownOpcode(AquaVolOpcode.OPTION_FAIR_VALUE);
        _requireUnknownOpcode(AquaVolOpcode.OPTION_INVENTORY_SKEW);
        _requireUnknownOpcode(AquaVolOpcode.RESERVED_BANK_START);
        _requireUnknownOpcode(0xef);
    }

    function testMalformedConstantPriceArgumentsRevert() public {
        _requireRunRevert(
            AquaVolOpcode.CONSTANT_PRICE,
            hex"00",
            address(quoteToken),
            address(callToken),
            false,
            10e18,
            ONE_CALL,
            AquaVolConstantPrice.InvalidArgumentsLength.selector
        );
    }

    function testZeroPremiumReverts() public {
        _requireRunRevert(
            AquaVolOpcode.CONSTANT_PRICE,
            abi.encode(address(callToken), address(quoteToken), uint256(0)),
            address(quoteToken),
            address(callToken),
            false,
            10e18,
            ONE_CALL,
            AquaVolConstantPrice.ZeroPremium.selector
        );
    }

    function testExactInputAndWrongDirectionRevert() public {
        bytes memory args = abi.encode(address(callToken), address(quoteToken), PREMIUM);
        _requireRunRevert(
            AquaVolOpcode.CONSTANT_PRICE,
            args,
            address(quoteToken),
            address(callToken),
            true,
            10e18,
            ONE_CALL,
            AquaVolConstantPrice.ExactInputUnsupported.selector
        );
        _requireRunRevert(
            AquaVolOpcode.CONSTANT_PRICE,
            args,
            address(callToken),
            address(quoteToken),
            false,
            10e18,
            ONE_CALL,
            AquaVolConstantPrice.UnsupportedPair.selector
        );
    }

    function testInsufficientOutputLiquidityReverts() public {
        _requireRunRevert(
            AquaVolOpcode.CONSTANT_PRICE,
            abi.encode(address(callToken), address(quoteToken), PREMIUM),
            address(quoteToken),
            address(callToken),
            false,
            ONE_CALL - 1,
            ONE_CALL,
            AquaVolConstantPrice.InsufficientOutputLiquidity.selector
        );
    }

    function testHandlerDoesNotMoveTokens() public {
        callToken.mint(address(opcodes), 3e18);
        quoteToken.mint(address(opcodes), 100e6);
        uint256 callBefore = callToken.balanceOf(address(opcodes));
        uint256 quoteBefore = quoteToken.balanceOf(address(opcodes));

        opcodes.run(
            AquaVolOpcode.CONSTANT_PRICE,
            abi.encode(address(callToken), address(quoteToken), PREMIUM),
            address(quoteToken),
            address(callToken),
            false,
            100e6,
            3e18,
            0,
            ONE_CALL
        );

        require(callToken.balanceOf(address(opcodes)) == callBefore, "CALL moved");
        require(quoteToken.balanceOf(address(opcodes)) == quoteBefore, "quote moved");
    }

    function testRouterPreservesOfficialBindings() public {
        Aqua aqua = new Aqua();
        MockERC20 weth = new MockERC20("Wrapped Ether", "WETH", 18);
        AquaVolSwapVMRouter router = new AquaVolSwapVMRouter(
            address(aqua), address(weth), address(this), "AquaVol SwapVM", "1"
        );

        require(address(router.AQUA()) == address(aqua), "wrong Aqua binding");
        require(address(router.WETH()) == address(weth), "wrong WETH binding");
        require(address(router.asView()) == address(router), "wrong simulator binding");
    }

    function _requireUnknownOpcode(uint8 opcode) private {
        _requireRunRevert(
            opcode,
            "",
            address(quoteToken),
            address(callToken),
            false,
            10e18,
            ONE_CALL,
            AquaOpcodes.UnknownOpcode.selector
        );
    }

    function _requireRunRevert(
        uint256 opcode,
        bytes memory args,
        address tokenIn,
        address tokenOut,
        bool isExactIn,
        uint256 balanceOut,
        uint256 amountOut,
        bytes4 expectedSelector
    ) private {
        (bool success, bytes memory result) = address(opcodes)
            .call(
                abi.encodeCall(
                    AquaVolOpcodeHarness.run,
                    (opcode, args, tokenIn, tokenOut, isExactIn, 0, balanceOut, 0, amountOut)
                )
            );

        require(!success, "expected revert");
        _requireSelector(result, expectedSelector);
    }

    function _requireSelector(bytes memory result, bytes4 expected) private pure {
        require(result.length >= 4, "missing revert selector");
        bytes4 actual;
        assembly ("memory-safe") {
            actual := mload(add(result, 0x20))
        }
        require(actual == expected, "wrong revert selector");
    }
}
