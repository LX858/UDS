INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES
('scissors', 'Scissors', 1, 0, 1),
('scissors_dirty', 'Dirty scissors', 1, 0, 1),
('dirty_wine_bottle', 'Dirty wine bottle', 1, 0, 1),
('empty_wine_bottle', 'Empty wine bottle', 1, 0, 1),
('red_wine_grapes', 'Red grapes', 1, 0, 1),
('red_wine_prepared', 'Red grapes prepared', 1, 0, 1),
('red_wine_juice', 'Red pressed grapes', 1, 0, 1),
('red_wine_bottle', 'Red wine bottle', 1, 0, 1),
('red_wine_glass', 'Red wine glass', 1, 0, 1),
('white_wine_grapes', 'White grapes', 1, 0, 1),
('white_wine_prepared', 'White grapes prepared', 1, 0, 1),
('white_wine_juice', 'White pressed grapes', 1, 0, 1),
('white_wine_bottle', 'White wine bottle', 1, 0, 1),
('white_wine_glass', 'White wine glass', 1, 0, 1),
('rose_wine_grapes', 'Rose grapes', 1, 0, 1),
('rose_wine_prepared', 'Rose grapes prepared', 1, 0, 1),
('rose_wine_juice', 'Rose pressed grapes', 1, 0, 1),
('rose_wine_bottle', 'Rose wine bottle', 1, 0, 1),
('rose_wine_glass', 'Rose wine glass', 1, 0, 1),
('wine_glass', 'Wine glass', 1, 0, 1),
('empty_wine_bottle_labeled', 'Empty wine labeled bottle', 1, 0, 1),
('wine_label', 'Wine label', 1, 0, 1);

INSERT INTO `addon_account` (name, label, shared) VALUES
	('society_wine', 'wine', 1)
;

INSERT INTO `addon_inventory` (name, label, shared) VALUES
	('society_wine', 'wine', 1)
;

INSERT INTO `datastore` (name, label, shared) VALUES
	('society_wine', 'wine', 1)
;

INSERT INTO `jobs` (name, label) VALUES
	('wine', 'Winemaker')
;

INSERT INTO `job_grades` (job_name, grade, name, label, salary, skin_male, skin_female) VALUES
	('wine',0,'recruit','Recruit',120,'{}','{}'),
	('wine',1,'novice','Novice',240,'{}','{}'),
	('wine',2,'experienced','Experienced',360,'{}','{}'),
	('wine',3,'advanced',"Advanced",480,'{}','{}'),
	('wine',4,'manager',"Manager",480,'{}','{}'),
	('wine',5,'boss','Boss',500,'{}','{}')
;