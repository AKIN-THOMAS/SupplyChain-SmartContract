import { expect } from 'chai';
import pkg from 'hardhat';
const { ethers } = pkg;

describe("SupplyChain", function () {
    let SupplyChain, supplyChain, owner, producer, customer;

    beforeEach(async function () {
        [owner, producer, customer] = await ethers.getSigners();

        SupplyChain = await ethers.getContractFactory("SupplyChain");
        supplyChain = await SupplyChain.deploy();
        await supplyChain.deployed();
    });

    it("Should create a shipment", async function () {
        await supplyChain.connect(producer).createShipment(
            1,
            customer.address,
            "Electronics",
            10,
            ethers.utils.parseEther("1.0")
        );

        const shipment = await supplyChain.shipmentDetails(1);
        // console.log('Shipment:', shipment);
        expect(shipment[0].toNumber()).to.equal(1);
        expect(shipment[1]).to.equal(producer.address);
        expect(shipment[2]).to.equal(customer.address);
        expect(shipment[3]).to.equal("Electronics");
        expect(shipment[4].toNumber()).to.equal(10);
        expect(shipment[10].toString()).to.equal(ethers.utils.parseEther("1.0").toString());
        console.log("Shipment created successfully ✅");
    });

    it("Should verify the product", async function () {
        await supplyChain.connect(producer).createShipment(
            1,
            customer.address,
            "Electronics",
            10,
            ethers.utils.parseEther("1.0")
        );

        await supplyChain.connect(customer).verifyProduct(1);
        const shipment = await supplyChain.shipmentDetails(1);
        console.log('Verified shipment:', shipment);
        expect(shipment[7]).to.equal(true); // shipment.verified
        console.log("Verification Complete✅");
    });

    it("Should start the shipment", async function () {
        await supplyChain.connect(producer).createShipment(
            1,
            customer.address,
            "Electronics",
            10,
            ethers.utils.parseEther("1.0")
        );

        await supplyChain.connect(customer).verifyProduct(1);
        await supplyChain.connect(producer).startShipment(customer.address, 1, "Electronics");
        const shipment = await supplyChain.shipmentDetails(1);
        // console.log('Shipment in Transit:', shipment);
        expect(shipment[9]).to.equal(2); // shipment.shipmentStages (Transit)
        console.log("Shipment Status test completed✅");
    });

    it("Should complete the shipment", async function () {
        await supplyChain.connect(producer).createShipment(
            1,
            customer.address,
            "Electronics",
            10,
            ethers.utils.parseEther("1.0")
        );

        await supplyChain.connect(customer).verifyProduct(1);
        await supplyChain.connect(producer).startShipment(customer.address, 1, "Electronics");

        await supplyChain.connect(customer).completeShipment(1, { value: ethers.utils.parseEther("1.0") });

        const shipment = await supplyChain.shipmentDetails(1);
        // console.log('Completed shipment:', shipment);
        expect(shipment[9]).to.equal(3); // shipment.shipmentStages (Delivered)
        expect(shipment[8]).to.equal(true); // shipment.isPaid
        console.log("Shipment completed and payment successful ✅");
    });
});
