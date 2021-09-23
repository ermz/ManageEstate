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

def test_add_property(_manage_estate, alice, bob):
    with brownie.reverts():
        _manage_estate.addProperty("1234 Parsons Ave", "5F", 1750, {"from": bob})
    _manage_estate.addLandlord(bob, {"from": alice})
    _manage_estate.addProperty("1234 Parsons Ave, Flushing, NYC 11354", "3F", 1800, {"from": bob}) == True
    assert _manage_estate.viewProperty(1)["direction"] == "1234 Parsons Ave, Flushing, NYC 11354"