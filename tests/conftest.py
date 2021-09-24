import pytest
from brownie import accounts, ManageEstate

@pytest.fixture()
def alice(accounts):
    return accounts[0]

@pytest.fixture()
def bob(accounts):
    return accounts[1]

@pytest.fixture()
def chad(accounts):
    return accounts[2]

@pytest.fixture()
def _manage_estate(alice):
    _manage_estate = ManageEstate.deploy({"from": alice})
    return _manage_estate

@pytest.fixture()
def dom(accounts):
    return accounts[3]

@pytest.fixture()
def ed(accounts):
    return accounts[4]

@pytest.fixture()
def fin(accounts):
    return accounts[5]

@pytest.fixture()
def gary(accounts):
    return accounts[6]

@pytest.fixture()
def huck(accounts):
    return accounts[7]

@pytest.fixture()
def _estate_2(dom, ed, fin , gary):
    _estate_2 = ManageEstate.deploy({"from": dom})
    _estate_2.addLandlord(ed, {"from": dom})
    _estate_2.addBroker(fin, {"from": dom})
    _estate_2.addProperty("7767 gray cedar", "5F", 1, {"from": ed})
    _estate_2.approveBroker(fin, {"from": ed})
    _estate_2.approveAgents(gary, {"from": fin})
    return _estate_2

