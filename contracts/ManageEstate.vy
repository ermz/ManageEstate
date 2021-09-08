# @version ^0.2.0

struct Property:
    direction: String[50]
    unit: String[10]
    rent: uint256
    owner: address
    tenant: address

admin: address

propertyLedger: HashMap[uint256, Property]
landlordList: HashMap[address, bool]
brokerList: HashMap[address, bool]
propertyId: uint256

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

