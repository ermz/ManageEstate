import pytest
from brownie import ZERO_ADDRESS, accounts
import brownie

def test_apply_as_tenant(_estate_2, dom, ed, fin, huck):
    with brownie.reverts("You must transfer enough to cover 2 months of rent and app fee"):
        _estate_2.applyAsTenant(1, 21231242, 0, 12, {"from": huck, "value": "1 ether"})
    _estate_2.applyAsTenant(1, 123124124, 0, 12, {"from": huck, "value": "3 ether"})
    assert _estate_2.viewApplication(1, {"from": ed})["broker"] == ZERO_ADDRESS
    assert _estate_2.viewApplication(1, {"from": ed})["tenant"] == huck