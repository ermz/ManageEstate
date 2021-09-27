import pytest
from brownie import ZERO_ADDRESS, chain, accounts
import brownie

def test_make_property_sellable(_estate_2, dom, ed, fin, gary, huck):
    with brownie.reverts("Only owner"):
        _estate_2.makePropertySellable(1, 5, 100, {"from": gary})
    original_ed_token_balance = _estate_2.balanceOf(ed)
    _estate_2.makePropertySellable(1, 5, 100, {"from": ed})
    assert _estate_2.balanceOf(ed) - 1 == original_ed_token_balance
    assert _estate_2.ownerOf(1) == ed
    with brownie.reverts("This property is already up for sale"):
        _estate_2.makePropertySellable(1, 5, 100, {"from": ed})

def test_make_property_sellable_with_tenant(_estate_3, dom, ed, fin, gary, huck):
    with brownie.reverts("Tenant occupied"):
        _estate_3.makePropertySellable(1, 5, 100, {"from": ed})
    with brownie.reverts("There is no owner yet"):
        _estate_3.ownerOf(1)
    assert _estate_3.balanceOf(ed) == 0

def test_property_percentage(_estate_2, dom, ed, fin, gary, huck):
    _estate_2.makePropertySellable(1, 5, 100, {"from": ed})
    with brownie.reverts("You can't sell more than what you own"):
        _estate_2.sellPropertyPercentage(1, 101, {"from": ed})