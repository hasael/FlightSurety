interface FlightSuretyDataContract {
    function addFlight(
        address airline,
        string memory flight,
        uint256 timestamp
    ) external;

    function updateFlightStatus(
        address airline,
        string calldata flight,
        uint256 timestamp,
        uint8 statusCode
    ) external;
}
