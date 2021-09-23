import pytest
from brownie import accounts
import brownie

def test_approve_broker(_manage_estate, alice, bob, chad):
    with brownie.reverts("You may only approve, certified brokers"):
        _manage_estate.approveBroker(bob)
    _manage_estate.addBroker(bob, {"from": alice})
    with brownie.reverts("You are not a certified landlord"):
        _manage_estate.approveBroker(bob, {"from": chad})
    _manage_estate.addLandlord(chad, {"from": alice})
    _manage_estate.approveBroker(bob, {"from": chad})

def test_approve_agents(_manage_estate, alice, bob, chad):
    with brownie.reverts("You are not a certified broker"):
        _manage_estate.approveAgents(chad, {"from": bob})
    _manage_estate.addBroker(bob, {"from": alice})
    _manage_estate.approveAgents(chad, {"from": bob})

def test_remove_agents(_manage_estate, alice, bob, chad):
    _manage_estate.addBroker(bob, {"from": alice})
    _manage_estate.approveAgents(chad, {"from": bob})
    with brownie.reverts("You can only remove your agents"):
        _manage_estate.removeAgents(alice, {"from": bob})
    _manage_estate.removeAgents(chad, {"from": bob})

def test_check_agent(_manage_estate, alice, bob, chad):
    _manage_estate.addBroker(bob, {"from": alice})
    _manage_estate.addLandlord(chad, {"from": alice})
    _manage_estate.addProperty("123 Northern Boulevadd", "2D", 2200, {"from": chad})
    with brownie.reverts("This broker does not have access to this unit"):
        _manage_estate.checkAgent(accounts[5], bob, 1)
    _manage_estate.approveBroker(bob, {"from": chad})
    with brownie.reverts("This agent is not sponsored by this broker"):
        _manage_estate.checkAgent(accounts[5], bob, 1)
    _manage_estate.approveAgents(accounts[5], {"from": bob})
    _manage_estate.checkAgent(accounts[5], bob, 1)
    
