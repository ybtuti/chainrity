// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract Chainrity is AutomationCompatibleInterface {
    // Donation struct to hold details about each donation
    struct Donation {
        address payable donor;
        address payable recipient;
        uint256 amount;
        uint256 timestamp;
        bool isRecurring;
        uint256 nextDonationTime;
    }

    // Mapping to store donations indexed by donation ID
    mapping(uint256 => Donation) public donations;

    // Variable to store next donation ID
    uint256 public nextDonationId;

    // Chainlink Price Feed address for reference currency (e.g., USD)
    address public priceFeedAddress;

    // Minimum donation amount in Wei
    uint256 public minimumDonation;

    // Donation created event
    event DonationCreated(
        uint256 donationId,
        address donor,
        address recipient,
        uint256 amount,
        uint256 timestamp,
        bool isRecurring
    );
    event DonationFailed(
        uint256 donationId,
        address donor,
        address recipient,
        uint256 amount,
        bool isRecurring
    );

    constructor(address _priceFeedAddress) {
        priceFeedAddress = _priceFeedAddress;
        nextDonationId = 1;
    }

    // Function to donate to a recipient with optional recurring donations
    function donate(
        address payable _recipient,
        uint256 _amount,
        bool _isRecurring
    ) public payable {
        require(
            _amount >= minimumDonation,
            "Donation amount must be greater than or equal to minimum donation"
        );
        donations[nextDonationId] = Donation(
            payable(msg.sender),
            payable(_recipient),
            _amount,
            block.timestamp,
            _isRecurring,
            block.timestamp + 1 days
        );
        nextDonationId++;
        emit DonationCreated(
            nextDonationId - 1,
            msg.sender,
            _recipient,
            _amount,
            block.timestamp,
            _isRecurring
        );
        // // Transfer the donation amount to the recipient
        // _recipient.transfer(msg.value);
    }

    //function that allows the only the recipient to withdraw the funds
    function withdraw(uint256 _amount) public {
        require(
            msg.sender == donations[nextDonationId].recipient,
            "Only the recipient can withdraw the funds"
        );
        donations[nextDonationId].recipient.transfer(_amount);
    }

    // Function to check if upkeep is needed (for automatic recurring donations)
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        // This function checks for donations marked recurring after 1 day from donation timestamp
        upkeepNeeded = upcomingRecurringDonation();
        performData = "";
    }

    // Function to perform upkeep (automatic recurring donations)
    function performUpkeep(bytes calldata /* performData */) external override {
        // Logic to process automatic recurring donations based on checkUpkeep results
        for (uint256 i = 1; i < nextDonationId; i++) {
            Donation storage donation = donations[i];
            if (
                donation.isRecurring &&
                donation.nextDonationTime <= block.timestamp
            ) {
                // Call donate function again for the recurring donation
                donate(donation.donor, donation.amount, donation.isRecurring);
                // Update the next donation time
                donation.nextDonationTime += 1 days;
            }
        }
    }

    // Helper function to check for upcoming recurring donations
    function upcomingRecurringDonation() private view returns (bool) {
        // Iterate through donations and check for upcoming recurring ones based on nextDonationTime
        for (uint256 i = 1; i < nextDonationId; i++) {
            Donation memory donation = donations[i];
            if (
                donation.isRecurring &&
                donation.nextDonationTime <= block.timestamp
            ) {
                return true;
            }
        }
        return false;
    }

    // Function to get minimum donation amount in reference currency (e.g., USD) using Chainlink Price Feed
    function getMinimumDonationInUSD() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // Convert minimumDonation in Wei to reference currency using price feed data
        // additional logic needed for conversion based on price feed decimals etc.
        uint256 minimumDonationInUSD = (minimumDonation * uint256(answer)) /
            (10 ** priceFeed.decimals());
        return minimumDonationInUSD;
    }

    // // Function to set the recurring transfer interval )
    // function setInterval(uint256 _interval) public onlyOwner {
    //     interval = _interval;
    // }
    function getPriceFeed() external view returns (AggregatorV3Interface) {
        return AggregatorV3Interface(priceFeedAddress);
    }
}
