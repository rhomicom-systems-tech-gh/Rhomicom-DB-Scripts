CREATE SCHEMA ccs AUTHORIZATION postgres;
COMMENT ON SCHEMA ccs IS 'Catholic Church Sacrament';

CREATE TABLE ccs.baptism
(
    bptsm_id bigserial,
    title character varying(15),
    last_name character varying(50),
    middle_names character varying(100),
    first_name character varying(100),
    father_full_name character varying(150),
    mother_full_name character varying(150),
    pob character varying(50),
    dob character varying(10),
    date_of_baptism character varying(10),
    place_of_baptism character varying(50),
    minister_full_name character varying(150),
    mode character varying(50),
    godparent_full_name character varying(150),
    father_religion character varying(30),
    mother_religion character varying(30),
    gender character varying(10),
    org_id bigint,
	created_by bigint,
    creation_date character varying(21),
    last_update_by bigint,
    last_update_date character varying(21),
	status character varying(15)
);

ALTER TABLE ccs.baptism
    OWNER to postgres;

ALTER TABLE ccs.baptism
    ADD CONSTRAINT pk_bptsm_id PRIMARY KEY (bptsm_id);
	
CREATE TABLE ccs.first_communion
(
    frst_communion_id bigserial,
    bptsm_id bigint,
    minister_full_name character varying(150),
    communion_date character varying(21),
    place_of_first_communion character varying(100),
    created_by bigint,
    creation_date character varying(21),
    last_update_by bigint,
    last_update_date character varying(21),
    CONSTRAINT pk_first_communion_id PRIMARY KEY (frst_communion_id)
);

ALTER TABLE ccs.first_communion
    OWNER to postgres;
	

CREATE TABLE ccs.confirmation
(
    cnfrmtn_id bigserial,
    bptsm_id bigint,
    confirmation_name character varying(50),
    godparent_full_name character varying(150),
    confirmation_minister character varying(150),
    place_of_confirmation character varying(50),
    date_of_confirmation character varying(10),
    created_by bigint,
    creation_date character varying,
    last_update_by bigint,
    last_update_date character varying,
    CONSTRAINT pk_cnfrmtn_id PRIMARY KEY (cnfrmtn_id)
);

ALTER TABLE ccs.confirmation
    OWNER to postgres;

CREATE TABLE ccs.holy_matrimony
(
    matrimony_id bigserial,
    bptsm_id bigint,
    spouse_first_name character varying(100),
    spouse_surname character varying(50),
    spouse_dob character varying(10),
    spouse_pob character varying(100),
    father_of_spouse character varying(150),
    mother_of_spouse character varying(150),
    bptsm_id_spouse bigint DEFAULT -1,
    spouse_baptism_date character varying(10),
    spouse_baptism_place character varying(100),
    created_by bigint,
    creation_date character varying(21),
    last_update_by bigint,
    last_update_date character varying(21),
    CONSTRAINT pk_matrimony_id PRIMARY KEY (matrimony_id)
);

ALTER TABLE ccs.holy_matrimony
    OWNER to postgres;

ALTER TABLE ccs.holy_matrimony
ADD COLUMN matrimony_place CHARACTER VARYING(50),
ADD COLUMN matrimony_date CHARACTER VARYING(10),
ADD COLUMN minister CHARACTER VARYING(150),
ADD COLUMN church CHARACTER VARYING(50),
ADD COLUMN dispensation CHARACTER VARYING(50);

ALTER TABLE ccs.holy_matrimony
ADD COLUMN spouse_gender CHARACTER VARYING(6);

ALTER TABLE ccs.baptism
ADD COLUMN bptsm_sys_code CHARACTER VARYING(20);

-- Table: ccs.ccs_audit_trail_tbl

-- DROP TABLE ccs.ccs_audit_trail_tbl;

CREATE TABLE ccs.ccs_audit_trail_tbl
(
    user_id bigint NOT NULL,
    action_type character varying(30) COLLATE pg_catalog."default",
    action_details text COLLATE pg_catalog."default",
    action_time character varying(21) COLLATE pg_catalog."default",
    login_number bigint,
    dflt_row_id bigserial,
    CONSTRAINT pk_dflt_row_id PRIMARY KEY (dflt_row_id)
)

TABLESPACE pg_default;

ALTER TABLE ccs.ccs_audit_trail_tbl
    OWNER to postgres;
-- Index: idx_action_details

-- DROP INDEX aca.idx_action_details;

CREATE INDEX idx_action_details
    ON ccs.ccs_audit_trail_tbl USING btree
    (action_details COLLATE pg_catalog."default" ASC NULLS FIRST)
    TABLESPACE pg_default;
-- Index: idx_action_time

-- DROP INDEX aca.idx_action_time;

CREATE INDEX idx_action_time
    ON ccs.ccs_audit_trail_tbl USING btree
    (action_time COLLATE pg_catalog."default" ASC NULLS FIRST)
    TABLESPACE pg_default;
-- Index: idx_action_type

-- DROP INDEX aca.idx_action_type;

CREATE INDEX idx_action_type
    ON ccs.ccs_audit_trail_tbl USING btree
    (action_type COLLATE pg_catalog."default" ASC NULLS FIRST)
    TABLESPACE pg_default;
-- Index: idx_adt_dflt_row_id

-- DROP INDEX aca.idx_adt_dflt_row_id;

CREATE UNIQUE INDEX idx_adt_dflt_row_id
    ON ccs.ccs_audit_trail_tbl USING btree
    (dflt_row_id ASC NULLS FIRST)
    TABLESPACE pg_default;
-- Index: idx_login_number

-- DROP INDEX aca.idx_login_number;

CREATE INDEX idx_login_number
    ON ccs.ccs_audit_trail_tbl USING btree
    (login_number ASC NULLS FIRST)
    TABLESPACE pg_default;
-- Index: idx_user_id

-- DROP INDEX aca.idx_user_id;

CREATE INDEX idx_user_id
    ON ccs.ccs_audit_trail_tbl USING btree
    (user_id ASC NULLS FIRST)
    TABLESPACE pg_default;
	
CREATE TABLE ccs.matrimony_witness
(
    wtnss_id serial,
    matrimony_id bigint,
    witness_name character varying(150),
    witness_for character varying(5),
    created_by bigint,
    creation_date character varying(21),
    last_update_by bigint,
    last_update_date character varying(21),
    CONSTRAINT pk_wtnss_id PRIMARY KEY (wtnss_id)
);

ALTER TABLE ccs.matrimony_witness
    OWNER to postgres;	