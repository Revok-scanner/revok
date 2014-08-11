SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET search_path = public, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;

--
-- Name: runcases; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE runcases(
    id character varying(64) NOT NULL,
    process character varying(10),
    scanConfig integer DEFAULT 0,
    targetInfo text NOT NULL,
    log text,
    startTime integer DEFAULT date_part('epoch'::text, now()),
    endTime integer DEFAULT date_part('epoch'::text, now()),
    requestor character varying(60)
);

--
-- Name: runcases; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY runcases
    ADD CONSTRAINT runcases_pkey PRIMARY KEY (id);


