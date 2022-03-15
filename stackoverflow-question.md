https://stackoverflow.com/questions/70635906/mysql-dynamic-sql-is-not-allowed-in-stored-function-or-trigger

DROP FUNCTION IF EXISTS random_integer;
CREATE FUNCTION random_integer(value_minimum INT, value_maximum INT)
RETURNS INT
LANGUAGE SQL
NOT DETERMINISTIC
RETURN FLOOR(value_minimum + RAND() * (value_maximum - value_minimum + 1));
SELECT random_integer(1,10);

DROP FUNCTION IF EXISTS next_invoice_id_val;
DELIMITER //
CREATE FUNCTION next_invoice_id_val ()
RETURNS BIGINT(8)
LANGUAGE SQL
NOT DETERMINISTIC
BEGIN
  DECLARE lastId BIGINT(8) DEFAULT 1;
  DECLARE randId BIGINT(8) DEFAULT 1;
  DECLARE newId BIGINT(8) DEFAULT 1;
  DECLARE nextId BIGINT(8) DEFAULT 1;

  SELECT (SELECT MAX(`id`) FROM `invoices`) INTO lastId;
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
SELECT next_invoice_id_val();

DROP TRIGGER IF EXISTS next_invoice_id_val_trigger;
DELIMITER //
CREATE TRIGGER next_invoice_id_val_trigger
BEFORE INSERT
ON invoices FOR EACH ROW
BEGIN
  SET NEW.id = next_invoice_id_val();
END//
DELIMITER ;


DROP PROCEDURE IF EXISTS last_id;
DELIMITER //
CREATE PROCEDURE last_id (IN tableName VARCHAR(50), OUT lastId BIGINT(8))
COMMENT 'Gets the last id value'
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
CALL last_id('invoices', @nextInvoiceId);
SELECT @nextInvoiceId;

DROP PROCEDURE IF EXISTS next_id_val;
DELIMITER //
CREATE PROCEDURE next_id_val (IN tableName VARCHAR(50), OUT nextId BIGINT(8))
COMMENT 'Give the Next Id value + a random value'
LANGUAGE SQL
NOT DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE randId BIGINT(8) DEFAULT 1;

  SELECT (SELECT random_integer(1,10)) INTO randId;

  CALL last_id(tableName, @currentId);

  IF @currentId IS NULL
  THEN
    SET nextId = randId;
  ELSE
    SELECT ( @currentId + randId ) INTO nextId;
  END IF;
END //
DELIMITER ;
CALL next_id_val('invoices', @nextInvoiceId);
SELECT @nextInvoiceId;

# Call the procedure from a trigger
DROP TRIGGER IF EXISTS next_invoice_id_val_trigger;
DELIMITER //
CREATE TRIGGER next_invoice_id_val_trigger
BEFORE INSERT
ON invoices FOR EACH ROW
BEGIN
  CALL next_id_val('invoices', @nextInvoiceId);
  SET NEW.id = @nextInvoiceId;
END//
DELIMITER ;
