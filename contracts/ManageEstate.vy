# @version >=0.2.7 <0.3.0

from vyper.interfaces import ERC721

implements: ERC721

interface ERC721Receiver:
    def onERC721Received(
        _operator: address,
        _from: address,
        _tokenId: uint256,
        _data: Bytes[1024]
    ) -> bytes32: view

event EtherTransfer:
    sender: indexed(address)
    receiver: indexed(address)
    amount: uint256

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    amount: uint256

event Approval:
    owner: indexed(address)
    approved: indexed(address)
    tokenId: indexed(uint256)

event ApprovalForAll:
    owner: indexed(address)
    operator: indexed(address)
    approved: bool

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
    price: uint256

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

subtenantLedger: HashMap[uint256, HashMap[address, uint256]]

# ERC721 storage variables
idToOwner: HashMap[uint256, address]
idToApprovals: HashMap[uint256, address]
ownerToNFTokenCount: HashMap[address, uint256]
ownerToOperators: HashMap[address, HashMap[address, bool]]
minter: address
supportedInterfaces: HashMap[bytes32, bool]
ERC165_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000001ffc9a7
ERC721_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000080ac58cd

@external
def __init__():
    self.admin = msg.sender
    self.minter = msg.sender
    self.propertyId = 1
    self.supportedInterfaces[ERC165_INTERFACE_ID] = True
    self.supportedInterfaces[ERC721_INTERFACE_ID] = True

# ERC721 functions
@view
@external
def supportsInterface(_interfaceID: bytes32) -> bool:
    return self.supportedInterfaces[_interfaceID]

@view
@external
def balanceOf(_owner: address) -> uint256:
    assert _owner != ZERO_ADDRESS
    return self.ownerToNFTokenCount[_owner]

@view
@external
def ownerOf(_tokenId: uint256) -> address:
    owner: address = self.idToOwner[_tokenId]
    assert owner != ZERO_ADDRESS
    return owner

@view
@external
def getApproved(_tokenId: uint256) -> address:
    assert self.idToOwner[_tokenId] != ZERO_ADDRESS
    return self.idToApprovals[_tokenId]

@view
@external
def isApprovedForAll(_owner: address, _operator: address) -> bool:
    return (self.ownerToOperators[_owner])[_operator]

@view
@internal
def _isApprovedOrOwner(_spender: address, _tokenId: uint256) -> bool:
    owner: address = self.idToOwner[_tokenId]
    spenderIsOwner: bool = owner == _spender
    spenderIsApproved: bool = _spender == self.idToApprovals[_tokenId]
    spenderIsApprovedForAll: bool = (self.ownerToOperators[owner])[_spender]
    return (spenderIsOwner or spenderIsApproved) or spenderIsApprovedForAll

@internal
def _addTokenTo(_to: address, _tokenId: uint256):
    assert self.idToOwner[_tokenId] == ZERO_ADDRESS
    self.idToOwner[_tokenId] = _to
    self.ownerToNFTokenCount[_to] += 1

@internal
def _removeTokenFrom(_from: address, _tokenId: uint256):
    assert self.idToOwner[_tokenId] == _from
    self.idToOwner[_tokenId] = ZERO_ADDRESS
    self.ownerToNFTokenCount[_from] -= 1

@internal
def _clearApproval(_owner: address, _tokenId: uint256):
    assert self.idToOwner[_tokenId] == _owner
    if self.idToApprovals[_tokenId] != ZERO_ADDRESS:
        self.idToApprovals[_tokenId] = ZERO_ADDRESS

@internal
def _transferFrom(_from: address, _to: address, _tokenId: uint256, _sender: address):
    assert self._isApprovedOrOwner(_sender, _tokenId)
    assert _to != ZERO_ADDRESS
    self._clearApproval(_from, _tokenId)
    self._removeTokenFrom(_from, _tokenId)
    self._addTokenTo(_to, _tokenId)
    log Transfer(_from, _to, _tokenId)


@external
def transferFrom(_from: address, _to: address, _tokenId: uint256):
    self._transferFrom(_from, _to, _tokenId, msg.sender)

@external
def safeTransferFrom(_from: address, _to: address, _tokenId: uint256, _data: Bytes[1024]=b""):
    self._transferFrom(_from, _to, _tokenId, msg.sender)
    if _to.is_contract:
        returnValue: bytes32 = ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data)
        assert returnValue == method_id("onERC721Received(address,address,uint256,bytes)", output_type=bytes32)

@external
def approve(_approved: address, _tokenId: uint256):
    owner: address = self.idToOwner[_tokenId]
    assert owner != ZERO_ADDRESS
    assert _approved != owner
    senderIsOwner: bool = self.idToOwner[_tokenId] == msg.sender
    senderIsApprovedForAll: bool = (self.ownerToOperators[owner])[msg.sender]
    assert (senderIsOwner or senderIsApprovedForAll)
    self.idToApprovals[_tokenId] = _approved
    log Approval(owner, _approved, _tokenId)


@external
def setApprovalForAll(_operator: address, _approved: bool):
    assert _operator != msg.sender
    self.ownerToOperators[msg.sender][_operator] = _approved
    log ApprovalForAll(msg.sender, _operator, _approved)

# Shouldn't need to use this function at all
@external
def mint(_to: address, _tokenId: uint256) -> bool:
    assert msg.sender == self.minter
    assert _to != ZERO_ADDRESS
    self._addTokenTo(_to, _tokenId)
    log Transfer(ZERO_ADDRESS, _to, _tokenId)
    return True


@external
def burn(_tokenId: uint256):
    assert self._isApprovedOrOwner(msg.sender, _tokenId)
    owner: address = self.idToOwner[_tokenId]
    assert owner != ZERO_ADDRESS
    self._clearApproval(owner, _tokenId)
    self._removeTokenFrom(owner, _tokenId)
    log Transfer(owner, ZERO_ADDRESS, _tokenId)

# End of ERC721 functions
    

@external
def addLandlord(addr: address):
    assert msg.sender == self.admin
    self.landlordList[addr] = True

@view
@external
def realLandlord(addr: address) -> bool:
    assert self.brokerList[msg.sender] == True, "Only a broker may request this information"
    return self.landlordList[addr]

@external
def addBroker(addr: address):
    assert msg.sender == self.admin
    self.brokerList[addr] = True

@view
@external
def realBroker(addr: address) -> bool:
    assert self.landlordList[msg.sender] == True, "Only a landlord may request this information"
    return self.brokerList[addr]

@external
def addProperty(_direction: String[50], _unit: String[10], _rent: uint256):
    assert self.landlordList[msg.sender] == True, "You are not a certified landlord"
    self.propertyLedger[self.propertyId] = Property({
        direction: _direction,
        unit: _unit,
        rent: _rent,
        owner: msg.sender,
        tenant: ZERO_ADDRESS,
        price: 0
    })
    self.propertyId += 1

@external
@view
def viewProperty(_propertyId: uint256) -> Property:
    return self.propertyLedger[_propertyId]

# Callable only by property owners already
@internal
def _mintProperty(_to: address, _tokenId: uint256) -> bool:
    assert _to != ZERO_ADDRESS
    self._addTokenTo(_to, _tokenId)
    log Transfer(ZERO_ADDRESS, _to, _tokenId)
    return True 

# PropertyId to Address and Percentage they own
propertyPercentage: HashMap[uint256, HashMap[address, uint256]]
# Whether property is up for sale by who and what percentage
propertyForSale: HashMap[uint256, HashMap[address, uint256]]
# There is a limit of 10 owners per property
propertyOwners: HashMap[uint256, address[10]]

@external
def makePropertySellable(_propertyId: uint256, _price: uint256, _percentage: uint256):
    assert self.propertyLedger[_propertyId].price == 0, "This property is already up for sale"
    assert self.propertyLedger[_propertyId].owner == msg.sender
    assert self.propertyLedger[_propertyId].tenant == ZERO_ADDRESS
    self._mintProperty(msg.sender, _propertyId)
    self.propertyLedger[_propertyId].price = _price
    self.propertyPercentage[_propertyId][msg.sender] = 100
    self.propertyForSale[_propertyId][msg.sender] = _percentage

@external
def sellPropertyPercentage(_propertyId: uint256, _percentage: uint256):
    assert self.propertyPercentage[_propertyId][msg.sender] >= _percentage, "You can't sell more than what you own"
    self.propertyForSale[_propertyId][msg.sender] = _percentage

@internal
def _propertyPerShareCost(_propertyId: uint256) -> uint256:
    currentPropertyPrice: uint256 = self.propertyLedger[_propertyId].price
    assert currentPropertyPrice > 0, "This property is not up for sale"
    return currentPropertyPrice / 100

# Will transfer ownership to the majority owner of property
# This will be called anytime part of a property are called
# Have to add caveat if there is a tie in ownership percentage
@internal
def _transferOwnership(_propertyId: uint256):
    currentOwner: address = self.propertyLedger[_propertyId].owner
    majorityOwner: address = ZERO_ADDRESS
    largestPercentage: uint256 = 0
    currentOwners: address[10] = self.propertyOwners[_propertyId]
    for i in range(0, 9):
        if currentOwners[i] != ZERO_ADDRESS:
            if self.propertyPercentage[_propertyId][currentOwners[i]] > largestPercentage:
                majorityOwner = currentOwners[i]
                largestPercentage = self.propertyPercentage[_propertyId][currentOwners[i]]
        elif currentOwners[i] == ZERO_ADDRESS:
            pass
    self._transferFrom(majorityOwner, currentOwner, _propertyId, currentOwner)

@internal
def _closingDistribution(_amount: uint256, _owner: address) -> uint256:
    earningsAsDecimal: decimal = convert(_amount, decimal)
    ownerEarnings: decimal = earningsAsDecimal * 0.97
    return convert(ownerEarnings, uint256)


@payable
@external
def buyProperty(_propertyId: uint256, _owner: address, _percentage: uint256):
    assert self.propertyForSale[_propertyId][_owner] >= _percentage, "This property is not for sale or you can't purchase more than it's being sold"
    assert self.propertyOwners[_propertyId][9] == ZERO_ADDRESS, "The limit for owners has been reached"
    assert msg.value >= as_wei_value(self._propertyPerShareCost(_propertyId) * _percentage, "ether") + APPLICATION_FEE
    for i in range(0, 9):
        if self.propertyOwners[_propertyId][i] == ZERO_ADDRESS:
            self.propertyOwners[_propertyId][i] = msg.sender
            self.propertyPercentage[_propertyId][_owner] -= _percentage
            self.propertyPercentage[_propertyId][msg.sender] += _percentage
    self._transferOwnership(_propertyId)
    ownerEarnings: uint256 = self._closingDistribution(msg.value, _owner)
    send(_owner, as_wei_value(ownerEarnings, "ether"))
    log EtherTransfer(msg.sender, self, msg.value)
    log EtherTransfer(self, _owner, ownerEarnings)
    

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
    assert self.agentLedger[agent] == broker, "This agent is not sponsored by this broker"
    return True

@payable
@external
def applyAsTenant(_propertyId: uint256, _startDate: uint256, _monthsFree: uint256, months: uint256):
    # Payment is two months up front(1st month rent and security deposit) + application fee
    # assert 2 * as_wei_value(self.propertyLedger[_propertyId].rent, "ether") + APPLICATION_FEE >= msg.value, "You must transfer enough to cover app fee and 1 month rent"
    assert msg.value >= (APPLICATION_FEE + (as_wei_value(self.propertyLedger[_propertyId].rent, "ether") * 2 )), "You must transfer enough to cover 2 months of rent and app fee"
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
    log EtherTransfer(msg.sender, self, msg.value)

@payable
@external
def applyAsBroker(_propertyId: uint256, _startDate: uint256, _monthsFree: uint256, months: uint256, _tenant: address, _brokerFee: uint256):
    property_owner: address = self.propertyLedger[_propertyId].owner
    assert self.brokerApprove[msg.sender][property_owner] == True, "You don't work with this landlord. Contact landlord for access"
    assert msg.value >= (APPLICATION_FEE + (as_wei_value(self.propertyLedger[_propertyId].rent, "ether") * 2 )), "This won't cover enough for app fee and two months of rent"
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
    log EtherTransfer(msg.sender, self, msg.value)

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
    
    log EtherTransfer(self, self.propertyLedger[_propertyId].owner, self.propertyLedger[_propertyId].rent)
    log LeaseApproved(self.propertyLedger[_propertyId].owner, self.applicationLedger[_propertyId].tenant, block.timestamp)

@external
def withdrawBrokerFee(_propertyId: uint256):
    property_application: Application = self.applicationLedger[_propertyId]
    assert property_application.broker == msg.sender
    assert property_application.brokerFee > 0, "Nothing to collect or already collected"
    assert property_application.approved == True
    assert property_application.startDate <= block.timestamp, "You can only withdraw funds once tenants have moved into their new unit"
    send(msg.sender, as_wei_value(property_application.brokerFee, "ether"))
    self.applicationLedger[_propertyId].brokerFee = 0
    log EtherTransfer(self, msg.sender, property_application.brokerFee)

@external
def withdrawSecurityDeposit(_propertyId: uint256):
    property_application: Application = self.applicationLedger[_propertyId]
    assert property_application.tenant == msg.sender, "You are either no the tenant or you already collected you security deposit"
    assert property_application.approved == True
    assert property_application.startDate + property_application.length <= block.timestamp, "You can only withdraw your deposit once you're lease is up"
    send(msg.sender, as_wei_value(self.propertyLedger[_propertyId].rent, "ether"))
    self.applicationLedger[_propertyId].tenant = ZERO_ADDRESS
    log EtherTransfer(self, msg.sender, self.propertyLedger[_propertyId].rent)


@external
def subletRental(_propertyId: uint256, _newTenant: address, _length: uint256):
    property_application: Application = self.applicationLedger[_propertyId]
    assert property_application.tenant == msg.sender
    assert property_application.approved == True
    assert property_application.startDate + property_application.length > block.timestamp + _length, "Sublease length must be less than the total time of original lease"
    self.subtenantLedger[_propertyId][_newTenant] = _length

@payable
@external
def payRent(_propertyId: uint256):
    assert self.propertyLedger[_propertyId].tenant == msg.sender or self.subtenantLedger[_propertyId][msg.sender] > 0, "You are not renting this unit or subleasing this unit"
    assert as_wei_value(self.propertyLedger[_propertyId].rent, "ether") <= msg.value, "You aren't sending enough to cover rent"
    send(self.propertyLedger[_propertyId].owner, as_wei_value(self.propertyLedger[_propertyId].rent, "ether"))
    log EtherTransfer(msg.sender, self.propertyLedger[_propertyId].owner, msg.value)
