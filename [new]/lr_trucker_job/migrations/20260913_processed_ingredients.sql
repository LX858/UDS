-- Run with lr_trucker_job and xn_banhnuoc STOPPED after all B2B missions finish.
-- Back up first. This script never converts inventory or rewrites history.
DELIMITER $$
DROP PROCEDURE IF EXISTS lr_trucker_migrate_processed_ingredients$$
CREATE PROCEDURE lr_trucker_migrate_processed_ingredients()
BEGIN
  IF EXISTS (SELECT 1 FROM lr_trucker_business_orders
      WHERE status IN ('reserving', 'in_transit'))
    OR EXISTS (SELECT 1 FROM lr_trucker_business_order_lines l
      JOIN lr_trucker_business_orders o ON o.id = l.order_id
      WHERE l.reservation_state IN ('reserved', 'settled') AND o.status <> 'delivered')
    OR EXISTS (SELECT 1 FROM lr_trucker_business_delivery_receipts r
      JOIN lr_trucker_business_orders o ON o.id = r.order_id WHERE o.status <> 'delivered') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'STOP: finish active B2B missions/import/settlement before migration';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE()
      AND table_name = 'lr_trucker_business_order_lines' AND column_name = 'destination_item_id') THEN
    ALTER TABLE lr_trucker_business_order_lines ADD COLUMN destination_item_id varchar(64) NULL DEFAULT NULL;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE()
      AND table_name = 'lr_trucker_business_order_lines' AND column_name = 'destination_label') THEN
    ALTER TABLE lr_trucker_business_order_lines ADD COLUMN destination_label varchar(96) NULL DEFAULT NULL;
  END IF;
  -- Only unassigned, unpaid-to-driver orders. NULL is the migration sentinel:
  -- rerunning never overwrites mappings locked by a newer config.
  UPDATE lr_trucker_business_order_lines l
    JOIN lr_trucker_business_orders o ON o.id = l.order_id
    SET l.destination_item_id = CASE l.item_id
      WHEN 'luami' THEN 'gao' WHEN 'coconut' THEN 'dua_soche' WHEN 'la_che' THEN 'tra_kho' END,
      l.destination_label = CASE l.item_id
      WHEN 'luami' THEN 'Gạo' WHEN 'coconut' THEN 'Dừa sơ chế' WHEN 'la_che' THEN 'Trà khô' END
    WHERE o.business_id IN ('restaurant_shop', 'bar') AND o.adapter = 'stash'
      AND o.status IN ('waiting_stock', 'available')
      AND COALESCE(o.team_id, '') = '' AND COALESCE(o.mission_id, '') = ''
      AND l.item_id IN ('luami', 'coconut', 'la_che')
      AND l.destination_item_id IS NULL;
END$$
CALL lr_trucker_migrate_processed_ingredients()$$
DROP PROCEDURE lr_trucker_migrate_processed_ingredients$$
DELIMITER ;
