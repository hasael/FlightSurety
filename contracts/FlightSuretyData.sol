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
    address private authorizedCaller;
    bool private operational = true; // Blocks all state changes throughout the contract if false
    // Flight status codees
    mapping(address => uint256) private usersBalance;
    mapping(address => uint256) private airlineFunds;
    //map of insurance keys to all users who have acquired it
    mapping(bytes32 => Insurance[]) private insuranceUsers;
    mapping(bytes32 => Flight) private flights;
    mapping(bytes32 => Airline) private registeredAirlines;
    mapping(string => address) private airlinesNamestoAddress;
    mapping(bytes32 => uint128) private airlineRegisterVotes;
    mapping(bytes32 => bool) private airlineRegisterVotesHistory;
    FlightStatusCodes.FlightInfo[] private flightLists;
    uint128 private airlineCount;

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
        bool hasPaidFunds;
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
        authorizedCaller = msg.sender;
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
    modifier requireAuthorizedCaller() {
        require(
            msg.sender == authorizedCaller,
            "Caller is not authorized"
        );
        _; // All modifiers require an "_" which indicates where the function body will be added
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

    function authorizeCaller(address caller) external requireContractOwner {
        authorizedCaller = caller;
    }

    function addAirlineRegisterVote(address airline, address requester)
        external
        requireAuthorizedCaller
    {
        bytes32 key = getAirlineKey(airline);
        bytes32 voteHistoryKey = keccak256(
            abi.encodePacked(airline, requester)
        );
        airlineRegisterVotes[key] = airlineRegisterVotes[key] + 1;
        airlineRegisterVotesHistory[voteHistoryKey] = true;
    }

    function hasAlreadyVoted(address airline, address requester)
        external
        view
        requireAuthorizedCaller
        returns (bool)
    {
        bytes32 voteHistoryKey = keccak256(
            abi.encodePacked(airline, requester)
        );
        return airlineRegisterVotesHistory[voteHistoryKey];
    }

    function getAirlineRegisterVote(address airline)
        external
        view
        requireAuthorizedCaller
        returns (uint128)
    {
        bytes32 key = getAirlineKey(airline);
        return airlineRegisterVotes[key];
    }

    function getAirlineCount() external view returns (uint128) {
        return airlineCount;
    }

    function addAirline(address airline, string memory name) internal {
        bytes32 key = getAirlineKey(airline);
        registeredAirlines[key] = Airline(airline, name, false);
        airlinesNamestoAddress[name] = airline;
    }

    function isAirlineRegistered(address airline)
        external
        view
        requireAuthorizedCaller
        returns (bool)
    {
        bytes32 key = getAirlineKey(airline);
        return registeredAirlines[key].airlineAddress != address(0);
    }

    function isAirlineFunded(address airline)
        external
        view
        requireAuthorizedCaller
        returns (bool)
    {
        bytes32 key = getAirlineKey(airline);
        return
            registeredAirlines[key].airlineAddress != address(0) &&
            registeredAirlines[key].hasPaidFunds == true;
    }

    function setAirlineAsFunded(address airline)
        external
        requireAuthorizedCaller
    {
        setAirlineAsFundedInternal(airline);
    }

    function setAirlineAsFundedInternal(address airline) internal {
        bytes32 key = getAirlineKey(airline);
        Airline memory foundAirline = registeredAirlines[key];
        registeredAirlines[key] = Airline(airline, foundAirline.name, true);
        airlineCount++;
    }

    function airlineAddressFromName(string calldata name)
        external
        view
        requireAuthorizedCaller
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
    ) external requireAuthorizedCaller {
        // Generate a unique key for storing the flight
        bytes32 key = getFlightKey(flightAirline, flight);
        flights[key].isRegistered = true;
        flights[key].statusCode = FlightStatusCodes.STATUS_CODE_UNKNOWN;
        flights[key].updatedTimestamp = timestamp;
        flights[key].airline = flightAirline;

        bytes32 airlineKey = getAirlineKey(flightAirline);
        flightLists.push(
            FlightStatusCodes.FlightInfo(
                flight,
                registeredAirlines[airlineKey].name
            )
        );
    }

    function updateFlightStatus(
        address airline,
        string calldata flight,
        uint256 timestamp,
        uint8 statusCode
    ) external requireAuthorizedCaller {
        bytes32 key = getFlightKey(airline, flight);
        flights[key].statusCode = statusCode;
        flights[key].updatedTimestamp = timestamp;
    }

    function getFlight(address airline, string calldata flight)
        external
        view
        requireAuthorizedCaller
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

    function getFlightsList()
        external
        view
        requireAuthorizedCaller
        returns (FlightStatusCodes.FlightInfo[] memory)
    {
        return flightLists;
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
    ) external requireAuthorizedCaller {
        bytes32 key = getInsuranceKey(airline, flight);
        insuranceUsers[key].push(Insurance(user, amount, 0));
    }

    /**
     *  @dev Credits payouts to insurees
     */
    function creditInsurees(address airline, string calldata flight)
        external
        requireAuthorizedCaller
    {
        bytes32 key = getInsuranceKey(airline, flight);
        Insurance[] memory userInsurances = insuranceUsers[key];

        for (uint256 i = 0; i < userInsurances.length; i++) {
            address insuranceUser = userInsurances[i].user;
            uint256 reimbursedAmount = userInsurances[i].reimbursedAmount;
            uint256 insuranceAmount = userInsurances[i].paidAmount;
            if (reimbursedAmount == 0) {
                uint256 credit = (insuranceAmount * 3) / 2;
     
                usersBalance[insuranceUser] += credit;
                insuranceUsers[key][i] = Insurance(insuranceUser, insuranceAmount, credit);
            }
        }
    }

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
     */
    function withdrawUserBalance(uint256 amount, address user)
        external
        requireAuthorizedCaller
    {
        require(
            amount <= usersBalance[user],
            "Requested amount higher than balance"
        );
        require(amount > 0, "Request amount should be not zero");
        usersBalance[user] = usersBalance[user] - amount;
    }

    function getUserBalance(address user)
        external
        view
        requireAuthorizedCaller
        returns (uint256 amount)
    {
        return usersBalance[user];
    }

    function addAirlineFunds(address airline, uint256 amount)
        external
        requireAuthorizedCaller
    {
        airlineFunds[airline] += amount;
    }

    function getAirlineFunds(address airline)
        external
        view
        requireAuthorizedCaller
        returns (uint256)
    {
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
