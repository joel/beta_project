# https://www.postgresql.org/docs/11/sql-createfunction.html

# https://www.postgresql.org/docs/11/sql-createtrigger.html

# Function to get the next incremented posts id
CREATE OR REPLACE FUNCTION next_post_id_val() RETURNS integer
AS $BODY$
DECLARE
  lastPostId INT;
  randInteger INT;
  nextId INT;
BEGIN
    SELECT (SELECT MAX(id) FROM posts) INTO lastPostId;
    SELECT (SELECT FLOOR(RANDOM() * 10 + 1)::INT) INTO randInteger;

    nextId := lastPostId + randInteger;

    RETURN nextId;
END;
$BODY$
LANGUAGE PLPGSQL;

# Call the function example:
SELECT * FROM next_post_id_val();

# Function to assign the next incremented posts id to posts.random_id
CREATE OR REPLACE FUNCTION next_post_id_val_trigger()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL
AS $BODY$
BEGIN
  NEW.random_id = next_post_id_val();
  RETURN NEW;
END;
$BODY$;

# Trigger calling next_post_id_val_trigger() on posts INSERT
CREATE TRIGGER next_post_id_val_trigger
 BEFORE INSERT
  ON posts
  FOR EACH ROW
   EXECUTE PROCEDURE next_post_id_val_trigger();

# Pass table to the function

# Function to get random integer
CREATE OR REPLACE FUNCTION random_val() RETURNS integer
AS $BODY$
DECLARE
  randInteger INT;
BEGIN
  SELECT (SELECT FLOOR(RANDOM() * 10 + 1)::INT) INTO randInteger;
  RETURN randInteger;
END;
$BODY$
LANGUAGE PLPGSQL;
SELECT * FROM random_val();

# Function to get the next incremented id of any tables
CREATE OR REPLACE FUNCTION next_id_val(tableName text) RETURNS integer
AS $BODY$
DECLARE
  lastId INT;
  randInteger INT;
  nextId INT;
BEGIN
  EXECUTE format('SELECT MAX(id) FROM %s', tableName)
  INTO lastId;

  randInteger := random_val();

  IF lastId IS NULL
  THEN
    nextId := randInteger;
  ELSE
    nextId := lastId + randInteger;
  END IF;

  RETURN nextId;
END;
$BODY$
LANGUAGE PLPGSQL;
SELECT * FROM next_id_val('posts');

# Function to assign the next incremented id to <any table>.id
CREATE OR REPLACE FUNCTION next_id_val_trigger()
  RETURNS TRIGGER
AS $BODY$
DECLARE
  tableName text;
BEGIN
  tableName := TG_ARGV[0];
  NEW.id = next_id_val(tableName);
  RETURN NEW;
END;
$BODY$
LANGUAGE PLPGSQL;

# Trigger calling next_id_val_trigger(<tableName>) on posts INSERT
DROP TRIGGER IF EXISTS next_post_id_val_trigger ON posts CASCADE;
CREATE TRIGGER next_post_id_val_trigger
 BEFORE INSERT
  ON posts
  FOR EACH ROW
   EXECUTE PROCEDURE next_id_val_trigger('posts');
