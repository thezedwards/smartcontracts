// Allows us to use ES6 in our migrations and tests.
require('babel-register');

module.exports = {
    networks: {
        development: {
            host: 'dev.papyrus.global',
            port: 80,
            network_id: '*', // Match any network id
            from: "0xbcb960702272e89b76cfed5395404f345a4a0fdc"
        }
    }
};