// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(
        bytes memory returndata,
        string memory errorMessage
    ) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

library Strings {
    function toUpperCase(
        string memory _str
    ) public pure returns (string memory) {
        bytes memory bStr = bytes(_str);
        bytes memory bUpper = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase the letter if it's a lowercase letter
            if ((bStr[i] >= 0x61) && (bStr[i] <= 0x7A)) {
                bUpper[i] = bytes1(uint8(bStr[i]) - 32);
            } else {
                bUpper[i] = bStr[i];
            }
        }
        return string(bUpper);
    }
}

interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface PAXGOLD {
    function feeRate() external view returns (uint256);
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(
            nonceAfter == nonceBefore + 1,
            "SafeERC20: permit did not succeed"
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

/**
 * @title HToken
 * @dev HToken is an ERC20 token that is backed by Pax Gold (PAXG).
 *The value of the token is derived from the amount of PAXG in the reserve.
 *HToken can be minted and burned by depositing and withdrawing PAXG from the reserve.
 *A small percentage of each transfer is burned, decreasing the total supply and increasing the value of each token.
 */
contract HToken is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public totalReserve_; // Total amount of PAXG in the reserve
    uint256 private immutable initialSupply_;
    uint256 public value_; // The value of each token, expressed in PAXG
    uint256 public constant burnFee_ = 5; // 0.5% burn rate (in basis points)
    uint256 public constant MULTIPLIER = 1000; //basis points
    IERC20 public paxGold_; // The PAXG contract
    address public immutable hTokenFactoryAddr_; //HTOKEN Factory Address
    uint256 public constant PRECISION_FACTOR = 1e18; //Precison factor for value calculations
    uint256 public lastValue_; //The last value recorded
    // uint256 public paxGoldFee; //Get transfer fee from PaxGold
    uint256 public constant PAXGOLD_FEE_PARTS = 1000000; //Get paxGoldFeeParts

    event HTokenMinted(
        address indexed tokenAddress,
        string name,
        string symbol,
        address indexed account,
        uint256 value
    );
    event HTokenBurned(
        address indexed tokenAddress,
        string name,
        string symbol,
        address indexed account,
        uint256 value
    );

    /**

    @dev Constructor for HToken contract

    @param _paxGold The address of the PAXG contract

    @param _initialDeposit The initial amount of PAXG to deposit into the reserve

    @param _initialSupply The initial supply of HToken to mint

    @param _name The name of the HToken

    @param _symbol The symbol of the HToken

    @param _userAddress The address of the user that will receive the initial supply of HToken
    */
    constructor(
        address _paxGold,
        uint256 _initialDeposit,
        uint256 _initialSupply,
        string memory _name,
        string memory _symbol,
        address _userAddress
    ) ERC20(_name, _symbol) {
        paxGold_ = IERC20(_paxGold);
        hTokenFactoryAddr_ = msg.sender;
        require(
            _initialDeposit > 0,
            "Initial deposit must be greater than zero"
        );
        require(_initialSupply > 0, "Initial supply must be greater than zero");

        totalReserve_ = calculateReceivedPaxg(_initialDeposit);
        initialSupply_ = _initialSupply;
        value_ = (totalReserve_.mul(PRECISION_FACTOR)).div(_initialSupply);
        _mint(_userAddress, _initialSupply);
    }

    /**
    @dev Calculates the receivable PAXG.
    @param _amount the amount of HToken to burn.
    @return receivedPaxg - Receivable PAXG after fee deduction.
     */
    function calculateReceivedPaxg(
        uint256 _amount
    ) public view returns (uint256 receivedPaxg) {
        return
            _amount.sub(
                (_amount.mul(PAXGOLD(address(paxGold_)).feeRate())).div(
                    PAXGOLD_FEE_PARTS
                )
            );
    }

    /*
    @dev Calculates the Htoken to be minted.
    @param _amountPaxg the amount of PAXG to deposit
    @return HTKAmountsOut - HToken to be minted.
     */
    function getHtokenAmountsOut(
        uint _amountPaxg
    ) public view returns (uint256 HTKAmountsOut) {
        uint tempPaxgReceived = calculateReceivedPaxg(_amountPaxg); //Dummy var to calculate PAXG to be received after fee deduction.
        if (totalSupply() == 0) {
            return (tempPaxgReceived.mul(PRECISION_FACTOR)).div(lastValue_);
        } else {
            return (tempPaxgReceived.mul(PRECISION_FACTOR)).div(value_);
        }
    }

    function getPaxgAmountsOut(
        uint _amountHtoken
    ) public view returns (uint256 PAXGAmountsOut) {
        uint256 temp;
        if (value_ == 0) {
            temp = (_amountHtoken.mul(lastValue_)).div(PRECISION_FACTOR);
        } else {
            temp = (_amountHtoken.mul(value_)).div(PRECISION_FACTOR);
        }
        return calculateReceivedPaxg(temp);
    }

    /**

    @dev Calculates the current value of each HToken
    */
    function _updateValue() public {
        value_ = totalSupply() == 0
            ? 0
            : (totalReserve_.mul(PRECISION_FACTOR)).div(totalSupply());
    }

    /**

    @dev Mint new HToken by depositing PAXG into the reserve

    @param _value The amount of PAXG to deposit
    */
    function mint(uint256 _value) public nonReentrant {
        uint256 hTokenToMint;
        uint256 paxgReceived;

        require(
            paxGold_.balanceOf(msg.sender) >= _value,
            "Insufficient PaxGold balance"
        );

        paxGold_.safeTransferFrom(msg.sender, address(this), _value);
        paxgReceived = calculateReceivedPaxg(_value);

        if (totalSupply() == 0) {
            hTokenToMint = (paxgReceived.mul(PRECISION_FACTOR)).div(lastValue_);
        } else {
            hTokenToMint = (paxgReceived.mul(PRECISION_FACTOR)).div(value_);
        }
        _mint(msg.sender, hTokenToMint);

        totalReserve_ = totalReserve_.add(paxgReceived);
        lastValue_ = value_;
        _updateValue();
        emit HTokenMinted(
            address(this),
            name(),
            symbol(),
            msg.sender,
            hTokenToMint
        );
    }

    /**

    @dev Burn HToken and receive PAXG in return

    @param _value The amount of HToken to burn
    */
    function burn(uint256 _value) public nonReentrant {
        require(balanceOf(msg.sender) >= _value, "Insufficient HToken balance");
        //Expected Paxg
        uint256 paxGoldValue = (_value.mul(value_)).div(PRECISION_FACTOR);
        paxGold_.safeTransfer(msg.sender, paxGoldValue);
        totalReserve_ = totalReserve_.sub(paxGoldValue);
        _burn(msg.sender, _value);
        lastValue_ = value_;
        _updateValue();
        emit HTokenBurned(address(this), name(), symbol(), msg.sender, _value);
    }

    /**

    @dev Transfer HToken while applying a burn fee

    @param recipient The address to transfer HToken to

    @param amount The amount of HToken to transfer

    @return A boolean indicating if the transfer was successful or not
    */
    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 calculatedBurnFee = amount.mul(burnFee_).div(MULTIPLIER);

        _burn(msg.sender, calculatedBurnFee);
        lastValue_ = value_;
        _updateValue();
        return super.transfer(recipient, amount.sub(calculatedBurnFee));
    }

    /**

    @dev Transfer HToken from a specified address to another while applying a burn fee

    @param sender The address to transfer HToken from

    @param recipient The address to transfer HToken to

    @param amount The amount of HToken to transfer

    @return A boolean indicating if the transfer was successful or not
    */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 calculatedBurnFee = amount.mul(burnFee_).div(MULTIPLIER);

        _burn(sender, calculatedBurnFee);
        lastValue_ = value_;
        _updateValue();
        return
            super.transferFrom(
                sender,
                recipient,
                amount.sub(calculatedBurnFee)
            );
    }

    /**

    @dev Get HToken contract details
    @return A tuple containing the HToken name, symbol, total supply, and current value of the HToken
    */
    function getDetails()
        public
        view
        returns (string memory, string memory, uint256, uint256)
    {
        return (name(), symbol(), totalSupply(), value_);
    }
}

/**
 * @title HTokenFactory
 * @dev A factory contract for creating HToken instances.
 */
contract HTokenFactory is ReentrancyGuard {
    IERC20 public immutable paxGold_;
    using Strings for string;

    struct HTokenData {
        address hTokenAddress;
        string name;
        string symbol;
        uint256 index;
    }

    uint256 internal hTokenCount_;
    uint256 internal immutable minPaxgDeposit_;
    mapping(uint256 => address) internal hTokenIndexToAddress_;
    mapping(address => HTokenData) internal hTokenAddressToData_;
    mapping(string => uint) internal hTokenNameToIndex_;

    event HTokenCreated(
        address indexed hTokenAddress,
        string name,
        string symbol
    );

    constructor(IERC20 _paxGold, uint _minPaxgAmount) {
        paxGold_ = _paxGold;
        minPaxgDeposit_ = _minPaxgAmount;
    }

    function createHToken(
        string memory _name,
        string memory _symbol,
        uint256 _initialDeposit,
        uint256 _initialSupply
    ) public nonReentrant {
        require(
            _initialDeposit >= minPaxgDeposit_,
            "Initial deposit is too low"
        );
        require(_initialSupply > 0, "Initial supply must be greater than ZERO");
        require(
            paxGold_.balanceOf(msg.sender) >= _initialDeposit,
            "Insufficient PaxGold balance"
        );
        require(
            paxGold_.allowance(msg.sender, address(this)) >= _initialDeposit,
            "Factory is not approved to spend PAXG on behalf of user"
        );

        string memory tempName = convertToUpperCase(_name);
        string memory tempSymbol = convertToUpperCase(_symbol);
        require(
            hTokenNameToIndex_[tempName] == 0,
            "HToken name already exists"
        );
        require(
            hTokenNameToIndex_[tempSymbol] == 0,
            "HToken symbol already exists"
        );

        hTokenCount_++;

        HToken hToken = new HToken(
            address(paxGold_),
            _initialDeposit,
            _initialSupply,
            _name,
            _symbol,
            msg.sender
        );

        hTokenAddressToData_[address(hToken)] = HTokenData({
            hTokenAddress: address(hToken),
            name: _name,
            symbol: _symbol,
            index: hTokenCount_
        });

        require(
            paxGold_.transferFrom(msg.sender, address(hToken), _initialDeposit),
            "Paxg transfer failed"
        );

        hTokenIndexToAddress_[hTokenCount_] = address(hToken);
        hTokenNameToIndex_[tempName] = hTokenCount_;
        hTokenNameToIndex_[tempSymbol] = hTokenCount_;

        emit HTokenCreated(address(hToken), _name, _symbol);
    }

    /*
    @dev Gets the minimum amount out of PAXG to be deposited.
    @return minimumPaxgDeposit.
     */
    function getMinPaxgDeposit()
        public
        view
        returns (uint256 minimumPaxgDeposit)
    {
        return minPaxgDeposit_;
    }

    /*
    @dev Gets the current HToken count.
    @return hTokenCounts.
     */
    function getHTokenCount() public view returns (uint256 hTokenCounts) {
        return hTokenCount_;
    }

    /*
    @dev Gets the Htoken address from index value.
    @param _num Index number
    @return htokenIndexToAddress - HToken address.
     */
    function getHTokenAddressFromIndex(
        uint256 _num
    ) public view returns (address htokenIndexToAddress) {
        return hTokenIndexToAddress_[_num];
    }

    /*
    @dev Gets the Htoken details from address.
    @param _addr Address of HToken
    @return hTokenAddress - HToken address.
    @return name - HToken name.
    @return symbol - HToken symbol.
     */
    function getHTokenDataFromAddress(
        address _addr
    )
        public
        view
        returns (
            address hTokenAddress,
            string memory name,
            string memory symbol,
            uint256 index
        )
    {
        HTokenData storage hTokenData = hTokenAddressToData_[_addr];
        return (
            hTokenData.hTokenAddress,
            hTokenData.name,
            hTokenData.symbol,
            hTokenData.index
        );
    }

    function convertToUpperCase(
        string memory _str
    ) internal pure returns (string memory) {
        return _str.toUpperCase();
    }
}

/**
 * @title HTokenRouter
 * @dev A router contract for interacting with HToken instances and
 * performing token swaps.
 */
contract HTokenRouter is ReentrancyGuard {
    HTokenFactory public immutable factory_;

    using SafeMath for uint256;

    /**
     * @dev Constructor to initialize the HTokenRouter with the HTokenFactory address.
     * @param _factory The address of the HTokenFactory contract.
     */
    constructor(HTokenFactory _factory) {
        factory_ = _factory;
    }

    /**
     * @dev Function to check if an HToken contract is valid.
     * @param _htk The address of the HToken contract.
     * @return A boolean indicating if the HToken contract is valid.
     */
    function isValidHTK(address _htk) public view returns (bool) {
        (, , , uint index) = factory_.getHTokenDataFromAddress(_htk);
        return index != 0;
    }

    /**
     * @dev Function to get the HToken balances of a user.
     * @param _user The address of the user.
     * @return htokenBalances - An array of the user's HToken balances.
     */
    function getUserBalances(
        address _user
    ) public view returns (uint256[] memory htokenBalances) {
        uint256 hTokenCount = factory_.getHTokenCount();
        uint256[] memory hTokenBalances = new uint256[](hTokenCount);
        for (uint256 i = 1; i < hTokenCount; i++) {
            address hTokenAddress = factory_.getHTokenAddressFromIndex(i);
            HToken hToken = HToken(hTokenAddress);
            hTokenBalances[i] = hToken.balanceOf(_user);
        }
        return (hTokenBalances);
    }

    /**
     * @dev Function to swap one HToken for another.
     * @param fromHTK The address of the HToken to swap from.
     * @param fromAmount The amount of fromHTK to swap.
     * @param toHTK The address of the HToken to swap to.
     */
    function swapExactHTKForHTK(
        address fromHTK,
        uint256 fromAmount,
        address toHTK
    ) public nonReentrant {
        // Ensure that the fromHTK and toHTK are valid HToken contracts
        require(isValidHTK(fromHTK), "fromHTK is not a valid HToken contract");
        require(isValidHTK(toHTK), "toHTK is not a valid HToken contract");

        // Get the instances of the HToken contracts
        HToken fromToken = HToken(fromHTK);
        HToken toToken = HToken(toHTK);

        //Fetch paxgBalanceBeforeBurn
        uint256 paxgBalanceBeforeBurn = fromToken.paxGold_().balanceOf(
            address(this)
        );
        uint256 paxgBalanceAfterBurn; //Stores Paxg Balance of the contract after burn.

        // Ensure that the caller has sufficient balance of the from HToken
        require(
            fromToken.balanceOf(msg.sender) >= fromAmount,
            "Insufficient from HToken balance"
        );

        // Transfer the fromHTK from the caller to the router, and approve the router to spend the fromAmount
        require(
            fromToken.transferFrom(msg.sender, address(this), fromAmount),
            "HTK Transfer to the router failed."
        );

        //calculate the received amount of from HToken after deducting the burn fee.
        uint256 receivedFromToken = fromAmount.sub(
            (fromAmount.mul(fromToken.burnFee_())).div(fromToken.MULTIPLIER())
        );

        // Burn the fromToken and retrieve the paxGoldValue
        fromToken.burn(receivedFromToken); // this will return paxg to the router

        paxgBalanceAfterBurn = fromToken.paxGold_().balanceOf(address(this));

        //Calculate the PaxgReceived to router contract after burning From HToken
        uint256 paxgReceivedToRouter = paxgBalanceAfterBurn.sub(
            paxgBalanceBeforeBurn
        );

        //Approve the ToToken Contract to mint on behalf of Router contract
        IERC20 paxGold = fromToken.paxGold_();
        require(
            paxGold.approve(address(toToken), paxgReceivedToRouter),
            "PAXG Approve Failed"
        );

        // Mint the new toTokens using the received paxGold
        toToken.mint(paxgReceivedToRouter); // this will consume paxg from the router
        //mint directly to the user

        // Calculate to Htokens Htokens Minted

        uint256 toAmount = toToken.getHtokenAmountsOut(paxgReceivedToRouter);

        require(
            toToken.transfer(msg.sender, toAmount),
            "Desired Token transfer failed to the caller"
        ); // send the htoken that were recieved while mint.

        // Emit the Swap event
        emit Swap(msg.sender, fromAmount, fromHTK, toHTK, toAmount);
    }

    /**
     * @dev getSwapAmountsOut provides the desired token's value_ receivable to the caller.
     * @param _tokenA The address of the HToken being swapped from.
     * @param _tokenB The amount of the HToken being swapped to.
     * @param _amountA The amount of the HToken being swapped from.
     */
    function getSwapAmountsOut(
        address _tokenA,
        address _tokenB,
        uint256 _amountA
    ) public view returns (uint256 amountB) {
        // Get the instances of the HToken contracts
        HToken fromToken = HToken(_tokenA);
        HToken toToken = HToken(_tokenB);
        //temproray calculations for apperciated value while transfer from A to router.
        uint256 tempValueA = fromToken.value_();
        uint256 tempTotalSupplyA = fromToken.totalSupply();
        uint256 tempTotalReserveA = fromToken.totalReserve_();
        uint256 tempLastValueA = fromToken.lastValue_();
        uint256 paxgReceivedToRouter; //paxgReceived to router after burn.

        //calculate the received amount of from HToken after deducting the burn fee.
        uint256 receivedFromToken = _amountA.sub(
            (_amountA.mul(fromToken.burnFee_())).div(fromToken.MULTIPLIER())
        );

        tempTotalSupplyA = tempTotalSupplyA.sub(
            (_amountA.mul(fromToken.burnFee_())).div(fromToken.MULTIPLIER())
        );

        tempValueA = (tempTotalReserveA.mul(fromToken.PRECISION_FACTOR())).div(
            tempTotalSupplyA
        );

        //Calculate the PaxgReceived to router contract after burning From HToken
        if (tempValueA == 0) {
            paxgReceivedToRouter = (receivedFromToken.mul(tempLastValueA)).div(
                fromToken.PRECISION_FACTOR()
            );
        } else {
            paxgReceivedToRouter = (receivedFromToken.mul(tempValueA)).div(
                fromToken.PRECISION_FACTOR()
            );
        }
        //Calculating received PAXG.
        paxgReceivedToRouter = fromToken.calculateReceivedPaxg(
            paxgReceivedToRouter
        );

        // Calculate to Htokens Htokens Minted
        uint256 toAmount = toToken.getHtokenAmountsOut(paxgReceivedToRouter);

        //Final Amount of toToken transferred to user after fee deduction.
        toAmount = toAmount.sub(
            (toAmount.mul(toToken.burnFee_())).div(toToken.MULTIPLIER())
        );
        return toAmount;
    }

    /**
     * @dev Event emitted when a token swap occurs.
     * @param user The address of the user performing the swap.
     * @param amount The amount of the HToken being swapped from.
     * @param fromHTK The address of the HToken being swapped from.
     * @param toHTK The address of the HToken being swapped to.
     * @param toAmount The amount of the HToken being swapped to.
     */
    event Swap(
        address indexed user,
        uint256 amount,
        address indexed fromHTK,
        address indexed toHTK,
        uint256 toAmount
    );
}
