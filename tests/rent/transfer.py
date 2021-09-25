import pytest
from brownie import accounts, chain, ZERO_ADDRESS
import brownie
import time

# chain.sleep might not be necessary in this scenario
# There's nothing preventing users from paying before lease starts
def test_pay_rent(_estate_3, dom, ed, fin, gary):
    with brownie.reverts("You are not renting this unit or subleasing this unit"):
        _estate_3.payRent(1, {"from": fin, "value": "1 ether"})
    with brownie.reverts("You aren't sending enough to cover rent"):
        _estate_3.payRent(1, {"from": gary})
    original_gary_balance = gary.balance()
    _estate_3.payRent(1,{"from": gary, "value": "1 ether"})
    assert original_gary_balance - "1 ether" == gary.balance()

def test_subtenant_pay_rent(_estate_3, dom, ed, fin, gary):
    chain.sleep(86400)
    _estate_3.subletRental(1, accounts[9], 1, {"from": gary})
    original_account9_balance = accounts[9].balance()
    _estate_3.payRent(1, {"from": accounts[9], "value": "1 ether"})
    assert original_account9_balance - "1 ether" == accounts[9].balance()

def test_withdraw_broker_fee(_estate_3, dom, ed, fin, gary):
    with brownie.reverts("You are not the broker of this transaction"):
        _estate_3.withdrawBrokerFee(1, {"from": gary})
    with brownie.reverts("You can only withdraw funds once tenants have moved into their new unit"):
        _estate_3.withdrawBrokerFee(1, {"from": fin})
    chain.sleep(86401)
    original_broker_balance = fin.balance()
    _estate_3.withdrawBrokerFee(1, {"from": fin})
    assert original_broker_balance + "1 ether" == fin.balance()
    with brownie.reverts("Nothing to collect or already collected"):
        _estate_3.withdrawBrokerFee(1, {"from": fin})
    
def test_withdraw_unapproved_broker_fee(_estate_2, dom, ed, fin, gary):
    _estate_2.applyAsBroker(1, (chain.time() + 86400), 0, 4, gary, 1, {"from": fin, "value": "3 ether"})
    chain.sleep(86401)
    with brownie.reverts("This application hasn't been approved yet"):
        _estate_2.withdrawBrokerFee(1, {"from": fin})

def test_withdraw_security_deposit(_estate_3, dom, ed, fin, gary):
    with brownie.reverts("You are either no the tenant or you already collected you security deposit"):
        _estate_3.withdrawSecurityDeposit(1, {"from": fin})
    with brownie.reverts("You can only withdraw your deposit once you're lease is up"):
        _estate_3.withdrawSecurityDeposit(1, {"from": gary})
    original_gary_balance = gary.balance()
    chain.sleep(13_148_715)
    _estate_3.withdrawSecurityDeposit(1, {"from": gary})
    assert original_gary_balance + "1 ether" == gary.balance()
    with brownie.reverts("You are either no the tenant or you already collected you security deposit"):
        _estate_3.withdrawSecurityDeposit(1, {"from": gary})

def test_withdraw_security_deposit_unapproved(_estate_2, dom, ed, fin, gary):
    _estate_2.applyAsBroker(1, (chain.time() + 86400), 0, 4, gary, 1, {"from": fin, "value": "3 ether"})
    chain.sleep(13_148_715)
    with brownie.reverts("This application was never approved"):
        _estate_2.withdrawSecurityDeposit(1, {"from": gary})