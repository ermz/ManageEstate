import pytest
from brownie import accounts, ManageEstate

@pytest.fixture()
def alice():
    return accounts[0]

@pytest.fixture()
def _ManageEstate(alice):
    _ManageEstate = ManageEstate.deploy({"from": alice})
    return _ManageEstate