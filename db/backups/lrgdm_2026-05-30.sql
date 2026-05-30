--
-- PostgreSQL database dump
--

\restrict KntsdULVjzjXiXIBSxJJ5NaG4szrMXHe9Xffg1td2LDtBOB3XR5AxVRKfZp7u36

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
E-0029	Birth of Earl Wayne Reed	birth	1899-07-19	\N	\N	PL-0015	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0030	Death of Earl Wayne Reed	death	1974-04-11	\N	\N	\N	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0031	\N	residence	1900	\N	\N	PL-0022	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0032	Military Draft Registration	custom	1918	\N	\N	PL-0023	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0033	\N	residence	1930	\N	\N	PL-0024	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0034	\N	residence	1940	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0025` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0035	Residence	residence	\N	\N	\N	PL-0026	\N	\N	\N	public	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
E-0036	Citizenship	custom	\N	\N	\N	\N	\N	\N	\N	public	[fixup 2026-05-26] place_id was `PL-0027` (no matching Places row)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
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
E-0197	Burial of Earl Wayne Reed Sr	burial	1974	\N	year	PL-5235	\N	high	Burial of Estelle's only known child, Earl Wayne Reed Sr, in Elgin, Kane County, Illinois, in 1974. Per FS PID M3P5-XF6.	public	Source: FamilySearch extract 2026-05-26. Specific cemetery within Elgin not given.	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
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
\.


--
-- Data for Name: event_participant; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.event_participant (id, event_id, person_id, role) FROM stdin;
1	E-0001	P-0001	\N
2	E-0002	P-0001	\N
3	E-0002	P-0002	\N
4	E-0003	P-0001	\N
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
35	E-0029	P-0062	\N
36	E-0030	P-0062	\N
37	E-0031	P-0062	\N
38	E-0032	P-0062	\N
39	E-0033	P-0062	\N
40	E-0034	P-0062	\N
41	E-0035	P-0062	\N
42	E-0036	P-0062	\N
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
122	E-0116	P-0001	\N
123	E-0117	P-0001	\N
124	E-0118	P-0001	\N
125	E-0119	P-0001	\N
126	E-0120	P-0001	\N
127	E-0121	P-0001	\N
128	E-0122	P-0001	\N
129	E-0123	P-0001	\N
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
\.


--
-- Data for Name: media_link; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.media_link (id, media_id, subject_type, subject_id, role, sort_order) FROM stdin;
\.


--
-- Data for Name: narrative; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.narrative (person_id, dossier_date, body_md, rendered_html, published, updated_at) FROM stdin;
P-0036	2026-05-28	Estelle Gertrude Lambert was born on 30 October 1882 in Seely Township, Guthrie County, Iowa, on the rolling prairie about twenty miles west of Des Moines [1]. Her father Abiram Stacy Lambert, a fifty-one-year-old veteran of the 3rd Iowa Cavalry, had taken his second wife only thirteen months earlier — Helen Amelia Boles, then thirty-three, herself already a widow with three Foote children from a previous marriage [4][5][17][20]. The America Estelle was born into was Chester A. Arthur's: a presidency that had begun nine months earlier when Garfield died of an assassin's bullet, a Midwest that had just finished absorbing the post-bellum railroad boom, and an Iowa whose corn-belt agriculture was newly tied to Chicago by the Rock Island Line. The 1885 Iowa State Census found the Lamberts in Seely, Guthrie County, a household of seven: Abiram and Helen, two-year-old Gertrude and her one-year-old sister Sylvia, and Helen's three Foote children — Clara sixteen, Arthur fifteen, Edwin four [17]. It was a blended household before the word existed, a half-Civil-War-veteran/half-prairie-widow construction of the kind the war had left scattered across the Mississippi Valley.\n\nThe household did not last. Sometime between the 1885 state census and the 1895 one, Helen left Abiram. By the 1895 Iowa State Census she was "Helen Amelia Knapp," living with a man named Leslie Knapp; Estelle, then twelve, was still recorded as "Stella Gertrude Lambert" but was effectively being raised under a stepfather's roof from her teenage years onward [18]. There is no surviving Iowa divorce record yet found for Abiram and Helen, but the 1895 facts are unambiguous: Helen had moved on, Abiram was somewhere else (he would drift west toward Idaho over the next decade), and Estelle's adolescence took place in a Knapp household, not a Lambert one. The Iowa of the early 1890s was a hard place to be the daughter of a separated couple — the state's farm economy had collapsed into the Panic of 1893, the Populist movement was at its peak in the county courthouses around her, and "Coxey's Army" of unemployed workers passed through the Midwest the year she turned twelve.\n\nShe married young, and into the founding family of the next town over. On 5 March 1899, at sixteen, Estelle married John Foulk Reed in Guthrie County [6][7]. Monteith, John's birthplace and the nominal site of the wedding, was less a village than a Reed proposition: it had been platted only eighteen years earlier by Harmon T. Reed when the railroad reached his land, and the Reeds had been its founding family ever since [21]. Their first child Earl Wayne Reed was born four and a half months later, on 19 July 1899 [8][14] — by the time the 1900 US Census found the family in Valley Township at Guthrie Center, they were a tidy household of three, "Years married 1, Number of living children 1" [14]. Three more Reed children followed in quick succession: Harold Merle in January 1901, Oscar G. in 1903, and Edna Gertrude in August 1906 [9][10][11]. For ten years Estelle was a Guthrie County farm wife with four small children, while McKinley gave way to Roosevelt and Taft and the rural-Midwest banner stories shifted from free silver to trust-busting to the first stirrings of Prohibition.\n\nThen in 1912 she disappeared from the Reed household. On 18 September 1912, in Algona, Kossuth County, Iowa — 150 miles north of Guthrie Center — Estella G. Reed married Clarence D. Eichinger of Lafayette, Indiana, with her marital status politely entered on the license as "Widowed" [12]. John Foulk Reed was not, in fact, dead; he would live another forty years, dying in Davenport in 1952 [6]. "Widowed" was simply the easier word in 1912 Iowa for a Methodist-belt mother of four leaving one husband for another. By the 1920 US Census the new Eichinger household — Clarence, Gertrude, the teenage Edna (re-recorded under her stepfather's surname), and a six-year-old son Ray almost certainly Clarence's — was living at Sioux Falls Ward 11 in Minnehaha County, South Dakota, on the eastern edge of the Dakota plains [13][15]. The pull west wasn't unusual for the era: World War I had driven Iowa farm prices into a speculative spike, Sioux Falls had become a regional grain and meatpacking hub around the John Morrell plant, and second marriages with young children often moved across state lines to start clean. They didn't stay. By the 1925 Iowa State Census the family was back in Iowa, at Waterloo (4th Ward) in Black Hawk County, with eighteen-year-old Edna once again signing herself "Reed" [16].\n\nThe 1930s broke the Eichinger marriage and ushered in a third. The decade is largely undocumented in her open record — the 1930 and 1940 censuses are not among the 19 sources attached to her FamilySearch tree, and she does not appear in any of them under either Reed, Eichinger, or Lambert. By the time she next surfaces, in May 1946, she is "Estelle G **Sinderson**," divorced, living at 1339 South 48th Street on Chicago's West Side, and working as a waitress [19]. Her death certificate names her last husband only as "Harry" [19]. The Chicago of the war years had been a magnet for displaced Midwesterners — defense plants, war work, and a streetcar-flat economy that gave older women a place to land — and the Lawndale/Cicero corridor where 48th Street ran was thick with second-generation Iowa and Indiana families. She had also outlived her mother by seven years: Helen Knapp, the woman who had left Abiram a generation earlier and now lay under a stone reading "Helen Amelia Knapp," died in Iowa in January 1939 and was buried at Violet Hill Cemetery in Perry [5].\n\nEstelle died in Chicago on 20 May 1946 at sixty-three [2][19]. The spring of 1946 was the world's first nuclear peacetime — V-J Day was nine months in the past, Truman was president, and a wave of strikes was working through the postwar economy from the United Mine Workers to the railroad unions. The O'Shea and Raleigh funeral home on the West Side prepared her body and sent it north to Wisconsin, where she was buried three days later on 23 May 1946 at Prairie Home Cemetery, Waukesha — under her last married name, Sinderson, which is why a search of the cemetery's R-surname index turns up nothing [3][19]. Why Waukesha? The death certificate gives no answer, and none of the Lambert, Reed, or Eichinger families had previously been buried there. Harry Sinderson's roots are the most likely thread: somewhere in southeastern Wisconsin he had family ground, and the wife he had divorced years earlier was given a place in it. Her first husband John Foulk Reed died six years later in Davenport and was buried in Oakdale Memorial Gardens, Scott County, Iowa [6]. Their oldest son Earl Wayne Reed Sr lived in Chicago through middle age and was buried in Elgin, Kane County, Illinois, in April 1974 [8]. Of the five children Estelle bore between 1899 and ~1914, only Earl is documented in the LRGDM tree so far; the others — Harold, Oscar, Edna, and Ray — are open leads for a future ingest.	\N	t	2026-05-30 09:53:51.446353-05
P-0056	2026-05-30	John Ronald Reed was born on July 18, 1934, in Chicago, into a city and a country still in the grip of the Great Depression [1]. Franklin Roosevelt was barely a year into the New Deal; the banks had only recently reopened and a third of working Chicagoans had no steady job. His birth was registered three weeks later, on August 7 — routine civic paperwork in the expanding administrative state. He was a son of Earl Wayne Reed, born in 1899, and Isabelle Harriet Zika, born in 1913 [3] — an Anglo-American Reed father and a mother whose surname, Zika, places her among the great Bohemian-Czech migration that had filled the near-west suburbs a generation earlier. John was the middle of three brothers: Wayne came first, in 1930, and Jim followed around 1940 [8][9].\n\nThat heritage set the family in one of the most distinctive enclaves of working-class Chicagoland: Cicero, the dense, proudly Czech-and-Slovak industrial town built around the colossal Western Electric Hawthorne Works and only a few years removed from its notoriety as Al Capone's base after he was pushed out of Chicago proper. But the household John grew up in was no postcard of the era. By the spring of 1950 the census-taker found him, fifteen and still in school, in a home headed not by his father but by his mother — Isabelle, listed as divorced, supporting three sons on her wages as a "biller" in a telephone factory [5][6][7], almost certainly the Hawthorne plant that loomed over the town. The marriage had broken sometime in the 1940s, leaving a Depression-raised single mother to carry her boys through the postwar years. John came of age in that house — seven at Pearl Harbor, ten on V-J Day, too young to serve but old enough to feel his father's absence. At fourteen, in February 1949, he walked into a Social Security office for his first card, the document a working-class teenager got before his first paying job [4].\n\nThen came the war. John turned eighteen in July 1952, with the fighting in Korea grinding toward its bloody stalemate, and he served in the U.S. military during the Korean conflict [19] — by his family's account training at Camp Pendleton, the sprawling Marine Corps base on the California coast, a continent away from the two-flats of Cicero. He was one of the great cohort of his birth year swept into Korea and the Cold War garrisons that manned the line after the July 1953 armistice. For a boy raised by a single mother in a telephone-factory town, the Marines would have been both rupture and opportunity — the first time many such young men ever left Illinois.\n\nHe came home to a country booming, and the story turns. Around 1956, John — about twenty-two — married Leah Rae Mariotti, a twenty-year-old who had been born in Chicago, raised partly in Bedford, Iowa, and drawn back to the city; her parents were the Italian-American Ugo and Lena Mariotti [11][18]. It was a quintessential second-generation, melting-pot match of mid-century Chicago: an English-and-Czech Reed marrying into an Italian Catholic family, and John took up that faith and that church. The newlyweds set up house in Westchester, a brand-new bungalow suburb just west of the city [11] — and then, like millions of young couples riding the postwar boom of mortgages, expressways and parish schools, they pushed farther out, settling around 1964 in Glen Ellyn, a leafy DuPage County commuter town on the Chicago & North Western line [12]. There they raised an enormous baby-boom family — seven children, two sets of twins among them [13] — in a house on a quiet street, anchored to St. James the Apostle parish [14].\n\nFor John, Glen Ellyn was the destination of a single remarkable arc: from a broken Depression-era home in industrial Cicero to a full house in the green collar-county suburbs his children would call home for sixty years. He lived out the second half of the American Century there, the Social Security record fixing his address at ZIP 60137 [2]. His older brother Wayne had made the same westward move, raising his own family in Hoffman Estates from 1961 [8]; the three Cicero boys had scattered into the suburbs that the GI generation built.\n\nJohn Ronald Reed Sr died in DuPage County on May 2, 1995, at the age of sixty [2][15]. He left Leah a widow at fifty-eight, with seven grown children — and it was she, in the long widowhood that followed, who became the keeper of the family's memory, teaching herself genealogy and tracing the Reed and Mariotti lines back ten generations [17]. She outlived him by three decades, dying in July 2025 at eighty-eight, and was buried at Queen of Heaven Catholic Cemetery in Hillside [16]; John, who has no memorial of his own online, almost certainly lies in the same Catholic ground. Their line runs forward to the present day through their daughter Karen, whose son John Kenny is the proband at the root of this very family tree [17] — so that the boy born in Depression Cicero became, in the fullness of time, the grandfather at the center of the map.	\N	t	2026-05-30 09:53:51.446353-05
P-0059	2026-05-28	Ugo Mariotti was born on 21 July 1903 in Cintolese, a hamlet of Monsummano Terme in the Tuscan Province of Pistoia, a settlement that owed its existence to the late-eighteenth-century reclamation of the Fucecchio marshes by Grand Duke Pietro Leopoldo of Lorraine [15]. The parish around which the village was organized — *San Leopoldo in Cintolese*, consecrated in 1788 and named for the reformist grand duke who would soon become Holy Roman Emperor Leopold II — was almost certainly the church in which the infant Ugo was baptized in the summer of 1903 [15], the year Pope Leo XIII died and was succeeded by Pius X. The unified Kingdom of Italy was only forty-two years old. Vittorio Emanuele III had been on the throne three years; the *Risorgimento* generation was giving way to a country with a new, brittle ambition. Tuscany had been an "early generator" of emigrants since the 1870s [16], and across the Province of Pistoia young men were beginning to make the calculation that the future was on the other side of the Atlantic. His father was Leopoldo Mariotti (P-0067), born 1871 and named for the parish saint; his mother was Quintilia Lenzi (P-0069), born 1876 — both still in Cintolese when their son was born [5][6]. (An earlier guess in this dossier had Zelinda Pagni as his mother; the 1927 Iowa marriage record corrects that to Quintilia Lenzi.)\n\nHis childhood spanned the years in which Italy entered and exited the First World War. He was eleven when Italy joined the Entente in 1915 and fifteen at the armistice in November 1918 — old enough to remember the men who never came back from the Isonzo, too young to have served. The post-war biennio rosso, the rise of Mussolini in October 1922, and the agricultural crisis of the early 1920s formed the backdrop against which Ugo, like thousands of young Tuscan men, decided to cross. He was eighteen, single, and travelling alone when on **3 September 1920** he stepped off the **SS *Giuseppe Verdi*** at Ellis Island after a voyage from Genoa [19]. His father Leopoldo was named on the manifest as his nearest relative in country of last residence — meaning Leopoldo and Quintilia stayed in Cintolese [20]. (Leopoldo would die in 1933, almost certainly in Italy; the death place is one of this dossier's open follow-ups.) The voyage left from Genoa rather than Naples or Palermo — the standard Tuscan-Ligurian emigrant departure rather than the southern Italian one — and on the same manifest page sat a fellow passenger named Severino Stefanelli, probably from the same corner of the Province of Pistoia. Seven years later, in 1927, Ugo was naturalized in the U.S. District Court for the Northern District of Illinois [7] — exactly the five-year statutory residency window from his arrival, the earliest moment he could become a citizen.\n\nWhat he found, surprisingly, was not the Italian-immigrant Chicago of received imagination. On 5 May 1927 — the same year his naturalization came through — he married a seventeen-year-old Chicago-born Italian-American girl named **Lena M. Dini** in **Lenox, Taylor County, Iowa** [4], a tiny town in the southwestern corner of the state. His parents were named on the record (the indexer got them wrong: "Geopaldo Mariotti" is Leopoldo, "Quinta Ginse" is Quintilia Lenzi [5][6]). The young couple's first child, a son they named **Rolando** — anglicized to Roland — was born in Cicero, Illinois, on 17 June 1929 [8], registered there on 21 August as Certificate #228, with the father listed as "Hugo Mariotti, 25, Italian" and the mother as "Lina Dini, 20, Cicero." Roland's arrival came on the eve of the Wall Street crash. Cicero in 1929 was Al Capone's town — he had moved his headquarters into the Hawthorne Hotel in 1923 — and the St. Valentine's Day Massacre in Chicago in February 1929 was four months before Rolando Mariotti's birth.\n\nThe family did not stay in Cicero. By the April 1930 census they had settled in Bedford, Taylor County, Iowa — the same county where they had married — and they would remain in Bedford for the entire span of the Great Depression and the Second World War [9][10][12]. Ugo, who had emigrated from a Tuscan village known mostly for grapes and reclaimed marshland, became the proprietor of a "Candy Kitchen" in a southwestern Iowa town of fifteen hundred people [12][17]. The Tuscan-Italian confectioner in a Midwest small town was a real and underdocumented immigration story of the 1900s–1930s; he was one of many. When the United States entered the Second World War, Ugo — at thirty-eight, on the upper edge of the 18-45 band — registered for the Third Registration of the WWII Draft on 16 February 1942 in Bedford [11]. The card recorded him as five foot five, a hundred and sixty pounds, with brown hair and brown eyes and a light complexion; his employer was "Self"; his nearest relative was his wife Lena. Two more children had joined the household by then: **Leah Rae Mariotti** (P-0055), the great-grandmother of this database's proband, born 8 September 1936 in Chicago and registered on Cook County Certificate #32174 [14][10], and after the war, **Celiste Dee Mariotti** — the Celeste who appears in her brother Roland's 2023 obituary — born ~1944 in Illinois and recorded with the family in Bedford by the 1950 census [13]. (The 1936 birth certificate carries an interesting puzzle: it is indexed twice on FamilySearch with the same certificate number, once under "UNKNOWN" daughter and once under "Sarah Joy Mariotti." Whether Leah Rae was originally named Sarah Joy and renamed, or whether the indexer mis-tagged a record, is unresolved [14].)\n\nThrough the 1950s and 1960s the children grew and left. Roland served in the postwar military with stations in Alaska, Japan, and Korea and married a Polish-American woman, Virginia Jaskolski, at St. Valentine's Catholic Church on 5 September 1953 — an intermarriage of the kind that the second-generation Italian and Polish Catholic communities were beginning to produce as their children's expectations diverged from their parents'. Leah Rae married into the Reed family, contributing the line that this database's proband descends from. Ugo and Lena themselves eventually moved back east, to **Cicero, Illinois** — the suburb where their first child had been born — and Ugo died there at 78 on **20 February 1982** [2]; his Social Security record gives his last residence ZIP as 60650, the Cicero ZIP code, and his SSN as Iowa-issued, a small bureaucratic trace of the Bedford-to-Cicero arc [18]. He was buried three days later at Queen of Heaven Catholic Cemetery in Hillside, the great Archdiocese of Chicago cemetery consecrated in 1947, in plot **Section 40, Block 213, Lot 7, Grave 8** [3]. Lena outlived him by six years and joined him in 1988. Roland Mariotti, who would die in 2023, was buried in the same cemetery — the family plot the second generation made for the first, a single coordinate in Hillside that ties an Italian *contadino* boy born in 1903 in a marsh-reclaimed Tuscan hamlet to a Cook County suburb a century later.	\N	t	2026-05-30 09:53:51.446353-05
P-0072	2026-05-28	Abiram Stacy Lambert was born on 9 January 1831 in Salem, Washington County, Indiana — a small county-seat town built on land that had been Delaware Indian territory just thirteen years earlier, ceded under the Treaty of St. Mary's in 1818 and opened to white settlement as Indiana neared statehood [1] [2]. His father, David Lambert, was a Maine-born preacher-teacher-farmer and War of 1812 veteran who had drifted southwest through western New York into central Indiana by the late 1820s; his mother, Permelia Barnard, was thirty-three when Abiram was born. He came into the world in Andrew Jackson's second year, the year of Nat Turner's revolt in Virginia and of William Lloyd Garrison's first issue of *The Liberator*. By 1850 the household was settled in Clay Township, Howard County, Indiana, part of the great westward push of Yankee and Mid-Atlantic farmers that was reshaping the Old Northwest. On Christmas Day 1850 Abiram, not yet twenty, married sixteen-year-old Louisa Leach in neighboring Delaware County [10].\n\nThe Lamberts were a restless clan. In the fall of 1853 David Lambert led five Lambert households out of Howard County and across the Mississippi onto a military land warrant in Benton County, Iowa, joining a tide of Indiana and Ohio farmers who would, within a single decade, turn Iowa from frontier into the breadbasket of the Union [7]. Abiram and Louisa appear in the 1854 and 1856 Iowa state censuses in Canton Township with one child [8]. The Kansas-Nebraska Act of 1854 was tearing the nation apart as they settled in, and the Iowa they joined was a free state on the border of bleeding Kansas. By 1860 the young family had moved south again, to Franklin Township in Grundy County, Missouri — but they would not stay long.\n\nWhen the war came in 1861, Abiram enlisted at Corydon, Iowa in Company L of the 3rd Iowa Cavalry — "Naughton's Irish Dragoons," organized at Jefferson City, Missouri on 1 November [4]. The 3rd Iowa fought across the entire western theater. They were at Pea Ridge in March 1862, the engagement that secured Missouri for the Union; in the trenches at Vicksburg in the summer of 1863, Grant's masterstroke that split the Confederacy along the Mississippi; in the brutal cavalry actions at Brice's Crossroads and Tupelo in 1864 against Nathan Bedford Forrest; in Westport that fall, throwing back Sterling Price's last invasion of Missouri; and on Grierson's Raid into the Mississippi heartland over the winter. In the spring of 1865 the regiment rode with James H. Wilson on the largest cavalry operation ever mounted on the North American continent — thirteen thousand mounted men sweeping through Alabama and Georgia in the war's final weeks. Company L is specifically noted in the action at Maplesville, Alabama on 1 April 1865, the day before Selma fell [5]. The regiment was still in the field when news of Lee's surrender at Appomattox reached them. Of the 2,165 men who served in the 3rd Iowa Cavalry, 318 did not come home — eighty-four killed in combat, 234 dead of disease, the standard arithmetic of Civil War service. Abiram did. He mustered out at Atlanta on 9 August 1865 [6].\n\nHe came home to a country remade. The three decades that followed were the Gilded Age — railroad consolidation, the closing of the frontier, and the long agricultural depression that radicalized Midwestern farmers into the Granger and Populist movements. Abiram and Louisa settled in Guthrie County, Iowa, farming Union Township by 1870 and Seely Township by 1880; they would have been among the Iowa farmers reading William Jennings Bryan a decade later. Louisa appears to have died around 1880, at about forty-five [10]. In October 1881, at fifty, Abiram married Helen Amelia Boles — a widow whose first husband had been a Foote — in Guthrie County, and on 30 October 1882 their daughter Estelle Gertrude was born. In January 1907, with the Panic of that year tightening Iowa banks, Abiram filed for his Civil War pension. He was seventy-six and still farming.\n\nSometime between 1915 and 1920, in his mid-eighties, the old cavalryman made one last move. South-central Idaho — the Magic Valley — had been opened to irrigated farming by the 1894 Carey Act and the 1905 Milner Dam, and Iowa farmers were pouring west to claim newly-watered desert at a few dollars an acre. Twin Falls County had been carved out of sagebrush as recently as 1907 [15]. Abiram and Helen settled at Falls City, a small voting precinct in what was then still Lincoln County (it passed to Jerome County when Jerome was carved off in February 1919), about ten miles north of Twin Falls city across the Snake River canyon. The locality is defunct today; its post office had run only from 1909 to 1916 [3] [12]. Abiram died there on 28 April 1927, ninety-six years old, in the spring of Calvin Coolidge's prosperity — the year Charles Lindbergh would cross the Atlantic, Babe Ruth would hit sixty home runs, and the last veterans of the Civil War were vanishing fast. He was buried two days later in Twin Falls Cemetery [13]. Helen, who had married him forty-six years earlier as a widow, would marry once more — to a man named Knapp — and return at last to Iowa, where she lies in Violet Hill Cemetery in Perry, Dallas County, as Helen Amelia Knapp [11].	\N	t	2026-05-30 09:53:51.446353-05
\.


--
-- Data for Name: person; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.person (person_id, primary_name, sex, birth_date, birth_granularity, birth_place_id, death_date, death_granularity, death_place_id, life_confidence, privacy_level, branch, fs_id, notes, profile_media_id, source_summary, created_at, updated_at) FROM stdin;
P-0004	Elizabeth (Willey) Reed	female	circa 1846	\N	\N	1880-12-20	\N	PL-0002	med	public	Paternal Reed by marriage	\N	Married John T. Reed in Noble County, Ohio; moved to Iowa by 1870.	\N	Report	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0002	Rebecca (Talley) Reed	female	circa 1822	\N	PL-0074	1911	\N	PL-0002	med	public	Paternal Reed	\N	Daughter of John Foulk Talley and Hannah Poulson; migrated to Iowa; buried in Monteith.	\N	Report; Find a Grave	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0036	Estelle Gertrude Lambert	female	1882-10-30	\N	PL-0038	1946-05-20	\N	PL-0016	high	public	Maternal Lambert	LMWG-K6F	Daughter of Abiram S. Lambert and Helen Amelia Boles; later wife of John Foulk Reed.\n[deep-dive 2026-05-28] [deep-dive 2026-05-28 PM] FS PID LMWG-K6F confirmed; previously only on duplicate stub P-0063. All 19 FS attached sources inspected via authenticated Chrome MCP. THREE marriages confirmed: (1) John Foulk Reed m. 1899-03-05 Guthrie Co IA — four children (Earl Wayne 1899, Harold Merle 1901, Oscar G. 1903, Edna Gertrude 1906); (2) Clarence D. Eichinger m. 1912-09-18 Algona, Kossuth Co IA — one child (Ray ~1914); (3) Harry Sinderson by 1946 — died as 'Estelle G Sinderson' in Chicago, divorced, waitress, address 1339 S 48 St. Cook Co IL death cert (Q2M8-FDWY) confirms burial at Prairie Home Cemetery, Waukesha WI — GPKG E-0057 is correct (the AM dossier's Prairie-Twp-Delaware-Co patch was withdrawn). 1900 census Valley Twp Guthrie Center IA; 1920 census Sioux Falls SD; 1925 IA State Census Waterloo IA. Mother Helen had remarried as 'Helen Amelia Knapp' by the 1895 IA State Census — long before Abiram's 1927 death — so Estelle was raised partly by her Knapp stepfather Leslie from at least age 12.	\N	Report FSID:LMWG-K6F; FamilySearch attached records (19 of 19 inspected via authenticated Chrome MCP, 2026-05-28): Iowa Co Births 1880-1935 XVFQ-S6T (birth); IA State Census 1885 HZXM-SN2 (childhood household); IA State Census 1895 VT33-RWL (mother as Knapp); Iowa Co Marriages KLWR-25L + XJZB-48K + Iowa Marriages XJLP-MXL (1899 first marriage); Iowa Co Births XVN1-39X (Earl Wayne); Delayed Births Q246-SDPC (Harold Merle), XVZ5-VVH+XV2Y-VDM (Oscar G.), Q24X-4Z14 (Edna); 1900 US Census M9KG-C8W; Iowa Co Marriages XJ8W-XZ2 + XJPF-H6J (1912 Eichinger marriage); 1920 US Census M6JH-P4L; 1925 IA State Census QKQW-X88X; Cook Co IL Death Cert Q2M8-FDWY + IL Deaths N3Y4-J4F (1946 Sinderson death); Cook Co IL Death Cert Q2MN-CMG6 (Earl Wayne Reed 1974, names Estelle as mother). Plus Wikipedia/Monteith Iowa (Harmon T. Reed founding 1881).	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0068	Beatrice Delina Pouliot	female	1878-04-14	\N	PL-0158	1964-08-01	\N	PL-0031	high	public	Pouliot	LBHY-3B5	French-Canadian descent; married John F. Zika.	\N	FamilySearch (FS PID: LBHY-3B5)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0001	Bonum Reed	male	1816-06-03	\N	PL-0070	1893-12-13	\N	PL-0032	high	public	Paternal Reed	\N	Farmer; moved from Ohio to Iowa by 1870; buried at Monteith Cemetery.	\N	Report; RootsWeb; Find a Grave FSID:27XF-VBH	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0072	Abiram Stacy Lambert	male	1831-01-09	\N	PL-0367	1927-04-28	\N	PL-0059	high	public	Maternal Lambert	2WFL-ZVT	Civil War veteran (Co. L, 3rd Iowa Cavalry); farmer in Guthrie County, Iowa.\n[deep-dive 2026-05-28] Parents confirmed: David Lambert (1789-1866, b. Canaan ME, bur. McBroom Cem, Vinton, Benton Co IA) and Permelia Barnard (1798-1865) — multi-source (WikiTree + FindAGrave #10569107 + Benton Co Pioneers). Family migrated Howard Co IN → Benton Co IA fall 1853. Service detail: Co. L, 3rd Iowa Cavalry was at Maplesville AL on 1 Apr 1865 during Wilson's Raid. Death locality 'Falls City' was a Lincoln-then-Jerome Co Idaho voting precinct (PO 1909-1916), ~10 mi N of Twin Falls city across the Snake River canyon; defunct today.	\N	FamilySearch (FS PID: 2WFL-ZVT); WikiTree Lambert-3978 (parents); FindAGrave #10569107 (mother); BillionGraves David Lambert (father); Logan's Roster of Iowa Soldiers / iagenweb (3rd IA Cav); NPS Battle Unit Details UIA0003RC; HomeTownLocator (Falls City ID); Benton County Pioneers / iagenweb (1854/56 residence)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0012	Helen Amelia (Boles) Lambert	female	circa 1849	\N	PL-0066	1939-01-23	\N	PL-0067	med	public	Maternal Lambert	\N	Daughter of Silas P. Boles and Martha L. Spear; second wife of Abiram S. Lambert.\n[deep-dive 2026-05-28] [deep-dive 2026-05-28 via P-0036] Death date refined to 1939-01-23 per FS PID 29WD-T9P; previously stored as year-only '1938'. Burial: Violet Hill Cemetery, Perry, Dallas Co IA, with stone inscribed as 'Helen Amelia Knapp' (FindAGrave #16177390). PM correction: Helen had already been Mrs. Knapp by the 1895 IA State Census — the Knapp remarriage was a 1880s/early-1890s event after she separated from Abiram, not a post-1927 remarriage. She lived for decades as Mrs. Knapp with Leslie Knapp; her grave reflects that surname.	\N	Report; FindAGrave #16177390 (Helen Amelia Knapp); FS Iowa State Census 1885 HZXM-SN2; FS Iowa State Census 1895 (mother surname as Knapp); FS PID 29WD-T9P	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0046	Hannah Paulson	female	1793-08-11	\N	PL-0098	1857-09-30	\N	PL-0080	high	public	Paternal Reed	2MRH-9JF	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0052	Elizabeth Allen	female	1794-07-05	\N	PL-0096	1872-04-12	\N	PL-0082	med	public	Paternal Reed	2S2L-ZYQ	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0051	Benjamin Thorla	male	1790-09-14	\N	PL-0099	1861-07-05	\N	PL-0082	med	public	Paternal Reed	KLYD-X1Q	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0038	James Willey	male	1818-03-10	\N	PL-0085	1896-07-10	\N	PL-0082	high	public	Paternal Reed	LCTG-MNQ	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0042	Stephen Reed	male	1760	\N	PL-0088	1814-04	\N	PL-0083	med	public	Paternal Reed	LC5Y-HJ1	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0047	Samuel R Barnard	male	1749-03-09	\N	PL-0108	1815-08-08	\N	PL-0084	med	public	Paternal Reed	LHFS-KPJ	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0044	Else Alice Bonham	female	1762	\N	PL-0090	1819	\N	PL-0087	low	public	Paternal Reed	LCJK-F8G	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0129	Absalom Willey	male	6 May 1739	\N	PL-2536	19 December 1791	\N	PL-0097	high	public	Paternal Reed	LTCY-1RM	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: LTCY-1RM)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0043	Mary Polly Cook	female	1735-08-08	\N	PL-0089	1800-04-04	\N	PL-0100	med	public	Paternal Reed	LZVP-5FW	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0039	Emily Thorla	female	1819-05-15	\N	PL-0085	1910-10-08	\N	PL-0101	high	public	Paternal Reed	LCTG-MKP	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0050	Sarah Dye	female	1789-05-27	\N	PL-0085	1840-08-16	\N	PL-0105	med	public	Paternal Reed	278F-M4D	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0049	William Polk Willey	male	1788-01-06	\N	PL-0097	1860-04-06	\N	PL-0105	med	public	Paternal Reed	LHW8-G58	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0142	Deacon Francis Barnard	male	9 September 1719	\N	PL-3186	22 February 1789	\N	PL-0109	high	public	Paternal Reed	LCB7-QL6	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: LCB7-QL6)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0048	Roxana Desire Barnard	female	1756-07-21	\N	PL-0114	1830-09-09	\N	PL-0109	med	public	Paternal Reed	L5ZT-BM5	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0041	Sarah Dickerson	female	1794-10-11	\N	PL-0113	1858-01-24	\N	PL-0110	low	public	Paternal Reed	991N-J11	Matriarch of Reed line in Ohio.	\N	Report	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0040	Benjamin Reed	male	1789-12-24	\N	PL-0090	1872-05-04	\N	PL-0111	high	public	Paternal Reed	LZDK-YP8	Pioneer farmer; moved from Pennsylvania to Ohio; husband of Sarah Dickerson.	\N	Report	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0045	John Foulk Talley	male	1799-10-26	\N	PL-0081	1886-11-04	\N	PL-0112	high	public	Paternal Reed	L7NJ-1S1	\N	\N	\N	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0078	Paul Pouliot	male	1834-03-24	\N	PL-0506	1903-05-10	\N	PL-0158	high	public	Pouliot	96JW-KX5	French-Canadian immigrant; father of Delina.	\N	FamilySearch (FS PID: 96JW-KX5)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0076	Henriette St. Louis	female	1840-03-01	\N	PL-0049	22 January 1890	\N	PL-0158	high	public	Pouliot	MGNK-YL2	Wife of Paul Pouliot; French-Canadian.	\N	FamilySearch (FS PID: MGNK-YL2)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0075	Anton Zika	male	22 July 1848	\N	PL-0233	22 December 1924	\N	PL-0158	high	public	Zika	LKTC-D4S	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: LKTC-D4S)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0064	John Francis Zika	male	1875-10-10	\N	PL-0233	1957-06-09	\N	PL-0158	high	public	Zika	L2XV-HRY	Boilermaker in Chicago; Czech-American community.	\N	FamilySearch (FS PID: L2XV-HRY)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0055	Leah Rae Mariotti	female	1936-09-08	\N	PL-0158	2025-07-21	\N	PL-0159	high	public	Maternal Mariotti	L274-KT7	NULL	\N	FamilySearch (FS PID: L274-KT7)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0056	John Ronald Reed Sr	male	1934-07-18	\N	PL-0158	1995-05-02	\N	PL-0163	high	public	Paternal Reed	LY94-373	Child of Earl & Isabelle (age 5 in 1940 census).\n[deep-dive 2026-05-30] Married Leah Rae Mariotti in 1956; first home Westchester, IL, then Glen Ellyn from ~1964. Seven children (two sets of twins). Roman Catholic — family parish St. James the Apostle, Glen Ellyn. Two brothers: Earl Wayne 'Wayne' Reed Jr (1930-12-09 – 2024-07-20) and James 'Jim' Reed (b. ~1940). Parents divorced 1940–1950; mother Isabelle headed the Cicero household (biller, telephone factory). E-0025 (1949-02) = his SS-5 application. Served in the U.S. military during the Korean War (family testimony) — recalled training at Camp Pendleton (USMC), branch/dates unconfirmed. Maternal grandfather of proband John Kenny (L274-KNT) via daughter Karen (Reed) Kenny. Likely buried with Leah at Queen of Heaven Catholic Cemetery, Hillside (no FindAGrave memorial yet).	\N	FamilySearch (FS PID: LY94-373); 1934 Cook County birth certificate; 1940 & 1950 US Censuses (Cicero); SSDI (d. 1995-05-02, Glen Ellyn 60137); SS NUMIDENT (parents Earl W. Reed & Isabelle Zika, SSN applied Feb 1949); brother Earl W. Reed Jr's 2024 obituary; Leah R. Reed's 2025 obituary (Williams-Kampp — marriage 1956, 7 children, St. James parish, Queen of Heaven burial); FindAGrave (Leah memorial #285158675). Deep-dive 2026-05-30.	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0058	Isabelle Harriet Zika	female	3 December 1913	\N	PL-0158	13 October 2006	\N	PL-0172	high	public	Zika	LY94-DBH	Daughter of John F. Zika & Delina Pouliot; Chicago area.	\N	FamilySearch (FS PID: LY94-DBH)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0164	UMILTA' GIACOMELLI	female	1763	\N	PL-2171	29 December 1823	\N	PL-0178	high	public	Maternal Mariotti	GBFH-HZV	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GBFH-HZV)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0163	PIER DOMENICO NICCOLAI	male	12 March 1761	\N	PL-2171	23 December 1846	\N	PL-0178	high	public	Maternal Mariotti	GBF4-TKM	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GBF4-TKM)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0066	Zelinda Pagni	female	6 September 1874	\N	PL-0262	9 November 1936	\N	PL-0179	high	public	Maternal Mariotti	GCKQ-6RJ	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GCKQ-6RJ)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0059	Ugo Mariotti	male	21 July 1903	\N	PL-0178	20 February 1982	\N	PL-0179	high	public	Maternal Mariotti	PWPQ-D8V	Imported from FamilySearch extract on 2026-05-26.\n[deep-dive 2026-05-28] [deep-dive 2026-05-28 (2nd pass, FS-attached sources inspected)] PARENTS CONFIRMED via 1927 IA marriage: father Leopoldo Mariotti (P-0067), mother **Quintilia Lenzi (P-0069)** — NOT Zelinda Pagni (P-0066). SPOUSE CONFIRMED: Lena A Dini (P-0060), m. 5 May 1927 Lenox, Taylor Co, IA. CHILDREN per FS/census/obit: Rolando 'Roland' Mariotti (b. 17 Jun 1929 Cicero IL, d. 2023), Leah Rae Mariotti (P-0055; b. 8 Sep 1936 Chicago — see name-conflict note below), Celiste Dee 'Celeste' Mariotti (b. ~1944 IL, living). RESIDENCE: family lived in Bedford, Taylor County, Iowa ~1928–~1950; Ugo was proprietor of a Candy Kitchen there (1950 census). Late-life move to Cicero IL (ZIP 60650) before 1982 death. BURIAL: Queen of Heaven Catholic Cemetery, Hillside IL, Section 40/Block 213/Lot 7/Grave 8 (FindAGrave #288488976). NAMING CONFLICT: 8 Sep 1936 Cook Co birth cert #32174 is indexed by FS twice — once as 'UNKNOWN daughter' and once as 'Sarah Joy Mariotti' — same date and cert#. Likely the same record indexed before vs. after a name was supplied to the registrar. Whether Leah Rae's original given name was 'Sarah Joy' (later changed) needs verification against the scanned certificate.	\N	FamilySearch (FS PID: PWPQ-D8V); Iowa County Marriages 1838-1934 (FS XJX4-VDB); IL Northern District Naturalization Index 1840-1950 (FS XKGJ-M1P); IL Cook Co Birth Cert #228 [Roland] (FS QVSH-PG84); IL Cook Co Birth Cert #32174 [Leah/'Sarah Joy'] (FS QGCF-8JT5, QGCF-M3H7); 1930 US Census (FS XMKQ-K9T); 1940 US Census (FS KMBB-TY1); 1950 US Census (FS 6FQW-JRYD); IA WWII Draft 16 Feb 1942 (FS QG2P-J7N1); SSDI (FS JLLR-Z6F); IL Archdiocese Cemetery Records (FS Q2HF-8P34); FindAGrave #288488976; Roland W. Mariotti obituary (Shirley & Stout, 2023)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0060	Lena  A Dini	female	16 June 1909	\N	PL-0179	6 June 1988	\N	PL-0187	high	public	Maternal Mariotti	L278-SXK	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: L278-SXK)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0083	Rebecca Talley	female	7 November 1822	\N	PL-0638	16 July 1911	\N	PL-0196	high	public	Paternal Reed	L7J3-GVG	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: L7J3-GVG)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0082	Bonam Reed	male	3 June 1816	\N	PL-0610	13 December 1893	\N	PL-0196	high	public	Paternal Reed	27XF-VBH	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: 27XF-VBH)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0061	John Foulk Reed	male	1877-11-25	\N	PL-0196	1952-03-30	\N	PL-0197	high	public	Paternal Reed	KLGC-TLC	Son of John T. Reed and Elizabeth Willey; later father of Earl Wayne Reed.\n[deep-dive 2026-05-28] [deep-dive 2026-05-28 via P-0036] Burial confirmed at Oakdale Memorial Gardens, Davenport, Scott Co IA per FS PID KLGC-TLC. FS sourceCount=31.	\N	FamilySearch (FS PID: KLGC-TLC); FamilySearch extract 2026-05-26 (PID KLGC-TLC); see also reports/deep-dives/P-0036.md	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0074	Helen Amelia Boles	female	10 June 1849	\N	PL-0413	23 January 1939	\N	PL-0208	high	public	Maternal Lambert	29WD-T9P	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: 29WD-T9P)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0071	Elizabeth Willey	female	26 June 1846	\N	PL-0347	21 December 1880	\N	PL-0208	high	public	Paternal Reed	KJP4-9R4	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: KJP4-9R4)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0088	Marie Anna Říhová	female	21 March 1820	\N	PL-0233	18 October 1871	\N	PL-0233	high	public	Zika	GWCT-VWD	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GWCT-VWD)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0087	František Zíka	male	27 April 1801	\N	PL-0233	3 July 1872	\N	PL-0233	high	public	Zika	GWCT-J3K	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GWCT-J3K)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0069	Quintilia Lenzi	female	23 November 1876	\N	PL-0247	9 September 1960	\N	PL-0247	high	public	Maternal Mariotti	PWP7-JQ8	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: PWP7-JQ8)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0067	Leopoldo Mariotti	male	29 October 1871	\N	PL-0278	3 March 1933	\N	PL-0247	high	public	Maternal Mariotti	PWPW-LPC	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: PWPW-LPC)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0070	John Talley Reed	male	1841-06-26	\N	PL-0327	1903-11-11	\N	PL-0328	high	public	Paternal Reed	L487-WDC	Farmer in Valley Township; married Elizabeth Willey (1861) then Mary E. Headlee (~1881).	\N	FamilySearch (FS PID: L487-WDC)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
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
P-0091	Francois Pouliot	male	20 May 1805	\N	PL-0506	13 June 1858	\N	PL-0506	high	public	Pouliot	KCTF-J6N	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: KCTF-J6N)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0079	Angiolo Pagni	male	1847	\N	PL-0262	3 January 1925	\N	PL-0531	high	public	Maternal Mariotti	P7P4-4TS	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: P7P4-4TS)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0080	Maria Emilia Dini	female	8 June 1843	\N	PL-0390	26 November 1913	\N	PL-0557	high	public	Maternal Mariotti	P99J-6YC	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: P99J-6YC)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0131	Deliverance Owen	female	13 August 1754	\N	PL-2653	1821	\N	PL-0638	high	public	\N	2CND-ZJ7	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: 2CND-ZJ7)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0144	Jonathan Abel Oakes	male	21 August 1717	\N	PL-3553	2 December 1784	\N	PL-0667	high	public	Maternal Lambert	LZP7-DSJ	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: LZP7-DSJ)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0138	Sherebiah Lambert Sr.	male	28 March 1728	\N	PL-3115	1 May 1833	\N	PL-0667	high	public	Maternal Lambert	L7NQ-CKX	Patriot era; married Lydia (Hopkins?).	\N	FamilySearch (FS PID: L7NQ-CKX)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
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
P-0133	John Thomas Thurlow Jr	male	26 September 1745	\N	PL-2776	22 September 1835	\N	PL-2777	high	public	\N	24C5-JCJ	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: 24C5-JCJ)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
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
P-0093	Joseph Filiatrault dit St. Louis	male	\N	\N	\N	\N	\N	\N	med	public	Pouliot	GYV7-TRD	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GYV7-TRD)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0090	František Říha	male	before 1840	\N	PL-0233	before 1960	\N	\N	med	public	Zika	GS6J-92Z	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GS6J-92Z)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0089	Františka Klusová	female	before 1840	\N	PL-0233	before 1950	\N	\N	med	public	Zika	GWCT-JQN	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GWCT-JQN)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0081	Cherubina Giorgi	female	2 July 1844	\N	PL-0262	\N	\N	\N	high	public	Maternal Mariotti	P3YM-9YQ	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: P3YM-9YQ)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0077	Josephine Riha Veta	female	22 April 1854	\N	PL-0233	before 1964	\N	\N	high	public	Zika	LBH1-TK2	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: LBH1-TK2)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0073	Celestino Dini	male	23 September 1845	\N	PL-0390	\N	\N	\N	high	public	Maternal Mariotti	GSQJ-M1C	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GSQJ-M1C)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0065	Louis Dini	male	1873	\N	PL-0247	\N	\N	\N	high	public	Maternal Mariotti	GCKQ-RK3	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: GCKQ-RK3)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0057	Laura Kroll	female	\N	\N	\N	\N	\N	\N	med	public	Paternal Kroll	L24Z-SFM	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: L24Z-SFM)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0054	Phyllis Kroll	female	1931	\N	\N	May 2020	\N	\N	med	public	Paternal Kroll	L274-KGR	Imported from FamilySearch extract on 2026-05-26.	\N	FamilySearch (FS PID: L274-KGR)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0062	Earl Wayne Reed Sr	male	1899-07-19	\N	PL-0208	1974-04-11	\N	\N	high	public	Paternal Reed	M3P5-XF6	Married Isabelle Zika; lived in Chicago; possible WWI/WWII service.	\N	FamilySearch (FS PID: M3P5-XF6)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0033	James G. Reed	male	circa 1939	\N	PL-0010	NULL	\N	\N	med	public	Reed-Zika	\N	Child of Earl & Isabelle (6/12 in 1940 census).	\N	Report / 1940 census	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0031	Earl Wayne Reed Jr.	male	1930	\N	PL-0010	2024	\N	\N	med	public	Reed-Zika	\N	Child of Earl & Isabelle (per obituary).	\N	Report / Obituary	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0028	Henriette (Cheffre) Filiatrault	female	circa 1821	\N	\N	NULL	\N	\N	med	public	Pouliot	\N	Wife of Joseph Filiatrault dit St. Louis.	\N	Report	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0027	Joseph Filiatrault dit St. Louis	male	circa 1820	\N	\N	NULL	\N	\N	med	public	Pouliot	\N	Father of Henriette (Filiatrault) Pouliot; Quebec farmer.	\N	Report	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0025	François Pouliot	male	1805-05-20	\N	\N	1858-06-13	\N	\N	med	public	Pouliot	\N	Farmer at Île d’Orléans; father of Paul.	\N	Report	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0020	Josefína “Josie” (Říha) Zika	female	1853	\N	PL-0012	1930	\N	\N	med	public	Zika	\N	Wife of Anton; Czech immigrant.	\N	Report	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0019	Anton Zika	male	1859-06-13	\N	PL-0012	1948	\N	\N	med	public	Zika	\N	Czech immigrant; husband of Josefína (Říha) Zika.	\N	Report	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0018	Permelia M. Oak	female	1788	\N	\N	1845	\N	\N	med	public	Maternal Lambert	\N	Second wife of Sherebiah Jr.	\N	Report	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0016	Lydia A. (Hopkins) Lambert	female	1738	\N	\N	1806	\N	\N	med	public	Maternal Lambert	\N	Wife of Sherebiah Sr.; maiden name uncertain.	\N	Report	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0013	Silas P. Boles	male	1818	\N	\N	1900	\N	\N	med	public	Maternal Lambert	\N	Husband of Martha L. Spear.	\N	Report	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0010	Permelia (Barnard) Lambert	female	circa 1798	\N	\N	1865	\N	\N	med	public	Maternal Lambert	\N	Wife of David Lambert.	\N	Report	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
P-0035	Emma Rebecca Reed	female	1873	\N	\N	circa 1905	\N	\N	med	public	Paternal Reed	\N	Daughter of John T. Reed and Elizabeth Willey.	\N	Report / FamilySearch	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
\.


--
-- Data for Name: person_name; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.person_name (id, person_id, name_type, value, is_primary, notes, created_at) FROM stdin;
1	P-0004	primary	Elizabeth (Willey) Reed	t	\N	2026-05-30 09:42:59.684442-05
2	P-0002	primary	Rebecca (Talley) Reed	t	\N	2026-05-30 09:42:59.684442-05
3	P-0036	primary	Estelle Gertrude Lambert	t	\N	2026-05-30 09:42:59.684442-05
4	P-0068	primary	Beatrice Delina Pouliot	t	\N	2026-05-30 09:42:59.684442-05
5	P-0001	primary	Bonum Reed	t	\N	2026-05-30 09:42:59.684442-05
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
137	P-0027	primary	Joseph Filiatrault dit St. Louis	t	\N	2026-05-30 09:42:59.684442-05
138	P-0025	primary	François Pouliot	t	\N	2026-05-30 09:42:59.684442-05
139	P-0020	primary	Josefína “Josie” (Říha) Zika	t	\N	2026-05-30 09:42:59.684442-05
140	P-0019	primary	Anton Zika	t	\N	2026-05-30 09:42:59.684442-05
141	P-0018	primary	Permelia M. Oak	t	\N	2026-05-30 09:42:59.684442-05
142	P-0016	primary	Lydia A. (Hopkins) Lambert	t	\N	2026-05-30 09:42:59.684442-05
143	P-0013	primary	Silas P. Boles	t	\N	2026-05-30 09:42:59.684442-05
144	P-0010	primary	Permelia (Barnard) Lambert	t	\N	2026-05-30 09:42:59.684442-05
145	P-0035	primary	Emma Rebecca Reed	t	\N	2026-05-30 09:42:59.684442-05
\.


--
-- Data for Name: place; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.place (place_id, name, std_name, geom, admin_hierarchy, geocode_quality, created_at, updated_at, historical_name, notes, time_valid_from, time_valid_to) FROM stdin;
PL-0072	Ohio, USA	\N	0101000020E6100000E78C28ED0DBA54C0764F1E166A354440	\N	settlement	2026-05-30 09:21:56.321112-05	2026-05-30 09:46:30.204248-05	\N	\N	\N	\N
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
R-0001	P-0001	spouse	P-0002	1837-11-23	NULL	Marriage in Morgan County, Ohio	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0002	P-0070	spouse	P-0004	1861-09-19	1880-12-20	Marriage in Noble County, Ohio; Elizabeth died 1880	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0003	P-0072	spouse	P-0012	1881-10	NULL	Second marriage (month recorded)	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0005	P-0064	spouse	P-0068	circa 1899	NULL	Married in/near Chicago	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0006	P-0062	spouse	P-0058	circa 1929	NULL	Married in/near Chicago	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0101	P-0040	parent	P-0001	NULL	NULL	Benjamin is father of Bonum	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0102	P-0041	parent	P-0001	NULL	NULL	Sarah is mother of Bonum	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0103	P-0001	parent	P-0070	NULL	NULL	Bonum is father of John Talley Reed	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
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
R-0119	P-0025	parent	P-0078	NULL	NULL	François is father of Paul	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0120	P-0094	parent	P-0078	NULL	NULL	Julie is mother of Paul	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
R-0121	P-0027	parent	P-0076	NULL	NULL	Joseph is father of Henriette	2026-05-30 09:21:56.321112-05	2026-05-30 09:21:56.321112-05
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
\.


--
-- Data for Name: research_lead; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.research_lead (id, person_id, category, description, status, source_dossier, created_at, updated_at) FROM stdin;
90	P-0036	record	Cook County, IL death certificate full image (entry 15350) — should give cause of death and informant. The FS index page has the structured fields but no image attached on the public side.	open	P-0036	2026-05-30 09:53:51.446353-05	2026-05-30 09:53:51.446353-05
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
\.


--
-- Data for Name: source; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.source (source_id, source_type, title, informant, repository, url, citation, source_date, accessed_date, confidence, notes, created_at, updated_at) FROM stdin;
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
\.


--
-- Name: citation_citation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.citation_citation_id_seq', 156, true);


--
-- Name: event_participant_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.event_participant_id_seq', 221, true);


--
-- Name: media_link_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.media_link_id_seq', 1, true);


--
-- Name: person_name_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.person_name_id_seq', 145, true);


--
-- Name: research_lead_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.research_lead_id_seq', 168, true);


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

\unrestrict KntsdULVjzjXiXIBSxJJ5NaG4szrMXHe9Xffg1td2LDtBOB3XR5AxVRKfZp7u36

