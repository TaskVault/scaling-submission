// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TaskVault {
    IERC20 public usdcToken;

    event JobSubmitted(uint256 indexed _jobIndex, Submission submission);
    event JobCreated(uint256 indexed _jobIndex, Job job);
    event JobDisputed(uint256 indexed jobId, address indexed client);
    event jobResolved(uint256 indexed jobId, bool freelancerWins);
    event PaymentReleased(uint256 indexed jobId, address indexed freelancer, uint256 amount);
    event JobAccepted(uint256 indexed jobId, address indexed freelancer);

    address payable private escrow;
    uint256 private freelancerDeposit;

    enum JobStatus {
        Created,
        Accepted,
        Completed,
        Submitted,
        Disputed,
        Resolved,
        Paid
    }

    struct Job {
        string jobName;
        string jobDescription;
        uint256 jobPrice;
        uint256 jobDeadline;
        JobStatus status;
        address jobClient;
        address jobFreelancer;
    }

    struct Submission {
        uint256 jobIndex;
        string githubLink;
    }
    
    Job[] public jobs;

    constructor (address _usdcToken, uint256 _freelancerDeposit) {
        usdcToken = IERC20(_usdcToken);
        escrow = payable(msg.sender);
        freelancerDeposit = _freelancerDeposit;
    }

    function createJobListing(string memory _jobName, string memory _jobDescription, uint256 _jobPrice, uint256 _jobDeadline) public payable {
        require(usdcToken.transferFrom(msg.sender, escrow, _jobPrice), "Failed to transfer USDC to escrow");
        Job memory newJob = Job({
            jobName: _jobName,
            jobDescription: _jobDescription,
            jobPrice: _jobPrice,
            jobDeadline: _jobDeadline,
            status: JobStatus.Created,
            jobClient: msg.sender,
            jobFreelancer: address(0)
        });
        jobs.push(newJob);
        uint256 jobIndex = jobs.length - 1;
        emit JobCreated(jobIndex, newJob);
    }

    function acceptJobListing(uint256 _jobIndex) public payable {
        require(jobs[_jobIndex].jobClient != msg.sender, "Client cannot accept their own job");
        require(jobs[_jobIndex].jobFreelancer == address(0), "Job already has a freelancer");
        require(usdcToken.transferFrom(msg.sender, escrow, freelancerDeposit), "Failed to transfer USDC to escrow");
        jobs[_jobIndex].jobFreelancer = msg.sender;
        jobs[_jobIndex].status = JobStatus.Accepted;
        emit JobAccepted(_jobIndex, msg.sender);
    }

    function submitJob(uint256 _jobIndex, string memory _githubLink) public {
        require(jobs[_jobIndex].jobFreelancer == msg.sender, "Only the freelancer can submit a job");
        require(jobs[_jobIndex].status == JobStatus.Accepted, "Job not accepted");
        require(jobs[_jobIndex].status != JobStatus.Submitted, "Job already submitted");
        require(jobs[_jobIndex].jobDeadline > block.timestamp, "Job deadline has passed");
        Submission memory newSubmission = Submission({
            jobIndex: _jobIndex,
            githubLink: _githubLink
        });
        jobs[_jobIndex].status = JobStatus.Completed;
        emit JobSubmitted(_jobIndex, newSubmission);
    }

    function releasePayment(uint256 _jobIndex) public {
        require(jobs[_jobIndex].jobClient == msg.sender, "Only the client can release payment");
        require(jobs[_jobIndex].status == JobStatus.Completed, "Job not completed");
        require(jobs[_jobIndex].status != JobStatus.Paid, "Job already paid");
        jobs[_jobIndex].status = JobStatus.Paid;
        uint256 jobPrice = jobs[_jobIndex].jobPrice;
        uint256 totalAmount = jobPrice + freelancerDeposit;
        require(usdcToken.transfer(jobs[_jobIndex].jobFreelancer, totalAmount), "Failed to transfer USDC to freelancer");
        emit PaymentReleased(_jobIndex, jobs[_jobIndex].jobFreelancer, totalAmount);
    }

    function disputeJob(uint256 _jobIndex) public {
        require(jobs[_jobIndex].jobClient == msg.sender, "Only the client can dispute a job");
        require(jobs[_jobIndex].status == JobStatus.Completed, "Job not completed");
        jobs[_jobIndex].status = JobStatus.Disputed;
        emit JobDisputed(_jobIndex, msg.sender);
    }

    function resolveDispute(uint256 _jobIndex, bool _freelancerWins) public {
        require(msg.sender == escrow, "Only the contract deployer can resolve a dispute");
        require(jobs[_jobIndex].status == JobStatus.Disputed, "Job not disputed");

        uint256 jobPrice = jobs[_jobIndex].jobPrice;
        uint256 totalAmount = jobPrice + freelancerDeposit;

        if (_freelancerWins) {
            require(usdcToken.transfer(jobs[_jobIndex].jobFreelancer, totalAmount), "Failed to transfer USDC to freelancer");
        } else {
            require(usdcToken.transfer(jobs[_jobIndex].jobClient, totalAmount), "Failed to transfer USDC to client");
        }

        jobs[_jobIndex].status = JobStatus.Resolved;
        emit jobResolved(_jobIndex, _freelancerWins);
    }
}