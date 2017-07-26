pragma solidity ^0.4.11;


contract DSPRegistry {
    mapping (address => mapping (address => uint256)) dsp_deposits;
    mapping (address => address[]) dsp_ssp_relations;
    address[] dspAddresses;

    function DSPRegistry(){
        address dsp1 = 0xf61e02f629E3cA8Af430f8Db8D1ab22C7093303B;
        address dsp2 = 0x1311ad419343F0bB20750e295AAb1DD6299B3aC7;
        address dsp3 = 0x74D1A4B07a1AF3f38e4C7c91E177bD2195909bF1;
        address ssp1 = 0xde0A0AB0af829dD7ba1c62f5B3fE9B88f7D92496;
        address ssp2 = 0x9aaA67a61C893FBd5b92E3BfCe2661A6c2695805;

        register(dsp1, ssp1, 1);
        register(dsp1, ssp2, 3);
        register(dsp2, ssp2, 2);
        register(dsp3, ssp1, 4);
    }

    function register(address dsp, address ssp, uint256 deposit) {
        require(deposit > 0);
        if (dsp_ssp_relations[dsp].length == 0) {
            dspAddresses.push(dsp);
        }
        if (dsp_deposits[dsp][ssp] == 0) {
            dsp_ssp_relations[dsp].push(ssp);
        }
        dsp_deposits[dsp][ssp] = deposit;
    }

    function getAllDsp() constant returns (address[]) {
        dspAddresses;
    }

    function getMyDeposits(address dsp) constant returns (uint256){
        dsp_deposits[dsp][msg.sender];
    }
}
