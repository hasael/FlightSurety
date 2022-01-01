pragma solidity ^0.8.10;

library FlightStatusCodes {
    // Flight status codees
    uint8 constant STATUS_CODE_UNKNOWN = 0;
    uint8 constant STATUS_CODE_ON_TIME = 10;
    uint8 constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 constant STATUS_CODE_LATE_OTHER = 50;

    struct FlightInfo {
        string flight;
        string airline;
    }
}
