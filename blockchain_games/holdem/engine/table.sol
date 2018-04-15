import "card.sol";
import "seats.sol";
import "deck.sol";

contract Table {
    uint public dealer_btn;
    // sb and bb
    uint[] public blind_pos;
    Seat[] public seats;
    Deck public deck;
    Card[] public community_card;

    function Table(Deck _init_deck) {
        dealer_btn = 0;
        seats = Seats();
        deck = _init_deck;
    }

    // get before game
    function setblind_pos(uint sb_pos, uint bb_pos) {
        blind_pos = [sb_pos, bb_pos];
    }

    function sb_pos() {
        return blind_pos[0];
    }

    // may not always sb * bb later
    function bb_pos() {
        return blind_pos[1];
    }

    function getcommunity_card() {
        return community_card;
    }

    function addcommunity_card(Card card) {
        community_card.push(card);
    }

    // init before game
    function reset() {
        deck.restore();
        community_card = [];
        for (uint i = 0; i < seats.players.length; i++) {
            players[i].clear_holecard();
            players[i].clear_action_histories();
            players[i].clear_pay_info();
        }
    }

    function shift_dealer_btn() {
        dealer_btn = next_active_player_pos(dealer_btn);
    }

    // user still in game
    function next_active_player_pos(uint start_pos) {
        Player[] players = seats.players;
        Player[] search_targets = players;
        for (uint i = 0; i < players.length; i++) {
            search_targets.push(players[i]);
        }
        for (uint j = start_pos; j < players.length; j++) {
            // ignore user without enouget chip that default as fold when need paid
            if (search_targets[j].is_active() && search_targets[j].stack != 0) {
                return search_targets[j];
            }
        }
        return;
    }

    // round search by pos 
    function next_ask_waiting_player_pos(uint start_pos) {
        Player[] players = seats.players;
        Player[] search_targets = players;
        for (uint i = 0; i < players.length; i++) {
            search_targets.push(players[i]);
        }
        for (uint j = start_pos; j < players.length; j++) {
            if (search_targets[j].is_waiting_ask()) {
                return search_targets[j];
            }
        }
        return;
    }
}
