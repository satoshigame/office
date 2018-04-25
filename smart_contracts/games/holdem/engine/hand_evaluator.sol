import "engine/seats.sol";
import "engine/player.sol";
import "engine/table.sol";
import "engine/round_manager.sol";


contract HandEvaluator {
    uint public HIGHCARD; 
    uint public ONEPAIR;
    uint public TWOPAIR;         
    uint public THREECARD;         
    uint public STRAIGHT;        
    uint public FLASH;             
    uint public FULLHOUSE;         
    uint public FOURCARD;          
    uint public STRAIGHTFLASH; 
    uint public ROYALSTRAIGHTFLASH;
    mapping (string => string) HAND_STRENGTH_MAP;

 // Return Format
 // [9 bits of type score][20 bits (4bit*5) of rank score]
 // ex.)
 //       HighCard            of K,Q,J,T,8 => 000000000 1101 1100 1011 1010 1000
 //       OnePair             of K,K,Q,J,T => 000000001 0000 1101 1100 1011 1010
 //       TwoPair             of K,K,Q,Q,J => 000000010 0000 0000 1101 1100 1011
 //       ThreeCard           of K,K,K,Q,J => 000000100 0000 0000 1101 1100 1011
 //       Straight            of A,K,Q,J,T => 000001000 0000 0000 0000 0000 1110
 //       Flush               of K,Q,J,T,8 => 000010000 1101 1100 1011 1010 1000
 //       FullHouse           of K,K,K,Q,Q => 000100000 0000 0000 0000 1101 1100
 //       FourCard            of K,K,K,K,Q => 001000000 0000 0000 0000 1101 1100
 //       StraightFlush       of K,Q,J,T,9 => 010000000 0000 0000 0000 0000 1101
 //       RoyalStraightFlush  of A,K,Q,J,T => 100000000 0000 0000 0000 0000 1110
  
    function HandEvaluator() {
        // bitmap for ez compare
        HIGHCARD           = 0;	
        ONEPAIR            = 1 << 20;	
        TWOPAIR            = 1 << 21;	
        THREECARD          = 1 << 22;	
        STRAIGHT           = 1 << 23;	
        FLASH              = 1 << 24;	
        FULLHOUSE          = 1 << 25;	
        FOURCARD           = 1 << 26;	
        STRAIGHTFLASH      = 1 << 27;	 
        ROYALSTRAIGHTFLASH = 1 << 28;

        HAND_STRENGTH_MAP["HIGHCARD"] = "HighCard";
        HAND_STRENGTH_MAP["ONEPAIR"] = "OnePair";
        HAND_STRENGTH_MAP["TWOPAIR"] = "TwoPair";
        HAND_STRENGTH_MAP["THREECARD"] = "ThreeCard";
        HAND_STRENGTH_MAP["STRAIGHT"] = "Straight";
        HAND_STRENGTH_MAP["FLASH"] = "Flush";
        HAND_STRENGTH_MAP["FULLHOUSE"] = "FullHouse";
        HAND_STRENGTH_MAP["FOURCARD"] = "FourCard";
        HAND_STRENGTH_MAP["STRAIGHTFLASH"] = "StraightFlush";
        HAND_STRENGTH_MAP["ROYALSTRAIGHTFLASH"] = "RoyalStraightFlush";
    }

    // get strangth with detail info of hand card and hole card
    function gen_hand_rank_info(Card[] hole, Card[] community) {
        uint hand_flg = eval_hand(hole, community);
        string row_strength = __mask_hand_strength(hand_flg);
        string strength = HAND_STRENGTH_MAP[row_strength];
        uint hand_high = __mask_hand_high_rank(hand_flg);
        uint hand_low = __mask_hand_low_rank(hand_flg);

        uint hole_flg = __eval_holecard(hole);
        uint hole_high = __mask_hole_high_rank(hole_flg);
        uint hole_low = __mask_hole_low_rank(hole_flg);

        RankInfo res;
        res.hand.strength = strength;
        // for case that strength equal
        res.hand.high = hand_high;
        res.hand.low = hand_low;
        res.hole.high = hole_high;
        res.hole.low = hole_low;

        return res;
    }

    function eval_hand(Card[] hole, Card[] community) {
        return __calc_hand_info_flg(hole, community);
    }

    function __calc_hand_info_flg(Card[] hole, Card[] community) {
        Card[] cards = hole;
        return __eval_highcard(cards);
    }

    function __eval_holecard(Card[] hole) {
        uint[] ranks;
        for (uint i = 0; i < hole.length; i++) {
            ranks.push(hole[i].rank);
        }
        return __calculate_score(ranks);
    }

    function __eval_highcard(Card[] cards) {
        uint[] ranks;
        // merge and cards and community cards
        for (uint i = 0; i < 5; i++) {
            ranks.push(hole[i].rank);
        }
        return __calculate_score(ranks);
    }

    // judgement for each strength
    function __is_onepair(Card[] cards) {
        if (__search_onepair(cards) != 0) {
            return true;
        }
        return false;
    }

    function __eval_onepair(Card[] cards) {
        return __search_onepair(cards);
    }

    function __search_onepair(Card[] cards) {
        uint result = 0;
        uint rank = 0;
        uint memo = 0;
        for (uint i = 0; i < cards.length; i++) {
            uint mask = 1 << cards[i].rank;
            if (memo & mask != 0) {
                rank = cards[i].rank;
                Card[] lefts;
                for (uint j = 0; j < cards.length; j++) { 
                    if (cards[j].rank != rank) {
                        lefts.push(cards[j].rank);
                    }
                }
                result = __calculate_score(ranks);
                break;
            }
            memo |= mask;
        }
        return result;
    }

    function __is_twopair(Card[] cards) {
        if (__search_twopair(cards) != 0) {
            return true;
        }
        return false;
    }

    function __eval_twopair(Card[] cards) {
        return __search_twopair(cards);
    }

    function __search_twopair(Card[] cards) {
        uint result = 0;
        uint[] ranks;
        uint memo = 0;
        for (uint i = 0; i < cards.length; j++) { 
            mask = 1 << cards[i].rank;
            if (memo & mask != 0) {
                ranks.push(cards[i].rank);
            }
            memo |= mask;
        }
        result = __calculate_score(ranks);
        return result;
    }

    function __is_threecard(Card[] cards) {
        if (__search_threecard(cards) != 0) {
            return true;
        }
        return false;
    }

    function __eval_threecard(Card[] cards) {
        return __search_threecard(cards);
    }

    function __search_threecard(Card[] cards) {
        uint result = 0;
        uint[] ranks_count;
        for (uint i = 0; i < cards.length; j++) { 
            ranks_count[card.rank] += 1;
        }
        result = __calculate_score(ranks_count);
        return result;
    }

    function __is_straight(Card[] cards) {
        if (__search_straight(cards) != 0) {
            return true;
        }
        return false;
    }

    function __eval_straight(Card[] cards) {
        return __search_straight(cards);
    }

    function __search_straight(Card[] cards) {
        uint[] ranks;
        for (uint i = 0; i < cards.length; i++) {
            ranks.push(cards[i].rank);
        }
        uint rank = straight_check(ranks);
        return rank;
    }

    function __is_flash(Card[] cards) {
        if (__search_flash(cards) != 0) {
            return true;
        }
        return false;
    }

    function __eval_flash(Card[] cards) {
        return __search_flash(cards);
    }

    function __search_flash(Card[] cards) {
        uint result = 0;
        bool get = false;
        mapping (int => int) fetch_suit;
        for (uint i = 0; i < cards.length; i++) {
            fetch_suit[cards[i].suit] += 1;
            if (fetch_suit[cards[i].suit] >= 5) {
                get = true;
            }
        }
        if (get) {
            result = __calculate_score(cards);
        }
        return result;
    }

    function __is_fullhouse(Card[] cards) {
        if (__search_fullhouse(cards) != 0) {
            return true;
        }
        return false;
    }

    function __eval_fullhouse(Card[] cards) {
        return __search_fullhouse(cards);
    }

    function __search_fullhouse(Card[] cards) {
        uint result = 0;
        uint[] three_card_ranks;
        uint[] two_pair_ranks;
        uint[] fetch_rank;
        mapping (int => int) rank_count;
        uint get_2 = 0;
        uint get_3 = 0;
        for (uint i = 0; i < cards.length; i++) {
            fetch_rank.push(cards[i].rank);
            rank_count[cards[i].rank] += 1;
            if (rank_count[cards[i].rank] == 2) {
                get_2 += 1;
            } 
            else if (rank_count[cards[i].rank] == 3) {
                get_3 += 1;
            }
        }
        if (get_2 == 2 && get_3 == 1) {
            result = __calculate_score(cards);
        }
        return result;
    }

    function __is_fourcard(Card[] cards) {
        if (__search_fourcard(cards) != 0) {
            return true;
        }
        return false;
    }

    function __eval_fourcard(cards) {
        return __search_fourcard(cards);
    }

    function __search_fourcard(Card[] cards) {
        uint result = 0;
        uint[] fetch_rank;
        bool get = false;
        mapping (int => int) rank_count;
        for (uint i = 0; i < cards.length; i++) {
            fetch_rank.push(cards[i].rank);
            rank_count[cards[i].rank] += 1;
            if (rank_count[cards[i].rank] == 4) {
                get = true;
            } 
        }
        if (get) {
            result = __calculate_score(cards);
        }
        return result;
    }

    function __is_straightflash(Card[] cards) {
        if (__search_straightflash(cards) != 0) {
            return true;
        }
        return false;
    }

    function __eval_straightflash(Card[] cards) {
        return __search_straightflash(cards);
    }

    function __search_straightflash(Card[] cards) {
        uint result = 0;
        uint[] fetch_rank;
        bool get = false;
        mapping (int => int) rank_count;
        for (uint i = 0; i < cards.length; i++) {
            fetch_rank.push(cards[i].rank);
            rank_count[cards[i].rank] += 1;
            if (rank_count[cards[i].rank] == 5) {
                get = true;
            } 
        }
        if (get) {
            result = __calculate_score(cards);
        }
        return result;
    }

    function __is_royalstraightflash(Card[] cards) {
        if (__search_royalstraightflash(cards) != 0) {
            return true;
        }
        return false;
    }

    function __eval_royalstraightflash(Card[] cards) {
        return __search_royalstraightflash(cards);
    }

    function __search_royalstraightflash(Card[] cards) {
        uint result = __search_straightflash(cards);
        if (result == 14) {
            return result;
        }
        return 0;
    }

    function __mask_hand_strength(uint bit) {
        uint mask = ((1 << 9) - 1) << 20;
        return (bit & mask);
    }

    function __mask_hand_high_rank(uint bit) {
        uint mask = ((1 << 20) - 1);
        return (bit & mask);
    }

    function __mask_hand_low_rank(uint bit) {
        uint mask = 0;
        return (bit & mask);
    }
        
    function __mask_hole_high_rank(uint bit) {
        uint mask = ((1 << 4) - 1) << 4;
        return (bit & mask) >> 4;
    }

    function __mask_hole_low_rank(uint bit) {
        uint mask = ((1 << 4) - 1);
        return (bit & mask);
    }

    function __calculate_score(uint[] ranks) {
        uint result = 0;
        for (uint i = 0; i < ranks.length; i++) {
            result |= ranks[i] << (4 * i);
        }
        return result;
    }
}
