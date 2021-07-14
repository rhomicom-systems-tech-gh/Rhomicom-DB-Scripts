-- Table: accb.accb_trans_to_reconcile
-- DROP TABLE accb.accb_trans_to_reconcile;
CREATE TABLE accb.accb_trans_to_reconcile (
	reconcile_line_id bigserial NOT NULL
	, bnk_trans_date character varying(21) COLLATE pg_catalog."default"
	, value_date character varying(21) COLLATE pg_catalog."default"
	, reconcile_desc character varying(300) COLLATE pg_catalog."default"
	, ref_doc_number character varying(200) COLLATE pg_catalog."default"
	, account_id integer
	, imprtd_rec_pos_cntr integer
	, import_hdr_runid bigint
	, reconcile_strt_date character varying(21) COLLATE pg_catalog."default"
	, reconcile_end_date character varying(21) COLLATE pg_catalog."default"
	, debit_amount numeric
	, credit_amount numeric
	, net_amount numeric
	, bals_afta_trans numeric
	, opng_dbt_amount numeric
	, opng_crdt_amount numeric
	, opng_net_amount numeric
	, clsng_dbt_amount numeric
	, clsng_crdt_amount numeric
	, clsng_net_amount numeric
	, is_reconciled character varying(1) COLLATE pg_catalog."default"
	, lnkd_sys_trans_id bigint
	, org_id integer
	, created_by bigint
	, creation_date character varying(21) COLLATE pg_catalog."default"
	, last_update_by bigint
	, last_update_date character varying(21) COLLATE pg_catalog."default"
	, CONSTRAINT pk_reconcile_line_id PRIMARY KEY (reconcile_line_id))
TABLESPACE pg_default;

-- Index: idx_import_hdr_runid
-- DROP INDEX accb.idx_import_hdr_runid;
CREATE INDEX idx_import_hdr_runid ON accb.accb_trans_to_reconcile USING btree (import_hdr_runid ASC NULLS FIRST) TABLESPACE pg_default;

-- Index: idx_imprtd_rec_pos_cntr
-- DROP INDEX accb.idx_imprtd_rec_pos_cntr;
CREATE INDEX idx_imprtd_rec_pos_cntr ON accb.accb_trans_to_reconcile USING btree (imprtd_rec_pos_cntr ASC NULLS FIRST) TABLESPACE pg_default;

-- Index: idx_rcl_account_id
-- DROP INDEX accb.idx_rcl_account_id;
CREATE INDEX idx_rcl_account_id ON accb.accb_trans_to_reconcile USING btree (account_id ASC NULLS FIRST) TABLESPACE pg_default;

-- Index: idx_reconcile_end_date
-- DROP INDEX accb.idx_reconcile_end_date;
CREATE INDEX idx_reconcile_end_date ON accb.accb_trans_to_reconcile USING btree (reconcile_end_date COLLATE pg_catalog."default" ASC NULLS FIRST) TABLESPACE pg_default;

-- Index: idx_reconcile_strt_date
-- DROP INDEX accb.idx_reconcile_strt_date;
CREATE INDEX idx_reconcile_strt_date ON accb.accb_trans_to_reconcile USING btree (reconcile_strt_date COLLATE pg_catalog."default" ASC NULLS FIRST) TABLESPACE pg_default;

