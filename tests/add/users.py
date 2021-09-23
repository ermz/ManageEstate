import pytest
from brownie import accounts
import brownie

def test_add_landlord(_manage_estate, alice, bob, chad):
    _manage_estate.addLandlord(bob, {"from": alice})
    with brownie.reverts("Only a broker may request this information"):
        _manage_estate.realLandlord(bob, {"from": chad})
    _manage_estate.addBroker(chad, {"from": alice})
    assert _manage_estate.realLandlord(bob, {"from": chad}) == True

def test_add_broker(_manage_estate, alice, bob, chad):
    _manage_estate.addBroker(chad, {"from": alice})
    with brownie.reverts("Only a landlord may request this information"):
        _manage_estate.realBroker(chad, {"from": bob})
    _manage_estate.addLandlord(bob, {"from": alice})
    assert _manage_estate.realBroker(chad, {"from": bob})
