
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
DROP TABLE IF EXISTS `ar_internal_metadata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ar_internal_metadata` (
  `key` varchar(255) CHARACTER SET utf8mb3 NOT NULL,
  `value` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `posts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `posts` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `random_id` bigint(20) NOT NULL DEFAULT 1,
  `name` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `schema_migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `schema_migrations` (
  `version` varchar(255) CHARACTER SET utf8mb3 NOT NULL,
  PRIMARY KEY (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

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

INSERT INTO `schema_migrations` (version) VALUES
('20210917095639'),
('20220108111613');
