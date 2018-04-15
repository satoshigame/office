import "hand_evaluator.sol";
import "pay_info.sol";
import "card.sol";
import "table.sol";

contract Pot {
    uint public amount;
    Plyer public eligibles; 
}

contract PlayerScore {
    Player public player;
    uint public score;
}

contract GameEvaluator {

    // strength judgement include main pot and side pots, hand info is used to display 
    function judge(Table table) {
        Player[] winners = __find_winners_from(table.get_community_card(), table.seats.players);
        HandInfo hand_info = __gen_hand_info_if_needed(table.seats.players, table.get_community_card());
        PM prize_map = __calc_prize_distribution(table.get_community_card(), table.seats.players);
        return (winners, hand_info, prize_map);
    }

    // get all pot
    function create_pot(Player[] players) {
        Pot[] res = __get_side_pots(players);
        res.push(__get_main_pot(players, side_pots));
        return res;
    }

    // split prize into pots, get prize distribution in each pot and merge
    function __calc_prize_distribution(Card[] community_card, Player[] players) {
        mapping (uint => uint) prize_map = __create_prize_map(players.length);
        Pot[] pots = create_pot(players);
        for (uint i = 0; i < pots.length; i++) {
            Plyer[] winners = __find_winners_from(community_card, pot.eligibles);
            uint prize = pot.amount / winners.length;
            // merge prize for each player
            for (uint j = 0; j < winners.length; j++) {
                prize_map[players.index(winner)] += prize;
            }
        }
        return prize_map;
    }

    function __create_prize_map(uint player_num) {
        mapping (uint => uint) res;
        for (uint i = 0; i < player_num; i++) {
            res[i] = 0;
        }
        return res;
    }

    // calculate score for each play 
    function __find_winners_from(Card[] community_card, Player[] players) {
        Player[] winners;

        PlayerScore[] player_score;
        uint best_score = 0;
        for (uint i = 0; i < players.length; i++) {
            if (!players[i].is_active()) {
                continue;
            }
            uint score = HandEvaluator.eval_hand(players[i].hole_card, community_card);
            if (score > best_score) {
                best_score = score;
            }
            PlayerScore ps;
            ps.player = players[i];
            ps.score = score;
            player_score.push(ps);
        }

        for (i = 0; i < player_score.length; i++) {
            if (player_score[i].score == best_score) {
                winners.push(player_score[i].player);
            }
        }
        return winners;
    }

    function __gen_hand_info_if_needed(Player[] players, Card[] community) {
        HandInfo[] res;
        for (uint i = 0; i < players.length; i++) {
            if (players[i].is_active()) {
                HandInfo hand_info;
                hand_info.uuid = players[i].uuid;
                hand_info.hand = HandEvaluator.gen_hand_rank_info(players[i].hole_card, community);
                res.push(hand_info);
            }
        }
        return res;
    }

    function __get_main_pot(Player[] players, Pot[] sidepots) {
        uint max_pay = 0;
        PayInfo[] infos = __get_payinfo(players);
        for (uint i = 0; i < infos.length; i++) {
            if (infos[i] > max_pay) {
                max_pay = infos[i];
            }
        }
        Pot res;
        res.amount = __get_players_pay_sum(players) - __get_sidepots_sum(sidepots);
        for (uint j = 0; j < players.length; j++) {
            if (players[j].pay_info.amount == max_pay) {
                res.eligibles.push(players[j]);
            }
        }
        return res;
    }

    function __get_players_pay_sum(Player[] players) {
        uint sum = 0;
        for (uint i = 0; i < players.length; i++) {
            sum += __get_payinfo(players[i]).amount;
        }
        return sum;
    }

    function __get_side_pots(Player[] players) {
        PayInfo[] infos = __fetch_allin_payinfo(players);
        uint[] pay_amounts;
        for (uint i = 0; i < infos.length; i++) {
            pay_amounts.push(infos[i].amount);
        }

        Pot[] pots;
        for (uint j = 0; j < infos.length; i++) {
            pots.push(__create_sidepot(players, sidepots, allin_amount));
        }
        return pots;
    }

    function __create_sidepot(Player[] players, Pot[] smaller_side_pots, uint allin_amount) {
        Pot res;
        res.amount = __calc_sidepot_size(players, smaller_side_pots, allin_amount);
        res.eligibles = __select_eligibles(players, allin_amount);
        return res;
    }

    function __calc_sidepot_size(Player[] players, Pot[] smaller_side_pots, uint allin_amount) {
        uint add_chip_for_pot = 0;
        for (uint i = 0; i < players.length; i++) {
            if (allin_amount > players[i].pay_info.amount) {
                add_chip_for_pot += players[i].pay_info.amount;
            } else {
                add_chip_for_pot += allin_amount;
            }
        }
        uint target_pot_size = 0;
        for (uint k = 0; k < players.length; k++) {
            target_pot_size += add_chip_for_pot(players[k]);
        }
        return target_pot_size - __get_sidepots_sum(smaller_side_pots);
    }

    function __get_sidepots_sum(Pot[] sidepots) {
        uint res = 0;
        for (uint i = 0; i < sidepots.length; i++) {
            res += sidepots[i].amount;
        }
        return res;
    }

    function __select_eligibles(Player[] players, uint allin_amount) {
        Player[] res;
        for (uint i = 0; i < players.length; i++) {
            res.push(__is_eligible(players[i], allin_amount));
        }
        return res;
    }

    function __is_eligible(Player[] player, uint allin_amount) {
        if (player.pay_info.amount >= allin_amount && (player.pay_info.status == PayInfo.FOLDED || player.pay_info.status == PayInfo.WATCH)) {
            return true;
        }
        return false;
    }

    function __fetch_allin_payinfo(Player[] players) {
        PayInfo[] payinfo = __get_payinfo(players);
        PayInfo[] allin_info;
        for (uint i = 0; i < payinfo.length; i++) {
            if (payinfo[i].status == PayInfo.ALLIN) {
                allin_info.push(payinfo[i]);
            }
        }
        return allin_info;
    }

    function __get_payinfo(Player[] players) {
        PayInfo[] res;
        for (uint i = 0; i < players.length; i++) {
            res.push(players[i].pay_info);
        }
        return res;
    }
}
