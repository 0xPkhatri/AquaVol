// SPDX-License-Identifier: LicenseRef-Degensoft-SwapVM-1.1
pragma solidity 0.8.30;

/// @custom:license-url https://github.com/1inch/swap-vm/blob/feb16411738331f7d05ae71d4a664154068018fc/LICENSES/SwapVM-1.1.txt
/// @custom:copyright © 2025 Degensoft Ltd
/// @custom:modification AquaVol opcode dispatcher extension added 2026-09-26.

import { Context } from "@1inch/swap-vm/contracts/libs/VM.sol";
import { AquaOpcodes } from "@1inch/swap-vm/contracts/opcodes/AquaOpcodes.sol";

import { AquaVolOpcode } from "./AquaVolOpcode.sol";
import { AquaVolConstantPrice } from "./AquaVolConstantPrice.sol";
import { AquaVolFairValue } from "./AquaVolFairValue.sol";

/// @notice Dispatches AquaVol instructions and delegates all other opcodes upstream.
contract AquaVolOpcodes is AquaOpcodes {
    function _runOpcode(Context memory ctx, uint256 opcode, bytes calldata args)
        internal
        virtual
        override
    {
        if (opcode == AquaVolOpcode.CONSTANT_PRICE) {
            AquaVolConstantPrice.exec(ctx, args);
        } else if (opcode == AquaVolOpcode.OPTION_FAIR_VALUE) {
            AquaVolFairValue.exec(ctx, args);
        } else {
            super._runOpcode(ctx, opcode, args);
        }
    }
}
