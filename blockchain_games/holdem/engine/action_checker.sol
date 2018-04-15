
contract ActionChecker {

    // illegal check

    // correct action 
    function correct_action(Player[] players, uint8 player_pos, uint sb_amount, string action, uint amount) {
        // judge payment to set status as allin
        if (is_allin(players[player_pos], action, amount)) {
            amount = players[player_pos].stack + players[player_pos].paid_sum();
        }
        // set fold for illegal action
        else if (__is_illegal(players, player_pos, sb_amount, action, amount)) {
            action = "fold";
            amount = 0;
        }
        return (action, amount);
    }

    function is_allin(Player player, string action, uint bet_amount) {
        if (action == "call") {
            if (bet_amount >= player.stack + player.paid_sum()) {
                return true;
            } else {
                return false;
            }
        }
        else if (action == "raise") {
            // pay all in stack
            if (bet_amount == player.stack + player.paid_sum()) {
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    function need_amount_for_action(Player player, uint amount) {
        // var amount is highest chip amount in this street
        return amount - player.paid_sum();
    }

    function agree_amount(Player[] players) {
        Action last_raise = __fetch_last_raise(players);
        Action last_call = __fetch_last_call(players);
        if (last_call && last_raise) {
            if (last_call.amount > last_raise.amount) {
                    return last_call.amount;
            }
        }
        return last_raise.amount;
    }

    function _is_legal(Player[] players, uint8 player_pos, uint8 sb_amount, string action, uint amount) {
        if (__is_illegal(players, player_pos, sb_amount, action, amount)) {
            return false;
        }
        return true;
    }

    function __is_illegal(Player[] players, uint8 player_pos, uint8 sb_amount, string action, uint amount) {
        if (action == "fold") {
            return false;
        }
        else if (action == "call") {
            if (__is_short_of_money(players[player_pos], amount) || __is_illegal_call(players, amount)) {
                return true;
            } else {
                return false;
            }
        }
        else if (action == "raise") {
            if (__is_short_of_money(players[player_pos], amount) || __is_illegal_raise(players, amount, sb_amount)) {
                return true;
            } else {
                return false;
            }
        }
    }

    function __is_illegal_call(Player[] players, uint amount) {
        // amount mismatch
        if (amount != agree_amount(players)) {
            return true;
        }
        return false;
    }

    function __is_illegal_raise(Player[] players, uint amount, uint sb_amount) {
        // raise amount is less than min limit
        if (__min_raise_amount(players, sb_amount) > amount) {
            return true;
        }
        return false;
    }

    function __min_raise_amount(Player[] players, uint sb_amount) {
        Action raise_ = __fetch_last_raise(players);
        if (raise_) {
            return (raise_.amount + raise_.add_amount);
        }
        return sb_amount * 2;
    }

    function __is_short_of_money(Player[] players, uint amount) {
        if (player.stack < amount - player.paid_sum()) {
            return true;
        }
        return false;
    }
}
