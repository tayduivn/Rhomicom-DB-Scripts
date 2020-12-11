--DROP SCHEMA hosp CASCADE;
--CREATE OR REPLACE FUNCTION
--CREATE FUNCTION
ALTER TABLE accb.accb_fa_assets_rgstr
    ADD COLUMN rvnu_accnt_id integer NOT NULL DEFAULT -1;

ALTER TABLE accb.accb_fa_assets_rgstr
    ADD COLUMN mntnc_exp_accnt_id integer NOT NULL DEFAULT -1;
	
ALTER TABLE scm.scm_cnsmr_credit_analys ADD branch_loc_id integer NOT NULL DEFAULT -1;
ALTER TABLE scm.scm_cnsmr_credit_analys ADD dflt_rcvbl_account_id integer NOT NULL DEFAULT -1;

ALTER TABLE aca.aca_classes
	ADD COLUMN elgblty_criteria text NOT NULL DEFAULT 'SELECT ''YES:''';

ALTER TABLE aca.aca_classes_n_thr_crses
	ADD COLUMN elgblty_criteria text NOT NULL DEFAULT 'SELECT ''YES:''';

ALTER TABLE aca.aca_crsrs_n_thr_sbjcts
	ADD COLUMN elgblty_criteria text NOT NULL DEFAULT 'SELECT ''YES:''';

ALTER TABLE aca.aca_prsns_acdmc_sttngs
	ADD COLUMN is_finalized character varying(1) NOT NULL DEFAULT '0';

--DROP TABLE accb.accb_smpl_vchr_hdr;
CREATE TABLE accb.accb_smpl_vchr_hdr (
	smpl_vchr_hdr_id bigserial NOT NULL,
	smpl_vchr_date character varying(21) COLLATE pg_catalog. "default",
	smpl_vchr_number character varying(100) COLLATE pg_catalog. "default",
	smpl_vchr_type character varying(50) COLLATE pg_catalog. "default",
	comments_desc character varying(300) COLLATE pg_catalog. "default",
	ref_doc_number character varying(200) COLLATE pg_catalog. "default" NOT NULL DEFAULT ''::character varying,
	supplier_id bigint,
	supplier_site_id bigint,
	invc_curr_id integer,
	func_curr_rate numeric,
	invoice_amount numeric,
	approval_status character varying(100) COLLATE pg_catalog. "default",
	org_id integer,
	gl_batch_id bigint,
	created_by bigint,
	creation_date character varying(50) COLLATE pg_catalog. "default",
	last_update_by bigint,
	last_update_date character varying(50) COLLATE pg_catalog. "default",
	CONSTRAINT pk_smpl_vchr_hdr_id PRIMARY KEY (smpl_vchr_hdr_id)
)
WITH (
	OIDS = FALSE)
TABLESPACE pg_default;

ALTER TABLE accb.accb_smpl_vchr_hdr
	ADD COLUMN smpl_vchr_det_tmplt_id integer NOT NULL DEFAULT - 1;

ALTER TABLE accb.accb_smpl_vchr_hdr
	ADD COLUMN mltpl_lines_allwd character varying(1) NOT NULL DEFAULT '0';

ALTER TABLE accb.accb_smpl_vchr_hdr
	ALTER COLUMN mltpl_lines_allwd SET DEFAULT '0'::character varying;

--DROP TABLE accb.accb_smpl_vchr_det;
CREATE TABLE accb.accb_smpl_vchr_det (
	smpl_vchr_det_id bigserial NOT NULL,
	smpl_vchr_hdr_id bigint NOT NULL,
	smpl_vchr_det_tmplt_id integer NOT NULL,
	smpl_vchr_det_desc character varying(500) COLLATE pg_catalog. "default",
	smpl_vchr_line_date character varying(21) COLLATE pg_catalog. "default",
	smpl_vchr_det_amnt numeric,
	created_by bigint,
	creation_date character varying(21) COLLATE pg_catalog. "default",
	last_update_by bigint,
	last_update_date character varying(21) COLLATE pg_catalog. "default",
	CONSTRAINT pk_smpl_vchr_det_id PRIMARY KEY (smpl_vchr_det_id)
)
WITH (
	OIDS = FALSE)
TABLESPACE pg_default;

--DROP TABLE gst.gst_gnrl_data_storage;
ALTER TABLE aca.aca_grade_scales
	ALTER COLUMN grade_gpa_value TYPE numeric;

CREATE TABLE gst.gst_gnrl_data_storage (
	gnrl_data1 text,
	gnrl_data2 text,
	gnrl_data3 text,
	gnrl_data4 text,
	gnrl_data5 text,
	gnrl_data6 text,
	gnrl_data7 text,
	gnrl_data8 text,
	gnrl_data9 text,
	gnrl_data10 text,
	gnrl_data11 text,
	gnrl_data12 text,
	gnrl_data13 text,
	gnrl_data14 text,
	gnrl_data15 text,
	gnrl_data16 text,
	gnrl_data17 text,
	gnrl_data18 text,
	gnrl_data19 text,
	gnrl_data20 text,
	gnrl_data21 text,
	gnrl_data22 text,
	gnrl_data23 text,
	gnrl_data24 text,
	gnrl_data25 text,
	gnrl_data26 text,
	gnrl_data27 text,
	gnrl_data28 text,
	gnrl_data29 text,
	gnrl_data30 text,
	gnrl_data31 text,
	gnrl_data32 text,
	gnrl_data33 text,
	gnrl_data34 text,
	gnrl_data35 text,
	gnrl_data36 text,
	gnrl_data37 text,
	gnrl_data38 text,
	gnrl_data39 text,
	gnrl_data40 text,
	gnrl_data41 text,
	gnrl_data42 text,
	gnrl_data43 text,
	gnrl_data44 text,
	gnrl_data45 text,
	gnrl_data46 text,
	gnrl_data47 text,
	gnrl_data48 text,
	gnrl_data49 text,
	gnrl_data50 text
)
WITH (
	OIDS = FALSE)
TABLESPACE pg_default;

--DROP TABLE pay.loan_pymnt_invstmnt_typs;
CREATE TABLE pay.loan_pymnt_invstmnt_typs (
	item_type_id bigserial NOT NULL,
	item_type_name character varying(200),
	item_type_desc character varying(300),
	item_type character varying(50),
	/*LOAN or PAYMENT or INVESTMENT*/
	pay_itm_set_id bigint DEFAULT - 1 NOT NULL,
	main_amnt_itm_id bigint DEFAULT - 1 NOT NULL,
	cash_accnt_id integer,
	asset_accnt_id integer,
	rcvbl_accnt_id integer,
	lblty_accnt_id integer,
	rvnu_accnt_id integer,
	investment_period numeric,
	period_type character varying(50),
	is_enabled character varying(1),
	org_id integer,
	created_by bigint NOT NULL,
	creation_date character varying(21) COLLATE pg_catalog. "default",
	last_update_by bigint NOT NULL,
	last_update_date character varying(21) COLLATE pg_catalog. "default" NOT NULL,
	CONSTRAINT pk_lpi_item_type_id PRIMARY KEY (item_type_id)
)
WITH (
	OIDS = FALSE)
TABLESPACE pg_default;

CREATE UNIQUE INDEX idx_plp_item_type_id ON pay.loan_pymnt_invstmnt_typs USING btree (item_type_id DESC NULLS FIRST) TABLESPACE pg_default;

ALTER TABLE pay.loan_pymnt_invstmnt_typs
	ADD COLUMN perdic_deduc_frmlr text NOT NULL DEFAULT 'select 0';

ALTER TABLE pay.loan_pymnt_invstmnt_typs
	ADD COLUMN INTRST_RATE numeric NOT NULL DEFAULT 0;

ALTER TABLE pay.loan_pymnt_invstmnt_typs
	ADD COLUMN intrst_period_type character varying(100);

ALTER TABLE pay.loan_pymnt_invstmnt_typs
	ADD COLUMN REPAY_PERIOD numeric NOT NULL DEFAULT 0;

ALTER TABLE pay.loan_pymnt_invstmnt_typs
	ADD COLUMN repay_period_type character varying(100);

ALTER TABLE pay.pay_itm_trnsctns
	ADD COLUMN pay_request_id bigint NOT NULL DEFAULT '-1'::integer;

ALTER TABLE pay.pay_value_sets_det
	ADD COLUMN pay_request_id bigint NOT NULL DEFAULT '-1'::integer;

ALTER TABLE pay.loan_pymnt_invstmnt_typs
	ADD COLUMN net_loan_amount_sql text NOT NULL DEFAULT 'select 0';

ALTER TABLE pay.loan_pymnt_invstmnt_typs
	ADD COLUMN max_loan_amount_sql text NOT NULL DEFAULT 'select 0';

ALTER TABLE pay.loan_pymnt_invstmnt_typs
	ADD COLUMN enforce_max_amnt character varying(1) NOT NULL DEFAULT '0';

ALTER TABLE pay.loan_pymnt_invstmnt_typs
	ADD COLUMN min_loan_amount_sql text NOT NULL DEFAULT 'select 0';

ALTER TABLE pay.loan_pymnt_invstmnt_typs
	ADD COLUMN lnkd_loan_type_id bigint NOT NULL DEFAULT - 1;

ALTER TABLE pay.loan_pymnt_invstmnt_typs
	ADD COLUMN lnkd_loan_mn_itm_id bigint NOT NULL DEFAULT - 1;

ALTER TABLE pay.loan_pymnt_invstmnt_typs
	ADD COLUMN INTRST_RATE numeric NOT NULL DEFAULT 0;

ALTER TABLE accb.accb_trnsctn_templates_hdr
	ADD COLUMN is_enabled character varying(1) COLLATE pg_catalog. "default";

ALTER TABLE accb.accb_trnsctn_templates_hdr
	ADD COLUMN doc_type character varying(15) COLLATE pg_catalog. "default";


/*ALTER TABLE accb.accb_doc_tmplts_det
 ADD COLUMN bals_accnt_id integer;*/
--DROP TABLE pay.loan_pymnt_typ_clsfctn;

CREATE TABLE pay.loan_pymnt_typ_clsfctn (
	typ_clsfctn_id serial NOT NULL,
	item_type_id bigint NOT NULL,
	clsfctn_name character varying(200),
	clsfctn_desc character varying(300),
	order_number integer,
	is_enabled character varying(1) NOT NULL DEFAULT '0',
	created_by bigint NOT NULL,
	creation_date character varying(21) COLLATE pg_catalog. "default",
	last_update_by bigint NOT NULL,
	last_update_date character varying(21) COLLATE pg_catalog. "default" NOT NULL,
	CONSTRAINT pk_plc_typ_clsfctn_id PRIMARY KEY (typ_clsfctn_id)
)
WITH (
	OIDS = FALSE)
TABLESPACE pg_default;

CREATE UNIQUE INDEX idx_plc_typ_clsfctn_id ON pay.loan_pymnt_typ_clsfctn USING btree (typ_clsfctn_id DESC NULLS FIRST) TABLESPACE pg_default;

--DROP TABLE pay.pay_loan_pymnt_rqsts;
CREATE TABLE pay.pay_loan_pymnt_rqsts (
	pay_request_id bigserial NOT NULL,
	RQSTD_FOR_PERSON_ID bigint DEFAULT - 1 NOT NULL,
	request_type character varying(50),
	/*LOAN or PAYMENT*/
	item_type_id bigint,
	REQUEST_REASON text,
	local_clsfctn character varying(200),
	/*January Clothing, July Clothing*/
	PRNCPL_AMOUNT numeric,
	mnthly_deduc numeric,
	intrst_rate numeric,
	intrst_period_type character varying(100),
	repay_period numeric,
	repay_period_type character varying(100),
	REQUEST_STATUS character varying(50),
	HAS_AGREED character varying(1) DEFAULT '0',
	IS_PROCESSED character varying(1) DEFAULT '0',
	org_id integer,
	created_by bigint NOT NULL,
	creation_date character varying(21) COLLATE pg_catalog. "default",
	last_update_by bigint NOT NULL,
	last_update_date character varying(21) COLLATE pg_catalog. "default" NOT NULL,
	CONSTRAINT pk_pay_request_id PRIMARY KEY (pay_request_id)
)
WITH (
	OIDS = FALSE)
TABLESPACE pg_default;

CREATE UNIQUE INDEX idx_pay_request_id ON pay.pay_loan_pymnt_rqsts USING btree (pay_request_id DESC NULLS FIRST) TABLESPACE pg_default;

CREATE INDEX idx_RQSTD_FOR_PERSON_ID ON pay.pay_loan_pymnt_rqsts USING btree (RQSTD_FOR_PERSON_ID ASC NULLS FIRST) TABLESPACE pg_default;

CREATE INDEX idx_item_type_id ON pay.pay_loan_pymnt_rqsts USING btree (item_type_id ASC NULLS LAST) TABLESPACE pg_default;

ALTER TABLE pay.pay_loan_pymnt_rqsts
	ADD COLUMN date_processed character varying(21) NOT NULL DEFAULT '';

ALTER TABLE pay.pay_loan_pymnt_rqsts
	ADD COLUMN net_loan_amount numeric NOT NULL DEFAULT 0;

ALTER TABLE pay.pay_loan_pymnt_rqsts
	ADD COLUMN max_loan_amount numeric NOT NULL DEFAULT 0;

ALTER TABLE pay.pay_loan_pymnt_rqsts
	ADD COLUMN enforce_max_amnt character varying(1) NOT NULL DEFAULT '0';

ALTER TABLE pay.pay_loan_pymnt_rqsts
	ADD COLUMN min_loan_amount numeric NOT NULL DEFAULT 0;

ALTER TABLE pay.pay_loan_pymnt_rqsts
	ADD COLUMN lnkd_loan_id bigint NOT NULL DEFAULT - 1;

--DROP TABLE pay.pay_fund_management;
CREATE TABLE pay.pay_fund_management (
	investment_id bigserial NOT NULL,
	item_type_id bigint,
	investor_client_id character varying(200),
	investment_ref_num character varying(200),
	investment_narration character varying(300),
	transaction_type character varying(50),
	/*PURCHASED or REDISCOUNTED*/
	roll_over_type character varying(50),
	/*None or Roll Over or Roll Over with Interest*/
	entrd_crcny_id integer,
	prchs_amnt numeric,
	maturity_amnt numeric,
	cur_exchng_rate numeric NOT NULL DEFAULT 1,
	intrst_rate numeric,
	gl_batch_id bigint,
	REQUEST_STATUS character varying(50),
	purchase_date character varying(21) COLLATE pg_catalog. "default",
	maturity_date character varying(21) COLLATE pg_catalog. "default",
	org_id integer,
	created_by bigint NOT NULL,
	creation_date character varying(21) COLLATE pg_catalog. "default",
	last_update_by bigint NOT NULL,
	last_update_date character varying(21) COLLATE pg_catalog. "default" NOT NULL,
	CONSTRAINT pk_pfm_investment_id PRIMARY KEY (investment_id)
)
WITH (
	OIDS = FALSE)
TABLESPACE pg_default;

ALTER TABLE pay.pay_fund_management
	ADD COLUMN old_maturity_amnt character varying(21) NOT NULL DEFAULT '';

CREATE UNIQUE INDEX idx_pfm_investment_id ON pay.pay_fund_management USING btree (investment_id DESC NULLS FIRST) TABLESPACE pg_default;

CREATE TABLE pay.pay_trans_attchmnts (
	attchmnt_id bigserial NOT NULL,
	src_pkey_id bigint NOT NULL,
	src_trans_type character varying(100) COLLATE pg_catalog. "default" NOT NULL,
	/*LOAN or PAYMENT or INVESTMENT*/
	attchmnt_desc character varying(500) COLLATE pg_catalog. "default" NOT NULL,
	file_name character varying(50) COLLATE pg_catalog. "default" NOT NULL,
	created_by bigint NOT NULL,
	creation_date character varying(21) COLLATE pg_catalog. "default" NOT NULL,
	last_update_by bigint NOT NULL,
	last_update_date character varying(21) COLLATE pg_catalog. "default" NOT NULL,
	CONSTRAINT pk_py_attchmnt_id PRIMARY KEY (attchmnt_id)
)
WITH (
	OIDS = FALSE)
TABLESPACE pg_default;

CREATE INDEX idx_py_attchmnt_desc ON pay.pay_trans_attchmnts USING btree (attchmnt_desc COLLATE pg_catalog. "default" ASC NULLS LAST) TABLESPACE pg_default;

CREATE INDEX idx_py_src_trans_type ON pay.pay_trans_attchmnts USING btree (src_trans_type COLLATE pg_catalog. "default" ASC NULLS LAST) TABLESPACE pg_default;

CREATE UNIQUE INDEX idx_py_attchmnt_id ON pay.pay_trans_attchmnts USING btree (attchmnt_id ASC NULLS LAST) TABLESPACE pg_default;

CREATE INDEX idx_py_attchmt_src_pkey_id ON pay.pay_trans_attchmnts USING btree (src_pkey_id ASC NULLS LAST) TABLESPACE pg_default;

