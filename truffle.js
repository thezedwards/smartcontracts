// Allows us to use ES6 in our migrations and tests.
require('babel-register');

module.exports = {
    networks: {
        development: {
            host: '35.227.236.24',
            port: 80,
            network_id: '*', // Match any network id
            gas: 10000000,
            gasPrice: 0x01
            // from: "0x3a4cac8ae75136b1e54cce14b8e1c11b8de39544"
        },
        local: {
            host: 'localhost',
            port: 8545,
            network_id: '*', // Match any network id
            gas: 10000000,
            gasPrice: 0x01
        }
    }
};