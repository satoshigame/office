import "pay_info.sol";
import "card.sol";
import "poker_constants.sol";

// define player class
contract Player {
    string public ACTION_FOLD_STR;
    string public ACTION_CALL_STR;
    string public ACTION_RAISE_STR;
    string public ACTION_SMALL_BLIND;
    string public ACTION_BIG_BLIND;
    string public ACTION_ANTE;

    string public name;
    // session_id
    uint public uuid;
    string public head_img;
    Card[] public hole_card;
    uint public stack;
    Action[] round_action_histories;
    Action[] action_histories;
    PayInfo public pay_info;
    // player participate in pre round
    bool public pre_exist;
    string public code; 
    
    // get by game_evaluation
    string public hand_strength;

    function Player(uint _uuid, uint _initial_stack, string _name, string _head_img, bool _pre_exist, string _code) {
        ACTION_FOLD_STR = "FOLD";
        ACTION_CALL_STR = "CALL";
        ACTION_RAISE_STR = "RAISE";
        ACTION_SMALL_BLIND = "SMALLBLIND";
        ACTION_BIG_BLIND = "BIGBLIND";
        ACTION_ANTE = "ANTE";
        name = _name;
        uuid = _uuid;

        head_img = _head_img;
        stack = _initial_stack;     // chip take on table
        round_action_histories = __init_round_action_histories();
        pay_info = PayInfo();
        pre_exist = _pre_exist;
        code = _code;
        hand_strength = "";
    }

    function add_holecard(Card[] cards) {
        // lump-sum send card 
        if (hole_card.length != 0) {
            return;
        }
        if (cards.length != 2) {
            return;
        }
        hole_card = cards;
    }

    function clear_holecard() {
        hole_card = [];
    }

    // call when user click or set default supply
    function append_chip(uint amount) {
        stack += amount;
    }

    function collect_bet(uint amount) {
        if (stack < amount) {
            return;
        }
        stack -= amount;
    }

    function is_active() {
        if (pay_info.status == FOLDED || pay_info.status == WATCH) {
            return false;
        }
        return true;
    }

    function is_waiting_ask() {
        // not reach an agreement in a street
        return pay_info.status == PAY_TILL_END;
    }

    function add_action_history(uint kind, uint chip_amount, uint add_amount, uint sb_amount) {
        Action history;

        // record a history into list for each operation
        if (kind == Action.FOLD) {
            history = __fold_history();
        }
        else if (kind == Action.CALL) {
            history = __call_history(chip_amount);
        }
        else if (kind == Action.RAISE) {
            history = __raise_history(chip_amount, add_amount);
        }
        else if (kind == Action.SMALL_BLIND) {
            history = __blind_history(true, sb_amount);
        }
        else if (kind == Action.BIG_BLIND) {
            history = __blind_history(False, sb_amount);
        }
        else if (kind == Action.ANTE) {
            history = __ante_history(chip_amount);
        }
        else {
            return;
        }
        history = __add_uuid_on_history(history);
        action_histories.append(history);
        return;
    }

    function save_street_action_histories(uint street_flg) {
        // group action by street
        round_action_histories[street_flg] = action_histories;
        action_histories = [];
    }

    function clear_action_histories() {
        round_action_histories = __init_round_action_histories();
        action_histories = [];
    }

    function clear_pay_info() {
        pay_info = PayInfo();
    }

    function paid_sum() {
        Action[] pay_history;
        for (uint i = 0; i < action_histories.length; i++) {
            if (action_histories[i].action != "FOLD" && action_histories[i].action != "ANTE") {
                pay_history.push(action_histories[i]);
            }
        }
        if (pay_history.length > 0) {
            // amount means sum of paid in a round
            return pay_history[pay_history.length - 1].amount;
        }
        return 0;
    }

    function __init_round_action_histories() {
        return [];  
    }

    // history record
    function __fold_history() {
        Action res;
        res.action = ACTION_FOLD_STR;
        return res;
    }

    function __call_history(uint bet_amount) {
        Action res;
        res.action = ACTION_CALL_STR;
        res.amount = bet_amount;
        res.paid = bet_amount - paid_sum();
        return res;
    }

    function __raise_history(uint bet_amount, uint add_amount) {
        Action res;
        res.action = ACTION_RAISE_STR;
        res.amount = bet_amount;
        res.paid = bet_amount - paid_sum();
        res.add_amount = add_amount;
        return res;
    }

    function __blind_history(uint small_blind, uint sb_amount) {
        action = ACTION_BIG_BLIND;
        amount = sb_amount * 2;
        add_amount = sb_amount * 2;
        if (small_blind) {
            action = ACTION_SMALL_BLIND;
            amount = small_blind;
            add_amount = small_blind;
        }
        Action res;
        res.action = action;
        res.amount = amount;
        res.add_amount = add_amount;
        return res;
    }

    function __ante_history(uint pay_amount) {
        Action res;
        res.action = ACTION_ANTE;
        res.amount = pay_amount;
        return res;
    }

    function __add_uuid_on_history(Action history) {
        history.uuid = uuid;
        return history;
    }
}

