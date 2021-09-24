import pytest
from brownie import ZERO_ADDRESS, accounts
import brownie

def test_apply_as_tenant(_estate_2, ed, huck):
    with brownie.reverts("You must transfer enough to cover 2 months of rent and app fee"):
        _estate_2.applyAsTenant(1, 21231242, 0, 12, {"from": huck, "value": "1 ether"})
    _estate_2.applyAsTenant(1, 123124124, 0, 12, {"from": huck, "value": "3 ether"})
    assert _estate_2.viewApplication(1, {"from": ed})["broker"] == ZERO_ADDRESS
    assert _estate_2.viewApplication(1, {"from": ed})["tenant"] == huck

def test_apply_as_broker(_estate_2, ed, fin, huck):
    with brownie.reverts("You don't work with this landlord. Contact landlord for access"):
        _estate_2.applyAsBroker(1, 123124124, 0, 12, huck, 1, {"from": huck})
    with brownie.reverts("This won't cover enough for app fee and two months of rent"):
        _estate_2.applyAsBroker(1, 12352312, 0, 12, huck, 1, {"from": fin, "value": "1 ether"})
    _estate_2.applyAsBroker(1, 1215123, 0, 12, huck, 1, {"from": fin, "value": "3 ether"})
    assert _estate_2.viewApplication(1, {"from": ed})["broker"] == fin
    assert _estate_2.viewApplication(1, {"from": ed})["brokerFee"] == 1

def test_approve_application(_estate_2, dom, ed, fin, huck):
    _estate_2.applyAsTenant(1, 5123412332, 0, 12, {"from": huck, "value": "3 ether"})
    with brownie.reverts("Only the property owner may approve this application"):
        _estate_2.approveApplication(1, {"from": fin})