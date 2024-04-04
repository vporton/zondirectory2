import Verify "mo:passport-client-dfinity/lib/Verifier";

module {
    // Don't verify users for sybil. It's useful for a test installation running locally.
    public let skipSybil = true;

    public let configScorer: Verify.Config = {
        scorerId = 7007; // get it at https://scorer.gitcoin.co/
        scorerAPIKey = "UnbfvrpJ.AcVDV2OpDGOswClXiChDAHUTESEccSx0"; // get it at https://scorer.gitcoin.co/
        scorerUrl = "https://api.scorer.gitcoin.co";
    };
    public let minimumScore = 20.0;
}