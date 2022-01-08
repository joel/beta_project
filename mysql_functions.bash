export DB_USER=root
export DB_PASSWORD=db_password
export container_name="bundle_local_cache_travis_beta_test-db"
export database_name="beta_project_development"

docker exec -it bundle_local_cache_travis_beta_test-db bash
mysql -u root -pdb_password
show global variables like 'auto_inc%';

set global auto_increment_increment = 2;

docker exec bundle_local_cache_travis_beta_test-db sh -c "mysql -u root -pdb_password -e 'SHOW DATABASES;'"

SELECT routine_name FROM information_schema.routines WHERE routine_type = 'FUNCTION' AND routine_schema = 'beta_project_development';

SHOW TRIGGERS;
SHOW TRIGGERS FROM beta_project_development;

# https://dev.mysql.com/doc/refman/8.0/en/create-procedure.html

# Simple function to get a random integer
DROP FUNCTION IF EXISTS random_integer;
CREATE FUNCTION random_integer(value_minimum INT, value_maximum INT)
RETURNS INT
LANGUAGE SQL
NOT DETERMINISTIC
RETURN FLOOR(value_minimum + RAND() * (value_maximum - value_minimum + 1));
SELECT random_integer(1,10);

# Simple function to get the incremented next id + a random integer gap
# ISSUE: table is not Dynamic, we can apply that function to whatever tables
}
DROP FUNCTION IF EXISTS next_random_sequence;
DELIMITER //
CREATE FUNCTION next_random_sequence ()
RETURNS BIGINT(8)
LANGUAGE SQL
NOT DETERMINISTIC
BEGIN
  DECLARE lastId BIGINT(8) DEFAULT 1;
  DECLARE randId BIGINT(8) DEFAULT 1;
  DECLARE newId BIGINT(8) DEFAULT 1;
  DECLARE nextId BIGINT(8) DEFAULT 1;

  SELECT (SELECT MAX(`id`) FROM `posts`) INTO lastId;
  SELECT (SELECT random_integer(1,10)) INTO randId;
  SELECT ( lastId + randId ) INTO nextId;

  IF lastId IS NULL
  THEN
    SET newId = randId;
  ELSE
    SET newId = nextId;
  END IF;

  RETURN newId;
END //
DELIMITER ;
SELECT next_random_sequence();

SELECT ( (SELECT MAX(`id`) FROM `posts`) + random_integer(1,10));

# https://dev.mysql.com/doc/refman/8.0/en/create-trigger.html

# Simple trigger to set the next id
# ISSUE: table is not Dynamic, we can apply that function to whatever tables
DROP TRIGGER IF EXISTS random_integer_sequence_trigger;
DELIMITER //
CREATE TRIGGER random_integer_sequence_trigger
BEFORE INSERT
ON posts FOR EACH ROW
BEGIN
  SET NEW.random_id = next_random_sequence();
END//
DELIMITER ;

# For comments table:

# Specific example for comments table, not really DRY
DROP FUNCTION IF EXISTS next_comment_id_val;
DELIMITER //
CREATE FUNCTION next_comment_id_val ()
RETURNS BIGINT(8)
LANGUAGE SQL
NOT DETERMINISTIC
BEGIN
  DECLARE lastId BIGINT(8) DEFAULT 1;
  DECLARE randId BIGINT(8) DEFAULT 1;
  DECLARE nextId BIGINT(8) DEFAULT 1;

  SELECT (SELECT MAX(`id`) FROM `comments`) INTO lastId;
  SELECT (SELECT random_integer(1,10)) INTO randId;
  SELECT ( lastId + randId ) INTO nextId;

  RETURN nextId;
END //
DELIMITER ;

DROP TRIGGER IF EXISTS next_comment_id_val_trigger;
DELIMITER //
CREATE TRIGGER next_comment_id_val_trigger
BEFORE INSERT
ON comments FOR EACH ROW
BEGIN
  SET NEW.id = next_comment_id_val();
END//
DELIMITER ;

# https://dev.mysql.com/doc/refman/8.0/en/create-procedure.html

# Try to DRY up a bit a make common behavior callable for any table

# Simple procedure to get the last id value
DROP PROCEDURE IF EXISTS last_id;
DELIMITER //
CREATE PROCEDURE last_id (IN tableName VARCHAR(50), OUT lastId BIGINT(8))
COMMENT 'Give the Next Id with a random gap to ensure nonlinear sequence'
LANGUAGE SQL
NOT DETERMINISTIC
READS SQL DATA
BEGIN
  SET @s := CONCAT('SELECT MAX(`id`) FROM `',tableName,'`');
  PREPARE QUERY FROM @s;
  EXECUTE QUERY;
  DEALLOCATE PREPARE QUERY;
END //
DELIMITER ;
CALL last_id('posts', @nextPostId);
SELECT @nextPostId;

# Attempts to call a Dynamic SQL of the procedure from the function to make the function available for
# any tables of the schema
DROP FUNCTION IF EXISTS next_id;
DELIMITER //
CREATE FUNCTION next_id (tableName VARCHAR(50))
RETURNS BIGINT(8)
LANGUAGE SQL
NOT DETERMINISTIC
BEGIN
  DECLARE lastId BIGINT(8) DEFAULT 1;
  DECLARE randId BIGINT(8) DEFAULT 1;
  DECLARE nextId BIGINT(8) DEFAULT 1;

  SELECT (SELECT random_integer(1,10)) INTO randId;

  CALL last_id(tableName, lastId);

  IF lastId IS NULL
  THEN
    # SET nextId = randId;
    SELECT randId INTO nextId;
  ELSE
    SELECT ( lastId + randId ) INTO nextId;
  END IF;

  RETURN nextId;
END //
DELIMITER ;
SELECT next_id('posts');
# => Dynamic SQL is not allowed in stored function or trigger; OH GOD I can't believe it!!!!

# Do everything in a procedure rather a function to handle Dynamic SQL
DROP PROCEDURE IF EXISTS next_id_val;
DELIMITER //
CREATE PROCEDURE next_id_val (IN tableName VARCHAR(50), OUT lastId BIGINT(8))
COMMENT 'Give the Next Id with a random gap to ensure nonlinear sequence'
LANGUAGE SQL
NOT DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE randId BIGINT(8) DEFAULT 1;

  SELECT (SELECT random_integer(1,10)) INTO randId;

  CALL last_id(tableName, @currentId);

  IF @currentId IS NULL
  THEN
    SET lastId = randId;
  ELSE
    SELECT ( @currentId + randId ) INTO lastId;
  END IF;
END //
DELIMITER ;
CALL next_id_val('posts', @nextPostId);
SELECT @nextPostId;

# Call the procedure from a trigger
DROP TRIGGER IF EXISTS next_comment_id_val_trigger;
DELIMITER //
CREATE TRIGGER next_comment_id_val_trigger
BEFORE INSERT
ON comments FOR EACH ROW
BEGIN
  CALL next_id_val('comments', @nextCommentId);
  SET NEW.id = @nextCommentId;
END//
DELIMITER ;

CREATE TABLE `comments` (
  `id` bigint(20) NOT NULL,
  `title` varchar(255) DEFAULT NULL,
  `content` text DEFAULT NULL,
  `post_id` bigint(20) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_comments_on_post_id` (`post_id`),
  CONSTRAINT `fk_rails_2fd19c0db7` FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=42 DEFAULT CHARSET=utf8mb4;

# To insert into db/structure.sql

DROP FUNCTION IF EXISTS random_integer;
CREATE FUNCTION random_integer(value_minimum INT, value_maximum INT)
RETURNS INT
LANGUAGE SQL
NOT DETERMINISTIC
RETURN FLOOR(value_minimum + RAND() * (value_maximum - value_minimum + 1));

DROP PROCEDURE IF EXISTS last_id;
DELIMITER //
CREATE PROCEDURE last_id (IN tableName VARCHAR(50), OUT lastId BIGINT(8))
COMMENT 'Give the Next Id with a random gap to ensure nonlinear sequence'
LANGUAGE SQL
NOT DETERMINISTIC
READS SQL DATA
BEGIN
  SET @s := CONCAT('SELECT MAX(`id`) FROM `',tableName,'`');
  PREPARE QUERY FROM @s;
  EXECUTE QUERY;
  DEALLOCATE PREPARE QUERY;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS next_id_val;
DELIMITER //
CREATE PROCEDURE next_id_val (IN tableName VARCHAR(50), OUT lastId BIGINT(8))
COMMENT 'Give the Next Id with a random gap to ensure nonlinear sequence'
LANGUAGE SQL
NOT DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE randId BIGINT(8) DEFAULT 1;

  SELECT (SELECT random_integer(1,10)) INTO randId;

  CALL last_id(tableName, @currentId);

  IF @currentId IS NULL
  THEN
    SET lastId = randId;
  ELSE
    SELECT ( @currentId + randId ) INTO lastId;
  END IF;
END //
DELIMITER ;

DROP TRIGGER IF EXISTS next_comment_id_val_trigger;
DELIMITER //
CREATE TRIGGER next_comment_id_val_trigger
BEFORE INSERT
ON comments FOR EACH ROW
BEGIN
  CALL next_id_val('comments', @nextCommentId);
  SET NEW.id = @nextCommentId;
END//
DELIMITER ;
