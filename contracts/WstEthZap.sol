// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IWeth is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

interface IWstEth is IERC20{
    function unwrap(uint256 _wstETHAmount) external returns (uint256);
    function wrap(uint256 stETHAmount) external returns (uint256);
    function stETH() external view returns (IERC20);
}


contract WstEthZap is IUniswapV3SwapCallback{
    using SafeMath for uint256;
    using SafeCast for uint256;

    IUniswapV3Pool public uniPool;

    IERC20 public stEth;
    IWstEth public wstETH;
    uint32 twapDuration;
    IWeth public weth = IWeth(address(0xd0A1E359811322d97991E03f863a0C30C2cF029C));

    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;

    uint256 public MAX = uint256(-1);

    constructor() public {
            uniPool = IUniswapV3Pool(address(0x579f24B20A237c7544b1eD7468e606Ba5FB893CD));
            wstETH = IWstEth(address(0x387e56C0574a05F480E1Ee0FA00aF28B19076392));
            stEth = wstETH.stETH();
            stEth.approve(address(wstETH), MAX);
    }

    receive () payable external {

    }

    fallback () payable external {

    }

    function swap(
        address tokenIn, 
        uint256 amountIn, 
        uint256 amountOut,
        address receipent) external payable {
        

        require(tokenIn == address(stEth) || tokenIn == address(0), "Only steth eth swap");

        if(tokenIn == address(0)){
            
            require(msg.value >= amountIn, "Not enough ether");
            weth.deposit{value: msg.value}();
            tokenIn = address(weth);

        }else{
            stEth.transferFrom(msg.sender, address(this), amountIn);
            amountIn = wstETH.wrap(amountIn);
            tokenIn = address(wstETH);
        }

        bool zeroForOne = tokenIn == uniPool.token0();

        bytes memory data = abi.encode(amountOut, zeroForOne, receipent);
        uniPool.swap(
            address(this), 
            zeroForOne,
            amountIn.toInt256(),
            zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
            data
        );


    }


    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {

        require(msg.sender == address(uniPool), "Invalid access");

        (uint256 amountOut, bool zeroForOne, address receipent) = abi.decode(_data, (uint256, bool, address));

        (address tokenIn, address tokenOut, uint256 amountIn) = zeroForOne ? 
                            (uniPool.token0(), uniPool.token1(), uint256(amount0Delta)) 
                            : (uniPool.token1(), uniPool.token0(), uint256(amount1Delta));
        


        if(tokenOut == address(weth)){


            weth.withdraw(weth.balanceOf(address(this)));
            require(address(this).balance >= amountOut, "Not enough transferred");

            payable(receipent).transfer(address(this).balance);

        }else{
            

            uint256 stethAmount = wstETH.unwrap(wstETH.balanceOf(address(this)));
            
            require(stethAmount >= amountOut, "Steth amount is required");

            stEth.transfer(receipent, stethAmount);

        }


        IERC20(tokenIn).transfer(address(uniPool), amountIn);
    }
    


}