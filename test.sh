#!/bin/env bash

test() {
    if [ $@ > 0 ] 
    then
        echo -e "Test_func - true"
        true
    else
        echo -e "Test_func - false"
        false
    fi
}

main() {
    if  test $@ 
    then
        echo $@
    else
        echo "Empty"
    fi
}

main $@