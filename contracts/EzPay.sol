// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EzPay {
    // events
    event LoanRequested(
        address indexed paymentToken,
        bool indexed borrower,
        bytes32 indexed id
    );
    event ChangeRequested(address lender, address borrower, bytes32 indexed id, bool notificationToLender);

    event AcceptedLoan(address indexed payer, bytes32 indexed id);
    event RepayedEMI();
    event ColllateralAdded();
    event LoanClosed();

    struct Request {
        address user;
        uint48 timePeriod;
        address collateralToken;
        address paymentToken;
        bool isBorrower;
        uint256 interestRate;
        uint256 paymentTokenAmount;
        uint256 collateralTokenAmount;
    }

    struct Changes {
        address changeRequester;
        address changeRequestTo;
        uint48 timePeriod;
        address collateralToken;
        address paymentToken;
        uint256 interestRate;
        uint256 paymentTokenAmount;
        uint256 collateralTokenAmount;
    }

    struct UnclaimedTokens {
        address user;
        address token;
        uint256 amount;
        uint48 timestamp;
    }

    struct SemiApprovedRequest {
        address approvedBy;
        address needApprovalFrom;
        uint48 timePeriod;
        address collateralToken;
        address paymentToken;
        uint256 interestRate;
        uint256 paymentTokenAmount;
        uint256 collateralTokenAmount;
        bool paidPaymentToken;
    }

    struct Installment {
        address lender;
        uint48 timePeriod;
        uint48 startDate;
        uint256 interestRate;
        address borrower;
        address collateralToken;
        uint256 collateralAmount;
        bool paymentFinalised;
        bool collateralWithdrawn;
        bool borrowerDefaulted;
        address paymentToken;
        uint256 paymentTokenAmount;
    }

    struct EMIDetails {
        uint256 principle;
        uint256 interest;
        uint256 emiAmount;
        uint16 totalMonths;
        uint256 emiPaid;
        uint16 monthsPaid;
        uint48 nextDate;
    }

    // IERC20 public ERC20;

    uint256 constant ONE_DAY = 24 * 60 * 60; // 86400
    uint256 constant ONE_MONTH = 30 * ONE_DAY;

    mapping(bytes32 => Request) public requests;
    mapping(bytes32 => Changes[]) public changes;
    mapping(bytes32 => UnclaimedTokens) public unclaimedTokens;
    // mapping(bytes32 => mapping(address => uint256)) public interestedUsers;
    // mapping(bytes32 => mapping(address => uint256)) public repliesToUsers;
    mapping(bytes32 => mapping(address => SemiApprovedRequest[])) public finalApproval;

    mapping(bytes32 => Installment) public installments; // user => loanId => installment
    // mapping(bytes32 => Collateral) public collateral; // user => token => collateralAmount
    mapping(bytes32 => EMIDetails) public amountPaid; // user => loanId => amountPaid
    mapping(address => bytes32[]) public userLoans;
    mapping(address => bytes32[]) public loanGiven;
    bytes32[] public loans;

    function createRequest(
        address collateralToken,
        address paymentToken,
        uint256 requiredAmount,
        uint256 interestRate,
        uint48 timePeriod,
        bool isLoanRequest,
        uint256 collateralTokenAmount
    ) public {
        require(interestRate <= 5000, "Limit Exceded"); // not more than 50%
        require(timePeriod % ONE_MONTH == 0, "30 Multiple only");

        bytes32 id = keccak256(abi.encode(msg.sender, timePeriod, block.timestamp));

        requests[id].user = msg.sender;
        requests[id].timePeriod = timePeriod;
        requests[id].collateralToken = collateralToken;
        requests[id].paymentToken = paymentToken;
        requests[id].isBorrower = isLoanRequest;
        requests[id].interestRate = interestRate;
        requests[id].paymentTokenAmount = requiredAmount;
        requests[id].collateralTokenAmount = collateralTokenAmount;

        emit LoanRequested(paymentToken, isLoanRequest, id);
    }

    function requestChanges(
        bytes32 id,
        address changeRequestTo,
        uint48 timePeriod,
        address collateralToken,
        address paymentToken,
        uint256 interestRate,
        uint256 paymentTokenAmount,
        uint256 collateralTokenAmount
    ) public {
        require(requests[id].user != address(0), "Invalid Id");
        require(timePeriod % ONE_MONTH == 0, "30 Multiple only");

        Changes memory _changes;

        _changes.changeRequester = msg.sender;
        _changes.timePeriod = timePeriod;
        _changes.collateralToken = collateralToken;
        _changes.paymentToken = paymentToken;
        _changes.interestRate = interestRate;
        _changes.paymentTokenAmount =  paymentTokenAmount;
        _changes.collateralTokenAmount = collateralTokenAmount;

        if(msg.sender != requests[id].user) {
            // interestedUsers[id][msg.sender] = changes[id].length + 1;
            changeRequestTo = msg.sender;
            _changes.changeRequestTo = requests[id].user;
        } else {
            // repliesToUsers[id][changeRequestTo] = changes[id].length + 1;
            _changes.changeRequestTo = changeRequestTo;
        }

        changes[id].push(_changes);

        emit ChangeRequested(requests[id].user, changeRequestTo, id, msg.sender != requests[id].user);
    }

    function claimBackTokens(bytes32 id) public {
        UnclaimedTokens memory _unclaimedToken = unclaimedTokens[id];
        require(_unclaimedToken.user == msg.sender, "Not Authorized");
        require(_unclaimedToken.timestamp + ONE_DAY <= block.timestamp, "Cooldown Period");

        IERC20(_unclaimedToken.token).transfer(_unclaimedToken.user, _unclaimedToken.amount);

        delete(unclaimedTokens[id]);
    }

    function acceptRequest(bytes32 id, uint256 requestNumber) public {
        Changes memory _change = changes[id][requestNumber];
        address requester = _change.changeRequester;

        require(requester != msg.sender || requester != address(0));
        require(_change.changeRequestTo == msg.sender, "Not Requested");

        SemiApprovedRequest memory _semiApprovedRequest;

        _semiApprovedRequest.approvedBy = msg.sender;
        _semiApprovedRequest.needApprovalFrom = _change.changeRequester;
        _semiApprovedRequest.timePeriod = _change.timePeriod;
        _semiApprovedRequest.collateralToken = _change.collateralToken;
        _semiApprovedRequest.paymentToken = _change.paymentToken;
        _semiApprovedRequest.interestRate = _change.interestRate;
        _semiApprovedRequest.paymentTokenAmount = _change.paymentTokenAmount;
        _semiApprovedRequest.collateralTokenAmount = _change.collateralTokenAmount;

        address token = _change.collateralToken;
        uint256 amount = _change.collateralTokenAmount;
        if ((requests[id].user == msg.sender && requests[id].isBorrower == false) ||
        (requests[id].user != msg.sender && requests[id].isBorrower == true)) {
            token = _change.paymentToken;
            amount = _change.paymentTokenAmount;
            _semiApprovedRequest.paidPaymentToken = true;
        }

        finalApproval[id][_change.changeRequester].push(_semiApprovedRequest);

        UnclaimedTokens memory _unclaimedTokens;
        _unclaimedTokens.user = msg.sender;
        _unclaimedTokens.token = token;
        _unclaimedTokens.amount = amount;
        _unclaimedTokens.timestamp = uint48(block.timestamp);

        unclaimedTokens[id] = _unclaimedTokens;

        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function initiateEMI(
        bytes32 id,
        uint256 finalRequestIndex
    ) public {
        bool originalUser = msg.sender == requests[id].user;
        finalRequestIndex = originalUser ? finalRequestIndex : 0;

        SemiApprovedRequest memory _semiApproval = finalApproval[id][msg.sender][finalRequestIndex];

        address token = _semiApproval.paymentToken;
        uint256 amount = _semiApproval.paymentTokenAmount;
        address lender = msg.sender;
        address borrower = _semiApproval.approvedBy;

        require(msg.sender == _semiApproval.needApprovalFrom, "Approval Needed");

        if(_semiApproval.paidPaymentToken) {
            token = _semiApproval.collateralToken;
            amount = _semiApproval.collateralTokenAmount;
            lender = _semiApproval.approvedBy;
            borrower = msg.sender;
        }

        // Installment storage _installment;
        // bytes32 id = keccak256(abi.encode(payer, msg.sender, timePeriod));

        installments[id].lender = lender;
        installments[id].borrower = borrower;
        installments[id].timePeriod = _semiApproval.timePeriod;
        installments[id].startDate = uint48(block.timestamp);
        installments[id].interestRate = _semiApproval.interestRate;
        installments[id].paymentToken = _semiApproval.paymentToken;
        installments[id].paymentTokenAmount = _semiApproval.paymentTokenAmount;
        installments[id].collateralAmount = _semiApproval.collateralTokenAmount;
        installments[id].collateralToken = _semiApproval.collateralToken;

        EMIDetails memory _emi;
        _emi.principle = _semiApproval.paymentTokenAmount;
        _emi.interest = (_semiApproval.paymentTokenAmount * _semiApproval.interestRate)/10000;
        _emi.totalMonths = uint16(_semiApproval.timePeriod / ONE_MONTH);
        _emi.emiAmount = (_semiApproval.paymentTokenAmount + _emi.interest) / _emi.totalMonths;
        _emi.nextDate = uint48(block.timestamp + ONE_MONTH);

        amountPaid[id] = _emi;

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        IERC20(_semiApproval.paymentToken).transfer(borrower, _semiApproval.paymentTokenAmount);

        // emit LoanRequested(payer, msg.sender, id);
    }

    function repayEMI(bytes32 id) public {
        require(installments[id].borrower == msg.sender);
        require(installments[id].paymentFinalised == false);

        EMIDetails memory _emi;
        uint256 amountToPay = amountPaid[id].emiAmount;

        if (amountPaid[id].emiAmount > amountPaid[id].principle - amountPaid[id].emiPaid) {
            amountToPay = amountPaid[id].principle - amountPaid[id].emiPaid;
            installments[id].paymentFinalised = true;
        }

        _emi.emiPaid += amountToPay;
        _emi.monthsPaid += 1;
        if (!installments[id].paymentFinalised) {
            _emi.nextDate = uint48(amountPaid[id].nextDate + ONE_MONTH);
        } else {
            _emi.nextDate = 0;
        }

        amountPaid[id] = _emi;

        IERC20(installments[id].paymentToken).transferFrom(msg.sender, installments[id].lender, amountPaid[id].emiAmount);
    }

    function withdrawCollateral(bytes32 id) public {
        require(installments[id].paymentFinalised == true);
        require(installments[id].collateralWithdrawn == false);

        installments[id].collateralWithdrawn = true;

        IERC20(installments[id].collateralToken).transfer(installments[id].borrower, installments[id].collateralAmount);
    }

    function liquidate(bytes32 id) public {
        require(installments[id].paymentFinalised == false);
        require(amountPaid[id].nextDate < block.timestamp);

        installments[id].collateralWithdrawn = true;
        installments[id].borrowerDefaulted = true;
        installments[id].paymentFinalised = true;

        IERC20(installments[id].collateralToken).transfer(installments[id].lender, installments[id].collateralAmount);
    }
}
