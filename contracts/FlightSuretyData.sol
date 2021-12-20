pragma solidity ^0.8.10;

import "../node_modules/openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "./FlightSuretyDataContract.sol";

contract FlightSuretyData is FlightSuretyDataContract {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner; // Account used to deploy contract
    bool private operational = true; // Blocks all state changes throughout the contract if false
    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    mapping(address => uint256) private usersBalance;
    mapping(address => uint256) private airlineFunds;
    //map of insurance keys to all users who have acquired it
    mapping(bytes32 => address[]) private insuranceUsers;
    mapping(bytes32 => Flight) private flights;

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
    }

    struct Insurance {
        address airline;
        string flight;
    }

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    /**
     * @dev Constructor
     *      The deploying account becomes contractOwner
     */
    constructor() {
        contractOwner = msg.sender;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
     * @dev Modifier that requires the "operational" boolean variable to be "true"
     *      This is used on all state changing functions to pause the contract in
     *      the event there is an issue that needs to be fixed
     */
    modifier requireIsOperational() {
        require(operational, "Contract is currently not operational");
        _; // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
     * @dev Modifier that requires the "ContractOwner" account to be the function caller
     */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
     * @dev Get operating status of contract
     *
     * @return A bool that is the current operating status
     */
    function isOperational() public view returns (bool) {
        return operational;
    }

    /**
     * @dev Sets contract operations on/off
     *
     * When operational mode is disabled, all write transactions except for this one will fail
     */
    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
     * @dev Add an airline to the registration queue
     *      Can only be called from FlightSuretyApp contract
     *
     */
    function registerAirline() external pure {}

    /**
     * @dev Register a future flight for insuring.
     *
     */
    function addFlight(
        address flightAirline,
        string memory flight,
        uint256 timestamp
    ) external {
        // Generate a unique key for storing the flight
        bytes32 key = getFlightKey(flightAirline, flight, timestamp);
        flights[key].isRegistered = true;
        flights[key].statusCode = STATUS_CODE_UNKNOWN;
        flights[key].updatedTimestamp = timestamp;
        flights[key].airline = flightAirline;
    }

    function updateFlightStatus(
        address airline,
        string calldata flight,
        uint256 timestamp,
        uint8 statusCode
    ) external {
        bytes32 key = getFlightKey(airline, flight, timestamp);
        flights[key].statusCode = statusCode;
        flights[key].updatedTimestamp = timestamp;
    }

    function getFlight(
        address airline,
        string memory flight,
        uint256 timestamp
    )
        external
        view
        returns (
            address,
            string memory,
            uint8,
            uint256
        )
    {
        // Generate a unique key for storing the flight
        bytes32 key = getFlightKey(airline, flight, timestamp);
        return (
            airline,
            flight ,
            flights[key].statusCode,
            flights[key].updatedTimestamp
        );
    }

    /**
     * @dev Buy insurance for a flight
     *
     */
    function addUserInsurance(
        string calldata flight,
        address airline,
        address user
    ) external {
        bytes32 key = getInsuranceKey(airline, flight);
        insuranceUsers[key].push(user);
    }

    /**
     *  @dev Credits payouts to insurees
     */
    function creditInsurees(address user, uint256 credit) external {
        usersBalance[user] += credit;
    }

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
     */
    function pay() external pure {}

    function addAirlineFunds(address airline, uint256 amount) external {
        airlineFunds[airline] += amount;
    }

    function getAirlineFunds(address airline) external view returns (uint256) {
        return airlineFunds[airline];
    }

    function getFlightKey(
        address airline,
        string memory flight,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    function getInsuranceKey(address airline, string memory flight)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(airline, flight));
    }
}
