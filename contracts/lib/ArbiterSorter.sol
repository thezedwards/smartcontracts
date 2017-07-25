pragma solidity ^0.4.11;

library ArbiterSorter {

    function sort(Arbiter[] storage data) {

        uint n = data.length;
        Arbiter[] memory arr = new Arbiter[](n);
        uint i;

        for (i = 0; i < n; i++) {
            arr[i] = data[i];
        }

        Arbiter key;
        uint j;

        for (i = 1; i < arr.length; i++) {
            key = arr[i];

            for (j = i; j > 0 && arr[j - 1].karma < key.karma; j--) {
                arr[j] = arr[j - 1];
            }

            arr[j] = key;
        }

        for (i = 0; i < n; i++) {
            data[i] = arr[i];
        }

    }

}
