contract PayInfo {
    uint8 public PAY_TILL_END;
    uint8 public ALLIN;
    uint8 public FOLDED;
    uint8 public WATCH;
    uint public amount;
    uint public status;

    // record status and amount
    function PayInfo(uint _amount, uint _status) {
        PAY_TILL_END = 0;
        ALLIN = 1;
        FOLDED = 2;
        WATCH = 3;
        amount = _amount;
        status = _status;
    }

    function update_by_pay(uint _amount) {
        amount += _amount;
    }

    function update_to_fold() {
        status = FOLDED;
    }

    function update_to_allin() {
        status = ALLIN;
    }

    // stand up, still get game info 
    function update_to_watch() {
        status = WATCH;
    }

}



