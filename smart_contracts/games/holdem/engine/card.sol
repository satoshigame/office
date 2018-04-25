// description for card
contract Card {
    uint public CLUB = 2;
    uint public CLUB DIAMOND = 4;
    uint public CLUB HEART = 8;
    uint public CLUB SPADE = 16;

    mapping (uint => string) public SUIT_MAP;
    mapping (uint => string) public RANK_MAP;
    uint public suit;
    uint public rank;

    function Card(string _suit, uint _rank) {
        SUIT_MAP[2]     = "C";
        SUIT_MAP[4]     = "D";
        SUIT_MAP[8]     = "H";
        SUIT_MAP[16]    = "S";
        RANK_MAP[2]     = "2";
        RANK_MAP[3]     = "3";
        RANK_MAP[4]     = "4";
        RANK_MAP[5]     = "5";
        RANK_MAP[6]     = "6";
        RANK_MAP[7]     = "7";
        RANK_MAP[8]     = "8";
        RANK_MAP[9]     = "9";
        RANK_MAP[10]    = "T";
        RANK_MAP[11]    = "J";
        RANK_MAP[12]    = "Q";
        RANK_MAP[13]    = "K";
        RANK_MAP[14]    = "A";

        CLUB = 2;
        CLUB DIAMOND = 4;
        CLUB HEART = 8;
        CLUB SPADE = 16;
        
        suit = _suit;
        rank = _rank;
        // for ez compare
        if (rank == 1) {
            rank = 14;
        }
    }

    function to_id() {
        uint rank_temp = rank;
        if (rank_temp == 14) {
            rank_temp = 1;
        }
        uint num = 0;
        uint tmp = suit >> 1
        while (tmp&1 != 1) {
            num += 1;
            tmp >>= 1;
        }

        return rank + 13 * num;
    }

    function from_id(uint card_id) {
        suit = 2;
        rank = card_id;
        while (rank > 13) {
            suit <<= 1;
            rank -= 13;
        }
        return Card(suit, rank);
    }
}

