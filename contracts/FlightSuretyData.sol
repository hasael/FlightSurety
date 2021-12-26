pragma solidity ^0.8.10;

import "../node_modules/openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "./FlightSuretyDataContract.sol";
import {FlightStatusCodes} from "./FlightStatusCodes.sol";

contract FlightSuretyData is FlightSuretyDataContract {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner; // Account used to deploy contract
    bool private operational = true; // Blocks all state changes throughout the contract if false
    // Flight status codees
    mapping(address => uint256) private usersBalance;
    mapping(address => uint256) private airlineFunds;
    //map of insurance keys to all users who have acquired it
    mapping(bytes32 => Insurance[]) private insuranceUsers;
    mapping(bytes32 => Flight) private flights;
    mapping(bytes32 => Airline) private registeredAirlines;
    mapping(string => address) private airlinesNamestoAddress;

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
    }

    struct Insurance {
        address user;
        uint256 paidAmount;
        uint256 reimbursedAmount;
    }

    struct Airline {
        address airlineAddress;
        string name;
    }

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    /**
     * @dev Constructor
     *      The deploying account becomes contractOwner
     */
    constructor(address firstAirline, string memory airlineName) {
        addAirline(firstAirline, airlineName);
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
    function registerAirline(address airline, string calldata name) external {
        addAirline(airline, name);
    }

    function addAirline(address airline, string memory name) internal {
        bytes32 key = getAirlineKey(airline);
        registeredAirlines[key] = Airline(airline, name);
        airlinesNamestoAddress[name] = airline;
    }

    function isAirlineRegistered(address airline) external view returns (bool) {
        bytes32 key = getAirlineKey(airline);
        return registeredAirlines[key].airlineAddress != address(0);
    }

    function airlineAddressFromName(string calldata name)
        external
        view
        returns (address)
    {
        return airlinesNamestoAddress[name];
    }

    /**
     * @dev Register a future flight for insuring.
     *
     */
    function addFlight(
        address flightAirline,
        string calldata flight,
        uint256 timestamp
    ) external {
        // Generate a unique key for storing the flight
        bytes32 key = getFlightKey(flightAirline, flight);
        flights[key].isRegistered = true;
        flights[key].statusCode = FlightStatusCodes.STATUS_CODE_UNKNOWN;
        flights[key].updatedTimestamp = timestamp;
        flights[key].airline = flightAirline;
    }

    function updateFlightStatus(
        address airline,
        string calldata flight,
        uint256 timestamp,
        uint8 statusCode
    ) external {
        bytes32 key = getFlightKey(airline, flight);
        flights[key].statusCode = statusCode;
        flights[key].updatedTimestamp = timestamp;
    }

    function getFlight(address airline, string calldata flight)
        external
        view
        returns (
            address returnAirline,
            string calldata retFlight,
            uint8 status,
            uint256 timestamp
        )
    {
        // Generate a unique key for storing the flight
        bytes32 key = getFlightKey(airline, flight);
        return (
            flights[key].airline,
            flight,
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
        address user,
        uint256 amount
    ) external {
        bytes32 key = getInsuranceKey(airline, flight);
        insuranceUsers[key].push(Insurance(user, amount, 0));
    }

    /**
     *  @dev Credits payouts to insurees
     */
    function creditInsurees(address airline, string calldata flight) external {
        bytes32 key = getInsuranceKey(airline, flight);
        Insurance[] memory userInsurances = insuranceUsers[key];

        for (uint256 i = 0; i < userInsurances.length; i++) {
            address insuranceUser = userInsurances[i].user;
            uint256 reimbursedAmount = userInsurances[i].reimbursedAmount;
            uint256 insuranceAmount = userInsurances[i].paidAmount;
            if (reimbursedAmount == 0) {
                uint256 credit = (insuranceAmount * 3) / 2;
                userInsurances[i] = Insurance(
                    insuranceUser,
                    insuranceAmount,
                    reimbursedAmount
                );
                usersBalance[insuranceUser] += credit;
            }
        }
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

    function getFlightKey(address airline, string calldata flight)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(airline, flight));
    }

    function getAirlineKey(address airline) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline));
    }

    function getInsuranceKey(address airline, string calldata flight)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(airline, flight));
    }
}
