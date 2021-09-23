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

