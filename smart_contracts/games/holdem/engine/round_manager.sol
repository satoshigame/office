import "table.sol";
import "player.sol";
import "pay_info.sol";
import "poker_constants.sol";
import "action_checker.sol";
import "game_evaluator.sol";
import "message_builder.sol";


contract RoundManager {
        
    // round_count: round for a new rot
    // get seed_list and shuffle_seq_list from random system
    function start_new_round(uint round_count, uint small_blind_amount, uint ante_amount, Table table, uint[] seed_list, uint[] shuffle_seq_list, uint tax_rate) {
        State _state = __gen_initial_state(round_count, small_blind_amount, table);
        State state = __deep_copy_state(_state);
        Table table = state.table;
        // get shuffle_seed sqquence from random system every round
        table.deck.shuffle(seed_list, shuffle_seq_list);
        __correct_ante(ante_amount, table.seats.players);
        __correct_blind(small_blind_amount, table);
        __deal_holecard(table);
        __round_start_message(round_count, table);
        state = __start_street(state, tax_rate);
        return state;
    }

    // process player action
    function apply_action(State original_state, Action action, uint bet_amount, uint tax_rate) {
        State state = __deep_copy_state(original_state);
        state = __update_state_by_action(state, action, bet_amount);
        if (__is_everyone_agreed(state)) {
            state.street += 1;
            state = __start_street(state, tax_rate);
            return state;
        } else {
            state.next_player = state.table.next_ask_waiting_player_pos(state.next_player);
            uint next_player_pos = state.next_player;
            // circulate search
            Player next_player = state.table.seats.players[next_player_pos];
            return state;
        }
    }

    // usually 0 in recent version
    function __correct_ante(uint ante_amount, Player[] players) {
        if (ante_amount == 0) {
            return;
        }
        for (uint i = 0; i < players.length; i++) {
            if (players[i].is_active()) {
                players[i].collect_bet(ante_amount);
                players[i].pay_info.update_by_pay(ante_amount);
                players[i].add_action_history(Const.Action.ANTE, ante_amount);
            }
        }
    }

    function __correct_blind(uint sb_amount, Table table) {
        __blind_transaction(table.seats.players[table.sb_pos()], true, sb_amount);
        __blind_transaction(table.seats.players[table.bb_pos()], false, sb_amount);
    }

    function __blind_transaction(Player player, uint small_blind, uint sb_amount) {
        Action action = Const.Action.BIG_BLIND;
        uint blind_amount = sb_amount * 2;
        // treat small_blind as action and record in history list
        if (small_blind) {
            action = Const.Action.SMALL_BLIND;
            blind_amount = sb_amount;
        }
        player.collect_bet(blind_amount);
        player.add_action_history(action, sb_amount);
        player.pay_info.update_by_pay(blind_amount);
    }

    function __deal_holecard(Table table) {
        Deck deck = table.deck;
        Player[] players = table.seats.players;
        uint start_pos = table.dealer_btn;
        Player[] search_targets = players;
        for (uint i = 0; i < players.length; i++) {
            search_targets.push(players[i]);
        }
        for (uint j = start_pos; j < players.length; j++) {
            search_targets[j].add_holecard(deck.draw_cards(2));
        }
    }

    // process game with status struct and process function
    function __start_street(State state, uint tax_rate) {
        uint next_player_pos = state.table.next_ask_waiting_player_pos(state.table.sb_pos()-1);
        state.next_player = next_player_pos;
        uint street = state.street;
        if (street == Const.Street.PREFLOP) {
            return __preflop(state, tax_rate);
        }
        else if (street == Const.Street.FLOP) {
            return __flop(state, tax_rate);
        }
        else if (street == Const.Street.TURN) {
            return __turn(state, tax_rate);
        }
        else if (street == Const.Street.RIVER) {
            return __river(state, tax_rate);
        }
        else if (street == Const.Street.SHOWDOWN) {
            // for payment settlement
            return __showdown(state, tax_rate);
        }
        else {
            return;
        }
    }

    function __preflop(State state, uint tax_rate) {
        for (uint i = 0; i < 2; i++) {
            state.next_player = state.table.next_ask_waiting_player_pos(state.next_player);
        }
        return __forward_street(state, tax_rate);
    }

    function __flop(State state, uint tax_rate) {
        for (uint i = 0; i < state.table.deck.draw_cards(6).length; i++) {
            if (i % 2 == 1) {
                // get first three community card
                state.table.add_community_card(card);
            }
        }
        return __forward_street(state, tax_rate);
    }

    function __turn(State state, uint tax_rate) {
        state.table.add_community_card(state.table.deck.draw_cards(2)[1]);
        return __forward_street(state, tax_rate);
    }

    function __river(State state, uint tax_rate) {
        state.table.add_community_card(state.table.deck.draw_cards(2)[1]);
        return __forward_street(state, tax_rate);
    }

    // message info for display in web page
    function __round_result_message(uint round_count, Player[] winners, HandInfo hand_info, State state) {
        Player[] players = state.table.seats.players;
        return MessageBuilder.build_round_result_message(round_count, winners, hand_info, state, players);
    }

    function __showdown(State state, uint tax_rate) {
        // for strength compare
        Player[] winners = GameEvaluator.judge(state.table)[0];
        HandInfo hand_info = GameEvaluator.judge(state.table)[1];
        // get user-prize map
        PM prize_map = GameEvaluator.judge(state.table)[2];
        Player[] players = state.table.seats.players;
        // add prize value to player's stack
        AccountInfo account_info = __prize_to_winners(players, prize_map, tax_rate);
        state.street += 1;
        state.account_info = account_info;
        return state;
    }

    // get player base stack, final stack, diff and tax info
    function __prize_to_winners(Player[] players, PM prize_map, uint tax_rate) {
        PW res;
        Account[] account_list;
        uint winner_gain = 0;
        uint all_tax = 0;

        // chips in stack right now is not base for a player
        for (uint i = 0; i < prize_map.length; i++) {
            uint uuid = players[i].uuid;
            uint stack_base = players[i].base_stack;
            uint stack_final = players[i].stack + prize;
            int diff = stack_final - stack_base;

            uint tax = 0;
            if (!(tax_rate > 0 && tax_rate <= 1)) {
                tax_rate = 0;
            }

            if (diff > 0) {
                tax = diff * tax_rate / 1000;
            }

            int checked_diff = diff - tax;
            if (checked_diff > 0) {
                winner_gain += checked_diff;
            }

            stack_final = stack_base + checked_diff;
            all_tax += tax;

            players[i].append_chip(prize - tax);
            account_list.push(Account(stack_base, stack_final, checked_diff, tax));
        }

        res.all_tax = all_tax;
        res.account_list = account_list;
        res.winner_gain = winner_gain;
        return res;
    }

    function __round_start_message(uint round_count, Table table) {
        Player[] players = table.seats.players;
        // build message for display
        Message gen_msg = MessageBuilder.build_round_start_message(round_count, table.seats);
        return gen_msg;
    }

    function __forward_street(State state, uint tax_rate) {
        Table table = state.table;
        //Message street_start_msg = MessageBuilder.build_street_start_message(state);
        
        if (table.seats.count_ask_wait_players() <= 1) {
            state.street += 1;
            state = __start_street(state, tax_rate);
            return state;
        }
        return state;
    }

    function __update_state_by_action(State state, string action, uint bet_amount) {
        Table table = state.table;
        Action act = ActionChecker.correct_action(table.seats.players, state.next_player, state.small_blind_amount, action, bet_amount);
        action = act.action;
        bet_amount = act.amount;
        Player next_player = table.seats.players[state.next_player];
        if (ActionChecker.is_allin(next_player, action, bet_amount)) {
            next_player.pay_info.update_to_allin();
        }
        return __accept_action(state, action, bet_amount);
    }

    // action check
    function __accept_action(State state, string action, uint bet_amount) {
        Player player = state.table.seats.players[state.next_player];
        if (action == "call") {
            __chip_transaction(player, bet_amount);
            player.add_action_history(Const.Action.CALL, bet_amount);
        }
        else if (action == "raise") {
            __chip_transaction(player, bet_amount);
            int add_amount = bet_amount - ActionChecker.agree_amount(state.table.seats.players);
            player.add_action_history(Const.Action.RAISE, bet_amount, add_amount);
        }
        else if (action == "fold") {
            player.add_action_history(Const.Action.FOLD);
            player.pay_info.update_to_fold();
        }
        else {
            return;
        }
        return state;
    }

    function __chip_transaction(Player player, uint bet_amount) {
        uint need_amount = ActionChecker.need_amount_for_action(player, bet_amount);
        player.collect_bet(need_amount);
        player.pay_info.update_by_pay(need_amount);
    }

    function __update_message(State state, Action action, uint bet_amount, bool street_last_message) {
        if (street_last_message) {
            state.next_player = -1;
        }
        else {
            state.next_player = state.table.next_ask_waiting_player_pos(next_player_state.next_player);
        }
        return MessageBuilder.build_game_update_message(state.next_player, action, bet_amount, next_player_state);
    }

    // condition to start next street
    function __is_everyone_agreed(State state) {
        __agree_logic_bug_catch(state);
        Player[] players = state.table.seats.players;
        uint next_player_pos = state.table.next_ask_waiting_player_pos(state.next_player);
        Player next_player = players[next_player_pos];
        uint max_pay = 0;
        for (uint i = 0; i < players.length; i++) {
            if (max_pay < players[i].paid_sum()) {
                max_pay = players[i].paid_sum();
            }
        }
        bool everyone_agreed = false;
        uint count = 0;
        for (uint j = 0; j < players.length; j++) {
            if (__is_agreed(max_pay, players[j])) {
                count += 1;
            }
        }
        if (count == players.length) {
            everyone_agreed = true;
        }
        
        bool lonely_player = state.table.seats.count_active_players() == 1;
        bool no_need_to_ask = state.table.seats.count_ask_wait_players() == 1 && next_player && next_player.is_waiting_ask() && next_player.paid_sum() == max_pay;
        return everyone_agreed || lonely_player || no_need_to_ask;
    }

    function __is_agreed(uint max_pay, Player player) {
        bool is_preflop = player.round_action_histories.length == 0;
        bool bb_ask_once = player.action_histories == 1 && player.action_histories[0].action == Player.ACTION_BIG_BLIND;
        bool bb_ask_check = !is_preflop || !bb_ask_once;
        // judging condition
        return (bb_ask_check && player.paid_sum() == max_pay && player.action_histories.length != 0) || (player.pay_info.status == PayInfo.FOLDED || player.pay_info.status == PayInfo.ALLIN || player.pay_info.status == PayInfo.WATCH);
    }
}
