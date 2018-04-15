import "pay_info.sol";
import "poker_constants.sol";
import "game_evaluator.sol";

// parse data for c-s 
contract DataEncoder {
    string public PAY_INFO_PAY_TILL_END_STR;
    string public PAY_INFO_ALLIN_STR;
    string public PAY_INFO_FOLDED_STR;
    string public PAY_INFO_WATCH_STR;

    struct Hash {
        string name;
        string uuid;
        uint stack;
        string head_img;
        string state;
    }

    function DataEncoder() {
        PAY_INFO_PAY_TILL_END_STR = "participating";
        PAY_INFO_ALLIN_STR = "allin";
        PAY_INFO_FOLDED_STR = "folded";
        PAY_INFO_WATCH_STR = "watching";
    }

    function encode_player(Player player) {
        Hash[] hashs;
        for (uint i = 0; i < player.hole_card.length; i++) {
            Hash hash;
            hash.name = player.name;
            hash.uuid = player.uuid;
            hash.stack = player.stack;
            hash.head_img = player.head_img;
            hash.state = payinfo_to_str(player.pay_info.status);
            hashs.push(hash);
        }
        return hashs;
    }

    function encode_seats(Seat[] seats) {
        string[] res;
        for (uint i = 0; i < seats.players.length; i++) {
            res.push(encode_player(seats.players[i]));
        }
        return res;
    }


    function payinfo_to_str(string status) {
        if (status == PayInfo.PAY_TILL_END) {
            return PAY_INFO_PAY_TILL_END_STR;
        }
        if (status == PayInfo.ALLIN) {
            return PAY_INFO_ALLIN_STR;
        }
        if (status == PayInfo.FOLDED) {
            return PAY_INFO_FOLDED_STR;
        }
        if (status == PayInfo.WATCH) {
            return PAY_INFO_WATCH_STR;
        }
    }

    function __street_to_str(uint street) {
        if (street == Const.Street.PREFLOP) {
            return "preflop";
        }
        if (street == Const.Street.FLOP) {
            return "flop";
        }
        if (street == Const.Street.TURN) {
            return "turn";
        }
        if (street == Const.Street.RIVER) {
            return "river";
        }
        if (street == Const.Street.SHOWDOWN) {
            return "showdown";
        }
    }

    function __encode_players(Player[] players) {
        Hash[][] res;
        for (uint i = 0; i < players.length; i++) {
            res.push(encode_player(players[i]));
        }
        return res;
    }
}
