import "seats.sol";
import "card.sol";

contract Deck {
    string[] public deck;

    function Deck() {
        __setup();
    }

    // get all card list and pop when it needs
    function draw_card() {
        return deck.pop();
    }

    function size() {
        return deck.length;
    }

    function restore() {
        // init card list
        deck = __setup();
    }

    //completely random seed and long enough
    function shuffle(string seed_list, uint256[] shuffle_seq_list) {
        string[] res;
        uint amnt_to_shuffle = deck.length;

        for (uint i = 0; i < 52; i++) {
            uint randv = shuffle_seq_list[i];
            uint j = randv % amnt_to_shuffle;
            res.push(deck[j]);
            deck.pop(j);
            amnt_to_shuffle -= 1;
        }
        deck = res;
    }

    function serialize() {
        string[] res;
        for (uint i = 0; i < deck.length; i++) {
            res.push(deck[i].to_id());
        }
        return res;
    }


    function __setup() {
        return __setup_52_cards();
    }

    // get order cards
    function __setup_52_cards() {
        string[] res;
        for (uint i = 1; i < 53; i++) {
            res.push(deck[i].from_id());
        }
        return res;
    }
}


