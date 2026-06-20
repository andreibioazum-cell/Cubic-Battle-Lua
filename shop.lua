local shop = {}

shop.items = {
    { id = "speed_boost", name = "Speed Boost", price = 100, description = "Increase speed by 20%", owned = false },
    { id = "shield", name = "Shield", price = 150, description = "Temporary protection", owned = false },
    { id = "double_points", name = "Double Points", price = 120, description = "Earn 2x points", owned = false },
}

shop.currency = 0

function shop.addCurrency(amount)
    shop.currency = shop.currency + amount
end

function shop.buyItem(itemId)
    for i, item in ipairs(shop.items) do
        if item.id == itemId then
            if shop.currency >= item.price then
                shop.currency = shop.currency - item.price
                item.owned = true
                return true
            end
            return false
        end
    end
    return false
end

function shop.getOwnedItems()
    local owned = {}
    for i, item in ipairs(shop.items) do
        if item.owned then
            table.insert(owned, item)
        end
    end
    return owned
end

return shop
