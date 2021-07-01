
-- 1) Составить общее текстовое описание БД и решаемых ею задач;

/*
Описать модель хранения данных "птицефабрика".
Созданная база данных хранит самую важную часть информации и осуществляет взаимосвязь и контроль информации следующих
подразделений: родительские корпуса, яйцесклад, инкубаторий, площадки выращивания.
Родительские корпуса - корпуса, где происходит посадка птицы, которая со временем начинает давать яйцо.
Яйцесклад - подразделение, где получают яйцо от родительских корпусов, сортируют его (согласно требованиям/нормам) и
складируют.
Инкубаторий - подразделение, куда поступает яйцо с яйцесклада, сортируется (согласно требованиям/нормам), производится закладка
яйца, инкубация, вывод и сортировка цыплят, и производится посадка в корпуса на площадках выращивания.
Площадки выращивания - подразделения, где выращивают птицу до ее созревания и дальнейшего убоя.
База данных решает следующие задачи:
1) Хранение информации от всех подразделений
2) Удобное и доступное размещение информации
3) В дальнейшем удобное извлечениие информации и анализ данных
*/

-- 2) минимальное количество таблиц - 10;
-- 3) скрипты создания структуры БД (с первичными ключами, индексами, внешними ключами);

-- выполнение 2 и 3 заданий

/*
DROP DATABASE IF EXISTS chicken_factory;
CREATE DATABASE chicken_factory;
USE chicken_factory;

DROP TABLE IF EXISTS parent_buildings;
CREATE TABLE parent_buildings (
	id SERIAL PRIMARY KEY,
	parent_building_number TINYINT UNSIGNED NOT NULL COMMENT 'номер корпуса', -- корпусов примерно 10, на больших птицефабриках - до 20, но это зависит от содержания птицы (напольное или клеточное)
	total_chickens MEDIUMINT UNSIGNED NOT NULL COMMENT 'количество птицы было посажено в корпус',
	date_of_delivery DATE NOT NULL COMMENT 'дата посадки',	
	INDEX parent_buildings__parent_building_number_idx(parent_building_number)
) COMMENT = 'родительские корпуса';

DROP TABLE IF EXISTS info_about_parent_building;
CREATE TABLE info_about_parent_building (
	id SERIAL PRIMARY KEY,
	`current_date` DATE NOT NULL COMMENT 'текущая дата',
	day_of_growing SMALLINT UNSIGNED NOT NULL COMMENT 'день выращивания',
	chickens_dead SMALLINT UNSIGNED NOT NULL COMMENT 'количество птицы пало за 1 день',
	eggs_produced MEDIUMINT UNSIGNED DEFAULT 0 COMMENT 'яйца произведено за 1 день',
	feed_eaten DECIMAL(4,2) UNSIGNED DEFAULT 0 COMMENT 'корма съедено за 1 день (тонн)',
	water_drunk DECIMAL(4,2) UNSIGNED DEFAULT 0 COMMENT 'воды выпито за 1 день (тонн)',
	INDEX info_about_parent_building__current_date__eggs_produced__idx(`current_date`, eggs_produced)
) COMMENT = 'вся информации о жизни корпуса за каждый день';

DROP TABLE IF EXISTS parent_buildings__info_about_parent_building;
CREATE TABLE parent_buildings__info_about_parent_building (
	parent_buildings_id BIGINT UNSIGNED NOT NULL,
	info_about_parent_building_id BIGINT UNSIGNED NOT NULL,
	PRIMARY KEY(parent_buildings_id, info_about_parent_building_id),
	FOREIGN KEY(parent_buildings_id) REFERENCES parent_buildings(id) ON UPDATE CASCADE ON DELETE RESTRICT,
	FOREIGN KEY(info_about_parent_building_id) REFERENCES info_about_parent_building(id) ON UPDATE CASCADE ON DELETE RESTRICT
);

DROP TABLE IF EXISTS egg_storage;
CREATE TABLE egg_storage(
	info_about_parent_building_id SERIAL PRIMARY KEY,
	defect SMALLINT UNSIGNED NOT NULL COMMENT 'брак',
	total_eggs_after_sorting MEDIUMINT UNSIGNED COMMENT 'всего яйца после сортировки одного корпуса',
	INDEX e_s__i_a_p_b_id__t_e_a_s__idx(info_about_parent_building_id, total_eggs_after_sorting),
	FOREIGN KEY(info_about_parent_building_id) REFERENCES info_about_parent_building(id) ON UPDATE CASCADE ON DELETE RESTRICT
) COMMENT = 'яйцесклад';

-- инкубация длится 21 день, в связи с этим инкубатор делим на инкубатор_закладка и инкубатор_вывод (вывод цыплят)
DROP TABLE IF EXISTS info_incubator_laying;
CREATE TABLE info_incubator_laying (
	id SERIAL PRIMARY KEY,
	eggs_got_from_egg_storage MEDIUMINT UNSIGNED NOT NULL COMMENT 'яйца взято с яйцесклада для закладки',
	defect SMALLINT UNSIGNED NOT NULL COMMENT 'брак',
	laid_eggs_after_sorting MEDIUMINT UNSIGNED NULL COMMENT 'заложено яйца после сортировки',
	INDEX info_incubator_laying__defect__laid_eggs_after_sorting__idx(defect, laid_eggs_after_sorting)
) COMMENT = 'подробная информация при закладке яйца в инкубатории';

-- необходима связь м-м, так как очень часто случается, когда берут не все яйцо за одну дату. оставшееся яйцо забирают на 
-- следующий день. здесь такое не реализовал, чтобы не запутать себя и Вас
DROP TABLE IF EXISTS egg_storage__info_incubator_laying;
CREATE TABLE egg_storage__info_incubator_laying (
	info_about_parent_building_id BIGINT UNSIGNED NOT NULL,
	info_incubator_laying_id BIGINT UNSIGNED NOT NULL,
	PRIMARY KEY (info_about_parent_building_id, info_incubator_laying_id),
	FOREIGN KEY (info_about_parent_building_id) REFERENCES egg_storage(info_about_parent_building_id),
	FOREIGN KEY (info_incubator_laying_id) REFERENCES info_incubator_laying(id)
);

DROP TABLE IF EXISTS incubator_laying;
CREATE TABLE incubator_laying (
	id SERIAL PRIMARY KEY,
	batch_number SMALLINT UNSIGNED NOT NULL COMMENT 'номер партии',
	date_of_laying DATE DEFAULT (CURRENT_DATE) NOT NULL COMMENT 'дата закладки',
	total_chicken_hatch MEDIUMINT UNSIGNED NULL COMMENT 'всего цыплят получено',
	INDEX incubator_laying__batch_number__date_of_laying_idx(batch_number, date_of_laying)
) COMMENT = 'инкубатор при закладке яйца';

DROP TABLE IF EXISTS info_incubator_laying__incubator_laying;
CREATE TABLE info_incubator_laying__incubator_laying (
	info_incubator_laying_id BIGINT UNSIGNED NOT NULL,
	incubator_laying_id BIGINT UNSIGNED NOT NULL,
	PRIMARY KEY (info_incubator_laying_id, incubator_laying_id),
	FOREIGN KEY (info_incubator_laying_id) REFERENCES info_incubator_laying(id),
	FOREIGN KEY (incubator_laying_id) REFERENCES incubator_laying(id)
);

DROP TABLE IF EXISTS info_incubator_hatch;
CREATE TABLE info_incubator_hatch (
	id SERIAL PRIMARY KEY,
	chicken_hatch MEDIUMINT UNSIGNED NOT NULL COMMENT 'цыплят получено',
	average_chicken_weight DECIMAL(3,1) UNSIGNED NOT NULL COMMENT 'средний вес цыплят',
	FOREIGN KEY (id) REFERENCES info_incubator_laying(id)
) COMMENT = 'подробная информация при выводе цыплят в инкубатории';

DROP TABLE IF EXISTS autopsy;
CREATE TABLE autopsy (
	id SERIAL PRIMARY KEY,
	unfertilized DECIMAL(3,1) UNSIGNED NULL COMMENT 'неоплод (%)',
	death_day_one_two DECIMAL(3,1) UNSIGNED NULL COMMENT 'гибель на 1-2 сутки (%)',
	blood_ring DECIMAL(3,1) UNSIGNED NULL COMMENT 'кровь кольцо (%)',
	frozen DECIMAL(3,1) UNSIGNED NULL COMMENT 'замершие (%)',
	tyke DECIMAL(3,1) UNSIGNED NULL COMMENT 'задохлики (%)',
	weak_and_cripple DECIMAL(3,1) UNSIGNED NULL COMMENT 'слабые и калеки (%)',
	freak DECIMAL(3,1) UNSIGNED NULL COMMENT 'урод (%)',
	rotten DECIMAL(3,1) UNSIGNED NULL COMMENT 'тумак (%)',
	cracked DECIMAL(3,1) UNSIGNED NULL COMMENT 'насечка (%)',
	FOREIGN KEY (id) REFERENCES info_incubator_hatch(id)
) COMMENT = 'вскрытие контрольных лотков'; -- производится вскрытие каждого корпуса в партии, а иногда и одного корпуса несколько раз

DROP TABLE IF EXISTS info_about_chicken_laying;
CREATE TABLE info_about_chicken_laying (
	id SERIAL PRIMARY KEY,
	number_of_place TINYINT UNSIGNED NOT NULL COMMENT 'номер площадки',
	parent_building_number TINYINT UNSIGNED NOT NULL COMMENT 'номер корпуса',
	date_of_delivery DATE DEFAULT (CURRENT_DATE) NOT NULL COMMENT 'дата посадки',
	chickens_delivered MEDIUMINT UNSIGNED NOT NULL COMMENT 'цыплят посажено',
	average_chicken_weight DECIMAL(3,1) UNSIGNED NOT NULL COMMENT 'средний вес цыплят',
	INDEX number_of_place__parent_building_number__date_of_delivery_idx(number_of_place, parent_building_number, date_of_delivery)
) COMMENT = 'информация о посадке цыплят';

-- необходима связь м-м, так как очень часто случается, когда посадка цыплят происходит на несколько корпусов. здесь такое не реализовал, чтобы не запутать себя и Вас
DROP TABLE IF EXISTS info_incubator_laying__info_about_chicken_laying;
CREATE TABLE info_incubator_laying__info_about_chicken_laying (
	info_incubator_laying_id BIGINT UNSIGNED NOT NULL,
	info_about_chicken_laying_id BIGINT UNSIGNED NOT NULL,
	PRIMARY KEY (info_incubator_laying_id, info_about_chicken_laying_id),
	FOREIGN KEY (info_incubator_laying_id) REFERENCES info_incubator_laying(id),
	FOREIGN KEY (info_about_chicken_laying_id) REFERENCES info_about_chicken_laying(id)
);

DROP TABLE IF EXISTS live_chicken_of_building;
CREATE TABLE live_chicken_of_building (
	id SERIAL PRIMARY KEY,
	`current_date` DATE DEFAULT (CURRENT_DATE) NOT NULL COMMENT 'текущая дата',
	chickens_dead SMALLINT UNSIGNED NOT NULL COMMENT 'количество птицы пало за 1 день',
	average_weight_growth DECIMAL(5,1) NOT NULL COMMENT 'средний прирост/потеря веса',
	feed_eaten DECIMAL(4,2) UNSIGNED NULL COMMENT 'корма съедено за 1 день (тонн)',
	water_drunk DECIMAL(4,2) UNSIGNED NULL COMMENT 'воды выпито за 1 день (тонн)',
	INDEX id__average_weight_growth_idx(id, average_weight_growth)
) COMMENT = 'вся информации о жизни корпуса за каждый день';

DROP TABLE IF EXISTS info_about_chicken_laying__live_chicken_of_building;
CREATE TABLE info_about_chicken_laying__live_chicken_of_building (
	info_about_chicken_laying_id BIGINT UNSIGNED NOT NULL,
	live_chicken_of_building_id BIGINT UNSIGNED NOT NULL,
	PRIMARY KEY (info_about_chicken_laying_id, live_chicken_of_building_id),
	FOREIGN KEY (info_about_chicken_laying_id) REFERENCES info_about_chicken_laying(id),
	FOREIGN KEY (live_chicken_of_building_id) REFERENCES live_chicken_of_building(id)
);
*/

-- 4) создать ERDiagram для БД;

-- создал и прикрепил

-- 8) хранимые процедуры / триггеры;
/*
DROP TRIGGER IF EXISTS insert_parent_buildings;
DELIMITER //
//
CREATE TRIGGER insert_parent_buildings
BEFORE INSERT 
ON parent_buildings FOR EACH ROW 
BEGIN 
	IF NEW.parent_building_number IS NULL THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Необходимо заполнить: parent_building_number';
	ELSEIF NEW.total_chickens IS NULL THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Необходимо заполнить: total_chickens';
	ELSEIF NEW.date_of_delivery IS NULL THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Необходимо заполнить: date_of_delivery';
	END IF;	
END//
DELIMITER ;
*/
/*
-- проверка работы триггера
INSERT INTO parent_buildings (total_chickens, date_of_delivery) VALUES
	(5000, '2021-02-01');

INSERT INTO parent_buildings (parent_building_number, date_of_delivery) VALUES
	(1, '2021-02-01');

INSERT INTO parent_buildings (parent_building_number, total_chickens) VALUES
	(1, 5000);
*/
/*
DROP TRIGGER IF EXISTS insert_info_about_parent_building;
DELIMITER //
//
CREATE TRIGGER insert_info_about_parent_building
BEFORE INSERT 
ON info_about_parent_building FOR EACH ROW 
BEGIN 
	IF NEW.`current_date` IS NULL THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Необходимо заполнить: current_date';
	ELSEIF NEW.day_of_growing IS NULL THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Необходимо заполнить: day_of_growing';
	ELSEIF NEW.chickens_dead IS NULL THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Необходимо заполнить: chickens_dead';
	END IF;
END//
DELIMITER ;
*/
/*
-- проверка работы триггера
INSERT INTO info_about_parent_building (day_of_growing, chickens_dead) VALUES
	(49, 1);

INSERT INTO info_about_parent_building (`current_date`, chickens_dead) VALUES
	('2021-03-22', 1);

INSERT INTO info_about_parent_building (`current_date`, day_of_growing) VALUES
	('2021-03-22', 49);
*/

/* Я не знаю почему, но процедура только так работает. Я пытался избавиться от DECLARE и внести в запрос и вставку
 * last_insert_id(), но как только я это делаю, процедура срабатывает 1 раз и потом выдает все значения NULL. Подскажите в
 * чем причина и как можно красиво все сократить и оформить? */
/*
DROP PROCEDURE IF EXISTS sp_insert_egg_storage;
DELIMITER //
//
CREATE PROCEDURE sp_insert_egg_storage(defect SMALLINT UNSIGNED)
BEGIN
	
	DECLARE proced_total_eggs_after_sorting MEDIUMINT UNSIGNED;
	
	START TRANSACTION;
	
	INSERT INTO egg_storage(defect) VALUES
		(defect);
	
	SET @num := last_insert_id();
	
	SET proced_total_eggs_after_sorting = (SELECT iapb.eggs_produced - es.defect
								FROM info_about_parent_building iapb
								JOIN egg_storage es ON es.info_about_parent_building_id = iapb.id 
								WHERE iapb.id = @num);
							
	UPDATE egg_storage es SET
		total_eggs_after_sorting = proced_total_eggs_after_sorting
	WHERE
		info_about_parent_building_id = @num;
	COMMIT;
END//
DELIMITER ;
*/
-- в 5 пункте использую эту процедуру
/*
DROP PROCEDURE IF EXISTS sp_insert_info_incubator_laying;
DELIMITER //
//
CREATE PROCEDURE sp_insert_info_incubator_laying(eggs_got_from_egg_storage MEDIUMINT UNSIGNED,
													defect SMALLINT UNSIGNED)
BEGIN
	
	DECLARE proced_laid_eggs_after_sorting MEDIUMINT UNSIGNED;
	
	SET proced_laid_eggs_after_sorting = eggs_got_from_egg_storage - defect;

	INSERT INTO info_incubator_laying(eggs_got_from_egg_storage, defect, laid_eggs_after_sorting) VALUES
		(eggs_got_from_egg_storage, defect, proced_laid_eggs_after_sorting);
	
END//
DELIMITER ;
*/

-- проверка работы процедуры
/*
CALL sp_insert_info_incubator_laying (4900, 50);
CALL sp_insert_info_incubator_laying (4900, 50);
CALL sp_insert_info_incubator_laying (4900, 50);
CALL sp_insert_info_incubator_laying (4900, 50);
CALL sp_insert_info_incubator_laying (4900, 50);
*/

-- 5) скрипты наполнения БД данными;

/*
INSERT INTO parent_buildings (parent_building_number, total_chickens, date_of_delivery) VALUES
	(1, 5000, '2021-02-01'),
	(5, 5000, '2021-02-01'),
	(7, 10000, '2021-02-02');

INSERT INTO info_about_parent_building (`current_date`, day_of_growing, chickens_dead, eggs_produced, feed_eaten, water_drunk) VALUES
	('2021-03-22', 49, 1, 5000, 3.22, 1.05),
	('2021-03-23', 50, 3, 5000, 3.12, 1.17),
	('2021-03-24', 51, 6, 5000, 3.05, 1.13),
	('2021-03-25', 52, 0, 5000, 3.11, 1.09),
	('2021-03-26', 53, 0, 5000, 3.15, 1.14),
	('2021-03-22', 49, 7, 5000, 3.18, 1.14),
	('2021-03-23', 50, 3, 5000, 3.13, 1.05),
	('2021-03-24', 51, 0, 5000, 3.16, 1.09),
	('2021-03-25', 52, 1, 5000, 3.14, 1.05),
	('2021-03-26', 53, 4, 5000, 3.20, 1.16),
	('2021-03-22', 49, 1, 10000, 3.09, 1.11),
	('2021-03-23', 50, 3, 10000, 3.13, 1.14),
	('2021-03-24', 51, 6, 10000, 3.15, 1.09),
	('2021-03-25', 52, 0, 10000, 3.12, 1.13),
	('2021-03-26', 53, 0, 10000, 3.08, 1.15);

INSERT INTO parent_buildings__info_about_parent_building (parent_buildings_id, info_about_parent_building_id) VALUES
	(1, 1),
	(1, 2),
	(1, 3),
	(1, 4),
	(1, 5),
	(2, 6),
	(2, 7),
	(2, 8),
	(2, 9),
	(2, 10),
	(3, 11),
	(3, 12),
	(3, 13),
	(3, 14),
	(3, 15);

CALL sp_insert_egg_storage(100);
CALL sp_insert_egg_storage(100);
CALL sp_insert_egg_storage(100);
CALL sp_insert_egg_storage(100);
CALL sp_insert_egg_storage(100);

INSERT INTO egg_storage (defect, total_eggs_after_sorting) VALUES
	(100, 4900),
	(100, 4900),
	(100, 4900),
	(100, 4900),
	(100, 4900),
	(200, 9900),
	(200, 9900),
	(200, 9900),
	(200, 9900),
	(200, 9900);

INSERT INTO info_incubator_laying (eggs_got_from_egg_storage, defect, laid_eggs_after_sorting) VALUES
	(4900, 50, 4850),
	(4900, 50, 4850),
	(4900, 50, 4850),
	(4900, 50, 4850),
	(4900, 50, 4850),
	(9900, 100, 9800),
	(9900, 100, 9800),
	(9900, 100, 9800),
	(9900, 100, 9800),
	(9900, 100, 9800);

INSERT INTO egg_storage__info_incubator_laying (info_about_parent_building_id, info_incubator_laying_id) VALUES
	(1, 1),
	(2, 2),
	(3, 3),
	(4, 4),
	(5, 5),
	(6, 6),
	(7, 7),
	(8, 8),
	(9, 9),
	(10, 10),
	(11, 11),
	(12, 12),
	(13, 13),
	(14, 14),
	(15, 15);

INSERT INTO incubator_laying (batch_number, date_of_laying, total_chicken_hatch) VALUES
	(1,'2021-03-24', 18500),
	(2,'2021-03-25', 18500),
	(3,'2021-03-26', 18500),
	(4,'2021-03-27', 18500),
	(5,'2021-03-28', 18500);

INSERT INTO info_incubator_laying__incubator_laying (info_incubator_laying_id, incubator_laying_id) VALUES
	(1, 1),
	(2, 2),
	(3, 3),
	(4, 4),
	(5, 5),
	(6, 1),
	(7, 2),
	(8, 3),
	(9, 4),
	(10, 5),
	(11, 1),
	(12, 2),
	(13, 3),
	(14, 4),
	(15, 5);

INSERT INTO info_incubator_hatch (chicken_hatch, average_chicken_weight) VALUES
	(4500, 37.1),
	(4500, 36.5),
	(4500, 36.9),
	(4500, 36.7),
	(4500, 36.4),
	(4500, 36.7),
	(4500, 36.9),
	(4500, 37.0),
	(4500, 37.1),
	(4500, 36.8),
	(9500, 36.8),
	(9500, 37.0),
	(9500, 36.9),
	(9500, 36.7),
	(9500, 36.9);

INSERT INTO autopsy (unfertilized, death_day_one_two, blood_ring, frozen, tyke, weak_and_cripple, freak, rotten, cracked) VALUES
	(4.3, 1.4, 1.1, 0.5, 1.1, 1.6, 0.2, 0.2, 0.5),
	(4.0, 1.1, 1.4, 0.4, 0.9, 1.4, 0.3, 0.4, 0.2),
	(4.1, 1.3, 1.3, 0.8, 1.0, 1.4, 0.5, 0.4, 0.3),
	(4.5, 1.2, 1.5, 0.5, 1.4, 1.5, 0.4, 0.3, 0.5),
	(4.2, 1.5, 1.2, 0.4, 1.2, 1.2, 0.3, 0.2, 0.4),	
	(3.9, 1.2, 1.1, 0.4, 1.2, 1.5, 0.0, 0.4, 0.0),
	(4.1, 1.3, 1.3, 0.6, 1.3, 1.7, 0.1, 0.3, 0.2),
	(3.8, 1.6, 1.4, 0.5, 1.4, 1.4, 0.3, 0.5, 0.3),
	(4.4, 1.4, 1.2, 0.3, 1.2, 1.5, 0.2, 0.3, 0.4),
	(4.6, 1.5, 1.5, 0.6, 1.8, 1.6, 0.5, 0.4, 0.2),
	(4.4, 1.3, 1.2, 0.7, 1.2, 1.9, 0.3, 0.4, 0.1),
	(4.1, 1.1, 1.4, 0.6, 1.0, 1.5, 0.1, 0.1, 0.3),
	(4.5, 1.2, 1.5, 0.1, 1.6, 1.1, 0.4, 0.5, 0.0),
	(3.9, 1.4, 1.3, 0.4, 1.4, 1.8, 0.6, 0.7, 0.1),
	(3.5, 1.3, 1.1, 0.5, 1.5, 1.6, 0.2, 0.2, 0.5);

INSERT INTO info_about_chicken_laying (number_of_place, parent_building_number, date_of_delivery, chickens_delivered, average_chicken_weight) VALUES
	(1, 5, '2021-03-24', 18500, 37.3),
	(1, 6, '2021-03-25', 18500, 37.5),
	(3, 11, '2021-03-26', 18500, 37.6),
	(3, 12, '2021-03-27', 18500, 37.4),
	(3, 13, '2021-03-28', 18500, 37.5);

INSERT INTO info_incubator_laying__info_about_chicken_laying (info_incubator_laying_id, info_about_chicken_laying_id) VALUES
	(1, 1),
	(2, 2),
	(3, 3),
	(4, 4),
	(5, 5),
	(6, 1),
	(7, 2),
	(8, 3),
	(9, 4),
	(10, 5),
	(11, 1),
	(12, 2),
	(13, 3),
	(14, 4),
	(15, 5);

INSERT INTO live_chicken_of_building (`current_date`, chickens_dead, average_weight_growth, feed_eaten, water_drunk) VALUES
	('2021-03-25', 3, -6.3, 0.75, 0.65),
	('2021-03-26', 7, -1.5, 0.78, 0.66),
	('2021-03-27', 5, 2.7, 0.80, 0.68),
	('2021-03-28', 4, 8.8, 0.84, 0.69),
	('2021-03-29', 4, 12.4, 0.87, 0.71),
	('2021-03-25', 4, -4.3, 0.74, 0.63),
	('2021-03-26', 10, -2.5, 0.77, 0.63),
	('2021-03-27', 9, 2.6, 0.79, 0.65),
	('2021-03-28', 4, 5.8, 0.82, 0.67),
	('2021-03-29', 5, 10.3, 0.84, 0.70),
	('2021-03-25', 12, -8.3, 0.70, 0.60),
	('2021-03-26', 19, -5.5, 0.69, 0.59),
	('2021-03-27', 10, -1.7, 0.70, 0.60),
	('2021-03-28', 8, 4.8, 0.74, 0.62),
	('2021-03-29', 5, 8.2, 0.77, 0.65),
	('2021-03-25', 7, -2.1, 0.78, 0.69),
	('2021-03-26', 5, 1.9, 0.79, 0.69),
	('2021-03-27', 6, 10.7, 0.82, 0.70),
	('2021-03-28', 3, 15.8, 0.86, 0.71),
	('2021-03-29', 0, 20.1, 0.89, 0.72),
	('2021-03-25', 6, -0.9, 0.72, 0.61),
	('2021-03-26', 4, 0.3, 0.76, 0.64),
	('2021-03-27', 8, 0.5, 0.77, 0.65),
	('2021-03-28', 10, 5.1, 0.77, 0.66),
	('2021-03-29', 15, 9.4, 0.78, 0.67);

INSERT INTO info_about_chicken_laying__live_chicken_of_building (info_about_chicken_laying_id, live_chicken_of_building_id) VALUES
	(1, 1),
	(1, 2),
	(1, 3),
	(1, 4),
	(1, 5),
	(2, 6),
	(2, 7),
	(2, 8),
	(2, 9),
	(2, 10),
	(3, 11),
	(3, 12),
	(3, 13),
	(3, 14),
	(3, 15),
	(4, 16),
	(4, 17),
	(4, 18),
	(4, 19),
	(4, 20),
	(5, 21),
	(5, 22),
	(5, 23),
	(5, 24),
	(5, 25);
*/

-- 6) скрипты характерных выборок (включающие группировки, JOIN'ы, вложенные таблицы);

/*
-- запрос для получения всей информации о родительском корпусе
SELECT
	pb.parent_building_number,
	pb.total_chickens,
	SUM(iapb.chickens_dead) AS sum_chickens_dead,
	SUM(iapb.eggs_produced) AS sum_eggs_produced,
	SUM(es.defect) AS sum_defect,
	SUM(es.total_eggs_after_sorting) AS sum_total_eggs_after_sorting,
	SUM(iil.defect) AS sum_defect,
	SUM(iil.laid_eggs_after_sorting) AS sum_laid_eggs_after_sorting,
	SUM(iih.chicken_hatch) AS sum_chicken_hatch
FROM parent_buildings pb 
JOIN parent_buildings__info_about_parent_building pbiapb ON pbiapb.parent_buildings_id = pb.id 
JOIN info_about_parent_building iapb ON iapb.id = pbiapb.info_about_parent_building_id 
JOIN egg_storage es ON es.info_about_parent_building_id = iapb.id
JOIN egg_storage__info_incubator_laying esiil ON esiil.info_about_parent_building_id = es.info_about_parent_building_id
JOIN info_incubator_laying iil ON iil.id = esiil.info_incubator_laying_id 
JOIN info_incubator_hatch iih ON iih.id = iil.id
WHERE pb.parent_building_number = 1;

-- запрос о получении всей информации о вскрытии яйца с определенного корпуса за определенный период
SELECT
	pb.parent_building_number,
	AVG(a.unfertilized) AS avg_unfertilized,
	AVG(a.death_day_one_two) AS avg_death_day_one_two,
	AVG(a.blood_ring) AS avg_blood_ring,
	AVG(a.frozen) AS avg_frozen,
	AVG(a.tyke) AS avg_tyke,
	AVG(a.weak_and_cripple) AS avg_weak_and_cripple,
	AVG(a.freak) AS avg_freak,
	AVG(a.rotten) AS avg_rotten,
	AVG(a.cracked) AS avg_cracked
FROM parent_buildings pb 
JOIN parent_buildings__info_about_parent_building pbiapb ON pbiapb.parent_buildings_id = pb.id 
JOIN info_about_parent_building iapb ON iapb.id = pbiapb.info_about_parent_building_id 
JOIN egg_storage es ON es.info_about_parent_building_id = iapb.id
JOIN egg_storage__info_incubator_laying esiil ON esiil.info_about_parent_building_id = es.info_about_parent_building_id
JOIN info_incubator_laying iil ON iil.id = esiil.info_incubator_laying_id 
JOIN info_incubator_hatch iih ON iih.id = iil.id
JOIN autopsy a ON a.id = iih.id 
WHERE pb.parent_building_number = 1 AND iapb.`current_date` > '2021-03-22' AND iapb.`current_date` < '2021-03-24';

-- запрос о получении всей информации о выращивании с определенного корпуса
SELECT 
	iacl.number_of_place,
	iacl.parent_building_number,
	iacl.date_of_delivery,
	iacl.chickens_delivered,
	iacl.average_chicken_weight,
	SUM(lcob.chickens_dead) AS sum_chickens_dead,
	SUM(lcob.average_weight_growth) AS sum_average_weight_growth,
	SUM(lcob.feed_eaten) AS sum_feed_eaten,
	SUM(lcob.water_drunk) AS sum_water_drunk
FROM info_about_chicken_laying iacl 
JOIN info_about_chicken_laying__live_chicken_of_building iacllcob ON iacllcob.info_about_chicken_laying_id = iacl.id
JOIN live_chicken_of_building lcob ON lcob.id = iacllcob.live_chicken_of_building_id
WHERE iacl.parent_building_number = 5;

-- сколько цыплят выдала площадка за год
SELECT 
	iacl.number_of_place,
	SUM(iacl.chickens_delivered) AS total_chickens_delivered,
	SUM(lcob.chickens_dead) AS total_chickens_dead,
	SUM(iacl.chickens_delivered) - SUM(lcob.chickens_dead) AS total_chicken
FROM info_about_chicken_laying iacl 
JOIN info_about_chicken_laying__live_chicken_of_building iacllcob ON iacllcob.info_about_chicken_laying_id = iacl.id
JOIN live_chicken_of_building lcob ON lcob.id = iacllcob.live_chicken_of_building_id
WHERE iacl.number_of_place = 1 AND iacl.date_of_delivery > '2021-01-01' AND iacl.date_of_delivery < '2022-01-01';

-- вся информация о яйце за год (родительская площадка и яйцесклад)
SELECT
	SUM(iapb.eggs_produced) AS total_eggs_produced,
	SUM(es.defect) AS total_defect,
	SUM(es.total_eggs_after_sorting) AS total_eggs_after_sorting
FROM parent_buildings pb
JOIN parent_buildings__info_about_parent_building pbiapb ON pbiapb.parent_buildings_id = pb.id 
JOIN info_about_parent_building iapb ON iapb.id = pbiapb.info_about_parent_building_id 
JOIN egg_storage es ON es.info_about_parent_building_id = iapb.id
WHERE iapb.`current_date` > '2021-01-01' AND iapb.`current_date` < '2022-01-01';

-- вся информация о яйце за год (инкубатор)
SELECT
	SUM(iil.eggs_got_from_egg_storage) AS total_eggs_got_from_egg_storage,
	SUM(iil.defect) AS total_defect,
	SUM(iil.laid_eggs_after_sorting) AS total_laid_eggs_after_sorting
FROM incubator_laying il
JOIN info_incubator_laying__incubator_laying iilil ON iilil.incubator_laying_id = il.id 
JOIN info_incubator_laying iil ON iil.id = iilil.info_incubator_laying_id 
WHERE DATE_ADD(il.date_of_laying, INTERVAL 21 DAY) > '2021-01-01' AND DATE_ADD(il.date_of_laying, INTERVAL 21 DAY) < '2022-01-01';
-- в условии к дате закладки прибавляем 21 день для поправки на время инкубации (21 день инкубации)
*/

-- 7) представления (минимум 2);

/*
CREATE OR REPLACE VIEW v_total_info_parent_buildings AS 
SELECT 
	pb.parent_building_number,
	pb.total_chickens,
	pb.date_of_delivery,
	iapb.`current_date`,
	iapb.day_of_growing,
	iapb.chickens_dead,
	iapb.eggs_produced,
	iapb.feed_eaten,
	iapb.water_drunk,
	es.defect,
	es.total_eggs_after_sorting 
FROM parent_buildings pb
JOIN parent_buildings__info_about_parent_building pbiapb ON pbiapb.parent_buildings_id = pb.id 
JOIN info_about_parent_building iapb ON iapb.id = pbiapb.info_about_parent_building_id 
JOIN egg_storage es ON es.info_about_parent_building_id = iapb.id;

-- узнаю информацию по родительскому корпусу за каждый день
SELECT * FROM v_total_info_parent_buildings vtipb WHERE parent_building_number = 5 AND date_of_delivery = '2021-02-01';

CREATE OR REPLACE VIEW v_total_info_incubator AS
SELECT
	pb.parent_building_number,
	il.batch_number,
	il.date_of_laying,
	iil.eggs_got_from_egg_storage,
	iil.defect,
	iil.laid_eggs_after_sorting,
	iih.chicken_hatch,
	iih.average_chicken_weight 
FROM parent_buildings pb 
JOIN parent_buildings__info_about_parent_building pbiapb ON pbiapb.parent_buildings_id = pb.id 
JOIN info_about_parent_building iapb ON iapb.id = pbiapb.info_about_parent_building_id 
JOIN egg_storage es ON es.info_about_parent_building_id = iapb.id
JOIN egg_storage__info_incubator_laying esiil ON esiil.info_about_parent_building_id = es.info_about_parent_building_id
JOIN info_incubator_laying iil ON iil.id = esiil.info_incubator_laying_id 
JOIN info_incubator_hatch iih ON iih.id = iil.id
JOIN info_incubator_laying__incubator_laying iilil ON iilil.info_incubator_laying_id = iil.id 
JOIN incubator_laying il ON il.id = iilil.incubator_laying_id;

-- узнаю основные показатели за определенну партию и корпус
SELECT * FROM v_total_info_incubator vtii WHERE parent_building_number = 7 AND batch_number = 3;

CREATE OR REPLACE VIEW v_total_info_about_chicken_laying AS
SELECT
	iacl.parent_building_number,  
	iacl.date_of_delivery,
	iacl.chickens_delivered,
	iacl.average_chicken_weight,
	DATEDIFF(lcob.`current_date`, iacl.date_of_delivery) AS day_of_growing,
	lcob.chickens_dead,
	lcob.average_weight_growth 
FROM info_about_chicken_laying iacl
JOIN info_about_chicken_laying__live_chicken_of_building iacllcob ON iacllcob.info_about_chicken_laying_id = iacl.id
JOIN live_chicken_of_building lcob ON lcob.id = iacllcob.live_chicken_of_building_id;

-- узнаю основную информацию о корпусе посаженном в конкретную дату
SELECT * FROM v_total_info_about_chicken_laying WHERE date_of_delivery = '2021-03-25' AND parent_building_number = 6;
*/









