// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract TaskVault {
    IERC20 public usdcToken;

    event JobSubmitted(Submission submission);
    event JobCreated(Job job);

    address payable private escrow;
    uint256 private freelancerDeposit;

    struct Job {
        string jobName;
        string jobDescription;
        uint256 jobPrice;
        uint256 jobDeadline;
        bool jobCompleted;
        bool jobPaid;
        bool jobAccepted;
        address jobClient;
        address jobFreelancer;
    }

    struct Submission {
        uint256 jobIndex;
        string githubLink;
    }
    
    Job[] public jobs;

    constructor (address _usdcToken, address payable _escrow, uint256 _freelancerDeposit) {
        usdcToken = IERC20(_usdcToken);
        escrow = _escrow;
        freelancerDeposit = _freelancerDeposit;
    }

    function createJobListing(string memory _jobName, string memory _jobDescription, uint256 _jobPrice, uint256 _jobDeadline) public payable {
        Job memory newJob = Job({
            jobName: _jobName,
            jobDescription: _jobDescription,
            jobPrice: _jobPrice,
            jobDeadline: _jobDeadline,
            jobCompleted: false,
            jobPaid: false,
            jobAccepted: false,
            jobClient: msg.sender,
            jobFreelancer: address(0)
        });
        require(usdcToken.transferFrom(msg.sender, escrow, _jobPrice), "Failed to transfer USDC to escrow");
        jobs.push(newJob);
        emit JobCreated(newJob);
    }

    function acceptJobListing(uint256 _jobIndex) public payable {
        require(jobs[_jobIndex].jobClient != msg.sender, "Client cannot accept their own job");
        require(jobs[_jobIndex].jobFreelancer == address(0), "Job already has a freelancer");
        require(usdcToken.transferFrom(msg.sender, escrow, freelancerDeposit), "Failed to transfer USDC to escrow");
        jobs[_jobIndex].jobFreelancer = msg.sender;
        jobs[_jobIndex].jobAccepted = true;
    }

    function submitJob(uint256 _jobIndex, string memory _githubLink) public payable {
        require(jobs[_jobIndex].jobFreelancer == msg.sender, "Only the freelancer can submit a job");
        require(jobs[_jobIndex].jobCompleted == false, "Job already completed");
        require(jobs[_jobIndex].jobDeadline > block.timestamp, "Job deadline has passed");
        Submission memory newSubmission = Submission({
            jobIndex: _jobIndex,
            githubLink: _githubLink
        });
        jobs[_jobIndex].jobCompleted = true;
        emit JobSubmitted(newSubmission);
    }
}