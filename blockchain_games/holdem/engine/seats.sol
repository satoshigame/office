
import "player.sol";
import "pay_info.sol";

// describe pos info for each player
contract Seats {
    // player that participate in the game
    Player[] public players;

    function Seats() {
        ;
    }

    // from auditorium to seat
    function sitdown(Player player) {
        players.push(player);
    }

    function size() {
        return players.length;
    }

    // still in game and not fold
    function count_active_players() {
        Player[] active_players;
        for (uint i = 0; i < players.length; i++) {
            if (players[i].is_active()) {
                active_players.push(players[i]);
            }
        }
        return active_players.length;
    }

    function count_ask_wait_players() {
        Player[] wait_players;
        for (uint i = 0; i < players.length; i++) {
            if (players[i].is_active()) {
                wait_players.push(players[i]);
            }
        }
        return wait_players.length;
    }
}
