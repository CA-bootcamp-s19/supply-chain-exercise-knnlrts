pragma solidity ^0.6.12;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";
import "../contracts/ActorProxy.sol";

contract TestSupplyChain {

    // Test for failing conditions in this contracts:
    // https://truffleframework.com/tutorials/testing-for-throws-in-solidity-tests

    ActorProxy buyer;
    ActorProxy seller;
    ActorProxy randomPerson;
    SupplyChain supplychain;
    uint public initialBalance = 1 gwei;

    function beforeEach() public {
        //supplychain = SupplyChain(DeployedAddresses.SupplyChain());
        supplychain = new SupplyChain();
        buyer = new ActorProxy(address(supplychain));
        address(buyer).transfer(10000);
        seller = new ActorProxy(address(supplychain));
        address(seller).transfer(10000);
        randomPerson = new ActorProxy(address(supplychain));
        address(randomPerson).transfer(10000);
    }

    function testItemCanBePutOnSale() public {
        string memory expectedName = "Book";
        uint expectedPrice = 1000;
        seller.placeItemForSale(expectedName, expectedPrice);
        (string memory _name, uint _sku, uint _price, uint _state, address _seller, address _buyer) = supplychain.fetchItem(0);
        Assert.equal(_name, expectedName, "The item name should match");
        Assert.equal(_sku, 0, "The item sku should match 0");
        Assert.equal(_price, expectedPrice, "The item price should match");
        Assert.equal(_state, uint(SupplyChain.State.ForSale), "The item state at creation should match .ForSale");
        Assert.equal(_seller, address(seller), "The function caller should be the seller");
        Assert.equal(_buyer, address(0), "The item buyer should be empty");
    }

    // buyItem
    // test for failure if user does not send enough funds
    function testUserDoesNotPayTheRightPrice() public {
        seller.placeItemForSale("Book", 1000);
        Assert.isFalse(buyer.purchaseItem(0, 500), "The item buyer must send enough funds to buy the item");
    }

    function testUserPaysCorrectPrice() public {
        seller.placeItemForSale("Book", 1000);
        buyer.purchaseItem(0, 1000);
        ( , , , uint _state, , address _buyer) = supplychain.fetchItem(0);
        Assert.equal(_state, uint(SupplyChain.State.Sold), "The item state after buying should match .Sold");
        Assert.equal(_buyer, address(buyer), "The function caller should be the buyer");
    }

    // test for purchasing an item that is not for Sale
    function testItemCannotBePurchasedtwice() public {
        seller.placeItemForSale("Book", 1000);
        buyer.purchaseItem(0, 1000);
        Assert.isFalse(buyer.purchaseItem(0, 1000), "The item buyer cannot purchase an item that is not for sale");
    }

    // shipItem
    // test for calls that are made by not the seller
    function testRandomUserCannotShipItem() public {
        seller.placeItemForSale("Book", 1000);
        buyer.purchaseItem(0, 1000);
        Assert.isFalse(randomPerson.shipItem(0), "Only the item seller can ship an item");
    }

    function testSellerCanShipItem() public {
        seller.placeItemForSale("Book", 1000);
        buyer.purchaseItem(0, 1000);
        seller.shipItem(0);
        ( , , , uint _state, , ) = supplychain.fetchItem(0);
        Assert.equal(_state, uint(SupplyChain.State.Shipped), "The item state after seller shipping should match .Shipped");
    }

    // test for trying to ship an item that is not marked Sold
    function testCannotShipAnItemThatIsNotSold() public {
        seller.placeItemForSale("Book", 1000);
        Assert.isFalse(seller.shipItem(0), "The item seller cannot ship an item that has not been sold yet");
    }

    // receiveItem
    // test calling the function from an address that is not the buyer
    function testNonBuyerCannotSetItemAsReceived() public {
        seller.placeItemForSale("Book", 1000);
        buyer.purchaseItem(0, 1000);
        seller.shipItem(0);
        Assert.isFalse(randomPerson.receiveItem(0), "Only the item buyer can receive an item");
    }

    function testBuyerCanSetItemAsReceived() public {
        seller.placeItemForSale("Book", 1000);
        buyer.purchaseItem(0, 1000);
        seller.shipItem(0);
        buyer.receiveItem(0);
        ( , , , uint _state, , ) = supplychain.fetchItem(0);
        Assert.equal(_state, uint(SupplyChain.State.Received), "The item state after buyer reception should match .Shipped");
    }

    // test calling the function on an item not marked Shipped
    function testBuyerCannotReceiveItemNotShipped() public {
        seller.placeItemForSale("Book", 1000);
        buyer.purchaseItem(0, 1000);
        Assert.isFalse(buyer.receiveItem(0), "The item buyer cannot receive an item that has not been shipped yet");
    }

}
