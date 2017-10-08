// Allows us to use ES6 in our migrations and tests.
require('babel-register');

module.exports = {
    networks: {
        development: {
            host: 'dev.papyrus.global',
            port: 80,
            network_id: '*', // Match any network id
            from: "0x3a4cac8ae75136b1e54cce14b8e1c11b8de39544"
        }
    }
};