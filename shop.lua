local shop = {}

shop.items = {
    { id = "speed", name = "Speed Boost", price = 100, owned = false },
    { id = "shield", name = "Shield", price = 150, owned = false }
}

shop.coins = 0

function shop.addCoins(amount)
    shop.coins = shop.coins + amount
end

function shop.buy(id)
    for _, item in ipairs(shop.items) do
        if item.id == id and not item.owned and shop.coins >= item.price then
            shop.coins = shop.coins - item.price
            item.owned = true
            return true
        end
    end
    return false
end

return shop
