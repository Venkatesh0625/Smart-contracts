pragma solidity ^0.5.0;

contract Escrow {
    
    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE }

    struct product {
        State stage;
        string product_name;
        uint256 amount;
        address seller;
        address buyer;
    }

    struct user {
        address addr;
        string nick_name;
        uint bought;
        uint sold;
        uint balance;
    }

    address escrower;
    product[] products;
    mapping(address => user) users;
    

    modifier is_escrower() {
        require(msg.sender == escrower, 'Authorised for Escrower alone');
        _; 
    }

    modifier not_escrower() {
        require(msg.sender != escrower, 'Unauthorised to escrower');
        _;
    }

    modifier is_new() {
        require(users[msg.sender].addr == address(0), 'Already registered');
        _;
    }

    modifier is_registered() {
       require(users[msg.sender].addr == msg.sender, 'Not yet registered');
       _;
    }

    constructor() public {
        escrower = msg.sender;
    }

    function register(address _joiner, string memory _nick_name) public is_new {
        users[_joiner] = user({
            addr: msg.sender,
            nick_name: _nick_name,
            bought: 0,
            sold: 0,
            balance: 0
        });
    }

    function initiate_escrow(string memory _product_name, address _seller, address _buyer, uint256 _amount) public is_registered returns(uint) {
        require(msg.sender == _buyer || msg.sender == _seller, 'Only buyer or seller can initiate escrow');
        require(_buyer != _seller, 'Buyer and seller cant be the same');
        products.push(product({
            stage: State.AWAITING_PAYMENT,
            product_name: _product_name,
            seller: _seller,
            buyer: _seller,
            amount: _amount
        }));

        uint escrow_id = products.length - 1;
        if(users[products[escrow_id].buyer].balance >= _amount) {
            products[escrow_id].stage = State.AWAITING_DELIVERY;
        }
        return escrow_id;
    }

    function initiate_delivery(uint escrow_id) public not_escrower {
        require(msg.sender == products[escrow_id].seller, 'Only seller can initiate_delivery');
        require(users[products[escrow_id].buyer].balance >= products[escrow_id].amount, 'Buyers balance is insufficient to proceed');
        products[escrow_id].stage = State.AWAITING_DELIVERY;
    }

    function move_payment(uint escrow_id) public not_escrower {
        require(msg.sender == products[escrow_id].buyer, 'Only buyer can initiate_delivery');
        address seller = products[escrow_id].seller;
        users[seller].balance += products[escrow_id].amount;
    }

    function deposit() public payable not_escrower is_registered {
        users[msg.sender].balance += msg.value;
    }
    
    function get_balance() public view is_registered returns (uint256) {
        return users[msg.sender].balance;
    }
    
    function withdraw() public is_registered returns (uint256) {
        address payable addr = msg.sender;
        if(users[msg.sender].balance > 0) {
            addr.transfer(users[msg.sender].balance);
        }
        
    }
    
}