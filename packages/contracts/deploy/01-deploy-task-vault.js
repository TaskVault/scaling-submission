import { ethers } from "hardhat";

const main = async () => {
    const USDC_ADDRESS_MUMBAI = "0x0FA8781a83E46826621b3BC094Ea2A0212e71B23";
    const FREELANCER_DEPOSIT = ethers.utils.parseUnits('10', 6);

    const TaskVault = await ethers.getContractFactory("TaskVault");
    const taskVault = await TaskVault.deploy(USDC_ADDRESS_MUMBAI, FREELANCER_DEPOSIT);

    console.log("TaskVault deployed to:", taskVault.address);
};

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    }
);