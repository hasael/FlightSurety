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

    function creditInsurees(
        address airline,
        string calldata flight,
        uint256 credit
    ) external;

    function addUserInsurance(
        string calldata flight,
        address airline,
        address user
    ) external;

    function getFlight(address airline, string calldata flight)
        external
        view
        returns (
            address returnAirline,
            string calldata retFlight,
            uint8 status,
            uint256 timestamp
        );

    function registerAirline(address airline) external;

    function isAirlineRegistered(address airline) external view returns (bool);
}
