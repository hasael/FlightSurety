
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async () => {

    let result = null;

    let contract = new Contract('localhost', () => {


        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            let airline = DOM.elid('airline-fetch').value;
            // Write transaction
            contract.fetchFlightStatus(flight, airline, (error, result) => {
                display('Oracles', 'Trigger oracles', [{ label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp }]);
            });
        })

        //Airline register flight
        DOM.elid('register-flight').addEventListener('click', () => {
            let flight = DOM.elid('flight-number-2').value;
            // Write transaction
            contract.registerFlight(flight, (error, result) => {
                display('Flights', 'Register flight', [{ label: 'Register flight Status', error: error, value: result.flight + ' ' + result.timestamp }]);
            });
        })

        //Passenger buy insurance
        DOM.elid('buy-insurance').addEventListener('click', () => {
            let flight = DOM.elid('flight-number-user').value;
            let airline = DOM.elid('airline-buy').value;
            let insuranceValue = DOM.elid('insurance-value-buy').value;
            // Write transaction
            contract.buyInsurance(flight, airline, insuranceValue, (error, result) => {
                display('Flights', 'Buy Insurance', [{ label: 'Buy Insurance Status', error: error, value: result.flight + ' ' + result.timestamp }]);
            });
        })

        //Passenger withdraw balance
        DOM.elid('withdraw-balance').addEventListener('click', () => {
            let value = DOM.elid('withdraw-value').value;
            // Write transaction
            contract.withdrawBalance(value, (error, result) => {
                display('Flights', 'Buy Insurance', [{ label: 'withdraw- Status', error: error, value: result }]);
            });
        })

        //Airline register
        DOM.elid('register-airline').addEventListener('click', () => {
            // Write transaction
            let name = DOM.elid('register-airline-name').value;
            let airlineAddress = DOM.elid('register-airline-address').value;
            contract.registerAirline(name, airlineAddress, (error, result) => {
                display('Flights', 'Register Airline', [{ label: 'Register Airline Status', error: error, value: result }]);
            });
        })
        //Airline fund
        DOM.elid('fund-bttn').addEventListener('click', () => {
            // Write transaction
            let fundValue = DOM.elid('fund-value').value;

            contract.fundAirline(fundValue, (error, result) => {
                display('Flights', 'Register Airline', [{ label: 'Register Airline Status', error: error, value: result }]);
            });
        })

    });

    // Read transaction
    contract.isOperational((error, result) => {
        console.log(error, result);
        display('Operational Status', 'Check if contract is operational', [{ label: 'Operational Status', error: error, value: result }]);
    });

    // Read transaction
    contract.getFlights((error, result) => {
        console.log(error, result);
        displayFlights(result);
    });

    // Read transaction
    contract.getBalance((error, result) => {
        console.log('Balance: ' + result);
        let displayDiv = DOM.elid("balance-value");
        displayDiv.innerText = result;
    });


})();


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({ className: 'row' }));
        row.appendChild(DOM.div({ className: 'col-sm-4 field' }, result.label));
        row.appendChild(DOM.div({ className: 'col-sm-8 field-value' }, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}

function displayFlights(results) {
    let displayDiv = DOM.elid("flights-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2("Flights"));
    results.map((result) => {
        let row = section.appendChild(DOM.div({ className: 'row' }));
        row.appendChild(DOM.div({ className: 'col-sm-6 field' }, 'Airline: ' + result.airline));
        row.appendChild(DOM.div({ className: 'col-sm-6 field-value' }, 'Flight: ' + result.flight));
        section.appendChild(row);
    })
    displayDiv.append(section);
}
