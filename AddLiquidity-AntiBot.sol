uint256 launchedAt = 0;
uint256 botDuration = 1000;

_transfer(from, to, amount) {

    if(isAntiBotEnabled) {
        if(!launched() && _isIncludedInAntiDumping[to]) {
            launch();
            setTimer(botDuration);
        } else if(inBotTime && _isIncludedInAntiDumping[to]) {
            blacklist(from);
            transfer zero amount;
        } else {
            check if from/to is blacklisted
            if yes, revert
        }
    }

    // Rest of the stuff;

}

function launch() {
    launchedAt = 1;
}

function launched() {
    return launchedAt != 0;
}

functino launchAgain() {
    launchedAt = 0;
}