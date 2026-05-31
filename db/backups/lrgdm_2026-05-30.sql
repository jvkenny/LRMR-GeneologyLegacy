--
-- PostgreSQL database dump
--

\restrict dffS5mi7DsghD0oQoXRipcIYZmay0BSdS3V1bVbHfpgy9BMc2JSrmLianWW9GVH

-- Dumped from database version 18.3 (Homebrew)
-- Dumped by pg_dump version 18.3 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: citation_subject_fk(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.citation_subject_fk() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
DECLARE ok boolean;
BEGIN
  EXECUTE format(
    'SELECT EXISTS(SELECT 1 FROM %I WHERE %I = $1)',
    CASE NEW.subject_type
      WHEN 'person' THEN 'person' WHEN 'event' THEN 'event'
      WHEN 'place'  THEN 'place'  WHEN 'relationship' THEN 'relationship' END,
    CASE NEW.subject_type
      WHEN 'person' THEN 'person_id' WHEN 'event' THEN 'event_id'
      WHEN 'place'  THEN 'place_id'  WHEN 'relationship' THEN 'rel_id' END)
  INTO ok USING NEW.subject_id;
  IF NOT ok THEN
    RAISE EXCEPTION 'citation.subject_id % not found in % table', NEW.subject_id, NEW.subject_type;
  END IF;
  RETURN NEW;
END;
$_$;


--
-- Name: lrgdm_era(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lrgdm_era(yr integer) RETURNS text
    LANGUAGE sql STABLE
    AS $$
  SELECT label FROM era
  WHERE yr IS NOT NULL
    AND (year_start IS NULL OR yr >= year_start)
    AND (year_end   IS NULL OR yr <  year_end)
  ORDER BY sort_order
  LIMIT 1;
$$;


--
-- Name: lrgdm_year(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lrgdm_year(d text) RETURNS integer
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT NULLIF(substring(d FROM '\d{4}'), '')::int;
$$;


--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: citation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.citation (
    citation_id bigint NOT NULL,
    source_id text NOT NULL,
    subject_type text NOT NULL,
    subject_id text NOT NULL,
    subject_field text,
    claim text,
    confidence text,
    conflicts_flag boolean DEFAULT false NOT NULL,
    locator text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT citation_confidence_check CHECK ((confidence = ANY (ARRAY['high'::text, 'med'::text, 'low'::text]))),
    CONSTRAINT citation_subject_type_check CHECK ((subject_type = ANY (ARRAY['person'::text, 'event'::text, 'place'::text, 'relationship'::text])))
);


--
-- Name: citation_citation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.citation_citation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: citation_citation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.citation_citation_id_seq OWNED BY public.citation.citation_id;


--
-- Name: era; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.era (
    code text NOT NULL,
    label text NOT NULL,
    year_start integer,
    year_end integer,
    sort_order integer NOT NULL
);


--
-- Name: event; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event (
    event_id text NOT NULL,
    title text,
    event_type text,
    date_start text,
    date_end text,
    date_granularity text,
    place_id text,
    importance integer,
    confidence text,
    description text,
    privacy_level text DEFAULT 'public'::text NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT event_confidence_check CHECK ((confidence = ANY (ARRAY['high'::text, 'med'::text, 'low'::text]))),
    CONSTRAINT event_privacy_level_check CHECK ((privacy_level = ANY (ARRAY['public'::text, 'private'::text])))
);


--
-- Name: event_participant; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event_participant (
    id bigint NOT NULL,
    event_id text NOT NULL,
    person_id text NOT NULL,
    role text
);


--
-- Name: event_participant_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.event_participant_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_participant_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.event_participant_id_seq OWNED BY public.event_participant.id;


--
-- Name: event_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event_type (
    code text NOT NULL,
    label text,
    description text
);


--
-- Name: media; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.media (
    media_id text NOT NULL,
    media_type text,
    title text,
    caption text,
    file_path text,
    url text,
    mime_type text,
    sha256 text,
    bytes bigint,
    captured_date text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT media_media_type_check CHECK ((media_type = ANY (ARRAY['image'::text, 'scan'::text, 'pdf'::text, 'audio'::text, 'video'::text])))
);


--
-- Name: media_link; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.media_link (
    id bigint NOT NULL,
    media_id text NOT NULL,
    subject_type text NOT NULL,
    subject_id text NOT NULL,
    role text,
    sort_order integer DEFAULT 0 NOT NULL,
    CONSTRAINT media_link_subject_type_check CHECK ((subject_type = ANY (ARRAY['person'::text, 'event'::text, 'place'::text, 'source'::text])))
);


--
-- Name: media_link_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.media_link_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: media_link_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.media_link_id_seq OWNED BY public.media_link.id;


--
-- Name: narrative; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.narrative (
    person_id text NOT NULL,
    dossier_date date,
    body_md text,
    rendered_html text,
    published boolean DEFAULT true NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: person; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.person (
    person_id text NOT NULL,
    primary_name text NOT NULL,
    sex text,
    birth_date text,
    birth_granularity text,
    birth_place_id text,
    death_date text,
    death_granularity text,
    death_place_id text,
    life_confidence text,
    privacy_level text DEFAULT 'public'::text NOT NULL,
    branch text,
    fs_id text,
    notes text,
    profile_media_id text,
    source_summary text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT person_birth_granularity_check CHECK ((birth_granularity = ANY (ARRAY['day'::text, 'month'::text, 'year'::text, 'decade'::text, 'circa'::text]))),
    CONSTRAINT person_death_granularity_check CHECK ((death_granularity = ANY (ARRAY['day'::text, 'month'::text, 'year'::text, 'decade'::text, 'circa'::text]))),
    CONSTRAINT person_life_confidence_check CHECK ((life_confidence = ANY (ARRAY['high'::text, 'med'::text, 'low'::text]))),
    CONSTRAINT person_privacy_level_check CHECK ((privacy_level = ANY (ARRAY['public'::text, 'private'::text]))),
    CONSTRAINT person_sex_check CHECK ((sex = ANY (ARRAY['male'::text, 'female'::text, 'unknown'::text])))
);


--
-- Name: person_name; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.person_name (
    id bigint NOT NULL,
    person_id text NOT NULL,
    name_type text NOT NULL,
    value text NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT person_name_name_type_check CHECK ((name_type = ANY (ARRAY['primary'::text, 'birth'::text, 'married'::text, 'maiden'::text, 'nickname'::text, 'alias'::text, 'variant'::text])))
);


--
-- Name: person_name_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.person_name_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: person_name_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.person_name_id_seq OWNED BY public.person_name.id;


--
-- Name: place; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.place (
    place_id text NOT NULL,
    name text NOT NULL,
    std_name text,
    geom public.geometry(Point,4326),
    admin_hierarchy text,
    geocode_quality text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    historical_name text,
    notes text,
    time_valid_from text,
    time_valid_to text
);


--
-- Name: relation_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.relation_type (
    code text NOT NULL,
    label text
);


--
-- Name: relationship; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.relationship (
    rel_id text NOT NULL,
    person_id_a text NOT NULL,
    relation text NOT NULL,
    person_id_b text NOT NULL,
    start_date text,
    end_date text,
    evidence_note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: research_lead; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.research_lead (
    id bigint NOT NULL,
    person_id text,
    category text,
    description text NOT NULL,
    status text DEFAULT 'open'::text NOT NULL,
    source_dossier text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT research_lead_status_check CHECK ((status = ANY (ARRAY['open'::text, 'in_progress'::text, 'done'::text, 'dropped'::text])))
);


--
-- Name: research_lead_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.research_lead_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: research_lead_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.research_lead_id_seq OWNED BY public.research_lead.id;


--
-- Name: source; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.source (
    source_id text NOT NULL,
    source_type text,
    title text NOT NULL,
    informant text,
    repository text,
    url text,
    citation text,
    source_date text,
    accessed_date date,
    confidence text,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT source_confidence_check CHECK ((confidence = ANY (ARRAY['high'::text, 'med'::text, 'low'::text])))
);


--
-- Name: source_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.source_type (
    code text NOT NULL,
    label text
);


--
-- Name: v_birth_location_points; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_birth_location_points AS
 SELECT p.person_id,
    p.primary_name,
    p.birth_date,
    public.lrgdm_year(p.birth_date) AS birth_year,
    public.lrgdm_era(public.lrgdm_year(p.birth_date)) AS era,
    p.privacy_level,
    pl.geom
   FROM (public.person p
     JOIN public.place pl ON ((pl.place_id = p.birth_place_id)))
  WHERE (pl.geom IS NOT NULL);


--
-- Name: v_birth_to_death_lines; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_birth_to_death_lines AS
 SELECT p.person_id,
    p.primary_name,
    (public.st_makeline(b.geom, d.geom))::public.geometry(LineString,4326) AS geom
   FROM ((public.person p
     JOIN public.place b ON ((b.place_id = p.birth_place_id)))
     JOIN public.place d ON ((d.place_id = p.death_place_id)))
  WHERE ((b.geom IS NOT NULL) AND (d.geom IS NOT NULL) AND (NOT public.st_equals(b.geom, d.geom)));


--
-- Name: v_birth_to_death_lines_eras; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_birth_to_death_lines_eras AS
 SELECT p.person_id,
    p.primary_name,
    public.lrgdm_year(p.birth_date) AS birth_year,
    public.lrgdm_year(p.death_date) AS death_year,
    ((public.lrgdm_year(p.birth_date) + public.lrgdm_year(p.death_date)) / 2) AS mid_year,
    public.lrgdm_era(((public.lrgdm_year(p.birth_date) + public.lrgdm_year(p.death_date)) / 2)) AS era,
    (public.st_makeline(b.geom, d.geom))::public.geometry(LineString,4326) AS geom
   FROM ((public.person p
     JOIN public.place b ON ((b.place_id = p.birth_place_id)))
     JOIN public.place d ON ((d.place_id = p.death_place_id)))
  WHERE ((b.geom IS NOT NULL) AND (d.geom IS NOT NULL) AND (NOT public.st_equals(b.geom, d.geom)));


--
-- Name: v_citations_expanded; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_citations_expanded AS
 SELECT c.citation_id,
    c.subject_type,
    c.subject_id,
    c.subject_field,
    c.claim,
    c.confidence,
    c.conflicts_flag,
    c.locator,
    s.source_id,
    s.source_type,
    s.title AS source_title,
    s.repository,
    s.url
   FROM (public.citation c
     JOIN public.source s ON ((s.source_id = c.source_id)));


--
-- Name: v_death_location_points; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_death_location_points AS
 SELECT p.person_id,
    p.primary_name,
    p.death_date,
    public.lrgdm_year(p.death_date) AS death_year,
    public.lrgdm_era(public.lrgdm_year(p.death_date)) AS era,
    p.privacy_level,
    pl.geom
   FROM (public.person p
     JOIN public.place pl ON ((pl.place_id = p.death_place_id)))
  WHERE (pl.geom IS NOT NULL);


--
-- Name: v_event_participants; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_event_participants AS
 SELECT ep.id,
    ep.event_id,
    e.title,
    e.event_type,
    e.date_start,
    ep.person_id,
    p.primary_name,
    ep.role,
    pl.geom
   FROM (((public.event_participant ep
     JOIN public.event e ON ((e.event_id = ep.event_id)))
     JOIN public.person p ON ((p.person_id = ep.person_id)))
     LEFT JOIN public.place pl ON ((pl.place_id = e.place_id)));


--
-- Name: v_event_points; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_event_points AS
 SELECT e.event_id,
    e.title,
    e.event_type,
    e.date_start,
    e.date_end,
    e.confidence,
    e.privacy_level,
    pl.geom
   FROM (public.event e
     JOIN public.place pl ON ((pl.place_id = e.place_id)))
  WHERE (pl.geom IS NOT NULL);


--
-- Name: v_person_locations; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_person_locations AS
 SELECT p.person_id,
    p.primary_name,
    'birth'::text AS role,
    pl.place_id,
    pl.geom
   FROM (public.person p
     JOIN public.place pl ON ((pl.place_id = p.birth_place_id)))
  WHERE (pl.geom IS NOT NULL)
UNION
 SELECT p.person_id,
    p.primary_name,
    'death'::text AS role,
    pl.place_id,
    pl.geom
   FROM (public.person p
     JOIN public.place pl ON ((pl.place_id = p.death_place_id)))
  WHERE (pl.geom IS NOT NULL)
UNION
 SELECT ep.person_id,
    p.primary_name,
    COALESCE(NULLIF(ep.role, ''::text), 'event'::text) AS role,
    pl.place_id,
    pl.geom
   FROM (((public.event_participant ep
     JOIN public.event e ON ((e.event_id = ep.event_id)))
     JOIN public.person p ON ((p.person_id = ep.person_id)))
     JOIN public.place pl ON ((pl.place_id = e.place_id)))
  WHERE (pl.geom IS NOT NULL);


--
-- Name: v_source_summary; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_source_summary AS
 SELECT c.subject_id AS person_id,
    string_agg(DISTINCT s.title, '; '::text ORDER BY s.title) AS source_summary,
    count(*) AS citation_count
   FROM (public.citation c
     JOIN public.source s ON ((s.source_id = c.source_id)))
  WHERE (c.subject_type = 'person'::text)
  GROUP BY c.subject_id;


--
-- Name: citation citation_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.citation ALTER COLUMN citation_id SET DEFAULT nextval('public.citation_citation_id_seq'::regclass);


--
-- Name: event_participant id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_participant ALTER COLUMN id SET DEFAULT nextval('public.event_participant_id_seq'::regclass);


--
-- Name: media_link id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_link ALTER COLUMN id SET DEFAULT nextval('public.media_link_id_seq'::regclass);


--
-- Name: person_name id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.person_name ALTER COLUMN id SET DEFAULT nextval('public.person_name_id_seq'::regclass);


--
-- Name: research_lead id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.research_lead ALTER COLUMN id SET DEFAULT nextval('public.research_lead_id_seq'::regclass);


--
-- Data for Name: citation; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.citation (citation_id, source_id, subject_type, subject_id, subject_field, claim, confidence, conflicts_flag, locator, created_at) FROM stdin;
157	S-0001	person	P-0167	birth_date	Born 3 November 1961	high	f	card body: 'Born NOVEMBER 3, 1961'	2026-05-30 12:24:02.787679-05
158	S-0001	person	P-0167	death_date	Died ('At Peace') 17 October 2025	high	f	card body: 'At Peace OCTOBER 17, 2025'	2026-05-30 12:24:02.787679-05
208	S-8141B6A4	person	P-0078	\N	Numerous 1908–1943 Cook County death/birth records are mis-attached to Paul on FS (other Pouliots, several dying after 1903) — FS data-hygiene issue, not facts about this Paul	high	t	\N	2026-05-30 20:44:12.395074-05
159	S-7CE9FAE0	person	P-0070	\N	John T. Reed, b. 1841, d. 11 Nov 1903, buried Monteith Cemetery, Guthrie Co., Iowa; recorded as "s/o Bonam" and "h/o Elizabeth" — independently confirms parentage (Bonum Reed), spouse (Elizabeth), birth year, death date, and burial.	high	f	\N	2026-05-30 13:43:52.653522-05
160	S-7CE9FAE0	person	P-0070	\N	Wife Elizabeth Reed, b. 26 Jun 1846, d. 21 Dec 1880, Monteith Cemetery Lot 18, "w/o John" — supplies Elizabeth's exact birth date (DB had "circa 1846") and a death date one day off the DB value.	high	t	\N	2026-05-30 13:43:52.653522-05
161	S-7CE9FAE0	person	P-0070	\N	Father Bonam (Bonum) Reed, d. 13 Dec 1893 at age 77, Monteith Cemetery Lot 6, "h/o Rebecca" — corroborates P-0001 death date exactly.	high	f	\N	2026-05-30 13:43:52.653522-05
162	S-7CE9FAE0	person	P-0070	\N	Mother Rebecca Reed, d. 16 Jul 1911 at age 88, Monteith Cemetery Lot 6, "w/o Bonam" — supplies exact death date (DB had year only, "1911") and implies birth ~1822/1823.	high	f	\N	2026-05-30 13:43:52.653522-05
163	S-DA90F5B1	person	P-0070	\N	The Bonum Reed family occupies the Monteith Cemetery plot (Lot 6 = Bonum & Rebecca; Lot 18 = Elizabeth); John T. Reed is buried in the same cemetery. Monteith Cemetery (Monteith, Guthrie Co., IA) holds ~488 burials.	high	f	\N	2026-05-30 13:43:52.653522-05
164	S-13D70DD6	person	P-0070	\N	A second, unrelated Reed family was prominent in the same county: Samuel & Anna Reed and their sons (Theodore P., Culbertson F.), buried at Valley/Union cemeteries; "Mr. and Mrs. [T.P.] Reed came to this county in 1857." Useful for disambiguation — these are NOT John T.'s line.	med	f	\N	2026-05-30 13:43:52.653522-05
165	S-5F963BBF	person	P-0070	\N	Sidney R. (Riley) Reed, 29 Apr 1859 – 30 Apr 1934, buried Monteith Cemetery, served in the Iowa General Assembly (37th GA, 1917 session). Possibly a younger brother of John T. (both Monteith, Bonum-era) but parentage not confirmed this dive.	low	f	\N	2026-05-30 13:43:52.653522-05
166	S-3AC5E090	person	P-0070	\N	No obituary for John T. Reed (d. 1903) located in open Guthrie County collections (Genealogy Trails, IAGenWeb obit indexes); the Panora/Guthrie Center newspaper run for Nov 1903 is not digitized in the open archives searched. Negative finding.	\N	f	\N	2026-05-30 13:43:52.653522-05
167	S-F50FBD95	person	P-0070	\N	Civil War: the only Ohio-roster "John **T.** Reed" (matching his middle initial) served in the **21st OVI, Co. F** — a **northwest** Ohio regiment (Hancock Co., org. Findlay), whole company enrolled Sept 6 1861, 3-yr term. Geographically wrong for a Monroe/Noble Co. man, and the enrollment collides with his Sept 19 1861 Noble Co. wedding. Assessed as a **different** John T. Reed.	low	f	\N	2026-05-30 13:43:52.653522-05
168	S-70E4E2BE	person	P-0070	\N	His home regiment, the **116th OVI** (org. Marietta/Gallipolis; Co. H heavily Noble County), contains **no John Reed** — only a "Reed, Willard." Negative finding for the most geographically likely unit.	med	f	\N	2026-05-30 13:43:52.653522-05
169	S-70E4E2BE	person	P-0070	\N	A geographically/chronologically plausible candidate exists — "Reed, John" (no middle initial) in the **122nd OVI, Co. I** (org. Zanesville Sept 1862, SE Ohio) — but it is indistinguishable from any other John Reed, and the Ohio roster records no residence to confirm. Inconclusive.	low	f	\N	2026-05-30 13:43:52.653522-05
170	S-7CE9FAE0	person	P-0070	\N	The WPA cemetery survey entry for John T. Reed carries **no veteran/GAR notation** (such surveys routinely flagged veterans), a weak negative indicator of Civil War service.	low	f	\N	2026-05-30 13:43:52.653522-05
171	S-F6A67948	person	P-0062	\N	Born 19 July 1899, Guthrie County, Iowa (indexed "Wayne E"/"Earl Wayne")	high	f	\N	2026-05-30 15:38:23.279346-05
172	S-E3E75D10	person	P-0062	\N	1900 census: in household of John F. Reed (head) & Gertrude E. Reed, "Wayne E Reed" age 1, Valley Twp / Guthrie Center, Guthrie Co, IA	high	f	\N	2026-05-30 15:38:23.279346-05
173	S-5F9361B1	person	P-0062	\N	Brother **Harold Merle Reed** died 26 Feb 1921 in **Panama**, age ~20	med	f	\N	2026-05-30 15:38:23.279346-05
174	S-E3E75D10	person	P-0062	\N	WWI draft registration, 1917-18, registered at **Waukesha, Waukesha Co, Wisconsin** (indexed "Earle Wayne Reed")	high	f	\N	2026-05-30 15:38:23.279346-05
175	S-E3E75D10	person	P-0062	\N	1930 census: residing **Cicero, Cook Co, Illinois** (indexed "Earl W Reed")	high	f	\N	2026-05-30 15:38:23.279346-05
176	S-E3E75D10	person	P-0062	\N	Son **Earl Wayne Reed Jr** born 9 Dec 1930, Chicago, Cook Co, IL	high	f	\N	2026-05-30 15:38:23.279346-05
177	S-E3E75D10	person	P-0062	\N	Son **John Ronald Reed** born 1934, Cook Co, IL	high	f	\N	2026-05-30 15:38:23.279346-05
178	S-5F9361B1	person	P-0062	\N	Son **James Gary Reed** born 9 Oct 1939, Chicago, Cook Co, IL	med	f	\N	2026-05-30 15:38:23.279346-05
179	S-E3E75D10	person	P-0062	\N	1940 census: residing **Cicero, Cook Co, Illinois**	high	f	\N	2026-05-30 15:38:23.279346-05
180	S-E3E75D10	person	P-0062	\N	WWII draft registration, 1942, Illinois ("old man's registration")	high	f	\N	2026-05-30 15:38:23.279346-05
181	S-E3E75D10	person	P-0062	\N	1950 census: residing **Chicago, Cook Co, Illinois**	high	f	\N	2026-05-30 15:38:23.279346-05
182	S-EABD01D2	person	P-0062	\N	**Died 7 April 1974, Elk Grove Village (Elk Grove Twp), Cook Co, Illinois**, age 74	high	f	\N	2026-05-30 15:38:23.279346-05
183	S-EABD01D2	person	P-0062	\N	Occupation at death: **Carpenter**; race White; marital status Married	high	f	\N	2026-05-30 15:38:23.279346-05
184	S-EABD01D2	person	P-0062	\N	Last residence: **4 N 711 Medinah Road, Addison, DuPage Co, Illinois**	high	f	\N	2026-05-30 15:38:23.279346-05
185	S-0D54D37B	person	P-0062	\N	**Buried 11 April 1974, Lakewood Memorial Park ("Lake St Mem Park"), Elgin, Illinois**; Martin Funeral Home Ltd; informant on death record was "John Reed" (likely son John Ronald)	high	f	\N	2026-05-30 15:38:23.279346-05
186	S-0D54D37B	person	P-0062	\N	FindAGrave memorial has a headstone photograph and a biography	med	f	\N	2026-05-30 15:38:23.279346-05
187	S-E3E75D10	person	P-0062	\N	SSN/NUMIDENT record on file (indexed "Earl W Reed")	med	f	\N	2026-05-30 15:38:23.279346-05
188	S-5F9361B1	person	P-0062	\N	Father John Foulk Reed died 30 Mar 1952, Davenport, Scott Co, IA	high	f	\N	2026-05-30 15:38:23.279346-05
82	S-36D10AC3	person	P-0036	\N	Born 30 October 1882 in Seely Township, Guthrie County, Iowa	high	f	\N	2026-05-30 09:53:51.446353-05
83	S-D3DD5D0F	person	P-0036	\N	Died 20 May 1946 in Chicago, Cook County, Illinois (age 63)	high	f	\N	2026-05-30 09:53:51.446353-05
84	S-D3DD5D0F	person	P-0036	\N	Buried 23 May 1946 at **Prairie Home Cemetery, Waukesha, Wisconsin**	high	f	\N	2026-05-30 09:53:51.446353-05
85	S-306EE8EC	person	P-0036	\N	Father: Abiram Stacy Lambert (1831-01-09 – 1927-04-28), FS PID 2WFL-ZVT	high	f	\N	2026-05-30 09:53:51.446353-05
86	S-454BFE1A	person	P-0036	\N	Mother: Helen Amelia Boles (1849-06-10 – 1939-01-23), FS PID 29WD-T9P. Helen had **three marriages**: first to a Mr Foote (children Clara b.~1869, Arthur b.~1870, possibly Edwin b.~1881); second to Abiram Lambert (1881-10, children Estelle and Sylvia); third to Leslie Knapp by 1895. Buried as "Helen Amelia Knapp" at Violet Hill Cemetery, Perry, Dallas Co, Iowa.	high	t	\N	2026-05-30 09:53:51.446353-05
87	S-3A1CF2A9	person	P-0036	\N	First spouse: John Foulk Reed (1877-11-25 – 1952-03-30), FS PID KLGC-TLC, m. **5 March 1899** in Guthrie County, Iowa; he was the head of household by the 1900 US Census in Valley Twp, Guthrie Center, Iowa. Birthplace Monteith IA; died Davenport IA; buried Oakdale Memorial Gardens, Davenport.	high	f	\N	2026-05-30 09:53:51.446353-05
88	S-80F41041	person	P-0036	\N	(preserved from AM) Marriage to John Foulk Reed in Monteith Valley, Guthrie Co, Iowa — `evidence_note` on R-0129	med	f	\N	2026-05-30 09:53:51.446353-05
89	S-E658B293	person	P-0036	\N	First child: Earl Wayne Reed Sr (1899-07-19 – 1974), FS PID M3P5-XF6, born Guthrie Co IA. Listed in 1900 US Census as "Wayne E Reed, son, 1 year." Cook County, IL death record (Q2MN-CMG6) names his father as "John Reed" and gives death date **7 April 1974** (FS-extract had 11 April — minor record-vs-tree conflict).	high	f	\N	2026-05-30 09:53:51.446353-05
90	S-AD3D3F97	person	P-0036	\N	Second child (NEW): **Harold Merle Reed**, born 7 January 1901 in Guthrie Co IA, parents John F. Reed and Estelle Gertrude Reed (née Lambert).	high	f	\N	2026-05-30 09:53:51.446353-05
91	S-99C163B4	person	P-0036	\N	Third child (NEW): **Oscar G. Reed**, born 1903 in Guthrie Co IA, parents John F. Reed and Estella G. "Laubert" (Lambert).	high	f	\N	2026-05-30 09:53:51.446353-05
92	S-FDF13B88	person	P-0036	\N	Fourth child (NEW): **Edna Gertrude Reed**, born 16 August 1906 in Iowa, parents John F. Reed and Estelle Gertrude Lambert. Appears later as "Edna Eichinger" (1920 US Census, age 13, in Sioux Falls SD with stepfather Clarence) and as "Edna Reed, daughter, 18" (1925 IA State Census, Waterloo).	high	f	\N	2026-05-30 09:53:51.446353-05
93	S-4828EF7A	person	P-0036	\N	**Second marriage:** Estella G. Reed → **Clarence D. Eichinger**, married **18 September 1912 in Algona, Kossuth County, Iowa**. Estella's marital status on the license: "Widowed" (almost certainly a polite misstatement — her first husband John Foulk Reed did not actually die until 1952). Clarence: b. Lafayette, Indiana, son of John Eichinger and Mary Jane Towers, first marriage for him.	high	f	\N	2026-05-30 09:53:51.446353-05
94	S-792A1300	person	P-0036	\N	Fifth child (NEW, Eichinger): **Ray Eichinger**, born ~1914 in Iowa (age 6 in 1920 census, age 11 in 1925). Almost certainly Clarence + Estelle's son.	high	f	\N	2026-05-30 09:53:51.446353-05
95	S-0E9B4AC0	person	P-0036	\N	1900 US Census household at Valley Township / Guthrie Center, Guthrie County, Iowa: John F. Reed 23 (head), Gertrude E. Reed 19 (wife, "Years Married 1," "Number of Living Children 1"), Wayne E. Reed 1 (son). Sheet 15B, line 61, ED 66, household 367.	high	f	\N	2026-05-30 09:53:51.446353-05
96	S-A12E8B14	person	P-0036	\N	1920 US Census household at **Sioux Falls Ward 11, Minnehaha County, South Dakota** (ED 202, household 80, sheet 4A): Clarence Eichinger 36 (head, b. Indiana), **Gertrude Eichinger 37** (wife, b. Iowa, father's birthplace Pennsylvania, mother's Michigan), Edna Eichinger 13 (b. Iowa — actually Edna Gertrude Reed under stepfather's name), Ray Eichinger 6 (b. Iowa).	high	f	\N	2026-05-30 09:53:51.446353-05
97	S-EFEA344C	person	P-0036	\N	1925 Iowa State Census household at **Waterloo (4th Ward), Black Hawk County, Iowa**, house #134: Clarence Eichinger 41 (head), Gertrude Eichinger 40 (wife), Ray Eichinger 11 (son), **Edna Reed 18** (daughter — kept her Reed surname).	high	f	\N	2026-05-30 09:53:51.446353-05
98	S-3C8DEC75	person	P-0036	\N	1885 Iowa State Census household at **Seely, Guthrie County, Iowa**: Abiram L. Lambert 53, Helen A. Lambert 34, **Gertrude Lambert 2** (Estelle herself), **Sylvia L. Lambert 1** (younger sister, NEW), Clara L. Foote 16, Arthur Foote 15, Edwin Foote 4 (Helen's stepchildren from her first marriage to a Foote).	high	f	\N	2026-05-30 09:53:51.446353-05
99	S-0F37D24C	person	P-0036	\N	By the **1895 Iowa State Census**, Helen had separated from Abiram and remarried, appearing as "Helen Amelia Knapp" with "Leslie Knapp." Estelle was 12 and still listed under her original name as "Stella Gertrude Lambert."	high	t	\N	2026-05-30 09:53:51.446353-05
100	S-D3DD5D0F	person	P-0036	\N	**Third marriage / death name:** Estelle died as "Estelle G **Sinderson**." Cook County death certificate names spouse "Harry" (presumably Harry Sinderson). Death cert details: age 63, address 1339 S 48 St (Chicago — West Side, Lawndale/Cicero border), **marital status: Divorced**, occupation: **Waitress**, race: White, funeral home **O'Shea And Raleigh**, cemetery Prairie Home, burial place Waukesha WI, entry number 15350. Birthplace recorded as "Guthrie Center, Iowa" (informant-given, less precise than her actual Seely Township birthplace).	high	f	\N	2026-05-30 09:53:51.446353-05
101	S-3140FE85	person	P-0036	\N	Estelle's mother Helen had also been married to a Foote before Abiram — i.e. Helen Boles → Mrs. Foote → Mrs. Lambert → Mrs. Knapp. The Foote stepchildren (Clara, Arthur, Edwin) lived in the Lambert household when Estelle was a small child.	high	f	\N	2026-05-30 09:53:51.446353-05
102	S-BC6891C3	person	P-0036	\N	Husband's family founded Monteith, Iowa. Town was platted 1881 by **Harmon T. Reed** following the railroad's arrival.	high	f	\N	2026-05-30 09:53:51.446353-05
103	S-7E85F67E	person	P-0056	\N	Born **18 Jul 1934, Chicago, Cook County, IL**.	high	f	\N	2026-05-30 09:53:51.446353-05
104	S-860A19C8	person	P-0056	\N	Died **2 May 1995**; last residence **Glen Ellyn, DuPage Co. (ZIP 60137)**.	high	f	\N	2026-05-30 09:53:51.446353-05
105	S-7E85F67E	person	P-0056	\N	Parents: **Earl W. Reed** & **Isabelle Zika**.	high	f	\N	2026-05-30 09:53:51.446353-05
106	S-7E85F67E	person	P-0056	\N	**Applied for Social Security Feb 1949** (age 14) — = GPKG event E-0025.	high	f	\N	2026-05-30 09:53:51.446353-05
107	S-8F4C3FCC	person	P-0056	\N	**1950 census:** Cicero, Cook Co. (ED 104-1), age 15, single, "Son."	high	f	\N	2026-05-30 09:53:51.446353-05
108	S-8F4C3FCC	person	P-0056	\N	By 1950 mother **Isabelle divorced & head of household**, "Biller" at a "Telephone Factory" (Western Electric Hawthorne).	high	f	\N	2026-05-30 09:53:51.446353-05
109	S-8F4C3FCC	person	P-0056	\N	Father **Earl Sr absent from 1950 household** → parents divorced **between 1940 and 1950**.	med	f	\N	2026-05-30 09:53:51.446353-05
110	S-891101CB	person	P-0056	\N	**Brother: Earl Wayne "Wayne" Reed Jr**, b. 9 Dec 1930 Chicago, d. 20 Jul 2024 Bartlett, IL; Hoffman Estates from 1961; m. Georgia Bogda.	high	f	\N	2026-05-30 09:53:51.446353-05
111	S-8F4C3FCC	person	P-0056	\N	**Brother: James "Jim" Reed**, b. ~1940, IL.	high	f	\N	2026-05-30 09:53:51.446353-05
112	S-891101CB	person	P-0056	\N	Wife confirmed as **"Leah"** — "brother of the late John (Leah)".	high	f	\N	2026-05-30 09:53:51.446353-05
113	S-14001891	person	P-0056	\N	**Married Leah Rae Mariotti in 1956** (Leah was 20); couple began married life in **Westchester, IL**.	high	f	\N	2026-05-30 09:53:51.446353-05
114	S-14001891	person	P-0056	\N	Settled in **Glen Ellyn ~1964** (Leah was a 61-year Glen Ellyn resident, d. 2025).	med	f	\N	2026-05-30 09:53:51.446353-05
115	S-14001891	person	P-0056	\N	John & Leah had **seven children** (including two sets of twins).	high	f	\N	2026-05-30 09:53:51.446353-05
116	S-14001891	person	P-0056	\N	John was **Roman Catholic** — family parish **St. James the Apostle, Glen Ellyn** (Leah's funeral mass).	med	f	\N	2026-05-30 09:53:51.446353-05
117	S-14001891	person	P-0056	\N	John **predeceased Leah**, who "became a young widow at 58" (i.e., 1995).	high	f	\N	2026-05-30 09:53:51.446353-05
118	S-1259ED34	person	P-0056	\N	Leah Rae Mariotti Reed **buried at Queen of Heaven Catholic Cemetery, Hillside, IL** (memorial #285158675). John has **no FindAGrave memorial** — grave undocumented online; likely the same Catholic family plot.	high	f	\N	2026-05-30 09:53:51.446353-05
119	S-14001891	person	P-0056	\N	John is the **maternal grandfather of the proband, John Kenny (L274-KNT)** — via his daughter Karen (Reed) Kenny. The repo's namesake, Leah, was the family genealogist who traced the line "back 10 generations" — the origin of the LRGDM.	high	f	\N	2026-05-30 09:53:51.446353-05
120	S-51B6AEA7	person	P-0056	\N	Wife Leah b. 1936/37 Illinois, raised in **Bedford, Taylor Co., Iowa**; parents **Ugo & Lena (Dini) Mariotti**; siblings **Roland** (dec.) & **Celeste**. (Corroborates the obituary; spouse-record enrichment.)	high	f	\N	2026-05-30 09:53:51.446353-05
121	S-84D090B0	person	P-0056	\N	**Served in the U.S. military during the Korean War.** Family recollection places his training at **Camp Pendleton, CA** — a USMC base, which would make him a **Marine**. Consistent with his age (turned 18 in July 1952, war ongoing until the July 1953 armistice); estimated service window ~1952–1956. Branch, base, and exact dates not yet documentarily confirmed (no online record — see §3 copyright/sourcing note and §6).	high	f	\N	2026-05-30 09:53:51.446353-05
122	S-EAFAD919	person	P-0059	\N	Born 21 July 1903 in Cintolese, Monsummano Terme, Pistoia, Tuscany, Italy.	high	f	\N	2026-05-30 09:53:51.446353-05
123	S-41743961	person	P-0059	\N	Died 20 February 1982, Cook County, Illinois, last residence ZIP 60650 (Cicero).	high	f	\N	2026-05-30 09:53:51.446353-05
124	S-AFE96315	person	P-0059	\N	Buried 23 February 1982 at Queen of Heaven Catholic Cemetery, Hillside, Cook County, Illinois. Plot: **Section 40, Block 213, Lot 7, Grave 8**. GPS 41.8442383, -87.9189224 (more precise than cemetery centroid). Photographed memorial; memorial includes biography.	high	f	\N	2026-05-30 09:53:51.446353-05
125	S-901C14F2	person	P-0059	\N	**Married Lena M. Dini on 5 May 1927 in Lenox, Taylor County, Iowa.** Ugo age 23 (b. ~1904 Italy), Lena age 17 (b. ~1910 Chicago IL). Marriage record p. 366.	high	f	\N	2026-05-30 09:53:51.446353-05
126	S-901C14F2	person	P-0059	\N	**Father: Leopoldo Mariotti** (indexed "Geopaldo" — OCR error for "Leopoldo" in handwritten record). Confirms P-0067 (Leopoldo Mariotti, b. 1871, d. 1933).	high	f	\N	2026-05-30 09:53:51.446353-05
127	S-901C14F2	person	P-0059	\N	**Mother: Quintilia Lenzi** (indexed "Quinta Ginse" — OCR error). Confirms P-0069 (Quintilia Lenzi, b. 1876, d. 1960) as Ugo's mother.	high	f	\N	2026-05-30 09:53:51.446353-05
128	S-FBA8255E	person	P-0059	\N	Naturalized US citizen 1927, Northern District of Illinois (Soundex Index to Naturalization Petitions, M1285, film #126). 1950 census later reports `Citizenship Status: yes`.	high	f	\N	2026-05-30 09:53:51.446353-05
129	S-3EF7B735	person	P-0059	\N	**Son Rolando ("Roland") Mariotti born 17 June 1929 in Cicero, Cook, Illinois.** Birth registered 21 Aug 1929, Certificate #228. Father "Hugo Mariotti" 25, Italian; mother "Lina Dini" 20, Cicero IL.	high	f	\N	2026-05-30 09:53:51.446353-05
130	S-16AC9E36	person	P-0059	\N	1930 US Census: Hugo Mariotti (26, head, married, Italy), Lena (20, IL), Roland (infant, IL) at **Bedford, Taylor County, Iowa**. ED 87-1A (later 87-3 in 1950). Sheet 6A line 7.	high	f	\N	2026-05-30 09:53:51.446353-05
131	S-93DF3F9C	person	P-0059	\N	1940 US Census: Hugo Mariotti (36, head, married, Italy), Lena (30, IL), Roland (10, IL), Leah Rae (3, IL) at **Bedford Township, Bedford City W of Madison St, Taylor County, Iowa**. Residence Date 1935 also Bedford — i.e. family had been in Bedford since at least 1935. ED 87-1A, line 14, sheet 13A.	high	f	\N	2026-05-30 09:53:51.446353-05
132	S-EAFAD919	person	P-0059	\N	**WWII Draft Registration 16 February 1942** (3rd Registration), Bedford, Taylor County, IA. Birthplace listed as **"Cintolese, Italy"**. Physical: 5'5", 160 lbs, light complexion, brown eyes, brown hair. **Employer: Self.** Nearest relative: Lena Mariotti.	high	f	\N	2026-05-30 09:53:51.446353-05
133	S-707ACA78	person	P-0059	\N	1950 US Census: Ugo Mariotti (46, head, married, b. Italy), Lena (40, IL), Leah Rae (13, IL), **Celiste Dee Mariotti** (6, IL) at **Bedford Township, Taylor County, Iowa**. ED 87-3, line 21, sheet 16. Roland absent (then ~20, likely in military). **Occupation: Proprietor. Industry: Candy Kitchen.** Citizenship Status yes.	high	f	\N	2026-05-30 09:53:51.446353-05
134	S-707ACA78	person	P-0059	\N	**Daughter Celiste Dee Mariotti** (also seen as "Celeste" in son Roland's obit) born ~1944 in Illinois. **First time daughter Celeste's full name and approximate birth year are recorded.**	high	f	\N	2026-05-30 09:53:51.446353-05
135	S-E7E14B49	person	P-0059	\N	**Daughter's birth certificate, 8 September 1936, Cook County, Illinois, Cert #32174**. The certificate is attached to Ugo's FS profile twice with the same cert number: one indexed entry has the daughter's name "UNKNOWN" with registration date 11 Sep 1936; the other has the daughter named **"Sarah Joy Mariotti"** with registration date 23 Sep 1936. **The 8 Sep 1936 birth date matches Leah Rae Mariotti's GPKG birth date exactly (P-0055).** Mother on cert: "Lena Dini" 27, Chicago IL. The two entries appear to be the same record indexed twice — one before, one after a name was supplied to the registrar.	high	f	\N	2026-05-30 09:53:51.446353-05
136	S-79D5EA92	person	P-0059	\N	Cintolese was founded as a settlement on land reclaimed from the Fucecchio marshes in the second half of the 18th century under Grand Duke Pietro Leopoldo. Its parish, **San Leopoldo in Cintolese**, was established 1781, the church consecrated 10 March 1788, in tribute to the Lorraine grand duke. This is the parish in which Ugo would have been baptized.	high	f	\N	2026-05-30 09:53:51.446353-05
137	S-0FCB8893	person	P-0059	\N	Tuscany was an "early generator" Italian emigrant region from the 1870s onward; the Pistoia province sent steady streams of agricultural laborers to the Americas through the early 20th century.	high	f	\N	2026-05-30 09:53:51.446353-05
138	S-707ACA78	person	P-0059	\N	**Bedford, Iowa is a small town in Taylor County (sw IA, ~1,500 people in 1930).** That Ugo Mariotti spent the bulk of his adult life there as the proprietor of a "Candy Kitchen" is the genuinely unusual story arc this dossier brings to the surface — first-generation Tuscan Italian confectioner in a rural Midwest small town. Tuscan immigrants to the US Midwest were disproportionately represented in the candy / confectionery trade in the 1900s–1950s.	high	f	\N	2026-05-30 09:53:51.446353-05
139	S-41743961	person	P-0059	\N	Ugo's SSN was issued in Iowa; his last place of residence was Cook County, Illinois (ZIP 60650 = Cicero). This documents a late-life relocation from Bedford to Cicero between the 1950 census and 1982 death.	high	f	\N	2026-05-30 09:53:51.446353-05
189	S-0002	person	P-0105	death_date	Died 1 May 1833	high	f	upper inscription, 'DIED May 1, 1833'	2026-05-30 16:03:18.881179-05
190	S-0002	person	P-0105	birth_date	Aged 74 at death (Æ 74), implying birth c. 1758-1759 — consistent with recorded 11 Sep 1759	med	f	age line 'Æ 74' beneath death date	2026-05-30 16:03:18.881179-05
191	S-0002	person	P-0843	death_date	Died 16 Jan 1845	high	f	lower inscription, 'PAMELIA, his wife / Died Jan. 16, 1845'	2026-05-30 16:03:18.881179-05
192	S-0002	person	P-0843	birth_date	Aged 77 at death (Æ. 77), implying birth c. 1767-1768	med	f	age line 'Æ. 77' beneath her death date	2026-05-30 16:03:18.881179-05
140	S-02EDC1CB	person	P-0059	\N	**Arrived at Ellis Island on the SS *Giuseppe Verdi*, 3 September 1920, having departed from Genoa, Italy.** Age 18, single, male. Residence at time of departure: Cintolese. Father Leopoldo Mariotti named on the manifest as relative in country of last residence (i.e. Leopoldo stayed in Italy). Travelling-list neighbor: Severino Stefanelli (indexed "Cusin" — probably part of name or relationship-to mis-parse). The Indexer-assigned "Nationality: Italy, Italian South" is wrong — Cintolese is Tuscany (central/north Italy); FS indexers used "Italian South" as a default for many Italian arrivals. Index reads birth year as 1902 (off by one from 1903 — common for indexed ages).	high	f	\N	2026-05-30 09:53:51.446353-05
141	S-02EDC1CB	person	P-0059	\N	**Ugo emigrated alone**, not with his parents — Leopoldo (then 48) and Quintilia (then 43) stayed in Italy. Confirmed by absence of Leopoldo as a separate passenger on the same voyage in FS's Ellis Island collection, and the standard manifest interpretation of the "nearest relative" field. Consistent with Leopoldo's death in 1933 likely being in Italy (death place still unknown in GPKG).	med	f	\N	2026-05-30 09:53:51.446353-05
142	S-2A57A6F0	person	P-0072	\N	Father: David Lambert, b. 17 Jan 1789 Canaan, Maine; d. 1866 Benton Co IA; buried McBroom Cemetery, Vinton, Benton Co IA; War of 1812 vet	high	f	\N	2026-05-30 09:53:51.446353-05
143	S-3980082F	person	P-0072	\N	Mother: Permelia Barnard, b. 12 Jun 1798; d. 15 Dec 1865 age 67y 6m 3d; buried McBroom Cem, Vinton, Benton Co IA; wife of David Lambert	high	t	\N	2026-05-30 09:53:51.446353-05
144	S-75E512CA	person	P-0072	\N	Death place is **Falls City, Jerome County, Idaho** (not Lincoln) — a former voting precinct / school district at 42.680°N, -114.424°W, post office 1909–1916, in Lincoln Co until Jerome Co was carved off 8 Feb 1919, in Jerome Co thereafter	high	f	\N	2026-05-30 09:53:51.446353-05
145	S-87DBA874	person	P-0072	\N	Co. L, 3rd Iowa Cavalry organized at Jefferson City, MO on 1 Nov 1861 ("Naughton's Irish Dragoons"); left at Springfield MO as garrison Feb 1862, rejoined regiment Nov 1862	high	f	\N	2026-05-30 09:53:51.446353-05
146	S-06A59EB5	person	P-0072	\N	3rd Iowa Cavalry combat: Pea Ridge (Mar 7–8 1862), Vicksburg siege (Jun–Jul 1863), Jackson MS (Jul 1863), Brice's Crossroads / Guntown (Jun 1864), Tupelo (Jul 1864), Westport / Price's MO campaign (Sep–Nov 1864), Grierson's Raid (Dec 1864–Jan 1865), **Wilson's Selma/Macon Raid (Mar 22–Apr 24 1865)** — Co. L specifically at Maplesville AL on 1 Apr 1865	high	f	\N	2026-05-30 09:53:51.446353-05
147	S-87DBA874	person	P-0072	\N	Regiment mustered out 9 Aug 1865 at Atlanta GA; 318 fatalities of 2,165 men (84 combat, 234 disease)	high	f	\N	2026-05-30 09:53:51.446353-05
148	S-C06CFFCD	person	P-0072	\N	David Lambert family migrated as a group of 5 households from Howard Co IN to Benton Co IA in fall 1853, on a military land warrant	med	f	\N	2026-05-30 09:53:51.446353-05
149	S-C06CFFCD	person	P-0072	\N	Abiram + Louisa enumerated in **1854 and 1856 Iowa State Census, Canton Township, Benton County, Iowa** with one child (name in index garbled as "Abinanse Lambert")	med	f	\N	2026-05-30 09:53:51.446353-05
150	S-C06CFFCD	person	P-0072	\N	Abiram's siblings (partial): Sherebiah b.1825 (married Louisa Smith), Abner b.1833, John B. Lambert (Civil War vet, bur. Fort Bidwell CA), Laura Ann Lambert (m. Uel Mather), Sophronia Lambert-Pore-Wilcox, Samuel B. Lambert (stayed Howard Co IN)	med	f	\N	2026-05-30 09:53:51.446353-05
151	S-C06CFFCD	person	P-0072	\N	Louisa Leach b. ~1834 Indiana; m. Abiram 25 Dec 1850 Delaware Co IN at age ~16; d. ~1880 Iowa age ~45	low	f	\N	2026-05-30 09:53:51.446353-05
152	S-454BFE1A	person	P-0072	\N	Helen Amelia (Boles, Foote) Lambert (P-0012) outlived Abiram; remarried a Knapp after 1927 and returned to Iowa; buried Violet Hill Cemetery, Perry, Dallas Co IA as "Helen Amelia Knapp" (FindAGrave #16177390) — search snippet confirms previous spouse 1831–1927	med	f	\N	2026-05-30 09:53:51.446353-05
153	S-75E512CA	person	P-0072	\N	Falls City Idaho — post office 1909–1916; ~10 mi N of Twin Falls city across Snake River canyon; defunct locality	high	f	\N	2026-05-30 09:53:51.446353-05
154	S-6768718C	person	P-0072	\N	Twin Falls Cemetery, Twin Falls Co ID — est. 1907, ~14,001 memorials; the cemetery where Abiram was buried 30 Apr 1927	med	f	\N	2026-05-30 09:53:51.446353-05
155	S-2A57A6F0	person	P-0072	\N	David Lambert was son of Sherebiah Lambert Sr (1728–1790 Canaan ME) and Lydia Hopkins → Abiram's grandparents	med	f	\N	2026-05-30 09:53:51.446353-05
156	S-CC8A8048	person	P-0072	\N	Magic Valley irrigation boom (1903 Carey Act, 1905 Milner Dam, Twin Falls Co created 1907) drove Iowa farmer migration to south-central Idaho 1907–1920 — historical context for Abiram's 1915→1920 move to ID at age 84+	med	f	\N	2026-05-30 09:53:51.446353-05
193	S-8141B6A4	person	P-0078	\N	Born/baptized 24 March 1834 at Saint-Laurent, Île d'Orléans, Québec	high	f	\N	2026-05-30 20:44:12.395074-05
194	S-86A81566	person	P-0078	\N	Son of François Pouliot (1805–1858, KCTF-J6N) and Julie Audet dit Lapointe (1812–1894, 96JW-KFH), who married 19 Feb 1832 at Saint-Jean, Île d'Orléans	high	f	\N	2026-05-30 20:44:12.395074-05
195	S-86A81566	person	P-0078	\N	One of seventeen children of François & Julie (siblings incl. François Xavier 1833, Pierre 1835, Damase 1837, Louis Achille 1842, Marie Nathalie 1847…)	med	f	\N	2026-05-30 20:44:12.395074-05
196	S-8141B6A4	person	P-0078	\N	Present in Québec (Île d'Orléans) in the 1851 Canadian census, age ~17	high	f	\N	2026-05-30 20:44:12.395074-05
197	S-86A81566	person	P-0078	\N	Married Henriette St. Louis on 7 November 1858 at St. Anne, Kankakee County, Illinois	high	f	\N	2026-05-30 20:44:12.395074-05
198	S-86A81566	person	P-0078	\N	Wife Henriette St. Louis (1840–1890, MGNK-YL2); she predeceased Paul, dying in 1890	high	f	\N	2026-05-30 20:44:12.395074-05
199	S-86A81566	person	P-0078	\N	Nine children: Henriette (1859), Thomas (1861), Harriet (1862), Francois (1863), Albert J. (1870), Edward (1873), Arthur (1876), Beatrice Delina (1878), Eva (1881)	med	f	\N	2026-05-30 20:44:12.395074-05
200	S-8141B6A4	person	P-0078	\N	Daughter Beatrice Delina born 1878 in Cook County, Illinois	high	f	\N	2026-05-30 20:44:12.395074-05
201	S-8141B6A4	person	P-0078	\N	Daughter Eva born 1881 in Cook County, Illinois	high	f	\N	2026-05-30 20:44:12.395074-05
202	S-8141B6A4	person	P-0078	\N	Resident of Chicago, Cook County, in the 1880 US federal census	high	f	\N	2026-05-30 20:44:12.395074-05
203	S-8141B6A4	person	P-0078	\N	Resident of Chicago, Cook County, in the 1900 US federal census	high	f	\N	2026-05-30 20:44:12.395074-05
204	S-8141B6A4	person	P-0078	\N	Died 10 May 1903 in Chicago, Cook County, Illinois	high	f	\N	2026-05-30 20:44:12.395074-05
205	S-8141B6A4	person	P-0078	\N	Son Albert J. Pouliot (1870–1942) married in 1916, with Paul named as the groom's father	med	f	\N	2026-05-30 20:44:12.395074-05
206	S-15C14395	person	P-0078	\N	St. Anne, Kankakee Co., was founded 1850 by Fr. Charles Chiniquy as a French-Canadian Catholic temperance colony; ~200 settlers by Dec 1851 and 1,000+ Canadian families arriving in 1854	high	f	\N	2026-05-30 20:44:12.395074-05
207	S-D224FA55	person	P-0078	\N	The colony fractured in a religious schism — Bishop O'Regan excommunicated Chiniquy on 3 Sept 1856 and many colonists turned Protestant; Abraham Lincoln defended Chiniquy in an 1856 slander suit	high	f	\N	2026-05-30 20:44:12.395074-05
\.


--
-- Data for Name: era; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.era (code, label, year_start, year_end, sort_order) FROM stdin;
colonial	Colonial Era	\N	1788	1
early_republic	Early Republic	1788	1830	2
civil_war	Civil War & Reconstruction	1830	1865	3
gilded_age	Gilded Age	1865	1900	4
progressive_wwi	Progressive Era & WWI	1900	1920	5
roaring_depression	Roaring 20s & Great Depression	1920	1940	6
modern	Modern	1940	\N	7
\.


--
-- Data for Name: event; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.event (event_id, title, event_type, date_start, date_end, date_granularity, place_id, importance, confidence, description, privacy_level, notes, created_at, updated_at) FROM stdin;
E-0001	Birth of Bonum Reed	birth	1816-06-03	\N	day	PL-0001	5	med	Born in Wills Creek, Coshocton County, Ohio.	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0002	Marriage of Bonum Reed and Rebecca Talley	marriage	1837-11-23	\N	day	PL-0007	4	med	Marriage recorded in Morgan County, Ohio.	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0003	Death of Bonum Reed	death	1893-12-13	\N	day	PL-0002	4	med	Died in Monteith, Guthrie County, Iowa; buried at Monteith Cemetery.	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0004	Birth of John Talley Reed	birth	1841-06-26	\N	day	PL-0003	5	med	Born in Woodsfield, Monroe County, Ohio.	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0005	Marriage of John T. Reed and Elizabeth Willey	marriage	1861-09-19	\N	day	PL-0008	4	med	Marriage recorded in Noble County, Ohio.	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0006	Death of John Talley Reed	death	1903-11-11	\N	day	PL-0004	4	med	Died in Valley Township, Guthrie County, Iowa; buried in Monteith.	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0007	Birth of Abiram Stacy Lambert	birth	1831-01-09	\N	day	PL-0005	5	med	Born in Salem, Washington County, Indiana.	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0008	Marriage of Abiram Lambert and Louisa Leach	marriage	1850-12-25	\N	day	PL-0009	4	med	Married in Delaware County, Indiana.	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0009	Enlistment of Abiram S. Lambert	enlistment	1861	\N	year	PL-0013	5	med	Enlisted in Co. L, 3rd Iowa Cavalry; residence Corydon, Iowa.	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0010	Discharge of Abiram S. Lambert	discharge	1865-08-09	\N	day	PL-0014	3	med	Mustered out at Atlanta, Georgia.	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0011	Marriage of Abiram Lambert and Helen Amelia (Boles) Foote	marriage	1881-10	\N	month	PL-0015	3	med	Second marriage; daughter Estelle born 1882.	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0012	Birth of John F. Zika	birth	1874	\N	year	PL-0012	4	med	Born in Bohemia; later immigrated to USA.	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0013	Death of John F. Zika	death	1957	\N	year	PL-0011	3	med	Buried at Oakridge-Glen Oak Cemetery, Hillside, Illinois.	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0014	Marriage of John F. Zika and Delina B. Pouliot	marriage	circa 1899	\N	approx	PL-0010	3	low	Married in Chicago area.	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0015	Birth of Delina Beatrice Pouliot	birth	1878-04-14	\N	day	PL-0010	4	high	Born in Chicago, Illinois.	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0016	Death of Delina Beatrice (Pouliot) Zika	death	1964	\N	year	PL-0010	2	med	Died in Illinois.	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0017	Birth of Earl Wayne Reed	birth	1899-07-19	\N	day	PL-0004	5	high	Born in Valley Township, Guthrie County, Iowa.	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0018	Marriage of Earl Wayne Reed and Isabelle Zika	marriage	circa 1929	\N	approx	PL-0010	3	med	Married in Chicago area.	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0019	Birth of Isabelle Zika	birth	1913	\N	year	PL-0010	4	med	Born likely in Chicago, Illinois.	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0020	Death of Isabelle (Zika) Reed	death	2006	\N	year	PL-0010	2	med	Died in Illinois.	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0021	Birth of John Ronald Reed Sr	birth	1934-07-18	\N	\N	PL-0016	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0022	Death of John Ronald Reed Sr	death	1995-05-02	\N	\N	PL-0017	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0023	Event Registration	custom	1934-08-07	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0018` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0024	\N	residence	1940	\N	\N	PL-0019	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0025	Social Program Application	custom	1949-02	\N	\N	\N	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0026	Previous Residence	residence	\N	\N	\N	PL-0017	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0027	Birth of Leah Rae Mariotti	birth	1936-09-08	\N	\N	PL-0020	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0028	Death of Leah Rae Mariotti	death	2025-07-21	\N	\N	PL-0021	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0031	\N	residence	1900	\N	\N	PL-0022	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0032	Military Draft Registration	custom	1918	\N	\N	PL-0023	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0033	\N	residence	1930	\N	\N	PL-0024	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0034	\N	residence	1940	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0025` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0035	Residence	residence	\N	\N	\N	PL-0026	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0037	Birth of Isabelle (Zika) Reed	birth	1913-12-03	\N	\N	PL-0016	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0038	Death of Isabelle (Zika) Reed	death	2006-10-13	\N	\N	PL-0028	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0039	\N	burial	2006	\N	\N	PL-0029	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0040	\N	residence	1920	\N	\N	PL-0030	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0041	\N	residence	1930	\N	\N	PL-0016	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0042	Event Registration	custom	1966-08-16	\N	\N	PL-0031	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0043	Birth of John Foulk Reed	birth	1877-11-25	\N	\N	PL-0032	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0044	Death of John Foulk Reed	death	1952-03-30	\N	\N	PL-0033	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0045	\N	burial	1952-04-01	\N	\N	PL-0034	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0046	\N	residence	1880	\N	\N	PL-0035	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0047	\N	residence	1895	\N	\N	PL-0015	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0048	\N	residence	1900	\N	\N	PL-0022	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0049	Military Draft Registration	custom	1918	\N	\N	PL-0036	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0050	\N	residence	1925	\N	\N	PL-0033	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0051	\N	residence	1930	\N	\N	PL-0033	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0052	\N	residence	1940	\N	\N	PL-0037	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0053	Military Draft Registration	custom	1942-04-27	\N	\N	PL-0033	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0054	Social Program Claim	custom	1944-02-01	\N	\N	\N	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0055	Birth of Estelle Gertrude Lambert	birth	1882-10-30	\N	\N	PL-0038	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0056	Death of Estelle Gertrude Lambert	death	1946-05-20	\N	\N	PL-0016	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0057	\N	burial	1946-05-23	\N	\N	PL-0039	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0058	\N	marriage	1899-03-05	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0040` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0059	\N	residence	1920	\N	\N	PL-0041	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0060	Birth of John F. Zika	birth	1875-10-10	\N	\N	PL-0042	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0061	Death of John F. Zika	death	1957-06-09	\N	\N	PL-0016	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0062	\N	immigration	1885	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0027` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0063	\N	residence	1900	\N	\N	PL-0016	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0064	\N	residence	1910	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0043` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0065	Military Draft Registration	custom	1918	\N	\N	PL-0044	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0066	\N	residence	1920	\N	\N	PL-0030	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0067	\N	residence	1940	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0045` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0068	\N	residence	\N	\N	\N	PL-0046	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0069	Birth of Delina Beatrice (Pouliot) Zika	birth	1878-04-14	\N	\N	PL-0016	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0070	Death of Delina Beatrice (Pouliot) Zika	death	1964-08-01	\N	\N	PL-0031	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0071	\N	burial	1964	\N	\N	PL-0047	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0072	Birth Registration	custom	\N	\N	\N	PL-0031	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0073	\N	residence	1950-04-14	\N	\N	PL-0016	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0074	Birth of Paul Pouliot	birth	1834-03-24	\N	\N	PL-0048	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0075	Death of Paul Pouliot	death	1903-05-10	\N	\N	PL-0016	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0076	\N	immigration	1855	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0027` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0077	\N	residence	1880	\N	\N	PL-0016	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0078	\N	residence	1900	\N	\N	PL-0016	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0079	Birth of Henriette (Filiatrault dit St. Louis) Pouliot	birth	1840-10-17	\N	\N	PL-0049	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0080	Death of Henriette (Filiatrault dit St. Louis) Pouliot	death	1890-01-22	\N	\N	PL-0016	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0081	\N	residence	1880	\N	\N	PL-0016	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0082	Birth of John Talley Reed	birth	1841-06-26	\N	\N	PL-0050	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0083	Death of John Talley Reed	death	1903-11-11	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0051` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0084	\N	burial	\N	\N	\N	PL-0032	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0085	\N	residence	1860	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0052` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0086	\N	residence	1880	\N	\N	PL-0035	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0087	\N	residence	1895	\N	\N	PL-0015	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0088	\N	residence	1900	\N	\N	PL-0053	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0089	Birth of Elizabeth (Willey) Reed	birth	1846-06-26	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0054` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0090	Death of Elizabeth (Willey) Reed	death	1880-12-21	\N	\N	PL-0015	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0091	\N	burial	\N	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0055` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0092	\N	residence	1850	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0056` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0093	\N	residence	1860	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0052` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0094	\N	residence	1870	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0057` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0095	\N	residence	1880	\N	\N	PL-0035	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0096	Birth of Abiram Stacy Lambert	birth	1831-01-09	\N	\N	PL-0058	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0097	Death of Abiram Stacy Lambert	death	1927-04-28	\N	\N	PL-0059	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0098	\N	burial	1927-04-30	\N	\N	PL-0060	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0099	\N	residence	1850	\N	\N	PL-0061	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0100	\N	residence	1860	\N	\N	PL-0062	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0101	\N	residence	1870	\N	\N	PL-0063	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0102	\N	residence	1880	\N	\N	PL-0038	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0103	\N	residence	1900	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0064` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0104	\N	residence	1910	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0064` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0105	\N	residence	1915	\N	\N	PL-0065	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0106	\N	residence	1920	\N	\N	PL-0060	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0107	Pension	custom	1907-01-01	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0027` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0108	Birth of Helen Amelia (Boles) Lambert	birth	1849-06-10	\N	\N	PL-0066	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0109	Death of Helen Amelia (Boles) Lambert	death	1939-01-23	\N	\N	PL-0015	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0110	\N	burial	1939-01-25	\N	\N	PL-0067	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0111	\N	residence	1850	\N	\N	PL-0066	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0112	\N	residence	1860	\N	\N	PL-0068	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0113	\N	residence	1895	\N	\N	PL-0015	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0114	\N	residence	1900	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0051` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0115	\N	residence	1920	\N	\N	PL-0069	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0116	Birth of Bonum Reed	birth	1816-06-03	\N	\N	PL-0070	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0117	Death of Bonum Reed	death	1893-12-13	\N	\N	PL-0032	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0118	\N	burial	1893-12-14	\N	\N	PL-0032	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0119	\N	residence	1840	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0071` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0120	\N	residence	1860	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0052` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0121	\N	residence	1870	\N	\N	PL-0072	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0122	\N	residence	1880	\N	\N	PL-0035	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0123	\N	residence	1885	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0073` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0124	Birth of Rebecca (Talley) Reed	birth	1822-11-07	\N	\N	PL-0074	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0125	Death of Rebecca (Talley) Reed	death	1911-07-16	\N	\N	PL-0032	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0126	\N	burial	1911-07-18	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0055` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0127	\N	residence	1860	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0052` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0128	\N	residence	1870	\N	\N	PL-0072	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0129	\N	residence	1880	\N	\N	PL-0035	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0130	\N	residence	1885	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0073` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0131	\N	residence	1895	\N	\N	PL-0015	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0132	\N	residence	1900	\N	\N	PL-0075	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0133	\N	residence	1910	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0073` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0134	Marriage of John Foulk Reed and Estelle Gertrude Lambert	marriage	1899-03-05	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0040` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0135	Birth of James Willey	birth	1818-03-10	\N	\N	PL-0085	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0136	Death of James Willey	death	1896-07-10	\N	\N	PL-0082	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0137	Burial of James Willey	burial	1896	\N	\N	PL-0082	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0138	Birth of Emily Thorla	birth	1819-05-15	\N	\N	PL-0085	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0139	Death of Emily Thorla	death	1910-10-08	\N	\N	PL-0101	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0140	Burial of Emily Thorla	burial	1910	\N	\N	PL-0103	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0141	Birth of Benjamin Reed	birth	1789-12-24	\N	\N	PL-0090	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0142	Death of Benjamin Reed	death	1872-05-04	\N	\N	PL-0111	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0143	Burial of Benjamin Reed	burial	1872-05	\N	\N	PL-0106	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0144	Birth of Sarah Dickerson	birth	1794-10-11	\N	\N	PL-0113	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0145	Death of Sarah Dickerson	death	1858-01-24	\N	\N	PL-0110	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0146	Burial of Sarah Dickerson	burial	1858-01	\N	\N	PL-0107	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0147	Birth of Stephen Reed	birth	1760	\N	\N	PL-0088	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0148	Death of Stephen Reed	death	1814-04	\N	\N	PL-0083	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0149	Birth of Mary Polly Cook	birth	1735-08-08	\N	\N	PL-0089	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0150	Death of Mary Polly Cook	death	1800-04-04	\N	\N	PL-0100	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0151	Burial of Mary Polly Cook	burial	1800-04	\N	\N	PL-0104	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0152	Birth of Else Alice Bonham	birth	1762	\N	\N	PL-0090	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0153	Death of Else Alice Bonham	death	1819	\N	\N	PL-0087	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0154	Birth of John Foulk Talley	birth	1799-10-26	\N	\N	PL-0081	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0155	Death of John Foulk Talley	death	1886-11-04	\N	\N	PL-0112	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0156	Burial of John Foulk Talley	burial	1886-11	\N	\N	PL-0086	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0157	Birth of Hannah Paulson	birth	1793-08-11	\N	\N	PL-0098	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0158	Death of Hannah Paulson	death	1857-09-30	\N	\N	PL-0080	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0159	Burial of Hannah Paulson	burial	1857	\N	\N	PL-0079	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0160	Birth of Samuel R Barnard	birth	1749-03-09	\N	\N	PL-0108	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0161	Death of Samuel R Barnard	death	1815-08-08	\N	\N	PL-0084	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0162	Birth of Roxana Desire Barnard	birth	1756-07-21	\N	\N	PL-0114	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0163	Death of Roxana Desire Barnard	death	1830-09-09	\N	\N	PL-0109	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0164	Birth of William Polk Willey	birth	1788-01-06	\N	\N	PL-0097	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0165	Death of William Polk Willey	death	1860-04-06	\N	\N	PL-0105	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0166	Burial of William Polk Willey	burial	1860-04	\N	\N	PL-0103	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0167	Birth of Sarah Dye	birth	1789-05-27	\N	\N	PL-0085	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0168	Death of Sarah Dye	death	1840-08-16	\N	\N	PL-0105	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0169	Burial of Sarah Dye	burial	1840-08	\N	\N	PL-0103	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0170	Birth of Benjamin Thorla	birth	1790-09-14	\N	\N	PL-0099	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0171	Death of Benjamin Thorla	death	1861-07-05	\N	\N	PL-0082	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0172	Burial of Benjamin Thorla	burial	\N	\N	\N	PL-0103	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0173	Birth of Elizabeth Allen	birth	1794-07-05	\N	\N	PL-0096	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0174	Death of Elizabeth Allen	death	1872-04-12	\N	\N	PL-0082	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0175	Burial of Elizabeth Allen	burial	1872-04	\N	\N	PL-0103	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0176	\N	residence	1850	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0094` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0177	\N	residence	1860	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0092` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0178	\N	residence	1870	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0092` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0179	\N	residence	1880	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0095` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0180	\N	legal	1881	\N	\N	PL-0101	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0181	\N	residence	1850	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0094` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0182	\N	residence	1860	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0092` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0183	\N	residence	1870	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0092` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0184	\N	residence	1880	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0095` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0185	\N	residence	1910	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0095` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0186	\N	residence	1840-06-01	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0091` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0187	\N	residence	1860	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0092` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0188	\N	residence	1870	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0102` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0189	\N	residence	1870	\N	\N	PL-0078	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0190	\N	residence	1840-06-01	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0093` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0191	\N	residence	1850	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0094` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0192	1854 & 1856 Iowa State Census — Canton Twp, Benton Co, IA	residence	1854-01-01	1856-12-31	year	PL-5233	\N	med	Abiram + Louisa enumerated in Canton Twp, Benton Co IA in both the 1854 and 1856 Iowa state censuses with one child. Family migrated as a 5-household group from Howard Co IN to Benton Co IA in fall 1853 on a military land warrant.	public	Source: Benton County Pioneers (iagenweb); index garbles surname once as 'Abinanse Lambert' — same household.	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0193	Wilson's Raid — Action at Maplesville, AL (Co. L, 3rd Iowa Cavalry)	military	1865-04-01	\N	day	PL-0014	\N	high	Abiram's Company L, 3rd Iowa Cavalry was specifically noted in action at Maplesville, Alabama on 1 April 1865 during Wilson's Selma/Macon Raid (the cavalry campaign that captured Selma the next day and Columbus GA / Macon shortly after). Regiment mustered out 9 Aug 1865 at Atlanta. NB: place_ref is set to Atlanta GA (existing PL-0014) since Maplesville is not in the GPKG; a future patch could add Maplesville AL as a Place if desired.	public	Source: Logan's Roster of Iowa Soldiers (3rd IA Cav) via iagenweb; NPS Battle Unit Details for 3rd IA Cav.	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0196	Burial of John Foulk Reed	burial	1952-04-01	\N	day	PL-5234	\N	high	Burial of Estelle's husband John Foulk Reed at Oakdale Memorial Gardens, Davenport, Scott County, Iowa, two days after his death on 30 Mar 1952. Per FS PID KLGC-TLC.	public	Source: FamilySearch extract 2026-05-26	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0198	Marriage of Clarence D. Eichinger and Estella G. Reed	marriage	1912-09-18	\N	day	PL-5236	\N	high	Second marriage of Estelle Gertrude Lambert (then Estella G. Reed) to Clarence D. Eichinger of Lafayette, Indiana, in Algona, Kossuth County, Iowa. Her marital status on the license was reported as 'Widowed,' though her first husband John Foulk Reed actually lived until 1952 — almost certainly a polite misstatement to mask the divorce.	public	Source: FS Iowa Marriages 1809-1992 XJPF-H6J + Iowa County Marriages 1838-1934 XJ8W-XZ2	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0199	1900 US Census — Valley Twp, Guthrie Center, Guthrie Co, Iowa	census	1900	\N	year	PL-0065	\N	high	Reed household at Valley Township / Guthrie Center, Iowa: John F. Reed (head, 23), Gertrude E. Reed (wife, 19, b. Oct 1881 IA), Wayne E. Reed (son, 1, b. IA). Years married 1; number of living children 1. Sheet 15B, line 61, ED 66, household 367.	public	Source: FS 1900 US Census record M9KG-C8W	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0200	1925 Iowa State Census — Waterloo (4th Ward), Black Hawk Co	census	1925	\N	year	PL-5237	\N	high	Eichinger household at Waterloo (4th Ward), Black Hawk County, Iowa, house #134: Clarence Eichinger 41 (head), Gertrude Eichinger 40 (wife — Estelle), Ray Eichinger 11 (son), Edna Reed 18 (daughter — kept her Reed surname). Shows the Eichinger family had returned from Sioux Falls SD to Iowa by 1925.	public	Source: FS 1925 IA State Census record QKQW-X88X	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0201	Birth of Ugo Mariotti — Cintolese, Tuscany	birth	1903-07-21	\N	day	PL-0178	\N	high	Born 21 July 1903 in Cintolese, a hamlet of Monsummano Terme in the Province of Pistoia, Tuscany. Likely baptized at the parish church of San Leopoldo in Cintolese (parish founded 1781).	public	Source: WWII Draft Registration Card 1942 (FS QG2P-J7N1) lists birthplace 'Cintolese, Italy'; FS extract 13 attached sources concur.	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0202	Immigration — SS Giuseppe Verdi, Genoa → Ellis Island	immigration	1920-09-03	\N	day	PL-5241	\N	high	Arrived at Ellis Island on 3 September 1920 aboard the SS Giuseppe Verdi from Genoa, Italy. Age 18, single, residence at departure Cintolese. Father Leopoldo Mariotti named on the manifest as relative in country of last residence (i.e. parents stayed in Italy). Travelled in proximity to a fellow Cintolese-area passenger, Severino Stefanelli. Page 68 of the manifest; microfilm T715-2825, image 131.	public	Source: New York, Passenger Arrival Lists (Ellis Island), 1892-1925 (FS J6F8-T28). Indexed nationality 'Italian South' is incorrect — Cintolese is Tuscany. Index also has birth year 1902 (vs 1903 in all other records — common 1-yr off in indexed ages).	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0203	Marriage of Ugo Mariotti and Lena M. Dini — Lenox, Iowa	marriage	1927-05-05	\N	day	PL-5240	\N	high	Ugo Mariotti (23, Italian-born) married Lena M. Dini (17, born Chicago IL) on 5 May 1927 in Lenox, Taylor County, Iowa. Marriage record page 366. Ugo's parents named on the record as Leopoldo Mariotti (indexed 'Geopaldo' — OCR error) and Quintilia Lenzi (indexed 'Quinta Ginse').	public	Source: Iowa, County Marriages, 1838-1934 (FS XJX4-VDB).	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0204	Naturalization — Northern District of Illinois	naturalization	1927-01-01	\N	year	PL-0179	\N	high	Ugo Mariotti naturalized as a US citizen in 1927, U.S. District Court for the Northern District of Illinois. Indexed in M1285 Soundex Index to Naturalization Petitions (film #126). The 1950 census later confirms 'Citizenship Status: yes'.	public	Source: Illinois, Northern District Naturalization Index, 1840-1950 (FS XKGJ-M1P). Court was in Chicago/Cook County.	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0205	1930 US Census — Bedford, Taylor Co, Iowa	census	1930-04-01	\N	day	PL-5239	\N	high	Hugo Mariotti (26, head, married, b. Italy), wife Lena (20, IL), son Roland (infant, IL). Family settled in Bedford by April 1930 — having moved from Cicero IL where Roland was born June 1929.	public	Sheet 6A line 7. Source: 1930 US Census (FS XMKQ-K9T).	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0206	1940 US Census — Bedford Twp, Taylor Co, Iowa	census	1940-04-01	\N	day	PL-5239	\N	high	Hugo Mariotti (36, head, married, b. Italy), wife Lena (30, IL), son Roland (10, IL), daughter Leah Rae (3, IL). Residence Date 1935 also Bedford — i.e. family had been in Bedford continuously since at least mid-Depression.	public	ED 87-1A Bedford Twp/Bedford City W of Madison St/Taylor County Jail. Line 14, sheet 13A. Source: 1940 US Census (FS KMBB-TY1).	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0207	WWII Draft Registration (3rd Registration) — Bedford, IA	military	1942-02-16	\N	day	PL-5239	\N	high	Registered for the WWII Draft (3rd Registration of 16 Feb 1942, covering men 18-45) at Bedford, Taylor County, IA. Physical description: 5'5", 160 lbs, light complexion, brown eyes, brown hair. Employer: Self (matches 1950 census occupation 'Proprietor, Candy Kitchen'). Nearest relative: wife Lena Mariotti. Birthplace given as 'Cintolese, Italy'.	public	Source: Iowa, World War II Draft Registration Cards, 1940-1945 (FS QG2P-J7N1).	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0208	1950 US Census — Bedford Twp, Taylor Co, Iowa	census	1950-04-10	\N	day	PL-5239	\N	high	Ugo Mariotti (46, head, married, b. Italy), wife Lena (40, IL), daughter Leah Rae (13, IL), daughter Celiste Dee (6, IL). Son Roland absent (~20, likely military). Occupation: Proprietor, Industry: Candy Kitchen. Citizenship Status: yes.	public	ED 87-3, line 21, page 16. Source: 1950 US Census (FS 6FQW-JRYD).	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0209	Death of Ugo Mariotti — Cicero, Illinois	death	1982-02-20	\N	day	PL-0179	\N	high	Died 20 February 1982, age 78. Last residence ZIP 60650 (Cicero, IL); SSN issued in Iowa.	public	Source: SSDI (FS JLLR-Z6F); Archdiocese of Chicago Cemetery Records (FS Q2HF-8P34); FindAGrave Memorial #288488976.	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0210	Burial of Ugo Mariotti — Queen of Heaven, Hillside, IL	burial	1982-02-23	\N	day	PL-5238	\N	high	Buried 23 February 1982 at Queen of Heaven Catholic Cemetery, Hillside, Cook County, Illinois. Plot: Section 40, Block 213, Lot 7, Grave 8. His son Roland W. Mariotti (d. 2023) is buried at the same cemetery — family plot.	public	Source: IL Archdiocese of Chicago Cemetery Records 1864-1989 (FS Q2HF-8P34) and FindAGrave Memorial #288488976.	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0211	1950 US Census — Cicero, Cook Co, IL (ED 104-1)	census	1950-04-29	\N	day	PL-0019	\N	high	John Reed, 15, single, 'Son', in the household of his divorced mother Isabelle Reed (head, 36, 'Biller' at a telephone factory). Brothers Wayne (19) and James (10) also present; father Earl Sr absent.	public	Source: 1950 US Federal Census, FamilySearch ark:/61903/1:1:6X1N-2M9L. ED 104-1.	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0212	Marriage of John Ronald Reed Sr & Leah Rae Mariotti	marriage	1956	\N	year	PL-5243	\N	med	John (age ~21–22) married Leah Rae Mariotti (age 20) in 1956; the couple began married life in Westchester, IL. Exact date and ceremony venue not yet sourced from a civil/church record; place_ref reflects their first home, not necessarily the wedding site.	public	Source: Leah R. Reed obituary (Williams-Kampp Funeral Home, 2025). Cook County marriage record not located on FamilySearch's free index.	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0213	Korean War U.S. military service	military	1952	1955	year	PL-5244	\N	med	Served in the U.S. military during the Korean War (family testimony, John Kenny, 2026). Family recalls training at Camp Pendleton, CA — a USMC base, implying U.S. Marine Corps. He turned 18 in July 1952; the war ran to the July 1953 armistice. Service window (1952-1955), branch (likely USMC), and base are ESTIMATED/UNCONFIRMED pending an NPRC service record, a county-recorded DD-214, his 1995 obituary, or a headstone marker.	public	Source: oral family history (proband John Kenny), relayed 2026-05-30. No documentary record located online; VA BIRLS Death File search returned nothing.	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0214	Occupation — Carpenter	occupation	1974-04-07	\N	day	PL-166025	\N	high	Recorded as a carpenter on his Cook County death record. Occupation consistent with a lifetime trade in the Chicago building boom of the 1920s-1950s.	public	Source: Illinois, Cook County Deaths, 1871-1998 (entry 02060).	2026-05-30 15:38:23.117619-05	2026-05-30 15:38:23.117619-05
E-0215	1950 US Census — Chicago, Cook Co, IL	census	1950	\N	year	PL-0010	\N	high	Earl W. Reed enumerated in Chicago, Cook County, Illinois in the 1950 federal census — the household had moved from Cicero (1930, 1940) into the city proper by 1950.	public	Source: United States Census, 1950, attached to FS M3P5-XF6.	2026-05-30 15:38:23.117619-05	2026-05-30 15:38:23.117619-05
E-0030	Death of Earl Wayne Reed	death	1974-04-07	\N	day	PL-166025	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 15:42:11.880293-05
E-0197	Burial of Earl Wayne Reed Sr	burial	1974-04-11	\N	day	PL-166026	\N	high	Buried 11 April 1974 at Lakewood Memorial Park, Elgin, Illinois (Martin Funeral Home Ltd). Per Cook County death record (Q2MN-CML4) and Find a Grave (QV2L-ZBPS).	public	Source: FamilySearch extract 2026-05-26. Specific cemetery within Elgin not given.	2026-05-30 09:21:56.321112-05	2026-05-30 15:42:11.880293-05
E-0216	Marriage of Paul Pouliot and Henriette St. Louis	marriage	1858-11-07	\N	day	PL-166027	\N	high	Paul Pouliot married Henriette St. Louis on 7 November 1858 at St. Anne, the French-Canadian Catholic colony in Kankakee County, Illinois.	public	Source: Illinois County Marriages 1810-1940 & Illinois Marriages 1815-1935 (FamilySearch, attached to 96JW-KX5)	2026-05-30 20:44:12.241497-05	2026-05-30 20:44:12.241497-05
E-0217	1851 Canadian Census — Île d'Orléans, Québec	census	1851	\N	year	PL-0506	\N	high	Paul Pouliot, age ~17, enumerated with his family on Île d'Orléans in the 1851 Census of Canada East — four years before his emigration to Illinois.	public	Source: Canada Census 1851 (FamilySearch, attached to 96JW-KX5)	2026-05-30 20:44:12.241497-05	2026-05-30 20:44:12.241497-05
\.


--
-- Data for Name: event_participant; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.event_participant (id, event_id, person_id, role) FROM stdin;
3	E-0002	P-0002	\N
5	E-0004	P-0070	\N
6	E-0005	P-0070	\N
7	E-0005	P-0004	\N
8	E-0006	P-0070	\N
9	E-0007	P-0072	\N
10	E-0008	P-0072	\N
11	E-0008	P-0055	\N
12	E-0009	P-0072	\N
13	E-0010	P-0072	\N
14	E-0011	P-0072	\N
15	E-0011	P-0012	\N
16	E-0012	P-0064	\N
17	E-0013	P-0064	\N
18	E-0014	P-0064	\N
19	E-0014	P-0068	\N
20	E-0015	P-0068	\N
21	E-0016	P-0068	\N
22	E-0017	P-0062	\N
23	E-0018	P-0062	\N
24	E-0018	P-0058	\N
25	E-0019	P-0058	\N
26	E-0020	P-0058	\N
27	E-0021	P-0056	\N
28	E-0022	P-0056	\N
29	E-0023	P-0056	\N
30	E-0024	P-0056	\N
31	E-0025	P-0056	\N
32	E-0026	P-0056	\N
33	E-0027	P-0055	\N
34	E-0028	P-0055	\N
36	E-0030	P-0062	\N
37	E-0031	P-0062	\N
38	E-0032	P-0062	\N
39	E-0033	P-0062	\N
40	E-0034	P-0062	\N
41	E-0035	P-0062	\N
43	E-0037	P-0058	\N
44	E-0038	P-0058	\N
45	E-0039	P-0058	\N
46	E-0040	P-0058	\N
47	E-0041	P-0058	\N
48	E-0042	P-0058	\N
49	E-0043	P-0061	\N
50	E-0044	P-0061	\N
51	E-0045	P-0061	\N
52	E-0046	P-0061	\N
53	E-0047	P-0061	\N
54	E-0048	P-0061	\N
55	E-0049	P-0061	\N
56	E-0050	P-0061	\N
57	E-0051	P-0061	\N
58	E-0052	P-0061	\N
59	E-0053	P-0061	\N
60	E-0054	P-0061	\N
61	E-0055	P-0036	\N
62	E-0056	P-0036	\N
63	E-0057	P-0036	\N
64	E-0058	P-0036	\N
65	E-0059	P-0036	\N
66	E-0060	P-0064	\N
67	E-0061	P-0064	\N
68	E-0062	P-0064	\N
69	E-0063	P-0064	\N
70	E-0064	P-0064	\N
71	E-0065	P-0064	\N
72	E-0066	P-0064	\N
73	E-0067	P-0064	\N
74	E-0068	P-0064	\N
75	E-0069	P-0068	\N
76	E-0070	P-0068	\N
77	E-0071	P-0068	\N
78	E-0072	P-0068	\N
79	E-0073	P-0068	\N
80	E-0074	P-0078	\N
81	E-0075	P-0078	\N
82	E-0076	P-0078	\N
83	E-0077	P-0078	\N
84	E-0078	P-0078	\N
85	E-0079	P-0076	\N
86	E-0080	P-0076	\N
87	E-0081	P-0076	\N
88	E-0082	P-0070	\N
89	E-0083	P-0070	\N
90	E-0084	P-0070	\N
91	E-0085	P-0070	\N
92	E-0086	P-0070	\N
93	E-0087	P-0070	\N
94	E-0088	P-0070	\N
95	E-0089	P-0004	\N
96	E-0090	P-0004	\N
97	E-0091	P-0004	\N
98	E-0092	P-0004	\N
99	E-0093	P-0004	\N
100	E-0094	P-0004	\N
101	E-0095	P-0004	\N
102	E-0096	P-0072	\N
103	E-0097	P-0072	\N
104	E-0098	P-0072	\N
105	E-0099	P-0072	\N
106	E-0100	P-0072	\N
107	E-0101	P-0072	\N
108	E-0102	P-0072	\N
109	E-0103	P-0072	\N
110	E-0104	P-0072	\N
111	E-0105	P-0072	\N
112	E-0106	P-0072	\N
113	E-0107	P-0072	\N
114	E-0108	P-0012	\N
115	E-0109	P-0012	\N
116	E-0110	P-0012	\N
117	E-0111	P-0012	\N
118	E-0112	P-0012	\N
119	E-0113	P-0012	\N
120	E-0114	P-0012	\N
121	E-0115	P-0012	\N
130	E-0124	P-0002	\N
131	E-0125	P-0002	\N
132	E-0126	P-0002	\N
133	E-0127	P-0002	\N
134	E-0128	P-0002	\N
135	E-0129	P-0002	\N
136	E-0130	P-0002	\N
137	E-0131	P-0002	\N
138	E-0132	P-0002	\N
139	E-0133	P-0002	\N
140	E-0134	P-0061	\N
141	E-0134	P-0036	\N
142	E-0192	P-0072	self
143	E-0193	P-0072	self
144	E-0196	P-0061	self
145	E-0197	P-0062	self
146	E-0198	P-0036	spouse
147	E-0199	P-0036	self
148	E-0199	P-0061	head_of_household
149	E-0199	P-0062	child
150	E-0200	P-0036	self
151	E-0201	P-0059	self
152	E-0202	P-0059	self
153	E-0203	P-0059	self
154	E-0204	P-0059	self
155	E-0205	P-0059	head_of_household
156	E-0206	P-0059	head_of_household
157	E-0207	P-0059	self
158	E-0208	P-0059	head_of_household
159	E-0209	P-0059	self
160	E-0210	P-0059	self
161	E-0211	P-0056	child
162	E-0212	P-0056	spouse
163	E-0212	P-0055	spouse
164	E-0213	P-0056	self
165	E-0153	P-0044	self
166	E-0159	P-0046	self
167	E-0191	P-0041	self
168	E-0174	P-0052	self
169	E-0142	P-0040	self
170	E-0190	P-0041	self
171	E-0149	P-0043	self
172	E-0152	P-0044	self
173	E-0165	P-0049	self
174	E-0167	P-0050	self
175	E-0173	P-0052	self
176	E-0184	P-0039	self
177	E-0172	P-0051	self
178	E-0168	P-0050	self
179	E-0189	P-0040	self
180	E-0146	P-0041	self
181	E-0143	P-0040	self
182	E-0162	P-0048	self
183	E-0156	P-0045	self
184	E-0163	P-0048	self
185	E-0136	P-0038	self
186	E-0186	P-0040	self
187	E-0188	P-0040	self
188	E-0137	P-0038	self
189	E-0185	P-0039	self
190	E-0148	P-0042	self
191	E-0177	P-0038	self
192	E-0178	P-0038	self
193	E-0135	P-0038	self
194	E-0187	P-0040	self
195	E-0147	P-0042	self
196	E-0179	P-0038	self
197	E-0170	P-0051	self
198	E-0181	P-0039	self
199	E-0169	P-0050	self
200	E-0182	P-0039	self
201	E-0157	P-0046	self
202	E-0183	P-0039	self
203	E-0160	P-0047	self
204	E-0144	P-0041	self
205	E-0140	P-0039	self
206	E-0161	P-0047	self
207	E-0155	P-0045	self
208	E-0138	P-0039	self
209	E-0151	P-0043	self
210	E-0158	P-0046	self
211	E-0171	P-0051	self
212	E-0175	P-0052	self
213	E-0139	P-0039	self
214	E-0166	P-0049	self
215	E-0150	P-0043	self
216	E-0141	P-0040	self
217	E-0154	P-0045	self
218	E-0164	P-0049	self
219	E-0145	P-0041	self
220	E-0180	P-0038	self
221	E-0176	P-0038	self
1	E-0001	P-0082	\N
2	E-0002	P-0082	\N
4	E-0003	P-0082	\N
122	E-0116	P-0082	\N
123	E-0117	P-0082	\N
124	E-0118	P-0082	\N
125	E-0119	P-0082	\N
126	E-0120	P-0082	\N
127	E-0121	P-0082	\N
128	E-0122	P-0082	\N
129	E-0123	P-0082	\N
222	E-0214	P-0062	self
223	E-0215	P-0062	self
224	E-0216	P-0078	self
225	E-0216	P-0076	spouse
226	E-0217	P-0078	self
\.


--
-- Data for Name: event_type; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.event_type (code, label, description) FROM stdin;
birth	Birth	Birth event
death	Death	Death event
marriage	Marriage	Marriage / union
divorce	Divorce	Dissolution of marriage
residence	Residence	Place of residence at a point in time
census	Census	Census enumeration
immigration	Immigration	Arrival / passenger manifest
naturalization	Naturalization	Citizenship / naturalization
burial	Burial	Burial / interment
baptism	Baptism	Baptism / christening
occupation	Occupation	Employment / occupation
military	Military service	Military service or enlistment
education	Education	Schooling / enrollment
custom	Custom	Other / uncategorised event
other	Other	Other event
enlistment	\N	\N
discharge	\N	\N
legal	\N	\N
\.


--
-- Data for Name: media; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.media (media_id, media_type, title, caption, file_path, url, mime_type, sha256, bytes, captured_date, created_at, updated_at) FROM stdin;
M-0001	pdf	Gerald Arthur Kenny — memorial prayer card	Funeral prayer card, Williams-Kampp Funeral Home, 2025	S-0001/Geraldprayercard.pdf	https://lrgdmmedia885f01.blob.core.windows.net/originals/S-0001/Geraldprayercard.pdf	application/pdf	6d0e98301e9130a9f6cef31c2eea8c7276daa37b68450ae86764b0daa04f278c	198967	2025	2026-05-30 12:24:02.787679-05	2026-05-30 12:24:02.787679-05
M-0002	image	Sherebiah & Pamelia Lambert headstone	Shared grave marker; 'SHEREBIAH LAMBERT / DIED May 1, 1833 / Æ 74' over 'PAMELIA, his wife / Died Jan. 16, 1845 / Æ. 77'.	S-0002/sherebiahlambertgrave.jpg	https://lrgdmmedia885f01.blob.core.windows.net/originals/S-0002/sherebiahlambertgrave.jpg	image/jpeg	cb74e48a6a91c5473020eb6d7101cc0325e36bce26d2d2c4fd8248a488d125be	223497	\N	2026-05-30 16:03:18.881179-05	2026-05-30 16:03:18.881179-05
\.


--
-- Data for Name: media_link; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.media_link (id, media_id, subject_type, subject_id, role, sort_order) FROM stdin;
2	M-0001	source	S-0001	document_scan	0
3	M-0001	person	P-0167	document_scan	0
4	M-0002	source	S-0002	headstone	0
5	M-0002	person	P-0105	headstone	0
6	M-0002	person	P-0843	headstone	0
\.


--
-- Data for Name: narrative; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.narrative (person_id, dossier_date, body_md, rendered_html, published, updated_at) FROM stdin;
P-0036	2026-05-28	Estelle Gertrude Lambert was born on 30 October 1882 in Seely Township, Guthrie County, Iowa, on the rolling prairie about twenty miles west of Des Moines [1]. Her father Abiram Stacy Lambert, a fifty-one-year-old veteran of the 3rd Iowa Cavalry, had taken his second wife only thirteen months earlier — Helen Amelia Boles, then thirty-three, herself already a widow with three Foote children from a previous marriage [4][5][17][20]. The America Estelle was born into was Chester A. Arthur's: a presidency that had begun nine months earlier when Garfield died of an assassin's bullet, a Midwest that had just finished absorbing the post-bellum railroad boom, and an Iowa whose corn-belt agriculture was newly tied to Chicago by the Rock Island Line. The 1885 Iowa State Census found the Lamberts in Seely, Guthrie County, a household of seven: Abiram and Helen, two-year-old Gertrude and her one-year-old sister Sylvia, and Helen's three Foote children — Clara sixteen, Arthur fifteen, Edwin four [17]. It was a blended household before the word existed, a half-Civil-War-veteran/half-prairie-widow construction of the kind the war had left scattered across the Mississippi Valley.\n\nThe household did not last. Sometime between the 1885 state census and the 1895 one, Helen left Abiram. By the 1895 Iowa State Census she was "Helen Amelia Knapp," living with a man named Leslie Knapp; Estelle, then twelve, was still recorded as "Stella Gertrude Lambert" but was effectively being raised under a stepfather's roof from her teenage years onward [18]. There is no surviving Iowa divorce record yet found for Abiram and Helen, but the 1895 facts are unambiguous: Helen had moved on, Abiram was somewhere else (he would drift west toward Idaho over the next decade), and Estelle's adolescence took place in a Knapp household, not a Lambert one. The Iowa of the early 1890s was a hard place to be the daughter of a separated couple — the state's farm economy had collapsed into the Panic of 1893, the Populist movement was at its peak in the county courthouses around her, and "Coxey's Army" of unemployed workers passed through the Midwest the year she turned twelve.\n\nShe married young, and into the founding family of the next town over. On 5 March 1899, at sixteen, Estelle married John Foulk Reed in Guthrie County [6][7]. Monteith, John's birthplace and the nominal site of the wedding, was less a village than a Reed proposition: it had been platted only eighteen years earlier by Harmon T. Reed when the railroad reached his land, and the Reeds had been its founding family ever since [21]. Their first child Earl Wayne Reed was born four and a half months later, on 19 July 1899 [8][14] — by the time the 1900 US Census found the family in Valley Township at Guthrie Center, they were a tidy household of three, "Years married 1, Number of living children 1" [14]. Three more Reed children followed in quick succession: Harold Merle in January 1901, Oscar G. in 1903, and Edna Gertrude in August 1906 [9][10][11]. For ten years Estelle was a Guthrie County farm wife with four small children, while McKinley gave way to Roosevelt and Taft and the rural-Midwest banner stories shifted from free silver to trust-busting to the first stirrings of Prohibition.\n\nThen in 1912 she disappeared from the Reed household. On 18 September 1912, in Algona, Kossuth County, Iowa — 150 miles north of Guthrie Center — Estella G. Reed married Clarence D. Eichinger of Lafayette, Indiana, with her marital status politely entered on the license as "Widowed" [12]. John Foulk Reed was not, in fact, dead; he would live another forty years, dying in Davenport in 1952 [6]. "Widowed" was simply the easier word in 1912 Iowa for a Methodist-belt mother of four leaving one husband for another. By the 1920 US Census the new Eichinger household — Clarence, Gertrude, the teenage Edna (re-recorded under her stepfather's surname), and a six-year-old son Ray almost certainly Clarence's — was living at Sioux Falls Ward 11 in Minnehaha County, South Dakota, on the eastern edge of the Dakota plains [13][15]. The pull west wasn't unusual for the era: World War I had driven Iowa farm prices into a speculative spike, Sioux Falls had become a regional grain and meatpacking hub around the John Morrell plant, and second marriages with young children often moved across state lines to start clean. They didn't stay. By the 1925 Iowa State Census the family was back in Iowa, at Waterloo (4th Ward) in Black Hawk County, with eighteen-year-old Edna once again signing herself "Reed" [16].\n\nThe 1930s broke the Eichinger marriage and ushered in a third. The decade is largely undocumented in her open record — the 1930 and 1940 censuses are not among the 19 sources attached to her FamilySearch tree, and she does not appear in any of them under either Reed, Eichinger, or Lambert. By the time she next surfaces, in May 1946, she is "Estelle G **Sinderson**," divorced, living at 1339 South 48th Street on Chicago's West Side, and working as a waitress [19]. Her death certificate names her last husband only as "Harry" [19]. The Chicago of the war years had been a magnet for displaced Midwesterners — defense plants, war work, and a streetcar-flat economy that gave older women a place to land — and the Lawndale/Cicero corridor where 48th Street ran was thick with second-generation Iowa and Indiana families. She had also outlived her mother by seven years: Helen Knapp, the woman who had left Abiram a generation earlier and now lay under a stone reading "Helen Amelia Knapp," died in Iowa in January 1939 and was buried at Violet Hill Cemetery in Perry [5].\n\nEstelle died in Chicago on 20 May 1946 at sixty-three [2][19]. The spring of 1946 was the world's first nuclear peacetime — V-J Day was nine months in the past, Truman was president, and a wave of strikes was working through the postwar economy from the United Mine Workers to the railroad unions. The O'Shea and Raleigh funeral home on the West Side prepared her body and sent it north to Wisconsin, where she was buried three days later on 23 May 1946 at Prairie Home Cemetery, Waukesha — under her last married name, Sinderson, which is why a search of the cemetery's R-surname index turns up nothing [3][19]. Why Waukesha? The death certificate gives no answer, and none of the Lambert, Reed, or Eichinger families had previously been buried there. Harry Sinderson's roots are the most likely thread: somewhere in southeastern Wisconsin he had family ground, and the wife he had divorced years earlier was given a place in it. Her first husband John Foulk Reed died six years later in Davenport and was buried in Oakdale Memorial Gardens, Scott County, Iowa [6]. Their oldest son Earl Wayne Reed Sr lived in Chicago through middle age and was buried in Elgin, Kane County, Illinois, in April 1974 [8]. Of the five children Estelle bore between 1899 and ~1914, only Earl is documented in the LRGDM tree so far; the others — Harold, Oscar, Edna, and Ray — are open leads for a future ingest.	\N	t	2026-05-30 09:53:51.446353-05
P-0056	2026-05-30	John Ronald Reed was born on July 18, 1934, in Chicago, into a city and a country still in the grip of the Great Depression [1]. Franklin Roosevelt was barely a year into the New Deal; the banks had only recently reopened and a third of working Chicagoans had no steady job. His birth was registered three weeks later, on August 7 — routine civic paperwork in the expanding administrative state. He was a son of Earl Wayne Reed, born in 1899, and Isabelle Harriet Zika, born in 1913 [3] — an Anglo-American Reed father and a mother whose surname, Zika, places her among the great Bohemian-Czech migration that had filled the near-west suburbs a generation earlier. John was the middle of three brothers: Wayne came first, in 1930, and Jim followed around 1940 [8][9].\n\nThat heritage set the family in one of the most distinctive enclaves of working-class Chicagoland: Cicero, the dense, proudly Czech-and-Slovak industrial town built around the colossal Western Electric Hawthorne Works and only a few years removed from its notoriety as Al Capone's base after he was pushed out of Chicago proper. But the household John grew up in was no postcard of the era. By the spring of 1950 the census-taker found him, fifteen and still in school, in a home headed not by his father but by his mother — Isabelle, listed as divorced, supporting three sons on her wages as a "biller" in a telephone factory [5][6][7], almost certainly the Hawthorne plant that loomed over the town. The marriage had broken sometime in the 1940s, leaving a Depression-raised single mother to carry her boys through the postwar years. John came of age in that house — seven at Pearl Harbor, ten on V-J Day, too young to serve but old enough to feel his father's absence. At fourteen, in February 1949, he walked into a Social Security office for his first card, the document a working-class teenager got before his first paying job [4].\n\nThen came the war. John turned eighteen in July 1952, with the fighting in Korea grinding toward its bloody stalemate, and he served in the U.S. military during the Korean conflict [19] — by his family's account training at Camp Pendleton, the sprawling Marine Corps base on the California coast, a continent away from the two-flats of Cicero. He was one of the great cohort of his birth year swept into Korea and the Cold War garrisons that manned the line after the July 1953 armistice. For a boy raised by a single mother in a telephone-factory town, the Marines would have been both rupture and opportunity — the first time many such young men ever left Illinois.\n\nHe came home to a country booming, and the story turns. Around 1956, John — about twenty-two — married Leah Rae Mariotti, a twenty-year-old who had been born in Chicago, raised partly in Bedford, Iowa, and drawn back to the city; her parents were the Italian-American Ugo and Lena Mariotti [11][18]. It was a quintessential second-generation, melting-pot match of mid-century Chicago: an English-and-Czech Reed marrying into an Italian Catholic family, and John took up that faith and that church. The newlyweds set up house in Westchester, a brand-new bungalow suburb just west of the city [11] — and then, like millions of young couples riding the postwar boom of mortgages, expressways and parish schools, they pushed farther out, settling around 1964 in Glen Ellyn, a leafy DuPage County commuter town on the Chicago & North Western line [12]. There they raised an enormous baby-boom family — seven children, two sets of twins among them [13] — in a house on a quiet street, anchored to St. James the Apostle parish [14].\n\nFor John, Glen Ellyn was the destination of a single remarkable arc: from a broken Depression-era home in industrial Cicero to a full house in the green collar-county suburbs his children would call home for sixty years. He lived out the second half of the American Century there, the Social Security record fixing his address at ZIP 60137 [2]. His older brother Wayne had made the same westward move, raising his own family in Hoffman Estates from 1961 [8]; the three Cicero boys had scattered into the suburbs that the GI generation built.\n\nJohn Ronald Reed Sr died in DuPage County on May 2, 1995, at the age of sixty [2][15]. He left Leah a widow at fifty-eight, with seven grown children — and it was she, in the long widowhood that followed, who became the keeper of the family's memory, teaching herself genealogy and tracing the Reed and Mariotti lines back ten generations [17]. She outlived him by three decades, dying in July 2025 at eighty-eight, and was buried at Queen of Heaven Catholic Cemetery in Hillside [16]; John, who has no memorial of his own online, almost certainly lies in the same Catholic ground. Their line runs forward to the present day through their daughter Karen, whose son John Kenny is the proband at the root of this very family tree [17] — so that the boy born in Depression Cicero became, in the fullness of time, the grandfather at the center of the map.	\N	t	2026-05-30 09:53:51.446353-05
P-0059	2026-05-28	Ugo Mariotti was born on 21 July 1903 in Cintolese, a hamlet of Monsummano Terme in the Tuscan Province of Pistoia, a settlement that owed its existence to the late-eighteenth-century reclamation of the Fucecchio marshes by Grand Duke Pietro Leopoldo of Lorraine [15]. The parish around which the village was organized — *San Leopoldo in Cintolese*, consecrated in 1788 and named for the reformist grand duke who would soon become Holy Roman Emperor Leopold II — was almost certainly the church in which the infant Ugo was baptized in the summer of 1903 [15], the year Pope Leo XIII died and was succeeded by Pius X. The unified Kingdom of Italy was only forty-two years old. Vittorio Emanuele III had been on the throne three years; the *Risorgimento* generation was giving way to a country with a new, brittle ambition. Tuscany had been an "early generator" of emigrants since the 1870s [16], and across the Province of Pistoia young men were beginning to make the calculation that the future was on the other side of the Atlantic. His father was Leopoldo Mariotti (P-0067), born 1871 and named for the parish saint; his mother was Quintilia Lenzi (P-0069), born 1876 — both still in Cintolese when their son was born [5][6]. (An earlier guess in this dossier had Zelinda Pagni as his mother; the 1927 Iowa marriage record corrects that to Quintilia Lenzi.)\n\nHis childhood spanned the years in which Italy entered and exited the First World War. He was eleven when Italy joined the Entente in 1915 and fifteen at the armistice in November 1918 — old enough to remember the men who never came back from the Isonzo, too young to have served. The post-war biennio rosso, the rise of Mussolini in October 1922, and the agricultural crisis of the early 1920s formed the backdrop against which Ugo, like thousands of young Tuscan men, decided to cross. He was eighteen, single, and travelling alone when on **3 September 1920** he stepped off the **SS *Giuseppe Verdi*** at Ellis Island after a voyage from Genoa [19]. His father Leopoldo was named on the manifest as his nearest relative in country of last residence — meaning Leopoldo and Quintilia stayed in Cintolese [20]. (Leopoldo would die in 1933, almost certainly in Italy; the death place is one of this dossier's open follow-ups.) The voyage left from Genoa rather than Naples or Palermo — the standard Tuscan-Ligurian emigrant departure rather than the southern Italian one — and on the same manifest page sat a fellow passenger named Severino Stefanelli, probably from the same corner of the Province of Pistoia. Seven years later, in 1927, Ugo was naturalized in the U.S. District Court for the Northern District of Illinois [7] — exactly the five-year statutory residency window from his arrival, the earliest moment he could become a citizen.\n\nWhat he found, surprisingly, was not the Italian-immigrant Chicago of received imagination. On 5 May 1927 — the same year his naturalization came through — he married a seventeen-year-old Chicago-born Italian-American girl named **Lena M. Dini** in **Lenox, Taylor County, Iowa** [4], a tiny town in the southwestern corner of the state. His parents were named on the record (the indexer got them wrong: "Geopaldo Mariotti" is Leopoldo, "Quinta Ginse" is Quintilia Lenzi [5][6]). The young couple's first child, a son they named **Rolando** — anglicized to Roland — was born in Cicero, Illinois, on 17 June 1929 [8], registered there on 21 August as Certificate #228, with the father listed as "Hugo Mariotti, 25, Italian" and the mother as "Lina Dini, 20, Cicero." Roland's arrival came on the eve of the Wall Street crash. Cicero in 1929 was Al Capone's town — he had moved his headquarters into the Hawthorne Hotel in 1923 — and the St. Valentine's Day Massacre in Chicago in February 1929 was four months before Rolando Mariotti's birth.\n\nThe family did not stay in Cicero. By the April 1930 census they had settled in Bedford, Taylor County, Iowa — the same county where they had married — and they would remain in Bedford for the entire span of the Great Depression and the Second World War [9][10][12]. Ugo, who had emigrated from a Tuscan village known mostly for grapes and reclaimed marshland, became the proprietor of a "Candy Kitchen" in a southwestern Iowa town of fifteen hundred people [12][17]. The Tuscan-Italian confectioner in a Midwest small town was a real and underdocumented immigration story of the 1900s–1930s; he was one of many. When the United States entered the Second World War, Ugo — at thirty-eight, on the upper edge of the 18-45 band — registered for the Third Registration of the WWII Draft on 16 February 1942 in Bedford [11]. The card recorded him as five foot five, a hundred and sixty pounds, with brown hair and brown eyes and a light complexion; his employer was "Self"; his nearest relative was his wife Lena. Two more children had joined the household by then: **Leah Rae Mariotti** (P-0055), the great-grandmother of this database's proband, born 8 September 1936 in Chicago and registered on Cook County Certificate #32174 [14][10], and after the war, **Celiste Dee Mariotti** — the Celeste who appears in her brother Roland's 2023 obituary — born ~1944 in Illinois and recorded with the family in Bedford by the 1950 census [13]. (The 1936 birth certificate carries an interesting puzzle: it is indexed twice on FamilySearch with the same certificate number, once under "UNKNOWN" daughter and once under "Sarah Joy Mariotti." Whether Leah Rae was originally named Sarah Joy and renamed, or whether the indexer mis-tagged a record, is unresolved [14].)\n\nThrough the 1950s and 1960s the children grew and left. Roland served in the postwar military with stations in Alaska, Japan, and Korea and married a Polish-American woman, Virginia Jaskolski, at St. Valentine's Catholic Church on 5 September 1953 — an intermarriage of the kind that the second-generation Italian and Polish Catholic communities were beginning to produce as their children's expectations diverged from their parents'. Leah Rae married into the Reed family, contributing the line that this database's proband descends from. Ugo and Lena themselves eventually moved back east, to **Cicero, Illinois** — the suburb where their first child had been born — and Ugo died there at 78 on **20 February 1982** [2]; his Social Security record gives his last residence ZIP as 60650, the Cicero ZIP code, and his SSN as Iowa-issued, a small bureaucratic trace of the Bedford-to-Cicero arc [18]. He was buried three days later at Queen of Heaven Catholic Cemetery in Hillside, the great Archdiocese of Chicago cemetery consecrated in 1947, in plot **Section 40, Block 213, Lot 7, Grave 8** [3]. Lena outlived him by six years and joined him in 1988. Roland Mariotti, who would die in 2023, was buried in the same cemetery — the family plot the second generation made for the first, a single coordinate in Hillside that ties an Italian *contadino* boy born in 1903 in a marsh-reclaimed Tuscan hamlet to a Cook County suburb a century later.	\N	t	2026-05-30 09:53:51.446353-05
P-0072	2026-05-28	Abiram Stacy Lambert was born on 9 January 1831 in Salem, Washington County, Indiana — a small county-seat town built on land that had been Delaware Indian territory just thirteen years earlier, ceded under the Treaty of St. Mary's in 1818 and opened to white settlement as Indiana neared statehood [1] [2]. His father, David Lambert, was a Maine-born preacher-teacher-farmer and War of 1812 veteran who had drifted southwest through western New York into central Indiana by the late 1820s; his mother, Permelia Barnard, was thirty-three when Abiram was born. He came into the world in Andrew Jackson's second year, the year of Nat Turner's revolt in Virginia and of William Lloyd Garrison's first issue of *The Liberator*. By 1850 the household was settled in Clay Township, Howard County, Indiana, part of the great westward push of Yankee and Mid-Atlantic farmers that was reshaping the Old Northwest. On Christmas Day 1850 Abiram, not yet twenty, married sixteen-year-old Louisa Leach in neighboring Delaware County [10].\n\nThe Lamberts were a restless clan. In the fall of 1853 David Lambert led five Lambert households out of Howard County and across the Mississippi onto a military land warrant in Benton County, Iowa, joining a tide of Indiana and Ohio farmers who would, within a single decade, turn Iowa from frontier into the breadbasket of the Union [7]. Abiram and Louisa appear in the 1854 and 1856 Iowa state censuses in Canton Township with one child [8]. The Kansas-Nebraska Act of 1854 was tearing the nation apart as they settled in, and the Iowa they joined was a free state on the border of bleeding Kansas. By 1860 the young family had moved south again, to Franklin Township in Grundy County, Missouri — but they would not stay long.\n\nWhen the war came in 1861, Abiram enlisted at Corydon, Iowa in Company L of the 3rd Iowa Cavalry — "Naughton's Irish Dragoons," organized at Jefferson City, Missouri on 1 November [4]. The 3rd Iowa fought across the entire western theater. They were at Pea Ridge in March 1862, the engagement that secured Missouri for the Union; in the trenches at Vicksburg in the summer of 1863, Grant's masterstroke that split the Confederacy along the Mississippi; in the brutal cavalry actions at Brice's Crossroads and Tupelo in 1864 against Nathan Bedford Forrest; in Westport that fall, throwing back Sterling Price's last invasion of Missouri; and on Grierson's Raid into the Mississippi heartland over the winter. In the spring of 1865 the regiment rode with James H. Wilson on the largest cavalry operation ever mounted on the North American continent — thirteen thousand mounted men sweeping through Alabama and Georgia in the war's final weeks. Company L is specifically noted in the action at Maplesville, Alabama on 1 April 1865, the day before Selma fell [5]. The regiment was still in the field when news of Lee's surrender at Appomattox reached them. Of the 2,165 men who served in the 3rd Iowa Cavalry, 318 did not come home — eighty-four killed in combat, 234 dead of disease, the standard arithmetic of Civil War service. Abiram did. He mustered out at Atlanta on 9 August 1865 [6].\n\nHe came home to a country remade. The three decades that followed were the Gilded Age — railroad consolidation, the closing of the frontier, and the long agricultural depression that radicalized Midwestern farmers into the Granger and Populist movements. Abiram and Louisa settled in Guthrie County, Iowa, farming Union Township by 1870 and Seely Township by 1880; they would have been among the Iowa farmers reading William Jennings Bryan a decade later. Louisa appears to have died around 1880, at about forty-five [10]. In October 1881, at fifty, Abiram married Helen Amelia Boles — a widow whose first husband had been a Foote — in Guthrie County, and on 30 October 1882 their daughter Estelle Gertrude was born. In January 1907, with the Panic of that year tightening Iowa banks, Abiram filed for his Civil War pension. He was seventy-six and still farming.\n\nSometime between 1915 and 1920, in his mid-eighties, the old cavalryman made one last move. South-central Idaho — the Magic Valley — had been opened to irrigated farming by the 1894 Carey Act and the 1905 Milner Dam, and Iowa farmers were pouring west to claim newly-watered desert at a few dollars an acre. Twin Falls County had been carved out of sagebrush as recently as 1907 [15]. Abiram and Helen settled at Falls City, a small voting precinct in what was then still Lincoln County (it passed to Jerome County when Jerome was carved off in February 1919), about ten miles north of Twin Falls city across the Snake River canyon. The locality is defunct today; its post office had run only from 1909 to 1916 [3] [12]. Abiram died there on 28 April 1927, ninety-six years old, in the spring of Calvin Coolidge's prosperity — the year Charles Lindbergh would cross the Atlantic, Babe Ruth would hit sixty home runs, and the last veterans of the Civil War were vanishing fast. He was buried two days later in Twin Falls Cemetery [13]. Helen, who had married him forty-six years earlier as a widow, would marry once more — to a man named Knapp — and return at last to Iowa, where she lies in Violet Hill Cemetery in Perry, Dallas County, as Helen Amelia Knapp [11].	\N	t	2026-05-30 09:53:51.446353-05
P-0070	2026-05-30	John Talley Reed was born on 26 June 1841 in Woodsfield, the county seat of Monroe County in the rolling hill country of southeastern Ohio [1]. He was a son of Bonum and Rebecca (Talley) Reed [1], a farming family of the upper Ohio valley in the years when the state was still filling in with settlers pushing west from Pennsylvania and Virginia. John carried his mother's maiden name, Talley, as his own middle name — a common way frontier families kept a maternal line visible across generations. He came of age in a Union that was tearing itself apart over slavery and union: he turned twenty in the spring of 1861, the same season Fort Sumter fell and Ohio began raising regiments by the dozen.\n\nIn the middle of that first wartime autumn, on 19 September 1861, John married Elizabeth Willey in neighboring Noble County, Ohio — a county that had itself been carved out of Monroe and Morgan only a decade earlier. Elizabeth had been born on 26 June 1846, sharing his own birthday by the calendar [2]. They were a young couple starting a household against the backdrop of a war that would consume four years and touch nearly every Ohio family; whether John served in the Union army remains an open question this research could not settle. Like tens of thousands of families from the worn-out farms of the eastern hill counties, the Reeds eventually looked west, where the prairie counties of Iowa were selling cheap, deep-soiled land to anyone willing to break the sod.\n\nBy 1880 John and Elizabeth had settled in Jackson Township, Guthrie County, in west-central Iowa, where John farmed. His parents, Bonum and Rebecca, had made the same move — Bonum would die in Guthrie County in December 1893 and Rebecca in July 1911, the two of them laid side by side in Lot 6 of the cemetery at the little hamlet of Monteith [3][4]. The Reeds were part of a broad post-war migration that turned the tallgrass prairie of Iowa into one of the most productive farming regions on earth within a single generation, as railroads threaded the county and turned wheat and corn and hogs into cash. The family was not the only Reed clan in the county — an unrelated Samuel Reed line had arrived in 1857 and settled the Valley and Union neighborhoods — so the Monteith Reeds had to share their surname with strangers at the county fair [6].\n\nThe 1880s brought hard loss. Elizabeth died on 21 December 1880, just thirty-four years old, and was buried in Lot 18 at Monteith [2]. John was left a widower with young children, among them Emma Rebecca (born 1873) and the son who would carry the family forward, John Foulk Reed (born 1877). Family tradition holds that John remarried about 1881 to a Mary E. Headlee, though no record of that union surfaced in this search. He spent the rest of his life on the land in Valley Township, appearing in the county records through the 1895 state census and the 1900 federal census, a settled prairie farmer in the full Gilded-Age maturity of rural Iowa.\n\nJohn Talley Reed died on 11 November 1903 in Valley Township, at age sixty-two, and was buried at Monteith Cemetery near the parents and the wife who had gone before him [1][5]. He died in a county that looked nothing like the raw frontier his parents had broken a half-century earlier: by 1903 Guthrie County was a tidy grid of fenced farms, county roads, and rail-served market towns. No obituary for him turned up in the open newspaper collections, the Guthrie-area papers of that November not yet being digitized [8] — but the cemetery survey, taken by WPA workers in the 1930s, preserved the bare and durable facts of his life and the family plot at Monteith that gathered three generations of Reeds into one quiet ground.	\N	t	2026-05-30 13:43:52.653522-05
P-0062	2026-05-30	Earl Wayne Reed was born on 19 July 1899 in Guthrie County, in the rolling\nfarm country of west-central Iowa, the eldest son of John Foulk Reed and\nEstelle Gertrude Lambert [1][2]. He arrived in the last summer of the\nnineteenth century, into a young nation still catching its breath after the\nPanic of 1893 and the brief, feverish Spanish-American War — a country whose\ncenter of gravity was exactly the kind of small county-seat farming town,\nGuthrie Center, where the 1900 census found him as a one-year-old in his\nparents' household [2]. The Reeds were restless, as so many plains families\nwere in those years; over the next two decades the household drifted north and\nwest across Iowa, into South Dakota, and on toward Wisconsin, chasing the work\nand land that the railroads had thrown open across the upper Midwest.\n\nHis was a large and not always lucky family. Among his siblings was a brother,\nHarold Merle Reed, whose life ended far from any Iowa cornfield — he died in\n1921 in Panama, where the recently opened Canal Zone drew a generation of young\nAmerican men into its orbit of labor, soldiering, and disease [3]. The fuller\nshape of the family — four Reed children and, after their mother's later\nremarriage, an Eichinger half-brother — is set out in the dossier for Estelle\nherself [[P-0036]]. Earl came of age just as the United States entered the\nFirst World War; in 1917 or 1918 he registered for the draft not in Iowa but\nin Waukesha, Wisconsin, a marker of how far the family had already roamed by\nthe time he reached twenty [4].\n\nThe 1920s carried Earl, like hundreds of thousands of Midwesterners, into the\ngravitational pull of Chicago. By 1930 he had settled in Cicero — the gritty,\nfactory-laced industrial suburb on the city's western edge, then notorious as\nthe staging ground of the Capone outfit — where he raised his family with his\nwife, Isabelle Zika, the daughter of Chicago's large Bohemian Czech community\n[5]. Their sons arrived through the heart of the Great Depression: Earl Jr. in\nDecember 1930, John Ronald in 1934, and James Gary in 1939 [6][7][8]. Through\nit all Earl worked as a carpenter [13] — a trade that, even in lean years, kept\na man employed in a metropolis perpetually building, tearing down, and building\nagain. The family stayed rooted in Cicero across both the 1930 and 1940\ncensuses [5][9], weathering the decade that broke so many.\n\nWhen the country went to war again, Earl — by then past forty — registered in\nthe 1942 "old man's registration," the WWII draft sweep of older men meant to\ninventory the nation's manpower and skills [10]. The postwar years brought the\nupward, outward mobility that defined his generation's later life. By the 1950\ncensus the family had moved from Cicero into Chicago proper [11], and in the\ndecades that followed Earl followed the great suburban tide still farther west,\nout past the city limits into DuPage County. He spent his last years at 4 N 711\nMedinah Road in Addison [14], in the booming postwar suburbs that cornfields\nwere rapidly becoming.\n\nEarl Wayne Reed died on 7 April 1974, at Elk Grove Village in Cook County,\nIllinois, at the age of seventy-four [12]. He was buried four days later, on 11\nApril, at Lakewood Memorial Park in Elgin, his funeral handled by the Martin\nFuneral Home; the informant on his death record was a "John Reed," very likely\nhis son John Ronald [15]. He had lived three-quarters of a century that traced\nthe whole arc of the American twentieth century — from a horse-and-buggy Iowa\nfarm town at the turn of the century, through the industrial boom and bust of\nChicago, to a postwar suburb of expressways and subdivisions. His wife Isabelle\nand three sons survived him, and his namesake, Earl Wayne Reed Jr., would carry\nthe name another fifty years.	\N	t	2026-05-30 15:38:23.279346-05
P-0078	2026-05-30	Paul Pouliot was born on 24 March 1834 and baptized in the parish of Saint-Laurent on the Île d'Orléans, the long green island that sits in the St. Lawrence River just below Québec City [1]. He was one of seventeen children born to François Pouliot and Julie Audet dit Lapointe, a farming couple married in 1832 in the neighbouring parish of Saint-Jean [2][3]. The Pouliots had by then been rooted on the island and the Côte-de-Beaupré for nearly two centuries, descendants of the seventeenth-century settler Charles Pouliot. The Île d'Orléans of Paul's boyhood was a crowded, subdivided seigneurial countryside under British colonial rule; the failed Lower Canada Rebellion of 1837–38 had just passed, and the long-cultivated farms could no longer be split among ever-larger Catholic families. For a younger son in a household of seventeen, the island offered a name and a faith but very little land.\n\nThe 1851 census still found Paul, then about seventeen, living with his family on the island [4]. But the pressure that was emptying rural Québec of its surplus sons was already pulling hundreds of thousands of French Canadians south and west across the border, and Paul soon joined them. His destination was no accident. In 1850 the charismatic temperance priest Father Charles Chiniquy had planted a French-Canadian Catholic colony on the Illinois prairie at a place he named St. Anne, in Kankakee County, and a steady stream of Québec families followed — some two hundred settlers by the end of 1851, and more than a thousand families in 1854 alone [14]. Paul came into this wave in the mid-1850s, trading the worn farms of the St. Lawrence for cheap, flat, treeless Illinois land that a young man could actually own.\n\nIt was at St. Anne, on 7 November 1858, that Paul married Henriette St. Louis, herself of French-Canadian stock [5][6]. They married into a community in turmoil: just two years earlier, in September 1856, Bishop O'Regan had excommunicated Father Chiniquy, and a large part of the colony had broken with Rome and turned Protestant — a schism so bitter it produced lawsuits, one of them defended by a Springfield attorney named Abraham Lincoln [15]. The Pouliots remained Catholic, and like many in the colony they eventually left the contested prairie for the city. Over the next two decades Paul and Henriette raised a large family — nine children in all: Henriette (1859), Thomas (1861), Harriet (1862), Francois (1863), Albert (1870), Edward (1873), Arthur (1876), Beatrice Delina (1878), and Eva (1881) [7]. The shift of the younger births into Cook County marks the family's move to Chicago, where Delina and Eva were both registered at birth [8][9].\n\nBy 1880 the household was firmly established in Chicago, the fastest-growing city in America, rebuilt at furious speed after the Great Fire of 1871 and swelling with Catholic immigrants — Irish, German, Polish, and the French Canadians among whom the Pouliots could still hear their mother tongue [10]. Paul lived through the city's Gilded-Age boom: the rise of the stockyards and rail yards, the Haymarket affair of 1886, and the World's Columbian Exposition of 1893 that announced Chicago to the world. The 1900 census still found him in the city [11], by then a widower — Henriette had died in 1890, leaving him the better part of thirteen years alone among his grown children [6].\n\nPaul Pouliot died in Chicago on 10 May 1903, at sixty-nine [12]. He had crossed in a single lifetime from a subdivided island parish under the British crown to a metropolis of more than a million on Lake Michigan, one small thread in the great southward exodus that carried perhaps a million French Canadians out of Québec in the nineteenth century. His daughter Beatrice Delina — the only one of his nine children carried forward in this family's records so far — married John Francis Zika, joining the French-Canadian line to a Bohemian one, and it is through her that Paul's descent runs down to the present.	\N	t	2026-05-30 20:44:12.395074-05
\.


--
-- Data for Name: person; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.person (person_id, primary_name, sex, birth_date, birth_granularity, birth_place_id, death_date, death_granularity, death_place_id, life_confidence, privacy_level, branch, fs_id, notes, profile_media_id, source_summary, created_at, updated_at) FROM stdin;
P-0004	Elizabeth (Willey) Reed	female	circa 1846	\N	\N	1880-12-20	\N	PL-0002	med	public	Paternal Reed by marriage	\N	Married John T. Reed in Noble County, Ohio; moved to Iowa by 1870.	\N	Report	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0002	Rebecca (Talley) Reed	female	circa 1822	\N	PL-0074	1911	\N	PL-0002	med	public	Paternal Reed	\N	Daughter of John Foulk Talley and Hannah Poulson; migrated to Iowa; buried in Monteith.	\N	Report; Find a Grave	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0036	Estelle Gertrude Lambert	female	1882-10-30	\N	PL-0038	1946-05-20	\N	PL-0016	high	public	Maternal Lambert	LMWG-K6F	Daughter of Abiram S. Lambert and Helen Amelia Boles; later wife of John Foulk Reed.\n[deep-dive 2026-05-28] [deep-dive 2026-05-28 PM] FS PID LMWG-K6F confirmed; previously only on duplicate stub P-0063. All 19 FS attached sources inspected via authenticated Chrome MCP. THREE marriages confirmed: (1) John Foulk Reed m. 1899-03-05 Guthrie Co IA — four children (Earl Wayne 1899, Harold Merle 1901, Oscar G. 1903, Edna Gertrude 1906); (2) Clarence D. Eichinger m. 1912-09-18 Algona, Kossuth Co IA — one child (Ray ~1914); (3) Harry Sinderson by 1946 — died as 'Estelle G Sinderson' in Chicago, divorced, waitress, address 1339 S 48 St. Cook Co IL death cert (Q2M8-FDWY) confirms burial at Prairie Home Cemetery, Waukesha WI — GPKG E-0057 is correct (the AM dossier's Prairie-Twp-Delaware-Co patch was withdrawn). 1900 census Valley Twp Guthrie Center IA; 1920 census Sioux Falls SD; 1925 IA State Census Waterloo IA. Mother Helen had remarried as 'Helen Amelia Knapp' by the 1895 IA State Census — long before Abiram's 1927 death — so Estelle was raised partly by her Knapp stepfather Leslie from at least age 12.	\N	Report FSID:LMWG-K6F; FamilySearch attached records (19 of 19 inspected via authenticated Chrome MCP, 2026-05-28): Iowa Co Births 1880-1935 XVFQ-S6T (birth); IA State Census 1885 HZXM-SN2 (childhood household); IA State Census 1895 VT33-RWL (mother as Knapp); Iowa Co Marriages KLWR-25L + XJZB-48K + Iowa Marriages XJLP-MXL (1899 first marriage); Iowa Co Births XVN1-39X (Earl Wayne); Delayed Births Q246-SDPC (Harold Merle), XVZ5-VVH+XV2Y-VDM (Oscar G.), Q24X-4Z14 (Edna); 1900 US Census M9KG-C8W; Iowa Co Marriages XJ8W-XZ2 + XJPF-H6J (1912 Eichinger marriage); 1920 US Census M6JH-P4L; 1925 IA State Census QKQW-X88X; Cook Co IL Death Cert Q2M8-FDWY + IL Deaths N3Y4-J4F (1946 Sinderson death); Cook Co IL Death Cert Q2MN-CMG6 (Earl Wayne Reed 1974, names Estelle as mother). Plus Wikipedia/Monteith Iowa (Harmon T. Reed founding 1881).	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0068	Beatrice Delina Pouliot	female	1878-04-14	\N	PL-0158	1964-08-01	\N	PL-0031	high	public	Pouliot	LBHY-3B5	French-Canadian descent; married John F. Zika.	\N	FamilySearch (FS PID: LBHY-3B5)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0072	Abiram Stacy Lambert	male	1831-01-09	\N	PL-0367	1927-04-28	\N	PL-0059	high	public	Maternal Lambert	2WFL-ZVT	Civil War veteran (Co. L, 3rd Iowa Cavalry); farmer in Guthrie County, Iowa.\n[deep-dive 2026-05-28] Parents confirmed: David Lambert (1789-1866, b. Canaan ME, bur. McBroom Cem, Vinton, Benton Co IA) and Permelia Barnard (1798-1865) — multi-source (WikiTree + FindAGrave #10569107 + Benton Co Pioneers). Family migrated Howard Co IN → Benton Co IA fall 1853. Service detail: Co. L, 3rd Iowa Cavalry was at Maplesville AL on 1 Apr 1865 during Wilson's Raid. Death locality 'Falls City' was a Lincoln-then-Jerome Co Idaho voting precinct (PO 1909-1916), ~10 mi N of Twin Falls city across the Snake River canyon; defunct today.	\N	FamilySearch (FS PID: 2WFL-ZVT); WikiTree Lambert-3978 (parents); FindAGrave #10569107 (mother); BillionGraves David Lambert (father); Logan's Roster of Iowa Soldiers / iagenweb (3rd IA Cav); NPS Battle Unit Details UIA0003RC; HomeTownLocator (Falls City ID); Benton County Pioneers / iagenweb (1854/56 residence)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0012	Helen Amelia (Boles) Lambert	female	circa 1849	\N	PL-0066	1939-01-23	\N	PL-0067	med	public	Maternal Lambert	\N	Daughter of Silas P. Boles and Martha L. Spear; second wife of Abiram S. Lambert.\n[deep-dive 2026-05-28] [deep-dive 2026-05-28 via P-0036] Death date refined to 1939-01-23 per FS PID 29WD-T9P; previously stored as year-only '1938'. Burial: Violet Hill Cemetery, Perry, Dallas Co IA, with stone inscribed as 'Helen Amelia Knapp' (FindAGrave #16177390). PM correction: Helen had already been Mrs. Knapp by the 1895 IA State Census — the Knapp remarriage was a 1880s/early-1890s event after she separated from Abiram, not a post-1927 remarriage. She lived for decades as Mrs. Knapp with Leslie Knapp; her grave reflects that surname.	\N	Report; FindAGrave #16177390 (Helen Amelia Knapp); FS Iowa State Census 1885 HZXM-SN2; FS Iowa State Census 1895 (mother surname as Knapp); FS PID 29WD-T9P	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0129	Absalom Willey	male	6 May 1739	\N	PL-2536	19 December 1791	\N	PL-0097	high	public	Paternal Reed	LTCY-1RM	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: LTCY-1RM)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0142	Deacon Francis Barnard	male	9 September 1719	\N	PL-3186	22 February 1789	\N	PL-0109	high	public	Paternal Reed	LCB7-QL6	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: LCB7-QL6)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0076	Henriette St. Louis	female	1840-03-01	\N	PL-0049	22 January 1890	\N	PL-0158	high	public	Pouliot	MGNK-YL2	Wife of Paul Pouliot; French-Canadian.	\N	FamilySearch (FS PID: MGNK-YL2)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0075	Anton Zika	male	22 July 1848	\N	PL-0233	22 December 1924	\N	PL-0158	high	public	Zika	LKTC-D4S	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: LKTC-D4S)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0064	John Francis Zika	male	1875-10-10	\N	PL-0233	1957-06-09	\N	PL-0158	high	public	Zika	L2XV-HRY	Boilermaker in Chicago; Czech-American community.	\N	FamilySearch (FS PID: L2XV-HRY)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0042	Stephen Reed	male	1760	\N	PL-0088	1814-04	\N	PL-0083	med	public	Paternal Reed	LC5Y-HJ1	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 13:24:50.942302-05
P-0078	Paul Pouliot	male	1834-03-24	\N	PL-0506	1903-05-10	\N	PL-0158	high	public	Pouliot	96JW-KX5	French-Canadian immigrant; father of Delina.\n[deep-dive 2026-05-30] Married Henriette St. Louis 7 Nov 1858 at St. Anne, Kankakee Co., IL — the Chiniquy French-Canadian colony. Father of nine children; only Delina (P-0068) is materialized in LRGDM. One of 17 children of François Pouliot & Julie Audet dit Lapointe.	\N	FamilySearch (FS PID: 96JW-KX5); FamilySearch attached records (30): 1834 St-Laurent baptism, 1851 Canada census, 1858 IL marriage, 1878/1881 Cook Co. birth registers, 1880 & 1900 US census, 1903 Cook Co. death	2026-05-30 09:21:56.321112-05	2026-05-30 20:44:12.241497-05
P-0055	Leah Rae Mariotti	female	1936-09-08	\N	PL-0158	2025-07-21	\N	PL-0159	high	public	Maternal Mariotti	L274-KT7	NULL	\N	FamilySearch (FS PID: L274-KT7)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0056	John Ronald Reed Sr	male	1934-07-18	\N	PL-0158	1995-05-02	\N	PL-0163	high	public	Paternal Reed	LY94-373	Child of Earl & Isabelle (age 5 in 1940 census).\n[deep-dive 2026-05-30] Married Leah Rae Mariotti in 1956; first home Westchester, IL, then Glen Ellyn from ~1964. Seven children (two sets of twins). Roman Catholic — family parish St. James the Apostle, Glen Ellyn. Two brothers: Earl Wayne 'Wayne' Reed Jr (1930-12-09 – 2024-07-20) and James 'Jim' Reed (b. ~1940). Parents divorced 1940–1950; mother Isabelle headed the Cicero household (biller, telephone factory). E-0025 (1949-02) = his SS-5 application. Served in the U.S. military during the Korean War (family testimony) — recalled training at Camp Pendleton (USMC), branch/dates unconfirmed. Maternal grandfather of proband John Kenny (L274-KNT) via daughter Karen (Reed) Kenny. Likely buried with Leah at Queen of Heaven Catholic Cemetery, Hillside (no FindAGrave memorial yet).	\N	FamilySearch (FS PID: LY94-373); 1934 Cook County birth certificate; 1940 & 1950 US Censuses (Cicero); SSDI (d. 1995-05-02, Glen Ellyn 60137); SS NUMIDENT (parents Earl W. Reed & Isabelle Zika, SSN applied Feb 1949); brother Earl W. Reed Jr's 2024 obituary; Leah R. Reed's 2025 obituary (Williams-Kampp — marriage 1956, 7 children, St. James parish, Queen of Heaven burial); FindAGrave (Leah memorial #285158675). Deep-dive 2026-05-30.	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0058	Isabelle Harriet Zika	female	3 December 1913	\N	PL-0158	13 October 2006	\N	PL-0172	high	public	Zika	LY94-DBH	Daughter of John F. Zika & Delina Pouliot; Chicago area.	\N	FamilySearch (FS PID: LY94-DBH)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0164	UMILTA' GIACOMELLI	female	1763	\N	PL-2171	29 December 1823	\N	PL-0178	high	public	Maternal Mariotti	GBFH-HZV	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GBFH-HZV)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0163	PIER DOMENICO NICCOLAI	male	12 March 1761	\N	PL-2171	23 December 1846	\N	PL-0178	high	public	Maternal Mariotti	GBF4-TKM	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GBF4-TKM)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0066	Zelinda Pagni	female	6 September 1874	\N	PL-0262	9 November 1936	\N	PL-0179	high	public	Maternal Mariotti	GCKQ-6RJ	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GCKQ-6RJ)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0059	Ugo Mariotti	male	21 July 1903	\N	PL-0178	20 February 1982	\N	PL-0179	high	public	Maternal Mariotti	PWPQ-D8V	Imported from FamilySearch extract on 2026-05-26.\n[deep-dive 2026-05-28] [deep-dive 2026-05-28 (2nd pass, FS-attached sources inspected)] PARENTS CONFIRMED via 1927 IA marriage: father Leopoldo Mariotti (P-0067), mother **Quintilia Lenzi (P-0069)** — NOT Zelinda Pagni (P-0066). SPOUSE CONFIRMED: Lena A Dini (P-0060), m. 5 May 1927 Lenox, Taylor Co, IA. CHILDREN per FS/census/obit: Rolando 'Roland' Mariotti (b. 17 Jun 1929 Cicero IL, d. 2023), Leah Rae Mariotti (P-0055; b. 8 Sep 1936 Chicago — see name-conflict note below), Celiste Dee 'Celeste' Mariotti (b. ~1944 IL, living). RESIDENCE: family lived in Bedford, Taylor County, Iowa ~1928–~1950; Ugo was proprietor of a Candy Kitchen there (1950 census). Late-life move to Cicero IL (ZIP 60650) before 1982 death. BURIAL: Queen of Heaven Catholic Cemetery, Hillside IL, Section 40/Block 213/Lot 7/Grave 8 (FindAGrave #288488976). NAMING CONFLICT: 8 Sep 1936 Cook Co birth cert #32174 is indexed by FS twice — once as 'UNKNOWN daughter' and once as 'Sarah Joy Mariotti' — same date and cert#. Likely the same record indexed before vs. after a name was supplied to the registrar. Whether Leah Rae's original given name was 'Sarah Joy' (later changed) needs verification against the scanned certificate.	\N	FamilySearch (FS PID: PWPQ-D8V); Iowa County Marriages 1838-1934 (FS XJX4-VDB); IL Northern District Naturalization Index 1840-1950 (FS XKGJ-M1P); IL Cook Co Birth Cert #228 [Roland] (FS QVSH-PG84); IL Cook Co Birth Cert #32174 [Leah/'Sarah Joy'] (FS QGCF-8JT5, QGCF-M3H7); 1930 US Census (FS XMKQ-K9T); 1940 US Census (FS KMBB-TY1); 1950 US Census (FS 6FQW-JRYD); IA WWII Draft 16 Feb 1942 (FS QG2P-J7N1); SSDI (FS JLLR-Z6F); IL Archdiocese Cemetery Records (FS Q2HF-8P34); FindAGrave #288488976; Roland W. Mariotti obituary (Shirley & Stout, 2023)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0060	Lena  A Dini	female	16 June 1909	\N	PL-0179	6 June 1988	\N	PL-0187	high	public	Maternal Mariotti	L278-SXK	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: L278-SXK)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0083	Rebecca Talley	female	7 November 1822	\N	PL-0638	16 July 1911	\N	PL-0196	high	public	Paternal Reed	L7J3-GVG	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: L7J3-GVG)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0061	John Foulk Reed	male	1877-11-25	\N	PL-0196	1952-03-30	\N	PL-0197	high	public	Paternal Reed	KLGC-TLC	Son of John T. Reed and Elizabeth Willey; later father of Earl Wayne Reed.\n[deep-dive 2026-05-28] [deep-dive 2026-05-28 via P-0036] Burial confirmed at Oakdale Memorial Gardens, Davenport, Scott Co IA per FS PID KLGC-TLC. FS sourceCount=31.	\N	FamilySearch (FS PID: KLGC-TLC); FamilySearch extract 2026-05-26 (PID KLGC-TLC); see also reports/deep-dives/P-0036.md	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0074	Helen Amelia Boles	female	10 June 1849	\N	PL-0413	23 January 1939	\N	PL-0208	high	public	Maternal Lambert	29WD-T9P	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: 29WD-T9P)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0071	Elizabeth Willey	female	26 June 1846	\N	PL-0347	21 December 1880	\N	PL-0208	high	public	Paternal Reed	KJP4-9R4	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: KJP4-9R4)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0088	Marie Anna Říhová	female	21 March 1820	\N	PL-0233	18 October 1871	\N	PL-0233	high	public	Zika	GWCT-VWD	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GWCT-VWD)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0087	František Zíka	male	27 April 1801	\N	PL-0233	3 July 1872	\N	PL-0233	high	public	Zika	GWCT-J3K	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GWCT-J3K)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0069	Quintilia Lenzi	female	23 November 1876	\N	PL-0247	9 September 1960	\N	PL-0247	high	public	Maternal Mariotti	PWP7-JQ8	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: PWP7-JQ8)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0067	Leopoldo Mariotti	male	29 October 1871	\N	PL-0278	3 March 1933	\N	PL-0247	high	public	Maternal Mariotti	PWPW-LPC	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: PWPW-LPC)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0162	Maria Pasqua Baldi	female	about 1730	\N	PL-0390	\N	\N	PL-0390	med	public	Maternal Mariotti	GRLP-TVD	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GRLP-TVD)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0161	Giovan Pietro Spadoni	male	2 April 1725	\N	PL-0390	\N	\N	PL-0390	med	public	Maternal Mariotti	GRL2-KCR	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GRL2-KCR)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0122	ANGIOLO NICCOLAI	male	27 February 1780	\N	PL-2171	20 December 1862	\N	PL-0390	high	public	Maternal Mariotti	GBFH-79H	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GBFH-79H)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0120	MARIA UMILTA' PORCIANI	female	1787	\N	PL-0178	4 November 1854	\N	PL-0390	high	public	Maternal Mariotti	GBF4-PH4	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GBF4-PH4)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0118	Maria Angiola Ercolini	female	about 1780	\N	\N	\N	\N	PL-0390	med	public	Maternal Mariotti	GRLV-YDR	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GRLV-YDR)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0117	Pier Domenico Spadoni	male	about 1774	\N	\N	3 April 1864	\N	PL-0390	med	public	Maternal Mariotti	GRLV-XZB	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GRLV-XZB)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0099	Giovanni Dini	male	1803	\N	\N	22 December 1878	\N	PL-0390	high	public	Maternal Mariotti	P355-XWC	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: P355-XWC)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0155	Marie Louise St-Mars	female	26 October 1739	\N	PL-4392	before 17 March 1792	\N	PL-0506	high	public	Pouliot	L8PT-TR4	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: L8PT-TR4)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0154	Pierre Pouliot	male	23 May 1749	\N	PL-0506	8 July 1822	\N	PL-0506	high	public	Pouliot	L4QP-2GB	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: L4QP-2GB)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0153	Genevieve Godbout	female	5 March 1753	\N	PL-0506	29 May 1810	\N	PL-0506	high	public	Pouliot	LJYN-TJY	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: LJYN-TJY)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0111	Therese Denis Lapierre	female	22 June 1779	\N	PL-0506	20 November 1846	\N	PL-0506	high	public	Pouliot	KCYF-LFN	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: KCYF-LFN)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0079	Angiolo Pagni	male	1847	\N	PL-0262	3 January 1925	\N	PL-0531	high	public	Maternal Mariotti	P7P4-4TS	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: P7P4-4TS)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0080	Maria Emilia Dini	female	8 June 1843	\N	PL-0390	26 November 1913	\N	PL-0557	high	public	Maternal Mariotti	P99J-6YC	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: P99J-6YC)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0569	John Strong	male	about 1585	\N	PL-67532	14 June 1613	\N	PL-67532	high	public	Paternal Reed	94RB-17S	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 94RB-17S)	2026-05-30 13:23:14.722755-05	2026-05-30 13:24:50.775708-05
P-0144	Jonathan Abel Oakes	male	21 August 1717	\N	PL-3553	2 December 1784	\N	PL-0667	high	public	Maternal Lambert	LZP7-DSJ	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: LZP7-DSJ)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0106	Permelia "Millie" Oaks	female	11 September 1768	\N	PL-1467	6 January 1845	\N	PL-0667	high	public	Maternal Lambert	LZNM-W98	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: LZNM-W98)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0105	Sherebiah Lambert Jr	male	11 September 1759	\N	PL-1426	1 May 1833	\N	PL-0667	high	public	Maternal Lambert	LDF8-39B	Revolutionary veteran; moved to Ohio by ~1819; later married Permelia Oak.	\N	FamilySearch (FS PID: LDF8-39B)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0085	Permelia Barnard	female	12 June 1798	\N	PL-0699	15 December 1865	\N	PL-0668	high	public	Paternal Reed	LDFM-SM7	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: LDFM-SM7)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0084	David Lambert	male	17 January 1790	\N	PL-0667	15 December 1865	\N	PL-0668	high	public	Maternal Lambert	L7XP-Y6P	Son of Sherebiah Lambert II and an unknown first wife; pioneer to Indiana.	\N	FamilySearch (FS PID: L7XP-Y6P)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0092	Martha Lovina Spears	female	25 April 1823	\N	PL-0931	24 December 1895	\N	PL-0732	high	public	Maternal Lambert	KN1Q-GH1	Wife of Silas P. Boles.	\N	FamilySearch (FS PID: KN1Q-GH1)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0086	Silas A. Boles	male	28 April 1819	\N	PL-0731	3 April 1900	\N	PL-0732	high	public	Maternal Lambert	KN1Q-9L5	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: KN1Q-9L5)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0157	Marie Angelique Pépin dit Lachance	female	9 November 1747	\N	PL-4553	21 March 1826	\N	PL-1000	high	public	Pouliot	LRD1-TMD	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: LRD1-TMD)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0113	Marie Louise Tremblay	female	24 December 1782	\N	PL-1765	7 August 1869	\N	PL-1000	high	public	Pouliot	LHJ9-SLF	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: LHJ9-SLF)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0112	Michel Olivier Audet	male	12 March 1778	\N	PL-1000	14 November 1848	\N	PL-1000	high	public	Pouliot	MJ8T-X8V	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: MJ8T-X8V)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0094	Julie Audet dit Lapointe	female	1812-03-01	\N	PL-1000	1894-04-03	\N	PL-1001	high	public	Pouliot	96JW-KFH	Wife of François; Audet dit Lapointe line.	\N	FamilySearch (FS PID: 96JW-KFH)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0100	Maria Cristiana Niccolai	female	1807	\N	PL-1230	29 September 1870	\N	PL-1038	high	public	Maternal Mariotti	PMCT-ZRN	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: PMCT-ZRN)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0095	Domenico Dini	male	1806	\N	PL-1038	18 October 1888	\N	PL-1039	high	public	Maternal Mariotti	PMCT-5RX	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: PMCT-5RX)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0146	Františka Doležalová	female	about 1730	\N	\N	29 November 1805	\N	PL-1550	med	public	Zika	GWCT-1N1	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GWCT-1N1)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0145	Jan Zíka	male	24 May 1729	\N	PL-1550	3 August 1810	\N	PL-1550	med	public	Zika	GWCT-J7B	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GWCT-J7B)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0114	Marie Zemanová	female	10 October 1797	\N	PL-1810	19 December 1853	\N	PL-1550	med	public	Zika	GWCY-M48	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GWCY-M48)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0109	František Říha	male	9 January 1788	\N	PL-0233	23 December 1848	\N	PL-1550	med	public	Zika	GWCY-7JL	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GWCY-7JL)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0108	Barbora Michalíčková	female	2 May 1776	\N	PL-0233	7 May 1863	\N	PL-1550	med	public	Zika	GWCT-BFG	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GWCT-BFG)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0110	Pierre Pouliot	male	28 August 1775	\N	PL-1635	8 April 1845	\N	PL-1635	high	public	Pouliot	KZXQ-XCP	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: KZXQ-XCP)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0123	Priscilla Foulk	female	3 March 1775	\N	PL-2218	3 March 1802	\N	PL-2219	high	public	Paternal Reed	K262-J62	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: K262-J62)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0124	Harman Talley	male	28 April 1775	\N	PL-2218	24 August 1858	\N	PL-2268	high	public	Paternal Reed	L7NJ-XMX	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: L7NJ-XMX)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0125	Sarah Brown	female	1758	\N	PL-2318	July 1794	\N	PL-2319	high	public	Paternal Reed	L8J2-MLN	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: L8J2-MLN)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0127	Richard R. Dickerson Sr.	male	1748	\N	PL-2424	1836	\N	PL-2425	high	public	Paternal Reed	L8J2-M2Y	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: L8J2-M2Y)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0128	Simon Poulson lll	male	16 October 1752	\N	PL-2218	1 October 1801	\N	PL-2480	high	public	Paternal Reed	KVJJ-262	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: KVJJ-262)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0130	Margaret Polk	female	14 November 1741	\N	PL-2593	3 January 1816	\N	PL-2594	high	public	Paternal Reed	GSMH-72F	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GSMH-72F)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0135	Elizabeth Lemley	female	23 June 1756	\N	PL-2908	1 May 1792	\N	PL-2714	high	public	Paternal Reed	M3G6-T7D	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: M3G6-T7D)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0132	Benjamin Dye	male	1755	\N	PL-2713	2 April 1789	\N	PL-2714	high	public	Paternal Reed	GDZ6-V7D	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GDZ6-V7D)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0610	Innocent Audet	male	26 March 1614	\N	PL-80226	\N	\N	PL-22281	high	public	Pouliot	LYSP-RN5	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LYSP-RN5)	2026-05-30 13:23:14.722755-05	2026-05-30 13:24:50.775708-05
P-0134	Asher Allen	male	22 May 1756	\N	PL-2841	5 February 1840	\N	PL-2842	high	public	Paternal Reed	97RN-BFV	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: 97RN-BFV)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0136	Lydia Hopkins	female	16 April 1737	\N	PL-2975	5 March 1826	\N	PL-2976	med	public	Maternal Lambert	G8SF-YZH	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: G8SF-YZH)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0137	Elizabeth Polly Palmer	female	14 November 1757	\N	PL-2841	23 July 1851	\N	PL-3045	high	public	Paternal Reed	2S2L-ZGM	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: 2S2L-ZGM)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0140	Abigail Whitney Rand	female	14 November 1736	\N	PL-1467	1813	\N	PL-3258	high	public	Maternal Lambert	LHKW-2DG	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: LHKW-2DG)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0141	Edward Ebenezer Barnard	male	8 September 1710	\N	PL-3186	5 February 1783	\N	PL-3331	high	public	Paternal Reed	L5ZR-PVC	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: L5ZR-PVC)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0143	Lucretia Carroll Pinney	female	17 January 1722	\N	PL-3186	26 October 1773	\N	PL-3478	high	public	Paternal Reed	LD9K-29K	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: LD9K-29K)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0156	Jacques Denis	male	18 June 1732	\N	PL-4471	6 May 1810	\N	PL-4472	high	public	Pouliot	KK1G-S62	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: KK1G-S62)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0159	Jacques Tremblay	male	9 November 1744	\N	PL-4720	20 January 1810	\N	PL-4635	high	public	Pouliot	KLLJ-SJR	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: KLLJ-SJR)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0158	Guillaume Audet	male	8 March 1742	\N	PL-4635	18 May 1805	\N	PL-4636	med	public	Pouliot	LRQ4-GD9	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: LRQ4-GD9)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0160	Marie Angelique Delage	female	23 October 1738	\N	PL-4805	16 June 1810	\N	PL-4805	high	public	Pouliot	KN1W-474	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: KN1W-474)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0053	Edward Kenny	male	23 March 1933	\N	PL-0155	13 June 1978	\N	PL-5232	high	public	Paternal Kenny	L274-KLZ	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: L274-KLZ)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0166	CATERINA PARLANTI	female	\N	\N	PL-5231	\N	\N	\N	high	public	Maternal Mariotti	PM4B-ZZR	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: PM4B-ZZR)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0165	GIUSEPPE PORCIANI	male	\N	\N	PL-5231	\N	\N	\N	high	public	Maternal Mariotti	PM4B-PBP	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: PM4B-PBP)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0152	Magdalena Říhová	female	\N	\N	\N	\N	\N	\N	med	public	Zika	GT5S-PGJ	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GT5S-PGJ)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0151	Magdalena Dufková	female	1747	\N	PL-4083	\N	\N	\N	med	public	Zika	PH93-PYK	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: PH93-PYK)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0150	Václav Říha	male	\N	\N	\N	\N	\N	\N	med	public	Zika	GPDL-25D	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GPDL-25D)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0149	Eva Zemanová	female	\N	\N	\N	\N	\N	\N	med	public	Zika	GT5S-14P	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GT5S-14P)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0148	František Jan Michalíček	male	1745	\N	PL-3854	1800	\N	\N	med	public	Zika	PH93-RMY	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: PH93-RMY)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0147	Antonín Zeman	male	\N	\N	\N	\N	\N	\N	med	public	Zika	GPDL-R79	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GPDL-R79)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0139	Mabel Pinney	female	30 September 1723	\N	PL-3186	1783	\N	\N	high	public	Paternal Reed	L5ZR-LXX	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: L5ZR-LXX)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0126	Ann Patton	female	about 1760	\N	PL-2371	\N	\N	\N	high	public	Paternal Reed	KVJJ-2F9	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: KVJJ-2F9)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0121	Carlo Dini	male	\N	\N	PL-0390	\N	\N	\N	high	public	Maternal Mariotti	P99N-2W1	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: P99N-2W1)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0119	Annunziata Grossi	female	\N	\N	\N	\N	\N	\N	high	public	Maternal Mariotti	P99N-599	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: P99N-599)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0116	Elisabetta Giovacchini	female	\N	\N	\N	\N	\N	\N	med	public	Maternal Mariotti	P35T-Q4G	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: P35T-Q4G)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0115	Pietro Dini	male	\N	\N	\N	\N	\N	\N	med	public	Maternal Mariotti	P355-FRN	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: P355-FRN)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0107	Martin Zíka	male	7 November 1769	\N	PL-0233	\N	\N	\N	med	public	Zika	L2V1-YHK	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: L2V1-YHK)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0104	Thomas Spear	male	\N	\N	\N	\N	\N	\N	high	public	Maternal Lambert	K8F2-Y27	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: K8F2-Y27)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0103	Nancy Walls	female	\N	\N	\N	\N	\N	\N	high	public	Maternal Lambert	K4BN-VM7	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: K4BN-VM7)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0102	Pellegrino Giorgi	male	\N	\N	\N	\N	\N	\N	med	public	Maternal Mariotti	P7P4-8PM	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: P7P4-8PM)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0101	Piera Bellandi	female	about 1815	\N	\N	after 1872	\N	\N	med	public	Maternal Mariotti	PC4W-R8N	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: PC4W-R8N)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0098	Leopoldo Pagni	male	about 1810	\N	\N	\N	\N	\N	med	public	Maternal Mariotti	P7PW-CCK	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: P7PW-CCK)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0097	Henriette Cheffre	female	\N	\N	\N	\N	\N	\N	med	public	Pouliot	GYVW-44Y	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GYVW-44Y)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0096	Pasqua Rosa Spadoni	female	about 1805	\N	PL-0390	\N	\N	\N	high	public	Maternal Mariotti	GSQJ-4RC	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GSQJ-4RC)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0090	František Říha	male	before 1840	\N	PL-0233	before 1960	\N	\N	med	public	Zika	GS6J-92Z	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GS6J-92Z)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0089	Františka Klusová	female	before 1840	\N	PL-0233	before 1950	\N	\N	med	public	Zika	GWCT-JQN	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GWCT-JQN)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0081	Cherubina Giorgi	female	2 July 1844	\N	PL-0262	\N	\N	\N	high	public	Maternal Mariotti	P3YM-9YQ	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: P3YM-9YQ)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0077	Josephine Riha Veta	female	22 April 1854	\N	PL-0233	before 1964	\N	\N	high	public	Zika	LBH1-TK2	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: LBH1-TK2)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0073	Celestino Dini	male	23 September 1845	\N	PL-0390	\N	\N	\N	high	public	Maternal Mariotti	GSQJ-M1C	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GSQJ-M1C)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0065	Louis Dini	male	1873	\N	PL-0247	\N	\N	\N	high	public	Maternal Mariotti	GCKQ-RK3	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GCKQ-RK3)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0057	Laura Kroll	female	\N	\N	\N	\N	\N	\N	med	public	Paternal Kroll	L24Z-SFM	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: L24Z-SFM)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0054	Phyllis Kroll	female	1931	\N	\N	May 2020	\N	\N	med	public	Paternal Kroll	L274-KGR	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: L274-KGR)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0033	James G. Reed	male	circa 1939	\N	PL-0010	NULL	\N	\N	med	public	Reed-Zika	\N	Child of Earl & Isabelle (6/12 in 1940 census).	\N	Report / 1940 census	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0031	Earl Wayne Reed Jr.	male	1930	\N	PL-0010	2024	\N	\N	med	public	Reed-Zika	\N	Child of Earl & Isabelle (per obituary).	\N	Report / Obituary	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0028	Henriette (Cheffre) Filiatrault	female	circa 1821	\N	\N	NULL	\N	\N	med	public	Pouliot	\N	Wife of Joseph Filiatrault dit St. Louis.	\N	Report	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0020	Josefína “Josie” (Říha) Zika	female	1853	\N	PL-0012	1930	\N	\N	med	public	Zika	\N	Wife of Anton; Czech immigrant.	\N	Report	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0019	Anton Zika	male	1859-06-13	\N	PL-0012	1948	\N	\N	med	public	Zika	\N	Czech immigrant; husband of Josefína (Říha) Zika.	\N	Report	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0018	Permelia M. Oak	female	1788	\N	\N	1845	\N	\N	med	public	Maternal Lambert	\N	Second wife of Sherebiah Jr.	\N	Report	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0016	Lydia A. (Hopkins) Lambert	female	1738	\N	\N	1806	\N	\N	med	public	Maternal Lambert	\N	Wife of Sherebiah Sr.; maiden name uncertain.	\N	Report	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0013	Silas P. Boles	male	1818	\N	\N	1900	\N	\N	med	public	Maternal Lambert	\N	Husband of Martha L. Spear.	\N	Report	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0010	Permelia (Barnard) Lambert	female	circa 1798	\N	\N	1865	\N	\N	med	public	Maternal Lambert	\N	Wife of David Lambert.	\N	Report	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0035	Emma Rebecca Reed	female	1873	\N	\N	circa 1905	\N	\N	med	public	Paternal Reed	\N	Daughter of John T. Reed and Elizabeth Willey.	\N	Report / FamilySearch	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0167	Gerald Arthur Kenny	male	3 November 1961	day	\N	17 October 2025	day	\N	high	public	Paternal Kenny	\N	Father of John Kenny (proband, FS L274-KNT — not yet in DB as of 2026-05-30). Added from memorial prayer card, Williams-Kampp Funeral Home.	\N	\N	2026-05-30 12:22:39.180392-05	2026-05-30 12:22:39.180392-05
P-0168	John Kenny	male	1995	year	\N	\N	\N	\N	high	private	\N	L274-KNT	Proband (root of the tree). Living — privacy_level=private. Added 2026-05-30.	\N	\N	2026-05-30 12:30:44.345343-05	2026-05-30 12:30:44.345343-05
P-0169	Benjamin Reed	male	24 March 1734	\N	PL-5245	\N	\N	PL-5245	med	public	Paternal Reed	PZ8T-G62	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PZ8T-G62)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0666	Jean Roussin	male	about 3 October 1597	\N	PL-99590	about 1682	\N	PL-166023	high	public	Pouliot	LTHY-88Y	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LTHY-88Y)	2026-05-30 13:23:14.722755-05	2026-05-30 13:24:50.775708-05
P-0171	Hezekiah Bonham III	male	1725	\N	PL-5245	1763	\N	PL-5252	high	public	Paternal Reed	L63D-BWR	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L63D-BWR)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0670	André Mouillard	male	\N	\N	PL-36870	\N	\N	PL-36870	high	public	Pouliot	LZPZ-526	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZPZ-526)	2026-05-30 13:23:14.722755-05	2026-05-30 13:24:50.775708-05
P-0173	John Dickerson	male	11 February 1721	\N	PL-2318	15 March 1785	\N	PL-5263	high	public	Paternal Reed	9V31-GLZ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 9V31-GLZ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0723	Jeanne Galiot	female	1605	\N	\N	8 August 1662	\N	PL-82185	high	public	Pouliot	PWHF-K7N	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PWHF-K7N)	2026-05-30 13:23:14.722755-05	2026-05-30 13:24:50.775708-05
P-0175	Gideon Dickerson	male	\N	\N	\N	\N	\N	\N	med	public	Paternal Reed	LVFW-SXF	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVFW-SXF)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0778	Francois de Romilley	male	about 1550	\N	PL-143581	\N	\N	PL-166024	high	public	Pouliot	KVL7-KL6	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KVL7-KL6)	2026-05-30 13:23:14.722755-05	2026-05-30 13:24:50.775708-05
P-0183	Henry Dickerson	male	about 1685	\N	PL-5356	1785	\N	PL-5357	high	public	Paternal Reed	LRQZ-QDQ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRQZ-QDQ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0189	Hezekiah Bonham Sr	male	6 May 1667	\N	PL-5469	27 January 1738	\N	PL-5470	high	public	Paternal Reed	LDMF-GFZ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LDMF-GFZ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0199	John Willey	male	1708	\N	PL-5760	1742	\N	PL-5760	high	public	Paternal Reed	P3WB-9J8	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P3WB-9J8)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0203	James O Dye	male	1 January 1720	\N	PL-5907	6 April 1764	\N	PL-5908	high	public	Paternal Reed	LK4Y-B4R	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LK4Y-B4R)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0207	Willey	male	\N	\N	\N	\N	\N	\N	med	public	Paternal Reed	GKZL-6GJ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GKZL-6GJ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0212	John Laurence Dye	male	1 October 1687	\N	PL-6320	8 March 1751	\N	PL-6321	med	public	Paternal Reed	PWWX-6Z8	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PWWX-6Z8)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0040	Benjamin Reed	male	1789-12-24	\N	PL-0090	1872-05-04	\N	PL-0111	high	public	Paternal Reed	LZDK-YP8	Pioneer farmer; moved from Pennsylvania to Ohio; husband of Sarah Dickerson.	\N	Report	2026-05-30 09:21:56.321112-05	2026-05-30 13:24:50.942302-05
P-0039	Emily Thorla	female	1819-05-15	\N	PL-0085	1910-10-08	\N	PL-0101	high	public	Paternal Reed	LCTG-MKP	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 13:24:50.942302-05
P-0043	Mary Polly Cook	female	1735-08-08	\N	PL-0089	1800-04-04	\N	PL-0100	med	public	Paternal Reed	LZVP-5FW	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 13:24:50.942302-05
P-0046	Hannah Paulson	female	1793-08-11	\N	PL-0098	1857-09-30	\N	PL-0080	high	public	Paternal Reed	2MRH-9JF	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 13:24:50.942302-05
P-0048	Roxana Desire Barnard	female	1756-07-21	\N	PL-0114	1830-09-09	\N	PL-0109	med	public	Paternal Reed	L5ZT-BM5	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 13:24:50.942302-05
P-0049	William Polk Willey	male	1788-01-06	\N	PL-0097	1860-04-06	\N	PL-0105	med	public	Paternal Reed	LHW8-G58	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 13:24:50.942302-05
P-0050	Sarah Dye	female	1789-05-27	\N	PL-0085	1840-08-16	\N	PL-0105	med	public	Paternal Reed	278F-M4D	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 13:24:50.942302-05
P-0051	Benjamin Thorla	male	1790-09-14	\N	PL-0099	1861-07-05	\N	PL-0082	med	public	Paternal Reed	KLYD-X1Q	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 13:24:50.942302-05
P-0047	Samuel R Barnard	male	1749-03-09	\N	PL-0108	1815-08-08	\N	PL-0084	med	public	Paternal Reed	LHFS-KPJ	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 13:24:50.942302-05
P-0052	Elizabeth Allen	female	1794-07-05	\N	PL-0096	1872-04-12	\N	PL-0082	med	public	Paternal Reed	2S2L-ZYQ	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 13:24:50.942302-05
P-0038	James Willey	male	1818-03-10	\N	PL-0085	1896-07-10	\N	PL-0082	high	public	Paternal Reed	LCTG-MNQ	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 13:24:50.942302-05
P-0044	Else Alice Bonham	female	1762	\N	PL-0090	1819	\N	PL-0087	low	public	Paternal Reed	LCJK-F8G	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 13:24:50.942302-05
P-0045	John Foulk Talley	male	1799-10-26	\N	PL-0081	1886-11-04	\N	PL-0112	high	public	Paternal Reed	L7NJ-1S1	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 13:24:50.942302-05
P-0041	Sarah Dickerson	female	1794-10-11	\N	PL-0113	1858-01-24	\N	PL-0110	low	public	Paternal Reed	991N-J11	Matriarch of Reed line in Ohio.	\N	Report	2026-05-30 09:21:56.321112-05	2026-05-30 13:24:50.942302-05
P-0232	Sarah Talley	female	9 February 1736	\N	PL-0081	6 September 1822	\N	PL-0098	high	public	Paternal Reed	L7NJ-FCV	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L7NJ-FCV)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0243	Simon Poulson Sr	male	about 1690	\N	PL-8318	\N	\N	PL-7483	med	public	Paternal Reed	2MRH-LLN	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 2MRH-LLN)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0244	Mrs. Simon Poulson	female	about 1695	\N	PL-7483	\N	\N	\N	high	public	Paternal Reed	41RC-XBL	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 41RC-XBL)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0249	Thomas Talley	male	about 1689	\N	PL-2371	1781	\N	PL-2371	high	public	Paternal Reed	LH7D-M4Q	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LH7D-M4Q)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0082	Bonum Reed	male	1816-06-03	\N	PL-0610	1893-12-13	\N	PL-0196	high	public	Paternal Reed	27XF-VBH	Farmer; moved from Ohio to Iowa by 1870; buried at Monteith Cemetery.	\N	FamilySearch (FS PID: 27XF-VBH)	2026-05-30 09:21:56.321112-05	2026-05-30 13:31:43.421889-05
P-0091	François Pouliot	male	1805-05-20	\N	PL-0506	1858-06-13	\N	PL-0506	high	public	Pouliot	KCTF-J6N	Farmer at Île d’Orléans; father of Paul.	\N	FamilySearch (FS PID: KCTF-J6N)	2026-05-30 09:21:56.321112-05	2026-05-30 13:31:43.421889-05
P-0093	Joseph Filiatrault dit St. Louis	male	circa 1820	\N	\N	\N	\N	\N	med	public	Pouliot	GYV7-TRD	Father of Henriette (Filiatrault) Pouliot; Quebec farmer.	\N	FamilySearch (FS PID: GYV7-TRD)	2026-05-30 09:21:56.321112-05	2026-05-30 13:31:43.421889-05
P-0261	Bengt Paulson	male	1657	\N	PL-9772	9 September 1728	\N	PL-8468	high	public	Paternal Reed	LHC7-YXX	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LHC7-YXX)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0275	Phineas Allen	male	24 July 1731	\N	PL-11078	21 December 1776	\N	PL-11079	high	public	Paternal Reed	LCXK-MX4	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LCXK-MX4)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0070	John Talley Reed	male	1841-06-26	\N	PL-0327	1903-11-11	\N	PL-0328	high	public	Paternal Reed	L487-WDC	Farmer in Valley Township; married Elizabeth Willey (1861) then Mary E. Headlee (~1881).\n[deep-dive 2026-05-30] Second marriage to Mary E. Headlee (~1881) remains uncorroborated by open records as of this dive; no person row or source yet.	\N	FamilySearch (FS PID: L487-WDC); Guthrie Co. IA WPA cemetery survey (letter R) confirms b.1841, d.11 Nov 1903, buried Monteith Cemetery, s/o Bonam, h/o Elizabeth	2026-05-30 09:21:56.321112-05	2026-05-30 13:43:52.513478-05
P-0285	Timothy Allen	male	22 February 1691	\N	PL-12110	10 May 1755	\N	PL-2841	high	public	Paternal Reed	94QS-95F	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 94QS-95F)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0303	Samuel Allen III	male	4 December 1660	\N	PL-12110	28 June 1750	\N	PL-12110	high	public	Paternal Reed	LTTF-WCP	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LTTF-WCP)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0313	François Pouliot	male	27 February 1708	\N	PL-4471	29 March 1785	\N	PL-0506	high	public	Pouliot	L4QP-LDQ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L4QP-LDQ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0062	Earl Wayne Reed Sr	male	1899-07-19	\N	PL-0208	1974-04-07	\N	PL-166025	high	public	Paternal Reed	M3P5-XF6	Married Isabelle Zika; lived in Chicago; possible WWI/WWII service.\n[deep-dive 2026-05-30] Carpenter by trade. Died 7 Apr 1974 at Elk Grove Village (Cook Co), IL; buried 11 Apr 1974 at Lakewood Memorial Park, Elgin (Martin Funeral Home). Last residence 4N711 Medinah Rd, Addison, DuPage Co. Migration: Guthrie Co IA (1899-1900) -> WWI draft Waukesha WI (1918) -> Cicero IL (1930, 1940) -> Chicago (1950) -> Addison/DuPage (by 1974). NOT his mother's only child — see [[P-0036]] (4 Reed children + 1 Eichinger half-sib).	\N	FamilySearch (FS PID: M3P5-XF6); FS attached records (16) inspected via authenticated Chrome MCP 2026-05-30: Iowa birth, 1900/1930/1940/1950 census, WWI (Waukesha WI) & WWII draft, two Cook Co birth certs (sons), NUMIDENT, Cook Co death cert (Q2MN-CML4), FindAGrave (QV2L-ZBPS).	2026-05-30 09:21:56.321112-05	2026-05-30 15:42:11.880293-05
P-0321	Jean Pouliot	male	20 December 1674	\N	PL-16347	1 June 1745	\N	PL-4471	high	public	Pouliot	9WB4-TJK	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 9WB4-TJK)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0337	Charles Pouliot	male	about April 1628	\N	PL-18465	about 6 August 1699	\N	PL-4471	high	public	Pouliot	LRS7-9X7	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRS7-9X7)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0843	Permelia (Oak) Lambert	female	circa 1768	circa	\N	16 January 1845	day	\N	med	public	Maternal Lambert	\N	Wife of Sherebiah Lambert Jr (P-0105). Identified from the shared grave marker ("PAMELIA, his wife / Died Jan. 16, 1845 / AE. 77") and P-0105's note that he "married Permelia Oak". Maiden surname Oak per that note - needs FamilySearch confirmation. Age 77 at 1845 death implies birth c. 1767-1768.	\N	\N	2026-05-30 16:02:41.376154-05	2026-05-30 16:02:41.376154-05
P-0138	Sherebiah Lambert Sr.	male	28 March 1728	\N	PL-3115	\N	\N	\N	high	public	Maternal Lambert	L7NQ-CKX	Patriot era; married Lydia (Hopkins?). [DQ 2026-05-30: removed death_date "1 May 1833" + death_place (Canaan, ME); those belong to his son Sherebiah Jr (P-0105) per the grave marker (AE 74). Sr true death date/place unknown - see research_lead.]	\N	FamilySearch (FS PID: L7NQ-CKX)	2026-05-30 09:21:56.321112-05	2026-05-30 16:02:41.376154-05
P-0369	Sergeant Joseph Barnard	male	20 June 1681	\N	PL-23227	12 July 1736	\N	PL-3186	high	public	Paternal Reed	G7GV-Q4N	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G7GV-Q4N)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0784	Pierre Burlon	male	\N	\N	\N	\N	\N	\N	high	public	Pouliot	98BW-MZZ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 98BW-MZZ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0387	Francis Barnard	male	about 1624	\N	PL-26169	3 February 1698	\N	PL-26170	high	public	Paternal Reed	2S4G-PGP	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 2S4G-PGP)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0418	Jeanne Pouliot	female	7 October 1678	\N	PL-16347	about January 1759	\N	PL-16476	high	public	Pouliot	LWV2-3FZ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LWV2-3FZ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0785	Jeanne Danet	female	\N	\N	\N	\N	\N	\N	high	public	Pouliot	98BW-MZ8	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 98BW-MZ8)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0453	PASQUINO NICCOLAI	male	19 July 1718	\N	PL-1230	9 September 1798	\N	PL-38717	high	public	Maternal Mariotti	PM4B-L5J	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PM4B-L5J)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0457	FRANCESCO NICCOLAI	male	27 February 1691	\N	PL-2171	\N	\N	\N	high	public	Maternal Mariotti	PM4B-XGN	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PM4B-XGN)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0461	PASQUINO NICCOLAI	male	18 March 1657	\N	PL-2171	\N	\N	\N	med	public	Maternal Mariotti	PM4B-6L4	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PM4B-6L4)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0474	Nicholas Bonham	male	30 June 1630	\N	PL-43109	20 July 1684	\N	PL-5470	high	public	Paternal Reed	MM4L-JLD	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MM4L-JLD)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0484	William Ambrose Dickerson	male	12 August 1623	\N	PL-45339	1662	\N	PL-5630	high	public	Paternal Reed	27SD-FR4	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 27SD-FR4)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0512	William Talley	male	1660	\N	PL-52058	about 1700	\N	PL-7349	high	public	Paternal Reed	LVP9-SGG	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVP9-SGG)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0589	Andrew Allen	male	21 March 1613	\N	PL-73542	24 October 1690	\N	PL-73543	med	public	Paternal Reed	LRQ4-5P4	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRQ4-5P4)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0588	Mrs. Uknown Morgan	female	\N	\N	\N	\N	\N	\N	med	public	Paternal Reed	P6QZ-H38	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P6QZ-H38)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0606	Johan Pouliot	male	\N	\N	PL-22281	\N	\N	PL-166022	high	public	Pouliot	LWV2-QR5	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LWV2-QR5)	2026-05-30 13:23:14.722755-05	2026-05-30 13:24:50.775708-05
P-0645	Barbe Cochois	female	about 1618	\N	\N	\N	\N	\N	high	public	Pouliot	LDMY-1B7	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LDMY-1B7)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0697	FRANCESCO NICCOLAI	male	1 September 1616	\N	PL-2171	11 August 1687	\N	PL-2171	med	public	Maternal Mariotti	GYT2-Q63	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GYT2-Q63)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0699	Domenico Mariotti	male	10 September 1617	\N	PL-1230	\N	\N	\N	med	public	Maternal Mariotti	PHWR-ZC6	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PHWR-ZC6)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0830	PASQUINO NICCOLAI	male	1570	\N	PL-2171	29 April 1631	\N	PL-166021	med	public	Maternal Mariotti	GYT2-2ZH	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GYT2-2ZH)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0834	BASTIANO NICCOLAI	male	1545	\N	PL-1230	10 October 1619	\N	PL-38717	med	public	Maternal Mariotti	PM4B-675	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PM4B-675)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0838	Bartolomeo Niccolai	male	1520	\N	\N	\N	\N	\N	med	public	Maternal Mariotti	GYT2-F1T	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GYT2-F1T)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05
P-0170	Jemima Green	female	2 August 1742	\N	PL-5247	4 April 1800	\N	PL-5248	high	public	Paternal Reed	K2Q9-B41	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: K2Q9-B41)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0172	Martha Runyan	female	1735	\N	PL-5257	1771	\N	PL-5252	med	public	Paternal Reed	GPV5-LPL	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GPV5-LPL)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0174	Mary Ruth Adams	female	1723	\N	PL-5270	December 1807	\N	PL-5263	high	public	Paternal Reed	LC52-2T8	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LC52-2T8)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0176	Eliza Gunn	female	\N	\N	\N	\N	\N	\N	med	public	Paternal Reed	LVFW-SKJ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVFW-SKJ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0177	Joseph Green Sr	male	1698	\N	PL-5247	12 March 1784	\N	PL-5247	high	public	Paternal Reed	L89C-MQM	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L89C-MQM)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0178	Elizabeth Ann Mershon	female	22 June 1714	\N	PL-5299	12 March 1784	\N	PL-5300	high	public	Paternal Reed	LHWH-LMJ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LHWH-LMJ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0179	Hezekiah Bonham Jr. II	male	1701	\N	PL-5310	16 April 1763	\N	PL-5311	high	public	Paternal Reed	LC8B-QNB	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LC8B-QNB)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0180	Martha Runyon	female	June 1704	\N	PL-5248	1753	\N	PL-5248	high	public	Paternal Reed	LHZY-DBH	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LHZY-DBH)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0181	Vincent Runyon Sr.	male	4 April 1702	\N	PL-5248	27 October 1770	\N	PL-5248	high	public	Paternal Reed	LCSB-PC6	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LCSB-PC6)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0182	Alice Curtis	female	1704	\N	PL-5248	1742	\N	PL-5248	med	public	Paternal Reed	9VCV-ZVJ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 9VCV-ZVJ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0184	Sabrina Susannah Sarratt	female	1685	\N	PL-5371	1765	\N	PL-5372	med	public	Paternal Reed	P953-QT9	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P953-QT9)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0185	William Green	male	about 1670	\N	PL-5388	16 June 1722	\N	PL-5389	high	public	Paternal Reed	LZJW-1PW	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZJW-1PW)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0186	Joanna Reeder	female	13 June 1669	\N	PL-5407	after 12 September 1734	\N	PL-5252	high	public	Paternal Reed	L6C6-5ZF	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L6C6-5ZF)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0187	Henry Mershon II	male	10 October 1672	\N	PL-5426	20 September 1738	\N	PL-5248	high	public	Paternal Reed	M576-6ZZ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: M576-6ZZ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0188	Hannah Haughton	female	1 January 1679	\N	PL-5446	20 October 1738	\N	PL-5447	high	public	Paternal Reed	LCVZ-VBH	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LCVZ-VBH)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0190	Ann Hunt	female	1680	\N	PL-5494	\N	\N	PL-5494	high	public	Paternal Reed	LL97-K91	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LL97-K91)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0191	Thomas Runyan	male	about 1673	\N	PL-5470	before 16 April 1753	\N	PL-5519	high	public	Paternal Reed	LZZ3-XNG	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZZ3-XNG)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0192	Martha Dunn	female	13 July 1681	\N	PL-5470	after 16 April 1753	\N	PL-5248	high	public	Paternal Reed	LZLX-LY2	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZLX-LY2)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0193	Thomas Curtis	male	7 September 1659	\N	PL-5570	May 1748	\N	PL-5571	high	public	Paternal Reed	LCTH-XG8	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LCTH-XG8)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0194	Elizabeth Ellis	female	3 February 1670	\N	PL-5599	1732	\N	PL-5600	high	public	Paternal Reed	KCHF-7GN	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KCHF-7GN)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0195	Thomas Dickerson Sr.	male	1657	\N	PL-5356	18 January 1724	\N	PL-5630	med	public	Paternal Reed	MKBD-SW7	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MKBD-SW7)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0196	Elizabeth Isabella Gambray	female	6 December 1646	\N	PL-5356	1713	\N	PL-5661	med	public	Paternal Reed	GWS9-1ND	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GWS9-1ND)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0197	Joseph Jacques Surratt	male	14 September 1662	\N	PL-5693	18 January 1715	\N	PL-5661	high	public	Paternal Reed	P953-M6F	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P953-M6F)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0198	Katherine Moreland Short	female	1665	\N	PL-5726	1717	\N	PL-5661	high	public	Paternal Reed	G1HB-F53	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G1HB-F53)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0200	Priscilla Margaret Polk	female	1711	\N	PL-5760	May 1759	\N	PL-5795	high	public	Paternal Reed	L83N-ZQJ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L83N-ZQJ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0201	Lt. James Knox Polk	male	17 May 1719	\N	PL-5831	April 1771	\N	PL-5832	med	public	Paternal Reed	LYMN-M4P	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LYMN-M4P)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0202	Mary Elizabeth Cottman	female	1723	\N	PL-5832	1744	\N	PL-5270	med	public	Paternal Reed	GNKY-W1K	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GNKY-W1K)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0204	Sarah J. Leach	female	1 January 1724	\N	PL-5948	31 October 1765	\N	PL-2713	high	public	Paternal Reed	LZNC-CZM	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZNC-CZM)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0205	Johann Esaias Lämlein	male	from 1712 to 1722	\N	PL-5989	about 26 August 1784	\N	PL-5990	high	public	Paternal Reed	G9XJ-HVK	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G9XJ-HVK)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0206	Catherine	female	1724	\N	PL-6033	1825	\N	\N	high	public	Paternal Reed	GH81-42P	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GH81-42P)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0208	Ephraim Polk	male	1671	\N	PL-6120	1739	\N	PL-6121	high	public	Paternal Reed	GNKY-7BR	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GNKY-7BR)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0209	Elizabeth Williams	female	29 May 1674	\N	PL-6167	24 March 1773	\N	PL-6168	high	public	Paternal Reed	LV64-MGL	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LV64-MGL)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0210	Benjamin Cottman III.	male	1696	\N	PL-6216	26 April 1767	\N	PL-6217	high	public	Paternal Reed	LYGX-BZ5	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LYGX-BZ5)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0211	Frances Brown	female	1700	\N	PL-6267	August 1796	\N	PL-6268	high	public	Paternal Reed	MZ2L-6KB	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MZ2L-6KB)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0213	Anna Moor	female	1687	\N	PL-6375	\N	\N	\N	med	public	Paternal Reed	PWY1-P89	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PWY1-P89)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0214	Friderich Lemlein	male	about 1685	\N	PL-6430	after 1734	\N	\N	high	public	Paternal Reed	G5MP-9Y8	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G5MP-9Y8)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0215	Maria Magdalena Waltz	female	about 1685	\N	PL-6486	\N	\N	\N	high	public	Paternal Reed	G58G-Z7Z	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G58G-Z7Z)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0216	Capt. Robert Bruce Pollock	male	before 1625	\N	PL-6543	5 June 1704	\N	PL-6544	high	public	Paternal Reed	LR2V-J76	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LR2V-J76)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0217	Magdalen Tasker	female	1634	\N	PL-6603	March 1726	\N	PL-5831	high	public	Paternal Reed	LBJN-L9R	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LBJN-L9R)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0218	Charles Williams	male	1653	\N	PL-6663	8 February 1737	\N	PL-5630	high	public	Paternal Reed	K2NK-VHL	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: K2NK-VHL)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0219	Mary Walston	female	1657	\N	PL-6121	10 September 1678	\N	PL-5831	high	public	Paternal Reed	G4FX-4S1	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G4FX-4S1)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0220	Benjamin Cottman II	male	29 March 1675	\N	PL-5831	27 February 1748	\N	PL-5831	high	public	Paternal Reed	LTCJ-1MS	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LTCJ-1MS)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0221	Elizabeth Hardy	female	25 November 1667	\N	PL-5760	1715	\N	PL-5760	high	public	Paternal Reed	LTCJ-BFB	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LTCJ-BFB)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0222	Mr. Brown	male	about 1675	\N	PL-6904	\N	\N	\N	med	public	Paternal Reed	KZC8-4KS	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KZC8-4KS)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0223	Mrs. Brown	female	about 1679	\N	PL-6904	\N	\N	\N	med	public	Paternal Reed	K864-KBW	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: K864-KBW)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0224	Hans Lauretzen Duyts	male	23 September 1644	\N	PL-7027	1708	\N	PL-7028	med	public	Paternal Reed	P637-KJG	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P637-KJG)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0225	Sarah Hance Vincent-Fountaine	female	28 February 1662	\N	PL-7092	1740	\N	PL-6320	med	public	Paternal Reed	P63Q-GWM	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P63Q-GWM)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0226	William Moor	male	\N	\N	\N	\N	\N	\N	med	public	Paternal Reed	PC23-6D1	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PC23-6D1)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0227	Annetje Jans	female	\N	\N	\N	\N	\N	\N	med	public	Paternal Reed	PC23-C9X	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PC23-C9X)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0228	Lämmlein	male	\N	\N	\N	\N	\N	\N	med	public	Paternal Reed	G5NK-N9N	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G5NK-N9N)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0229	William Talley Jr.	male	27 January 1747	\N	PL-7349	9 May 1812	\N	PL-7350	high	public	Paternal Reed	26KN-HXJ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 26KN-HXJ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0230	Dinah Stille	female	27 February 1751	\N	PL-2219	9 May 1812	\N	PL-2219	high	public	Paternal Reed	26KN-HV3	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 26KN-HV3)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0231	John Foulk	male	22 April 1735	\N	PL-7483	8 November 1820	\N	PL-0098	high	public	Paternal Reed	L7NJ-F7S	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L7NJ-F7S)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0233	Simon Poulson Jr.	male	about 1724	\N	PL-2218	about 1764	\N	PL-0081	high	public	Paternal Reed	KLC9-LP9	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KLC9-LP9)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0234	Eleanor West	female	29 March 1721	\N	PL-7685	29 April 1790	\N	PL-0098	high	public	Paternal Reed	LT9F-VVQ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LT9F-VVQ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0235	George Patton	male	about 1731	\N	PL-7483	\N	\N	\N	high	public	Paternal Reed	KLVC-1JH	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KLVC-1JH)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0236	Maria Sinnexon	female	5 October 1733	\N	PL-7483	\N	\N	\N	high	public	Paternal Reed	KGQ1-9RF	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KGQ1-9RF)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0237	Pvt. - MD William Talley Sr.	male	January 1714	\N	PL-0081	17 August 1790	\N	PL-7890	high	public	Paternal Reed	K26G-SJP	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: K26G-SJP)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0238	Hannah Grubb	female	1717	\N	PL-7350	1747	\N	PL-7350	high	public	Paternal Reed	GZVK-3YJ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GZVK-3YJ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0239	Jonathan Stille	male	1709	\N	PL-8029	21 April 1765	\N	PL-0081	high	public	Paternal Reed	LZD4-GHS	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZD4-GHS)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0240	Maria Magdalena Vandever	female	5 November 1718	\N	PL-2219	21 April 1765	\N	PL-2219	high	public	Paternal Reed	2HMS-F2N	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 2HMS-F2N)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0241	Stephen Foulk	male	1704	\N	PL-8170	before 16 August 1787	\N	PL-8171	high	public	Paternal Reed	LXQV-JGS	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LXQV-JGS)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0242	Esther Willis	female	1708	\N	PL-8244	1786	\N	PL-8171	high	public	Paternal Reed	L69N-KXQ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L69N-KXQ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0245	Thomas West	male	about 1689	\N	PL-8467	about 1743	\N	PL-8468	high	public	Paternal Reed	LS6W-Z5H	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LS6W-Z5H)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0246	Mary 'Jenny' Deane	female	about 1682	\N	PL-8545	about 1738	\N	PL-8468	high	public	Paternal Reed	LKGD-4G7	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LKGD-4G7)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0247	Brewer Sinnexson	male	about 1703	\N	PL-2218	March 1756	\N	PL-8623	high	public	Paternal Reed	LHQ3-XSN	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LHQ3-XSN)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0248	Brita Hendrickson	female	1705	\N	PL-8029	27 March 1755	\N	PL-0098	high	public	Paternal Reed	L41T-MWV	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L41T-MWV)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0250	Elenger Johnson	female	1691	\N	PL-7483	1732	\N	PL-0081	med	public	Paternal Reed	LH7D-M8W	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LH7D-M8W)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0251	Joseph Grubb	male	11 November 1685	\N	PL-8936	14 March 1747	\N	PL-8937	high	public	Paternal Reed	L5V7-JFK	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L5V7-JFK)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0252	Elizabeth Perkins	female	1685	\N	PL-7349	14 March 1746	\N	PL-2218	high	public	Paternal Reed	MFWS-62F	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MFWS-62F)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0253	Jacob Anderson Stille Sr	male	1680	\N	PL-9098	6 February 1774	\N	PL-8029	high	public	Paternal Reed	LBSF-V5X	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LBSF-V5X)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0254	Rebecca Charlesdotter Springer	female	1 June 1689	\N	PL-8029	10 October 1764	\N	PL-9180	high	public	Paternal Reed	L437-PH3	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L437-PH3)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0255	Jacob Corneliusson Vandever	male	1682	\N	PL-7349	16 November 1739	\N	PL-7349	high	public	Paternal Reed	LZX4-Z76	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZX4-Z76)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0256	Maria Stedham	female	1693	\N	PL-2218	24 November 1764	\N	PL-2218	high	public	Paternal Reed	LTHX-N76	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LTHX-N76)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0257	William Foulk	male	about 1680	\N	PL-8171	1720	\N	PL-9427	high	public	Paternal Reed	LHDG-FY2	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LHDG-FY2)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0258	Elizabeth Cope	female	about 1680	\N	PL-9511	23 January 1765	\N	PL-9427	high	public	Paternal Reed	GQYG-K92	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GQYG-K92)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0259	John Willis I	male	6 March 1669	\N	PL-9596	1745	\N	PL-9597	high	public	Paternal Reed	L6MV-B1L	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L6MV-B1L)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0260	Esther Brinton	female	9 October 1675	\N	PL-9684	1715	\N	PL-8170	high	public	Paternal Reed	L8M3-DPD	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L8M3-DPD)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0262	Margareta Johansson	female	9 September 1658	\N	PL-2371	September 1728	\N	PL-2371	high	public	Paternal Reed	LJB3-5Y4	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LJB3-5Y4)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0263	Major Thomas William West	male	about 1643	\N	PL-9949	1735	\N	PL-9949	high	public	Paternal Reed	MPYS-5C2	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MPYS-5C2)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0264	Rachel Gilpin	female	14 April 1660	\N	PL-10039	12 December 1700	\N	PL-10040	high	public	Paternal Reed	9KZY-SL1	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 9KZY-SL1)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0265	John Deane Alscollins	male	about 1632	\N	PL-10132	about 1693	\N	PL-8545	high	public	Paternal Reed	21RR-LSH	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 21RR-LSH)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0266	Ellinor Wilson	female	14 December 1654	\N	PL-5388	9 November 1694	\N	PL-8545	high	public	Paternal Reed	MYB3-ST8	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MYB3-ST8)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0267	James Sinnexon	male	1669	\N	PL-2219	1773	\N	PL-2219	high	public	Paternal Reed	LVYM-N9X	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVYM-N9X)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0268	Dorcas Harmensen	female	1674	\N	PL-2219	13 November 1723	\N	PL-2219	high	public	Paternal Reed	LVYM-JQG	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVYM-JQG)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0269	Johan "John" Hendrickson	male	1663	\N	PL-7483	7 November 1745	\N	PL-2218	high	public	Paternal Reed	9KFZ-S4B	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 9KFZ-S4B)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0270	Brigitta Mattson	female	1674	\N	PL-10593	11 June 1750	\N	PL-9098	high	public	Paternal Reed	G9FQ-SBX	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G9FQ-SBX)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0133	John Thomas Thurlow Jr	male	26 September 1745	\N	PL-2776	22 September 1835	\N	PL-2777	high	public	Paternal Reed	24C5-JCJ	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: 24C5-JCJ)	2026-05-30 09:21:56.321112-05	2026-05-30 13:23:45.452511-05
P-0131	Deliverance Owen	female	13 August 1754	\N	PL-2653	1821	\N	PL-0638	high	public	Paternal Reed	2CND-ZJ7	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: 2CND-ZJ7)	2026-05-30 09:21:56.321112-05	2026-05-30 13:23:45.452511-05
P-0271	John Thurlow Sr	male	5 October 1726	\N	PL-10687	after 1790	\N	PL-10688	high	public	Paternal Reed	LCMC-J5V	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LCMC-J5V)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0272	Ruth Stevens	female	20 February 1724	\N	PL-10784	1764	\N	PL-10688	high	public	Paternal Reed	MN82-GKV	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MN82-GKV)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0273	William Owen	male	1733	\N	PL-10687	29 June 1804	\N	PL-10881	med	public	Paternal Reed	PMGG-6X8	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PMGG-6X8)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0274	Elizabeth Davis	female	1738	\N	\N	3 May 1819	\N	PL-10979	med	public	Paternal Reed	LYP7-2BX	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LYP7-2BX)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0276	Elizabeth Sargent	female	5 February 1734	\N	PL-2841	28 December 1776	\N	PL-11180	high	public	Paternal Reed	MGKK-MV1	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MGKK-MV1)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0277	Joshua Palmer	male	14 April 1731	\N	PL-11282	November 1758	\N	PL-2841	high	public	Paternal Reed	KLYC-GFM	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KLYC-GFM)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0278	Ruth Sargeant	female	14 October 1732	\N	PL-2841	29 August 1808	\N	PL-11180	high	public	Paternal Reed	KG8Z-TC9	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KG8Z-TC9)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0279	Thomas Thurlo	male	11 December 1701	\N	PL-2776	28 October 1789	\N	PL-10687	high	public	Paternal Reed	LJLB-GM4	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LJLB-GM4)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0280	Joanna Pike	female	17 December 1700	\N	PL-2776	21 December 1759	\N	PL-10687	high	public	Paternal Reed	PZHH-861	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PZHH-861)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0281	John Stevens Jr.	male	22 March 1674	\N	PL-2776	8 November 1728	\N	PL-11691	high	public	Paternal Reed	L5XW-3KG	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L5XW-3KG)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0282	Mary Bartlett	female	17 April 1682	\N	PL-2776	February 1725	\N	PL-10687	high	public	Paternal Reed	L1PQ-KP7	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L1PQ-KP7)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0283	Robert Henry Owens	male	1693	\N	PL-11898	10 March 1750	\N	PL-11899	med	public	Paternal Reed	PMGP-VXC	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PMGP-VXC)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0284	Patience Clifton	female	about 1700	\N	\N	before 29 December 1759	\N	PL-11899	high	public	Paternal Reed	L414-DDK	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L414-DDK)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0286	Rachel Bushnell	female	27 October 1692	\N	PL-11078	23 September 1774	\N	PL-2841	high	public	Paternal Reed	LCCY-PKB	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LCCY-PKB)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0287	Isaac Sargeant	male	24 February 1699	\N	PL-12323	20 April 1742	\N	PL-2841	high	public	Paternal Reed	LC53-ZCB	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LC53-ZCB)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0288	Anna Wood	female	11 April 1700	\N	PL-12431	30 July 1792	\N	PL-11180	high	public	Paternal Reed	LZ6Y-SJV	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZ6Y-SJV)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0289	Stephen Palmer	male	1 May 1709	\N	PL-12540	30 October 1775	\N	PL-12541	high	public	Paternal Reed	KPWT-YYX	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KPWT-YYX)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0290	Elizabeth Quimby	female	1707	\N	PL-12652	18 October 1776	\N	PL-11282	high	public	Paternal Reed	KPWT-YRD	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KPWT-YRD)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0291	George Thurlo	male	12 March 1671	\N	PL-12764	17 January 1713	\N	PL-12764	high	public	Paternal Reed	LBRX-ZQS	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LBRX-ZQS)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0292	Mary Adams	female	16 January 1672	\N	PL-2776	17 January 1714	\N	PL-2776	high	public	Paternal Reed	L5ZC-FL8	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L5ZC-FL8)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0293	John Pike	male	28 December 1671	\N	PL-2776	13 August 1752	\N	PL-2776	high	public	Paternal Reed	L4HS-H16	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L4HS-H16)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0294	Lydia Coffin	female	22 April 1662	\N	PL-2776	25 March 1719	\N	PL-2776	high	public	Paternal Reed	LDLP-BCZ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LDLP-BCZ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0295	John Stevens Sr	male	19 November 1650	\N	PL-13213	6 April 1725	\N	PL-13214	high	public	Paternal Reed	LYB4-9D7	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LYB4-9D7)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0296	Mary Chase	female	3 February 1650	\N	PL-12764	6 April 1725	\N	PL-12764	high	public	Paternal Reed	LYB4-QFV	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LYB4-QFV)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0297	Christopher Bartlett II	male	11 June 1655	\N	PL-2776	14 April 1711	\N	PL-12652	high	public	Paternal Reed	LKTJ-ZMV	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LKTJ-ZMV)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0298	Deborah Weed	female	15 June 1659	\N	PL-13557	6 June 1726	\N	PL-12652	high	public	Paternal Reed	LYJF-YHT	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LYJF-YHT)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0299	Robert Owens	male	\N	\N	\N	\N	\N	\N	med	public	Paternal Reed	GVD6-NC3	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GVD6-NC3)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0300	Ann Lecompte	female	1675	\N	PL-13788	26 October 1767	\N	PL-13788	med	public	Paternal Reed	GVD6-ZD3	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GVD6-ZD3)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0301	Jonathan Clifton	male	1684	\N	PL-13905	February 1732	\N	PL-13788	high	public	Paternal Reed	PMG5-KP6	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PMG5-KP6)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0302	Mary Woodgate	female	August 1676	\N	PL-14023	1770	\N	PL-11898	high	public	Paternal Reed	LJ5V-V3J	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LJ5V-V3J)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0304	Rebecca Cary	female	30 March 1665	\N	PL-12110	29 October 1697	\N	PL-12110	high	public	Paternal Reed	LHR8-N3T	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LHR8-N3T)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0305	Joseph Bushnell	male	2 May 1651	\N	PL-14378	23 December 1746	\N	PL-11078	high	public	Paternal Reed	LZ4J-XY3	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZ4J-XY3)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0306	Mary Leffingwell	female	10 December 1654	\N	PL-14378	31 March 1745	\N	PL-11078	high	public	Paternal Reed	MM2G-NS6	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MM2G-NS6)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0307	John Sargeant II	male	10 February 1664	\N	PL-14617	16 April 1755	\N	PL-14618	high	public	Paternal Reed	L6NB-QQM	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L6NB-QQM)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0308	Mary Linnell	female	15 December 1666	\N	PL-12323	16 April 1755	\N	PL-2841	high	public	Paternal Reed	LXSD-FMZ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LXSD-FMZ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0309	Thomas Wood II	male	10 August 1658	\N	PL-2653	1 December 1702	\N	PL-2653	high	public	Paternal Reed	LR5W-6ZV	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LR5W-6ZV)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0310	Mary Hunt	female	28 September 1664	\N	PL-14982	7 November 1754	\N	PL-2841	high	public	Paternal Reed	FYWM-4VF	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: FYWM-4VF)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0311	Nehemiah Palmer Jr	male	8 July 1677	\N	PL-12540	1735	\N	PL-15105	high	public	Paternal Reed	L4BH-JD9	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L4BH-JD9)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0312	Jerusha Saxton	female	1683	\N	PL-12540	1751	\N	PL-12541	high	public	Paternal Reed	LZFX-CPJ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZFX-CPJ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0314	Marie Madeleine Chabot	female	15 January 1719	\N	PL-4471	23 April 1767	\N	PL-4471	high	public	Pouliot	LZVT-5T3	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZVT-5T3)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0315	Antoine Godebout	male	15 January 1722	\N	PL-0506	24 November 1797	\N	PL-0506	high	public	Pouliot	LC7N-PYN	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LC7N-PYN)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0316	Marie Anne Leclerc	female	1727	\N	PL-0506	23 March 1812	\N	PL-0506	high	public	Pouliot	LC7N-PYJ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LC7N-PYJ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0317	Jacque Denis	male	\N	\N	\N	16 April 1758	\N	PL-0506	high	public	Pouliot	L8PT-Y8W	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L8PT-Y8W)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0318	Véronique Mathieu	female	18 January 1704	\N	PL-15967	29 July 1759	\N	PL-0506	high	public	Pouliot	LHKW-3LD	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LHKW-3LD)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0319	Pierre Cinq-Mars dit Gobelin	male	22 April 1698	\N	PL-1001	22 October 1775	\N	PL-16092	high	public	Pouliot	LH35-2MF	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LH35-2MF)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0320	Genevieve Belanger	female	31 December 1709	\N	PL-16218	28 January 1785	\N	PL-16219	high	public	Pouliot	L8PT-TY4	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L8PT-TY4)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0322	Magdelaine Odet	female	18 September 1677	\N	PL-16476	8 November 1761	\N	PL-4471	high	public	Pouliot	LT94-67F	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LT94-67F)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0323	Jean Chabot	male	17 September 1693	\N	PL-0506	6 November 1755	\N	PL-0506	high	public	Pouliot	KHQ9-XVW	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KHQ9-XVW)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0324	Marie Madelaine Dufresne	female	17 June 1694	\N	PL-0506	10 October 1736	\N	PL-0506	high	public	Pouliot	LZVT-5SJ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZVT-5SJ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0325	Antoine Godebout	male	27 August 1693	\N	PL-4471	15 September 1749	\N	PL-4471	high	public	Pouliot	M8B2-8NV	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: M8B2-8NV)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0326	Genevieve Rouleau	female	21 November 1696	\N	PL-4471	17 December 1776	\N	PL-0506	high	public	Pouliot	27C9-VD9	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 27C9-VD9)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0327	Jean Le Clerc	male	about April 1694	\N	PL-17122	9 June 1772	\N	PL-17123	high	public	Pouliot	MJFB-GQW	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MJFB-GQW)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0328	Marie Madeleine Gosselin	female	22 May 1700	\N	PL-4471	5 April 1750	\N	PL-4471	high	public	Pouliot	LZFD-HBW	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZFD-HBW)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0329	Pierre Denys	male	10 April 1662	\N	PL-17386	18 September 1727	\N	PL-4471	high	public	Pouliot	LV7V-ZX9	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LV7V-ZX9)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0330	Marie Godin	female	27 April 1662	\N	PL-17519	about October 1733	\N	PL-4471	high	public	Pouliot	LTN2-G8G	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LTN2-G8G)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0331	Rene Mathieu	male	13 June 1674	\N	PL-17519	16 October 1730	\N	PL-17653	high	public	Pouliot	LHDT-9X4	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LHDT-9X4)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0332	Genevieve Roussin	female	19 February 1681	\N	PL-15967	21 March 1767	\N	PL-17653	high	public	Pouliot	L8PT-YFM	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L8PT-YFM)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0333	Marc Antoine Cinq-Mars dit Gobelin	male	1641	\N	PL-17922	12 October 1699	\N	PL-0506	high	public	Pouliot	ML69-RLT	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: ML69-RLT)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0334	Francoise Chapelain	female	3 January 1673	\N	PL-16347	6 November 1741	\N	PL-4805	high	public	Pouliot	L8PT-B83	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L8PT-B83)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0335	Charles Bélanger	male	3 July 1668	\N	PL-16218	11 November 1747	\N	PL-15967	high	public	Pouliot	LVBN-5QW	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVBN-5QW)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0336	Geneviefve Gagnon	female	4 March 1674	\N	PL-18328	28 April 1749	\N	PL-17519	high	public	Pouliot	LK4H-84N	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LK4H-84N)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0338	Francoise Le Mosnier	female	13 September 1653	\N	PL-18603	18 January 1703	\N	PL-4471	high	public	Pouliot	L17K-D6M	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L17K-D6M)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0339	Nicollas Audet	male	about July 1637	\N	PL-18742	9 December 1700	\N	PL-16476	high	public	Pouliot	LTF4-G5B	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LTF4-G5B)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0340	Magdeleine Després	female	2 August 1656	\N	PL-18882	18 December 1712	\N	PL-16476	high	public	Pouliot	LTF4-PNJ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LTF4-PNJ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0341	Jean Chabot	male	2 November 1667	\N	PL-19023	14 September 1727	\N	PL-19024	high	public	Pouliot	LZL1-9H1	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZL1-9H1)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0342	Eléonore Enaud	female	5 March 1673	\N	PL-19023	21 May 1746	\N	PL-0506	high	public	Pouliot	LZ2X-HZ5	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZ2X-HZ5)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0343	Pierre Dufresne	male	25 September 1669	\N	PL-16347	about 5 November 1740	\N	PL-4471	high	public	Pouliot	LCTK-JCB	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LCTK-JCB)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0344	Marie Madelaine Crespeau	female	1 December 1675	\N	\N	17 April 1748	\N	PL-4636	high	public	Pouliot	LRJ7-WGC	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRJ7-WGC)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0345	Antoine Godbout	male	16 November 1669	\N	PL-19593	April 1742	\N	PL-4471	high	public	Pouliot	LHJQ-F3D	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LHJQ-F3D)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0346	Marguerite Labrecque	female	about 1669	\N	PL-19737	19 October 1748	\N	PL-4471	high	public	Pouliot	LH5T-8SK	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LH5T-8SK)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0347	Guillaume Rouleau	male	27 April 1662	\N	PL-19882	6 March 1703	\N	PL-19024	high	public	Pouliot	PS2Y-M8D	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PS2Y-M8D)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0348	Catherine Dufresne	female	7 February 1668	\N	PL-16347	14 January 1711	\N	PL-4471	high	public	Pouliot	L6NK-LCZ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L6NK-LCZ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0349	Pierre Le Clerc	male	about January 1659	\N	PL-20173	25 January 1736	\N	PL-4471	high	public	Pouliot	LC7N-PNK	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LC7N-PNK)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0350	Elisabeth Rondeau	female	19 October 1670	\N	PL-16347	7 November 1746	\N	PL-4471	high	public	Pouliot	LJJC-CZ4	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LJJC-CZ4)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0351	Ignace Gosselin	male	13 February 1654	\N	PL-4636	10 April 1727	\N	PL-4471	high	public	Pouliot	LCRL-SSC	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LCRL-SSC)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0352	Marie Anne Raté	female	13 February 1665	\N	PL-20612	25 May 1729	\N	PL-4471	high	public	Pouliot	L1C5-DLC	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L1C5-DLC)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0353	Blaise Denys	male	1630	\N	PL-17386	1687	\N	\N	high	public	Pouliot	LV7V-ZBL	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LV7V-ZBL)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0354	Jeanne la Ponche	female	\N	\N	PL-20907	before 8 October 1687	\N	\N	high	public	Pouliot	LV7V-8MT	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LV7V-8MT)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0355	Charles Godin	male	about 1630	\N	PL-21056	after 1 December 1706	\N	PL-19737	high	public	Pouliot	LYXS-JG5	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LYXS-JG5)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0356	Marie Boucher	female	about April 1644	\N	PL-21206	about July 1730	\N	PL-15967	high	public	Pouliot	LY6R-WLM	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LY6R-WLM)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0357	Jean Mathieu	male	about 1637	\N	PL-21357	29 April 1699	\N	PL-15967	high	public	Pouliot	LJ2N-6WN	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LJ2N-6WN)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0358	Anne LeTartre	female	about 27 December 1651	\N	PL-21509	12 April 1696	\N	PL-15967	high	public	Pouliot	LVJ1-YJQ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVJ1-YJQ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0359	Nicolas Roussin	male	about 10 March 1635	\N	PL-21662	6 March 1697	\N	PL-15967	high	public	Pouliot	LVCQ-W56	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVCQ-W56)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0360	Marie Magdelaine Tremblé	female	9 July 1658	\N	PL-21206	9 April 1736	\N	PL-15967	high	public	Pouliot	L26G-51P	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L26G-51P)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0361	Pierre Gobelin	male	1620	\N	PL-21969	\N	\N	PL-21970	med	public	Pouliot	2S22-JJD	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 2S22-JJD)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0362	Madeleine Labelle	female	1624	\N	PL-21969	\N	\N	PL-21970	med	public	Pouliot	2S22-JJY	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 2S22-JJY)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0363	Bernard Chaplain	male	about 1651	\N	PL-22281	25 November 1734	\N	PL-22282	high	public	Pouliot	LCXR-PJ8	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LCXR-PJ8)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0364	Leonore Mouillard	female	about 1659	\N	PL-22281	about 2 December 1739	\N	PL-22282	high	public	Pouliot	MZ4D-28Z	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MZ4D-28Z)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0365	Charles Belanger	male	about 19 August 1640	\N	PL-21206	14 December 1692	\N	PL-17519	high	public	Pouliot	LRTX-7LB	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRTX-7LB)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0366	Barbe Delphine Cloustier	female	about 11 January 1650	\N	PL-18603	24 April 1711	\N	PL-17519	high	public	Pouliot	LR39-654	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LR39-654)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0367	Pierre Gagnon	male	about 1646	\N	PL-21206	10 August 1687	\N	PL-18603	high	public	Pouliot	LVBN-TRS	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVBN-TRS)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0368	Barbe Fortin	female	21 October 1654	\N	PL-21206	26 August 1737	\N	PL-23068	high	public	Pouliot	L5Y9-PD8	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L5Y9-PD8)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0370	Abigail Griswold	female	3 August 1685	\N	PL-23387	5 June 1747	\N	PL-3186	high	public	Paternal Reed	LCFC-L7P	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LCFC-L7P)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0371	Nathaniel Pinney	male	18 August 1695	\N	PL-3186	before 7 October 1735	\N	PL-3186	high	public	Paternal Reed	LZ6X-P5C	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZ6X-P5C)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0372	Elizabeth Carrier	female	3 June 1695	\N	PL-11691	after 7 October 1735	\N	\N	high	public	Paternal Reed	L71T-M3G	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L71T-M3G)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0373	Hamphrey Nathaniel Pinney	male	5 September 1694	\N	PL-3186	after 1737	\N	PL-3186	high	public	Paternal Reed	L5ZR-5GK	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L5ZR-5GK)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0374	Abigail Deming	female	21 January 1700	\N	PL-24028	6 June 1773	\N	PL-3186	high	public	Paternal Reed	L5ZR-K54	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L5ZR-K54)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0375	Joseph Bernard	male	1 January 1652	\N	PL-24028	6 September 1695	\N	PL-23227	high	public	Paternal Reed	L457-H8Q	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L457-H8Q)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0376	Sarah Strong	female	4 March 1656	\N	PL-24351	10 February 1733	\N	PL-23227	high	public	Paternal Reed	L6R7-RBX	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L6R7-RBX)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0377	Edward Griswold	male	19 March 1661	\N	PL-3186	30 May 1688	\N	PL-23387	high	public	Paternal Reed	LZGX-YG7	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZGX-YG7)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0378	Abigail Williams	female	31 May 1658	\N	PL-3186	16 September 1690	\N	PL-23387	high	public	Paternal Reed	LHXN-W6M	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LHXN-W6M)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0379	Nathaniel Pinney II	male	11 May 1671	\N	PL-3186	1 January 1764	\N	PL-3186	high	public	Paternal Reed	LX7J-XWZ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LX7J-XWZ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0380	Martha Thrall	female	31 May 1673	\N	PL-3186	15 November 1715	\N	PL-25000	high	public	Paternal Reed	LX7J-XC7	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LX7J-XC7)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0381	Richard Carrier	male	19 July 1674	\N	PL-25164	16 November 1749	\N	PL-25165	high	public	Paternal Reed	L8BG-MPW	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L8BG-MPW)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0382	Elizabeth Sessions	female	4 April 1673	\N	PL-11691	6 March 1704	\N	PL-25331	high	public	Paternal Reed	LZ38-XL4	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZ38-XL4)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0383	Isaac Pinney	male	24 February 1663	\N	PL-3186	6 October 1709	\N	PL-3331	high	public	Paternal Reed	LX72-R52	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LX72-R52)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0384	Sarah Clark	female	7 August 1663	\N	PL-3186	25 May 1751	\N	PL-3186	high	public	Paternal Reed	LZPR-4HZ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZPR-4HZ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0385	Jacob Deming	male	26 August 1670	\N	PL-25830	23 January 1712	\N	PL-25830	high	public	Paternal Reed	DK3Q-319	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: DK3Q-319)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0386	Elizabeth Edwards	female	11 September 1674	\N	PL-25998	1709	\N	PL-25999	high	public	Paternal Reed	L588-R34	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L588-R34)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0388	Hannah Merrill	female	about 1628	\N	PL-26170	17 September 1675	\N	PL-23227	high	public	Paternal Reed	GDNX-91R	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GDNX-91R)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0389	John Strong	male	10 June 1605	\N	PL-26513	14 April 1699	\N	PL-26514	high	public	Paternal Reed	LHN6-VQW	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LHN6-VQW)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0390	Abigail Ford	female	about 8 October 1619	\N	PL-26688	6 July 1688	\N	PL-26514	high	public	Paternal Reed	971N-SXM	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 971N-SXM)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0391	George Griswold	male	19 May 1633	\N	PL-26863	3 September 1704	\N	PL-3186	high	public	Paternal Reed	9H7S-R2T	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 9H7S-R2T)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0392	Mary Holcombe	female	about 1636	\N	PL-27039	4 April 1708	\N	PL-3186	high	public	Paternal Reed	KNX6-H1Y	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KNX6-H1Y)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0393	John Williams	male	24 May 1618	\N	PL-27216	14 May 1712	\N	PL-3186	high	public	Paternal Reed	MZ6X-YTJ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MZ6X-YTJ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0394	Mary Burlly	female	1616	\N	\N	17 April 1681	\N	PL-3186	high	public	Paternal Reed	LYR4-Y2M	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LYR4-Y2M)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0395	Samuel Pinney I	male	30 March 1635	\N	PL-27039	1681	\N	PL-27571	high	public	Paternal Reed	LZV8-G2P	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZV8-G2P)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0396	Joyce Bissell	female	21 May 1641	\N	PL-24351	1689	\N	PL-3186	high	public	Paternal Reed	L6KP-5JN	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L6KP-5JN)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0397	Timothy Thrall	male	25 July 1641	\N	PL-3186	7 June 1697	\N	PL-3186	high	public	Paternal Reed	LV46-1PB	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LV46-1PB)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0398	Deborah Gunn	female	21 February 1641	\N	PL-3186	17 January 1694	\N	PL-3186	high	public	Paternal Reed	LYW5-13Z	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LYW5-13Z)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0399	Thomas Carrier	male	1626	\N	PL-28284	16 May 1735	\N	PL-28285	high	public	Paternal Reed	K2RQ-CTK	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: K2RQ-CTK)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0400	Martha Allen (Allin) Carrier	female	1643	\N	PL-28466	5 August 1692	\N	PL-28467	med	public	Paternal Reed	P6QZ-F5J	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P6QZ-F5J)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0401	Alexander Sessions	male	14 February 1645	\N	PL-28650	26 February 1689	\N	PL-11691	high	public	Paternal Reed	L83J-NVL	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L83J-NVL)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0402	Elizabeth Spofford	female	14 December 1646	\N	PL-2653	16 June 1747	\N	PL-11691	high	public	Paternal Reed	L48D-1DM	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L48D-1DM)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0403	Capt. Daniel Clark	male	before 8 June 1623	\N	PL-29017	12 August 1710	\N	PL-29018	high	public	Paternal Reed	L5RG-L91	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L5RG-L91)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0404	Mary Newberry	female	22 October 1626	\N	PL-29204	29 August 1688	\N	PL-3186	high	public	Paternal Reed	LZ5P-B9Z	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZ5P-B9Z)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0405	John Deming	male	9 September 1638	\N	PL-25830	23 January 1712	\N	PL-25830	high	public	Paternal Reed	LR68-817	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LR68-817)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0406	Mary Mygatt	female	4 December 1637	\N	PL-24028	4 September 1714	\N	PL-25830	high	public	Paternal Reed	LZYB-DM2	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZYB-DM2)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0407	Richard Edwards	male	1 May 1647	\N	PL-24028	20 April 1718	\N	PL-24028	high	public	Paternal Reed	LRJ6-72K	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRJ6-72K)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0408	Elizabeth Tuttle	female	about 1645	\N	PL-29949	September 1691	\N	\N	high	public	Paternal Reed	9XY5-DMR	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 9XY5-DMR)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0409	Joseph Audet-dit-Lapointe	male	24 February 1704	\N	PL-4720	16 December 1788	\N	PL-4635	high	public	Pouliot	G7Q5-44F	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G7Q5-44F)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0410	Marie Anne Therrien	female	16 January 1723	\N	PL-4635	27 December 1759	\N	PL-30324	high	public	Pouliot	LZX1-22C	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZX1-22C)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0411	Charles Delage	male	25 October 1698	\N	PL-4471	28 November 1749	\N	PL-16476	high	public	Pouliot	K8R9-DGV	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: K8R9-DGV)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0412	Marie Josephe Plante	female	about 1708	\N	PL-30701	10 August 1781	\N	PL-1000	high	public	Pouliot	LVNN-QC4	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVNN-QC4)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0413	Jacques Tremblay	male	30 August 1702	\N	PL-17653	18 August 1769	\N	PL-1000	high	public	Pouliot	LRS1-YC3	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRS1-YC3)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0414	Marie Angélique Quentin dit Cantin	female	8 March 1707	\N	PL-17653	17 November 1749	\N	PL-1000	high	public	Pouliot	LDSS-3FG	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LDSS-3FG)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0415	Gervais Pépin dit Lachance	male	30 October 1714	\N	PL-16476	21 June 1789	\N	PL-4635	high	public	Pouliot	LRD5-K2F	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRD5-K2F)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0416	Marie Angélique Blouin	female	10 February 1721	\N	PL-4805	20 March 1809	\N	PL-4635	high	public	Pouliot	L71K-1M4	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L71K-1M4)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0417	Nicolas Odet	male	1680	\N	PL-16476	before 17 March 1732	\N	PL-16476	high	public	Pouliot	G81J-4TG	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G81J-4TG)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0419	Barthélémy Terrien	male	10 March 1694	\N	PL-16476	5 March 1743	\N	PL-16476	high	public	Pouliot	L5P3-FJM	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L5P3-FJM)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0420	Marguerite Fontaine	female	28 February 1693	\N	PL-16476	4 May 1777	\N	PL-32214	high	public	Pouliot	LDMY-YDH	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LDMY-YDH)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0421	Charles Delage	male	19 April 1672	\N	PL-16347	19 July 1748	\N	PL-4471	high	public	Pouliot	LVN7-PGK	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVN7-PGK)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0422	Marie Anne Manseau	female	26 October 1675	\N	PL-21206	20 March 1703	\N	PL-4805	high	public	Pouliot	LZXX-VRT	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZXX-VRT)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0423	Georges Plante	male	26 August 1659	\N	PL-19737	17 February 1718	\N	PL-16476	high	public	Pouliot	LVN7-XST	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVN7-XST)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0424	Margueritte Crepeau	female	11 March 1669	\N	PL-16347	about 1745	\N	PL-16476	high	public	Pouliot	LTH9-5ZC	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LTH9-5ZC)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0425	Jacques Tremblay	male	18 June 1664	\N	PL-17519	28 March 1741	\N	PL-15967	high	public	Pouliot	LVC1-1ZX	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVC1-1ZX)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0426	Agathe Lacroix	female	13 January 1675	\N	PL-18603	23 April 1742	\N	PL-15967	high	public	Pouliot	LVZM-M94	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVZM-M94)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0427	Louis Quentin	male	27 December 1675	\N	PL-15967	\N	\N	PL-17653	high	public	Pouliot	L63T-L1S	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L63T-L1S)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0428	Marie Matthieu	female	23 December 1682	\N	PL-33735	15 July 1771	\N	PL-17653	high	public	Pouliot	L63T-L1P	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L63T-L1P)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0429	Jan Pepin	male	29 March 1664	\N	PL-17519	about 1734	\N	\N	high	public	Pouliot	LR33-SSZ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LR33-SSZ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0430	Madeleine Fontaine	female	2 June 1688	\N	PL-16476	5 August 1768	\N	PL-16476	high	public	Pouliot	LZKL-ZND	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZKL-ZND)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0431	Jacque Belouyn	male	2 April 1676	\N	PL-16347	15 January 1744	\N	PL-16476	high	public	Pouliot	LVN7-YMR	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVN7-YMR)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0432	Marie Geneviève Plante	female	21 January 1693	\N	PL-34500	October 1765	\N	PL-4635	high	public	Pouliot	LVN7-T1M	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVN7-T1M)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0433	Pierre Terrien	male	1 November 1640	\N	PL-34693	12 September 1706	\N	PL-21206	high	public	Pouliot	LRBF-PM3	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRBF-PM3)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0434	Gabrielle Minaud	female	about 1655	\N	PL-34887	25 November 1707	\N	PL-16476	high	public	Pouliot	L5D9-R4D	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L5D9-R4D)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0435	Estienne de Fontaine	male	about 24 February 1659	\N	PL-35082	about 22 May 1739	\N	PL-16476	high	public	Pouliot	L5NN-2QT	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L5NN-2QT)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0436	Marie Conil	female	about 27 September 1665	\N	PL-34693	about 1 July 1737	\N	PL-16476	high	public	Pouliot	LVJ1-ZM1	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVJ1-ZM1)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0437	Nicolas Delage	male	about 1637	\N	PL-35473	before 22 July 1686	\N	PL-19737	high	public	Pouliot	L871-PK9	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L871-PK9)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0438	Marie Petit	female	28 June 1637	\N	PL-35670	19 December 1708	\N	PL-4471	high	public	Pouliot	LY41-PL9	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LY41-PL9)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0439	Jacques Manseau	male	16 February 1633	\N	PL-35868	25 June 1711	\N	PL-4805	high	public	Pouliot	LB9C-F1N	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LB9C-F1N)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0440	Marguerite Latouche	female	1652	\N	PL-36067	21 May 1732	\N	PL-0506	high	public	Pouliot	LB9C-4LQ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LB9C-4LQ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0441	Jean Plante	male	about 1626	\N	PL-36267	29 March 1706	\N	PL-17519	high	public	Pouliot	LRHS-WNS	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRHS-WNS)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0442	Françoise Boucher	female	about June 1636	\N	PL-21206	18 April 1711	\N	PL-17519	high	public	Pouliot	L24C-3RJ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L24C-3RJ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0443	Maurice Créspeau	male	about November 1637	\N	PL-36668	8 September 1704	\N	PL-4720	high	public	Pouliot	L7BH-YGT	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L7BH-YGT)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0444	Margueritte La Verdure	female	about 1640	\N	PL-36870	22 August 1727	\N	PL-4720	high	public	Pouliot	LVN7-47C	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVN7-47C)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0445	François-Normand Lacroix	male	21 October 1642	\N	PL-37073	27 August 1710	\N	PL-18603	high	public	Pouliot	KD9P-Q4C	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KD9P-Q4C)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0446	Anne Gangner	female	about October 1653	\N	PL-21206	\N	\N	\N	high	public	Pouliot	LZLP-PC2	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZLP-PC2)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0447	Nicolas Quentin	male	about 4 November 1633	\N	PL-37480	27 May 1683	\N	PL-15967	high	public	Pouliot	LRMD-519	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRMD-519)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0448	Magdelaine Roulois	female	about 1648	\N	PL-22281	after 24 July 1707	\N	\N	high	public	Pouliot	LJNB-RQH	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LJNB-RQH)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0449	Anthoine Pepin	male	10 April 1636	\N	PL-37889	about 23 January 1703	\N	PL-16347	high	public	Pouliot	L4R8-LG9	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L4R8-LG9)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0450	Marie Taiste	female	about 1638	\N	PL-38095	about 11 September 1701	\N	PL-16347	high	public	Pouliot	L2D4-M3L	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L2D4-M3L)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0451	Emeri Beglouin	male	about April 1640	\N	PL-38302	14 July 1707	\N	PL-16476	high	public	Pouliot	LB2F-WNH	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LB2F-WNH)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0452	Marie Careau	female	20 March 1655	\N	PL-21206	10 February 1722	\N	PL-16476	high	public	Pouliot	LVN7-Y1D	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVN7-Y1D)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0454	ELISABETTA BONAGUIDI	female	30 May 1727	\N	PL-2171	4 November 1805	\N	PL-38717	high	public	Maternal Mariotti	PM4B-FHC	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PM4B-FHC)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0455	GIUSEPPE GIACOMELLI	male	\N	\N	PL-2171	\N	\N	\N	high	public	Maternal Mariotti	P9YH-1TL	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P9YH-1TL)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0456	ANGIOLA CASSANESI	female	\N	\N	\N	\N	\N	\N	high	public	Maternal Mariotti	P9YC-4LF	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P9YC-4LF)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0458	MARIA ANGIOLA BARONTI	female	\N	\N	PL-2171	\N	\N	\N	med	public	Maternal Mariotti	PM4B-4W6	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PM4B-4W6)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0459	MARIANO BONAGUIDI	male	29 January 1688	\N	PL-38717	\N	\N	\N	med	public	Maternal Mariotti	P4N7-V6K	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P4N7-V6K)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0460	CATERINA PAPINI	female	20 January 1699	\N	PL-38717	\N	\N	\N	med	public	Maternal Mariotti	PHMQ-Z3K	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PHMQ-Z3K)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0462	FIORE MARIOTTI	female	1664	\N	PL-1230	22 August 1734	\N	PL-1230	med	public	Maternal Mariotti	PM4B-PFF	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PM4B-PFF)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0463	GIOVANNI BONAGUIDI	male	1656	\N	PL-38717	13 March 1726	\N	PL-38717	med	public	Maternal Mariotti	PHMQ-Q3F	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PHMQ-Q3F)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0464	MARIA ANGELA STEFANELLI	female	1668	\N	PL-38717	1738	\N	PL-38717	med	public	Maternal Mariotti	PHMQ-J5N	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PHMQ-J5N)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0465	Pasquino Papini	male	\N	\N	PL-1230	\N	\N	\N	med	public	Maternal Mariotti	PHMN-GG2	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PHMN-GG2)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0466	Barbera Simoni	female	\N	\N	PL-38717	\N	\N	\N	med	public	Maternal Mariotti	PHMJ-95S	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PHMJ-95S)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0467	Green	male	\N	\N	\N	\N	\N	\N	med	public	Paternal Reed	PMJJ-SV4	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PMJJ-SV4)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0468	John Reeder Jr	male	29 January 1645	\N	PL-29949	9 May 1694	\N	PL-5407	high	public	Paternal Reed	LZG8-HGR	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZG8-HGR)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0469	Joanna Burroughs	female	1650	\N	PL-6375	9 May 1694	\N	PL-6375	high	public	Paternal Reed	LDXB-GKK	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LDXB-GKK)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0470	Henri Marchand I	male	10 October 1648	\N	PL-5426	1685	\N	PL-42254	high	public	Paternal Reed	L5KN-S9J	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L5KN-S9J)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0471	Mary Ruscoe	female	1654	\N	PL-42464	1685	\N	PL-42465	high	public	Paternal Reed	LV3J-NGZ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LV3J-NGZ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0472	John Houghton	male	28 February 1655	\N	PL-42677	4 January 1710	\N	PL-42678	high	public	Paternal Reed	LB4K-3K6	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LB4K-3K6)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0473	Dyna Philips	female	18 September 1657	\N	PL-42892	October 1738	\N	PL-42893	high	public	Paternal Reed	LB4K-WDS	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LB4K-WDS)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0475	Hannah Fuller	female	8 October 1636	\N	PL-43326	1 January 1686	\N	PL-5470	high	public	Paternal Reed	LXS4-8L3	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LXS4-8L3)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0476	Vincent Rongnion	male	2 March 1645	\N	PL-43544	11 November 1713	\N	PL-5470	high	public	Paternal Reed	LR9C-ZFS	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LR9C-ZFS)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0477	Anna Martha Boutcher	female	about 1650	\N	PL-43763	2 February 1737	\N	PL-5470	high	public	Paternal Reed	MX1Y-F86	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MX1Y-F86)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0478	Hugh Dunn	male	18 November 1642	\N	PL-43983	14 November 1694	\N	PL-43984	high	public	Paternal Reed	LVXN-8NR	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVXN-8NR)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0479	Elizabeth Drake	female	25 December 1653	\N	PL-5470	8 August 1711	\N	PL-43984	high	public	Paternal Reed	K2SJ-LN2	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: K2SJ-LN2)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0480	John Curtis	male	8 September 1635	\N	PL-44427	1 February 1695	\N	PL-44428	high	public	Paternal Reed	LZN3-S98	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZN3-S98)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0481	Anne Revell	female	9 December 1627	\N	PL-44652	2 October 1687	\N	PL-44653	high	public	Paternal Reed	M5NP-BKH	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: M5NP-BKH)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0482	Thomas Ellis	male	about 25 March 1628	\N	PL-44879	May 1682	\N	PL-44880	high	public	Paternal Reed	L4JQ-657	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L4JQ-657)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0483	Hannah Hebden Hugh	female	1635	\N	PL-45108	17 September 1678	\N	PL-45109	high	public	Paternal Reed	P4R4-C2W	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P4R4-C2W)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0485	Elizabeth Trundle	female	1621	\N	PL-45570	1661	\N	PL-5661	med	public	Paternal Reed	G1HY-1LX	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G1HY-1LX)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0486	Richard Gambray	male	about 1620	\N	PL-6121	\N	\N	\N	med	public	Paternal Reed	MJF9-TNJ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MJF9-TNJ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0487	Missy Nae O'Dell	female	about 1625	\N	PL-6121	\N	\N	\N	high	public	Paternal Reed	4N6S-NTL	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 4N6S-NTL)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0488	Isaac Baptiste "Sarratt"	male	about 1605	\N	PL-5693	19 February 1683	\N	PL-5693	high	public	Paternal Reed	G9DC-YKP	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G9DC-YKP)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0489	Nicole Oudinot	female	14 July 1618	\N	PL-46495	30 August 1681	\N	PL-5693	high	public	Paternal Reed	L6FD-7P1	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L6FD-7P1)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0490	William C Short	male	1634	\N	PL-46728	16 March 1675	\N	PL-46729	med	public	Paternal Reed	LK7T-P67	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LK7T-P67)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0491	Mary Elisabeth Nash	female	13 April 1635	\N	PL-46964	31 August 1689	\N	PL-5661	med	public	Paternal Reed	G92W-VG2	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G92W-VG2)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0492	Pål Persson	male	1621	\N	PL-47200	before 1671	\N	PL-2218	high	public	Paternal Reed	G6LC-TXK	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G6LC-TXK)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0493	Margareta Olofsdotter	female	1620	\N	PL-47437	1674	\N	PL-47438	high	public	Paternal Reed	LJLF-7HD	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LJLF-7HD)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0494	Simon Johnsson	male	about 1620	\N	PL-47677	\N	\N	\N	med	public	Paternal Reed	KX56-51J	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KX56-51J)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0495	?	female	\N	\N	\N	\N	\N	\N	med	public	Paternal Reed	CCG4-3YQ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: CCG4-3YQ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0496	William Thomas West	male	5 November 1616	\N	PL-9949	17 January 1696	\N	PL-9949	high	public	Paternal Reed	L6MZ-7W4	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L6MZ-7W4)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0497	Elizabeth Middlemore	female	about 1615	\N	PL-48395	18 January 1684	\N	PL-48396	high	public	Paternal Reed	LCRK-HLX	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LCRK-HLX)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0498	Thomas Gilpin	male	1620	\N	\N	3 February 1682	\N	PL-10039	high	public	Paternal Reed	L8SS-GZT	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L8SS-GZT)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0499	Joan Bartholomew	female	1625	\N	PL-48879	21 January 1700	\N	PL-10039	high	public	Paternal Reed	WYFX-JNF	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: WYFX-JNF)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0500	Aaron Deane	male	about 1602	\N	PL-10132	9 March 1676	\N	PL-10132	high	public	Paternal Reed	MZ95-4QQ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MZ95-4QQ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0501	Rebecca Gardyne	female	about 1602	\N	PL-10132	July 1643	\N	PL-10132	med	public	Paternal Reed	MZ95-4QH	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MZ95-4QH)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0502	John Wilson	male	\N	\N	\N	about 1690	\N	PL-45570	high	public	Paternal Reed	MM6Y-RMF	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MM6Y-RMF)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0503	Elsabeth Atkinson	female	about 1633	\N	PL-49848	about 1686	\N	\N	high	public	Paternal Reed	MXDW-Q39	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MXDW-Q39)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0504	Broer Sinnicksson	male	about 1650	\N	PL-47677	30 November 1708	\N	PL-2219	high	public	Paternal Reed	LVYM-PNQ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVYM-PNQ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0505	Sophia Pålsdotter	female	1635	\N	PL-50335	9 December 1717	\N	PL-0098	high	public	Paternal Reed	L5FN-R1Y	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L5FN-R1Y)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0506	Jan Harmansen	male	about 1640	\N	PL-2219	1695	\N	\N	high	public	Paternal Reed	2DT2-LMQ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 2DT2-LMQ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0507	Catherina Corderus	female	about 1632	\N	PL-2219	1 December 1716	\N	PL-10881	med	public	Paternal Reed	KHTY-YF7	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KHTY-YF7)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0508	Hendrick Eigil Jacobsson	male	1636	\N	PL-51068	5 May 1704	\N	PL-51069	high	public	Paternal Reed	KC1C-YJJ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KC1C-YJJ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0509	Gertrude Hendricksdotter	female	1632	\N	PL-8170	27 December 1685	\N	PL-2218	med	public	Paternal Reed	K8QB-54M	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: K8QB-54M)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0510	Peter Mattson Dalbo	male	\N	\N	\N	\N	\N	\N	med	public	Paternal Reed	PDGY-165	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PDGY-165)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0511	Catherine Rambo	female	1655	\N	PL-51808	1708	\N	PL-51809	high	public	Paternal Reed	L78Y-J66	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L78Y-J66)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0513	Elinor Jansen	female	about 1645	\N	\N	after 21 November 1721	\N	PL-2218	med	public	Paternal Reed	GG27-TPH	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GG27-TPH)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0514	John Grubb Sr.	male	before 16 August 1652	\N	PL-52557	4 April 1708	\N	PL-8170	high	public	Paternal Reed	MYRD-6JG	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MYRD-6JG)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0515	Frances	female	about 1660	\N	PL-5388	12 February 1708	\N	PL-52808	high	public	Paternal Reed	LYHL-RQS	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LYHL-RQS)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0516	Anders Olofsson Stille	male	1639	\N	PL-53060	before 1693	\N	PL-51808	high	public	Paternal Reed	LRSN-KZ3	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRSN-KZ3)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0517	Annettje Perterse von Cowenhoven	female	1644	\N	PL-53313	1698	\N	PL-53314	high	public	Paternal Reed	G7D6-P5V	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G7D6-P5V)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0518	Carl Christopher Springer	male	6 November 1658	\N	PL-53569	26 May 1738	\N	PL-2218	high	public	Paternal Reed	M4WS-9GL	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: M4WS-9GL)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0519	Margietje Maria Hendricksdotter	female	1658	\N	PL-7483	15 March 1727	\N	PL-2218	high	public	Paternal Reed	LDM1-XBB	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LDM1-XBB)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0520	Cornelius Vandeveer	male	February 1659	\N	PL-2219	18 December 1712	\N	PL-2371	high	public	Paternal Reed	LVJ8-67G	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVJ8-67G)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0521	Margareta Fransson Van De  Ver	female	about 1658	\N	PL-7349	12 January 1763	\N	PL-0098	high	public	Paternal Reed	LZ4J-CFJ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZ4J-CFJ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0522	Adam Stidham	male	about 1660	\N	PL-54590	21 January 1695	\N	PL-2218	high	public	Paternal Reed	LTYD-JY8	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LTYD-JY8)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0523	Katherine Karin	female	1662	\N	PL-2218	21 November 1739	\N	PL-2219	high	public	Paternal Reed	MV9N-595	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MV9N-595)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0524	Owen Foulke	male	about 1650	\N	PL-55103	5 August 1695	\N	PL-6267	med	public	Paternal Reed	LHKT-VK6	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LHKT-VK6)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0525	Sarah Elinor Morgan	female	1655	\N	PL-55361	1720	\N	PL-2371	med	public	Paternal Reed	P3MB-WRQ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P3MB-WRQ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0526	Oliver Cope	male	13 March 1647	\N	PL-55620	after 21 May 1697	\N	PL-51808	high	public	Paternal Reed	L8YT-Y4C	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L8YT-Y4C)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0527	Rebecca Crooke	female	about 1647	\N	PL-55620	1728	\N	PL-55880	high	public	Paternal Reed	9X5H-MBT	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 9X5H-MBT)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0528	William Brinton Sr	male	1 December 1630	\N	PL-56141	20 October 1700	\N	PL-56142	high	public	Paternal Reed	KNDB-5MF	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KNDB-5MF)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0529	Ann Bagley	female	27 April 1634	\N	PL-56405	5 April 1699	\N	PL-56142	high	public	Paternal Reed	KNW3-434	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KNW3-434)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0530	Laurens Duyts	male	1610	\N	PL-56669	\N	\N	\N	med	public	Paternal Reed	GVVB-R3C	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GVVB-R3C)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0531	Grietje\\Ijtje\\Ytie (Jans\\Jansen) Dye\\ Duytszen\\Duyts	female	1620	\N	PL-56934	from 25 November 1658 to 1662	\N	PL-7028	med	public	Paternal Reed	P63W-W74	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P63W-W74)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0532	Robert Bruce Pollock	male	1606	\N	PL-57200	1660	\N	PL-57200	med	public	Paternal Reed	GRQP-X78	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GRQP-X78)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0533	Jean Crawford	female	1606	\N	PL-57200	\N	\N	\N	med	public	Paternal Reed	P7BB-7CY	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P7BB-7CY)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0534	Roger Tasker	male	1606	\N	PL-6120	1688	\N	PL-6120	high	public	Paternal Reed	PZTX-N47	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PZTX-N47)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0535	Magdalen Porter	female	1610	\N	PL-6603	from 1660 to 1700	\N	PL-6120	high	public	Paternal Reed	G26R-N8P	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G26R-N8P)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0536	Alexander Williams	male	about 1626	\N	PL-5388	before 11 August 1687	\N	PL-5760	high	public	Paternal Reed	9WPV-XJ7	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 9WPV-XJ7)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0537	Ruth Ann Tackling	female	about 1628	\N	PL-5760	\N	\N	\N	high	public	Paternal Reed	LWFV-JX5	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LWFV-JX5)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0538	Nehemiah Covington	male	1628	\N	PL-58797	9 June 1681	\N	PL-5831	high	public	Paternal Reed	LKTH-SXT	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LKTH-SXT)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0786	Jean Baillargeon	male	about 1612	\N	PL-146948	1681	\N	PL-4471	high	public	Pouliot	L52G-39Z	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L52G-39Z)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0539	Mary Vaughan	female	1627	\N	PL-59065	1 April 1667	\N	PL-5831	high	public	Paternal Reed	GL5B-VLY	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GL5B-VLY)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0540	Benjamin Cottman	male	24 May 1651	\N	PL-59334	29 March 1703	\N	PL-5760	high	public	Paternal Reed	LTCJ-LJG	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LTCJ-LJG)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0541	Mary Hudnall	female	April 1643	\N	PL-59604	September 1684	\N	\N	high	public	Paternal Reed	LBJY-GYQ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LBJY-GYQ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0542	Robert Hardy	male	1646	\N	PL-59875	August 1679	\N	PL-5760	high	public	Paternal Reed	G5GJ-WNB	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G5GJ-WNB)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0543	Mary Ann Olcott Moon	female	about 1648	\N	PL-45570	\N	\N	\N	high	public	Paternal Reed	LHPQ-PQ5	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LHPQ-PQ5)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0544	Deacon Samuel Allen Jr. of Bridgewater	male	about 1632	\N	PL-60418	before December 1705	\N	PL-60419	high	public	Paternal Reed	LYNR-7QR	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LYNR-7QR)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0545	Sarah Partridge	female	2 September 1639	\N	PL-60693	7 August 1722	\N	PL-12110	high	public	Paternal Reed	LHQY-8KR	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LHQY-8KR)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0546	John Cary	male	4 December 1610	\N	PL-60968	31 October 1681	\N	PL-60419	high	public	Paternal Reed	L5RC-VH1	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L5RC-VH1)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0547	Elizabeth Godfrey	female	about 1620	\N	PL-5388	1 November 1680	\N	PL-60419	high	public	Paternal Reed	LVG2-1ZL	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVG2-1ZL)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0548	Richard Bushnell Sr	male	April 1623	\N	PL-61519	17 July 1660	\N	PL-61520	high	public	Paternal Reed	M38Y-9YX	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: M38Y-9YX)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0549	Mary Marvin	female	before 16 December 1628	\N	PL-61798	26 March 1713	\N	PL-11078	high	public	Paternal Reed	LHNF-XSS	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LHNF-XSS)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0550	Lt. Thomas Leffingwell Jr.	male	about March 1624	\N	PL-62077	28 March 1714	\N	PL-11078	high	public	Paternal Reed	KZ9Q-314	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KZ9Q-314)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0551	Mary White	female	11 March 1626	\N	PL-62357	6 February 1711	\N	PL-11078	high	public	Paternal Reed	LC41-RL8	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LC41-RL8)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0552	John Sargent	male	before 8 December 1639	\N	PL-62638	9 September 1716	\N	PL-12323	high	public	Paternal Reed	LL9V-87D	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LL9V-87D)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0553	Deborah Hyllier	female	30 October 1643	\N	PL-62920	20 April 1669	\N	PL-12323	high	public	Paternal Reed	LL9K-4V1	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LL9K-4V1)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0554	David Linnell	male	9 March 1622	\N	PL-63203	14 November 1688	\N	PL-63204	high	public	Paternal Reed	LRH7-YLY	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRH7-YLY)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0555	Hannah Shelley	female	2 July 1637	\N	PL-63203	5 April 1709	\N	PL-63204	high	public	Paternal Reed	L6S4-FC8	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L6S4-FC8)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0556	Thomas Wood I	male	before 29 April 1632	\N	PL-63773	12 September 1687	\N	PL-2653	high	public	Paternal Reed	LY7R-F1C	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LY7R-F1C)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0557	Ann Hobkinson	female	23 March 1628	\N	PL-64059	29 December 1714	\N	PL-2653	high	public	Paternal Reed	LRF7-6K7	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRF7-6K7)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0558	Nehemiah Hunt, Sr.	male	1631	\N	\N	6 March 1718	\N	PL-14982	high	public	Paternal Reed	LZJM-6B3	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZJM-6B3)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0559	Mary Toll	female	8 December 1643	\N	PL-64632	29 August 1727	\N	PL-14982	high	public	Paternal Reed	LKKM-N84	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LKKM-N84)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0560	Lieutenant Nehemiah Palmer Sr.	male	2 November 1637	\N	PL-62638	17 February 1717	\N	PL-12540	high	public	Paternal Reed	LRLZ-5QR	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRLZ-5QR)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0561	Hannah Stanton	female	21 March 1644	\N	PL-25998	17 October 1727	\N	PL-15105	high	public	Paternal Reed	LVF6-HFJ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVF6-HFJ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0562	Captain Joseph Saxton	male	9 May 1656	\N	PL-65494	18 July 1715	\N	PL-12540	high	public	Paternal Reed	L63R-722	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L63R-722)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0563	Hannah Denison	female	20 May 1643	\N	PL-65783	18 October 1715	\N	PL-12540	high	public	Paternal Reed	L67T-MBL	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L67T-MBL)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0564	Lucretia Pinney Carroll	female	17 January 1723	\N	PL-3186	16 February 1805	\N	PL-0109	med	public	Paternal Reed	GL5H-K17	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GL5H-K17)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0565	Sir Francis Bernard II	male	about 1558	\N	PL-66362	November 1630	\N	PL-66362	high	public	Paternal Reed	LZZQ-9QY	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZZQ-9QY)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0566	Mary Woolhouse	female	about 1584	\N	PL-66653	about 1656	\N	PL-66362	high	public	Paternal Reed	M9KZ-LY2	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: M9KZ-LY2)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0567	Mathew Merrill	male	about 1596	\N	PL-66945	\N	\N	\N	high	public	Paternal Reed	PSGN-9Q8	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PSGN-9Q8)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0568	Isabell Freeman	female	about 1598	\N	PL-67238	about 1637	\N	\N	high	public	Paternal Reed	KCL6-G9K	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KCL6-G9K)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0570	Mrs. John Strong	female	1586	\N	PL-67827	24 April 1654	\N	PL-26513	high	public	Paternal Reed	M4MX-3Q3	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: M4MX-3Q3)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0571	Thomas Ford of Bridport	male	about 1591	\N	PL-68123	9 November 1676	\N	PL-26514	high	public	Paternal Reed	LZV6-VDJ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZV6-VDJ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0572	Elizabeth Charde	female	about 1589	\N	PL-26688	18 April 1643	\N	PL-24351	high	public	Paternal Reed	9DTT-B4C	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 9DTT-B4C)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0573	Edward Griswold	male	26 July 1607	\N	PL-26863	30 August 1690	\N	PL-68716	high	public	Paternal Reed	9QSM-2DZ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 9QSM-2DZ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0574	Margaret	female	1610	\N	PL-26863	23 August 1670	\N	PL-68716	high	public	Paternal Reed	MJFK-SCQ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MJFK-SCQ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0575	Thomas Holcombe	male	about 1609	\N	\N	7 September 1657	\N	PL-24351	high	public	Paternal Reed	L18L-Q7C	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L18L-Q7C)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0576	Elizabeth	female	11 November 1617	\N	PL-69608	7 October 1679	\N	PL-3186	high	public	Paternal Reed	LB9F-FGD	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LB9F-FGD)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0577	Robert Williams	male	29 May 1580	\N	PL-27216	4 April 1622	\N	PL-69907	high	public	Paternal Reed	MSVW-XF2	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MSVW-XF2)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0578	Elizabeth Stratton	female	27 August 1581	\N	PL-27216	28 July 1674	\N	PL-27216	high	public	Paternal Reed	GDXR-7D7	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GDXR-7D7)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0579	Sir Humphrey Pinney	male	20 November 1605	\N	PL-70506	20 August 1683	\N	PL-3186	high	public	Paternal Reed	L19S-RZC	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L19S-RZC)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0580	Mary Hull	female	27 July 1618	\N	PL-70807	18 August 1684	\N	PL-3186	high	public	Paternal Reed	K8V8-14J	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: K8V8-14J)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0581	John Bissell	male	30 October 1591	\N	PL-71109	3 October 1677	\N	PL-3331	high	public	Paternal Reed	LRLL-MDP	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRLL-MDP)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0582	unknown	female	about 1593	\N	PL-5388	21 May 1641	\N	PL-3331	high	public	Paternal Reed	M2X9-3ZF	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: M2X9-3ZF)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0583	William Thrall	male	August 1605	\N	PL-43763	3 August 1679	\N	PL-3186	high	public	Paternal Reed	LV95-7MM	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LV95-7MM)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0584	Elizabeth Goode	female	1605	\N	PL-72016	30 July 1676	\N	PL-3186	high	public	Paternal Reed	94NR-T21	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 94NR-T21)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0585	Thomas Gunn	male	about 1605	\N	PL-72320	26 February 1680	\N	PL-72321	high	public	Paternal Reed	LZPM-4YG	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZPM-4YG)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0586	Elizabeth	female	\N	\N	PL-5388	about 28 November 1678	\N	PL-72321	high	public	Paternal Reed	GZ18-J98	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GZ18-J98)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0587	Richard (Rici) Morgan de Ryppon	male	1609	\N	PL-55361	1649	\N	PL-45570	med	public	Paternal Reed	P6QZ-LRX	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P6QZ-LRX)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0590	Samuel Sessions	male	1614	\N	PL-73851	1706	\N	PL-11691	high	public	Paternal Reed	MSM9-3XP	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MSM9-3XP)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0591	Mrs. Lucille Sessions	female	about 1624	\N	PL-74160	\N	\N	\N	high	public	Paternal Reed	GSQ3-3Z4	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GSQ3-3Z4)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0592	John Spofford II	male	21 April 1611	\N	PL-74470	before 6 November 1678	\N	PL-2653	high	public	Paternal Reed	LR2W-6B1	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LR2W-6B1)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0593	Elizabeth Scott	female	18 November 1623	\N	PL-74781	10 February 1691	\N	PL-74782	high	public	Paternal Reed	LZPQ-RHG	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZPQ-RHG)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0594	Sabbath Clark	male	1587	\N	PL-75095	30 March 1663	\N	PL-29017	high	public	Paternal Reed	LC2Q-PGR	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LC2Q-PGR)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0595	Elizabeth Overton	female	November 1592	\N	PL-75409	September 1656	\N	PL-29017	high	public	Paternal Reed	LHTR-P82	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LHTR-P82)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0596	Captain Thomas Newberry	male	10 November 1594	\N	PL-75724	from 17 December 1635 to 28 January 1636	\N	PL-75725	high	public	Paternal Reed	MPJ4-G24	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MPJ4-G24)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0597	Joane Dabinott	female	about 1600	\N	PL-76042	19 February 1629	\N	PL-76043	high	public	Paternal Reed	LRR9-THB	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRR9-THB)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0598	John Deming	male	about 1610	\N	PL-5388	21 November 1705	\N	PL-25830	high	public	Paternal Reed	LW19-D2X	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LW19-D2X)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0599	Honor Treat	female	19 March 1615	\N	PL-76680	21 November 1705	\N	PL-25830	high	public	Paternal Reed	9CQT-Z1N	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 9CQT-Z1N)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0600	Joseph Mygatt	male	31 August 1596	\N	PL-77000	7 December 1680	\N	PL-24028	high	public	Paternal Reed	LCMG-FPB	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LCMG-FPB)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0601	Ann LNU	female	1596	\N	PL-5388	4 March 1686	\N	PL-24028	high	public	Paternal Reed	G3L4-B35	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G3L4-B35)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0602	William Edwards	male	1618	\N	PL-27216	4 December 1680	\N	PL-25998	high	public	Paternal Reed	LT7K-C5G	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LT7K-C5G)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0603	Agnes Harris	female	6 April 1604	\N	PL-77961	1705	\N	PL-24028	high	public	Paternal Reed	937M-96Z	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 937M-96Z)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0604	William Tuttle	male	26 December 1607	\N	PL-78283	16 June 1673	\N	PL-78284	high	public	Paternal Reed	LZV6-7D9	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZV6-7D9)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0605	Elizabeth	female	1609	\N	PL-78283	31 December 1684	\N	PL-78284	high	public	Paternal Reed	M7X2-6TY	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: M7X2-6TY)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0607	Jeanne Josse	female	\N	\N	PL-22281	after 5 June 1667	\N	PL-22281	high	public	Pouliot	L6LK-2H8	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L6LK-2H8)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0608	Mathurin Le Monnier	male	about 22 April 1619	\N	PL-79577	after 9 October 1676	\N	PL-19737	high	public	Pouliot	LVD4-CBY	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVD4-CBY)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0609	Francoise Faffart	female	about 1624	\N	PL-22281	13 January 1702	\N	PL-18603	high	public	Pouliot	LR2B-X2Q	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LR2B-X2Q)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0611	Vincende Roy	female	\N	\N	PL-22281	before 10 January 1645	\N	PL-22281	high	public	Pouliot	LYXP-148	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LYXP-148)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0612	Francois Despres	male	11 March 1531	\N	PL-18882	\N	\N	PL-18882	med	public	Pouliot	GD74-DWY	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GD74-DWY)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0613	Madeleine Legrand	female	1525	\N	PL-18882	\N	\N	PL-36870	med	public	Pouliot	GD74-WY3	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GD74-WY3)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0614	Mathurin Chabot	male	about 18 August 1637	\N	PL-81527	12 June 1696	\N	PL-81528	high	public	Pouliot	GMNX-ZPD	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GMNX-ZPD)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0615	Marie Mesange	female	about 4 April 1643	\N	PL-81856	13 March 1692	\N	PL-4471	high	public	Pouliot	9SLR-TSY	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 9SLR-TSY)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0616	Michel Enaud	male	1636	\N	PL-82185	3 September 1701	\N	PL-82186	high	public	Pouliot	LRJ7-8WS	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRJ7-8WS)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0617	Geneviève Eleonore Macré	female	1636	\N	PL-82517	about 12 December 1700	\N	PL-0506	high	public	Pouliot	LRPY-S44	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRPY-S44)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0618	Pierre Dufraisne	male	about 1627	\N	PL-82849	29 November 1687	\N	PL-4471	high	public	Pouliot	9S3W-MFB	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 9S3W-MFB)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0619	Anne Patin	female	about 1634	\N	PL-83182	about 29 November 1700	\N	PL-4471	high	public	Pouliot	9WFC-SZ3	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 9WFC-SZ3)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0620	Nicolas Godbout	male	17 May 1635	\N	PL-83516	5 September 1674	\N	PL-81528	high	public	Pouliot	LCXC-XY1	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LCXC-XY1)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0621	Marie Marthe Bourgoin	female	22 February 1638	\N	PL-36870	19 December 1682	\N	PL-17122	high	public	Pouliot	LB91-VFM	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LB91-VFM)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0622	Pierre BRULON	male	10 January 1637	\N	PL-84185	January 1678	\N	PL-84186	high	public	Pouliot	PH84-Y3T	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PH84-Y3T)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0623	Janne Baillargent	female	4 May 1651	\N	PL-21206	19 August 1729	\N	PL-20612	high	public	Pouliot	LKSD-MVW	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LKSD-MVW)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0624	Gabriel Rouleau dit Sanssoucy	male	1618	\N	PL-84859	22 February 1673	\N	PL-19023	high	public	Pouliot	GSZD-7CT	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GSZD-7CT)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0625	Mathurine Leroux	female	18 March 1635	\N	PL-85197	1 February 1708	\N	PL-4471	high	public	Pouliot	KHDK-896	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KHDK-896)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0626	Jean Le Clerc	male	about 24 August 1635	\N	PL-85536	about 1680	\N	\N	high	public	Pouliot	LTY4-Q4Q	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LTY4-Q4Q)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0627	Marie Blanquet	female	about 31 August 1631	\N	PL-85876	10 September 1709	\N	PL-4720	high	public	Pouliot	LT3W-WSZ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LT3W-WSZ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0628	Thomas Rondeau	male	about 1638	\N	PL-86217	10 November 1721	\N	PL-4720	high	public	Pouliot	LVLX-MKX	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVLX-MKX)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0629	Andrée Remondiere	female	about 1651	\N	PL-34693	21 November 1702	\N	PL-4720	high	public	Pouliot	LK99-VYZ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LK99-VYZ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0630	Gabriel Gosselin	male	1621	\N	PL-86900	about July 1697	\N	PL-21206	high	public	Pouliot	L7FH-H5N	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L7FH-H5N)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0631	Françoise Lelievre	female	1632	\N	PL-87243	27 September 1677	\N	PL-87244	high	public	Pouliot	LZVW-DK3	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZVW-DK3)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0632	Jacques Raté	male	about March 1630	\N	PL-36267	8 April 1699	\N	PL-4720	high	public	Pouliot	LBBX-7VK	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LBBX-7VK)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0633	Anne Martin	female	about March 1645	\N	PL-21206	14 January 1717	\N	PL-4720	high	public	Pouliot	LKN3-TLP	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LKN3-TLP)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0634	André Terrien	male	29 October 1611	\N	PL-34693	29 October 1661	\N	PL-34887	high	public	Pouliot	LR3J-8CQ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LR3J-8CQ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0635	Marie Anne Foucault	female	1615	\N	PL-34693	17 May 1670	\N	PL-34693	high	public	Pouliot	LYCV-JGN	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LYCV-JGN)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0636	Jean Mignault	male	about 1620	\N	PL-88965	about 22 July 1665	\N	PL-22281	high	public	Pouliot	LVRN-BGF	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVRN-BGF)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0637	Marie Louise Cloutier	female	about 1631	\N	PL-34693	15 January 1711	\N	PL-16476	high	public	Pouliot	GCM1-FQM	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GCM1-FQM)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0638	Jacque de Fontaine	male	about 1625	\N	PL-89656	after 8 February 1683	\N	PL-22281	high	public	Pouliot	LJ5F-D2F	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LJ5F-D2F)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0639	Jeanne Collinet	female	about 1627	\N	PL-89656	20 October 1686	\N	PL-89656	high	public	Pouliot	LJ5F-DLP	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LJ5F-DLP)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0640	Pierre Conille	male	14 March 1644	\N	PL-34693	1669	\N	PL-34693	high	public	Pouliot	LCJN-QV8	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LCJN-QV8)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0641	Marie Giton	female	about 1649	\N	PL-90695	17 January 1708	\N	PL-4471	high	public	Pouliot	LRMM-24S	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRMM-24S)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0642	Jacques Delage	male	about 1605	\N	PL-91043	before 10 October 1669	\N	PL-22281	med	public	Pouliot	K4PT-CML	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: K4PT-CML)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0643	Marguerite	female	1609	\N	PL-91043	after 1642	\N	PL-91392	med	public	Pouliot	KT4Z-VT2	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KT4Z-VT2)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0644	Eustache Petit	male	about 1608	\N	PL-36870	10 October 1669	\N	PL-36870	high	public	Pouliot	KGCL-LH9	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KGCL-LH9)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0646	Etienne Fontenay Manseau	male	1606	\N	PL-88965	21 September 1673	\N	PL-92440	high	public	Pouliot	LQR5-S8N	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LQR5-S8N)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0647	Marie MÉTAYER	female	\N	\N	\N	\N	\N	\N	high	public	Pouliot	LDSS-WJM	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LDSS-WJM)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0648	Jean Latouche	male	6 September 1632	\N	PL-93141	26 December 1689	\N	PL-93141	high	public	Pouliot	KV2P-G34	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KV2P-G34)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0649	Marie Tevellon	female	1630	\N	PL-93141	1673	\N	PL-36067	high	public	Pouliot	G3Z3-V4Q	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G3Z3-V4Q)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0650	Nicolas Plante	male	27 September 1583	\N	PL-93844	21 May 1647	\N	PL-93845	high	public	Pouliot	LR9H-CLZ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LR9H-CLZ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0651	Elizabeth Chauvin	female	1601	\N	PL-36267	14 February 1646	\N	PL-36267	high	public	Pouliot	L121-V1Y	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L121-V1Y)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0652	Marin Boucher	male	about 1587	\N	PL-94552	29 March 1671	\N	PL-17519	high	public	Pouliot	LTZN-HKC	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LTZN-HKC)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0653	Perrine Malet	female	about 1604	\N	PL-94907	24 August 1687	\N	PL-17519	high	public	Pouliot	LT4B-PJ7	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LT4B-PJ7)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0654	Jehan Créspeau	male	28 February 1614	\N	PL-95263	after 12 October 1665	\N	PL-22281	high	public	Pouliot	LXSZ-MWK	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LXSZ-MWK)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0655	Suzanne Fumoleau	female	25 April 1613	\N	PL-95620	12 November 1643	\N	PL-36668	high	public	Pouliot	L417-4LN	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L417-4LN)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0656	Martin La Verdure	male	\N	\N	PL-22281	after 12 October 1665	\N	PL-22281	high	public	Pouliot	L6QM-TVM	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L6QM-TVM)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0657	Jacline Le Liot	female	1620	\N	PL-96335	12 October 1665	\N	PL-96335	high	public	Pouliot	LVN7-CX8	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVN7-CX8)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0658	François Marsan Laponche	male	1600	\N	PL-96694	1691	\N	\N	med	public	Pouliot	GWLN-889	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GWLN-889)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0659	Françoise Lapierre	female	1594	\N	PL-97054	1645	\N	\N	med	public	Pouliot	PM5Y-BQD	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PM5Y-BQD)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0660	Jacques Godin	male	about 1605	\N	PL-21056	\N	\N	PL-22281	high	public	Pouliot	LT5F-2PQ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LT5F-2PQ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0661	Marguerite Nicole	female	about 1605	\N	PL-21056	\N	\N	\N	high	public	Pouliot	LRTN-KMH	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRTN-KMH)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0662	Jean Jacob Mathieu	male	16 February 1610	\N	PL-98135	29 April 1699	\N	PL-98136	high	public	Pouliot	LTRJ-WM4	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LTRJ-WM4)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0663	Isabelle Monnachau	female	1615	\N	PL-98135	19 November 1669	\N	PL-98135	high	public	Pouliot	LTRJ-5X8	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LTRJ-5X8)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0664	René Letartre	male	about 1626	\N	PL-98861	about 2 September 1699	\N	PL-15967	high	public	Pouliot	LF72-TFZ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LF72-TFZ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0665	Louise Goulet	female	about August 1628	\N	PL-99225	after 6 October 1696	\N	PL-19737	high	public	Pouliot	KN8P-Y6F	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KN8P-Y6F)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0667	Madeleine Giguère	female	26 May 1605	\N	PL-21662	before 3 April 1650	\N	PL-21662	high	public	Pouliot	LTHY-QYC	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LTHY-QYC)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0668	Loys ou Louis Chappellain	male	19 September 1617	\N	PL-100321	1 February 1700	\N	PL-81528	high	public	Pouliot	LTZ5-694	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LTZ5-694)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0669	Francoise Dechaux	female	about 1621	\N	PL-100688	25 January 1695	\N	PL-81528	high	public	Pouliot	LTZ5-6VP	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LTZ5-6VP)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0671	Sebastienne	female	\N	\N	PL-22281	after 9 November 1671	\N	PL-22281	high	public	Pouliot	LZZ2-PTX	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZZ2-PTX)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0672	Francois Bellanger	male	about 1612	\N	PL-101790	after 25 October 1685	\N	PL-19737	high	public	Pouliot	LRR2-WFV	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRR2-WFV)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0673	Marie Guyon	female	about March 1624	\N	PL-94552	29 August 1696	\N	PL-102159	high	public	Pouliot	LRCV-FXH	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRCV-FXH)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0674	Zacharie Cloustier	male	about 16 August 1617	\N	PL-94552	3 February 1708	\N	PL-17519	high	public	Pouliot	LBNL-4LN	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LBNL-4LN)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0675	Magdeleine Aymart	female	about 1 August 1626	\N	PL-102898	28 May 1708	\N	PL-17519	high	public	Pouliot	LT5N-95W	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LT5N-95W)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0676	Pierre Gagnon	male	about February 1612	\N	PL-103269	17 April 1699	\N	PL-17519	high	public	Pouliot	LVNP-921	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVNP-921)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0677	Vincente des Varieux	female	about 1624	\N	PL-103641	2 January 1695	\N	PL-17519	high	public	Pouliot	LZRK-9N9	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZRK-9N9)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0678	Julien Fortin	male	9 February 1621	\N	PL-18465	after 18 June 1689	\N	PL-19737	high	public	Pouliot	LBHP-HWL	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LBHP-HWL)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0679	Genevieve De Lamare	female	about 13 October 1636	\N	PL-104386	about 5 November 1709	\N	PL-23068	high	public	Pouliot	9V89-S2M	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 9V89-S2M)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0680	François LaCroix	male	1610	\N	PL-104760	24 August 1670	\N	PL-37073	high	public	Pouliot	L5RT-PYD	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L5RT-PYD)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0681	Jeanne Therese Huot	female	22 February 1612	\N	PL-104760	27 August 1710	\N	PL-105135	high	public	Pouliot	LV9Y-VJV	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LV9Y-VJV)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0682	Louys Gasnier	male	about 13 September 1612	\N	PL-37480	after 2 February 1660	\N	PL-18603	high	public	Pouliot	LT37-5J3	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LT37-5J3)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0683	Marie Michel	female	about 1615	\N	PL-105886	12 November 1687	\N	PL-18603	high	public	Pouliot	LYKT-S6Q	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LYKT-S6Q)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0684	Louys Quentin	male	1603	\N	PL-106263	\N	\N	PL-22281	high	public	Pouliot	LR2F-1R4	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LR2F-1R4)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0685	Marie Des Monceaux	female	1 April 1613	\N	PL-106641	\N	\N	PL-22281	high	public	Pouliot	L6HX-4FL	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L6HX-4FL)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0686	Michel Roulois	male	about 1622	\N	PL-107020	12 October 1690	\N	PL-15967	high	public	Pouliot	LJNB-TND	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LJNB-TND)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0687	Jehanne Masline	female	about 25 July 1625	\N	PL-18465	4 January 1689	\N	PL-17519	high	public	Pouliot	MBXN-CF9	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MBXN-CF9)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0688	Andre Pepin	male	about 1610	\N	PL-22281	\N	\N	PL-22281	high	public	Pouliot	LBV4-RVS	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LBV4-RVS)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0689	Jeanne Chevalier	female	12 September 1612	\N	PL-37480	\N	\N	\N	high	public	Pouliot	MXC6-3PS	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MXC6-3PS)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0690	Jean Teste	male	about 1610	\N	PL-108537	1652	\N	PL-108538	high	public	Pouliot	K4B5-K2B	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: K4B5-K2B)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0691	Louise Talonneau	female	1611	\N	PL-38095	after 1656	\N	PL-34693	high	public	Pouliot	MXR7-DS2	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MXR7-DS2)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0692	Andre Beglouin	male	1615	\N	PL-38302	\N	\N	PL-22281	high	public	Pouliot	LVDX-TRB	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVDX-TRB)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0693	Françoise Touzelet	female	\N	\N	PL-22281	\N	\N	PL-22281	high	public	Pouliot	LV4M-NGZ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LV4M-NGZ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0694	Louys Carreau	male	about 1622	\N	PL-22281	24 May 1693	\N	PL-81528	high	public	Pouliot	LBJW-2LC	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LBJW-2LC)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0695	Jeanne Le Rouge	female	about 24 June 1628	\N	PL-110444	about 9 March 1696	\N	PL-15967	high	public	Pouliot	LR82-XN2	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LR82-XN2)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0696	Maria Caterina Cecchi	female	about 1730	\N	PL-0390	about 1765	\N	PL-0390	med	public	Maternal Mariotti	GRL5-QZN	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GRL5-QZN)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0698	PIERA ARCANGELI	female	17 September 1627	\N	PL-2171	30 July 1699	\N	PL-38717	med	public	Maternal Mariotti	PM4B-B85	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PM4B-B85)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0700	Giovanna	female	\N	\N	\N	\N	\N	\N	med	public	Maternal Mariotti	PHWR-62J	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PHWR-62J)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0701	BARTOLOMEO BONAGUIDI	male	\N	\N	PL-38717	\N	\N	\N	med	public	Maternal Mariotti	PHMQ-74N	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PHMQ-74N)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0702	LISABETTA RICCI	female	\N	\N	PL-38717	13 January 1691	\N	\N	med	public	Maternal Mariotti	PHMQ-ZWS	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PHMQ-ZWS)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0703	Bartolomeo Stefanelli	male	\N	\N	PL-113501	\N	\N	\N	med	public	Maternal Mariotti	PHMN-B3F	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PHMN-B3F)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0704	Lisabetta	female	1664	\N	PL-113501	\N	\N	\N	med	public	Maternal Mariotti	PHMJ-3D5	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PHMJ-3D5)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0705	Michel Louis Pouillot Boullard	male	27 May 1580	\N	PL-114268	6 January 1644	\N	PL-98136	med	public	Pouliot	P3JH-NG2	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P3JH-NG2)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0706	Jacqueline Laurens	female	1584	\N	PL-35473	1615	\N	PL-98136	med	public	Pouliot	P3JH-MHN	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P3JH-MHN)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0707	Mathurin Joseph  Chevallier	male	1580	\N	PL-115037	1625	\N	PL-115038	med	public	Pouliot	P3JH-HX8	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P3JH-HX8)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0708	Anne Marie Meronache Mesange EOL	female	about 1585	\N	PL-115037	15 December 1625	\N	PL-115425	med	public	Pouliot	P3J4-BMV	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P3J4-BMV)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0709	Rene Le Monnier	male	about 1579	\N	PL-79577	after 3 November 1647	\N	PL-22281	high	public	Pouliot	LTRG-TLZ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LTRG-TLZ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0710	Marie Le Roux	female	3 February 1579	\N	PL-116200	\N	\N	PL-22281	high	public	Pouliot	LRSQ-6B4	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRSQ-6B4)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0711	Jean Fafart	male	\N	\N	PL-22281	\N	\N	\N	high	public	Pouliot	LRJN-SYY	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRJN-SYY)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0712	Elisabeth Tibou	female	\N	\N	PL-22281	after 3 November 1647	\N	PL-22281	high	public	Pouliot	LR15-YH4	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LR15-YH4)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0713	Jeanne Anna Magdalena Le Rouge Lue Roig	female	6 September 1565	\N	PL-117365	28 November 1618	\N	PL-117366	high	public	Pouliot	P3J4-G9H	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P3J4-G9H)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0714	Jehan Le Roux	male	1545	\N	PL-117757	1583	\N	PL-117757	med	public	Pouliot	PCX7-9TF	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PCX7-9TF)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0715	Guyonne Bourgault	female	1555	\N	PL-117757	1583	\N	PL-117757	med	public	Pouliot	PCXQ-J9C	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PCXQ-J9C)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0716	Michaellis Roig	male	about 1540	\N	PL-118540	\N	\N	\N	high	public	Pouliot	P3PX-KGZ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P3PX-KGZ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0717	Anne Roig	female	\N	\N	PL-118540	\N	\N	\N	high	public	Pouliot	P3PX-BB1	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P3PX-BB1)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0718	Jean Chabot	male	about 1607	\N	PL-95620	6 July 1653	\N	PL-81527	high	public	Pouliot	LB5Y-7V4	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LB5Y-7V4)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0719	Jeanne Rodé	female	26 March 1619	\N	PL-81527	about 16 October 1664	\N	PL-81527	high	public	Pouliot	LZN1-56V	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZN1-56V)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0720	Robert Mesange	male	about 1620	\N	\N	after 17 November 1661	\N	PL-22281	high	public	Pouliot	LZ6K-PWS	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LZ6K-PWS)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0721	Madeleine Le Houx	female	November 1620	\N	PL-99225	after 17 November 1661	\N	PL-22281	high	public	Pouliot	LRKZ-JMP	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRKZ-JMP)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0722	Yves Henault	male	1600	\N	PL-120893	8 August 1662	\N	\N	med	public	Pouliot	PWHF-6JL	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PWHF-6JL)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0724	Jean Macre	male	1605	\N	PL-121680	\N	\N	\N	med	public	Pouliot	LR5M-DCV	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LR5M-DCV)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0725	Barbe Landry	female	1600	\N	PL-122075	\N	\N	\N	med	public	Pouliot	LRJ7-DPY	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRJ7-DPY)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0726	Jacques Chabot	male	10 April 1568	\N	PL-122471	6 July 1653	\N	PL-122471	high	public	Pouliot	LHD5-B7C	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LHD5-B7C)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0727	Jeanne Jacques	female	1578	\N	PL-85197	1662	\N	PL-122471	med	public	Pouliot	GW8L-6KC	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GW8L-6KC)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0728	Denis Rodé	male	about 1595	\N	PL-22281	10 March 1650	\N	\N	high	public	Pouliot	MVJN-XGN	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MVJN-XGN)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0729	Françoise Gouin	female	about 1596	\N	PL-22281	10 March 1650	\N	\N	high	public	Pouliot	MVJN-XG5	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MVJN-XG5)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0730	Robert Mesange	male	1571	\N	PL-84859	\N	\N	\N	med	public	Pouliot	KCPJ-DYL	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KCPJ-DYL)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0731	Madeleine Jahan	female	1573	\N	PL-103269	\N	\N	\N	med	public	Pouliot	KLY3-NWS	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KLY3-NWS)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0732	Jaques Le Houx	male	about 1580	\N	PL-124848	16 February 1680	\N	PL-18603	high	public	Pouliot	LY4L-ZK2	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LY4L-ZK2)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0733	Marie Meilleur	female	about 1596	\N	PL-125246	before 9 February 1633	\N	PL-125246	high	public	Pouliot	LRB2-H8W	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LRB2-H8W)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0734	End Henault ( Enaud )	male	\N	\N	\N	\N	\N	\N	med	public	Pouliot	PZ4L-QVG	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PZ4L-QVG)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0735	End Galiot	male	\N	\N	\N	\N	\N	\N	med	public	Pouliot	PZ42-D1C	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PZ42-D1C)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0736	Jacques Chabot	male	28 October 1548	\N	PL-85197	1596	\N	PL-122471	high	public	Pouliot	L1R3-TPG	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L1R3-TPG)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0737	Anne Auphily	female	1550	\N	PL-90695	1573	\N	\N	med	public	Pouliot	KZVQ-JT5	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KZVQ-JT5)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0738	Pierre Jacques	male	1550	\N	\N	1612	\N	\N	med	public	Pouliot	2DXL-RZ2	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 2DXL-RZ2)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0739	Jeanne Dissert	female	1555	\N	PL-90695	1612	\N	PL-122471	med	public	Pouliot	2DXL-R47	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: 2DXL-R47)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0740	Jean Rodé	male	1580	\N	PL-128033	1634	\N	\N	med	public	Pouliot	GY4V-3TK	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GY4V-3TK)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0741	Françoise Galland	female	1585	\N	PL-128433	1605	\N	PL-128433	med	public	Pouliot	GDVN-HVT	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GDVN-HVT)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0742	Thomas Nicolas Lehoux	male	1560	\N	PL-81856	1599	\N	PL-81856	high	public	Pouliot	GP7D-F87	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GP7D-F87)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0743	Jacqueline Geffray	female	about 1564	\N	PL-81856	17 April 1649	\N	PL-81856	high	public	Pouliot	GL38-F8X	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GL38-F8X)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0744	Jehan Audet	male	1580	\N	PL-18742	13 February 1634	\N	PL-129634	high	public	Pouliot	MLFS-BY2	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MLFS-BY2)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0745	Andrée Barreau	female	1580	\N	PL-130036	1641	\N	PL-43544	high	public	Pouliot	GLQW-5WP	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GLQW-5WP)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0746	Pierre Roy	male	about 1578	\N	PL-130439	27 June 1643	\N	PL-130440	high	public	Pouliot	L6PX-DXX	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L6PX-DXX)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0747	Perrine Boutin	female	15 September 1586	\N	PL-93141	23 August 1631	\N	PL-130440	high	public	Pouliot	G2NV-QD3	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G2NV-QD3)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0748	Etienne Jehan Barreau	male	21 January 1556	\N	PL-131249	November 1614	\N	PL-131249	high	public	Pouliot	GR6X-P9M	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GR6X-P9M)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0749	Antoinette Picard	female	15 January 1560	\N	PL-131249	1615	\N	PL-131249	med	public	Pouliot	GKTC-JSZ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GKTC-JSZ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0750	Jean Louis Boutin	male	1544	\N	PL-132060	1597	\N	PL-132060	high	public	Pouliot	L2TV-4BJ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L2TV-4BJ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0751	Marie Louise Germont	female	1544	\N	PL-132467	1599	\N	PL-132468	med	public	Pouliot	L63F-W79	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L63F-W79)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0752	Louis Barreau	male	1529	\N	PL-22281	\N	\N	\N	med	public	Pouliot	GPMT-QJ6	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GPMT-QJ6)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0753	Charlotte Giton	female	\N	\N	\N	\N	\N	\N	med	public	Pouliot	GPMT-4TJ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GPMT-4TJ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0754	AnSe	female	\N	\N	\N	\N	\N	\N	med	public	Pouliot	GR6X-Y4Z	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GR6X-Y4Z)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0755	Louis Boutin	male	1521	\N	PL-132060	1549	\N	PL-132060	high	public	Pouliot	L63F-W7Y	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L63F-W7Y)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0756	Marie Guillebault	female	1519	\N	PL-132060	1563	\N	PL-132060	high	public	Pouliot	L63F-WHP	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L63F-WHP)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0757	Pierre Roux Dufresne	male	1600	\N	PL-83182	1635	\N	PL-83182	high	public	Pouliot	GD74-CN6	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GD74-CN6)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0758	Phoébé Pique	female	1600	\N	PL-135325	1645	\N	PL-135325	med	public	Pouliot	P3NH-Z2J	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P3NH-Z2J)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0759	Louis Patin	male	12 September 1600	\N	PL-135735	1634	\N	PL-135735	med	public	Pouliot	GD74-MDW	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GD74-MDW)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0760	Louise Magnan	female	1602	\N	PL-104760	1634	\N	PL-135735	med	public	Pouliot	P3N4-VG7	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P3N4-VG7)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0761	Loys Dufresnoy	male	about 1580	\N	PL-22281	before October 1601	\N	PL-22281	med	public	Pouliot	P3N4-KRY	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P3N4-KRY)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0762	Marie Pirenne	female	about 1580	\N	PL-22281	before 1621	\N	\N	med	public	Pouliot	P3NH-3F8	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P3NH-3F8)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0763	Pieter Pierre Pattyn	male	about 1568	\N	PL-137376	15 October 1629	\N	PL-137377	med	public	Pouliot	GDQJ-9HK	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GDQJ-9HK)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0764	Catharine de Bouchette	female	1568	\N	PL-137376	26 January 1646	\N	PL-137377	med	public	Pouliot	L5YL-63F	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L5YL-63F)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0765	Paul Crepeau	male	1573	\N	PL-22281	1653	\N	\N	med	public	Pouliot	GCXL-JBQ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GCXL-JBQ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0766	Marie Rose Claire Audet	female	28 August 1582	\N	PL-34500	4 January 1675	\N	PL-34500	med	public	Pouliot	GPCG-TLK	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GPCG-TLK)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0767	Louis Fumolloau	male	about 1580	\N	PL-36668	15 December 1628	\N	PL-36668	high	public	Pouliot	GPCG-RVJ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GPCG-RVJ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0768	Marie Jouet	female	1585	\N	PL-22281	\N	\N	\N	med	public	Pouliot	PQBF-GLP	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PQBF-GLP)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0769	Verdière	male	\N	\N	\N	\N	\N	\N	med	public	Pouliot	GR84-KPX	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GR84-KPX)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0770	Marie Jean Granjean	female	15 July 1599	\N	PL-140262	1654	\N	PL-100321	med	public	Pouliot	GR84-WKT	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GR84-WKT)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0771	Joseph Laliot Leliot Le Cat	male	1585	\N	PL-22281	\N	\N	\N	med	public	Pouliot	G666-QLF	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G666-QLF)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0772	Marie Leliot	female	1595	\N	PL-141089	\N	\N	\N	med	public	Pouliot	G666-M85	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G666-M85)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0773	Denis Pattyn	male	about 1518	\N	PL-137376	about 1600	\N	PL-137376	med	public	Pouliot	GDQJ-W4L	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GDQJ-W4L)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0774	Catherine Van Paemele	female	1526	\N	PL-137376	\N	\N	PL-137376	med	public	Pouliot	GDQJ-Z27	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GDQJ-Z27)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0775	Jean Van Bouchette	male	1540	\N	PL-137376	1633	\N	PL-137376	med	public	Pouliot	GH81-ZVQ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GH81-ZVQ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0776	Catherine	female	about 1543	\N	PL-142746	\N	\N	\N	med	public	Pouliot	GLQV-4ZD	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GLQV-4ZD)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0777	Maurice Crepeau	male	25 November 1537	\N	PL-143162	8 September 1604	\N	PL-143163	med	public	Pouliot	GD74-H6K	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GD74-H6K)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0779	Jacquemine de Servaude	female	about 1550	\N	PL-144000	\N	\N	\N	med	public	Pouliot	KVL7-KG3	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KVL7-KG3)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0780	Michel Godebout	male	24 March 1605	\N	PL-83516	1680	\N	PL-37480	high	public	Pouliot	LJH5-Y3H	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LJH5-Y3H)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0781	Colette Caron	female	1605	\N	PL-83182	1680	\N	PL-83182	high	public	Pouliot	LJHP-YK7	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LJHP-YK7)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0782	Jean Bourgoin	male	23 September 1618	\N	PL-145258	15 October 1646	\N	PL-145259	high	public	Pouliot	MNT4-YMN	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: MNT4-YMN)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0783	Marie Lefebvre	female	\N	\N	PL-22281	after 9 January 1662	\N	PL-145681	high	public	Pouliot	LH7D-GYT	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LH7D-GYT)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0787	Marguerite Guillebourdeau	female	about 1620	\N	PL-147372	20 October 1662	\N	PL-21206	high	public	Pouliot	G8C2-PGX	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G8C2-PGX)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0788	Nicolas Godbout	male	1573	\N	PL-83516	1660	\N	PL-83516	med	public	Pouliot	G1VT-9TD	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G1VT-9TD)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0789	Suzanne Gaudebout	female	1565	\N	PL-83516	1670	\N	PL-148221	med	public	Pouliot	G1VT-9ZW	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G1VT-9ZW)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0790	Gemmet Bourgoin	male	about 1590	\N	PL-22281	\N	\N	\N	med	public	Pouliot	G1VT-LHQ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G1VT-LHQ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0791	Marie Bedu	female	1600	\N	PL-148221	1645	\N	PL-22281	med	public	Pouliot	PSYY-JF9	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PSYY-JF9)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0792	Jean Le Fèbvre	male	about 1575	\N	PL-149497	December 1646	\N	PL-149498	high	public	Pouliot	GQWL-8YB	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GQWL-8YB)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0793	Jeanne Doubleau	female	about 1580	\N	PL-149498	December 1646	\N	PL-149498	high	public	Pouliot	LR9B-KDH	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LR9B-KDH)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0794	Louis Baillargeon	male	1580	\N	PL-150353	20 November 1649	\N	PL-150353	med	public	Pouliot	GGXT-NTX	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GGXT-NTX)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0795	Marthe Fovier	female	1585	\N	PL-150353	1650	\N	PL-150353	high	public	Pouliot	LT7K-55D	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LT7K-55D)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0796	Louis Guillebourday	male	1585	\N	PL-151210	1631	\N	PL-147372	high	public	Pouliot	LR9S-VR2	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LR9S-VR2)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0797	Marie Maguin	female	1601	\N	PL-151640	1650	\N	PL-151641	high	public	Pouliot	KDW6-L2Q	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KDW6-L2Q)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0798	Michel Godbout	male	1527	\N	PL-5426	about 1580	\N	PL-5426	high	public	Pouliot	PSYY-VLF	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PSYY-VLF)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0799	Jeanne Gay	female	1531	\N	PL-83182	\N	\N	PL-37480	med	public	Pouliot	KLQC-88V	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: KLQC-88V)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0800	Edward Bedu	male	24 March 1570	\N	PL-22281	\N	\N	\N	med	public	Pouliot	G1VT-HNZ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G1VT-HNZ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0801	Rollin Lefèbvre	male	1550	\N	PL-104760	\N	\N	\N	med	public	Pouliot	GZV8-FR2	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GZV8-FR2)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0802	Marguerite Louise Prevost	female	26 June 1562	\N	PL-22281	14 April 1612	\N	PL-36870	med	public	Pouliot	GZV8-V8W	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GZV8-V8W)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0803	Nicolas Pierre Doubleau	male	about 1550	\N	PL-56669	about 1620	\N	PL-22281	med	public	Pouliot	G1VT-9CN	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G1VT-9CN)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0804	Jeanne	female	about 1560	\N	PL-56669	about 1650	\N	\N	med	public	Pouliot	PSYY-KKG	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PSYY-KKG)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0805	Francois Charles Baillargeon	male	1560	\N	PL-155090	\N	\N	PL-155090	med	public	Pouliot	GYTG-L4S	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GYTG-L4S)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0806	Marie Anne Bouffard	female	1562	\N	PL-155090	20 November 1649	\N	PL-155090	med	public	Pouliot	GYTG-LPP	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GYTG-LPP)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0807	Ancetre Maguin	male	about 1585	\N	PL-22281	\N	\N	\N	med	public	Pouliot	L6QM-TDY	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L6QM-TDY)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0808	Madame Maguin	female	\N	\N	\N	\N	\N	\N	med	public	Pouliot	L6QM-T6C	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: L6QM-T6C)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0809	Sébastien Rouleau	male	1598	\N	\N	1618	\N	PL-84859	high	public	Pouliot	GM5J-KFN	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GM5J-KFN)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0810	Catherine Sauvage	female	1598	\N	PL-103269	29 July 1618	\N	PL-84859	med	public	Pouliot	GM5J-3RC	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GM5J-3RC)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0811	Anthoine Leroux	male	about 1610	\N	PL-157683	\N	\N	\N	high	public	Pouliot	GDRV-PVR	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GDRV-PVR)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0812	Jeanne Jouary	female	16 April 1607	\N	PL-22281	1655	\N	\N	high	public	Pouliot	LYXW-2GG	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LYXW-2GG)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0813	Antoine Rouleau	male	1575	\N	\N	1673	\N	\N	med	public	Pouliot	GHNH-FBM	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GHNH-FBM)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0814	Jeanne Genevieve Godbout	female	about 1578	\N	PL-22281	\N	\N	\N	med	public	Pouliot	LWBB-W1S	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LWBB-W1S)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0815	Jacques Sauvage II	male	1575	\N	PL-159416	1672	\N	PL-159417	high	public	Pouliot	LHTM-SR2	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LHTM-SR2)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0816	Marie Catherine Jean dite Vien	female	1576	\N	PL-22281	1670	\N	PL-22281	med	public	Pouliot	GHNH-GX5	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GHNH-GX5)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0817	Pierre Le Roux	male	about 1585	\N	PL-160288	\N	\N	\N	med	public	Pouliot	GLSW-814	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GLSW-814)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0818	Guillame Joiry	male	1590	\N	PL-160725	1619	\N	PL-160726	high	public	Pouliot	GZ2G-HLF	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GZ2G-HLF)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0819	Marthurine Mercier	female	1595	\N	PL-160726	19 May 1635	\N	PL-161165	high	public	Pouliot	GZ2G-NWJ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GZ2G-NWJ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0820	Antoine Rouleau	male	1549	\N	PL-37480	1598	\N	PL-22281	med	public	Pouliot	G11S-V4F	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G11S-V4F)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0821	Genevieve Godbout	female	1545	\N	PL-22281	after 1598	\N	PL-22281	med	public	Pouliot	G113-9BQ	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G113-9BQ)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0822	Antoine Godbout	male	1515	\N	PL-22281	\N	\N	\N	high	public	Pouliot	G1F5-87Y	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G1F5-87Y)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0823	Elizabeth Godbout	female	1519	\N	PL-22281	\N	\N	\N	med	public	Pouliot	G1F5-S67	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G1F5-S67)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0824	Guillaume Joiry	male	1565	\N	PL-160725	\N	\N	PL-163361	high	public	Pouliot	GZGB-MD9	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GZGB-MD9)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0825	Roulline Nogues	female	1570	\N	PL-163802	1612	\N	PL-163803	high	public	Pouliot	GZGY-B5V	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GZGY-B5V)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0826	Andre Jacques Mercier	male	5 November 1570	\N	PL-164246	18 October 1676	\N	PL-145259	high	public	Pouliot	G3TX-JKG	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: G3TX-JKG)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0827	Marie Roberte Cornilleau	female	1570	\N	PL-164246	12 January 1627	\N	PL-84859	high	public	Pouliot	LVZM-Q7B	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: LVZM-Q7B)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0828	FILIPPO BONAGUIDI	male	\N	\N	\N	\N	\N	\N	med	public	Maternal Mariotti	PHMQ-1KC	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PHMQ-1KC)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0829	BARTOLOMEO RICCI	male	\N	\N	PL-165576	\N	\N	\N	med	public	Maternal Mariotti	PHMQ-LNW	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PHMQ-LNW)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0831	Maria	female	\N	\N	\N	27 February 1641	\N	PL-38717	med	public	Maternal Mariotti	PMCB-26H	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PMCB-26H)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0832	Santi Arcangeli	male	27 June 1596	\N	PL-38717	5 December 1672	\N	PL-38717	med	public	Maternal Mariotti	P4N7-2J4	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P4N7-2J4)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0833	Pasqua	female	\N	\N	\N	\N	\N	\N	med	public	Maternal Mariotti	PHMC-P6X	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PHMC-P6X)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0835	Salvadore Arcangeli	male	\N	\N	\N	11 February 1641	\N	PL-38717	med	public	Maternal Mariotti	P4N7-H6G	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: P4N7-H6G)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0836	Maria Domenica	female	\N	\N	PL-38717	28 July 1659	\N	PL-38717	med	public	Maternal Mariotti	PHMH-BKX	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PHMH-BKX)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0837	Domenico	male	\N	\N	\N	\N	\N	\N	med	public	Maternal Mariotti	PHMC-N1W	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PHMC-N1W)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0839	Elena	female	\N	\N	\N	\N	\N	\N	med	public	Maternal Mariotti	GYT2-ZF5	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: GYT2-ZF5)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0840	Giorgio Arcangeli	male	\N	\N	\N	\N	\N	\N	med	public	Maternal Mariotti	PHMC-7P1	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PHMC-7P1)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0841	Francesco da Momigno	male	\N	\N	\N	\N	\N	\N	med	public	Maternal Mariotti	PHMC-FPP	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PHMC-FPP)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
P-0842	Salvatore Arcangeli	male	\N	\N	\N	\N	\N	\N	med	public	Maternal Mariotti	PHMC-K3B	Imported from FamilySearch extract on 2026-05-30.	\N	FamilySearch (FS PID: PHMC-K3B)	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:45.452511-05
\.


--
-- Data for Name: person_name; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.person_name (id, person_id, name_type, value, is_primary, notes, created_at) FROM stdin;
1	P-0004	primary	Elizabeth (Willey) Reed	t	\N	2026-05-30 09:42:59.684442-05
2	P-0002	primary	Rebecca (Talley) Reed	t	\N	2026-05-30 09:42:59.684442-05
3	P-0036	primary	Estelle Gertrude Lambert	t	\N	2026-05-30 09:42:59.684442-05
4	P-0068	primary	Beatrice Delina Pouliot	t	\N	2026-05-30 09:42:59.684442-05
6	P-0072	primary	Abiram Stacy Lambert	t	\N	2026-05-30 09:42:59.684442-05
7	P-0012	primary	Helen Amelia (Boles) Lambert	t	\N	2026-05-30 09:42:59.684442-05
8	P-0046	primary	Hannah Paulson	t	\N	2026-05-30 09:42:59.684442-05
9	P-0052	primary	Elizabeth Allen	t	\N	2026-05-30 09:42:59.684442-05
10	P-0051	primary	Benjamin Thorla	t	\N	2026-05-30 09:42:59.684442-05
11	P-0038	primary	James Willey	t	\N	2026-05-30 09:42:59.684442-05
12	P-0042	primary	Stephen Reed	t	\N	2026-05-30 09:42:59.684442-05
13	P-0047	primary	Samuel R Barnard	t	\N	2026-05-30 09:42:59.684442-05
14	P-0044	primary	Else Alice Bonham	t	\N	2026-05-30 09:42:59.684442-05
15	P-0129	primary	Absalom Willey	t	\N	2026-05-30 09:42:59.684442-05
16	P-0043	primary	Mary Polly Cook	t	\N	2026-05-30 09:42:59.684442-05
17	P-0039	primary	Emily Thorla	t	\N	2026-05-30 09:42:59.684442-05
18	P-0050	primary	Sarah Dye	t	\N	2026-05-30 09:42:59.684442-05
19	P-0049	primary	William Polk Willey	t	\N	2026-05-30 09:42:59.684442-05
20	P-0142	primary	Deacon Francis Barnard	t	\N	2026-05-30 09:42:59.684442-05
21	P-0048	primary	Roxana Desire Barnard	t	\N	2026-05-30 09:42:59.684442-05
22	P-0041	primary	Sarah Dickerson	t	\N	2026-05-30 09:42:59.684442-05
23	P-0040	primary	Benjamin Reed	t	\N	2026-05-30 09:42:59.684442-05
24	P-0045	primary	John Foulk Talley	t	\N	2026-05-30 09:42:59.684442-05
25	P-0078	primary	Paul Pouliot	t	\N	2026-05-30 09:42:59.684442-05
26	P-0076	primary	Henriette St. Louis	t	\N	2026-05-30 09:42:59.684442-05
27	P-0075	primary	Anton Zika	t	\N	2026-05-30 09:42:59.684442-05
28	P-0064	primary	John Francis Zika	t	\N	2026-05-30 09:42:59.684442-05
29	P-0055	primary	Leah Rae Mariotti	t	\N	2026-05-30 09:42:59.684442-05
30	P-0056	primary	John Ronald Reed Sr	t	\N	2026-05-30 09:42:59.684442-05
31	P-0058	primary	Isabelle Harriet Zika	t	\N	2026-05-30 09:42:59.684442-05
32	P-0164	primary	UMILTA' GIACOMELLI	t	\N	2026-05-30 09:42:59.684442-05
33	P-0163	primary	PIER DOMENICO NICCOLAI	t	\N	2026-05-30 09:42:59.684442-05
34	P-0066	primary	Zelinda Pagni	t	\N	2026-05-30 09:42:59.684442-05
35	P-0059	primary	Ugo Mariotti	t	\N	2026-05-30 09:42:59.684442-05
36	P-0060	primary	Lena  A Dini	t	\N	2026-05-30 09:42:59.684442-05
37	P-0083	primary	Rebecca Talley	t	\N	2026-05-30 09:42:59.684442-05
38	P-0082	primary	Bonam Reed	t	\N	2026-05-30 09:42:59.684442-05
39	P-0061	primary	John Foulk Reed	t	\N	2026-05-30 09:42:59.684442-05
40	P-0074	primary	Helen Amelia Boles	t	\N	2026-05-30 09:42:59.684442-05
41	P-0071	primary	Elizabeth Willey	t	\N	2026-05-30 09:42:59.684442-05
42	P-0088	primary	Marie Anna Říhová	t	\N	2026-05-30 09:42:59.684442-05
43	P-0087	primary	František Zíka	t	\N	2026-05-30 09:42:59.684442-05
44	P-0069	primary	Quintilia Lenzi	t	\N	2026-05-30 09:42:59.684442-05
45	P-0067	primary	Leopoldo Mariotti	t	\N	2026-05-30 09:42:59.684442-05
46	P-0070	primary	John Talley Reed	t	\N	2026-05-30 09:42:59.684442-05
47	P-0162	primary	Maria Pasqua Baldi	t	\N	2026-05-30 09:42:59.684442-05
48	P-0161	primary	Giovan Pietro Spadoni	t	\N	2026-05-30 09:42:59.684442-05
49	P-0122	primary	ANGIOLO NICCOLAI	t	\N	2026-05-30 09:42:59.684442-05
50	P-0120	primary	MARIA UMILTA' PORCIANI	t	\N	2026-05-30 09:42:59.684442-05
51	P-0118	primary	Maria Angiola Ercolini	t	\N	2026-05-30 09:42:59.684442-05
52	P-0117	primary	Pier Domenico Spadoni	t	\N	2026-05-30 09:42:59.684442-05
53	P-0099	primary	Giovanni Dini	t	\N	2026-05-30 09:42:59.684442-05
54	P-0155	primary	Marie Louise St-Mars	t	\N	2026-05-30 09:42:59.684442-05
55	P-0154	primary	Pierre Pouliot	t	\N	2026-05-30 09:42:59.684442-05
56	P-0153	primary	Genevieve Godbout	t	\N	2026-05-30 09:42:59.684442-05
57	P-0111	primary	Therese Denis Lapierre	t	\N	2026-05-30 09:42:59.684442-05
58	P-0091	primary	Francois Pouliot	t	\N	2026-05-30 09:42:59.684442-05
59	P-0079	primary	Angiolo Pagni	t	\N	2026-05-30 09:42:59.684442-05
60	P-0080	primary	Maria Emilia Dini	t	\N	2026-05-30 09:42:59.684442-05
61	P-0131	primary	Deliverance Owen	t	\N	2026-05-30 09:42:59.684442-05
62	P-0144	primary	Jonathan Abel Oakes	t	\N	2026-05-30 09:42:59.684442-05
63	P-0138	primary	Sherebiah Lambert Sr.	t	\N	2026-05-30 09:42:59.684442-05
64	P-0106	primary	Permelia "Millie" Oaks	t	\N	2026-05-30 09:42:59.684442-05
65	P-0105	primary	Sherebiah Lambert Jr	t	\N	2026-05-30 09:42:59.684442-05
66	P-0085	primary	Permelia Barnard	t	\N	2026-05-30 09:42:59.684442-05
67	P-0084	primary	David Lambert	t	\N	2026-05-30 09:42:59.684442-05
68	P-0092	primary	Martha Lovina Spears	t	\N	2026-05-30 09:42:59.684442-05
69	P-0086	primary	Silas A. Boles	t	\N	2026-05-30 09:42:59.684442-05
70	P-0157	primary	Marie Angelique Pépin dit Lachance	t	\N	2026-05-30 09:42:59.684442-05
71	P-0113	primary	Marie Louise Tremblay	t	\N	2026-05-30 09:42:59.684442-05
72	P-0112	primary	Michel Olivier Audet	t	\N	2026-05-30 09:42:59.684442-05
73	P-0094	primary	Julie Audet dit Lapointe	t	\N	2026-05-30 09:42:59.684442-05
74	P-0100	primary	Maria Cristiana Niccolai	t	\N	2026-05-30 09:42:59.684442-05
75	P-0095	primary	Domenico Dini	t	\N	2026-05-30 09:42:59.684442-05
76	P-0146	primary	Františka Doležalová	t	\N	2026-05-30 09:42:59.684442-05
77	P-0145	primary	Jan Zíka	t	\N	2026-05-30 09:42:59.684442-05
78	P-0114	primary	Marie Zemanová	t	\N	2026-05-30 09:42:59.684442-05
79	P-0109	primary	František Říha	t	\N	2026-05-30 09:42:59.684442-05
80	P-0108	primary	Barbora Michalíčková	t	\N	2026-05-30 09:42:59.684442-05
81	P-0110	primary	Pierre Pouliot	t	\N	2026-05-30 09:42:59.684442-05
82	P-0123	primary	Priscilla Foulk	t	\N	2026-05-30 09:42:59.684442-05
83	P-0124	primary	Harman Talley	t	\N	2026-05-30 09:42:59.684442-05
84	P-0125	primary	Sarah Brown	t	\N	2026-05-30 09:42:59.684442-05
85	P-0127	primary	Richard R. Dickerson Sr.	t	\N	2026-05-30 09:42:59.684442-05
86	P-0128	primary	Simon Poulson lll	t	\N	2026-05-30 09:42:59.684442-05
87	P-0130	primary	Margaret Polk	t	\N	2026-05-30 09:42:59.684442-05
88	P-0135	primary	Elizabeth Lemley	t	\N	2026-05-30 09:42:59.684442-05
89	P-0132	primary	Benjamin Dye	t	\N	2026-05-30 09:42:59.684442-05
90	P-0133	primary	John Thomas Thurlow Jr	t	\N	2026-05-30 09:42:59.684442-05
91	P-0134	primary	Asher Allen	t	\N	2026-05-30 09:42:59.684442-05
92	P-0136	primary	Lydia Hopkins	t	\N	2026-05-30 09:42:59.684442-05
93	P-0137	primary	Elizabeth Polly Palmer	t	\N	2026-05-30 09:42:59.684442-05
94	P-0140	primary	Abigail Whitney Rand	t	\N	2026-05-30 09:42:59.684442-05
95	P-0141	primary	Edward Ebenezer Barnard	t	\N	2026-05-30 09:42:59.684442-05
96	P-0143	primary	Lucretia Carroll Pinney	t	\N	2026-05-30 09:42:59.684442-05
97	P-0156	primary	Jacques Denis	t	\N	2026-05-30 09:42:59.684442-05
98	P-0159	primary	Jacques Tremblay	t	\N	2026-05-30 09:42:59.684442-05
99	P-0158	primary	Guillaume Audet	t	\N	2026-05-30 09:42:59.684442-05
100	P-0160	primary	Marie Angelique Delage	t	\N	2026-05-30 09:42:59.684442-05
101	P-0053	primary	Edward Kenny	t	\N	2026-05-30 09:42:59.684442-05
102	P-0166	primary	CATERINA PARLANTI	t	\N	2026-05-30 09:42:59.684442-05
103	P-0165	primary	GIUSEPPE PORCIANI	t	\N	2026-05-30 09:42:59.684442-05
104	P-0152	primary	Magdalena Říhová	t	\N	2026-05-30 09:42:59.684442-05
105	P-0151	primary	Magdalena Dufková	t	\N	2026-05-30 09:42:59.684442-05
106	P-0150	primary	Václav Říha	t	\N	2026-05-30 09:42:59.684442-05
107	P-0149	primary	Eva Zemanová	t	\N	2026-05-30 09:42:59.684442-05
108	P-0148	primary	František Jan Michalíček	t	\N	2026-05-30 09:42:59.684442-05
109	P-0147	primary	Antonín Zeman	t	\N	2026-05-30 09:42:59.684442-05
110	P-0139	primary	Mabel Pinney	t	\N	2026-05-30 09:42:59.684442-05
111	P-0126	primary	Ann Patton	t	\N	2026-05-30 09:42:59.684442-05
112	P-0121	primary	Carlo Dini	t	\N	2026-05-30 09:42:59.684442-05
113	P-0119	primary	Annunziata Grossi	t	\N	2026-05-30 09:42:59.684442-05
114	P-0116	primary	Elisabetta Giovacchini	t	\N	2026-05-30 09:42:59.684442-05
115	P-0115	primary	Pietro Dini	t	\N	2026-05-30 09:42:59.684442-05
116	P-0107	primary	Martin Zíka	t	\N	2026-05-30 09:42:59.684442-05
117	P-0104	primary	Thomas Spear	t	\N	2026-05-30 09:42:59.684442-05
118	P-0103	primary	Nancy Walls	t	\N	2026-05-30 09:42:59.684442-05
119	P-0102	primary	Pellegrino Giorgi	t	\N	2026-05-30 09:42:59.684442-05
120	P-0101	primary	Piera Bellandi	t	\N	2026-05-30 09:42:59.684442-05
121	P-0098	primary	Leopoldo Pagni	t	\N	2026-05-30 09:42:59.684442-05
122	P-0097	primary	Henriette Cheffre	t	\N	2026-05-30 09:42:59.684442-05
123	P-0096	primary	Pasqua Rosa Spadoni	t	\N	2026-05-30 09:42:59.684442-05
124	P-0093	primary	Joseph Filiatrault dit St. Louis	t	\N	2026-05-30 09:42:59.684442-05
125	P-0090	primary	František Říha	t	\N	2026-05-30 09:42:59.684442-05
126	P-0089	primary	Františka Klusová	t	\N	2026-05-30 09:42:59.684442-05
127	P-0081	primary	Cherubina Giorgi	t	\N	2026-05-30 09:42:59.684442-05
128	P-0077	primary	Josephine Riha Veta	t	\N	2026-05-30 09:42:59.684442-05
129	P-0073	primary	Celestino Dini	t	\N	2026-05-30 09:42:59.684442-05
130	P-0065	primary	Louis Dini	t	\N	2026-05-30 09:42:59.684442-05
131	P-0057	primary	Laura Kroll	t	\N	2026-05-30 09:42:59.684442-05
132	P-0054	primary	Phyllis Kroll	t	\N	2026-05-30 09:42:59.684442-05
133	P-0062	primary	Earl Wayne Reed Sr	t	\N	2026-05-30 09:42:59.684442-05
134	P-0033	primary	James G. Reed	t	\N	2026-05-30 09:42:59.684442-05
135	P-0031	primary	Earl Wayne Reed Jr.	t	\N	2026-05-30 09:42:59.684442-05
136	P-0028	primary	Henriette (Cheffre) Filiatrault	t	\N	2026-05-30 09:42:59.684442-05
139	P-0020	primary	Josefína “Josie” (Říha) Zika	t	\N	2026-05-30 09:42:59.684442-05
140	P-0019	primary	Anton Zika	t	\N	2026-05-30 09:42:59.684442-05
141	P-0018	primary	Permelia M. Oak	t	\N	2026-05-30 09:42:59.684442-05
142	P-0016	primary	Lydia A. (Hopkins) Lambert	t	\N	2026-05-30 09:42:59.684442-05
143	P-0013	primary	Silas P. Boles	t	\N	2026-05-30 09:42:59.684442-05
144	P-0010	primary	Permelia (Barnard) Lambert	t	\N	2026-05-30 09:42:59.684442-05
145	P-0035	primary	Emma Rebecca Reed	t	\N	2026-05-30 09:42:59.684442-05
146	P-0167	primary	Gerald Arthur Kenny	t	\N	2026-05-30 12:22:59.199698-05
147	P-0168	primary	John Kenny	t	\N	2026-05-30 12:30:44.345343-05
148	P-0843	primary	Permelia (Oak) Lambert	t	\N	2026-05-30 16:02:41.376154-05
149	P-0843	maiden	Permelia Oak	f	\N	2026-05-30 16:02:41.376154-05
150	P-0843	variant	Pamelia Lambert	f	\N	2026-05-30 16:02:41.376154-05
\.


--
-- Data for Name: place; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.place (place_id, name, std_name, geom, admin_hierarchy, geocode_quality, created_at, updated_at, historical_name, notes, time_valid_from, time_valid_to) FROM stdin;
PL-5245	Hopewell Township, Hunterdon, New Jersey, United States	Hopewell Township, Hunterdon, New Jersey, United States	0101000020E6100000FE43FAEDEBB052C00BB5A679C7314440	\N	township	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5247	Trenton, Mercer, New Jersey, United States	Trenton, Mercer, New Jersey, United States	0101000020E61000009BE61DA7E8B052C031992A18951C4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5248	Hopewell Township, Hunterdon, New Jersey, British Colonial America	Hopewell Township, Hunterdon, New Jersey, British Colonial America	0101000020E6100000FE43FAEDEBB052C00BB5A679C7314440	\N	township	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5252	Hunterdon, New Jersey, British Colonial America	Hunterdon, New Jersey, British Colonial America	0101000020E61000000B98C0ADBBBB52C0EACF7EA488484440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5257	New Jersey, British Colonial America	New Jersey, British Colonial America	0101000020E61000000000000000A052C0F6285C8FC2154440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5263	Morris Township, Washington, Pennsylvania, United States	Morris Township, Washington, Pennsylvania, United States	0101000020E6100000894160E5D01254C0DBF97E6ABC044440	\N	township	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5270	Frederick, Frederick, Maryland, United States	Frederick, Frederick, Maryland, United States	0101000020E6100000CE8DE9094B5A53C0FE7DC68503B54340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5299	Maidenhead, Maidenhead Township, Hunterdon, New Jersey, United States	Maidenhead, Maidenhead Township, Hunterdon, New Jersey, United States	0101000020E61000001F85EB51B8AE52C0832F4CA60A264440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5300	Burlington, New Jersey, United States	Burlington, New Jersey, United States	0101000020E6100000C2340C1F11A952C0B0C91AF510F14340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5310	Woodbridge Township, Middlesex, New Jersey, United States	Woodbridge Township, Middlesex, New Jersey, United States	0101000020E6100000910F7A36AB9252C0545227A089484440	\N	township	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5311	Hopewell Township, Mercer, New Jersey, United States	Hopewell Township, Mercer, New Jersey, United States	0101000020E6100000FE43FAEDEBB052C00BB5A679C7314440	\N	township	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5356	Charles, Maryland, British Colonial America	Charles, Maryland, British Colonial America	0101000020E61000009A999999992953C01904560E2D424340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5357	Montgomery, Maryland, United States	Montgomery, Maryland, United States	0101000020E6100000CDCCCCCCCC4C53C03333333333934340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5371	St Pauls Parish, Prince George's, Maryland, United States	St Pauls Parish, Prince George's, Maryland, United States	0101000020E6100000A5315A47552553C0C66E9F5566464340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5372	Prince George, Virginia, United States	Prince George, Virginia, United States	0101000020E6100000EEEBC039234E53C03A92CB7F48974240	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5388	England	England	0101000020E6100000A2B437F8C264FABF8E75711B0D384A40	\N	region	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5389	Trenton, Hunterdon, New Jersey, British Colonial America	Trenton, Hunterdon, New Jersey, British Colonial America	0101000020E61000009BE61DA7E8B052C031992A18951C4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5407	Newtown, Queens, New York Colony, British Colonial America	Newtown, Queens, New York Colony, British Colonial America	0101000020E61000006A4DF38E537852C05839B4C8765E4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5426	Caen, Calvados, France	Caen, Calvados, France	0101000020E61000005A643BDF4F8DD7BF643BDF4F8D974840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5446	Elmhurst, Queens, New York City, New York, United States	Elmhurst, Queens, New York City, New York, United States	0101000020E61000006A4DF38E537852C05839B4C8765E4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5447	Princeton Township, Mercer, New Jersey, United States	Princeton Township, Mercer, New Jersey, United States	0101000020E61000003333333333AB52C0BBB88D06F02E4440	\N	township	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5469	Piscataway Township, Middlesex, New Jersey, British Colonial America	Piscataway Township, Middlesex, New Jersey, British Colonial America	0101000020E6100000C442AD69DE9D52C0211FF46C56454440	\N	township	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5470	Piscataway, Middlesex, New Jersey, British Colonial America	Piscataway, Middlesex, New Jersey, British Colonial America	0101000020E61000006F8104C58F9952C0E4141DC9E53F4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5494	Piscataway, Middlesex, New Jersey, United States	Piscataway, Middlesex, New Jersey, United States	0101000020E61000006F8104C58F9952C0E4141DC9E53F4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5519	Hopewell, Hopewell Township, Hunterdon, New Jersey, British Colonial America	Hopewell, Hopewell Township, Hunterdon, New Jersey, British Colonial America	0101000020E6100000B84082E2C7B052C036CD3B4ED1314440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5570	North Wingfield, Derbyshire, England, United Kingdom	North Wingfield, Derbyshire, England, United Kingdom	0101000020E61000008048BF7D1D38F6BF3A234A7B83974A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5571	Mansfield, Burlington, New Jersey, United States	Mansfield, Burlington, New Jersey, United States	0101000020E6100000925CFE43FAAD52C05F07CE19510A4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5599	Pontefract, Yorkshire, England, United Kingdom	Pontefract, Yorkshire, England, United Kingdom	0101000020E6100000CBA145B6F3FDF4BF6C4084B872D84A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5600	New Jersey, United States	New Jersey, United States	0101000020E61000000000000000A052C0F6285C8FC2154440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5630	Prince George's, Maryland, British Colonial America	Prince George's, Maryland, British Colonial America	0101000020E61000007EA83462663653C0E44C13B69F6A4340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5661	Prince George's, Maryland, United States	Prince George's, Maryland, United States	0101000020E610000066666666663653C0B4C876BE9F6A4340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5693	Avize, Marne, France	Avize, Marne, France	0101000020E61000004D158C4AEA041040A3923A014D7C4840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5726	Scotland, United Kingdom	Scotland, United Kingdom	0101000020E6100000B1169F0260BC10C0E3AAB2EF8A684C40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5760	Somerset, Maryland, United States	Somerset, Maryland, United States	0101000020E6100000B4C876BE9FF652C06E3480B7400A4340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5795	Morgantown, Fauquier, Virginia, United States	Morgantown, Fauquier, Virginia, United States	0101000020E61000002AA913D0447853C0B1BFEC9E3C6C4340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5831	Somerset, Maryland, British Colonial America	Somerset, Maryland, British Colonial America	0101000020E61000007F87A2409FF652C003B2D7BB3F0A4340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5832	Frederick, Frederick, Maryland, British Colonial America	Frederick, Frederick, Maryland, British Colonial America	0101000020E61000003D2CD49AE65153C0AD69DE718A9E4340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5907	Richmond, New York Colony, British Colonial America	Richmond, New York Colony, British Colonial America	0101000020E61000009A999999998952C04963B48EAA4A4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5908	Perth Amboy, Middlesex, New Jersey, British Colonial America	Perth Amboy, Middlesex, New Jersey, British Colonial America	0101000020E6100000287E8CB96B9152C0ED0DBE3099424440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5948	Cranbury, Cranbury Township, Middlesex, New Jersey, United States	Cranbury, Cranbury Township, Middlesex, New Jersey, United States	0101000020E610000045D8F0F44AA152C0E3A59BC420284440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5989	Württemberg, Germany	Württemberg, Germany	0101000020E6100000ECC039234A1B2240A835CD3B4E494840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-5990	Winchester, Frederick, Virginia, United States	Winchester, Frederick, Virginia, United States	0101000020E61000004A0C022B878A53C09D8026C286974340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-6033	Manheim, Bergheim, North Rhine-Westphalia, Germany	Manheim, Bergheim, North Rhine-Westphalia, Germany	0101000020E61000006666666666661A40454772F90F714940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-6120	County Donegal, Ireland	County Donegal, Ireland	0101000020E61000005E11FC6F259B1FC0BFF1B56796744B40	\N	county	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-6121	Maryland, British Colonial America	Maryland, British Colonial America	0101000020E6100000CDCCCCCCCC2C53C00000000000804340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-6167	Crisfield, Somerset, Maryland, United States	Crisfield, Somerset, Maryland, United States	0101000020E6100000910F7A36ABF652C012143FC6DCFD4240	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-6168	Charles, Maryland, United States	Charles, Maryland, United States	0101000020E6100000F4FDD478E93E53C0E7FBA9F1D23D4340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-6216	Philadelphia, Pennsylvania, British Colonial America	Philadelphia, Pennsylvania, British Colonial America	0101000020E61000008195438B6CC752C00000000000004440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-6217	Philadelphia, Pennsylvania, United States	Philadelphia, Pennsylvania, United States	0101000020E61000003480B74082CA52C027A089B0E1F94340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-6267	Philadelphia, Philadelphia, Pennsylvania, British Colonial America	Philadelphia, Philadelphia, Pennsylvania, British Colonial America	0101000020E61000003480B74082CA52C027A089B0E1F94340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-6268	Cheltenham Township, Montgomery, Pennsylvania, United States	Cheltenham Township, Montgomery, Pennsylvania, United States	0101000020E61000005B423EE8D9C852C099BB96900F0A4440	\N	township	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-6320	Richmond, Richmond, New York, United States	Richmond, Richmond, New York, United States	0101000020E61000004694F6065F8852C05396218E75494440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-6321	Perth Amboy, Middlesex, New Jersey, United States	Perth Amboy, Middlesex, New Jersey, United States	0101000020E61000004C546F0D6C9152C0A661F88898424440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-6375	New York Colony, British Colonial America	New York Colony, British Colonial America	0101000020E61000000000000000E052C00000000000804540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-6430	Untermünkheim, Hall, Württemberg, Germany	Untermünkheim, Hall, Württemberg, Germany	0101000020E61000002B8716D9CE7723407958A835CD934840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-6486	Hall, Württemberg, Germany	Hall, Württemberg, Germany	0101000020E6100000CDCCCCCCCCCC2340E9B7AF03E7944840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-6543	Donegal, Donegal, County Donegal, Ireland	Donegal, Donegal, County Donegal, Ireland	0101000020E6100000A5BDC117263320C0CF6BEC12D5534B40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-6544	District 11, Somerset, Maryland, British Colonial America	District 11, Somerset, Maryland, British Colonial America	0101000020E61000001B12F758FAF852C0EDD3F19881164340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-6603	Cavanacor, Clonleigh, County Donegal, Ireland	Cavanacor, Clonleigh, County Donegal, Ireland	0101000020E610000055F65D11FC0F1EC0546F0D6C956C4B40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-6663	Queen Anne Parish, Prince George's, Maryland, British Colonial America	Queen Anne Parish, Prince George's, Maryland, British Colonial America	0101000020E6100000FB3E1C24442453C0B0C91AF510714340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-6904	Philadelphia Monthly Meeting, Philadelphia, Philadelphia, Pennsylvania, United States	Philadelphia Monthly Meeting, Philadelphia, Philadelphia, Pennsylvania, United States	0101000020E6100000742497FF90CA52C00A2E56D460FA4340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-7027	Harlem, New York County, New York, United States	Harlem, New York County, New York, United States	0101000020E6100000A323B9FC877C52C0BADA8AFD65674440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-7028	Richmond, Staten Island, New York City, New York, United States	Richmond, Staten Island, New York City, New York, United States	0101000020E61000004694F6065F8852C05396218E75494440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-7092	Brooklyn, New York City, New York, United States	Brooklyn, New York City, New York, United States	0101000020E6100000BE9F1A2FDD7C52C0C520B07268514440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-7349	Brandywine Hundred, New Castle, Delaware, British Colonial America	Brandywine Hundred, New Castle, Delaware, British Colonial America	0101000020E6100000F775E09C11E152C0211FF46C56E54340	\N	township	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-7350	Brandywine Hundred, New Castle, Delaware, United States	Brandywine Hundred, New Castle, Delaware, United States	0101000020E6100000931804560EE152C0BEC1172653E54340	\N	township	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-47677	Finland	Finland	0101000020E61000000000000000803A400000000000005040	\N	region	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-0072	Ohio, USA	\N	0101000020E6100000E78C28ED0DBA54C0764F1E166A354440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-7483	Delaware, British Colonial America	Delaware, British Colonial America	0101000020E61000000000000000E052C00000000000804340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-7685	Concord, Leacock Township, Lancaster, Pennsylvania, British Colonial America	Concord, Leacock Township, Lancaster, Pennsylvania, British Colonial America	0101000020E61000005C2041F1630853C050FC1873D7024440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-7890	Marcus Hook, Delaware, Pennsylvania, United States	Marcus Hook, Delaware, Pennsylvania, United States	0101000020E61000000A68226C78DA52C0454772F90FE94340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-8029	Christiana Hundred, New Castle, Delaware, British Colonial America	Christiana Hundred, New Castle, Delaware, British Colonial America	0101000020E61000006666666666E652C0211FF46C56E54340	\N	township	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-8170	Chester, Pennsylvania, British Colonial America	Chester, Pennsylvania, British Colonial America	0101000020E6100000CBA145B6F3ED52C05839B4C876FE4340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-8171	Bethel Township, Chester, Pennsylvania, United States	Bethel Township, Chester, Pennsylvania, United States	0101000020E610000002BC051214DF52C0BF0E9C33A2EC4340	\N	township	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-8244	Westbury, Nassau, New York, United States	Westbury, Nassau, New York, United States	0101000020E61000002AA913D0446452C0EEEBC03923624440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-8318	Norway	Norway	0101000020E610000000000000000024400000000000004F40	\N	region	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-8467	Buckinghamshire, England	Buckinghamshire, England	0101000020E610000047ACC5A70018E5BFEFACDD76A1E14940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-8468	Wilmington, Delaware, British Colonial America	Wilmington, Delaware, British Colonial America	0101000020E6100000AC8BDB6800E352C0ACADD85F76DF4340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-8545	Shoreditch, Middlesex, England	Shoreditch, Middlesex, England	0101000020E6100000A5BDC1172653B5BF787AA52C43C44940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-8623	Pee Dee, Montgomery, North Carolina, United States	Pee Dee, Montgomery, North Carolina, United States	0101000020E6100000ADFA5C6DC50254C00AD7A3703DA24140	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-8936	Grubbs Landing, New Castle, Delaware, British Colonial America	Grubbs Landing, New Castle, Delaware, British Colonial America	0101000020E6100000832F4CA60ADE52C05BB1BFEC9EE44340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-8937	Brandywine MM, New Castle, Delaware, British Colonial America	Brandywine MM, New Castle, Delaware, British Colonial America	0101000020E61000000000000000E052C01381EA1F44E44340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-9098	Christiana, Delaware, British Colonial America	Christiana, Delaware, British Colonial America	0101000020E61000002063EE5A42EA52C085EB51B81ED54340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-9180	Williamsburg, New Castle, Delaware, United States	Williamsburg, New Castle, Delaware, United States	0101000020E61000008FE4F21FD2EB52C0A52C431CEBCA4340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-9427	Bethel Township, Chester, Pennsylvania, British Colonial America	Bethel Township, Chester, Pennsylvania, British Colonial America	0101000020E610000002BC051214DF52C0BF0E9C33A2EC4340	\N	township	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-9511	Naaman, New Castle, Delaware, British Colonial America	Naaman, New Castle, Delaware, British Colonial America	0101000020E61000008638D6C56DDC52C0ABCFD556ECE74340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-9596	Shoreditch, Hackney, London, England, United Kingdom	Shoreditch, Hackney, London, England, United Kingdom	0101000020E61000001975ADBD4F55B5BF84F4143944C44940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-9597	Thornbury Township, Chester, Pennsylvania, British Colonial America	Thornbury Township, Chester, Pennsylvania, British Colonial America	0101000020E61000005DFE43FAEDDF52C0CA54C1A8A4F64340	\N	township	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-9684	Sedgley, Staffordshire, England, United Kingdom	Sedgley, Staffordshire, England, United Kingdom	0101000020E610000099BB96900FFA00C06891ED7C3F454A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-9772	Newark, Delaware, British Colonial America	Newark, Delaware, British Colonial America	0101000020E61000000000000000F052C0D6C56D3480D74340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-9949	Long Crendon, Buckinghamshire, England	Long Crendon, Buckinghamshire, England	0101000020E6100000462575029A08F0BF2575029A08E34940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-10039	Warborough, Oxfordshire, England	Warborough, Oxfordshire, England	0101000020E61000003A234A7B832FF2BF44FAEDEBC0D14940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-10040	Uxbridge, Hillingdon, London, England, United Kingdom	Uxbridge, Hillingdon, London, England, United Kingdom	0101000020E6100000B81E85EB51B8DEBF2063EE5A42C64940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-10132	Towersey, Buckinghamshire, England	Towersey, Buckinghamshire, England	0101000020E61000009F3C2CD49AE6EDBFBB270F0BB5DE4940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-10593	New Castle, New Hampshire, British Colonial America	New Castle, New Hampshire, British Colonial America	0101000020E6100000E8DEC325C7AD51C0C7D79E5912884540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-10687	Newbury, Essex, Massachusetts, United States	Newbury, Essex, Massachusetts, United States	0101000020E6100000D8648D7A88B851C01D03B2D7BB634540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-10688	Massachusetts, United States	Massachusetts, United States	0101000020E61000000000000000E051C00000000000204540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-10784	Haverhill, Essex, Massachusetts, United States	Haverhill, Essex, Massachusetts, United States	0101000020E6100000A245B6F3FDC451C017D9CEF753634540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-10881	Delaware, United States	Delaware, United States	0101000020E61000000000000000E052C00000000000804340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-10979	Middleton, Warwickshire, England, United Kingdom	Middleton, Warwickshire, England, United Kingdom	0101000020E6100000F54A598638D6FBBF423EE8D9AC4A4A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-11078	Norwich, New London, Connecticut Colony, British Colonial America	Norwich, New London, Connecticut Colony, British Colonial America	0101000020E61000007D0569C6A20552C04AD235936FC64440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-11079	Mansfield, Tolland, Connecticut, United States	Mansfield, Tolland, Connecticut, United States	0101000020E610000021938C9C850F52C08AB0E1E995E64440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-11180	Mansfield, Windham, Connecticut, United States	Mansfield, Windham, Connecticut, United States	0101000020E61000003B191C25AF0E52C0543A58FFE7E44440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-11282	Coventry, Windham, Connecticut Colony, British Colonial America	Coventry, Windham, Connecticut Colony, British Colonial America	0101000020E6100000E35295B6B81552C0EF01BA2F67E44440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-11691	Andover, Essex, Massachusetts Bay Colony, British Colonial America	Andover, Essex, Massachusetts Bay Colony, British Colonial America	0101000020E61000001B2FDD2406C951C040A4DFBE0E544540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-11898	Maryland, United States	Maryland, United States	0101000020E6100000CDCCCCCCCC2C53C00000000000804340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-11899	Worcester, Maryland, United States	Worcester, Maryland, United States	0101000020E6100000D8648D7A88D852C09A99999999194340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-12110	Bridgewater, Plymouth, Massachusetts Bay Colony, British Colonial America	Bridgewater, Plymouth, Massachusetts Bay Colony, British Colonial America	0101000020E6100000A643A7E7DDBD51C01D03B2D7BBFB4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-12323	Malden, Middlesex, Massachusetts Bay Colony, British Colonial America	Malden, Middlesex, Massachusetts Bay Colony, British Colonial America	0101000020E610000039D6C56D34C451C08351499D80364540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-12431	Rowley, Essex, Massachusetts, United States	Rowley, Essex, Massachusetts, United States	0101000020E6100000D578E92631B851C08E1EBFB7E95B4540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-12540	Stonington, New London, Connecticut Colony, British Colonial America	Stonington, New London, Connecticut Colony, British Colonial America	0101000020E61000001973D712F2F951C05EBA490C02AB4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-12541	Windham, Connecticut Colony, British Colonial America	Windham, Connecticut Colony, British Colonial America	0101000020E610000000000000000052C03A5B40683DEA4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-12652	Amesbury, Essex, Massachusetts Bay Colony, British Colonial America	Amesbury, Essex, Massachusetts Bay Colony, British Colonial America	0101000020E6100000CDCCCCCCCCBC51C0CDCCCCCCCC6C4540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-12764	Newburyport, Essex, Massachusetts Bay Colony, British Colonial America	Newburyport, Essex, Massachusetts Bay Colony, British Colonial America	0101000020E6100000D8648D7A88B851C0C66E9F5566664540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-13213	Newbury, Massachusetts Bay Colony, British Colonial America	Newbury, Massachusetts Bay Colony, British Colonial America	0101000020E6100000D8648D7A88B851C01D03B2D7BB634540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-13214	Haverhill, Essex, Massachusetts Bay Colony, British Colonial America	Haverhill, Essex, Massachusetts Bay Colony, British Colonial America	0101000020E6100000A245B6F3FDC451C017D9CEF753634540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-13557	Amesbury, Essex, Massachusetts, United States	Amesbury, Essex, Massachusetts, United States	0101000020E6100000CDCCCCCCCCBC51C0CDCCCCCCCC6C4540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-13788	Dorchester, Maryland, United States	Dorchester, Maryland, United States	0101000020E610000000000000000053C01D03B2D7BB3B4340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-13905	Nottinghamshire, England, United Kingdom	Nottinghamshire, England, United Kingdom	0101000020E610000001C11C3D7E6FF0BF82FFAD64C78E4A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-14023	Buxted, Sussex, England, United Kingdom	Buxted, Sussex, England, United Kingdom	0101000020E6100000B1E1E995B20CC13F499D8026C27E4940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-14378	Saybrook, New London, Connecticut Colony, British Colonial America	Saybrook, New London, Connecticut Colony, British Colonial America	0101000020E610000000917EFB3A1852C076711B0DE0A54440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-14617	Barnstable, Barnstable, Plymouth Colony, British Colonial America	Barnstable, Barnstable, Plymouth Colony, British Colonial America	0101000020E6100000F3936A9F8E9351C0A79196CADBD94440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-14618	Mansfield Four Corners, Mansfield, Tolland, Connecticut, United States	Mansfield Four Corners, Mansfield, Tolland, Connecticut, United States	0101000020E6100000F775E09C111152C027A089B0E1E94440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-14982	Concord, Middlesex, Massachusetts Bay Colony, British Colonial America	Concord, Middlesex, Massachusetts Bay Colony, British Colonial America	0101000020E6100000289B728577D751C01D03B2D7BB3B4540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-15105	Stonington, New London, Connecticut, United States	Stonington, New London, Connecticut, United States	0101000020E61000006EA301BC05FA51C0EC2FBB270FAB4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-15967	L'Ange-Gardien, Québec, Canada, New France	L'Ange-Gardien, Québec, Canada, New France	0101000020E6100000F5B9DA8AFDC551C0053411363C754740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-16092	Île d'Orléans, Montmorency No. 2, Canada East, British North America	Île d'Orléans, Montmorency No. 2, Canada East, British North America	0101000020E61000000F0BB5A679BB51C065AA605452774740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-16218	Chateau Richer, Montmorency No. 1, Quebec, Canada	Chateau Richer, Montmorency No. 1, Quebec, Canada	0101000020E61000009A779CA223C151C032772D211F7C4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-16219	Montmorency No. 2, Quebec, Canada	Montmorency No. 2, Quebec, Canada	0101000020E6100000C442AD69DEBD51C0211FF46C56754740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-16347	Sainte-Famille, Saint-Laurent, Québec, Canada, New France	Sainte-Famille, Saint-Laurent, Québec, Canada, New France	0101000020E6100000C4B12E6EA3BD51C06ADE718A8E7C4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-16476	Saint-Jean-Baptiste, Saint-Laurent, Québec, Canada, New France	Saint-Jean-Baptiste, Saint-Laurent, Québec, Canada, New France	0101000020E6100000295C8FC2F5B851C0849ECDAACF754740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-17122	Saint-Paul-de-l'Arbre-Sec, Saint-Laurent, Québec, Canada, New France	Saint-Paul-de-l'Arbre-Sec, Saint-Laurent, Québec, Canada, New France	0101000020E61000001C7C613255C051C03CBD5296216E4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-17123	Saint-Laurent, Île d'Orléans, Quebec, British North America	Saint-Laurent, Île d'Orléans, Quebec, British North America	0101000020E61000008D28ED0DBEC051C090A0F831E66E4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-17386	Layrac, Lot-et-Garonne, France	Layrac, Lot-et-Garonne, France	0101000020E6100000D26F5F07CE19E53FEF38454772114640	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-17519	Chateau Richer, Québec, Canada, New France	Chateau Richer, Québec, Canada, New France	0101000020E6100000FED478E926C151C0C0EC9E3C2C7C4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-17653	L'Ange-Gardien, Montmorency No. 1, Quebec, Canada	L'Ange-Gardien, Montmorency No. 1, Quebec, Canada	0101000020E610000044FAEDEBC0C551C0764F1E166A754740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-17922	Savignies, Oise, France	Savignies, Oise, France	0101000020E61000008FE4F21FD26FFF3F083D9B559FBB4840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-18328	Cap-Tourmente, Québec, Canada, New France	Cap-Tourmente, Québec, Canada, New France	0101000020E6100000401361C3D3B351C0637FD93D79884740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-0001	Wills Creek, Coshocton County, Ohio	Wills Creek, Coshocton County, Ohio, USA	0101000020E6100000314278B4717654C0D07EA4880C174440	Coshocton County, Ohio, USA	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0002	Monteith, Guthrie County, Iowa	Monteith, Guthrie County, Iowa, USA	0101000020E610000027309DD66D9B57C0303E16ECD0D04440	Guthrie County, Iowa, USA	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Includes Monteith Cemetery	\N	\N
PL-0003	Woodsfield, Monroe County, Ohio	Woodsfield, Monroe County, Ohio, USA	0101000020E6100000C8073D9B554754C0E09C11A5BDE14340	Monroe County, Ohio, USA	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0004	Valley Township, Guthrie County, Iowa	Valley Township, Guthrie County, Iowa, USA	0101000020E61000005AB741EDB79E57C0BAF42F4965E04440	Guthrie County, Iowa, USA	region	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0005	Salem, Washington County, Indiana	Salem, Washington County, Indiana, USA	0101000020E6100000103FFF3D788655C0F8FF71C2844D4340	Washington County, Indiana, USA	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0006	Ohio	Ohio, USA	0101000020E6100000E78C28ED0DBA54C0764F1E166A354440	USA	region	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0007	Morgan County, Ohio	Morgan County, Ohio, USA	0101000020E610000065C39ACAA27454C06EDFA3FE7AD34340	Ohio, USA	region	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0008	Noble County, Ohio	Noble County, Ohio, USA	0101000020E610000086014BAE625B54C07B2FBE688FDF4340	Ohio, USA	region	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0009	Delaware County, Indiana	Delaware County, Indiana, USA	0101000020E61000000CCA349A5C5955C068E90AB611214440	Indiana, USA	region	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0010	Chicago, Cook County, Illinois	Chicago, Cook County, Illinois, USA	0101000020E61000004E452A8C2DE855C06284F068E3F04440	Cook County, Illinois, USA	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0011	Oakridge-Glen Oak Cemetery, Hillside, Illinois	Oakridge-Glen Oak Cemetery, Hillside, Cook County, Illinois, USA	0101000020E6100000E2E995B20CF955C05917B7D100EE4440	Hillside, Cook County, Illinois, USA	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0012	Bohemia	Bohemia (now Czech Republic)	0101000020E61000006380441328F22E40EE5EEE93A3E84840	Czech Republic	region	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	Bohemia	\N	\N	\N
PL-0013	Corydon, Wayne County, Iowa	Corydon, Wayne County, Iowa, USA	0101000020E61000004694F6065F5457C0C66D3480B7604440	Wayne County, Iowa, USA	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0014	Atlanta, Georgia	Atlanta, Fulton County, Georgia, USA	0101000020E610000046B6F3FDD41855C01D5A643BDFDF4040	Fulton County, Georgia, USA	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0015	Guthrie County, Iowa, USA	Guthrie County, Iowa, USA	0101000020E61000001D5A643BDF9F57C00E2DB29DEFD74440	\N	county	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0016	Chicago, Cook County, Illinois, USA	\N	0101000020E61000004E452A8C2DE855C06284F068E3F04440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0017	Glen Ellyn, DuPage County, Illinois, USA	\N	0101000020E6100000E36BCF2C090456C0FA9B508880EF4440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0019	Cicero Town, Cicero Township, Cook County, Illinois, USA	\N	0101000020E6100000AD86C43D96F055C095B7239C16EC4440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0020	Bedford, Taylor County, Iowa, USA	\N	0101000020E6100000B1F9B83654AE57C06002B7EEE6554440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0021	1048 Alameda Dr, Aurora, IL 60506, USA	\N	0101000020E610000025E82FF4881756C066F4A3E194E34440	\N	address	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0022	Valley Township, Guthrie Center city, Guthrie County, Iowa, USA	\N	0101000020E61000008BFCFA2136A057C047C7D5C8AED64440	\N	township	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0023	Waukesha, Waukesha County, Wisconsin, USA	\N	0101000020E6100000B75D68AED30E56C0132C0E677E814540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0024	Cicero, Cook County, Illinois, USA	\N	0101000020E6100000AD86C43D96F055C095B7239C16EC4440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0026	4N711 Medinah Road, Addison, DuPage County, Illinois, USA	\N	0101000020E6100000C34483143C0356C00762D9CC21F94440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0028	Schaumburg Township, Cook County, Illinois, USA	\N	0101000020E610000041118B18760456C0CBF44BC45B034540	\N	township	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0029	Glen Oak Cemetery, Proviso Township, Cook County, Illinois, USA	\N	0101000020E6100000DC3818A0230D56C04F6331A0CDF24440	\N	cemetery	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0030	Aurora Ward 2, Kane County, Illinois, USA	\N	0101000020E61000005A17450F7C1456C0016A6AD95AE14440	\N	ward	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0031	Cook County, Illinois, USA	\N	0101000020E61000001B6C787AA5EC55C02D211FF46CDE4440	\N	county	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0032	Monteith, Guthrie County, Iowa, USA	\N	0101000020E610000027309DD66D9B57C0303E16ECD0D04440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0033	Davenport, Scott County, Iowa, USA	\N	0101000020E6100000B9DFA128D0A556C004E275FD82C54440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0034	Oakdale Memorial Gardens Cemetery, Davenport, Scott County, Iowa, USA	\N	0101000020E61000006FD39FFD48A356C0D97745F0BFC54440	\N	cemetery	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0035	Jackson Township, Guthrie County, Iowa, USA	\N	0101000020E6100000973B33C170A056C03909A52F84164540	\N	township	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0036	Niagara Falls, Niagara County, New York, USA	\N	0101000020E610000005022B8716C153C0CDCCCCCCCC8C4540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0037	Ward 6, Davenport City, Scott County, Iowa, USA	\N	0101000020E6100000C9022670EBA856C0E0D6DD3CD5D14440	\N	ward	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0038	Seely Township, Guthrie County, Iowa, USA	\N	0101000020E610000000FF942A51A557C093C6681D55DD4440	\N	township	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0039	Prairie Home Cemetery, Waukesha, Waukesha County, Wisconsin, USA	\N	0101000020E61000008FC2F5285C0F56C0BADA8AFD657F4540	\N	cemetery	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0041	Sioux Falls Ward 11, Minnehaha County, South Dakota, USA	\N	0101000020E6100000EF384547723558C06E32AA0CE3D44540	\N	ward	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0042	VraÅ¾dovy Lhotice #16, BeneÅ¡ov, Bohemia, Austria	\N	0101000020E610000080EF366F9C5C2E40B4CA4C69FDD14840	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0044	Aurora Township, Kane County, Illinois, USA	\N	0101000020E6100000D122DBF97E1256C0355EBA490CE24440	\N	township	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0046	6 S Leamington Ave, Chicago, Cook County, Illinois, USA	\N	0101000020E6100000FF428F183DF055C04BCB48BDA7F04440	\N	address	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0047	Oakridge Cemetery, Hillside, Cook County, Illinois, USA	\N	0101000020E6100000E2E995B20CF955C05917B7D100EE4440	\N	cemetery	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0048	Saint-Laurent-de-L'ÃŽle-d'OrlÃ©ans, L'ÃŽle-d'OrlÃ©ans, QuÃ©bec, Canada	\N	0101000020E6100000E694809884C051C0749A05DA1D6E4740	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0049	New York, USA	\N	0101000020E6100000AAF1D24D628052C05E4BC8073D5B4440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0050	Woodsfield, Monroe County, Ohio, USA	\N	0101000020E6100000C1073D9B554754C0E09C11A5BDE14340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0053	Valley Township, Guthrie Center, Guthrie County, Iowa, USA	\N	0101000020E61000002046088F36A057C002F1BA7EC1D64440	\N	township	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0058	Salem, Washington County, Indiana, USA	\N	0101000020E6100000103FFF3D788655C0F8FF71C2844D4340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0059	Falls City, Jerome County, Idaho, USA	\N	0101000020E61000002E73BA2C269B5CC07C0DC17119574540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0060	Twin Falls, Twin Falls County, Idaho, USA	\N	0101000020E6100000486DE2E47E9D5CC08750A5660F484540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0061	Clay Township, Howard County, Indiana, USA	\N	0101000020E6100000DF5339ED298D55C02E3D9AEAC9424440	\N	township	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0062	Franklin Township, Grundy County, Missouri, USA	\N	0101000020E61000002A8D98D9E76357C0CE716E13EE1D4440	\N	township	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0063	Union Township, Guthrie County, Iowa, USA	\N	0101000020E61000005776C1E09AAA57C077103B53E8DC4440	\N	township	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0065	Guthrie Center, Guthrie County, Iowa, USA	\N	0101000020E61000002046088F36A057C002F1BA7EC1D64440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0066	Rollin, Lenawee County, Michigan, USA	\N	0101000020E6100000E204A6D3BA1455C06B80D250A3F44440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0067	Violet Hill Cemetery, Perry, Dallas County, Iowa, USA	\N	0101000020E6100000E0BE0E9C338657C014D044D8F0EC4440	\N	cemetery	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0068	Mt Vernon, Franklin Township, Linn County, Iowa, USA	\N	0101000020E6100000CA54C1A8A4DA56C03D2CD49AE6F54440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0069	Ward 4, Cedar Rapids, Linn County, Iowa, USA	\N	0101000020E6100000F8E28BF678E956C0BFF2203D45F84440	\N	ward	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0070	Wills Creek, Coshocton County, Ohio, USA	\N	0101000020E6100000314278B4717654C0D07EA4880C174440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0074	Talley Town, Morgan County, Ohio, USA	\N	0101000020E61000005EC39ACAA27454C06EDFA3FE7AD34340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0075	Guthrie Center city, Valley Township, Guthrie County, Iowa, USA	\N	0101000020E61000002046088F36A057C002F1BA7EC1D64440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0078	Adams, Washington, Ohio, United States	\N	0101000020E61000006A656776825D54C01CC8C4F70FB74340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0079	Airington Cemetery, Bristol Township, Morgan County, Ohio, United States	\N	0101000020E6100000E5F21FD26F7054C044E048A0C1DA4340	\N	cemetery	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0080	Bloom Township, Morgan, Ohio, United States	\N	0101000020E6100000C554FA0967B054C090D959F44EE34340	\N	township	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0081	Brandywine, New Castle, Delaware, United States	\N	0101000020E6100000A461421633E252C06B589DE62EEA4340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0082	Caldwell, Noble, Ohio, United States	\N	0101000020E6100000FF9D488B0E6154C0CB243493B9DF4340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0083	Cambridge Township, Guernsey, Ohio, United States	\N	0101000020E61000000FEECEDA6D6554C0F8E3F6CB27034440	\N	township	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0084	Connecticut, United States	\N	0101000020E61000002B2C5D66FD2E52C00F9FCFDB33D34440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0085	Greene, Pennsylvania, United States	\N	0101000020E6100000047C6DECC80F54C010841A74F8EC4340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0086	Greenwood Cemetery, Zanesville, Muskingum, Ohio, United States	\N	0101000020E6100000453646A11B7F54C093BD4AE3BCF84340	\N	cemetery	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0087	Guernsey, Ohio, United States	\N	0101000020E6100000764DEDB1195F54C0E3B496B8440A4440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0088	Hopewell Township, Hunterdon, New Jerse	\N	0101000020E6100000793A579412B352C0AE9AE7887C2D4440	\N	township	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0089	Hunterdon, New Jersey	\N	0101000020E6100000DFA815A6EFBA52C09EB7B1D991484440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0090	Hunterdon, New Jersey, United States	\N	0101000020E61000004DC1752046BB52C0FA5BA736DD494440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0096	Lebanon, Grafton, New Hampshire, United States	\N	0101000020E610000052465C001A1052C0072461DF4ED24540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0097	Nanticoke Hundred, Sussex, Delaware, United States	\N	0101000020E6100000AE7FD767CEDB52C03BC5AA4198534340	\N	township	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0098	New Castle, Delaware, United States	\N	0101000020E6100000F7AB00DF6DEA52C062A98999D8CE4340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0099	New Hampshire, United States	\N	0101000020E6100000C6747C0FF2E951C09E7296A311BE4540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0100	Newport, Hunterdon, New Jersey, United States	\N	0101000020E61000002A6CABFE2DBA52C0302AA913D05C4440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0101	Noble, Ohio, United States	\N	0101000020E610000083FF081EBA5F54C0A8F5C83038E04340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0103	Olive Cemetery, Caldwell, Noble, Ohio, United States	\N	0101000020E610000082678C205F6054C0282A1BD654DF4340	\N	cemetery	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0104	Pennington Presbyterian Church Cemetery, Pennington, Mercer, New Jersey, United States	\N	0101000020E61000002976340EF5AE52C06C3F19E3C3264440	\N	cemetery	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0105	Renrock, Noble, Ohio, United States	\N	0101000020E61000004196AA590C6B54C01E98ED540AE14340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0106	Shafer Cemetery, Jackson Township, Noble, Ohio, United States	\N	0101000020E6100000EAD0E979375D54C020B24813EFD04340	\N	cemetery	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0107	Shafers Church Cemetery, Macksburg, Noble, Ohio, United States	\N	0101000020E6100000EAD0E979375D54C020B24813EFD04340	\N	cemetery	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0108	Simsbury, Hartford	\N	0101000020E61000005F57DD34473352C0DF0841FD1DF04440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0109	Simsbury, Hartford, Connecticut, United States	\N	0101000020E61000005F57DD34473352C0DF0841FD1DF04440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0110	Upper Lowell, Noble, Ohio, United States	\N	0101000020E610000037161406656154C004E5B67D8FC44340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0111	Upper Lowell, Washington, Ohio, United States	\N	0101000020E610000037161406656154C099A48D7E8FC44340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0112	Washington Township, Muskingum, Ohio, United States	\N	0101000020E6100000D7828362D07C54C016A7B5C425034440	\N	township	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0113	Washington, Pennsylvania, United States	\N	0101000020E6100000EF65EC95431054C06300F26FE1184440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0114	Windsor, Hartford, Connecticut	\N	0101000020E6100000AB97DF69322952C0485167EE21ED4440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0115	Renrock, Noble, Ohio, United States	\N	0101000020E61000004196AA590C6B54C01E98ED540AE14340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0116	Hunterdon, New Jersey, United States	\N	0101000020E61000004DC1752046BB52C0FA5BA736DD494440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0147	Olive Cemetery, Caldwell, Noble, Ohio, United States	\N	0101000020E610000082678C205F6054C0282A1BD654DF4340	\N	cemetery	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0148	Olive Cemetery, Caldwell, Noble, Ohio, United States	\N	0101000020E610000082678C205F6054C0282A1BD654DF4340	\N	cemetery	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0149	Olive Cemetery, Caldwell, Noble, Ohio, United States	\N	0101000020E610000082678C205F6054C0282A1BD654DF4340	\N	cemetery	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0150	Olive Cemetery, Caldwell, Noble, Ohio, United States	\N	0101000020E610000082678C205F6054C0282A1BD654DF4340	\N	cemetery	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0151	Greene, Pennsylvania, United States	\N	0101000020E6100000047C6DECC80F54C010841A74F8EC4340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0152	Greene, Pennsylvania, United States	\N	0101000020E6100000047C6DECC80F54C010841A74F8EC4340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0153	Caldwell, Noble, Ohio, United States	\N	0101000020E6100000FF9D488B0E6154C0CB243493B9DF4340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0154	Caldwell, Noble, Ohio, United States	\N	0101000020E6100000FF9D488B0E6154C0CB243493B9DF4340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
PL-0155	County Dublin, Ireland	County Dublin, Ireland	0101000020E61000000AD7A3703D0A19C05BD3BCE314AD4A40	\N	county	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0158	Chicago, Cook, Illinois, United States	Chicago, Cook, Illinois, United States	0101000020E61000001B0DE02D90E855C00C93A98251F14440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0159	Aurora, Kane, Illinois, United States	Aurora, Kane, Illinois, United States	0101000020E610000014AE47E17A1456C036AB3E575BE14440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0163	Glen Ellyn, DuPage, Illinois, United States	Glen Ellyn, DuPage, Illinois, United States	0101000020E61000008E06F016480456C0B81E85EB51F04440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0172	Schaumburg, Cook, Illinois, United States	Schaumburg, Cook, Illinois, United States	0101000020E61000006FF085C9540556C0787AA52C43044540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0178	Cintolese, Monsummano Terme, Pistoia, Tuscany, Italy	Cintolese, Monsummano Terme, Pistoia, Tuscany, Italy	0101000020E61000003196E99788A725406D1E87C1FCEB4540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0179	Cicero, Cook, Illinois, United States	Cicero, Cook, Illinois, United States	0101000020E6100000151DC9E53FF055C0B1BFEC9E3CEC4440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0187	Berwyn, Cook, Illinois, United States	Berwyn, Cook, Illinois, United States	0101000020E6100000C286A757CAF255C022FDF675E0EC4440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0196	Monteith, Guthrie, Iowa, United States	Monteith, Guthrie, Iowa, United States	0101000020E61000001D386744699B57C0E25817B7D1D04440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0197	Davenport, Scott, Iowa, United States	Davenport, Scott, Iowa, United States	0101000020E6100000295C8FC2F5A456C0C217265305C34440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0208	Guthrie, Iowa, United States	Guthrie, Iowa, United States	0101000020E6100000FBAD9D2809A057C046B41D5377D74440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0220	Seely Township, Guthrie, Iowa, United States	Seely Township, Guthrie, Iowa, United States	0101000020E6100000314278B471A457C02D3E05C078DE4440	\N	township	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0233	Beneschau, Bohemia, Austria	Beneschau, Bohemia, Austria	0101000020E61000000000000000802D404529215855D54840	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0247	Italy	Italy	0101000020E61000009A99999999992840CDCCCCCCCC8C4540	\N	region	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0262	Spianate, Altopascio, Lucca, Tuscany, Italy	Spianate, Altopascio, Lucca, Tuscany, Italy	0101000020E6100000C8B4368DED6D25403D1059A489E74540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0278	Cintolese, Monsummano, Pistoia, Tuscany, Italy	Cintolese, Monsummano, Pistoia, Tuscany, Italy	0101000020E61000003196E99788A725406D1E87C1FCEB4540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0327	Woodsfield, Monroe, Ohio, United States	Woodsfield, Monroe, Ohio, United States	0101000020E61000005646239F574754C01CCF6740BDE14340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0328	Valley Township, Guthrie, Iowa, United States	Valley Township, Guthrie, Iowa, United States	0101000020E61000002176A6D0799D57C0DF89592F86D24440	\N	township	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0347	Noble Township, Morgan, Ohio, United States	Noble Township, Morgan, Ohio, United States	0101000020E61000002DCF83BBB36254C0F819170E84E44340	\N	township	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0367	Salem, Washington Township, Washington, Indiana, United States	Salem, Washington Township, Washington, Indiana, United States	0101000020E61000000A68226C788655C0933A014D844D4340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0390	Ponte Buggianese, Pistoia, Tuscany, Italy	Ponte Buggianese, Pistoia, Tuscany, Italy	0101000020E6100000ADFA5C6DC57E2540CFF753E3A5EB4540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0413	Hillsdale, Michigan, United States	Hillsdale, Michigan, United States	0101000020E610000019E25817B72755C09A081B9E5EF54440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0506	Saint-Laurent, L'Île-d'Orléans, Quebec, Canada	Saint-Laurent, L'Île-d'Orléans, Quebec, Canada	0101000020E61000008D28ED0DBEC051C090A0F831E66E4740	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0531	Pescia, Lucca, Tuscany, Italy	Pescia, Lucca, Tuscany, Italy	0101000020E610000038F8C264AA60254087A757CA32F44540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0557	Chiesina Uzzanese, Pistoia, Tuscany, Italy	Chiesina Uzzanese, Pistoia, Tuscany, Italy	0101000020E6100000E3A59BC420702540C1CAA145B6EB4540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0610	Wills Creek, Coshocton, Ohio, United States	Wills Creek, Coshocton, Ohio, United States	0101000020E6100000F5DBD781737654C0D7A3703D0A174440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0638	Morgan, Ohio, United States	Morgan, Ohio, United States	0101000020E6100000A5315A47557554C080BA8102EFCE4340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0667	Canaan, Somerset, Maine, United States	Canaan, Somerset, Maine, United States	0101000020E61000007B14AE47E16251C0083D9B559F634640	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0668	Shellsburg, Benton, Iowa, United States	Shellsburg, Benton, Iowa, United States	0101000020E610000016FBCBEEC9F756C07958A835CD0B4540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0699	Rome, Oneida, New York, United States	Rome, Oneida, New York, United States	0101000020E6100000C58F31772DDD52C0CE1951DA1B9C4540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0731	Saratoga, New York, United States	Saratoga, New York, United States	0101000020E610000066666666667652C0CDCCCCCCCC8C4540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0732	Bayard, Guthrie, Iowa, United States	Bayard, Guthrie, Iowa, United States	0101000020E610000072F90FE9B7A357C030BB270F0BED4440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-0931	Trumbull, Ohio, United States	Trumbull, Ohio, United States	0101000020E6100000C2340C1F113154C0EACF7EA488A84440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-1000	Saint-Jean-Baptiste, Montmorency No. 2, Quebec, Canada	Saint-Jean-Baptiste, Montmorency No. 2, Quebec, Canada	0101000020E61000009BE61DA7E8B851C05917B7D100764740	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-1001	Saint-Laurent, Montmorency No. 2, Quebec, Canada	Saint-Laurent, Montmorency No. 2, Quebec, Canada	0101000020E61000008D28ED0DBEC051C090A0F831E66E4740	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-1038	Albinatico, Ponte Buggianese, Buggiano, Lucca, Tuscany, Italy	Albinatico, Ponte Buggianese, Buggiano, Lucca, Tuscany, Italy	0101000020E6100000C5CBD3B9A2842540A13028D368EC4540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-1039	Albinatico, Ponte Buggianese, Pistoia, Tuscany, Italy	Albinatico, Ponte Buggianese, Pistoia, Tuscany, Italy	0101000020E6100000C5CBD3B9A2842540A13028D368EC4540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-1230	Monsummano, Lucca, Tuscany	Monsummano, Lucca, Tuscany	0101000020E6100000C4B12E6EA3A125401DC9E53FA4EF4540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-1426	Wiscasset, Wiscasset, Lincoln, Massachusetts, United States	Wiscasset, Wiscasset, Lincoln, Massachusetts, United States	0101000020E61000007862D68BA16A51C09C8A54185B004640	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-1467	Harvard, Worcester, Massachusetts Bay Colony, British Colonial America	Harvard, Worcester, Massachusetts Bay Colony, British Colonial America	0101000020E6100000A5315A4755E551C08369183E22424540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-1550	Vrazdovy Lhotice, Benešov, Czechia	Vrazdovy Lhotice, Benešov, Czechia	0101000020E61000003D0E83F92B5C2E404FE8F527F1D14840	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-1635	St-Laurent-de-l'Île-d'Orléans Cemetery, Saint-Laurent, L'Île-d'Orléans, Quebec, Canada	St-Laurent-de-l'Île-d'Orléans Cemetery, Saint-Laurent, L'Île-d'Orléans, Quebec, Canada	0101000020E61000005AF0A2AF206B52C0598638D6C5C14640	\N	cemetery	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-1765	Saint-Jean, Orléans, Lower Canada, British North America	Saint-Jean, Orléans, Lower Canada, British North America	0101000020E6100000295C8FC2F5B851C02041F163CC754740	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-1810	Wonschow, Ledeč, Bohemia, Austria	Wonschow, Ledeč, Bohemia, Austria	0101000020E61000004B598638D6452E400B46257502CA4840	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-2171	Montevettolini, Monsummano Terme, Pistoia, Tuscany, Italy	Montevettolini, Monsummano Terme, Pistoia, Tuscany, Italy	0101000020E610000000E31934F4AF254092E86514CBED4540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-2218	New Castle, Delaware, British Colonial America	New Castle, Delaware, British Colonial America	0101000020E61000007D3F355EBAE952C0D122DBF97ECA4340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-2219	Wilmington, New Castle, Delaware, United States	Wilmington, New Castle, Delaware, United States	0101000020E6100000AC8BDB6800E352C0ACADD85F76DF4340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-2268	Piasa, Macoupin, Illinois, United States	Piasa, Macoupin, Illinois, United States	0101000020E61000004772F90FE98756C03B70CE88D28E4340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-2318	Frederick, Maryland, British Colonial America	Frederick, Maryland, British Colonial America	0101000020E61000009A999999995953C0B29DEFA7C6BB4340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-2319	Washington, Upper Mifflin Township, Cumberland, Pennsylvania, United States	Washington, Upper Mifflin Township, Cumberland, Pennsylvania, United States	0101000020E6100000516B9A779C5E53C027A089B0E1194440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-2371	New Castle, New Castle, Delaware, United States	New Castle, New Castle, Delaware, United States	0101000020E61000002AA913D044E452C0789CA223B9D44340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-2424	Fort Hill, Upper Turkeyfoot Township, Somerset, Pennsylvania, United States	Fort Hill, Upper Turkeyfoot Township, Somerset, Pennsylvania, United States	0101000020E61000005396218E75D153C035EF384547EA4340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-2425	Liberty, Guernsey, Ohio, United States	Liberty, Guernsey, Ohio, United States	0101000020E610000086C954C1A86454C0B37BF2B050134440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-2480	Mill Creek Hundred, New Castle, Delaware, United States	Mill Creek Hundred, New Castle, Delaware, United States	0101000020E6100000D656EC2FBBEB52C0EEEBC03923E24340	\N	township	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-2536	Nanticoke Hundred, Sussex, Delaware, British Colonial America	Nanticoke Hundred, Sussex, Delaware, British Colonial America	0101000020E6100000A323B9FC87E052C0DFE00B93A95A4340	\N	township	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-2593	Sussex, Delaware, British Colonial America	Sussex, Delaware, British Colonial America	0101000020E6100000910F7A36ABDA52C09A99999999594340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-2594	Morgantown, Monongalia, Virginia, United States	Morgantown, Monongalia, Virginia, United States	0101000020E61000003A58FFE730FD53C0AA656B7D91D04340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-2653	Rowley, Essex, Massachusetts Bay Colony, British Colonial America	Rowley, Essex, Massachusetts Bay Colony, British Colonial America	0101000020E6100000D578E92631B851C08E1EBFB7E95B4540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-2713	Cranbury Township, Middlesex, New Jersey, United States	Cranbury Township, Middlesex, New Jersey, United States	0101000020E61000003CBD529621A252C00000000000284440	\N	township	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-2714	Greene Township, Washington, Pennsylvania, United States	Greene Township, Washington, Pennsylvania, United States	0101000020E6100000A5660FB4020154C045813E9127E94340	\N	township	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-2776	Newbury, Essex, Massachusetts Bay Colony, British Colonial America	Newbury, Essex, Massachusetts Bay Colony, British Colonial America	0101000020E6100000D8648D7A88B851C01D03B2D7BB634540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-2777	Olive Township, Morgan, Ohio, United States	Olive Township, Morgan, Ohio, United States	0101000020E6100000295C8FC2F56054C0840D4FAF94DD4340	\N	township	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-2841	Mansfield, Windham, Connecticut Colony, British Colonial America	Mansfield, Windham, Connecticut Colony, British Colonial America	0101000020E61000003B191C25AF0E52C0543A58FFE7E44440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-2842	Washington, Ohio, United States	Washington, Ohio, United States	0101000020E61000008B5242B0AA5A54C04E452A8C2DC04340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-2908	Montgomery, Pennsylvania, United States	Montgomery, Pennsylvania, United States	0101000020E6100000643BDF4F8DD752C05EBA490C021B4440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-2975	Billerica, Middlesex, Massachusetts, United States	Billerica, Middlesex, Massachusetts, United States	0101000020E6100000F0A7C64B37D151C0643BDF4F8D474540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-2976	Stoddard, Cheshire, New Hampshire, United States	Stoddard, Cheshire, New Hampshire, United States	0101000020E6100000DE9387855A0752C0273108AC1C8A4540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-3045	Highland, Ohio, United States	Highland, Ohio, United States	0101000020E610000040DD408177E754C046B41D5377974340	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-3115	York, York, Maine, United States	York, York, Maine, United States	0101000020E61000009A99999999A951C0C1CAA145B6934540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-3186	Windsor, Hartford, Connecticut Colony, British Colonial America	Windsor, Hartford, Connecticut Colony, British Colonial America	0101000020E6100000AC730CC85E2952C0B03DB32440ED4440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-3258	Sangerville, Piscataquis, Maine, United States	Sangerville, Piscataquis, Maine, United States	0101000020E61000001F85EB51B85651C01361C3D32B954640	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-3331	Windsor, Hartford, Connecticut, United States	Windsor, Hartford, Connecticut, United States	0101000020E6100000AC730CC85E2952C0B03DB32440ED4440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-3478	Wintonbury Parish, Windsor, Hartford, Connecticut Colony, British Colonial America	Wintonbury Parish, Windsor, Hartford, Connecticut Colony, British Colonial America	0101000020E6100000C139234A7B2F52C040A4DFBE0EEC4440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-3553	Marlborough, Middlesex, Massachusetts Bay Colony, British Colonial America	Marlborough, Middlesex, Massachusetts Bay Colony, British Colonial America	0101000020E610000099BA2BBB60E351C01381EA1F442C4540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-3854	Tomice, Benešov, Czechia	Tomice, Benešov, Czechia	0101000020E6100000390B7BDAE14F2E40BBD05CA791D24840	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-4083	Košetice, Pelhřimov, Czechia	Košetice, Pelhřimov, Czechia	0101000020E6100000D0D556EC2F3B2E40410E4A9869C74840	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-4392	Saint-Laurent, Montreal, Canada, New France	Saint-Laurent, Montreal, Canada, New France	0101000020E61000006C787AA52C6B52C0D26F5F07CEC14640	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-4471	Saint-Laurent, Saint-Laurent, Québec, Canada, New France	Saint-Laurent, Saint-Laurent, Québec, Canada, New France	0101000020E61000008D28ED0DBEC051C090A0F831E66E4740	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-4472	Saint-Laurent, Orléans, Lower Canada, British North America	Saint-Laurent, Orléans, Lower Canada, British North America	0101000020E61000008D28ED0DBEC051C090A0F831E66E4740	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-4553	Saint-Jean, Trois-Rivières, Canada, New France	Saint-Jean, Trois-Rivières, Canada, New France	0101000020E61000008195438B6C0752C048BF7D1D38474740	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-4635	Saint-Jean-Baptiste, L'Île-d'Orléans, Quebec, Canada	Saint-Jean-Baptiste, L'Île-d'Orléans, Quebec, Canada	0101000020E61000009BE61DA7E8B851C05917B7D100764740	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-4636	Saint-Laurent, Québec, Canada, New France	Saint-Laurent, Québec, Canada, New France	0101000020E6100000705F07CE19BD51C039B4C876BE774740	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-4720	Saint-Pierre, Saint-Laurent, Québec, Canada, New France	Saint-Pierre, Saint-Laurent, Québec, Canada, New France	0101000020E61000007FFB3A70CEC451C07D3F355EBA714740	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-4805	Île d'Orléans, Montmorency No. 2, Quebec, Canada	Île d'Orléans, Montmorency No. 2, Quebec, Canada	0101000020E61000000F0BB5A679BB51C065AA605452774740	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-5231	Monsummano Terme, Pistoia, Tuscany, Italy	Monsummano Terme, Pistoia, Tuscany, Italy	0101000020E61000001B2FDD2406A12540643BDF4F8DEF4540	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Imported from FS extract 2026-05-26	\N	\N
PL-5232	Hillside, Cook, Illinois, United States	Hillside, Cook, Illinois, United States	0101000020E61000000BB5A679C7F955C0E3361AC05BF04440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Auto-geocoded from FS extract 2026-05-28	\N	\N
PL-5233	Canton Township, Benton County, Iowa, USA	Canton Township, Benton County, Iowa, USA	0101000020E61000002FDD240681FD56C00BB5A679C7194540	USA > Iowa > Benton County	township	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Source: Benton County Pioneers / iagenweb	\N	\N
PL-5234	Oakdale Memorial Gardens, Davenport, Scott County, Iowa, USA	Oakdale Memorial Gardens, Davenport, Scott County, Iowa, United States	0101000020E6100000091B9E5E29A356C06744696FF0C54440	USA > Iowa > Scott County > Davenport	cemetery	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Burial location for John Foulk Reed (P-0061) per FS PID KLGC-TLC. Added during P-0036 deep dive.	\N	\N
PL-5235	Elgin, Kane County, Illinois, USA	Elgin, Kane County, Illinois, United States	0101000020E6100000A7E8482EFF1156C0A2B437F8C2044540	USA > Illinois > Kane County > Elgin	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Burial place of Earl Wayne Reed Sr (P-0062) in 1974 per FS PID M3P5-XF6.	\N	\N
PL-5236	Algona, Kossuth, Iowa, United States	Algona, Kossuth County, Iowa, United States	0101000020E6100000098A1F63EE8E57C0454772F90F894540	USA > Iowa > Kossuth County > Algona	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Site of Estelle's second marriage (1912-09-18) to Clarence D. Eichinger.	\N	\N
PL-5237	Waterloo, Black Hawk, Iowa, United States	Waterloo, Black Hawk County, Iowa, United States	0101000020E610000004E78C28ED1557C002BC0512143F4540	USA > Iowa > Black Hawk County > Waterloo	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	1925 Iowa State Census residence of the Eichinger household (Clarence + Estelle + Ray + Edna).	\N	\N
PL-5238	Queen of Heaven Catholic Cemetery, Hillside, Cook, Illinois, United States	Queen of Heaven Catholic Cemetery, Hillside, Cook County, Illinois, United States	0101000020E6100000F5E3E59FCFFA55C0EC43280010EC4440	United States > Illinois > Cook County > Hillside	cemetery	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Roman Catholic cemetery, consecrated 1947, 472 acres, ~122,000+ burials. Operated by Catholic Cemeteries of the Archdiocese of Chicago. GPS from FindAGrave memorial #288488976; FS extract gave less precise (41.8578, -87.9091). Plot for Ugo Mariotti: Section 40, Block 213, Lot 7, Grave 8.	\N	\N
PL-5239	Bedford, Taylor, Iowa, United States	Bedford, Taylor County, Iowa, United States	0101000020E6100000984C158C4AAE57C0F7065F984C554440	United States > Iowa > Taylor County > Bedford	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	County seat of Taylor County, southwestern Iowa near MO border. Ugo Mariotti's primary residence ~1928–~1950+ (per 1930, 1940, 1950 censuses; 1927 marriage was in nearby Lenox, also Taylor Co). Proprietor of a candy kitchen here per 1950 census.	\N	\N
PL-5240	Lenox, Taylor, Iowa, United States	Lenox, Taylor County, Iowa, United States	0101000020E61000005C8FC2F528A457C0B7627FD93D714440	United States > Iowa > Taylor County > Lenox	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Small town in Taylor County, IA where Ugo Mariotti and Lena Dini were married 5 May 1927.	\N	\N
PL-5241	Ellis Island, New York City, New York, United States	Ellis Island, New York City, New York, United States	0101000020E61000004A0C022B878252C0A8C64B3789594440	United States > New York > New York City > Ellis Island	address	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	U.S. immigration inspection station 1892-1954. Point of arrival for Ugo Mariotti 3 Sep 1920 aboard SS Giuseppe Verdi from Genoa.	\N	\N
PL-5242	Genoa, Liguria, Italy	Genoa, Liguria, Italy	0101000020E6100000DC68006F81E42140F9A067B3EA334640	Italy > Liguria > Genoa	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Port of departure for Ugo Mariotti on SS Giuseppe Verdi, August 1920 — the principal Italian emigration port for Tuscan and Ligurian departures (Naples and Palermo dominated southern Italian streams).	\N	\N
PL-5243	Westchester, Cook County, Illinois	Westchester, Cook County, Illinois, United States	0101000020E6100000CD3B4ED191F855C022FDF675E0EC4440	USA > Illinois > Cook County	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	John & Leah Reed's first marital home, ~1956 (Leah's 2025 obituary).	\N	\N
PL-5244	Marine Corps Base Camp Pendleton, California	Marine Corps Base Camp Pendleton, San Diego County, California, United States	0101000020E6100000711B0DE02D645DC036AB3E575BB14040	USA > California > San Diego County	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	Recalled by family as John's training base during Korean War service — UNCONFIRMED. Camp Pendleton is a USMC installation, implying Marine Corps. Used as the place anchor for the military-service event below; revise if branch/base is documented otherwise.	\N	\N
PL-18465	Saint-Cosme-en-Vairais, Sarthe, France	Saint-Cosme-en-Vairais, Sarthe, France	0101000020E6100000713D0AD7A370DD3FEC2FBB270F234840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-18603	Sainte-Anne-de-Beaupré, Québec, Canada, New France	Sainte-Anne-de-Beaupré, Québec, Canada, New France	0101000020E61000006ADE718A8EBC51C0EEEBC03923824740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-18742	Maulais, Poitou, France	Maulais, Poitou, France	0101000020E61000001D5A643BDF4FC5BF3A92CB7F48774740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-18882	Saint-Sauveur, Paris, France	Saint-Sauveur, Paris, France	0101000020E6100000E23B31EBC5D0024025E99AC9376F4840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-19023	Sainte-Famille, L'Île-d'Orléans, Quebec, Canada	Sainte-Famille, L'Île-d'Orléans, Quebec, Canada	0101000020E6100000C4B12E6EA3BD51C06ADE718A8E7C4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-19024	Saint-Laurent-de-l'Île-d'Orléans, L'Île-d'Orléans, Quebec, Canada	Saint-Laurent-de-l'Île-d'Orléans, L'Île-d'Orléans, Quebec, Canada	0101000020E61000008D28ED0DBEC051C090A0F831E66E4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-19593	Quebec City, Quebec, Canada East, British North America	Quebec City, Quebec, Canada East, British North America	0101000020E6100000053411363CCD51C039D6C56D34684740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-19737	Québec, Canada, New France	Québec, Canada, New France	0101000020E6100000304CA60A46CD51C0E3A59BC420684740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-19882	Chateau Richer, La Côte-de-Beaupré, Quebec, Canada	Chateau Richer, La Côte-de-Beaupré, Quebec, Canada	0101000020E61000009A779CA223C151C032772D211F7C4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-20173	Ocqueville, Normandy, France	Ocqueville, Normandy, France	0101000020E6100000D95F764F1E16E63F11C7BAB88DE64840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-20612	Notre-Dame de Québec, Quebec City, Québec, Canada, New France	Notre-Dame de Québec, Quebec City, Québec, Canada, New France	0101000020E610000029ED0DBE30CD51C00EBE30992A684740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-20907	Gascony, France	Gascony, France	0101000020E6100000BA490C022B87C6BF931804560EFD4540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-21056	Beaumais, Normandy, France	Beaumais, Normandy, France	0101000020E610000074B515FBCBEEF13FDAACFA5C6DED4840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-21206	Quebec City, Québec, Canada, New France	Quebec City, Québec, Canada, New France	0101000020E6100000053411363CCD51C039D6C56D34684740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-21357	Coulonges, Angoumois, France	Coulonges, Angoumois, France	0101000020E6100000280F0BB5A679B73F423EE8D9ACEA4640	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-21509	Normandel, Perche, France	Normandel, Perche, France	0101000020E6100000956588635DDCE63F26E4839ECD524840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-21662	Saint-Aubin, Tourouvre, Orne, France	Saint-Aubin, Tourouvre, Orne, France	0101000020E6100000B30C71AC8BDBE43F4182E2C7984B4840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-21969	Oise, France	Oise, France	0101000020E610000000000000000004400000000000C04840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-21970	Savigny, Saône-et-Loire, France	Savigny, Saône-et-Loire, France	0101000020E610000016C26A2C619D1040D07EA4880C6F4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-22281	France	France	0101000020E610000000000000000000400000000000004740	\N	region	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-22282	Deschambault, Québec, Canada, New France	Deschambault, Québec, Canada, New France	0101000020E61000008F53742497FB51C06DE7FBA9F1524740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-23068	Notre-Dame-de-Bon-Secours, Québec, Canada, New France	Notre-Dame-de-Bon-Secours, Québec, Canada, New France	0101000020E6100000E4141DC9E59751C09C33A2B437904740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-23227	Deerfield, Hampshire, Massachusetts Bay Colony, British Colonial America	Deerfield, Hampshire, Massachusetts Bay Colony, British Colonial America	0101000020E610000040DD4081772752C01381EA1F44444540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-23387	Westfield, Hampshire, Massachusetts Bay Colony, British Colonial America	Westfield, Hampshire, Massachusetts Bay Colony, British Colonial America	0101000020E610000000000000003052C0399CF9D51C104540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-24028	Hartford, Hartford, Connecticut Colony, British Colonial America	Hartford, Hartford, Connecticut Colony, British Colonial America	0101000020E6100000006F8104C52B52C06EA301BC05E24440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-24351	Windsor, Connecticut Colony, British Colonial America	Windsor, Connecticut Colony, British Colonial America	0101000020E6100000AC730CC85E2952C0B03DB32440ED4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-25000	Simsbury, Hartford, Connecticut Colony, British Colonial America	Simsbury, Hartford, Connecticut Colony, British Colonial America	0101000020E61000005B423EE8D93452C0E5F21FD26FEF4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-25164	Billerica, Middlesex, Massachusetts Bay Colony, British Colonial America	Billerica, Middlesex, Massachusetts Bay Colony, British Colonial America	0101000020E6100000CCD1E3F736D151C0B30C71AC8B474540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-25165	Colchester, New London, Connecticut, United States	Colchester, New London, Connecticut, United States	0101000020E6100000F7065F984C1552C044696FF085C94440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-25331	New London, Connecticut Colony, British Colonial America	New London, Connecticut Colony, British Colonial America	0101000020E6100000F5673F52440452C07D96E7C1DDBD4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-25830	Wethersfield, Hartford, Connecticut Colony, British Colonial America	Wethersfield, Hartford, Connecticut Colony, British Colonial America	0101000020E61000007B14AE47E12A52C00473F4F8BDD94440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-25998	Hartford, Connecticut Colony, British Colonial America	Hartford, Connecticut Colony, British Colonial America	0101000020E61000001F85EB51B82E52C048E17A14AEE74440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-25999	Rhode Island, British Colonial America	Rhode Island, British Colonial America	0101000020E61000000000000000E051C09A99999999D94440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-26169	Boston, Massachusetts Bay Colony, British Colonial America	Boston, Massachusetts Bay Colony, British Colonial America	0101000020E610000087A2409FC8C351C012C2A38D232E4540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-26170	Hadley, Hampshire, Massachusetts Bay Colony, British Colonial America	Hadley, Hampshire, Massachusetts Bay Colony, British Colonial America	0101000020E6100000BA6B09F9A02552C01CB1169F022C4540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-26513	Taunton, Somerset, England	Taunton, Somerset, England	0101000020E6100000EBE2361AC0DB08C06EA301BC05824940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-26514	Northampton, Hampshire, Massachusetts Bay Colony, British Colonial America	Northampton, Hampshire, Massachusetts Bay Colony, British Colonial America	0101000020E6100000172B6A300D2952C0A81DFE9AAC294540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-26688	Bridport, Dorset, England	Bridport, Dorset, England	0101000020E6100000CB10C7BAB80D06C076711B0DE05D4940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-26863	Kenilworth, Warwickshire, England	Kenilworth, Warwickshire, England	0101000020E6100000234A7B832F4CF9BFCDCCCCCCCC2C4A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-27039	Dorchester, Suffolk, Massachusetts Bay Colony, British Colonial America	Dorchester, Suffolk, Massachusetts Bay Colony, British Colonial America	0101000020E6100000EA5BE67459C451C0499D8026C2264540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-27216	London, England	London, England	0101000020E6100000C7293A92CB7FC0BFD3BCE3141DC14940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-27571	Connecticut Panhandle, New York Colony, British Colonial America	Connecticut Panhandle, New York Colony, British Colonial America	0101000020E61000003EB14E95EF5F52C045D95BCAF98E4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-28284	Wales	Wales	0101000020E61000006F9EEA909B210EC0183E22A6442A4A40	\N	region	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-28285	Colchester, Hartford, Connecticut Colony, British Colonial America	Colchester, Hartford, Connecticut Colony, British Colonial America	0101000020E6100000F7065F984C1552C044696FF085C94440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-28466	Ashfield, Franklin, Massachusetts, United States	Ashfield, Franklin, Massachusetts, United States	0101000020E610000098DD9387853252C0C139234A7B434540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-28467	Salem, Essex, Massachusetts, United States	Salem, Essex, Massachusetts, United States	0101000020E6100000273108AC1CBA51C0A8C64B3789414540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-28650	Rowley, Massachusetts Bay Colony, British Colonial America	Rowley, Massachusetts Bay Colony, British Colonial America	0101000020E6100000D578E92631B851C08E1EBFB7E95B4540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-29017	Tarvin, Cheshire, England	Tarvin, Cheshire, England	0101000020E6100000431CEBE2361A06C0E2E995B20C994A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-29018	Suffield, Hartford, Connecticut Colony, British Colonial America	Suffield, Hartford, Connecticut Colony, British Colonial America	0101000020E6100000F5673F52442C52C07D96E7C1DDFD4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-29204	Marshwood, Dorset, England	Marshwood, Dorset, England	0101000020E610000068B3EA73B51507C0CC7F48BF7D654940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-29949	New Haven, Connecticut Colony, British Colonial America	New Haven, Connecticut Colony, British Colonial America	0101000020E61000009A999999993952C0CDCCCCCCCCAC4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-30324	Saint-Joseph, Deschambault, Québec, Canada, New France	Saint-Joseph, Deschambault, Québec, Canada, New France	0101000020E6100000058BC3995FFB51C05036E50AEF524740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-30701	Île-d'Orléans, Canada, New France	Île-d'Orléans, Canada, New France	0101000020E6100000C442AD69DEBD51C0BE9F1A2FDD744740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-32214	Saint-Jean-Baptiste, District Judiciaire de Québec, Quebec, British North America	Saint-Jean-Baptiste, District Judiciaire de Québec, Quebec, British North America	0101000020E6100000295C8FC2F5B851C02041F163CC754740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-33735	Charlesbourg, Québec, Canada, New France	Charlesbourg, Québec, Canada, New France	0101000020E6100000F7065F984CD151C091ED7C3F356E4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-34500	Île d'Orléans, Québec, Canada, New France	Île d'Orléans, Québec, Canada, New France	0101000020E61000000F0BB5A679BB51C065AA605452774740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-34693	La Rochelle, Aunis, France	La Rochelle, Aunis, France	0101000020E61000007E1D38674469F2BF3FC6DCB584144740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-34887	Notre-Dame-de-Cougnes, La Rochelle, Aunis, France	Notre-Dame-de-Cougnes, La Rochelle, Aunis, France	0101000020E61000002D211FF46C56F2BFDB8AFD65F7144740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-35082	Isle Dieu, Poitou, France	Isle Dieu, Poitou, France	0101000020E61000002A3A92CB7FC802C0B459F5B9DA5A4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-35473	Charente, France	Charente, France	0101000020E6100000A5BDC1172653B53F4C37894160D54640	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-35670	Saint-Benoît, Seine-et-Oise, France	Saint-Benoît, Seine-et-Oise, France	0101000020E61000001DC87A6AF595FE3F4AD235936F564840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-35868	Maillezais, Vendée, France	Maillezais, Vendée, France	0101000020E6100000BB270F0BB5A6E7BF01DE02098A2F4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-36067	Rennes, Brittany, France	Rennes, Brittany, France	0101000020E610000026E4839ECDAAFABF211FF46C56154840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-36267	Laleu, Aunis, France	Laleu, Aunis, France	0101000020E6100000ABCFD556EC2FF3BF21B0726891154740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-36668	Saint-Germain-de-Prinçay, Vendée, France	Saint-Germain-de-Prinçay, Vendée, France	0101000020E6100000F2D24D621058F0BF07F01648505C4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-36870	Paris, France	Paris, France	0101000020E6100000ED0DBE3099AA0240BBB88D06F06E4840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-37073	Estouteville-Écalles, Seine-Maritime, France	Estouteville-Écalles, Seine-Maritime, France	0101000020E6100000BEC117265305F53F2497FF907ECB4840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-37480	Normandy, France	Normandy, France	0101000020E6100000295C8FC2F528BCBF48E17A14AE874840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-37889	Le Havre, Normandy, France	Le Havre, Normandy, France	0101000020E61000002DB29DEFA7C6BB3FD734EF3845BF4840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-38095	Angoumois, France	Angoumois, France	0101000020E61000009A9999999999C93F6666666666E64640	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-38302	Étusson, Deux-Sèvres, France	Étusson, Deux-Sèvres, France	0101000020E6100000691D554D1075E0BF529B38B9DF814740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-38717	Monsummano, Lucca, Tuscany, Italy	Monsummano, Lucca, Tuscany, Italy	0101000020E6100000C4B12E6EA3A125401DC9E53FA4EF4540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-42254	At Sea	At Sea	0101000020E610000000000000000044C00000000000003E40	\N	region	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-42464	Norwalk, Fairfield, Connecticut Colony, British Colonial America	Norwalk, Fairfield, Connecticut Colony, British Colonial America	0101000020E6100000D6726726185B52C0BDE47FF2778F4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-42465	Family, Glacier, Montana, United States	Family, Glacier, Montana, United States	0101000020E61000008F537424972F5CC0A1F831E6AE3D4840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-42677	Lancaster, Middlesex, Massachusetts Bay Colony, British Colonial America	Lancaster, Middlesex, Massachusetts Bay Colony, British Colonial America	0101000020E6100000454772F90FEB51C05F7B6649803A4540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-42678	Princeton, Somerset, New Jersey, British Colonial America	Princeton, Somerset, New Jersey, British Colonial America	0101000020E6100000E0BE0E9C33AA52C0F7E461A1D62C4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-42892	Colonels Island, Suffolk, New York Colony, British Colonial America	Colonels Island, Suffolk, New York Colony, British Colonial America	0101000020E61000004C361E6CB12852C05A9E077767754440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-42893	Stony Brook, Mercer, New Jersey, United States	Stony Brook, Mercer, New Jersey, United States	0101000020E6100000910F7A36ABAA52C0545227A089284440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-43109	Stanway Hall, Essex, England	Stanway Hall, Essex, England	0101000020E61000008B71FE261422EA3FB0C91AF510F14940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-43326	Scituate, Plymouth Colony, British Colonial America	Scituate, Plymouth Colony, British Colonial America	0101000020E610000072FE261422B251C01D03B2D7BB1B4540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-43544	Poitiers, Vienne, France	Poitiers, Vienne, France	0101000020E610000067D5E76A2BF6D33F7689EAAD81494740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-43763	Hertfordshire, England	Hertfordshire, England	0101000020E610000036EA211ADD41C8BFC9B08A3732EB4940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-43983	County Tipperary, Ireland	County Tipperary, Ireland	0101000020E6100000295C8FC2F5A81FC0CDCCCCCCCC4C4A40	\N	county	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-43984	Woodbridge Township, Middlesex, New Jersey, British Colonial America	Woodbridge Township, Middlesex, New Jersey, British Colonial America	0101000020E6100000910F7A36AB9252C0545227A089484440	\N	township	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-44427	North Wingfield, Derbyshire, England	North Wingfield, Derbyshire, England	0101000020E610000062A1D634EF38F6BFACADD85F76974A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-44428	Springfield, Burlington, New Jersey, British Colonial America	Springfield, Burlington, New Jersey, British Colonial America	0101000020E610000023DBF97E6AAC52C0B1E1E995B2044440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-44652	Morton, Derbyshire, England	Morton, Derbyshire, England	0101000020E6100000F1F44A598638F6BF5227A089B0914A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-44653	Mansfield Township, Burlington, New Jersey, British Colonial America	Mansfield Township, Burlington, New Jersey, British Colonial America	0101000020E6100000A9A44E4013A952C0454772F90FF14340	\N	township	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-44879	Norfolk, England	Norfolk, England	0101000020E610000007616EF7721FEF3F0072C284D1564A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-44880	Burlington, Burlington, New Jersey, British Colonial America	Burlington, Burlington, New Jersey, British Colonial America	0101000020E6100000B4AB90F293B652C0D925AAB7060A4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-45108	Little Dunmow, Essex, England, United Kingdom	Little Dunmow, Essex, England, United Kingdom	0101000020E6100000BA6B09F9A067D73F73D712F241EF4940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-45109	Burlington, Burlington, New Jersey, United States	Burlington, Burlington, New Jersey, United States	0101000020E6100000D881734694B652C06EA301BC050A4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-45339	Brampton, Suffolk, England	Brampton, Suffolk, England	0101000020E61000009BE61DA7E848F93F1B2FDD2406314A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-45570	England, United Kingdom	England, United Kingdom	0101000020E6100000A2B437F8C264FABF8E75711B0D384A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-46495	Mareuil-le-Port, Marne, France	Mareuil-le-Port, Marne, France	0101000020E61000009FABADD85FF60D40D122DBF97E8A4840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-46728	Burntisland, Fife, Scotland	Burntisland, Fife, Scotland	0101000020E61000000612143FC6DC09C0ACADD85F76074C40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-46729	Prince George, British Columbia, British North America	Prince George, British Columbia, British North America	0101000020E6100000F775E09C11B15EC0211FF46C56F54A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-46964	Harberton, Devon, England, United Kingdom	Harberton, Devon, England, United Kingdom	0101000020E61000009BE61DA7E8C80DC0A1D634EF38354940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-47200	Visnum, Värmland, Sweden	Visnum, Värmland, Sweden	0101000020E6100000D4B5F63E55552C40213D450E11914D40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-47437	Liden, Västernorrland, Sweden	Liden, Västernorrland, Sweden	0101000020E6100000CDCCCCCCCCCC30409A99999999594F40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-47438	Backen, Liden, Västernorrland, Sweden	Backen, Liden, Västernorrland, Sweden	0101000020E610000051C1E10511D1304087A3AB7477574F40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-48395	Conistone, Yorkshire, England	Conistone, Yorkshire, England	0101000020E6100000B81E85EB513800C0789CA223B90C4B40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-48396	Buckingham, Buckinghamshire, England	Buckingham, Buckinghamshire, England	0101000020E610000040A4DFBE0E9CEFBF0000000000004A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-48879	Shillingford, Oxfordshire, England	Shillingford, Oxfordshire, England	0101000020E6100000FC3559A31E22F2BF5036E50AEFCE4940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-49848	West Boldon, Durham, England	West Boldon, Durham, England	0101000020E6100000A4DFBE0E9C33F7BFF085C954C1784B40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-50335	Bernshammar, Hed, Västmanland, Sweden	Bernshammar, Hed, Västmanland, Sweden	0101000020E61000000000000000802F4075ADBD4F55D54D40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-51068	Fryksdal, Värmland, Sweden	Fryksdal, Värmland, Sweden	0101000020E610000003098A1F636E2A40304CA60A46DD4D40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-51069	Christiana, New Castle, Delaware, United States	Christiana, New Castle, Delaware, United States	0101000020E61000002063EE5A42EA52C085EB51B81ED54340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-51808	Pennsylvania, British Colonial America	Pennsylvania, British Colonial America	0101000020E61000007F6ABC7493E052C0D9CEF753E3254440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-51809	Gloucester, New Jersey, United States	Gloucester, New Jersey, United States	0101000020E6100000D8648D7A88C852C07D96E7C1DDDD4340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-52058	Beccles, Suffolk, England, United Kingdom	Beccles, Suffolk, England, United Kingdom	0101000020E6100000228E75711B0DF93FED9E3C2CD43A4A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-52557	Stoke Climsland, Cornwall, England	Stoke Climsland, Cornwall, England	0101000020E6100000A54E4013614311C0A01A2FDD24464940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-52808	Chester, Pennsylvania, United States	Chester, Pennsylvania, United States	0101000020E6100000CBA145B6F3ED52C05839B4C876FE4340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-53060	Länna, Uppsala, Sweden	Länna, Uppsala, Sweden	0101000020E6100000832F4CA60AF63140F241CF66D5EF4D40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-53313	New Amsterdam, New Netherland	New Amsterdam, New Netherland	0101000020E610000000000000008052C008AC1C5A645B4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-53314	New York County, New York Colony, British Colonial America	New York County, New York Colony, British Colonial America	0101000020E61000008E01D9EBDD7D52C0E3FC4D2844644440	\N	county	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-53569	Klara, Stockholm, Sweden	Klara, Stockholm, Sweden	0101000020E6100000C7293A92CB0F3240EE7C3F355EAA4D40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-54590	New Sweden, Sweden	New Sweden, Sweden	0101000020E6100000A69BC420B0EA52C09A99999999D94340	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-55103	Merionethshire, Wales	Merionethshire, Wales	0101000020E61000004149810530050FC06D020CCB9F5F4A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-55361	Wales, United Kingdom	Wales, United Kingdom	0101000020E61000006F9EEA909B210EC0183E22A6442A4A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-55620	Avebury, Wiltshire, England	Avebury, Wiltshire, England	0101000020E610000004CAA65CE1DDFDBFB79C4B7155B54940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-55880	Bradford Hills, West Whiteland Township, Chester, Pennsylvania, United States	Bradford Hills, West Whiteland Township, Chester, Pennsylvania, United States	0101000020E6100000CC7F48BF7DE952C00E4FAF9465004440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-56141	Staffordshire, England, United Kingdom	Staffordshire, England, United Kingdom	0101000020E61000005C5A0D897BACFEBFD673D2FBC6634A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-56142	Birmingham Township, Chester, Pennsylvania, British Colonial America	Birmingham Township, Chester, Pennsylvania, British Colonial America	0101000020E6100000BADA8AFD65E752C0787AA52C43F44340	\N	township	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-56405	Sedgley, Staffordshire, England	Sedgley, Staffordshire, England	0101000020E610000090C01F7EFEFB00C0904E5DF92C454A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-56669	Netherlands	Netherlands	0101000020E610000000000000000017400000000000404A40	\N	region	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-56934	Oldenburg, Lower Saxony, Germany	Oldenburg, Lower Saxony, Germany	0101000020E6100000764F1E166A6D20400BB5A679C7914A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-57200	Ireland	Ireland	0101000020E610000000000000000020C00000000000804A40	\N	region	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-58797	Covington, Huntingdonshire, England	Covington, Huntingdonshire, England	0101000020E6100000EE5A423EE8D9DCBFB6F3FDD478294A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-59065	St Andrew's Church, Holborn, Middlesex, England	St Andrew's Church, Holborn, Middlesex, England	0101000020E6100000A51309A69A59BBBF6C5ED5592DC24940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-59334	Great Yarmouth, Norfolk, England, United Kingdom	Great Yarmouth, Norfolk, England, United Kingdom	0101000020E6100000014D840D4FAFFB3FA323B9FC874C4A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-59604	Great Berkhampstead, Hertfordshire, England	Great Berkhampstead, Hertfordshire, England	0101000020E61000004CFE277FF70EE2BF2785798F33E34940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-59875	Blyth, Nottinghamshire, England, United Kingdom	Blyth, Nottinghamshire, England, United Kingdom	0101000020E6100000E9482EFF21FDF0BF2AA913D044B04A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-60418	Braintree, Massachusetts Bay Colony, British Colonial America	Braintree, Massachusetts Bay Colony, British Colonial America	0101000020E61000003C6BB75D68C051C07BDAE1AFC91A4540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-60419	Bridgewater, Plymouth Colony, British Colonial America	Bridgewater, Plymouth Colony, British Colonial America	0101000020E6100000C442AD69DEBD51C088855AD3BCFB4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-60693	Duxbury, Plymouth Colony, British Colonial America	Duxbury, Plymouth Colony, British Colonial America	0101000020E61000008E01D9EBDDAD51C0E3FC4D2844044540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-60968	Bristol, England	Bristol, England	0101000020E6100000BF0E9C33A2B404C06E3480B740BA4940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-61519	Horsham, Sussex, England	Horsham, Sussex, England	0101000020E610000088855AD3BCE3D4BF2B1895D409884940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-61520	Norwalk, Connecticut Colony, British Colonial America	Norwalk, Connecticut Colony, British Colonial America	0101000020E6100000D6726726185B52C0BDE47FF2778F4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-61798	Great Bentley, Essex, England	Great Bentley, Essex, England	0101000020E61000005AF5B9DA8AFDF03F92CB7F48BFED4940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-62077	White Colne, Essex, England	White Colne, Essex, England	0101000020E61000003D2CD49AE61DE73FD712F241CFF64940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-62357	Cranbrook, Kent, England	Cranbrook, Kent, England	0101000020E6100000158C4AEA0434E13F5C2041F1638C4940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-62638	Charlestown, Massachusetts Bay Colony, British Colonial America	Charlestown, Massachusetts Bay Colony, British Colonial America	0101000020E61000000000000000C451C09C8A54185B304540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-62920	Yarmouth, Barnstable, Massachusetts Bay Colony, British Colonial America	Yarmouth, Barnstable, Massachusetts Bay Colony, British Colonial America	0101000020E610000032755776C18E51C0B3EDB43522DA4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-63203	Scituate, Plymouth, Massachusetts Bay Colony, British Colonial America	Scituate, Plymouth, Massachusetts Bay Colony, British Colonial America	0101000020E610000072FE261422B251C01D03B2D7BB1B4540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-63204	Barnstable, Barnstable, Massachusetts Bay Colony, British Colonial America	Barnstable, Barnstable, Massachusetts Bay Colony, British Colonial America	0101000020E610000040DD4081779751C046B41D5377D74440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-63773	Market Harborough, Leicestershire, England	Market Harborough, Leicestershire, England	0101000020E6100000B0726891ED7CEDBF69006F81043D4A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-64059	Kildwick, Yorkshire, England	Kildwick, Yorkshire, England	0101000020E6100000DE9387855AD3FFBF4D840D4FAFF44A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-64632	Sudbury, Middlesex, Massachusetts Bay Colony, British Colonial America	Sudbury, Middlesex, Massachusetts Bay Colony, British Colonial America	0101000020E6100000731074B4AADA51C0B0C91AF510314540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-65494	Boston, Suffolk, Massachusetts Bay Colony, British Colonial America	Boston, Suffolk, Massachusetts Bay Colony, British Colonial America	0101000020E610000087A2409FC8C351C012C2A38D232E4540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-65783	Roxbury, Massachusetts Bay Colony, British Colonial America	Roxbury, Massachusetts Bay Colony, British Colonial America	0101000020E610000072FE261422C651C09A99999999294540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-66362	Kingsthorpe, Northamptonshire, England	Kingsthorpe, Northamptonshire, England	0101000020E61000004F1E166A4DF3ECBFEF38454772214A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-66653	Glapwell, Derbyshire, England	Glapwell, Derbyshire, England	0101000020E6100000ED478AC8B08AF4BFB1DCD26A48984A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-66945	Downham, Cambridgeshire, England	Downham, Cambridgeshire, England	0101000020E6100000000000000000D03F1630815B77374A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-67238	Ely, Cambridgeshire, England	Ely, Cambridgeshire, England	0101000020E6100000CDCCCCCCCCCCD03F4260E5D022334A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-67532	Somerset, England	Somerset, England	0101000020E61000002E76FBAC323307C0F302ECA3538F4940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-67827	Chard, Somerset, England	Chard, Somerset, England	0101000020E6100000F46C567DAEB607C0643BDF4F8D6F4940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-68123	Dorset, England	Dorset, England	0101000020E6100000F06DFAB31F2901C065E256410C624940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-68716	Killingworth, New London, Connecticut Colony, British Colonial America	Killingworth, New London, Connecticut Colony, British Colonial America	0101000020E6100000AA605452272452C04B598638D6AD4440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-69608	Devon, England, United Kingdom	Devon, England, United Kingdom	0101000020E6100000A5DDE8633EC00DC0F5673F52445E4940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-69907	Bermondsey, Surrey, England	Bermondsey, Surrey, England	0101000020E6100000B1E1E995B20CB1BF9E5E29CB10BF4940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-70506	Keynsham, Somerset, England	Keynsham, Somerset, England	0101000020E610000011C7BAB88D0604C0A1D634EF38B54940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-70807	Crewkerne, Somerset, England	Crewkerne, Somerset, England	0101000020E6100000CAC342AD695E06C0613255302A714940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-71109	Somerset, England, United Kingdom	Somerset, England, United Kingdom	0101000020E61000002E76FBAC323307C0F302ECA3538F4940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-72016	Staffordshire, England	Staffordshire, England	0101000020E61000005C5A0D897BACFEBFD673D2FBC6634A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-72320	Devon, England	Devon, England	0101000020E6100000A5DDE8633EC00DC0F5673F52445E4940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-72321	Westfield, Massachusetts Bay Colony, British Colonial America	Westfield, Massachusetts Bay Colony, British Colonial America	0101000020E610000000000000003052C0399CF9D51C104540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-73542	Grantham, Lincolnshire, England, United Kingdom	Grantham, Lincolnshire, England, United Kingdom	0101000020E6100000711B0DE02D90E4BF789CA223B9744A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-73543	Andover, Essex, Massachusetts, United States	Andover, Essex, Massachusetts, United States	0101000020E61000001B2FDD2406C951C040A4DFBE0E544540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-73851	Shipton, Gloucestershire, England	Shipton, Gloucestershire, England	0101000020E6100000EB707495EEEEFEBFCDCCCCCCCCEC4940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-74160	Wantage, Berkshire, England	Wantage, Berkshire, England	0101000020E61000006DE7FBA9F1D2F6BF6C09F9A067CB4940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-74470	Toddington, Bedfordshire, England	Toddington, Bedfordshire, England	0101000020E6100000EC2FBB270F0BE1BF287E8CB96BF94940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-74781	Rattlesden, Suffolk, England	Rattlesden, Suffolk, England	0101000020E610000093A98251499DEC3FF085C954C1184A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-91392	Segonzac, Charente, France	Segonzac, Charente, France	0101000020E61000002B8716D9CEF7CBBFC976BE9F1ACF4640	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-74782	Bradford, Essex, Massachusetts Bay Colony, British Colonial America	Bradford, Essex, Massachusetts Bay Colony, British Colonial America	0101000020E610000074EFE192E3C451C0FC1D8A027D624540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-75095	Burton upon Trent, Staffordshire, England	Burton upon Trent, Staffordshire, England	0101000020E6100000C976BE9F1A2FFABF2AA913D044684A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-75409	Bedworth, Warwickshire, England	Bedworth, Warwickshire, England	0101000020E61000008CDB68006F81F7BF1283C0CAA13D4A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-75724	Axminster, Devon, England	Axminster, Devon, England	0101000020E6100000DC9E20B1DDDD07C084F4143944644940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-75725	Dorchester, Massachusetts Bay Colony, British Colonial America	Dorchester, Massachusetts Bay Colony, British Colonial America	0101000020E6100000EA5BE67459C451C0499D8026C2264540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-76042	Yarcombe, Devon, England	Yarcombe, Devon, England	0101000020E6100000787AA52C439C08C0F1F44A5986704940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-76043	Dorset, England, United Kingdom	Dorset, England, United Kingdom	0101000020E6100000F06DFAB31F2901C065E256410C624940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-76680	Pitminster, Somerset, England	Pitminster, Somerset, England	0101000020E6100000EFC9C342ADE908C016FBCBEEC97B4940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-77000	Coggeshall, Essex, England	Coggeshall, Essex, England	0101000020E61000004703780B2428E63F9D8026C286EF4940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-77961	Barnstaple, Devon, England	Barnstaple, Devon, England	0101000020E6100000789CA223B93C10C0D200DE02098A4940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-78283	Ringstead, Northamptonshire, England	Ringstead, Northamptonshire, England	0101000020E6100000C8073D9B559FE1BFCAC342AD692E4A40	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-78284	Newhaven Towne, New Haven, Connecticut Colony, British Colonial America	Newhaven Towne, New Haven, Connecticut Colony, British Colonial America	0101000020E6100000A5BDC117263B52C048E17A14AEA74440	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-79577	Clermont-Créans, Maine, France	Clermont-Créans, Maine, France	0101000020E6100000B98D06F0164890BF7958A835CDDB4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-80226	Saint-Pierre-des-Échaubrognes, Deux-Sèvres, France	Saint-Pierre-des-Échaubrognes, Deux-Sèvres, France	0101000020E610000028F224E99AC9E7BF51A5660FB47E4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-81527	Nalliers, Vendée, France	Nalliers, Vendée, France	0101000020E61000009CC420B07268F0BFDCD78173463C4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-81528	Hôtel-Dieu, Quebec City, Québec, Canada, New France	Hôtel-Dieu, Quebec City, Québec, Canada, New France	0101000020E610000068226C787ACD51C07FD93D7958684740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-81856	La Ventrouze, Orne, France	La Ventrouze, Orne, France	0101000020E6100000D734EF384547E63F03780B24284E4840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-82185	Vannes, Morbihan, France	Vannes, Morbihan, France	0101000020E61000006B2BF697DD1306C0F931E6AE25D44740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-82186	Quebec City, Quebec, Canada	Quebec City, Quebec, Canada	0101000020E6100000053411363CCD51C039D6C56D34684740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-82517	Notre-Dame-du-Rocher, Orne, France	Notre-Dame-du-Rocher, Orne, France	0101000020E6100000386744696FF0D9BF12143FC6DC654840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-82849	Dieppe, Normandy, France	Dieppe, Normandy, France	0101000020E610000058A835CD3B4EF13FBC74931804F64840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-83182	Dieppe, Seine-Maritime, France	Dieppe, Seine-Maritime, France	0101000020E610000058A835CD3B4EF13FBC74931804F64840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-83516	Berneval-le-Grand, Seine-Maritime, France	Berneval-le-Grand, Seine-Maritime, France	0101000020E6100000E25817B7D100F33F6E3480B740FA4840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-84185	Bordeaux, Gironde, France	Bordeaux, Gironde, France	0101000020E61000003BDF4F8D976EE2BF6C787AA52C6B4640	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-84186	Sainte-Famille, Québec, Canada, New France	Sainte-Famille, Québec, Canada, New France	0101000020E6100000D3DEE00B93BD51C0226C787AA57C4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-84859	Tourouvre, Orne, France	Tourouvre, Orne, France	0101000020E61000003B70CE88D2DEE43F3255302AA94B4840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-85197	La Rochelle, Charente-Maritime, France	La Rochelle, Charente-Maritime, France	0101000020E61000007E1D38674469F2BF3FC6DCB584144740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-85536	Saint-Rémy, Dieppe, Normandy, France	Saint-Rémy, Dieppe, Normandy, France	0101000020E61000007689EAAD812DF13F6666666666F64840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-85876	Saint-Vaast-d'Équiqueville, Seine-Maritime, France	Saint-Vaast-d'Équiqueville, Seine-Maritime, France	0101000020E6100000D6AD9E93DE37F43F30F0DC7BB8E84840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-86217	Sainte-Soule, Aunis, France	Sainte-Soule, Aunis, France	0101000020E61000008351499D8026F0BF006F8104C5174740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-86900	Combray, Calvados, France	Combray, Calvados, France	0101000020E61000007F6ABC749318DCBF8B6CE7FBA9794840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-87243	Nancy, Meurthe-et-Moselle, France	Nancy, Meurthe-et-Moselle, France	0101000020E61000007B14AE47E1BA1840D50968226C584840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-87244	Saint-François, Saint-Laurent, Québec, Canada, New France	Saint-François, Saint-Laurent, Québec, Canada, New France	0101000020E6100000B22E6EA301B451C02AA913D044804740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-88965	Fontenay-le-Comte, Vendée, France	Fontenay-le-Comte, Vendée, France	0101000020E6100000A54E401361C3E9BF083D9B559F3B4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-89656	L'Ile-d'Yeu, Vendée, France	L'Ile-d'Yeu, Vendée, France	0101000020E6100000764F1E166ACD02C0068195438B5C4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-90695	La Rochelle, Charente-Inférieure, France	La Rochelle, Charente-Inférieure, France	0101000020E61000007E1D38674469F2BF3FC6DCB584144740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-91043	Saintonge, Charente-Maritime, France	Saintonge, Charente-Maritime, France	0101000020E6100000000000000000E0BF4963B48EAAEA4640	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-92440	Le Comte, Ardèche, France	Le Comte, Ardèche, France	0101000020E6100000CBF27519FEF3114012F8C3CF7F894640	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-93141	Rennes, Ille-et-Vilaine, France	Rennes, Ille-et-Vilaine, France	0101000020E61000004F401361C3D3FABFE7FBA9F1D20D4840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-93844	Laleu, La Rochelle, Charente-Maritime, France	Laleu, La Rochelle, Charente-Maritime, France	0101000020E6100000ABCFD556EC2FF3BF21B0726891154740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-93845	Saint-Pierre-d'Oléron, Aunis, France	Saint-Pierre-d'Oléron, Aunis, France	0101000020E610000017D9CEF753E3F4BF1B9E5E29CBF84640	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-94552	Mortagne-au-Perche, Perche, France	Mortagne-au-Perche, Perche, France	0101000020E61000001B2FDD240681E13F3411363CBD424840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-94907	Courgeoût, Orne, France	Courgeoût, Orne, France	0101000020E6100000CC5D4BC8073DDF3F7E8CB96B09414840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-95263	Luçon, Vendée, France	Luçon, Vendée, France	0101000020E6100000D3DEE00B93A9F2BFE0BE0E9C333A4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-95620	Luçon, Poitou, France	Luçon, Poitou, France	0101000020E610000079E9263108ACF2BFE0BE0E9C333A4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-96335	Champs-Sur-Marne, Seine-et-Marne, France	Champs-Sur-Marne, Seine-et-Marne, France	0101000020E61000009A779CA223B9044021B07268916D4840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-96694	Goes, Zeeland, Netherlands	Goes, Zeeland, Netherlands	0101000020E610000072C45A7C0A200F404CA8E0F082C04940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-97054	Saint-Laurent, Cher, France	Saint-Laurent, Cher, France	0101000020E6100000CC7F48BF7D9D0140A2B437F8C29C4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-98135	Arrondissement d'Angoulême, Charente, France	Arrondissement d'Angoulême, Charente, France	0101000020E6100000A5BDC1172653B53F4C37894160D54640	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-98136	Angoulême, Charente, France	Angoulême, Charente, France	0101000020E61000003A234A7B832FC43F508D976E12D34640	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-98861	Charencey, Perche, France	Charencey, Perche, France	0101000020E610000011363CBD5296E73F00917EFB3A504840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-99225	La Poterie-au-Perche, Perche, France	La Poterie-au-Perche, Perche, France	0101000020E6100000933A014D840DE73F2AA913D044504840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-99590	Saint-Aubin, Tourouvre, Perche, France	Saint-Aubin, Tourouvre, Perche, France	0101000020E6100000B30C71AC8BDBE43F4182E2C7984B4840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-100321	Vienne, France	Vienne, France	0101000020E6100000499D8026C286DF3F7AC7293A923B4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-100688	Lubersac, Brive-la-Gaillarde, Corrèze, France	Lubersac, Brive-la-Gaillarde, Corrèze, France	0101000020E6100000AED4B3209437F63F59FAD005F5B94640	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-101790	Diocese of Lisieux, France	Diocese of Lisieux, France	0101000020E6100000956588635DDCC63F2A3A92CB7F884840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-102159	Cap-Saint-Ignace, Québec, Canada, New France	Cap-Saint-Ignace, Québec, Canada, New France	0101000020E6100000211FF46C569D51C0068195438B844740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-102898	Niort, Poitou, France	Niort, Poitou, France	0101000020E6100000E0BE0E9C33A2DCBF448B6CE7FB294740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-103269	Perche, France	Perche, France	0101000020E6100000ED9E3C2CD49A044045D8F0F44A514740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-103641	Saint-Vincent-Cramesnil, Seine-Maritime, France	Saint-Vincent-Cramesnil, Seine-Maritime, France	0101000020E61000008048BF7D1D38D73F713D0AD7A3C04840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-104386	Bréval, Yvelines, France	Bréval, Yvelines, France	0101000020E610000025068195438BF83F0C022B8716794840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-104760	Rouen, Seine-Maritime, France	Rouen, Seine-Maritime, France	0101000020E6100000000000000000F03F0000000000C04840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-105135	Canada, New France	Canada, New France	0101000020E6100000516B9A779C0253C054742497FFD04740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-105886	Saint-Martin-du-Vieux-Bellême, Orne, France	Saint-Martin-du-Vieux-Bellême, Orne, France	0101000020E6100000AC8BDB68006FE13F37894160E5304840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-106263	Gonneville-sur-Honfleur, Calvados, France	Gonneville-sur-Honfleur, Calvados, France	0101000020E61000005C8FC2F5285CCF3F8C4AEA0434B14840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-106641	Honfleur, Normandy, France	Honfleur, Normandy, France	0101000020E61000004B598638D6C5CD3F04560E2DB2B54840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-107020	Saint-Pierre-des-Ormes, Sarthe, France	Saint-Pierre-des-Ormes, Sarthe, France	0101000020E61000002497FF907EFBDA3F73D712F241274840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-108537	Salles, Angoumois, France	Salles, Angoumois, France	0101000020E6100000984C158C4AEAC43FA69BC420B0FA4640	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-108538	Marseille-en-Beauvaisis, Oise, France	Marseille-en-Beauvaisis, Oise, France	0101000020E6100000D044D8F0F44AFF3F6F8104C58FC94840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-110444	Joinville, Haute-Marne, France	Joinville, Haute-Marne, France	0101000020E6100000E4839ECDAA8F1440713D0AD7A3384840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-113501	Montecatini di Val Di Nievole, Lucca, Tuscany	Montecatini di Val Di Nievole, Lucca, Tuscany	0101000020E61000002EFF21FDF69525405F29CB10C7F24540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-114268	Valence, Charente, France	Valence, Charente, France	0101000020E610000083C0CAA145B6D33F36CD3B4ED1F14640	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-115037	Sarthe, France	Sarthe, France	0101000020E6100000A5BDC1172653B53F0000000000004840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-115038	Maine-de-Boixe, Charente, France	Maine-de-Boixe, Charente, France	0101000020E6100000772D211FF46CC63F143FC6DCB5EC4640	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-115425	Mirebeau, Vienne, France	Mirebeau, Vienne, France	0101000020E61000002A3A92CB7F48C73F068195438B644740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-116200	Le Mans, Sarthe, France	Le Mans, Sarthe, France	0101000020E610000096438B6CE7FBC93FBADA8AFD65FF4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-117365	Flaçà, Girona, Catalonia, Spain	Flaçà, Girona, Catalonia, Spain	0101000020E61000007C61325530AA07405917B7D100064540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-117366	Cesson-Sévigné, Ille-et-Vilaine, France	Cesson-Sévigné, Ille-et-Vilaine, France	0101000020E6100000151DC9E53FA4F9BFD6C56D34800F4840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-117757	Anjou, France	Anjou, France	0101000020E6100000F5DBD78173861340DCD7817346AC4640	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-118540	Spain	Spain	0101000020E610000000000000000010C0D7A3703D0A374440	\N	region	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-120893	Vannes, Brittany, France	Vannes, Brittany, France	0101000020E61000006B2BF697DD1306C0F931E6AE25D44740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-121680	Villaines-les-Rochers, Indre-et-Loire, France	Villaines-les-Rochers, Indre-et-Loire, France	0101000020E610000024B9FC87F4DBDF3FBF7D1D38679C4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-122075	Île-de-France, France	Île-de-France, France	0101000020E610000071AC8BDB68000440F9BD4D7FF66F4840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-122471	La Rochelle-Normande, Manche, France	La Rochelle-Normande, Manche, France	0101000020E61000001AC05B2041F1F6BF60E5D022DB614840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-124848	La Ventrouze, Normandy, France	La Ventrouze, Normandy, France	0101000020E6100000D734EF384547E63F03780B24284E4840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-125246	Tourouvre, Perche, France	Tourouvre, Perche, France	0101000020E61000003B70CE88D2DEE43F3255302AA94B4840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-128033	Château-Landon, Seine-et-Marne, France	Château-Landon, Seine-et-Marne, France	0101000020E6100000D95F764F1E9605403333333333134840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-128433	Gâtinais, France	Gâtinais, France	0101000020E6100000EE7C3F355EBA0440560E2DB29D0F4840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-129634	Taizé, Deux-Sèvres, France	Taizé, Deux-Sèvres, France	0101000020E6100000F0164850FC18A33F8E06F01648284740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-130036	Deux-Sèvres, France	Deux-Sèvres, France	0101000020E6100000000000000000D0BF0000000000404740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-130439	Archdiocese of Poitiers, France	Archdiocese of Poitiers, France	0101000020E6100000473D44A33B88D53F095053CBD64A4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-130440	Maulais, Deux-Sèvres, France	Maulais, Deux-Sèvres, France	0101000020E61000001D5A643BDF4FC5BF3A92CB7F48774740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-131249	Batilly-en-Gâtinais, Loiret, France	Batilly-en-Gâtinais, Loiret, France	0101000020E610000025068195430B0340B6F3FDD478094840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-132060	Poitou, Charente-Maritime, France	Poitou, Charente-Maritime, France	0101000020E6100000000000000000E0BF93C6681D55554740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-132467	Saint-Hilaire, Deux-Sèvres, France	Saint-Hilaire, Deux-Sèvres, France	0101000020E6100000295FD0420246C3BFF20C1AFA271C4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-132468	Poitou-Charentes, France	Poitou-Charentes, France	0101000020E6100000C74B37894160C53FB4C876BE9F0A4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-135325	King's Castle, St. Anne's Shandon, County Cork, Ireland	King's Castle, St. Anne's Shandon, County Cork, Ireland	0101000020E6100000E5B33C0FEEEE20C03333333333F34940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-135735	Moirans, Isère, France	Moirans, Isère, France	0101000020E6100000355EBA490C421640FD87F4DBD7A94640	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-137376	Menen, West Flanders, Belgium	Menen, West Flanders, Belgium	0101000020E61000000A68226C78FA0840D93D7958A8654940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-137377	Pittem, West Flanders, Belgium	Pittem, West Flanders, Belgium	0101000020E6100000DC4603780B240A408FC2F5285C7F4940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-140262	Champagne, France	Champagne, France	0101000020E6100000F6285C8FC2F5F83F6F1283C0CA614840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-141089	Saint-Nicolas-des-Champs, Paris, France	Saint-Nicolas-des-Champs, Paris, France	0101000020E6100000F8C264AA60D4024074B515FBCB6E4840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-142746	West Flanders, Belgium	West Flanders, Belgium	0101000020E610000000000000000008400000000000804940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-143162	Les Roches, Brantôme en Périgord, Dordogne, France	Les Roches, Brantôme en Périgord, Dordogne, France	0101000020E61000003FA9F6E978CCE53FA67EDE54A4AE4640	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-143163	Saint Pierre, Roussillon, Quebec, Canada	Saint Pierre, Roussillon, Quebec, Canada	0101000020E61000002AA913D0446452C0454772F90FB14640	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-143581	Hamelin, Manche, France	Hamelin, Manche, France	0101000020E6100000F8C264AA6054F3BFCB10C7BAB8454840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-144000	Parcé, Ille-et-Vilaine, France	Parcé, Ille-et-Vilaine, France	0101000020E6100000D93D7958A835F3BF97FF907EFB224840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-145258	Sainte-Gemme, Cher, France	Sainte-Gemme, Cher, France	0101000020E61000004D158C4AEA8406400A68226C78B24740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-145259	Orne, France	Orne, France	0101000020E61000007B14AE47E17AB43FF6285C8FC2554840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-145681	Paris, Seine, France	Paris, Seine, France	0101000020E6100000983446EBA8AA02405036E50AEF6E4840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-146948	Londigny, Charente, France	Londigny, Charente, France	0101000020E61000009EEFA7C64B37C13FD0B359F5B90A4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-147372	Marçay, Vienne, France	Marçay, Vienne, France	0101000020E610000060764F1E166ACD3FFAEDEBC0393B4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-148221	France Mission, France	France Mission, France	0101000020E6100000B84082E2C7180440C66D3480B7704740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-149497	Condé-sur-l'Escaut, Nord, France	Condé-sur-l'Escaut, Nord, France	0101000020E6100000736891ED7CBF0C40FE65F7E461394940	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-149498	Reims, Marne, France	Reims, Marne, France	0101000020E6100000D4B5F63E5555104075ADBD4F55954840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-150353	Angoulême, Angoumois, France	Angoulême, Angoumois, France	0101000020E61000003A234A7B832FC43F508D976E12D34640	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-151210	Marçay, Indre-et-Loire, France	Marçay, Indre-et-Loire, France	0101000020E610000070CE88D2DEE0CB3FCDCCCCCCCC8C4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-151640	Tours-sur-Meymont, Puy-de-Dôme, France	Tours-sur-Meymont, Puy-de-Dôme, France	0101000020E61000000B462575029A0C40CA32C4B12ED64640	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-151641	Vivonne, Vienne, France	Vivonne, Vienne, France	0101000020E6100000D6C56D3480B7D03F742497FF90364740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-155090	Villefagnan, Charente, France	Villefagnan, Charente, France	0101000020E6100000BADA8AFD65F7B43F7D3F355EBA014740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-157683	Aytré, Aunis, France	Aytré, Aunis, France	0101000020E6100000C0EC9E3C2CD4F1BFC5FEB27BF2104740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-159416	Tourville-sur-Odon, Calvados, France	Tourville-sur-Odon, Calvados, France	0101000020E610000011C7BAB88D06E0BFEEEBC03923924840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-159417	Acigné, Ille-et-Vilaine, France	Acigné, Ille-et-Vilaine, France	0101000020E6100000A779C7293A92F8BF70CE88D2DE104840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-160288	Aunis, France	Aunis, France	0101000020E6100000736891ED7C3FA5BFF5B9DA8AFD9D4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-160725	Bois, Doubs, France	Bois, Doubs, France	0101000020E6100000EF54C03DCF9F19403B191C25AFAE4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-160726	Saint-Hilaire, Maine-et-Loire, France	Saint-Hilaire, Maine-et-Loire, France	0101000020E6100000E272BC02D193E1BF87E123624A904740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-161165	Saint-Hilaire-du-Bois, Charente-Maritime, France	Saint-Hilaire-du-Bois, Charente-Maritime, France	0101000020E6100000151DC9E53FA4DFBF933A014D84B54640	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-163361	Montreuil, Seine-Saint-Denis, France	Montreuil, Seine-Saint-Denis, France	0101000020E61000001EA7E8482E7F0340E7FBA9F1D26D4840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-163802	Bretagne, Territoire de Belfort, France	Bretagne, Territoire de Belfort, France	0101000020E6100000EA04341136FC1B40F931E6AE25CC4740	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-163803	Bretagne-de-Marsan, Landes, France	Bretagne-de-Marsan, Landes, France	0101000020E610000021C84109336DDDBFB1506B9A77EC4540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-164246	Tourouvre, Tourouvre au Perche, Orne, France	Tourouvre, Tourouvre au Perche, Orne, France	0101000020E61000003B70CE88D2DEE43F925D6919A94B4840	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-165576	Collodi, Pescia, Florence, Tuscany	Collodi, Pescia, Florence, Tuscany	0101000020E61000007311DF89594F254090DAC4C9FDF24540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-166021	Montevettolini, Monsummano, Pistoia, Tuscany, Italy	Montevettolini, Monsummano, Pistoia, Tuscany, Italy	0101000020E61000007D04FEF0F3AF254051F9D7F2CAED4540	\N	settlement	2026-05-30 13:23:14.722755-05	2026-05-30 13:23:14.722755-05	\N	Imported from FS extract 2026-05-30	\N	\N
PL-166022	Nogent-le-Bernard, Sarthe, France	Nogent-le-Bernard, Sarthe, France	0101000020E6100000107A36AB3E57DF3F2E90A0F8311E4840	\N	settlement	2026-05-30 13:24:50.775708-05	2026-05-30 13:24:50.775708-05	\N	Auto-geocoded from FS extract 2026-05-30	\N	\N
PL-166023	L'Ange-Gardien Cemetery, Ange-Gardien, Rouville, Quebec, Canada	L'Ange-Gardien Cemetery, Ange-Gardien, Rouville, Quebec, Canada	0101000020E610000070B6B9313D3B52C00D54C6BFCFAC4640	\N	cemetery	2026-05-30 13:24:50.775708-05	2026-05-30 13:24:50.775708-05	\N	Auto-geocoded from FS extract 2026-05-30	\N	\N
PL-166024	Le Châtellier, Ille-et-Vilaine, France	Le Châtellier, Ille-et-Vilaine, France	0101000020E6100000E63FA4DFBE0EF4BF85EB51B81E354840	\N	settlement	2026-05-30 13:24:50.775708-05	2026-05-30 13:24:50.775708-05	\N	Auto-geocoded from FS extract 2026-05-30	\N	\N
PL-166025	Elk Grove Village, Cook County, Illinois	Elk Grove Village, Cook County, Illinois, United States	0101000020E6100000D95F764F1EFE55C02A3A92CB7F004540	USA > Illinois > Cook County > Elk Grove Village	settlement	2026-05-30 15:38:23.117619-05	2026-05-30 15:38:23.117619-05	\N	Source: place of death per Illinois, Cook County Deaths, 1871-1998 (entry for Earl Wayne Reed, 07 Apr 1974). Event Place (Original): Elk Grove Village; township: Elk Grove Township.	\N	\N
PL-166026	Lakewood Memorial Park, Elgin, Illinois	Lakewood Memorial Park, Elgin, Kane County, Illinois, United States	0101000020E6100000713D0AD7A31456C04703780B24004540	USA > Illinois > Kane County > Elgin	cemetery	2026-05-30 15:38:23.117619-05	2026-05-30 15:38:23.117619-05	\N	Source: burial cemetery per Find a Grave Index (QV2L-ZBPS) and Cook County death record (rendered 'Lake St Mem Park'). Headstone photo on file.	\N	\N
PL-166027	St. Anne, Kankakee County, Illinois	St. Anne, Kankakee County, Illinois, USA	0101000020E6100000F6285C8FC2ED55C0D044D8F0F4824440	USA > Illinois > Kankakee County	settlement	2026-05-30 20:44:12.241497-05	2026-05-30 20:44:12.241497-05	\N	Source: French-Canadian Catholic colony founded 1850 by Fr. Charles Chiniquy; Paul Pouliot's 1858 marriage place	\N	\N
\.


--
-- Data for Name: relation_type; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.relation_type (code, label) FROM stdin;
parent	Parent of
spouse	Spouse of
sibling	Sibling of
\.


--
-- Data for Name: relationship; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.relationship (rel_id, person_id_a, relation, person_id_b, start_date, end_date, evidence_note, created_at, updated_at) FROM stdin;
R-0002	P-0070	spouse	P-0004	1861-09-19	1880-12-20	Marriage in Noble County, Ohio; Elizabeth died 1880	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0003	P-0072	spouse	P-0012	1881-10	NULL	Second marriage (month recorded)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0005	P-0064	spouse	P-0068	circa 1899	NULL	Married in/near Chicago	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0006	P-0062	spouse	P-0058	circa 1929	NULL	Married in/near Chicago	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0104	P-0002	parent	P-0070	NULL	NULL	Rebecca is mother of John Talley Reed	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0105	P-0070	parent	P-0061	NULL	NULL	John T. is father of John Foulk Reed	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0106	P-0004	parent	P-0061	NULL	NULL	Elizabeth is mother of John Foulk Reed	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0107	P-0070	parent	P-0035	NULL	NULL	John T. is father of Emma Rebecca Reed	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0108	P-0004	parent	P-0035	NULL	NULL	Elizabeth is mother of Emma Rebecca Reed	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0109	P-0072	parent	P-0036	NULL	NULL	Abiram is father of Estelle Gertrude Lambert	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0110	P-0012	parent	P-0036	NULL	NULL	Helen is mother of Estelle Gertrude Lambert	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0111	P-0036	parent	P-0062	NULL	NULL	Estelle is mother of Earl Wayne Reed	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0112	P-0061	parent	P-0062	NULL	NULL	John Foulk Reed is father of Earl Wayne Reed	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0113	P-0064	parent	P-0058	NULL	NULL	John F. Zika is father of Isabelle	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0114	P-0068	parent	P-0058	NULL	NULL	Delina is mother of Isabelle	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0115	P-0019	parent	P-0064	NULL	NULL	Anton is father of John F.	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0116	P-0020	parent	P-0064	NULL	NULL	Josefína is mother of John F.	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0117	P-0078	parent	P-0068	NULL	NULL	Paul is father of Delina	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0118	P-0076	parent	P-0068	NULL	NULL	Henriette is mother of Delina	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0120	P-0094	parent	P-0078	NULL	NULL	Julie is mother of Paul	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0122	P-0028	parent	P-0076	NULL	NULL	Henriette (Cheffre) is mother of Henriette (Filiatrault)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0123	P-0062	parent	P-0031	NULL	NULL	Obituary indicates Earl Jr.	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0124	P-0058	parent	P-0031	NULL	NULL	Obituary indicates Earl Jr.	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0125	P-0062	parent	P-0056	NULL	NULL	1940 census indicates John R.	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0126	P-0058	parent	P-0056	NULL	NULL	1940 census indicates John R.	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0127	P-0062	parent	P-0033	NULL	NULL	1940 census indicates James G.	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0128	P-0058	parent	P-0033	NULL	NULL	1940 census indicates James G.	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0129	P-0061	spouse	P-0036	1899-03-05	NULL	Marriage reported in Monteith Valley, Guthrie County, Iowa.	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0130	P-0056	spouse	P-0055	NULL	NULL	Spousal link per provided family info; marriage date not specified.	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0131	P-0084	parent	P-0072	NULL	NULL	David Lambert is father of Abiram Stacy Lambert (per deep dive 2026-05-28; WikiTree Lambert-3978 + FindAGrave + Benton Co Pioneers)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0132	P-0010	parent	P-0072	NULL	NULL	Permelia (Barnard) Lambert is mother of Abiram Stacy Lambert (per deep dive 2026-05-28; FindAGrave #10569107 + Benton Co Pioneers)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0133	P-0167	parent	P-0168	\N	\N	Gerald Arthur Kenny is John Kenny's father (per John, self-reported, 2026-05-30; corroborated by memorial prayer card S-0001).	2026-05-30 12:30:44.345343-05	2026-05-30 12:30:44.345343-05
R-0001	P-0082	spouse	P-0002	1837-11-23	NULL	Marriage in Morgan County, Ohio	2026-05-30 09:21:56.321112-05	2026-05-30 13:31:43.374304-05
R-0103	P-0082	parent	P-0070	NULL	NULL	Bonum is father of John Talley Reed	2026-05-30 09:21:56.321112-05	2026-05-30 13:31:43.374304-05
R-0101	P-0040	parent	P-0082	NULL	NULL	Benjamin is father of Bonum	2026-05-30 09:21:56.321112-05	2026-05-30 13:31:43.374304-05
R-0102	P-0041	parent	P-0082	NULL	NULL	Sarah is mother of Bonum	2026-05-30 09:21:56.321112-05	2026-05-30 13:31:43.374304-05
R-0119	P-0091	parent	P-0078	NULL	NULL	François is father of Paul	2026-05-30 09:21:56.321112-05	2026-05-30 13:31:43.374304-05
R-0121	P-0093	parent	P-0076	NULL	NULL	Joseph is father of Henriette	2026-05-30 09:21:56.321112-05	2026-05-30 13:31:43.374304-05
R-0134	P-0105	spouse	P-0843	\N	\N	Shared grave marker names "Sherebiah Lambert" and "Pamelia, his wife"; P-0105 note states he married Permelia Oak.	2026-05-30 16:02:41.376154-05	2026-05-30 16:02:41.376154-05
\.


--
-- Data for Name: research_lead; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.research_lead (id, person_id, category, description, status, source_dossier, created_at, updated_at) FROM stdin;
169	P-0070	record	Civil War service — worked thoroughly this dive (open sources exhausted; result: likely did NOT serve). Examined the NPS Soldiers & Sailors DB and the full-text Official Roster of the Soldiers of the State of Ohio (Vols. III & VIII). The only name-perfect "John T. Reed" is in the 21st OVI Co. F — a NW-Ohio (Hancock Co.) regiment whose Sept 6 1861 enrollment collides with his Sept 19 1861 Noble Co. wedding → almost certainly a different man (§3 row 9). His own SE-Ohio regiment, the 116th OVI, has no John Reed (§3 row 10). A bare "John Reed" in the 122nd OVI Co. I (SE Ohio, 1862) fits geography+timing but can't be distinguished (§3 row 11). The Ohio roster records no residence, so it cannot bridge a soldier to Noble Co. or to Iowa. No veteran/GAR mark on his cemetery stone (§3 row 12). Decisive records remain, all behind auth: (a) Civil War Pension Index (Fold3/Ancestry/FS) — a pension card shows the state the claim was filed from (would be Iowa) + unit; (b) 1890 Union Veterans Schedule,	done	P-0070	2026-05-30 13:43:52.653522-05	2026-05-30 13:43:52.653522-05
170	P-0070	record	John T. Reed obituary, Nov 1903. Not in open archives. The Guthrie Center / Panora newspapers (e.g. Guthrie County Vedette) for Nov 1903 may exist on microfilm (FamilySearch catalog #448504) or behind newspapers.com — chase if John has access.	open	P-0070	2026-05-30 13:43:52.653522-05	2026-05-30 13:43:52.653522-05
171	P-0070	record	Federal & state censuses. 1850/1860 OH (with Bonum's household), 1870 (OH or IA?), 1880 Jackson Twp, 1895 IA state, 1900 Valley Twp — none cited yet. FamilySearch/Ancestry behind auth (Ring 0/Chrome MCP path).	open	P-0070	2026-05-30 13:43:52.653522-05	2026-05-30 13:43:52.653522-05
172	P-0070	record	Second marriage to Mary E. Headlee. Find the Guthrie County marriage record (~1881) and a death/burial record for Mary; she may also be at Monteith. Then materialize the spouse relationship.	open	P-0070	2026-05-30 13:43:52.653522-05	2026-05-30 13:43:52.653522-05
173	P-0070	record	Monteith Cemetery precise geocode. Find A Grave cemetery #2183425 — capture lat/long to upgrade burial place from settlement-level "Monteith" to a proper cemetery geocode.	open	P-0070	2026-05-30 13:43:52.653522-05	2026-05-30 13:43:52.653522-05
174	P-0070	other	Sidney R. Reed (1859–1934), Iowa legislator — likely a younger brother of John T. (both buried Monteith, Bonum-era). The 37th GA member PDF is a scanned image; OCR it (no text layer) to confirm parentage. If confirmed a son of Bonum, he's a missing P-#### sibling. Do NOT merge or create blind — route through lrgdm-data-quality / pedigree-walk.	open	P-0070	2026-05-30 13:43:52.653522-05	2026-05-30 13:43:52.653522-05
175	P-0070	other	P-0004 Elizabeth (Willey) Reed death date: DB stores `1880-12-20`; the WPA cemetery survey says `21 Dec 1880` (row 2). One-day discrepancy — not patched here because it touches P-0004, not P-0070.	open	P-0070	2026-05-30 13:43:52.653522-05	2026-05-30 13:43:52.653522-05
205	P-0078	paywall	None. PRDH and the Drouin Collection (Ancestry) would deepen the Québec side (godparents, exact parish acts) but were not needed — FS attached records covered the vitals. ~$ if John wants the Drouin parish images.	open	P-0078	2026-05-30 20:44:12.395074-05	2026-05-30 20:44:12.395074-05
90	P-0036	record	Cook County, IL death certificate full image (entry 15350) — should give cause of death and informant. The FS index page has the structured fields but no image attached on the public side.	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
176	P-0062	record	FindAGrave memorial biography (QV2L-ZBPS notes "Contains Biography" + headstone photo) — open the memorial on findagrave.com to capture the biography text and the stone image; candidate for a `media` row.	open	P-0062	2026-05-30 15:38:23.279346-05	2026-05-30 15:38:23.279346-05
177	P-0062	record	WWI draft card (Waukesha, WI, 1917-18) — open the image for physical description, employer, nearest relative; would confirm where/why he was in Wisconsin.	open	P-0062	2026-05-30 15:38:23.279346-05	2026-05-30 15:38:23.279346-05
178	P-0062	record	WWII draft card (Illinois, 1942) — open for employer + residence + physical description (height/weight/eyes).	open	P-0062	2026-05-30 15:38:23.279346-05	2026-05-30 15:38:23.279346-05
179	P-0062	record	1950 census image — capture exact Chicago address, household composition, and the column-20 occupation detail.	open	P-0062	2026-05-30 15:38:23.279346-05	2026-05-30 15:38:23.279346-05
180	P-0062	record	Marriage record, Earl × Isabelle Zika (~1929, Cook Co) — not yet located as an attached source; would pin the exact date/place (currently "circa 1929").	open	P-0062	2026-05-30 15:38:23.279346-05	2026-05-30 15:38:23.279346-05
181	P-0062	record	SSN application (SS-5) behind the NUMIDENT index — would give parents' names in his own hand.	open	P-0062	2026-05-30 15:38:23.279346-05	2026-05-30 15:38:23.279346-05
182	P-0062	person	Siblings (Harold Merle d.1921 Panama; Oscar Glenn; Edna Gertrude; Eichinger half-sib Ray) are documented in [[P-0036]] but may not yet exist as `person` rows linked through the parents — sibling materialization belongs to parent-level work, not this dossier.	open	P-0062	2026-05-30 15:38:23.279346-05	2026-05-30 15:38:23.279346-05
183	P-0062	person	FS timeline shows a second daughter "Edna May Reed, 7 Feb 1909, Bettendorf" distinct from "Edna Gertrude Reed ~1906/07" — possible duplicate or a child who died young; reconcile against [[P-0036]] before creating rows.	open	P-0062	2026-05-30 15:38:23.279346-05	2026-05-30 15:38:23.279346-05
184	P-0062	cross_skill	Death-date correction (1974-04-11 → 1974-04-07) — see §4.3; awaiting John's OK.	open	P-0062	2026-05-30 15:38:23.279346-05	2026-05-30 15:38:23.279346-05
185	P-0062	cross_skill	DQ — duplicate birth events E-0017 & E-0029 (same date, competing place_ids PL-0004/PL-0015) → dedupe via [[lrgdm-data-quality]].	open	P-0062	2026-05-30 15:38:23.279346-05	2026-05-30 15:38:23.279346-05
186	P-0062	cross_skill	DQ — stray `Citizenship` event E-0036 (no date/place; anomalous for a US-born man) — investigate provenance or drop.	open	P-0062	2026-05-30 15:38:23.279346-05	2026-05-30 15:38:23.279346-05
187	P-0062	cross_skill	DQ — burial event E-0197 has no cemetery and no place precision beyond "Elgin"; link to new PL Lakewood Memorial Park (§4.1) and set the cemetery.	open	P-0062	2026-05-30 15:38:23.279346-05	2026-05-30 15:38:23.279346-05
188	P-0062	cross_skill	DQ — possible conflation: two "US Obituary Records, 2014-2023" sources (dated 2024) are attached to Earl Sr. but almost certainly belong to Earl Wayne Reed Jr. (P-0031, d. 2024) — verify and detach from Sr.	open	P-0062	2026-05-30 15:38:23.279346-05	2026-05-30 15:38:23.279346-05
189	P-0062	cross_skill	Burial county: DB has Elgin in Kane County (PL-5235); FindAGrave indexes it as Cook — Elgin straddles both. Lakewood Memorial Park sits on the Kane side; keep Kane.	open	P-0062	2026-05-30 15:38:23.279346-05	2026-05-30 15:38:23.279346-05
190	P-0062	paywall	Open web (WebSearch + unauthenticated WebFetch) yielded nothing for this man: FindAGrave search returns HTTP 403, FamilySearch needs login, census/draft images are gated. The entire dossier came from Ring 0 FS attached records via authenticated Chrome MCP.	open	P-0062	2026-05-30 15:38:23.279346-05	2026-05-30 15:38:23.279346-05
191	P-0843	identity	Lock down Permelia (Oak) Lambert: find her FamilySearch PID, confirm maiden name "Oak", parents, exact birth date/place (age 77 at 16 Jan 1845 death -> b. c. 1767-1768), and burial place (shared headstone with Sherebiah Lambert Jr, P-0105).	open	sherebiah-lambert-grave scan	2026-05-30 16:02:41.376154-05	2026-05-30 16:02:41.376154-05
192	P-0138	data_quality	Sherebiah Lambert Sr (b. 1728) had death_date "1 May 1833" + death_place Canaan, ME, both copied from his son Sherebiah Jr (P-0105) per the grave marker. Cleared them. Research Sr actual death date and burial place.	open	sherebiah-lambert-grave scan	2026-05-30 16:02:41.376154-05	2026-05-30 16:02:41.376154-05
85	P-0036	record	1910 US Census — not in FS attached sources for LMWG-K6F. Should show the Reed household before the 1912 Eichinger marriage. Search Ancestry/FS for Estella G. Reed b. 1882 IA + spouse John F. Reed in Guthrie Co IA (or Sioux Falls SD if the move happened earlier than thought).	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
86	P-0036	record	1930 and 1940 US Censuses — also missing. Critical for pinning down when the Eichinger marriage ended and when the Sinderson marriage began. Estelle may appear under Eichinger in 1930, Sinderson in 1940 (or some intermediate state).	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
87	P-0036	record	Marriage record for Estelle + Harry Sinderson — date and place unknown. Best guess: somewhere in IL/WI/IA, 1925×1940 window. Try IL state marriage indexes, Cook Co IL marriage license index.	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
88	P-0036	record	Divorce records: Reed/Lambert divorce (Iowa, ~1911–12) and Eichinger/Lambert divorce (~1925–1940). Iowa district court records, by county of residence.	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
89	P-0036	record	Chicago Tribune death notice, 20–24 May 1946 — paywalled newspapers.com. Search both "Estelle Sinderson" and "Mrs. Harry Sinderson."	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
91	P-0036	record	FindAGrave memorial for Estelle Sinderson at Prairie Home Cemetery, Waukesha WI — referenced as a "similar record" in the Cook Co death cert. Plus a NUMIDENT (SSA) entry. Search FindAGrave for cemetery 88776 + Sinderson surname.	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
92	P-0036	record	Harry Sinderson — find his vital records to figure out where the Waukesha connection came from. He's the most likely reason her body was sent there.	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
93	P-0036	record	Reed-side context: John Foulk Reed's life 1912–1952 (he lived another 40 years after the divorce). Did he remarry? Where were the four Reed children raised after the 1912 split — with him in Iowa, or with Estelle and Clarence in Sioux Falls then Waterloo? The 1920 census shows only Edna in the Eichinger household — what about Harold and Oscar?	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
94	P-0036	record	Harmon T. Reed and the Reed founding family of Monteith — biographical sketch in the 1884 "History of Guthrie and Adair Counties, Iowa" (sites.rootsweb.com/~iabiog). Useful for the husband's-side context.	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
95	P-0036	person	Harold Merle Reed b. 7 Jan 1901 Guthrie Co IA — son of John F. Reed + Estelle G. Lambert. New People row candidate. FS source: Q246-SDPC.	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
96	P-0036	person	Oscar G. Reed b. 1903 Guthrie Co IA — son of John F. Reed + Estella G. Lambert. New People row candidate. FS sources: XVZ5-VVH, XV2Y-VDM.	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
97	P-0036	person	Edna Gertrude Reed b. 16 Aug 1906 Iowa — daughter of John F. Reed + Estelle G. Lambert. Appears in 1920 census as "Edna Eichinger" (stepfather Clarence) and 1925 census as "Edna Reed." New People row candidate. FS source: Q24X-4Z14.	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
98	P-0036	person	Ray Eichinger b. ~1914 Iowa — son of Clarence D. Eichinger + Estelle (Lambert) Eichinger. New People row candidate. FS sources: M6JH-P4L (1920 census), QKQW-X88X (1925 census).	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
99	P-0036	person	Sylvia L. Lambert b. ~1884 Iowa — younger sister of Estelle, age 1 in 1885 IA State Census. New People row candidate for the family graph. FS source: HZXM-SN2.	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
100	P-0036	person	Clarence D. Eichinger — second husband, b. Lafayette, Indiana, son of John Eichinger + Mary Jane Towers. New People row candidate. FS source: XJPF-H6J.	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
101	P-0036	person	Harry Sinderson — third husband. Almost certainly the reason for the Waukesha burial. New People row candidate. Lead: Cook Co death cert Q2M8-FDWY names spouse "Harry"; cross-search WI/IL/IA vital records for Harry Sinderson 1880s–1950s.	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
102	P-0036	person	Leslie Knapp — Estelle's stepfather (Helen's third husband), with her from the 1895 Iowa State Census onward. New People row candidate. FS source: VT33-RWL.	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
103	P-0036	person	Clara L. Foote (b.~1869), Arthur Foote (b.~1870), Edwin Foote (b.~1881) — Estelle's Foote half-siblings via Helen's first marriage. Three new People row candidates. FS source: HZXM-SN2.	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
104	P-0036	cross_skill	MERGE: P-0063 → P-0036 via `scripts/merge_duplicate_persons.py`. Same as the AM dossier — still valid after the PM redux.	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
105	P-0036	cross_skill	FS reconciliation — confirm `fs_id` set on P-0036, unset on P-0063 post-merge.	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
106	P-0036	cross_skill	Bulk-ingest the new People above via `lrgdm-ingest-fs` skill once their FS PIDs are pulled. For the Reed children especially, FS likely has them all under stable PIDs already (Earl Wayne Reed Sr is `M3P5-XF6`; siblings should be in the same generation).	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
107	P-0036	cross_skill	The AM dossier's burial-place patch (PL-DD-P0036-001 Prairie Twp Delaware IA) is RETRACTED — do NOT include it in the apply run. PL-0039 (Waukesha WI) is correct.	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
108	P-0036	paywall	FindAGrave (HTTP 403 to WebFetch) — Chrome MCP path works but wasn't routed there this dive; check Prairie Home Waukesha for Sinderson-surname memorials.	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
109	P-0036	paywall	Newspapers.com — Chicago Tribune 1946 obit; Waukesha Freeman 1946 funeral notice.	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
110	P-0036	paywall	Ancestry.com — 1910/1930/1940 census indices.	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
111	P-0056	record	1940 U.S. Census (intact household) — attached to `LY94-373` but the FS source-row panel toggle was flaky and the record search wouldn't bind the parent filters; would confirm Earl Sr present in 1940 and the exact Cicero address. Re-open from the sources page → 1940 row → View (opens outside the MCP tab group).	open	P-0056	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
112	P-0056	record	John's own 1995 obituary — not among FS attached sources; would give his occupation and any military service. Needs a Chicago Tribune / Daily Herald / DuPage newspaper archive (likely paywalled).	open	P-0056	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
113	P-0056	record	Korean War service — established via family testimony (John Kenny, 2026). Recorded as event E-DD-P0056-003. Now needs a documentary anchor to pin branch + base + dates, in rough order of effort:	done	P-0056	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
114	P-0056	record	Cook County marriage record (1956) — the obituary dates the marriage to 1956; the civil record (exact date + church) is not on FamilySearch's free index. Cook County Clerk / IRAD, or Ancestry's Cook County Marriage Index 1930–1960.	open	P-0056	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
115	P-0056	record	1934 Cook County birth certificate image — attached; would give the exact Chicago address/hospital. Low priority (facts triple-corroborated).	open	P-0056	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
116	P-0056	record	John's occupation — genuinely unknown. No source this dive named it.	open	P-0056	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
117	P-0056	person	Earl Wayne "Wayne" Reed Jr (1930-12-09 – 2024-07-20) — John's brother, deceased, fully documented (obituary ark XMRK-KN1N). Safe to add as a People row + sibling/child Relationships via the ingest/data-quality path (no insert_person op here).	open	P-0056	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
118	P-0056	person	James "Jim" Reed (b. ~1940) — John's brother; possibly living (~86), do NOT materialize without a death record.	open	P-0056	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
119	P-0056	person	John & Leah's seven children — all living (incl. Karen Kenny, the proband's mother); deliberately NOT materialized per privacy rules. They appear in the public obituary; quote-only, no rows.	open	P-0056	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
120	P-0056	cross_skill	Place dedupe (`lrgdm-data-quality`): PL-0158 ↔ PL-0016 (Chicago); PL-0163 ↔ PL-0017 (Glen Ellyn).	open	P-0056	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
121	P-0056	cross_skill	Orphan place: E-0023 birth-registration lost `PL-0018` in the 2026-05-26 cleanup.	open	P-0056	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
122	P-0056	cross_skill	Event note fix (manual): re-title E-0025 "Social Security application (SS-5)" — confirmed Feb 1949.	open	P-0056	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
123	P-0056	cross_skill	Create John's FindAGrave memorial (and link to Leah's #285158675) once burial at Queen of Heaven is confirmed — would close the burial gap and let future dives anchor the grave.	open	P-0056	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
124	P-0056	paywall	Cook County 1956 marriage index — not in FamilySearch free records.	open	P-0056	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
125	P-0056	paywall	John's 1995 newspaper obituary — open web returned only directories; behind newspaper paywalls.	open	P-0056	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
126	P-0056	paywall	FindAGrave — direct WebFetch is 403; the authenticated/headless browser worked.	open	P-0056	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
127	P-0059	record	Passenger arrival manifest — FOUND. SS Giuseppe Verdi, Genoa → Ellis Island, 3 Sep 1920. FS J6F8-T28. Original image is restricted on FS (NARA/Ellis Island licensing); to read the destination address, sponsor, occupation, and $ carried fields would require the Statue of Liberty Foundation viewer or NARA microfilm T715-2825 image 131. Worth a future browse for the destination field — most likely "join sponsor/relative in [city]" which would explain how he ended up in Iowa.	done	P-0059	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
128	P-0059	record	Severino Stefanelli on the same manifest page — possibly traveled with Ugo from Cintolese. If we can identify Severino's destination, it likely points at Ugo's too. Worth a FS lookup of "Severino Stefanelli" on 1920 Giuseppe Verdi.	open	P-0059	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
129	P-0059	record	Italian baptismal register, San Leopoldo in Cintolese, July 1903. Parish archives held under Diocesi di Pescia. Civil birth register: Comune di Monsummano Terme, July 1903 — likely on Antenati (antenati.cultura.gov.it). Italian-language browse-based search.	open	P-0059	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
130	P-0059	record	Birth Certificate #32174 image — Cook County 8 Sep 1936. The "Sarah Joy" vs "Leah Rae" puzzle needs the actual scanned certificate to resolve. Cook County Clerk: cookcountyclerkil.gov.	open	P-0059	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
131	P-0059	record	Roland Mariotti Cook County birth cert #228 image — the 17 June 1929 cert. Would confirm exact home address in Cicero at that date.	open	P-0059	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
132	P-0059	record	1920 US Census — Ugo would have been 16 if he arrived by then. If he's in the 1920 census (US), he arrived earlier than 1920; if he's NOT, that brackets arrival to 1920-1922.	open	P-0059	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
133	P-0059	record	Lena Dini family — the marriage record names her parents "Gina Ginn" (probably Louis Dini, P-0065?) and "Jerinda Pargin" (probably a Zelinda Pagni — possibly the same Zelinda Pagni P-0066 that the GPKG carries! If so, Ugo and Lena were related: Lena's mother being a Pagni would tie her into the Maternal Mariotti branch's own Pagni line. This is a major reconciliation lead — recommend a Lena-Dini deep dive next.)	open	P-0059	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
134	P-0059	record	Cintolese church / Mariotti & Lenzi families pre-1903 — given fs_id is set for both parents (P-0067, P-0069), a `lrgdm-pedigree-walk`-style FS sources pass on Leopoldo and Quintilia would give the Italian-side context Ugo himself can't.	open	P-0059	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
135	P-0059	person	Rolando "Roland" William Mariotti (b. 17 Jun 1929 Cicero IL — d. 29 Dec 2023 Tipton IN). Cert #228, Cook Co. Married Virginia Jaskolski 1953. Children: Mary Katherine, Michael J., Mark W., Mitchell K. Mariotti. Candidate for new People row in next ingest. Branch: Maternal Mariotti.	open	P-0059	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
136	P-0059	person	Celiste Dee "Celeste" Mariotti (b. ~1944 IL). Living. Anderson, IN. Privacy_level=private required when added.	open	P-0059	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
137	P-0059	person	Virginia A. Jaskolski Mariotti (d. 25 Jun 2014) — Roland's Polish-American wife. Out of LRGDM ancestral scope but useful for descendant research.	open	P-0059	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
138	P-0059	person	Renato Mariotti (1908–1931) — possible brother from MyHeritage. NOT corroborated by any of the 13 FS-attached sources, which list no siblings for Ugo. Demoted to low-confidence open lead pending Italian civil-records check. May be a separate Mariotti family.	open	P-0059	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
139	P-0059	other	Ugo's mother is Quintilia Lenzi (P-0069), not Zelinda Pagni (P-0066). The first-pass dossier inferred Zelinda from branch grouping; the 1927 marriage record overrules. The update_person op in §4.3 reflects this in notes/source_summary but does not write a Relationships row — that goes via DQ pass.	open	P-0059	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
140	P-0059	cross_skill	`lrgdm-data-quality` work: add Relationship rows linking P-0059 ↔ P-0067 (father), P-0059 ↔ P-0069 (mother), P-0059 ↔ P-0060 (spouse, m. 1927-05-05), P-0059 ↔ P-0055 (daughter). The `apply_deep_dive.py` patch schema does not include `insert_relationship`; this is a DQ-pass write.	open	P-0059	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
141	P-0059	cross_skill	`lrgdm-data-quality` work: backfill `admin_hierarchy` for PL-0178 (Cintolese) and PL-0179 (Cicero).	open	P-0059	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
142	P-0059	cross_skill	FS reconciliation: `fs_id` already set on Ugo (PWPQ-D8V), Lena (L278-SXK per FS extract couples table), Leopoldo (PWPW-LPC), and Quintilia (PWP7-JQ8). No action needed.	open	P-0059	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
143	P-0059	cross_skill	Next deep dive candidate: Lena A Dini (P-0060) — would close out the marriage-record name puzzles (Gina Ginn / Jerinda Pargin) and verify the Pagni cross-link that may tie the Dini and Mariotti families in Cintolese.	open	P-0059	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
144	P-0059	paywall	None in this pass. The 13 FS-attached sources were all free with login. FindAGrave memorial was public. Ancestry/MyHeritage were not consulted in the second pass.	open	P-0059	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
145	P-0072	record	Abiram's own FindAGrave memorial in Twin Falls Cemetery #80667. Almost certainly exists; WebFetch returns 403 on FindAGrave. Browse directly via Chrome MCP next time the cookie jar is loaded.	open	P-0072	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
146	P-0072	record	Helen A. Boles Knapp memorial #16177390 — direct browse to confirm she lists Abiram (1831–1927) as previous spouse and Estelle as daughter; will also pin Helen's death date (GPKG says 1938; stone may say 1939).	open	P-0072	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
147	P-0072	record	Civil War pension file (NARA RG 15) — index entry should exist; Fold3/Ancestry/FamilySearch paywalled. FamilySearch's free Pension Index card may give widow's claim filed by Helen post-1927.	open	P-0072	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
148	P-0072	record	Iowa Adjutant General report — Co. L 3rd IA Cav roster (Logan's Roster) — iagenweb's `mil603.htm` returns 403 on the roster section. Should give rank, enlistment date, casualty info.	open	P-0072	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
149	P-0072	record	1900 + 1910 US Census — almost certainly Guthrie Co IA still (1915 IA state census confirms Guthrie Center, and the gap should be Guthrie). Primary images behind FS login.	open	P-0072	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
150	P-0072	record	1854 / 1856 Iowa State Census — Canton Twp, Benton Co IA — verify directly against state archive images, not the iagenweb compilation.	open	P-0072	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
151	P-0072	record	Idaho death certificate 1927 — "Idaho Death Certificates 1911-1937" on FS (free with account) will give exact death locality, cause of death, parents, informant.	open	P-0072	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
152	P-0072	record	Twin Falls Times-News obit ~28 Apr–5 May 1927 — paywalled (Newspapers.com / GenealogyBank).	open	P-0072	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
153	P-0072	record	Estelle Gertrude Lambert (P-0036) FindAGrave / obit, d. 20 May 1946 — not located via web; likely Twin Falls Co.	open	P-0072	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
154	P-0072	person	Louisa Leach (1st wife) — needs a People row; b. ~1834 IN, d. ~1880 IA. Marriage event E-0008 already names her. (Do not create from a deep dive per skill rules; flagged for next FS reconciliation or manual add.)	open	P-0072	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
155	P-0072	person	David B. Lambert and Nancy J. Lambert — claimed children of Abiram + Louisa per compiled trees. Low confidence; verify against 1860 / 1870 census household composition.	open	P-0072	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
156	P-0072	person	Lambert siblings of Abiram (Sherebiah b.1825, Abner b.1833, John B., Laura Ann m. Mather, Sophronia Pore-Wilcox, Samuel B.) — none in GPKG. Candidates for FS reconciliation.	open	P-0072	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
157	P-0072	cross_skill	DQ — Relationship R-0004 is wrong. It currently says `P-0072 spouse → P-0055 Leah Rae Mariotti` (proband's 20th-c grandmother!) with date 1850-12-25. Should point to Louisa Leach (once she has a People row), OR be deleted and rebuilt when Louisa is added. Flag for [[lrgdm-data-quality]].	open	P-0072	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
158	P-0072	cross_skill	DQ — Duplicate Events E-0007 ≡ E-0096 (both `Birth of Abiram Stacy Lambert`, same date, different place_ids PL-0005 vs PL-0058 — themselves duplicate Places).	open	P-0072	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
159	P-0072	cross_skill	DQ — Duplicate Places PL-0005 ≡ PL-0058 (`Salem, Washington County, Indiana` ≡ `Salem, Washington County, Indiana, USA`); and PL-0367 ≡ PL-0058 (the People-linked variant with "Washington Township" added).	open	P-0072	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
160	P-0072	cross_skill	DQ — Duplicate People P-0009 ≡ P-0084 (`David Lambert` 1789–1865/1866). The fs-linked row P-0084 (fs_id L7XP-Y6P) should be the winner. Add to `MERGES` in `merge_duplicate_persons.py`.	open	P-0072	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
161	P-0072	cross_skill	DQ — Spelling. GPKG has `Parmelia (Barnard) Lambert` (P-0010); FindAGrave gravestone reads `Permelia`. Worth fixing `primary_name`. (Not patchable via deep-dive `update_person` — that op forbids `primary_name`.)	open	P-0072	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
162	P-0072	cross_skill	Relationships to add (post-DQ): `P-0072 parent_of P-0072's-merged-father-row`; `P-0072 parent_of P-0010` — i.e. `P-0072 child_of David` and `child_of Permelia`. Skill's patch schema doesn't model Relationships ops; add manually after DQ.	open	P-0072	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
163	P-0072	cross_skill	Place dedupe candidate: the People row says death at `Falls City, Lincoln, Idaho` (PL-0368) but Event E-0097 says `Falls City, Jerome, Idaho` (PL-0059). After patch §4.3 applies, PL-0368 becomes an orphan candidate for dedupe / removal in DQ.	open	P-0072	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
164	P-0072	paywall	Newspapers.com / Twin Falls Times-News — April–May 1927 obit. ~$25/mo subscription.	open	P-0072	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
165	P-0072	paywall	GenealogyBank — same paper, alternate path.	open	P-0072	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
166	P-0072	paywall	Fold3 — Civil War pension index + service record images. ~$10/mo or Ancestry bundle.	open	P-0072	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
167	P-0072	paywall	MyHeritage — Louisa Leach index, Helen Boles tree confirmations.	open	P-0072	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
168	P-0072	paywall	magicvalley.com (Times-News editorial archive) — Falls City history article had a fuller text behind tollbit paywall.	open	P-0072	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
193	P-0078	record	1880 & 1900 census images — read the actual sheets for Paul's occupation, street address, naturalization status, and (1900) immigration year, years married, and children-born/living counts. Attached on FS but not yet transcribed here.	open	P-0078	2026-05-30 20:44:12.395074-05	2026-05-30 20:44:12.395074-05
194	P-0078	record	1903 Cook County death record — pull the image for cause of death, residence at death, age, and especially burial place (no FindAGrave memorial exists for Paul or Henriette; the death/cemetery record is the only path to the grave).	open	P-0078	2026-05-30 20:44:12.395074-05	2026-05-30 20:44:12.395074-05
195	P-0078	record	1858 St. Anne marriage record image — confirm both spouses' parents; may name Henriette St. Louis's father (her parents are unknown in LRGDM).	open	P-0078	2026-05-30 20:44:12.395074-05	2026-05-30 20:44:12.395074-05
196	P-0078	record	Immigration/border crossing ~1855 — no ship, port, or exact date yet; fixes the broken immigration event E-0076. French-Canadian arrivals often came overland; check border-crossing and St. Anne colony arrival lists.	open	P-0078	2026-05-30 20:44:12.395074-05	2026-05-30 20:44:12.395074-05
197	P-0078	record	1834 St-Laurent baptism image — already attached on FS with a document image (artifact 122936882); transcribe godparents for the extended Île d'Orléans network.	open	P-0078	2026-05-30 20:44:12.395074-05	2026-05-30 20:44:12.395074-05
198	P-0078	person	Henriette St. Louis Pouliot (P-0076 already exists) — needs the spouse relationship row to Paul (see cross-skill follow-up); parents unknown.	open	P-0078	2026-05-30 20:44:12.395074-05	2026-05-30 20:44:12.395074-05
199	P-0078	person	Eight children not in LRGDM — candidates for FS ingest, with PIDs: Henriette (MRH2-HS8), Thomas (GQ8H-9M4), Harriet (GQ8H-46W), Francois (LV33-C24), Albert J. (G3YX-LXD), Edward (GQ8H-QPP), Arthur (GQ84-BCS), Eva (MGNK-Y2Z). Delina (P-0068) is already in.	open	P-0078	2026-05-30 20:44:12.395074-05	2026-05-30 20:44:12.395074-05
200	P-0078	person	Parents François Pouliot (P-0091 / KCTF-J6N) and Julie Audet dit Lapointe (P-0094 / 96JW-KFH) are already in LRGDM and FS-matched — good.	open	P-0078	2026-05-30 20:44:12.395074-05	2026-05-30 20:44:12.395074-05
201	P-0078	person	Sixteen siblings of Paul on FS (e.g. François Xavier 96JW-KXP, Pierre 96JW-KXR, Louis Achille 96JW-KX1) — collateral, ingest only if the Pouliot branch is being filled out.	open	P-0078	2026-05-30 20:44:12.395074-05	2026-05-30 20:44:12.395074-05
202	P-0078	cross_skill	Spouse relationship: `apply_deep_dive.py` has no relationship op. Add the Paul (P-0078) ↔ Henriette (P-0076) spouse relationship row manually (m. 1858-11-07), via QGIS or SQL.	open	P-0078	2026-05-30 20:44:12.395074-05	2026-05-30 20:44:12.395074-05
203	P-0078	cross_skill	Place dedupe (`merge_duplicate_persons.py` is for persons; this is a place issue for `lrgdm-data-quality`): birthplace rows PL-0506 (clean) and PL-0048 (mojibake `Saint-Laurent-de-L'ÎLe-d'Orléans`) are the same place; Chicago rows PL-0158 and PL-0016 are the same city. Consolidate and repoint refs.	open	P-0078	2026-05-30 20:44:12.395074-05	2026-05-30 20:44:12.395074-05
204	P-0078	cross_skill	FS ingest (`lrgdm-ingest-fs`): pull the eight missing children to grow the Pouliot branch.	open	P-0078	2026-05-30 20:44:12.395074-05	2026-05-30 20:44:12.395074-05
\.


--
-- Data for Name: source; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.source (source_id, source_type, title, informant, repository, url, citation, source_date, accessed_date, confidence, notes, created_at, updated_at) FROM stdin;
S-0001	other	Memorial prayer card — Gerald Arthur Kenny (1961–2025)	\N	Williams-Kampp Funeral Home	\N	Memorial/prayer card for Gerald Arthur Kenny, b. 3 Nov 1961, d. 17 Oct 2025; Williams-Kampp Funeral Home. Scanned from family records (Google Drive _drive_orginals), 2026-05-30.	2025	2026-05-30	high	Printed funeral prayer card, fully legible. Celtic cross + Irish blessing ("May the road rise up to meet you") indicate Irish Catholic. NOTE: source_type set to 'other' — consider adding a dedicated 'prayer_card' / 'funeral_card' code. Subject Gerald Arthur Kenny is NOT yet a person in the tree (see .md).\n\n[transcription 2025-prayer-card-gerald-kenny]\nIn Loving Memory of\nGerald Arthur Kenny\nBorn\nNOVEMBER 3, 1961\nAt Peace\nOCTOBER 17, 2025\n\n[Celtic cross illustration]\n\nMay the road rise up\nto meet you,\nMay the wind be always\nat your back,\nMay the sun shine warm\nupon your face,\nAnd the rain fall soft\nupon your fields,\nAnd until we meet again,\nMay God hold you\nin the palm of His hand.\n\nWilliams-Kampp Funeral Home	2026-05-30 12:24:02.787679-05	2026-05-30 12:24:02.787679-05
S-0002	grave_marker	Grave marker — Sherebiah Lambert & wife Pamelia	\N	\N	\N	Gravestone of Sherebiah Lambert (d. 1 May 1833, aged 74) and his wife Pamelia (d. 16 Jan 1845, aged 77); photograph of the monument (likely Canaan, Somerset County, Maine — burial place per DB, not stated on the stone).	1845	2026-05-30	high	Photograph of a shared headstone. Inscription names Sherebiah Lambert and 'Pamelia, his wife'. Age-74-at-1833-death matches Sherebiah Lambert Jr (P-0105, b. 1759), not Sr (P-0138, b. 1728).\n\n[transcription sherebiah-lambert-grave]\nSHEREBIAH LAMBERT\nDIED\nMay 1, 1833.\nÆ 74\nPAMELIA,\nhis wife\nDied Jan. 16, 1845.\nÆ. 77.	2026-05-30 16:03:18.881179-05	2026-05-30 16:03:18.881179-05
S-36D10AC3	website	FS extract LMWG-K6F + Iowa County Births 1880-1935 (record XVFQ-S6T)	\N	\N	https://familysearch.org/ark:/61903/1:1:XVFQ-S6T	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-306EE8EC	other	FS extract + already in GPKG (P-0072)	\N	\N	\N	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-3A1CF2A9	census	FS Iowa County Marriages KLWR-25L · 1900 US Census M9KG-C8W · FS extract KLGC-TLC	\N	\N	https://familysearch.org/ark:/61903/1:1:KLWR-25L	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-80F41041	other	GPKG R-0129	\N	\N	\N	\N	\N	\N	med	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-E658B293	census	FS Iowa County Births XVN1-39X · 1900 US Census M9KG-C8W · FS Cook Co Death Q2MN-CMG6	\N	\N	https://familysearch.org/ark:/61903/1:1:XVN1-39X	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-AD3D3F97	website	FS Iowa Delayed Birth Records 1850-1944, Q246-SDPC	\N	\N	https://www.familysearch.org/ark:/61903/1:1:Q246-SDPC	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-99C163B4	website	FS Iowa County Births XVZ5-VVH + Iowa Births & Christenings XV2Y-VDM	\N	\N	https://www.familysearch.org/ark:/61903/1:1:XVZ5-VVH	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-FDF13B88	census	FS Iowa Delayed Birth Records Q24X-4Z14 + 1920 US Census M6JH-P4L + 1925 IA State Census QKQW-X88X	\N	\N	https://www.familysearch.org/ark:/61903/1:1:Q24X-4Z14	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-4828EF7A	marriage_record	FS Iowa Marriages 1809-1992, XJPF-H6J + Iowa Co Marriages XJ8W-XZ2	\N	\N	https://www.familysearch.org/ark:/61903/1:1:XJPF-H6J	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-792A1300	census	1920 US Census M6JH-P4L + 1925 IA State Census QKQW-X88X	\N	\N	\N	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-0E9B4AC0	census	FS 1900 US Census M9KG-C8W	\N	\N	https://www.familysearch.org/ark:/61903/1:1:M9KG-C8W	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-A12E8B14	census	FS 1920 US Census M6JH-P4L	\N	\N	https://www.familysearch.org/ark:/61903/1:1:M6JH-P4L	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-EFEA344C	census	FS 1925 IA State Census QKQW-X88X	\N	\N	https://www.familysearch.org/ark:/61903/1:1:QKQW-X88X	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-3C8DEC75	census	FS 1885 IA State Census HZXM-SN2	\N	\N	https://www.familysearch.org/ark:/61903/1:1:HZXM-SN2	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-0F37D24C	census	FS 1895 IA State Census VT33-RWL (FS source title and reason-for-attachment note)	\N	\N	https://www.familysearch.org/ark:/61903/1:1:VT33-RWL	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-D3DD5D0F	death_record	FS Cook Co IL Death Cert Q2M8-FDWY · IL Deaths & Stillbirths N3Y4-J4F	\N	\N	https://www.familysearch.org/ark:/61903/1:1:Q2M8-FDWY	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-DA90F5B1	findagrave	Find A Grave cemetery record #2183425; WPA survey	\N	\N	https://www.findagrave.com/cemetery/2183425/monteith-cemetery	\N	\N	\N	high	\N	2026-05-30 13:43:52.653522-05	2026-05-30 13:43:52.653522-05
S-13D70DD6	website	Genealogy Trails, Guthrie Co. obituaries (Panora Vedette, 12 & 19 Jul 1894); WPA survey	\N	\N	https://genealogytrails.com/iowa/guthrie/obits_01.htm	\N	\N	\N	med	\N	2026-05-30 13:43:52.653522-05	2026-05-30 13:43:52.653522-05
S-5F963BBF	website	Iowa Legislature member record (37th GA); WPA survey	\N	\N	https://www.legis.iowa.gov/docs/History_Docs/37th%20GA/37_reed_sidney_guthrie.pdf	\N	\N	\N	low	\N	2026-05-30 13:43:52.653522-05	2026-05-30 13:43:52.653522-05
S-3AC5E090	obituary	Genealogy Trails & IAGenWeb obituary indexes (searched, no match)	\N	\N	https://genealogytrails.com/iowa/guthrie/	\N	\N	\N	\N	\N	2026-05-30 13:43:52.653522-05	2026-05-30 13:43:52.653522-05
S-F50FBD95	website	Official Roster of the Soldiers of the State of Ohio, Vol. III (21st–36th Regts.), 21st OVI Co. F	\N	\N	https://archive.org/details/ohiowarroster03howerich	\N	\N	\N	low	\N	2026-05-30 13:43:52.653522-05	2026-05-30 13:43:52.653522-05
S-70E4E2BE	website	Official Roster of the Soldiers of the State of Ohio, Vol. VIII, 122nd OVI Co. I	\N	\N	https://archive.org/details/officialrosterof08ohio	\N	\N	\N	med	\N	2026-05-30 13:43:52.653522-05	2026-05-30 13:43:52.653522-05
S-7CE9FAE0	website	Guthrie County, Iowa WPA Cemetery Records, letter R	\N	\N	http://iagenweb.org/guthrie/cemetery/WPA/wpa-r.html	\N	\N	\N	high	\N	2026-05-30 13:43:52.653522-05	2026-05-30 13:43:52.653522-05
S-86A81566	website	FS Family tab + Cook County birth registers	\N	\N	https://www.familysearch.org/en/tree/person/family/96JW-KX5	\N	\N	\N	high	\N	2026-05-30 20:44:12.395074-05	2026-05-30 20:44:12.395074-05
S-15C14395	website	Village of St. Anne; Shaw Local "A colony on the prairie"	\N	\N	https://villageofstanne.com/about/	\N	\N	\N	high	\N	2026-05-30 20:44:12.395074-05	2026-05-30 20:44:12.395074-05
S-D224FA55	website	Wikipedia "Charles Chiniquy"; Shaw Local	\N	\N	https://en.wikipedia.org/wiki/Charles_Chiniquy	\N	\N	\N	high	\N	2026-05-30 20:44:12.395074-05	2026-05-30 20:44:12.395074-05
S-8141B6A4	church_record	FamilySearch Sources tab ("unfinished attachments" warnings)	\N	\N	https://www.familysearch.org/en/tree/person/sources/96JW-KX5	\N	\N	\N	high	\N	2026-05-30 20:44:12.395074-05	2026-05-30 20:44:12.395074-05
S-3140FE85	census	derived from 1885 IA State Census HZXM-SN2 + GPKG E-0011 title "Helen Amelia (Boles) Foote"	\N	\N	\N	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-BC6891C3	website	Wikipedia "Monteith, Iowa"	\N	\N	https://en.wikipedia.org/wiki/Monteith,_Iowa	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-860A19C8	ssdi	Social Security Death Index	\N	\N	https://www.familysearch.org/ark:/61903/1:1:J1DC-22F	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-7E85F67E	numident	NUMIDENT	\N	\N	https://www.familysearch.org/ark:/61903/1:1:6K31-TC4G	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-8F4C3FCC	census	1950 census; brother's obituary	\N	\N	https://www.familysearch.org/ark:/61903/1:1:6X1N-2M9L	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-891101CB	census	Earl W. Reed Jr obituary (2024)	\N	\N	https://www.familysearch.org/ark:/61903/1:1:XMRK-KN1N	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-1259ED34	findagrave	FindAGrave	\N	\N	https://www.findagrave.com/memorial/285158675/leah-rae-reed	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-14001891	obituary	Leah's 2025 obituary + tree	\N	\N	https://www.williams-kampp.com/obituaries/Leah-R-Reed?obId=43658653	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-51B6AEA7	census	1940 & 1950 U.S. Census (Leah)	\N	\N	https://www.familysearch.org/search/record/results	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-84D090B0	oral_history	Family testimony (John Kenny, proband), relayed 2026-05-30	\N	\N	\N	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-AFE96315	findagrave	FindAGrave Memorial #288488976 (created by user "Beth D" 29 Oct 2025); cross-confirmed by IL Archdiocese of Chicago Cemetery Records 1864-1989 (FS Q2HF-8P34, "23 Feb 82").	\N	\N	https://www.findagrave.com/memorial/288488976/ugo-mariotti	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-F6A67948	website	Iowa, County Births, 1880-1935	\N	\N	https://www.familysearch.org/ark:/61903/1:1:XVN1-39D	\N	\N	\N	high	\N	2026-05-30 15:38:23.279346-05	2026-05-30 15:38:23.279346-05
S-901C14F2	findagrave	Same 1927 Iowa marriage record.	\N	\N	https://www.familysearch.org/ark:/61903/1:1:XJX4-VDB	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-FBA8255E	naturalization	Illinois, Northern District Naturalization Index, 1840-1950 (FS XKGJ-M1P).	\N	\N	https://www.familysearch.org/ark:/61903/1:1:XKGJ-M1P	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-3EF7B735	obituary	Illinois, Cook County, Birth Certificates, 1871-1953 (FS QVSH-PG84). Cross-confirmed by Roland's 2023 obituary (Shirley & Stout).	\N	\N	https://www.familysearch.org/ark:/61903/1:1:QVSH-PG84	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-16AC9E36	census	United States, Census, 1930 (FS XMKQ-K9T).	\N	\N	https://www.familysearch.org/ark:/61903/1:1:XMKQ-K9T	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-93DF3F9C	census	United States, Census, 1940 (FS KMBB-TY1).	\N	\N	https://www.familysearch.org/ark:/61903/1:1:KMBB-TY1	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-EAFAD919	draft_registration	Iowa, World War II Draft Registration Cards, 1940-1945 (FS QG2P-J7N1).	\N	\N	https://www.familysearch.org/ark:/61903/1:1:QG2P-J7N1	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-E7E14B49	birth_certificate	Illinois, Cook County, Birth Certificates, 1871-1953 (FS QGCF-8JT5 and FS QGCF-M3H7).	\N	\N	https://www.familysearch.org/ark:/61903/1:1:QGCF-M3H7	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-79D5EA92	church_record	Wikipedia: Chiesa di San Leopoldo (Monsummano Terme); Diocesi di Pescia parish register.	\N	\N	https://www.diocesidipescia.it/wd-annuario-enti/vicariato-di-monsummano-terme-282/s-leopoldo-cintolese-cintolese-237/	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-0FCB8893	website	Fauri, 2025, "A geographic and social profile of Italy's great migration (1876–1913)" (Wiley International Migration).	\N	\N	https://onlinelibrary.wiley.com/doi/10.1111/imig.13344	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-707ACA78	census	1930 + 1940 + 1950 US Census (all FS-attached).	\N	\N	https://www.familysearch.org/ark:/61903/1:1:6FQW-JRYD	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-41743961	ssdi	SSDI (FS JLLR-Z6F).	\N	\N	https://www.familysearch.org/ark:/61903/1:1:JLLR-Z6F	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-02EDC1CB	immigration	Inference from FS J6F8-T28 + null FS hits for Leopoldo Mariotti on 1920 Giuseppe Verdi.	\N	\N	https://www.familysearch.org/ark:/61903/1:1:J6F8-T28	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-3980082F	findagrave	FindAGrave memorial #10569107 (gravestone photo via Iowa Gravestone Photos); cross-confirmed by Benton County Pioneers narrative	\N	\N	https://www.findagrave.com/memorial/10569107/permelia-lambert	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-06A59EB5	website	NPS Battle Unit Details; iagenweb 3rd IA Cav regimental history; Wikipedia 3rd IA Cav	\N	\N	https://en.wikipedia.org/wiki/3rd_Regiment_Iowa_Volunteer_Cavalry	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-87DBA874	website	Logan's Roster; NPS	\N	\N	http://iagenweb.org/civilwar/books/logan/mil603.htm	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-C06CFFCD	website	MyHeritage index; Benton County Pioneers	\N	\N	https://iagenweb.org/benton/pioneers.htm	\N	\N	\N	med	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-454BFE1A	census	FindAGrave memorial #16177390 (search snippet — direct fetch 403)	\N	\N	https://www.findagrave.com/memorial/16177390/helen-amelia-knapp	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-75E512CA	website	HomeTownLocator	\N	\N	https://idaho.hometownlocator.com/id/jerome/falls-city.cfm	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-6768718C	findagrave	FindAGrave cemetery #80667	\N	\N	https://www.findagrave.com/cemetery/80667/twin-falls-cemetery	\N	\N	\N	med	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-2A57A6F0	census	WikiTree Lambert-3978	\N	\N	https://www.wikitree.com/wiki/Lambert-3978	\N	\N	\N	high	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-CC8A8048	other	Multiple gazetteer + state history sources	\N	\N	\N	\N	\N	\N	med	\N	2026-05-30 09:53:51.302088-05	2026-05-30 09:53:51.446353-05
S-EABD01D2	website	Illinois, Cook County Deaths, 1871-1998	\N	\N	https://www.familysearch.org/ark:/61903/1:1:Q2MN-CML4	\N	\N	\N	high	\N	2026-05-30 15:38:23.279346-05	2026-05-30 15:38:23.279346-05
S-0D54D37B	findagrave	Find a Grave Index	\N	\N	https://www.familysearch.org/ark:/61903/1:1:QV2L-ZBPS	\N	\N	\N	high	\N	2026-05-30 15:38:23.279346-05	2026-05-30 15:38:23.279346-05
S-E3E75D10	census	US Social Security NUMIDENT, 1936-2007	\N	\N	https://www.familysearch.org/tree/person/sources/M3P5-XF6	\N	\N	\N	high	\N	2026-05-30 15:38:23.279346-05	2026-05-30 15:38:23.279346-05
S-5F9361B1	website	FS Tree timeline / [[P-0061]]	\N	\N	https://www.familysearch.org/en/tree/person/timeline/M3P5-XF6	\N	\N	\N	med	\N	2026-05-30 15:38:23.279346-05	2026-05-30 15:38:23.279346-05
\.


--
-- Data for Name: source_type; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.source_type (code, label) FROM stdin;
census	Census
vital_record	Vital record
birth_certificate	Birth certificate
death_record	Death record
marriage_record	Marriage record
obituary	Obituary
findagrave	FindAGrave memorial
ssdi	Social Security Death Index
numident	SS NUMIDENT
oral_history	Oral history / family testimony
newspaper	Newspaper
book	Book / compiled genealogy
website	Website / online tree
photo	Photograph
military	Military record
immigration	Immigration / passenger record
naturalization	Naturalization record
directory	City / business directory
church_record	Church / parish record
draft_registration	Draft / Selective Service registration
other	Other
grave_marker	Grave marker / cemetery monument
\.


--
-- Name: citation_citation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.citation_citation_id_seq', 208, true);


--
-- Name: event_participant_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.event_participant_id_seq', 226, true);


--
-- Name: media_link_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.media_link_id_seq', 6, true);


--
-- Name: person_name_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.person_name_id_seq', 150, true);


--
-- Name: research_lead_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.research_lead_id_seq', 205, true);


--
-- Name: citation citation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.citation
    ADD CONSTRAINT citation_pkey PRIMARY KEY (citation_id);


--
-- Name: era era_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.era
    ADD CONSTRAINT era_pkey PRIMARY KEY (code);


--
-- Name: event_participant event_participant_event_id_person_id_role_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_participant
    ADD CONSTRAINT event_participant_event_id_person_id_role_key UNIQUE (event_id, person_id, role);


--
-- Name: event_participant event_participant_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_participant
    ADD CONSTRAINT event_participant_pkey PRIMARY KEY (id);


--
-- Name: event event_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event
    ADD CONSTRAINT event_pkey PRIMARY KEY (event_id);


--
-- Name: event_type event_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_type
    ADD CONSTRAINT event_type_pkey PRIMARY KEY (code);


--
-- Name: media_link media_link_media_id_subject_type_subject_id_role_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_link
    ADD CONSTRAINT media_link_media_id_subject_type_subject_id_role_key UNIQUE (media_id, subject_type, subject_id, role);


--
-- Name: media_link media_link_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_link
    ADD CONSTRAINT media_link_pkey PRIMARY KEY (id);


--
-- Name: media media_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media
    ADD CONSTRAINT media_pkey PRIMARY KEY (media_id);


--
-- Name: narrative narrative_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.narrative
    ADD CONSTRAINT narrative_pkey PRIMARY KEY (person_id);


--
-- Name: person_name person_name_person_id_name_type_value_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.person_name
    ADD CONSTRAINT person_name_person_id_name_type_value_key UNIQUE (person_id, name_type, value);


--
-- Name: person_name person_name_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.person_name
    ADD CONSTRAINT person_name_pkey PRIMARY KEY (id);


--
-- Name: person person_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.person
    ADD CONSTRAINT person_pkey PRIMARY KEY (person_id);


--
-- Name: place place_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.place
    ADD CONSTRAINT place_pkey PRIMARY KEY (place_id);


--
-- Name: relation_type relation_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relation_type
    ADD CONSTRAINT relation_type_pkey PRIMARY KEY (code);


--
-- Name: relationship relationship_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relationship
    ADD CONSTRAINT relationship_pkey PRIMARY KEY (rel_id);


--
-- Name: research_lead research_lead_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.research_lead
    ADD CONSTRAINT research_lead_pkey PRIMARY KEY (id);


--
-- Name: source source_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.source
    ADD CONSTRAINT source_pkey PRIMARY KEY (source_id);


--
-- Name: source_type source_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.source_type
    ADD CONSTRAINT source_type_pkey PRIMARY KEY (code);


--
-- Name: citation_source_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX citation_source_ix ON public.citation USING btree (source_id);


--
-- Name: citation_subject_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX citation_subject_ix ON public.citation USING btree (subject_type, subject_id);


--
-- Name: event_participant_person_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX event_participant_person_ix ON public.event_participant USING btree (person_id);


--
-- Name: event_place_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX event_place_ix ON public.event USING btree (place_id);


--
-- Name: event_type_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX event_type_ix ON public.event USING btree (event_type);


--
-- Name: media_link_subject_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX media_link_subject_ix ON public.media_link USING btree (subject_type, subject_id);


--
-- Name: media_sha256_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX media_sha256_ix ON public.media USING btree (sha256);


--
-- Name: person_birth_place_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX person_birth_place_ix ON public.person USING btree (birth_place_id);


--
-- Name: person_death_place_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX person_death_place_ix ON public.person USING btree (death_place_id);


--
-- Name: person_fs_id_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX person_fs_id_ix ON public.person USING btree (fs_id);


--
-- Name: person_name_person_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX person_name_person_ix ON public.person_name USING btree (person_id);


--
-- Name: person_name_value_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX person_name_value_ix ON public.person_name USING btree (lower(value));


--
-- Name: place_geom_gix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX place_geom_gix ON public.place USING gist (geom);


--
-- Name: relationship_a_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX relationship_a_ix ON public.relationship USING btree (person_id_a);


--
-- Name: relationship_b_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX relationship_b_ix ON public.relationship USING btree (person_id_b);


--
-- Name: research_lead_person_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX research_lead_person_ix ON public.research_lead USING btree (person_id);


--
-- Name: research_lead_status_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX research_lead_status_ix ON public.research_lead USING btree (status);


--
-- Name: source_type_ix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX source_type_ix ON public.source USING btree (source_type);


--
-- Name: citation citation_subject_fk_trg; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER citation_subject_fk_trg BEFORE INSERT OR UPDATE ON public.citation FOR EACH ROW EXECUTE FUNCTION public.citation_subject_fk();


--
-- Name: event event_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER event_set_updated_at BEFORE UPDATE ON public.event FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: media media_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER media_set_updated_at BEFORE UPDATE ON public.media FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: narrative narrative_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER narrative_set_updated_at BEFORE UPDATE ON public.narrative FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: person person_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER person_set_updated_at BEFORE UPDATE ON public.person FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: place place_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER place_set_updated_at BEFORE UPDATE ON public.place FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: relationship relationship_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER relationship_set_updated_at BEFORE UPDATE ON public.relationship FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: research_lead research_lead_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER research_lead_set_updated_at BEFORE UPDATE ON public.research_lead FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: source source_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER source_set_updated_at BEFORE UPDATE ON public.source FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: citation citation_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.citation
    ADD CONSTRAINT citation_source_id_fkey FOREIGN KEY (source_id) REFERENCES public.source(source_id) ON DELETE CASCADE;


--
-- Name: event event_event_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event
    ADD CONSTRAINT event_event_type_fkey FOREIGN KEY (event_type) REFERENCES public.event_type(code);


--
-- Name: event_participant event_participant_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_participant
    ADD CONSTRAINT event_participant_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.event(event_id) ON DELETE CASCADE;


--
-- Name: event_participant event_participant_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_participant
    ADD CONSTRAINT event_participant_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person(person_id);


--
-- Name: event event_place_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event
    ADD CONSTRAINT event_place_id_fkey FOREIGN KEY (place_id) REFERENCES public.place(place_id);


--
-- Name: media_link media_link_media_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_link
    ADD CONSTRAINT media_link_media_id_fkey FOREIGN KEY (media_id) REFERENCES public.media(media_id) ON DELETE CASCADE;


--
-- Name: narrative narrative_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.narrative
    ADD CONSTRAINT narrative_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person(person_id) ON DELETE CASCADE;


--
-- Name: person person_birth_place_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.person
    ADD CONSTRAINT person_birth_place_id_fkey FOREIGN KEY (birth_place_id) REFERENCES public.place(place_id);


--
-- Name: person person_death_place_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.person
    ADD CONSTRAINT person_death_place_id_fkey FOREIGN KEY (death_place_id) REFERENCES public.place(place_id);


--
-- Name: person_name person_name_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.person_name
    ADD CONSTRAINT person_name_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person(person_id) ON DELETE CASCADE;


--
-- Name: person person_profile_media_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.person
    ADD CONSTRAINT person_profile_media_fk FOREIGN KEY (profile_media_id) REFERENCES public.media(media_id);


--
-- Name: relationship relationship_person_id_a_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relationship
    ADD CONSTRAINT relationship_person_id_a_fkey FOREIGN KEY (person_id_a) REFERENCES public.person(person_id);


--
-- Name: relationship relationship_person_id_b_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relationship
    ADD CONSTRAINT relationship_person_id_b_fkey FOREIGN KEY (person_id_b) REFERENCES public.person(person_id);


--
-- Name: relationship relationship_relation_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relationship
    ADD CONSTRAINT relationship_relation_fkey FOREIGN KEY (relation) REFERENCES public.relation_type(code);


--
-- Name: research_lead research_lead_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.research_lead
    ADD CONSTRAINT research_lead_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person(person_id) ON DELETE CASCADE;


--
-- Name: source source_source_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.source
    ADD CONSTRAINT source_source_type_fkey FOREIGN KEY (source_type) REFERENCES public.source_type(code);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: -
--

GRANT ALL ON SCHEMA public TO lrgdm_rw;


--
-- Name: TABLE citation; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.citation TO lrgdm_rw;


--
-- Name: SEQUENCE citation_citation_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,USAGE ON SEQUENCE public.citation_citation_id_seq TO lrgdm_rw;


--
-- Name: TABLE era; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.era TO lrgdm_rw;


--
-- Name: TABLE event; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.event TO lrgdm_rw;


--
-- Name: TABLE event_participant; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.event_participant TO lrgdm_rw;


--
-- Name: SEQUENCE event_participant_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,USAGE ON SEQUENCE public.event_participant_id_seq TO lrgdm_rw;


--
-- Name: TABLE event_type; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.event_type TO lrgdm_rw;


--
-- Name: TABLE geography_columns; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.geography_columns TO lrgdm_rw;


--
-- Name: TABLE geometry_columns; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.geometry_columns TO lrgdm_rw;


--
-- Name: TABLE media; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.media TO lrgdm_rw;


--
-- Name: TABLE media_link; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.media_link TO lrgdm_rw;


--
-- Name: SEQUENCE media_link_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,USAGE ON SEQUENCE public.media_link_id_seq TO lrgdm_rw;


--
-- Name: TABLE narrative; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.narrative TO lrgdm_rw;


--
-- Name: TABLE person; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.person TO lrgdm_rw;


--
-- Name: TABLE person_name; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.person_name TO lrgdm_rw;


--
-- Name: SEQUENCE person_name_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,USAGE ON SEQUENCE public.person_name_id_seq TO lrgdm_rw;


--
-- Name: TABLE place; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.place TO lrgdm_rw;


--
-- Name: TABLE relation_type; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.relation_type TO lrgdm_rw;


--
-- Name: TABLE relationship; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.relationship TO lrgdm_rw;


--
-- Name: TABLE research_lead; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.research_lead TO lrgdm_rw;


--
-- Name: SEQUENCE research_lead_id_seq; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,USAGE ON SEQUENCE public.research_lead_id_seq TO lrgdm_rw;


--
-- Name: TABLE source; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.source TO lrgdm_rw;


--
-- Name: TABLE source_type; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.source_type TO lrgdm_rw;


--
-- Name: TABLE spatial_ref_sys; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.spatial_ref_sys TO lrgdm_rw;


--
-- Name: TABLE v_birth_location_points; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.v_birth_location_points TO lrgdm_rw;


--
-- Name: TABLE v_birth_to_death_lines; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.v_birth_to_death_lines TO lrgdm_rw;


--
-- Name: TABLE v_birth_to_death_lines_eras; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.v_birth_to_death_lines_eras TO lrgdm_rw;


--
-- Name: TABLE v_citations_expanded; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.v_citations_expanded TO lrgdm_rw;


--
-- Name: TABLE v_death_location_points; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.v_death_location_points TO lrgdm_rw;


--
-- Name: TABLE v_event_participants; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.v_event_participants TO lrgdm_rw;


--
-- Name: TABLE v_event_points; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.v_event_points TO lrgdm_rw;


--
-- Name: TABLE v_person_locations; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.v_person_locations TO lrgdm_rw;


--
-- Name: TABLE v_source_summary; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.v_source_summary TO lrgdm_rw;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE john IN SCHEMA public GRANT SELECT,USAGE ON SEQUENCES TO lrgdm_rw;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE john IN SCHEMA public GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO lrgdm_rw;


--
-- PostgreSQL database dump complete
--

\unrestrict dffS5mi7DsghD0oQoXRipcIYZmay0BSdS3V1bVbHfpgy9BMc2JSrmLianWW9GVH

