// SPDX-License-Identifier: LicenseRef-Degensoft-SwapVM-1.1
pragma solidity 0.8.30;

/// @custom:license-url https://github.com/1inch/swap-vm/blob/feb16411738331f7d05ae71d4a664154068018fc/LICENSES/SwapVM-1.1.txt
/// @custom:copyright © 2025 Degensoft Ltd
/// @custom:modification AquaVol deterministic proof instruction added 2026-09-26.

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Context } from "@1inch/swap-vm/contracts/libs/VM.sol";

import { AquaVolOpcode } from "./AquaVolOpcode.sol";
import { AquaVolInstructionBuilder } from "./AquaVolInstructionBuilder.sol";

/// @notice Temporary fixed-price instruction for proving custom SwapVM dispatch.
/// @dev Encoding: [address callToken, address quoteToken, uint256 premiumPerWholeCall].
///      The arguments use standard ABI encoding and therefore occupy 96 bytes.
library AquaVolConstantPrice {
    uint256 internal constant CALL_SCALE = 1e18;
    uint256 internal constant ARGUMENTS_LENGTH = 96;

    error InvalidArgumentsLength(uint256 actual, uint256 expected);
    error InvalidToken(address token);
    error ZeroPremium();
    error ExactInputUnsupported();
    error UnsupportedPair(address tokenIn, address tokenOut);
    error InsufficientOutputLiquidity(uint256 requested, uint256 available);

    function build(address callToken, address quoteToken, uint256 premiumPerWholeCall)
        internal
        pure
        returns (bytes memory)
    {
        _validateConfiguration(callToken, quoteToken, premiumPerWholeCall);
        return AquaVolInstructionBuilder.build(
            AquaVolOpcode.CONSTANT_PRICE, abi.encode(callToken, quoteToken, premiumPerWholeCall)
        );
    }

    function exec(Context memory ctx, bytes calldata args) internal pure {
        if (args.length != ARGUMENTS_LENGTH) {
            revert InvalidArgumentsLength(args.length, ARGUMENTS_LENGTH);
        }

        (address callToken, address quoteToken, uint256 premiumPerWholeCall) =
            abi.decode(args, (address, address, uint256));
        _validateConfiguration(callToken, quoteToken, premiumPerWholeCall);

        if (ctx.query.isExactIn) revert ExactInputUnsupported();
        if (ctx.query.tokenIn != quoteToken || ctx.query.tokenOut != callToken) {
            revert UnsupportedPair(ctx.query.tokenIn, ctx.query.tokenOut);
        }
        if (ctx.swap.amountOut > ctx.swap.balanceOut) {
            revert InsufficientOutputLiquidity(ctx.swap.amountOut, ctx.swap.balanceOut);
        }

        ctx.swap.amountIn =
            Math.mulDiv(ctx.swap.amountOut, premiumPerWholeCall, CALL_SCALE, Math.Rounding.Ceil);
    }

    function _validateConfiguration(
        address callToken,
        address quoteToken,
        uint256 premiumPerWholeCall
    ) private pure {
        if (callToken == address(0)) revert InvalidToken(callToken);
        if (quoteToken == address(0)) revert InvalidToken(quoteToken);
        if (callToken == quoteToken) revert UnsupportedPair(quoteToken, callToken);
        if (premiumPerWholeCall == 0) revert ZeroPremium();
    }
}
