import {FlightStatusCodes} from "./FlightStatusCodes.sol";

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

    function creditInsurees(address airline, string calldata flight) external;

    function addUserInsurance(
        string calldata flight,
        address airline,
        address user,
        uint256 amount
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

    function registerAirline(address airline, string calldata name) external;

    function airlineAddressFromName(string calldata name)
        external
        view
        returns (address);

    function isAirlineRegistered(address airline) external view returns (bool);

    function addAirlineRegisterVote(address airline, address requester)
        external;

    function getAirlineRegisterVote(address airline)
        external
        view
        returns (uint128);

    function getAirlineCount() external view returns (uint128);

    function hasAlreadyVoted(address airline, address requester)
        external
        view
        returns (bool);

    function isAirlineFunded(address airline) external view returns (bool);

    function setAirlineAsFunded(address airline) external;

    function getFlightsList()
        external
        view
        returns (FlightStatusCodes.FlightInfo[] memory);

    function withdrawUserBalance(uint256 amount) external;

    function getUserBalance() external view returns (uint256 amount);
}
