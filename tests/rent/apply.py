import pytest
from brownie import ZERO_ADDRESS, accounts, chain
import brownie
import time

def test_apply_as_tenant(_estate_2, ed, huck):
    with brownie.reverts("You must transfer enough to cover 2 months of rent and app fee"):
        _estate_2.applyAsTenant(1, 21231242, 0, 12, {"from": huck, "value": "1 ether"})
    original_huck_balance = huck.balance()
    _estate_2.applyAsTenant(1, 123124124, 0, 12, {"from": huck, "value": "3 ether"})
    assert original_huck_balance - "3 ether" == huck.balance()
    assert _estate_2.viewApplication(1, {"from": ed})["broker"] == ZERO_ADDRESS
    assert _estate_2.viewApplication(1, {"from": ed})["tenant"] == huck

def test_apply_as_broker(_estate_2, ed, fin, huck):
    with brownie.reverts("You don't work with this landlord. Contact landlord for access"):
        _estate_2.applyAsBroker(1, 123124124, 0, 12, huck, 1, {"from": huck})
    with brownie.reverts("This won't cover enough for app fee and two months of rent"):
        _estate_2.applyAsBroker(1, 12352312, 0, 12, huck, 1, {"from": fin, "value": "1 ether"})
    original_fin_balance = fin.balance()
    _estate_2.applyAsBroker(1, 1215123, 0, 12, huck, 1, {"from": fin, "value": "3 ether"})
    assert original_fin_balance - "3 ether" == fin.balance()
    assert _estate_2.viewApplication(1, {"from": ed})["broker"] == fin
    assert _estate_2.viewApplication(1, {"from": ed})["brokerFee"] == 1

def test_approve_application(_estate_2, dom, ed, fin, huck):
    _estate_2.applyAsTenant(1, 5123412332, 0, 12, {"from": huck, "value": "3 ether"})
    with brownie.reverts("Only the property owner may approve this application"):
        _estate_2.approveApplication(1, {"from": fin})
    assert _estate_2.viewApplication(1, {"from": ed})["approved"] == False
    original_contract_balance = _estate_2.balance()
    _estate_2.approveApplication(1, {"from": ed})
    assert _estate_2.viewApplication(1, {"from": ed})["approved"] == True
    assert original_contract_balance == _estate_2.balance() + "1 ether"

def test_sublet_rental(_estate_2, ed, fin, huck):
    _estate_2.applyAsTenant(1, (chain.time() + 86400), 0, 6, {"from": huck, "value": "3 ether"})
    with brownie.reverts("This property is not being rented by tenant"):
        _estate_2.subletRental(1, fin, 86400, {"from": huck})
    _estate_2.approveApplication(1, {"from": ed})
    with brownie.reverts("You are not the current tenant"):
        _estate_2.subletRental(1, fin, 86400, {"from": accounts[9]})
    chain.sleep(86401)
    _estate_2.subletRental(1, fin, 2, {"from": huck})

def test_invalid_sublet_rental(_estate_2, ed, fin, huck):
    _estate_2.applyAsTenant(1, (chain.time() + 86400), 0, 3, {"from": huck, "value": "3 ether"})
    _estate_2.approveApplication(1, {"from": ed})
    with brownie.reverts():
        _estate_2.subletRental(1, fin, 3_259_486, {"from": huck})
    chain.sleep(86401)
    _estate_2.subletRental(1, fin, 1, {"from": huck})