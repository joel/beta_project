SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.posts (
    id bigint NOT NULL,
    random_id bigint,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

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

DROP TRIGGER IF EXISTS next_post_id_val_trigger ON posts CASCADE;
CREATE TRIGGER next_post_id_val_trigger
 BEFORE INSERT
  ON posts
  FOR EACH ROW
   EXECUTE PROCEDURE next_id_val_trigger('posts');

INSERT INTO "schema_migrations" (version) VALUES
('20210917095639');
