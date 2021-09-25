import pytest
from brownie import accounts, chain, ZERO_ADDRESS
import brownie
import time

# chain.sleep might not be necessary in this scenario
# There's nothing preventing users from paying before lease starts
def test_pay_rent(_estate_3, dom, ed, fin, gary):
    chain.sleep(86400)
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
    
    assert int(time.time()) > 1
