// Allows us to use ES6 in our migrations and tests.
require('babel-register');

module.exports = {
    networks: {
        mvp: {
            host: '213.239.219.107',
            port: 8545,
            network_id: '4', // Match any network id
            gas: 7450000,
            gasPrice: 25000000000
        },
        development: {
            host: '35.205.243.163',
            port: 8545,
            network_id: '1337', // Match any network id
            gas: 10000000,
            gasPrice: 1000000000
        },
        local: {
            host: 'localhost',
            port: 8545,
            network_id: '*', // Match any network id
            gas: 5000000,
            gasPrice: 10000000000
        }
    },
    solc: {
        optimizer: {
            enabled: true,
            runs: 200
        }
    }
};