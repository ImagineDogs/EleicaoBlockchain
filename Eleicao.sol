// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    address private admin;
    bool public electionOpen;

    struct Candidate {
        uint voteNumber;
        string name;
        uint voteCount;
        bool isRegistered;
    }

    struct Voter {
        bool hasVoted;
    }

    mapping(uint => Candidate) private candidates;
    mapping(address => Voter) private voters;
    mapping(uint => address) private receipts; 
    uint[] private keys;

    event VoteCast(address indexed voter, uint candidateId, uint receipt);
    event CandidateAdded(uint id, string name);
    event ElectionStarted();
    event ElectionEnded();

    modifier onlyAdmin() {
        require(msg.sender == admin, "Apenas o admin pode realizar esta acao");
        _;
    }

    modifier onlyDuringElection() {
        require(electionOpen, "A eleicao nao esta aberta");
        _;
    }

    modifier onlyOffElection() {
        require(!electionOpen, "A eleicao esta aberta");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function uintToString(uint v) internal pure returns (string memory) {
        if (v == 0) {
            return "0";
        }
        uint maxlength = 78;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i); 
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1];
        }
        return string(s);
    }

    function startElection() public onlyAdmin {
        require(keys.length > 1, "Candidatos Insuficientes");
        electionOpen = true;
        emit ElectionStarted();
    }

    function endElection() public onlyAdmin {
        electionOpen = false;
        emit ElectionEnded();
    }

    function addCandidate(string memory _name, uint voteNumber) public onlyAdmin onlyOffElection {
        require(bytes(_name).length > 0, "Nome do candidato nao pode estar vazio");
        require(voteNumber != 0, "Numero eleitoral invalido");
        require(!candidates[voteNumber].isRegistered, "Candidato ja registrado");
        candidates[voteNumber] = Candidate(voteNumber, _name, 0, true);
        keys.push(voteNumber);
        emit CandidateAdded(voteNumber, _name);
    }

    function vote(uint voteNumber) public onlyDuringElection returns (uint ) {
        require(!voters[msg.sender].hasVoted, "Ja votou");
        require(candidates[voteNumber].isRegistered, "ID de candidato invalido");
        candidates[voteNumber].voteCount++;
        bytes32 voteReceipt = keccak256(abi.encodePacked(msg.sender, voteNumber));
        voters[msg.sender] = Voter(true);
        receipts[uint256(voteReceipt)] = msg.sender;

        emit VoteCast(msg.sender, voteNumber, uint256(voteReceipt));
        return uint256(voteReceipt);
    }

    function getVoteByReceipt(uint256 _receipt) public view returns (string memory) {
        bytes32 receiptHash = bytes32(_receipt);
        require(receipts[uint256(_receipt)] == msg.sender, "Nao autorizado ou recibo invalido");

        for (uint i = 0; i < keys.length; i++) {
            uint voteNumber = keys[i];
            bytes32 voteReceiptHash = keccak256(abi.encodePacked(msg.sender, voteNumber));
            if (voteReceiptHash == receiptHash) {
                string memory numVoto = uintToString(keys[i]);
                return string(abi.encodePacked(
                    "Candidato: ", candidates[keys[i]].name, " -- " 
                    ,"Numero Eleitoral: ", numVoto
                ));
            }
        }

        revert("Nenhum voto encontrado com este recibo");
    }

    function getResults() public onlyOffElection onlyAdmin view returns (string[] memory, uint[] memory, uint[] memory) {
        string[] memory candidateNames = new string[](keys.length);
        uint[] memory voteCounts = new uint[](keys.length);
        uint[] memory votePerc = new uint[](keys.length);
        uint totalvotos = 0;

        for (uint i = 0; i < keys.length; i++) {
            totalvotos += candidates[keys[i]].voteCount;
        }

        for (uint i = 0; i < keys.length; i++) {
            candidateNames[i] = candidates[keys[i]].name;
            votePerc[i] = (candidates[keys[i]].voteCount*100)/totalvotos;
            voteCounts[i] = candidates[keys[i]].voteCount;
        }

        return (candidateNames, voteCounts, votePerc);
    }

    function getCandidates() public view returns (string[] memory, uint[] memory) {
        string[] memory candidateNames = new string[](keys.length);
        uint[] memory candidateNumbers = new uint[](keys.length);

        for (uint i = 0; i < keys.length; i++) {
            candidateNames[i] = candidates[keys[i]].name;
            candidateNumbers[i] = keys[i];
        }

        return (candidateNames, candidateNumbers);
    }
}

