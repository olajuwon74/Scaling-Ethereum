// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;


contract CREDITSCORE {




    struct USERINFORMATION{

        address userAddress;
        bool oweing;
        uint currentLoanAmount;
        uint amountOfLoansCollected;
        uint creditPercent;
    }

    struct LOANINFORMATION{
        address user;
        uint amount;
        uint loanDate;
        uint repaymentDate;
        bool repaid;
    }

    uint public loanId;
    uint public balances = address(this).balance;

    mapping(address => USERINFORMATION) public addressDetails;
    mapping(uint => USERINFORMATION) public userID;
    mapping(address => LOANINFORMATION) public addressLoanInfo;
    mapping(uint => LOANINFORMATION) public idUserLoanInfo;

    function calculateLoan(address _loanee) public view returns(uint){
        // require(msg.sender.balance > _availableAmount, "you dont havee enough capital");
        USERINFORMATION storage info = addressDetails[_loanee];
        uint _amountObtainable = 0;
        uint _availableAmount = msg.sender.balance;
        if(info.amountOfLoansCollected > 10){
           _amountObtainable = (_availableAmount * info.creditPercent)/ info.amountOfLoansCollected;
        }
        else if(info.creditPercent < 1){
            _amountObtainable = (_availableAmount * 1) / 10000000000000000;
        }
        else{
         _amountObtainable = (_availableAmount * info.creditPercent)/10000000000000000;
        }
        return (_amountObtainable);

    }

    function addUser(address _user) public {
        require(_user == msg.sender, "not accepted");
        USERINFORMATION storage user = addressDetails[msg.sender];
        user.amountBorrowed = 0;
        user.amountOfLoansCollected = 0;
        user.creditPercent = 1;
        user.currentLoanAmount = 0;
        user.oweing = false;
        user.userAddress = _user;
    }

    //User must have funds on the platform(probably used as spot trading.
    //funds in futures or other trading asides spot trading are not considered.
    function takeLoan(uint _amountNeeded, uint _repaymentDate) public returns(uint){
        LOANINFORMATION storage loan = addressLoanInfo[msg.sender];
        USERINFORMATION storage user = addressDetails[msg.sender];
        uint _amountObtainable = calculateLoan(msg.sender);
        require(_amountObtainable >= _amountNeeded, "Amount needed exceeds amount that can be gotten");
        loan.amount = _amountObtainable;
        loan.loanDate = block.timestamp;
        loan.repaid = false;
        loan.repaymentDate = block.timestamp + _repaymentDate;
        loan.user = msg.sender;
        loanId++;
        user.amountBorrowed += _amountObtainable;
        user.amountOfLoansCollected++;
        user.currentLoanAmount = _amountObtainable;
        user.oweing = true;
        user.userAddress = msg.sender;
        address(this).balance - _amountObtainable;
        (bool success, bytes memory data) = msg.sender.call{value: _amountObtainable}("");
        return(_amountObtainable);

        //Transfer not working.
    }
    function repayLoan(uint _amount) public payable returns (uint){
        LOANINFORMATION storage loan = idUserLoanInfo[loanId];
        USERINFORMATION storage user = userID[loanId];
        require(_amount >= loan.amount, "invalid amount");
        (bool success, bytes memory data) = address(this).call{value: _amount}("");
        address(this).balance + _amount;
        loan.repaid = true;
        loan.repaymentDate = block.timestamp;
         user.oweing = false;
        if(block.timestamp <= loan.repaymentDate){
            user.creditPercent++;
        }
        else 
        user.creditPercent--;
        return(_amount);
    }

    function takeEther(address payable _to) public payable returns (uint){
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        return (msg.value);
    }

    receive() external payable {}


}