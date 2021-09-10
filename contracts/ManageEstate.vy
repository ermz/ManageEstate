# @version >=0.2.7 <0.3.0

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    amount: uint256

event LeaseApproved:
    landlord: indexed(address)
    tenenat: indexed(address)
    date: uint256

struct Property:
    direction: String[50]
    unit: String[10]
    rent: uint256
    owner: address
    tenant: address

struct Application:
    tenant: address
    propertyId: uint256
    length: uint256
    monthsFree: uint256
    approved: bool
    startDate: uint256
    broker: address
    brokerFee: uint256

admin: address

propertyLedger: HashMap[uint256, Property]
applicationLedger: HashMap[uint256, Application]
landlordList: HashMap[address, bool]
brokerList: HashMap[address, bool]
propertyId: uint256

APPLICATION_FEE: constant(uint256) = as_wei_value(1, "ether")

# For example DiGiulio to Brusco
# All DiGiuilio agents have access to Brusco units
brokerApprove: HashMap[address, HashMap[address, bool]]

# An agent tied to their broker
# Agent's can only have one broker
agentLedger: HashMap[address, address]

@external
def __init__():
    self.admin = msg.sender
    self.propertyId = 1

@external
def addLandlord(addr: address):
    assert msg.sender == self.admin
    self.landlordList[addr] = True

@external
def addBroker(addr: address):
    assert msg.sender == self.admin
    self.brokerList[addr] = True

@external
def addProperty(_direction: String[50], _unit: String[10], _rent: uint256):
    assert self.landlordList[msg.sender] == True, "You are not a certified landlord"
    self.propertyLedger[self.propertyId] = Property({
        direction: _direction,
        unit: _unit,
        rent: _rent,
        owner: msg.sender,
        tenant: ZERO_ADDRESS
    })
    self.propertyId += 1

@external
def approveBroker(broker: address):
    assert self.brokerList[broker] == True, "You may only approve, certified brokers"
    assert self.landlordList[msg.sender] == True, "You are not a certified landlord"
    self.brokerApprove[broker][msg.sender] = True

@external
def approveAgents(agent: address):
    assert self.brokerList[msg.sender] == True, "You are not a certified broker"
    assert self.agentLedger[agent] == ZERO_ADDRESS
    self.agentLedger[agent] = msg.sender

@external
def removeAgents(agent: address):
    assert self.agentLedger[agent] == msg.sender, "You can only remove your agents"
    self.agentLedger[agent] = ZERO_ADDRESS

@view
@external
def checkAgent(agent: address, broker: address, propertyId: uint256) -> bool:
    propertyOwner: address = self.propertyLedger[propertyId].owner
    assert self.brokerApprove[broker][propertyOwner] == True, "This broker does not have access to this unit"
    assert self.agentLedger[agent] == broker, "This agent is sponsored by this broker"
    return True

@payable
@external
def applyAsTenant(_propertyId: uint256, _startDate: uint256, _monthsFree: uint256, months: uint256):
    # Payment is two months up front(1st month rent and security deposit) + application fee
    assert 2 * as_wei_value(self.propertyLedger[_propertyId].rent, "ether") + APPLICATION_FEE >= msg.value, "You must transfer enough to cover app fee and 1 month rent"
    self.applicationLedger[_propertyId] = Application({
        tenant: msg.sender,
        propertyId: _propertyId,
        length: months,
        monthsFree: _monthsFree,
        approved: False,
        startDate: _startDate,
        broker: ZERO_ADDRESS,
        brokerFee: 0
    })
    log Transfer(msg.sender, self, msg.value)

@payable
@external
def applyAsBroker(_propertyId: uint256, _startDate: uint256, _monthsFree: uint256, months: uint256, _tenant: address, _brokerFee: uint256):
    property_owner: address = self.propertyLedger[_propertyId].owner
    assert self.brokerApprove[msg.sender][property_owner] == True, "You don't work with this landlord. Contact landlord for access"
    assert 2 * as_wei_value(self.propertyLedger[_propertyId].rent, "ether") + APPLICATION_FEE >= msg.value, "This won't cover enough for application"
    self.applicationLedger[_propertyId] = Application({
        tenant: _tenant,
        propertyId: _propertyId,
        length: months,
        monthsFree: _monthsFree,
        approved: False,
        startDate: _startDate,
        broker: msg.sender,
        brokerFee: _brokerFee
    })

@view
@external
def viewApplication(_propertyId: uint256) -> Application:
    assert self.propertyLedger[_propertyId].owner == msg.sender, "Only the property owner may view this application"
    return self.applicationLedger[_propertyId]

@external
def approveApplication(_propertyId: uint256):
    assert self.propertyLedger[_propertyId].owner == msg.sender, "Only the property owner may approve this application"
    self.applicationLedger[_propertyId].approved = True
    # Once application is approved landlord receives payment for 1 month rent
    # The security deposit is held until the end, for either security or given back
    send(msg.sender, as_wei_value(self.propertyLedger[_propertyId].rent, "ether"))
    
    log Transfer(self, self.propertyLedger[_propertyId].owner, self.propertyLedger[_propertyId].rent)
    log LeaseApproved(self.propertyLedger[_propertyId].owner, self.applicationLedger[_propertyId].tenant, block.timestamp)

@external
def withdrawBrokerFee(_propertyId: uint256):
    property_application: Application = self.applicationLedger[_propertyId]
    assert property_application.broker == msg.sender
    assert property_application.brokerFee > 0
    assert property_application.approved == True
    assert property_application.startDate <= block.timestamp, "You can only withdraw funds once tenants have moved into their new unit"
    send(msg.sender, as_wei_value(property_application.brokerFee, "ether"))
    log Transfer(self, msg.sender, property_application.brokerFee)

@external
def withdrawSecurityDeposit(_propertyId: uint256):
    property_application: Application = self.applicationLedger[_propertyId]
    assert property_application.tenant == msg.sender
    assert property_application.approved == True
    assert property_application.startDate + property_application.length <= block.timestamp, "You can only withdraw your deposit once you're lease is up"
    send(msg.sender, as_wei_value(self.propertyLedger[_propertyId].rent, "ether"))
    log Transfer(self, msg.sender, self.propertyLedger[_propertyId].rent)


# @external
# def subletRental(_propertyId: uint256, newTenant: address, length: address):


@payable
@external
def payRent(_propertyId: uint256):
    assert self.propertyLedger[_propertyId].tenant == msg.sender, "You are not renting this unit"
    assert as_wei_value(self.propertyLedger[_propertyId].rent, "ether") <= msg.value, "You aren't sending enough to cover rent"
    send(self.propertyLedger[_propertyId].owner, as_wei_value(self.propertyLedger[_propertyId].rent, "ether"))
    log Transfer(msg.sender, self.propertyLedger[_propertyId].owner, msg.value)
