// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EzPay {
    // events
    event LoanRequested(
        address indexed requester,
        bool indexed borrower,
        bytes32 indexed id
    );
    event ChangeRequested(address indexed lender, address indexed borrower, bytes32 indexed id, bool notificationToLender);
    event ClaimTokens(bytes32 indexed id);
    event RequestAccepted(bytes32 indexed id, address indexed user);

    event LoanTransferred(address indexed lender, address indexed borrower, bytes32 indexed id);
    event EMIPaid(address indexed borrower, uint256 amount);
    event CollateralWithdrawn(address indexed borrower, address token, uint256 amount);
    event Liquidated(address indexed lender, address indexed borrower, uint256 amount);

    struct Request {
        address user;
        uint48 timePeriod;
        address collateralToken;
        address paymentToken;
        bool isBorrower;
        uint256 interestRate;
        uint256 paymentTokenAmount;
        uint256 collateralTokenAmount;
        bool completed;
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
    mapping(bytes32 => mapping(address => uint256)) public interestedUsers;
    mapping(bytes32 => mapping(address => uint256)) public repliesToUsers;
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

        emit LoanRequested(msg.sender, isLoanRequest, id);
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
            interestedUsers[id][msg.sender] = changes[id].length + 1;
            changeRequestTo = msg.sender;
            _changes.changeRequestTo = requests[id].user;
        } else {
            repliesToUsers[id][changeRequestTo] = changes[id].length + 1;
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

        emit ClaimTokens(id);
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

        emit RequestAccepted(id, _change.changeRequester);
    }

    function initiateEMI(
        bytes32 id,
        uint256 finalRequestIndex
    ) public {
        require(requests[id].completed == false, "Initialised Already");
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
        requests[id].completed = true;

        delete(unclaimedTokens[id]);

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        IERC20(_semiApproval.paymentToken).transfer(borrower, _semiApproval.paymentTokenAmount);

        emit LoanTransferred(lender, borrower, id);
    }

    // function acceptEMI(bytes32 _loanId) public payable {
    //     Installment memory _installment = installments[_loanId];
    //     require(msg.sender == _installment.payer, "Not Authorized");

    //     installments[_loanId].requestAccepted = true;

    //     emit AcceptedLoan(msg.sender, _loanId);
    // }

    // function calculateLoan(
    //     bytes32 _loanId
    // ) public view returns (EMIDetails memory) {
    //     Installment memory _installment = installments[_loanId];

    //     EMIDetails memory detail;

    //     if (
    //         block.timestamp < _installment.startDate ||
    //         _installment.paymentFinalised == true
    //     ) {
    //         return detail;
    //     }

    //     uint256 timeperiodInMonth = ((_installment.timePeriod -
    //         _installment.startDate) / ONE_MONTH);

    //     detail.principle = _installment.amount / timeperiodInMonth;
    //     detail.interest =
    //         (detail.principle * _installment.interestRate) /
    //         10000;

    //     return detail;
    // }

    // function loanDepositRatio() public {}

    // function earlyCloseRequest() public {}

    // function closeLoan() public {}

    // function addTokens(
    //     bytes32 _loanId,
    //     bool lender
    // ) internal {
    //     Request memory _request = requests[_loanId];

    //     // Collateral memory _collateral;
    //     collateral[_loanId];
    // }

    function repayEMI(bytes32 id) public {
        require(installments[id].borrower == msg.sender);
        require(installments[id].paymentFinalised == false);

        EMIDetails memory _emi;
        uint256 amountToPay = amountPaid[id].emiAmount;

        if (amountPaid[id].emiAmount > amountPaid[id].principle + amountPaid[id].interest - amountPaid[id].emiPaid) {
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

        emit EMIPaid(msg.sender, amountToPay);
    }

    function withdrawCollateral(bytes32 id) public {
        require(installments[id].paymentFinalised == true);
        require(installments[id].collateralWithdrawn == false);

        installments[id].collateralWithdrawn = true;

        IERC20(installments[id].collateralToken).transfer(installments[id].borrower, installments[id].collateralAmount);

        emit CollateralWithdrawn(msg.sender, installments[id].collateralToken, installments[id].collateralAmount);
    }

    function liquidate(bytes32 id) public {
        require(installments[id].paymentFinalised == false);
        require(amountPaid[id].nextDate < block.timestamp);

        installments[id].collateralWithdrawn = true;
        installments[id].borrowerDefaulted = true;
        installments[id].paymentFinalised = true;

        IERC20(installments[id].collateralToken).transfer(installments[id].lender, installments[id].collateralAmount);

        emit Liquidated(installments[id].lender, installments[id].borrower, installments[id].collateralAmount);
    }
}
