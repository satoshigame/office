contract PokerConstants {

    enum Action {
        ANTE,           //0
        SMALL_BLIND,
        BIG_BLIND,
        FOLD,
        CHECK,
        CALL,
        BET,
        RAISE
    }

    enum Street {
        PREFLOP,
        FLOP,
        TURN,
        RIVER,
        SHOWDOWN,
        FINISHED
    }
}

