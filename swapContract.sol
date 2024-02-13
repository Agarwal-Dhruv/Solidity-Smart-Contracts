// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Swap {

IUniswapV2Router02 public uniswapRouter;

constructor(address _router) {
    uniswapRouter = IUniswapV2Router02(_router);
}

function swapTokenAForTokenB(uint256 amountIn, address tokenA, address tokenB ) public {
        IERC20(tokenA).approve(address(uniswapRouter), amountIn);

        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;

        uniswapRouter.swapExactTokensForTokens(
            amountIn,
            0,
            path,
            address(this),
            block.timestamp + 900
        );
    }

}