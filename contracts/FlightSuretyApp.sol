pragma solidity ^0.8.10;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "./FlightSuretyDataContract.sol";
import "./FlightStatusCodes.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)
    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner; // Account used to deploy contract
    bool private operational;
    FlightSuretyDataContract flightSuretyData;

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
        // Modify to call data contract's status
        require(true, "Contract is currently not operational");
        _; // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
     * @dev Modifier that requires the "ContractOwner" account to be the function caller
     */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireRegisteredAirline() {
        // Modify to call data contract's status
        require(
            flightSuretyData.isAirlineRegistered(msg.sender),
            "Only a registered airline can do this action"
        );
        _; // All modifiers require an "_" which indicates where the function body will be added
    }

    modifier requireFundedAirline() {
        // Modify to call data contract's status
        require(
            flightSuretyData.isAirlineFunded(msg.sender),
            "Only a funded airline can do this action"
        );
        _; // All modifiers require an "_" which indicates where the function body will be added
    }

    modifier notExistingAirline(address airline) {
        // Modify to call data contract's status
        require(
            !flightSuretyData.isAirlineRegistered(airline),
            "Address already registered to an airline"
        );
        _; // All modifiers require an "_" which indicates where the function body will be added
    }

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
     * @dev Contract constructor
     *
     */
    constructor(address dataContractAddress) {
        operational = true;
        contractOwner = msg.sender;
        flightSuretyData = FlightSuretyDataContract(dataContractAddress);
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() public view returns (bool) {
        return operational; // Modify to call data contract's status
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
    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
    }

    /**
     * @dev Buy insurance for a flight
     *
     */
    function buyInsurance(string calldata airlineName, string calldata flight)
        external
        payable
    {
        require(msg.value > 0 ether, "Not enough funds");
        require(msg.value <= 1 ether, "Not allowed more than 1 ether");
        address airline = flightSuretyData.airlineAddressFromName(airlineName);
        (
            address returnAirline,
            string memory retFlight,
            uint8 status,
            uint256 timestamp
        ) = flightSuretyData.getFlight(airline, flight);
        require(returnAirline != address(0), "Flight not found");

        flightSuretyData.addUserInsurance(
            flight,
            airline,
            msg.sender,
            msg.value
        );
        payable(airline).transfer(msg.value);
    }

    function fundAirline() external payable requireRegisteredAirline {
        require(msg.value == 10 ether, "10 ether required to fund an airline");
        flightSuretyData.setAirlineAsFunded(msg.sender);
    }

    /**
     * @dev Add an airline to the registration queue
     *
     */
    function registerAirline(address airline, string calldata name)
        external
        requireRegisteredAirline
        notExistingAirline(airline)
        returns (bool success, uint256 votes)
    {
        uint128 airlineCount = flightSuretyData.getAirlineCount();
        if (airlineCount < 5) {
            flightSuretyData.registerAirline(airline, name);
            return (true, 0);
        } else {
            if (!flightSuretyData.hasAlreadyVoted(airline, msg.sender)) {
                flightSuretyData.addAirlineRegisterVote(airline, msg.sender);
            }
            uint128 currentVote = flightSuretyData.getAirlineRegisterVote(
                airline
            );
            if (100 * (currentVote / airlineCount) >= 50) {
                flightSuretyData.registerAirline(airline, name);
                return (true, currentVote);
            } else {
                return (false, currentVote);
            }
        }
    }

    /**
     * @dev Register a future flight for insuring.
     *
     */
    function registerFlight(
        address airline,
        string calldata flight,
        uint256 timestamp
    ) external requireFundedAirline {
        flightSuretyData.addFlight(airline, flight, timestamp);
    }

    function getFlightsList()
        external
        view
        returns (FlightStatusCodes.FlightInfo[] memory)
    {
        return flightSuretyData.getFlightsList();
    }

    /**
     * @dev Called after oracle has updated flight status
     *
     */
    function processFlightStatus(
        address airline,
        string memory flight,
        uint256 timestamp,
        uint8 statusCode
    ) internal {
        flightSuretyData.updateFlightStatus(
            airline,
            flight,
            timestamp,
            statusCode
        );

        flightSuretyData.creditInsurees(airline, flight);
    }

    function withdrawUserBalance(uint256 amount) external {
        flightSuretyData.withdrawUserBalance(amount);
        payable(msg.sender).transfer(amount);
    }

    function getUserBalance() external view returns (uint256 amount) {
        return flightSuretyData.getUserBalance();
    }

    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus(
        string calldata airlineName,
        string memory flight,
        uint256 timestamp
    ) external {
        uint8 index = getRandomIndex(msg.sender);
        address airline = flightSuretyData.airlineAddressFromName(airlineName);
        (
            address returnAirline,
            string memory retFlight,
            uint8 status,
            uint256 retTimestamp
        ) = flightSuretyData.getFlight(airline, flight);

        require(returnAirline != address(0), "Flight not found");
        // Generate a unique key for storing the request
        bytes32 key = keccak256(
            abi.encodePacked(index, airline, flight, timestamp)
        );
        oracleResponses[key].requester = msg.sender;
        oracleResponses[key].isOpen = true;

        emit OracleRequest(index, airline, flight, timestamp);
    }

    // region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;

    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester; // Account that requested status
        bool isOpen; // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses; // Mapping key is the status code reported
        // This lets us group responses and identify
        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(
        address airline,
        string flight,
        uint256 timestamp,
        uint8 status
    );

    event OracleReport(
        address airline,
        string flight,
        uint256 timestamp,
        uint8 status
    );

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(
        uint8 index,
        address airline,
        string flight,
        uint256 timestamp
    );

    // Register an oracle with the contract
    function registerOracle() external payable {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({isRegistered: true, indexes: indexes});
    }

    function getMyIndexes() external view returns (uint8[3] memory) {
        require(
            oracles[msg.sender].isRegistered,
            "Not registered as an oracle"
        );

        return oracles[msg.sender].indexes;
    }

    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse(
        uint8 index,
        address airline,
        string memory flight,
        uint256 timestamp,
        uint8 statusCode
    ) external {
        require(
            (oracles[msg.sender].indexes[0] == index) ||
                (oracles[msg.sender].indexes[1] == index) ||
                (oracles[msg.sender].indexes[2] == index),
            "Index does not match oracle request"
        );

        bytes32 key = keccak256(
            abi.encodePacked(index, airline, flight, timestamp)
        );
        require(
            oracleResponses[key].isOpen,
            "Flight or timestamp do not match oracle request"
        );

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (
            oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES
        ) {
            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes(address account)
        internal
        returns (uint8[3] memory)
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);

        indexes[1] = indexes[0];
        while (indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while ((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex(address account) internal returns (uint8) {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(blockhash(block.number - nonce++), account)
                )
            ) % maxValue
        );

        if (nonce > 250) {
            nonce = 0; // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

    // endregion

    /**
     * @dev Fallback function for funding smart contract.
     *
     */
    fallback() external payable {}
}
