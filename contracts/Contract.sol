// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SupplyChain {
    address public owner;
    uint256 public shipmentCount;
    

    // Struct to store shipment details
    struct Shipment {
        uint256 shipmentId;
        address producer;
        address customer;
        string productType;
        uint256 quantity;
        uint256 timestamp;
        uint256 deliveryTime;
        bool verified;
        bool isPaid;
        ShipmentStatus shipmentStages;
        uint256 price;
    }

    // Enum to represent shipment status
    enum ShipmentStatus { Packaging, Loading, Transit, Delivered }

    // Mapping to store shipments
    mapping(uint256 => Shipment) public shipments;

    // Events for tracking shipment events
    event ShipmentCreated(uint256 indexed shipmentId, address indexed producer, string productType, uint256 _price, address _customer);
    event ShipmentInTransit(uint256 indexed shipmentId, string productType, address customer, uint256 timestamp);
    event ShipmentDelivered(address indexed producer, address customer, uint256 deliveryTime);
    event ProductVerified(uint256 indexed shipmentId);
    event ShipmentStageUpdated(uint256 indexed shipmentId, ShipmentStatus stage);
    event PaymentMade(uint256 indexed shipmentId, uint256 amount);
    event PaymentDetails(address indexed customer, address indexed producer, uint256 amount);

    constructor() payable{
        owner = msg.sender;
        shipmentCount = 0;
    }

    // Modifier to restrict access to certain functions
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    // Function to create a new shipment
    function createShipment(
        uint256 _shipmentId,
        address _customer,
        string memory _productType,
        uint256 _quantity,
        uint256 _price
    ) external {
        // Check if shipment ID is unique
        require(shipments[_shipmentId].producer == address(0), "Shipment ID already exists");
        require(shipments[_shipmentId].customer == address(0), "Shipment already exists");

    // Set the customer address
    shipments[_shipmentId].customer = _customer;


        // Create a new shipment
        shipments[_shipmentId] = Shipment({
            shipmentId: _shipmentId,
            producer: msg.sender,
            customer: _customer,
            productType: _productType,
            quantity: _quantity,
            timestamp: block.timestamp,
            deliveryTime: 0,
            verified: false,
            isPaid: false,
            shipmentStages: ShipmentStatus.Packaging,
            price: _price
        });

        shipmentCount ++;

        emit ShipmentCreated(_shipmentId, msg.sender, _productType, _price, _customer);
    }
    // Function for the customer to verify the product
   function verifyProduct(uint256 _shipmentId) public {
        Shipment storage shipment = shipments[_shipmentId];
        require(msg.sender == shipment.customer || msg.sender == shipment.producer, "Only the customer or producer can verify the product");

        shipment.verified = true;

        emit ProductVerified(_shipmentId);
    }

    modifier isVerified(uint256 _shipmentId) {
        Shipment storage shipment = shipments[_shipmentId];
        require(shipment.verified == true, "Product is not verified");
        _;
    }

   
    function startShipment(
        address customer,
        uint256 _shipmentId,
        string memory _productType) public isVerified(_shipmentId){
            Shipment storage shipment = shipments[_shipmentId];

            require(shipment.customer == customer, "Invalid Receiver");
            require(shipment.shipmentStages == ShipmentStatus.Packaging, "Product is already in transit");

            // updateShipmentStage(_shipmentId, ShipmentStatus.Transit);
            shipment.shipmentStages = ShipmentStatus.Transit;
            
            emit ShipmentInTransit(_shipmentId, _productType, customer, shipment.timestamp);

        }
    

    modifier shipmentReadyForCompletion(uint256 _shipmentId) {
        Shipment storage shipment = shipments[_shipmentId];
        require(shipment.shipmentStages == ShipmentStatus.Transit, "Product is not in transit");
        require(shipment.verified, "Product not verified");
        _;
    }


    function completeShipment(uint256 _shipmentId) public payable {
        Shipment storage shipment = shipments[_shipmentId];
        require(shipment.shipmentStages == ShipmentStatus.Transit, "Product is not in transit");
        require(shipment.verified, "Product not verified yet");
        require(shipment.shipmentStages != ShipmentStatus.Packaging, "Product is not ready for payment");

        shipment.shipmentStages = ShipmentStatus.Delivered;
        shipment.deliveryTime = block.timestamp;

        uint256 amount = shipment.price;
        require(amount > 0, "Payment amount must be greater than zero");

        address payable producer = payable(shipment.producer);

        emit PaymentDetails(shipment.customer, producer, amount);

        (bool success, ) = producer.call{value: amount}("");
        require(success, "Payment failed");

        // makePayment(_shipmentId);

        shipment.isPaid = true;
        emit PaymentMade(_shipmentId, amount);

        emit ShipmentDelivered(shipment.producer, shipment.customer, shipment.deliveryTime);
    }


    function shipmentDetails(uint256 _shipmentId) public view returns(uint256, address, address, string memory, uint256, uint256, uint256, bool, bool, ShipmentStatus, uint256) {
        Shipment storage shipment = shipments[_shipmentId];
        return (shipment.shipmentId, shipment.producer, shipment.customer, shipment.productType, shipment.quantity, shipment.timestamp, shipment.deliveryTime, shipment.verified, shipment.isPaid, shipment.shipmentStages, shipment.price);
    }

}
