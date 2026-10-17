Config.Billing = 'rlife_biling'
Config.BillingSociety = 'taxi'          
Config.BillingSocietyName = 'Ubee Taxi' 

Config.SendBill = function(src, p, d, r, label)
    if Config.Billing == 'rlife_biling' then 
        TriggerEvent('rlife_biling:CreateInvoiceFromServer', {
            target = src, invoice_item = label, invoice_value = r.price,
            author_identifier = d and d.id, author_name = d and d.name or 'Ubee',
            society = Config.BillingSociety, society_name = Config.BillingSocietyName,
            invoice_notes = ('Mã chuyến %s'):format(r.id),
        })
    elseif Config.Billing == 'billing' then 
        MySQL.insert('INSERT INTO billing (identifier, sender, target_type, target, label, amount) VALUES (?,?,?,?,?,?)',
            { p.id, d and d.id or 'ubee', 'player', d and d.id or 'ubee', label, r.price })
    elseif Config.Billing == 'phone_invoices' then 
        MySQL.insert('INSERT INTO phone_invoices (citizenid, amount, society, sender, sendercitizenid) VALUES (?,?,?,?,?)',
            { p.id, r.price, Config.BillingSociety, 'Ubee', d and d.id })
    end
end
