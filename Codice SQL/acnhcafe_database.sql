-- CREATE ----------------------------------------------------------------------------------------------

DROP DATABASE IF EXISTS acnhcafe;

CREATE DATABASE acnhcafe;

USE acnhcafe;

DROP TABLE IF EXISTS friendships;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS shopped;
DROP TABLE IF EXISTS decorations;
DROP TABLE IF EXISTS furniture;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS compositions;
DROP TABLE IF EXISTS ingredients;
DROP TABLE IF EXISTS animals;
DROP TABLE IF EXISTS personalities;
DROP TABLE IF EXISTS games;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS drinks;

-- Creazione tabella account

CREATE TABLE accounts (
    nickname varchar(100) primary key,
    password varchar(100) not null,
    level tinyint(2) default 0 not null
);

-- Creazione tabella amicizie

CREATE TABLE friendships (
    firstAccount varchar(100) not null,
    secondAccount varchar(100) not null,
    primary key (firstAccount, secondAccount),
    foreign key (firstAccount) references accounts (nickname) on delete cascade,
    foreign key (secondAccount) references accounts (nickname) on delete cascade
);

-- Creazione tabella utenti

CREATE TABLE users (
    nickname varchar(100),
    name varchar(100) not null,
    avatar varchar(20) not null,
    wallet int check (wallet >= 0) default 0 not null,
    points int default 0 not null,
    primary key (nickname),
    foreign key (nickname) references accounts (nickname)
);

-- Creazione tabella arredi

CREATE TABLE furniture (
    type varchar(100),
    style varchar(50),
    price smallint not null,
    level tinyint(2) default 0 not null,
    primary key (type, style)
);

-- Creazione tabella acquisti

CREATE TABLE shopped (
    nickname varchar(100),
    furnitureType varchar(100),
    furnitureStyle varchar(50),
    date datetime,
    primary key (nickname, furnitureType, furnitureStyle),
    foreign key (nickname) references users (nickname) on delete cascade,
    foreign key (furnitureType, furnitureStyle) references furniture (type, style)
);

-- Creazione tabella decorazioni

CREATE TABLE decorations (
    nickname varchar(100),
    furnitureType varchar(100),
    furnitureStyle varchar(50),
    primary key (nickname, furnitureType),
    foreign key (nickname) references users (nickname) on delete cascade,
    foreign key (furnitureType, furnitureStyle) references furniture (type, style)
);

-- Creazione tabella partite

CREATE TABLE games (
    id int(4) auto_increment,
    nickname varchar(100),
    duration time default 0 not null,
    primary key (id),
    foreign key (nickname) references users (nickname)
);

-- Creazione tabella bevande

CREATE TABLE drinks (
    type varchar(100),
    complexity tinyint(1),
    price double not null,
    primary key (type, complexity)
);

-- Creazione tabella personalità

CREATE TABLE personalities (
    type varchar(20) primary key check (type in ('Sisterly', 'Snooty', 'Smug', 'Peppy', 'Cranky', 'Jock', 'Lazy', 'Normal', 'Special')),
    dialog varchar(1000),
    tip double not null
);

-- Creazione tabella animali

CREATE TABLE animals (
    name varchar(100) primary key,
    species varchar(20) not null check (species in ('Alligator', 'Anteater', 'Bear', 'Bird', 'Bull', 'Cat', 'Chicken', 'Cow', 'Cub', 'Deer', 'Dog', 'Duck', 'Eagle', 'Elephant', 'Frog', 'Goat', 'Gorilla', 'Hamster', 'Hippo', 'Horse', 'Kangaroo', 'Koala', 'Lion', 'Monkey', 'Mouse', 'Octopus', 'Ostrich', 'Penguin', 'Pig', 'Rabbit', 'Rhino', 'Sheep', 'Squirrel', 'Tiger', 'Wolf')),
    personality varchar(20) check (personality in ('Sisterly', 'Snooty', 'Smug', 'Peppy', 'Cranky', 'Jock', 'Lazy', 'Normal', 'Special')),
    foreign key (personality) references personalities (type)
);

-- Creazione tabella ordini

CREATE TABLE orders (
    id int(4) auto_increment primary key,
    gameId int(4),
    drinkType varchar(100) not null,
    drinkComplexity tinyint(1) not null,
    animalName varchar(100) not null,
    stars tinyint(1) default 0 not null,
    profit int(3) default 0 not null,
    foreign key (gameId) references games (id) on delete cascade,
    foreign key (drinkType, drinkComplexity) references drinks (type, complexity),
    foreign key (animalName) references animals (name)
);

-- Creazione tabella ingredienti

CREATE TABLE ingredients (
    name varchar(100) primary key,
    category varchar(100) not null
);

-- Creazione tabella composizione

CREATE TABLE compositions (
    drinkType varchar(100),
    drinkComplexity tinyint(1),
    ingredientName varchar(100),
    percentage double not null,
    check (percentage between 0 and 1),
   -- check ((select sum(percentage) from compositions group by (drinkType, drinkComplexity))<=1),
    primary key (drinkType, drinkComplexity, ingredientName),
    foreign key (drinkType, drinkComplexity) references drinks (type, complexity),
    foreign key (ingredientName) references ingredients (name)
);

-- STORED PROCEDURE ----------------------------------------------------------------------------------------

-- Operazione 1: Generazione della partita

DELIMITER $$
CREATE PROCEDURE createGame(IN n varchar(100), OUT gid INT)
BEGIN
    INSERT INTO games (nickname) VALUE (n);
    SELECT id INTO gid FROM games WHERE nickname = n ORDER BY id DESC LIMIT 1;
END $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE generateOrder(IN gid INT, OUT oid INT)
BEGIN
    DECLARE an varchar(100);
    DECLARE dt varchar(100);
    DECLARE dc INT;
    SELECT name INTO an FROM animals WHERE name NOT IN
    (SELECT animalName FROM orders WHERE gameId = gid)
    ORDER BY RAND() LIMIT 1;
    SELECT type, complexity INTO dt, dc FROM drinks ORDER BY RAND() LIMIT 1;
    INSERT INTO orders (gameId, drinkType, drinkComplexity, animalName) VALUE (gid, dt, dc, an);
    SELECT id INTO oid FROM orders WHERE gameId = gid ORDER BY id DESC LIMIT 1;
END $$
DELIMITER ;

-- Operazione 2: Aggiornamento degli ordini

DELIMITER $$
CREATE PROCEDURE updateOrder(IN oid INT, IN s INT)
BEGIN
    UPDATE orders SET stars = s, profit = (getPrice(oid) + getTip(oid) * s) WHERE id = oid;
END $$
DELIMITER ;

-- Operazione 3: Registrazione della partita

DELIMITER $$
CREATE PROCEDURE endGame(IN gid INT, IN d TIME)
BEGIN
    UPDATE games SET duration = d WHERE id = gid;
    SELECT * FROM GameDetails WHERE id = gid;
    UPDATE users SET points = points + gamePoints(gid), wallet = wallet + gameProfits(gid)
    WHERE nickname = (SELECT nickname FROM games WHERE id = gid);
END $$
DELIMITER ;

-- Operazione 4: Gestione delle decorazioni

DELIMITER $$
CREATE PROCEDURE decorateBar(IN nick varchar(100), IN type varchar(100), IN style varchar(50))
BEGIN
    DECLARE control varchar(50);
    SELECT style INTO control FROM shopped
        WHERE nickname = nick AND furnitureType = type AND furnitureStyle = style;
    IF control IS NULL THEN
        SIGNAL SQLSTATE '45001' SET message_text = 'Item not bought.';
    END IF;
    UPDATE decorations SET furnitureStyle = style WHERE nickname = nick AND furnitureType = type;
END $$
DELIMITER ;

-- Operazione 5: Visualizzazione delle classifiche

DELIMITER $$
CREATE PROCEDURE viewRankings(IN n varchar(100))
BEGIN
    SELECT DISTINCT nickname, level, rank() over (order by level desc) as ranking from
    (SELECT DISTINCT a.nickname, a.level FROM accounts a
        INNER JOIN friendships f ON a.nickname = f.firstAccount OR a.nickname = f.secondAccount
        WHERE f.firstAccount = n OR f.secondAccount = n) as rankedFriends ORDER BY level DESC;
END $$
DELIMITER ;

-- Operazione 6: Pulizia dei dati storici

DELIMITER $$
CREATE PROCEDURE cleanHistory()
BEGIN
DELETE FROM games WHERE (nickname, id) NOT IN (select nickname, id from
    (SELECT g.* FROM games g WHERE (SELECT count(*) FROM games
    WHERE nickname = g.nickname AND id >= g.id) <= 2) AS last2games);
END $$
DELIMITER ;

-- Operazione 7: Report degli utenti

DELIMITER $$
CREATE PROCEDURE usersReport()
BEGIN
    SELECT count(*) AS 'users count' FROM users;
END $$
DELIMITER ;

-- Operazione 8: Aggiornamento del livello

DELIMITER $$
CREATE PROCEDURE updateLevel(IN n varchar(100))
BEGIN
    UPDATE accounts a JOIN users u USING (nickname)
    SET level = getLevel(points) WHERE a.nickname = n;
END $$
DELIMITER ;

-- UDF -----------------------------------------------------------------------------------------------------

-- Trova la mancia del cliente
CREATE FUNCTION getPrice(oid INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE p INT;
    SELECT price INTO p FROM orders
    INNER JOIN drinks ON drinkType = type AND drinkComplexity = complexity
    WHERE id = oid;
    RETURN p;
END;

-- Trova il prezzo della bevanda ordinata
CREATE FUNCTION getTip(oid INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE t INT;
    SELECT tip INTO t FROM orders
    INNER JOIN animals ON animalName = name
    INNER JOIN personalities ON personality = type
    WHERE orders.id = oid;
    RETURN t;
END;

-- Trova i punti della partita
CREATE FUNCTION gamePoints(gid INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE p INT;
    SELECT SUM(stars) INTO p FROM orders WHERE gameId = gid GROUP BY gameId;
    RETURN p;
END;

-- Trova i profitti della partita
CREATE FUNCTION gameProfits(gid INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE p INT;
    SELECT SUM(profit) INTO p FROM orders WHERE gameId = gid GROUP BY gameId;
    RETURN p;
END;

-- Definisce i passaggi di livello
CREATE FUNCTION getLevel(p INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE lvl INT;
    IF p >= 500 THEN SET lvl = 10;
    ELSEIF p >= 400 THEN SET lvl = 9;
    ELSEIF p >= 300 THEN SET lvl = 8;
    ELSEIF p >= 250 THEN SET lvl = 7;
    ELSEIF p >= 200 THEN SET lvl = 6;
    ELSEIF p >= 150 THEN SET lvl = 5;
    ELSEIF p >= 100 THEN SET lvl = 4;
    ELSEIF p >= 70 THEN SET lvl = 3;
    ELSEIF p >= 40 THEN SET lvl = 2;
    ELSEIF p >= 10 THEN SET lvl = 1;
    ELSE SET lvl = 0;
    END IF;
    RETURN lvl;
END;

-- VISTE --------------------------------------------------------------------------------------------------

CREATE VIEW GameDetails AS
SELECT id, nickname, duration, gamePoints(id) AS points, gameProfits(id) AS profit FROM games;

-- TRIGGER ------------------------------------------------------------------------------------------------

-- Trigger 1:
DELIMITER $$
CREATE TRIGGER beforeInsertFriendships
BEFORE INSERT ON friendships
FOR EACH ROW
BEGIN
    IF NEW.firstAccount > NEW.secondAccount THEN
        SET @temp = NEW.firstAccount;
        SET NEW.firstAccount = NEW.secondAccount;
        SET NEW.secondAccount = @temp;
    END IF;
END $$
DELIMITER ;

-- Trigger 2:
DELIMITER $$
CREATE TRIGGER afterUpdatePoints
AFTER UPDATE ON users
FOR EACH ROW
BEGIN
    IF NEW.points != OLD.points THEN
        CALL updateLevel(NEW.nickname);
    END IF;
END $$
DELIMITER ;

-- Trigger 3:
DELIMITER $$
CREATE TRIGGER afterInsertShopped
AFTER INSERT ON shopped
FOR EACH ROW
BEGIN
    DECLARE itemPrice INT;
    SELECT price INTO itemPrice FROM furniture
        WHERE type = NEW.furnitureType AND style = NEW.furnitureStyle;
    UPDATE users SET wallet = wallet - itemPrice
        WHERE nickname = NEW.nickname;
END $$
DELIMITER ;

-- Trigger 4:
DELIMITER $$
CREATE TRIGGER beforeInsertShopped
BEFORE INSERT ON shopped
FOR EACH ROW
BEGIN
    DECLARE itemLevel INT;
    DECLARE userLevel INT;
    SELECT level into itemLevel FROM furniture
         WHERE type = NEW.furnitureType AND style = NEW.furnitureStyle;
    SELECT level into userLevel FROM accounts
        WHERE nickname = NEW.nickname;
    IF itemLevel > userLevel THEN
        SIGNAL SQLSTATE '45002' SET message_text = 'User level is too low!';
    END IF;
END $$

-- INSERT --------------------------------------------------------------------------------------------------

USE acnhcafe;

INSERT INTO accounts (nickname, password, level) VALUES
('pannafritta','leila', 4), ('marrenk','tennisball02', 3), ('asap_pox','!02!vivalam024', 2), ('pasqua','kikipipi', 4), ('jackychan','PianoForteScacchi12093', 2), ('lalli88','2222', 1), ('yongmimi','Anubi01', 6),('elenona22','ElliotVenchiDolciCuori', 1),('default','password', 0);

INSERT INTO users (nickname, name, avatar, wallet, points) VALUES
('pannafritta','Anna','dog.png', 500, 100), ('default','User','default.png',0,0), ('marrenk','Fede','dog.png', 1200, 30), ('asap_pox','Michi','duck.png', 1200, 50), ('pasqua','Gabri','scarecrow.png', 830, 100), ('jackychan','Giacomo','default.png', 580, 40), ('lalli88','Laura','default.png', 900, 10), ('yongmimi','Marti','ninja.png', 2000, 200), ('elenona22','Nena','gnome.png',965,20);

INSERT INTO friendships (firstAccount, secondAccount) VALUES
('pannafritta','yongmimi'), ('pannafritta','marrenk'),('pannafritta','pasqua'),('pannafritta','asap_pox'),('pannafritta','jackychan'),('pannafritta','lalli88'),
('marrenk','asap_pox'), ('marrenk', 'yongmimi'), ('marrenk', 'jackychan'), ('marrenk', 'pasqua'),('marrenk', 'lalli88'),
('asap_pox', 'pasqua'), ('pasqua','jackychan');

INSERT INTO personalities (type, dialog, tip) VALUES
('Sisterly', 'Hey there! Could you get me my favorite drink, please?', 2.0),
('Snooty', 'I would like to order something exquisite and refreshing.', 2.5),
('Smug', 'Could you prepare me a delightful beverage?', 3.0),
('Peppy', 'Hi! Can I have my go-to drink? Thanks!', 2.0),
('Cranky', 'Get me my usual drink, and make it quick.', 1.5),
('Jock', 'I need a drink to keep my energy up, thanks!', 2.0),
('Lazy', 'Hey, can you get me a nice, relaxing drink?', 1.5),
('Normal', 'Could I please have a drink? Thank you!', 2.0),
('Special', 'I would love to have a special drink, thank you very much!', 5.0);

INSERT INTO animals (name, species, personality) VALUES
('Kiki','Cat','Normal'),('Teddy','Bear','Jock'),('Ace','Bird','Jock'),('Purrl','Cat','Snooty'),('Egbert','Chicken','Lazy'),
('Maple','Cub','Normal'),('Marty','Cub','Lazy'),('Bam','Deer','Jock'),('Fuchsia','Deer','Sisterly'),('Zell','Deer','Smug'),
('Bea','Dog','Normal'),('Biskit','Dog','Lazy'),('Cherry','Dog','Sisterly'),('Bones','Dog','Lazy'),('Daisy','Dog','Normal'),
('Goldie','Dog','Normal'),('Lucky','Dog','Lazy'),('Leila','Dog','Special'),('Anubi','Cat','Smug'),('Shep','Dog','Smug'),
('Ketchup','Duck','Peppy'),('Apollo','Eagle','Cranky'),('Cyd','Elephant','Cranky'),('Camofrog','Frog','Cranky'),
('Henry','Frog','Smug'),('Julian','Horse','Smug'),('Ozzie','Koala','Lazy'),('Zucker','Octopus','Lazy'),('Ribbot','Frog','Lazy'),
('Aurora','Penguin','Normal'),('Curly','Pig','Jock'),('Genji','Rabbit','Jock'),('Coco','Rabbit','Normal'),('Ione','Squirrel','Normal'),
('Marshal','Squirrel','Smug'),('Audie','Wolf','Peppy'),('Dobie','Wolf','Cranky');

INSERT INTO drinks (type, complexity, price) VALUES
('tea',1,6),('tea',2,6),('tea',3,10),
('coffee',1,4),('coffee',2,6),('coffee',3,8),
('bubble tea',2,10),('bubble tea',3,12),
('soda',1,6),('soda',2,6);

INSERT INTO ingredients (name, category) VALUES
('coffee','caffeinated'),('tea','caffeinated'),('honey','extra'),('ice','extra'),
('soda','drink'),('milk','dairy'),('tapioca','extra'),('cocoa','extra');

INSERT INTO compositions (drinkType, drinkComplexity, ingredientName, percentage) VALUES
('tea',1,'tea',1.0),
('tea',2,'tea',0.8),('tea',2,'honey',0.2),
('tea',3,'tea',0.5),('tea',3,'milk',0.3),('tea',3,'honey',0.2),
('coffee',1,'coffee',1.0),
('coffee',2,'coffee',0.7),('coffee',2,'milk',0.3),
('coffee',3,'coffee',0.5),('coffee',3,'milk',0.3),('coffee',3,'cocoa',0.2),
('bubble tea',2,'tea', 0.7),('bubble tea',2,'tapioca', 0.3),
('bubble tea',3,'tea', 0.4),('bubble tea',3,'milk', 0.3),('bubble tea',3,'tapioca', 0.3),
('soda',1,'soda',1.0),
('soda',2,'soda',0.9),('soda',2,'ice',0.1);

INSERT INTO games (id, nickname, duration) VALUES
(1, 'pannafritta', '00:30:00'),(2, 'marrenk', '00:35:00'),(3, 'asap_pox', '00:40:00'),(4, 'pasqua', '00:25:00'),(5, 'jackychan', '00:50:00'),(6, 'lalli88', '00:55:00'),(7, 'yongmimi', '01:00:00'),(8, 'elenona22', '01:05:00'),
(9, 'pannafritta', '00:30:00'),(10, 'marrenk', '00:35:00'),(11, 'asap_pox', '00:40:00'),(12, 'pasqua', '00:25:00'),(13, 'jackychan', '00:50:00'),(14, 'lalli88', '00:55:00'),(15, 'yongmimi', '01:00:00'),(16, 'elenona22', '01:05:00');

INSERT INTO orders (gameId, drinkType, drinkComplexity, animalName, stars, profit) VALUES
(1, 'tea', 1, 'Kiki', 1, 8),(1, 'coffee', 1, 'Teddy', 0, 4),(1, 'bubble tea', 2, 'Ace', 0, 10),(1, 'soda', 1, 'Purrl', 1, 8.5),(1, 'tea', 2, 'Egbert', 1, 7.5),
(2, 'coffee', 2, 'Maple', 0, 6),(2, 'bubble tea', 3, 'Marty', 0, 12),(2, 'soda', 2, 'Bam', 1, 8),(2, 'tea', 3, 'Fuchsia', 3, 16),(2, 'coffee', 3, 'Zell', 2, 14),
(3, 'tea', 1, 'Bea', 1, 8),(3, 'coffee', 1, 'Biskit', 0, 4),(3, 'bubble tea', 2, 'Cherry', 0, 10),(3, 'soda', 1, 'Bones', 0, 6),(3, 'tea', 2, 'Daisy', 1, 8),
(4, 'coffee', 2, 'Goldie', 2, 10),(4, 'bubble tea', 3, 'Lucky', 3, 16.5),(4, 'soda', 2, 'Leila', 1, 11),(4, 'tea', 3, 'Anubi', 2, 16),(4, 'coffee', 3, 'Shep', 1, 11),
(5, 'tea', 1, 'Ketchup', 1, 8),(5, 'coffee', 1, 'Apollo', 0, 4),(5, 'bubble tea', 2, 'Cyd', 2, 13),(5, 'soda', 1, 'Camofrog', 0, 6),(5, 'tea', 2, 'Henry', 2, 16),
(6, 'coffee', 2, 'Julian', 2, 12),(6, 'bubble tea', 3, 'Ozzie', 1, 13.5),(6, 'soda', 2, 'Zucker', 2, 9),(6, 'tea', 3, 'Ribbot', 0, 10),(6, 'coffee', 3, 'Aurora', 1, 10),
(7, 'tea', 1, 'Curly', 1, 8),(7, 'coffee', 1, 'Genji', 1, 6),(7, 'bubble tea', 2, 'Coco', 2, 14),(7, 'soda', 1, 'Ione', 1, 8),(7, 'tea', 2, 'Marshal', 2, 16),
(8, 'coffee', 2, 'Audie', 2, 10),(8, 'bubble tea', 3, 'Dobie', 3, 16.5),(8, 'soda', 2, 'Ace', 2, 10),(8, 'tea', 3, 'Kiki', 3, 16),(8, 'coffee', 3, 'Purrl', 3, 16.5),
(9, 'tea', 1, 'Egbert', 1, 7.5),(9, 'coffee', 1, 'Maple', 1, 6),(9, 'bubble tea', 2, 'Marty', 0, 10),(9, 'soda', 1, 'Bam', 0, 6),(9, 'tea', 2, 'Fuchsia', 1, 8),
(10, 'coffee', 2, 'Zell', 1, 9),(10, 'bubble tea', 3, 'Bea', 1, 14),(10, 'soda', 2, 'Biskit', 0, 6),(10, 'tea', 3, 'Cherry', 0, 10),(10, 'coffee', 3, 'Bones', 1, 9),
(11, 'tea', 1, 'Daisy', 0, 6),(11, 'coffee', 1, 'Goldie', 0, 4),(11, 'bubble tea', 2, 'Lucky', 0, 10),(11, 'soda', 1, 'Leila', 0, 6),(11, 'tea', 2, 'Anubi', 0, 10),
(12, 'coffee', 2, 'Shep', 2, 14),(12, 'bubble tea', 3, 'Ketchup', 0, 12),(12, 'soda', 2, 'Apollo', 0, 6),(12, 'tea', 3, 'Cyd', 0, 10),(12, 'coffee', 3, 'Camofrog', 0, 8),
(13, 'tea', 1, 'Henry', 1, 13),(13, 'coffee', 1, 'Julian', 1, 7),(13, 'bubble tea', 2, 'Ozzie', 2, 13.5),(13, 'soda', 1, 'Zucker', 1, 7.5),(13, 'tea', 2, 'Ribbot', 2, 13),
(14, 'coffee', 2, 'Aurora', 2, 10),(14, 'bubble tea', 3, 'Curly', 3, 19),(14, 'soda', 2, 'Genji', 2, 10),(14, 'tea', 3, 'Coco', 3, 16),(14, 'coffee', 3, 'Ione', 3, 14),
(15, 'tea', 1, 'Marshal', 1, 9),(15, 'coffee', 1, 'Audie', 1, 6),(15, 'bubble tea', 2, 'Dobie', 0, 10),(15, 'soda', 1, 'Ace', 1, 8),(15, 'tea', 2, 'Kiki', 2, 12),
(16, 'coffee', 2, 'Purrl', 2, 14),(16, 'bubble tea', 3, 'Egbert', 2, 19.5),(16, 'soda', 2, 'Maple', 2, 10),(16, 'tea', 3, 'Marty', 2, 13),(16, 'coffee', 3, 'Bam', 2, 14);

INSERT INTO furniture (type, style, price, level) VALUES
('dishware', 'simple', 0, 0),('dishware', 'country', 20, 1),('dishware', 'cute', 55, 2),('dishware', 'cool', 85, 3),('dishware', 'minimal', 145, 4),('dishware', 'nerdy', 235, 5),('dishware', 'antique', 295, 6),('dishware', 'exotic', 340, 7),('dishware', 'spooky', 395, 8),('dishware', 'space', 450, 9),
('chair', 'simple', 0, 0),('chair', 'country', 40, 1),('chair', 'cute', 75, 2),('chair', 'cool', 105, 3),('chair', 'minimal', 165, 4),('chair', 'nerdy', 255, 5),('chair', 'antique', 315, 6),('chair', 'exotic', 360, 7),('chair', 'spooky', 415, 8),('chair', 'space', 470, 9),
('tables', 'simple', 0, 0),('tables', 'country', 50, 1),('tables', 'cute', 85, 2),('tables', 'cool', 115, 3),('tables', 'minimal', 175, 4),('tables', 'nerdy', 265, 5),('tables', 'antique', 325, 6),('tables', 'exotic', 370, 7),('tables', 'spooky', 425, 8),('tables', 'space', 480, 9),
('wall decor', 'simple', 0, 0),('wall decor', 'country', 60, 1),('wall decor', 'cute', 95, 2),('wall decor', 'cool', 125, 3),('wall decor', 'minimal', 185, 4),('wall decor', 'nerdy', 275, 5),('wall decor', 'antique', 335, 6),('wall decor', 'exotic', 380, 7),('wall decor', 'spooky', 435, 8),('wall decor', 'space', 490, 9),
('counter', 'simple', 0, 0),('counter', 'country', 70, 1),('counter', 'cute', 105, 2),('counter', 'cool', 135, 3),('counter', 'minimal', 195, 4),('counter', 'nerdy', 285, 5),('counter', 'antique', 345, 6),('counter', 'exotic', 390, 7),('counter', 'spooky', 445, 8),('counter', 'space', 500, 9),
('lights', 'simple', 0, 0),('lights', 'country', 30, 1),('lights', 'cute', 65, 2),('lights', 'cool', 95, 3),('lights', 'minimal', 155, 4),('lights', 'nerdy', 245, 5),('lights', 'antique', 305, 6),('lights', 'exotic', 350, 7),('lights', 'spooky', 405, 8),('lights', 'space', 460, 9),
('plants', 'simple', 0, 0),('plants', 'country', 35, 1),('plants', 'cute', 70, 2),('plants', 'cool', 100, 3),('plants', 'minimal', 160, 4),('plants', 'nerdy', 250, 5),('plants', 'antique', 310, 6),('plants', 'exotic', 355, 7),('plants', 'spooky', 410, 8),('plants', 'space', 465, 9),
('wallpaper', 'simple', 0, 0),('wallpaper', 'country', 50, 1),('wallpaper', 'cute', 85, 2),('wallpaper', 'cool', 115, 3),('wallpaper', 'minimal', 175, 4),('wallpaper', 'nerdy', 265, 5),('wallpaper', 'antique', 325, 6),('wallpaper', 'exotic', 370, 7),('wallpaper', 'spooky', 425, 8),('wallpaper', 'space', 480, 9),
('flooring', 'simple', 0, 0),('flooring', 'country', 70, 1),('flooring', 'cute', 105, 2),('flooring', 'cool', 135, 3),('flooring', 'minimal', 195, 4),('flooring', 'nerdy', 285, 5),('flooring', 'antique', 345, 6),('flooring', 'exotic', 390, 7),('flooring', 'spooky', 445, 8),('flooring', 'space', 500, 9),
('entrance', 'simple', 0, 0),('entrance', 'country', 70, 1),('entrance', 'cute', 105, 2),('entrance', 'cool', 135, 3),('entrance', 'minimal', 195, 4),('entrance', 'nerdy', 285, 5),('entrance', 'antique', 345, 6),('entrance', 'exotic', 390, 7),('entrance', 'spooky', 445, 8),('entrance', 'space', 500, 9);

INSERT INTO decorations (nickname, furnitureType, furnitureStyle) VALUES
('pannafritta', 'dishware', 'simple'),('pannafritta', 'chair', 'cute'),('pannafritta', 'tables', 'nerdy'),('pannafritta', 'wall decor', 'simple'),('pannafritta', 'counter', 'simple'),('pannafritta', 'lights', 'simple'),('pannafritta', 'plants', 'simple'),('pannafritta', 'wallpaper', 'simple'),('pannafritta', 'flooring', 'simple'),('pannafritta', 'entrance', 'simple'),
('marrenk', 'dishware', 'simple'),('marrenk', 'chair', 'simple'),('marrenk', 'tables', 'simple'),('marrenk', 'wall decor', 'minimal'),('marrenk', 'counter', 'antique'),('marrenk', 'lights', 'country'),('marrenk', 'plants', 'simple'),('marrenk', 'wallpaper', 'simple'),('marrenk', 'flooring', 'simple'),('marrenk', 'entrance', 'simple'),
('asap_pox', 'dishware', 'simple'),('asap_pox', 'chair', 'simple'),('asap_pox', 'tables', 'simple'),('asap_pox', 'wall decor', 'simple'),('asap_pox', 'counter', 'simple'),('asap_pox', 'lights', 'simple'),('asap_pox', 'plants', 'cool'),('asap_pox', 'wallpaper', 'exotic'),('asap_pox', 'flooring', 'spooky'),('asap_pox', 'entrance', 'simple'),
('pasqua', 'dishware', 'cute'),('pasqua', 'chair', 'nerdy'),('pasqua', 'tables', 'simple'),('pasqua', 'wall decor', 'simple'),('pasqua', 'counter', 'simple'),('pasqua', 'lights', 'simple'),('pasqua', 'plants', 'simple'),('pasqua', 'wallpaper', 'simple'),('pasqua', 'flooring', 'simple'),('pasqua', 'entrance', 'space'),
('jackychan', 'dishware', 'simple'),('jackychan', 'chair', 'simple'),('jackychan', 'tables', 'minimal'),('jackychan', 'wall decor', 'antique'),('jackychan', 'counter', 'country'),('jackychan', 'lights', 'simple'),('jackychan', 'plants', 'simple'),('jackychan', 'wallpaper', 'simple'),('jackychan', 'flooring', 'simple'),('jackychan', 'entrance', 'simple'),
('lalli88', 'dishware', 'simple'),('lalli88', 'chair', 'simple'),('lalli88', 'tables', 'simple'),('lalli88', 'wall decor', 'simple'),('lalli88', 'counter', 'simple'),('lalli88', 'lights', 'cool'),('lalli88', 'plants', 'exotic'),('lalli88', 'wallpaper', 'spooky'),('lalli88', 'flooring', 'simple'),('lalli88', 'entrance', 'simple'),
('yongmimi', 'dishware', 'simple'),('yongmimi', 'chair', 'simple'),('yongmimi', 'tables', 'simple'),('yongmimi', 'wall decor', 'simple'),('yongmimi', 'counter', 'simple'),('yongmimi', 'lights', 'simple'),('yongmimi', 'plants', 'simple'),('yongmimi', 'wallpaper', 'simple'),('yongmimi', 'flooring', 'space'),('yongmimi', 'entrance', 'simple'),
('elenona22', 'dishware', 'simple'),('elenona22', 'chair', 'nerdy'),('elenona22', 'tables', 'minimal'),('elenona22', 'wall decor', 'antique'),('elenona22', 'counter', 'simple'),('elenona22', 'lights', 'simple'),('elenona22', 'plants', 'simple'),('elenona22', 'wallpaper', 'simple'),('elenona22', 'flooring', 'simple'),('elenona22', 'entrance', 'simple');

INSERT INTO shopped (nickname, furnitureType, furnitureStyle, date) VALUES
('pannafritta', 'dishware', 'simple', '2024-01-01 10:00:00'),('pannafritta', 'chair', 'cute', '2024-01-02 11:00:00'),('pannafritta', 'tables', 'nerdy', '2024-01-03 12:00:00'),
('marrenk', 'wall decor', 'minimal', '2024-01-04 13:00:00'),('marrenk', 'counter', 'antique', '2024-01-05 14:00:00'),('marrenk', 'lights', 'country', '2024-01-06 15:00:00'),
('asap_pox', 'plants', 'cool', '2024-01-07 16:00:00'),('asap_pox', 'wallpaper', 'exotic', '2024-01-08 17:00:00'),('asap_pox', 'flooring', 'spooky', '2024-01-09 18:00:00'),
('pasqua', 'entrance', 'space', '2024-01-10 19:00:00'),('pasqua', 'dishware', 'cute', '2024-01-11 20:00:00'),('pasqua', 'chair', 'nerdy', '2024-01-12 21:00:00'),
('jackychan', 'tables', 'minimal', '2024-01-13 22:00:00'),('jackychan', 'wall decor', 'antique', '2024-01-14 23:00:00'),('jackychan', 'counter', 'country', '2024-01-15 09:00:00'),
('lalli88', 'lights', 'cool', '2024-01-16 08:00:00'),('lalli88', 'plants', 'exotic', '2024-01-17 07:00:00'),('lalli88', 'wallpaper', 'spooky', '2024-01-18 06:00:00'),
('yongmimi', 'flooring', 'space', '2024-01-19 05:00:00'),('yongmimi', 'entrance', 'simple', '2024-01-20 04:00:00'),('yongmimi', 'dishware', 'cute', '2024-01-21 03:00:00'),
('elenona22', 'chair', 'nerdy', '2024-01-22 02:00:00'),('elenona22', 'tables', 'minimal', '2024-01-23 01:00:00'),('elenona22', 'wall decor', 'antique', '2024-01-24 00:00:00');

