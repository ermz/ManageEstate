# @version ^0.2.0

struct Property:
    direction: String[50]
    unit: String[10]
    rent: uint256
    owner: address

admin: address

landlordList: HashMap[address, bool]

@external
def __init__():
    self.admin = msg.sender

@external
def addLandlord(addr: address):
    assert msg.sender == self.admin
    self.landlordList[addr] = True

@external
def addProperty(_direction: String[50], _unit: String[10], _rent: uint256, _owner: address):
    assert self.landlordList[msg.sender] == True, "You are not a certified landlord"


