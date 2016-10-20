#!/bin/bash

. ../../exadata.env
if [ -z "$node_password"]; then
    echo node_password is not set
    exit 1
fi 
if [ -z "$cell_password"]; then
    echo cell_password is not set
    exit 1
fi 
if [ -z "$ilom_password"]; then
    echo ilom_password is not set
    exit 1
fi 
if [ -z "$ilom_password2"]; then
    echo ilom_password2 is not set
    exit 1
fi 

echo "Hello, this is upgrade step 1"
echo "Hello, this is upgrade step 2"
echo "Hello, this is upgrade step 3"
