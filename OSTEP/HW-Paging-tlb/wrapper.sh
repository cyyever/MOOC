#!/bin/bash
for i in $(seq 1 2 1000) 
do
  used_time=$(./tlb $i 10000)
  echo "$i $used_time"
done
