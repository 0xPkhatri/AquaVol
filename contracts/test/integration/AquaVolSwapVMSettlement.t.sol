// SPDX-License-Identifier: LicenseRef-Degensoft-SwapVM-1.1
pragma solidity 0.8.30;

/// @custom:license-url https://github.com/1inch/swap-vm/blob/feb16411738331f7d05ae71d4a664154068018fc/LICENSES/SwapVM-1.1.txt
/// @custom:copyright © 2025 Degensoft Ltd
/// @custom:modification AquaVol modified-router settlement tests added 2026-09-26.

import { Aqua } from "@1inch/aqua/src/Aqua.sol";
import { ISwapVM } from "@1inch/swap-vm/contracts/interfaces/ISwapVM.sol";
import { XYCSwap } from "@1inch/swap-vm/contracts/instructions/XYCSwap.sol";
import { Salt } from "@1inch/swap-vm/contracts/instructions/Controls.sol";
import { MakerTraitsLib } from "@1inch/swap-vm/contracts/libs/MakerTraits.sol";
import { TakerTraitsLib } from "@1inch/swap-vm/contracts/libs/TakerTraits.sol";
import { MockTaker } from "@1inch/swap-vm/test/solidity/mocks/MockTaker.sol";

import { MockERC20 } from "../../src/mocks/MockERC20.sol";
import { OptionSeries } from "../../src/options/OptionSeries.sol";
import { AquaVolConstantPrice } from "../../src/swapvm/AquaVolConstantPrice.sol";
import { AquaVolSwapVMRouter } from "../../src/swapvm/AquaVolSwapVMRouter.sol";

interface SettlementVm {
    function prank(address sender) external;
    function startPrank(address sender) external;
    function stopPrank() external;
}

/// @notice End-to-end settlement evidence for the AquaVol-modified SwapVM router.
contract AquaVolSwapVMSettlementTest {
    SettlementVm private constant VM =
        SettlementVm(address(uint160(uint256(keccak256("hevm cheat code")))));

    uint256 private constant INITIAL_CALL = 10e18;
    uint256 private constant INITIAL_USDC = 5_000e6;
    uint256 private constant CALL_TO_BUY = 1e18;
    uint256 private constant FIXED_PREMIUM = 61_505_937;
    uint256 private constant BASELINE_XYC_PREMIUM = 555_555_556;
    address private constant WRITER = address(0xA11CE);

    Aqua private aqua;
    AquaVolSwapVMRouter private router;
    MockTaker private taker;
    MockERC20 private weth;
    MockERC20 private usdc;
    OptionSeries private series;
    ISwapVM.Order private customOrder;
    bytes32 private customStrategyHash;

    function setUp() public {
        aqua = new Aqua();
        weth = new MockERC20("Wrapped Ether", "WETH", 18);
        usdc = new MockERC20("USD Coin", "USDC", 6);
        router = new AquaVolSwapVMRouter(
            address(aqua), address(weth), address(this), "AquaVol SwapVM", "1"
        );
        taker = new MockTaker(aqua, router, address(this));

        series = new OptionSeries(
            WRITER,
            address(weth),
            address(usdc),
            4_000e18,
            block.timestamp + 7 days,
            24 hours,
            "AquaVol WETH 4000 Call",
            "avWETH-4000-C"
        );

        weth.mint(WRITER, INITIAL_CALL);
        usdc.mint(WRITER, INITIAL_USDC);
        VM.startPrank(WRITER);
        weth.approve(address(series), type(uint256).max);
        series.write(INITIAL_CALL);
        series.approve(address(aqua), type(uint256).max);
        usdc.approve(address(aqua), type(uint256).max);
        VM.stopPrank();

        customOrder = _buildCustomOrder();
        customStrategyHash = _ship(customOrder);
    }

    function testFixedPremiumQuoteAndSwapReconcileThroughAqua() public {
        bytes memory quoteData = _takerData(0, block.timestamp + 60);
        (uint256 quotedUsdc, uint256 quotedCall, bytes32 quotedHash) =
            router.asView().quote(customOrder, CALL_TO_BUY, quoteData);

        require(quotedUsdc == FIXED_PREMIUM, "fixed premium not authoritative");
        require(quotedUsdc != BASELINE_XYC_PREMIUM, "constant-product price used");
        require(quotedCall == CALL_TO_BUY, "wrong quoted CALL");
        require(quotedHash == customStrategyHash, "wrong strategy hash");

        usdc.mint(address(taker), quotedUsdc);
        uint256 collateralBefore = weth.balanceOf(address(series));
        bytes memory executionData = _takerData(quotedUsdc, block.timestamp + 60);

        (uint256 paidUsdc, uint256 receivedCall) =
            taker.swap(customOrder, CALL_TO_BUY, executionData);

        require(paidUsdc == quotedUsdc, "quote and swap input differ");
        require(receivedCall == quotedCall, "quote and swap output differ");
        require(usdc.balanceOf(address(taker)) == 0, "trader USDC delta");
        require(series.balanceOf(address(taker)) == CALL_TO_BUY, "trader CALL delta");
        require(usdc.balanceOf(WRITER) == INITIAL_USDC + paidUsdc, "maker USDC delta");
        require(series.balanceOf(WRITER) == INITIAL_CALL - receivedCall, "maker CALL delta");

        (uint256 virtualCall, uint256 virtualUsdc) = _virtualBalances(customStrategyHash);
        require(virtualCall == INITIAL_CALL - receivedCall, "virtual CALL delta");
        require(virtualUsdc == INITIAL_USDC + paidUsdc, "virtual USDC delta");
        require(weth.balanceOf(address(series)) == collateralBefore, "collateral moved");
        require(weth.balanceOf(address(series)) == series.totalSupply(), "backing changed");
    }

    function testModifiedRouterStillSettlesUpstreamXYCSwapProgram() public {
        ISwapVM.Order memory upstreamOrder = _buildUpstreamOrder();
        bytes32 upstreamHash = _ship(upstreamOrder);
        bytes memory quoteData = _takerData(0, block.timestamp + 60);
        (uint256 quotedUsdc, uint256 quotedCall, bytes32 quotedHash) =
            router.asView().quote(upstreamOrder, CALL_TO_BUY, quoteData);

        require(quotedUsdc == BASELINE_XYC_PREMIUM, "upstream opcode changed");
        require(quotedCall == CALL_TO_BUY, "wrong upstream CALL quote");
        require(quotedHash == upstreamHash, "wrong upstream strategy hash");

        usdc.mint(address(taker), quotedUsdc);
        (uint256 paidUsdc, uint256 receivedCall) =
            taker.swap(upstreamOrder, CALL_TO_BUY, _takerData(quotedUsdc, block.timestamp + 60));

        require(paidUsdc == quotedUsdc, "upstream quote and swap differ");
        require(receivedCall == CALL_TO_BUY, "wrong upstream settlement output");
        (uint256 virtualCall, uint256 virtualUsdc) = _virtualBalances(upstreamHash);
        require(virtualCall == INITIAL_CALL - CALL_TO_BUY, "upstream virtual CALL delta");
        require(virtualUsdc == INITIAL_USDC + paidUsdc, "upstream virtual USDC delta");
    }

    function testMaximumInputThresholdRevertsAtomically() public {
        usdc.mint(address(taker), FIXED_PREMIUM);
        _expectSwapRevert(
            customOrder, CALL_TO_BUY, _takerData(FIXED_PREMIUM - 1, block.timestamp + 60)
        );
        _requireInitialState(customStrategyHash, FIXED_PREMIUM);
    }

    function testAlteredStrategyBytesCannotUseShippedBalances() public {
        ISwapVM.Order memory alteredOrder = customOrder;
        alteredOrder.data = bytes.concat(customOrder.data, hex"00");
        usdc.mint(address(taker), FIXED_PREMIUM);

        _expectSwapRevert(
            alteredOrder, CALL_TO_BUY, _takerData(FIXED_PREMIUM, block.timestamp + 60)
        );
        _requireInitialState(customStrategyHash, FIXED_PREMIUM);
    }

    function testInsufficientCallLiquidityRevertsAtomically() public {
        uint256 excessiveCall = INITIAL_CALL + 1;
        uint256 availableUsdc = FIXED_PREMIUM * 11;
        usdc.mint(address(taker), availableUsdc);

        _expectSwapRevert(
            customOrder, excessiveCall, _takerData(availableUsdc, block.timestamp + 60)
        );
        _requireInitialState(customStrategyHash, availableUsdc);
    }

    function _buildCustomOrder() private view returns (ISwapVM.Order memory) {
        bytes memory program = bytes.concat(
            AquaVolConstantPrice.build(address(series), address(usdc), FIXED_PREMIUM),
            Salt.build(uint64(1))
        );
        return _buildOrder(program);
    }

    function _buildUpstreamOrder() private view returns (ISwapVM.Order memory) {
        return _buildOrder(bytes.concat(XYCSwap.build(), Salt.build(uint64(2))));
    }

    function _buildOrder(bytes memory program) private view returns (ISwapVM.Order memory) {
        (address tokenA, address tokenB) = _sortedTokens();
        return MakerTraitsLib.build(
            MakerTraitsLib.Args({
                maker: WRITER,
                receiver: address(0),
                tokenA: tokenA,
                tokenB: tokenB,
                shouldUnwrapWeth: false,
                useAquaInsteadOfSignature: true,
                allowZeroAmountIn: false,
                usePermit2: false,
                hasPreTransferInHook: false,
                hasPostTransferInHook: false,
                hasPreTransferOutHook: false,
                hasPostTransferOutHook: false,
                preTransferInTarget: address(0),
                preTransferInData: "",
                postTransferInTarget: address(0),
                postTransferInData: "",
                preTransferOutTarget: address(0),
                preTransferOutData: "",
                postTransferOutTarget: address(0),
                postTransferOutData: "",
                program: program
            })
        );
    }

    function _ship(ISwapVM.Order memory order) private returns (bytes32 strategyHash) {
        (address tokenA, address tokenB) = _sortedTokens();
        address[] memory tokens = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        tokens[0] = tokenA;
        tokens[1] = tokenB;
        amounts[0] = tokenA == address(series) ? INITIAL_CALL : INITIAL_USDC;
        amounts[1] = tokenB == address(series) ? INITIAL_CALL : INITIAL_USDC;

        VM.prank(WRITER);
        strategyHash = aqua.ship(address(router), abi.encode(order), tokens, amounts);
        require(strategyHash == router.hash(order), "ship/hash bytes differ");
    }

    function _takerData(uint256 maxUsdc, uint256 deadline) private view returns (bytes memory) {
        (address tokenA,) = _sortedTokens();
        require(deadline <= type(uint40).max, "deadline overflow");
        return TakerTraitsLib.build(
            TakerTraitsLib.Args({
                taker: address(taker),
                isExactIn: false,
                shouldUnwrapWeth: false,
                isStrictThresholdAmount: false,
                isFirstTransferFromTaker: false,
                useTransferFromAndAquaPush: false,
                isAToB: tokenA == address(usdc),
                allowPartialFill: false,
                usePermit2: false,
                threshold: maxUsdc == 0 ? bytes("") : abi.encode(maxUsdc),
                to: address(0),
                // The preceding bound check makes this narrowing conversion safe.
                // forge-lint: disable-next-line(unsafe-typecast)
                deadline: uint40(deadline),
                hasPreTransferInCallback: true,
                hasPreTransferOutCallback: false,
                preTransferInHookData: "",
                postTransferInHookData: "",
                preTransferOutHookData: "",
                postTransferOutHookData: "",
                preTransferInCallbackData: "",
                preTransferOutCallbackData: "",
                instructionsArgs: "",
                signature: ""
            })
        );
    }

    function _expectSwapRevert(
        ISwapVM.Order memory order,
        uint256 amountOut,
        bytes memory takerData
    ) private {
        bool didRevert;
        try taker.swap(order, amountOut, takerData) { }
        catch {
            didRevert = true;
        }
        require(didRevert, "swap unexpectedly succeeded");
    }

    function _requireInitialState(bytes32 strategyHash, uint256 traderUsdc) private view {
        require(usdc.balanceOf(address(taker)) == traderUsdc, "trader USDC changed");
        require(series.balanceOf(address(taker)) == 0, "trader received CALL");
        require(usdc.balanceOf(WRITER) == INITIAL_USDC, "maker USDC changed");
        require(series.balanceOf(WRITER) == INITIAL_CALL, "maker CALL changed");
        require(weth.balanceOf(address(series)) == INITIAL_CALL, "collateral changed");
        require(series.totalSupply() == INITIAL_CALL, "CALL supply changed");

        (uint256 virtualCall, uint256 virtualUsdc) = _virtualBalances(strategyHash);
        require(virtualCall == INITIAL_CALL, "virtual CALL changed");
        require(virtualUsdc == INITIAL_USDC, "virtual USDC changed");
    }

    function _sortedTokens() private view returns (address tokenA, address tokenB) {
        tokenA = address(series);
        tokenB = address(usdc);
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
    }

    function _virtualBalances(bytes32 strategyHash)
        private
        view
        returns (uint256 callBalance, uint256 usdcBalance)
    {
        return aqua.safeBalances(
            WRITER, address(router), strategyHash, address(series), address(usdc)
        );
    }
}
