# https://www.postgresql.org/docs/11/sql-createfunction.html

# https://www.postgresql.org/docs/11/sql-createtrigger.html

# Simple function to get the incremented next id

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

SELECT * FROM next_post_id_val();

CREATE OR REPLACE FUNCTION next_post_id_val_trigger()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL
AS $BODY$
BEGIN
  NEW.random_id = next_post_id_val();
  RETURN NEW;
END;
$BODY$;

CREATE TRIGGER next_post_id_val_trigger
 BEFORE INSERT
  ON posts
  FOR EACH ROW
   EXECUTE PROCEDURE next_post_id_val_trigger();

# Pass table to the function

CREATE OR REPLACE FUNCTION next_id_val(tableName text) RETURNS integer
AS $BODY$
DECLARE
  lastId INT;
  randInteger INT;
  nextId INT;
BEGIN
  EXECUTE format('SELECT MAX(id) FROM %s', tableName)
  INTO lastId;

  SELECT (SELECT FLOOR(RANDOM() * 10 + 1)::INT) INTO randInteger;

  nextId := lastId + randInteger;

  RETURN nextId;
END;
$BODY$
LANGUAGE PLPGSQL;
SELECT * FROM next_id_val('posts');

CREATE OR REPLACE FUNCTION next_id_val_trigger()
  RETURNS TRIGGER
AS $BODY$
DECLARE
  tableName text;
BEGIN
  tableName := TG_ARGV[0];
  NEW.random_id = next_id_val(tableName);
  RETURN NEW;
END;
$BODY$
LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS next_post_id_val_trigger ON posts CASCADE;

CREATE TRIGGER next_post_id_val_trigger
 BEFORE INSERT
  ON posts
  FOR EACH ROW
   EXECUTE PROCEDURE next_id_val_trigger('posts');
