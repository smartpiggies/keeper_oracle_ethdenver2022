// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract BufferTest {

    uint256 constant public capacity = 6;
    uint256 public head;
    uint256 public tail;
    uint256 public latestIndex;
    uint256[capacity] public jobs;
    bool public bufferFull = false;

    function addJob(uint256 _input)
        public
    {
        require(bufferFull == false, "Jobs buffer full");

        // increase head
        head = addmod(head, 1, capacity);
        // add job
        jobs[head] = _input;

        bufferFull = (head == tail);
    }

    function clearJob(uint256 _input)
        public
    {
        // clean up jobs buffer
        uint256 index = 0;
        for(uint256 i = 0; i < capacity; i++)
        {
            index = addmod(tail, i, capacity);
            if(jobs[index] == _input)
            {
                latestIndex = index;
                break;
            }
        }
        // when index of removal is located
        // clean up the buffer
        for(uint256 i = 0; i < capacity; i++)
        {
            if(index == tail)
            {
                delete jobs[index];
                tail = addmod(tail, 1, capacity);
                break;
            }
            if(index == 0)
            {
                jobs[index] = jobs[capacity-1];
                index = capacity - 1;
            }
            else
            {
                jobs[index] = jobs[index-1];
                index = index - 1;
            }
        }
        bufferFull = (head == tail);
    }
}
