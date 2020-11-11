ALTER TABLE aca.aca_assess_sheet_hdr
    ADD COLUMN org_id integer;

ALTER TABLE aca.aca_assess_sheet_hdr
    ADD COLUMN assess_sheet_desc character varying(300) COLLATE pg_catalog."default";
ALTER TABLE aca.aca_assess_sheet_hdr
    ADD COLUMN assess_sheet_status character varying(100) NOT NULL Default 'Open for Editing';

ALTER TABLE aca.aca_assess_sheet_hdr
    ADD COLUMN assessed_person_id bigint not null default -1;

ALTER TABLE aca.aca_assess_sheet_hdr
    DROP COLUMN lnkd_grade_scale_id;
ALTER TABLE aca.aca_prsn_assmnt_col_vals
    ADD COLUMN col_value_2 TEXT COLLATE pg_catalog."default";

ALTER TABLE aca.aca_prsn_assmnt_col_vals
    RENAME ac_sttngs_sbjcts_id TO acdmc_sttngs_id;

ALTER TABLE aca.aca_crsrs_n_thr_sbjcts
    DROP COLUMN is_value_charctr;
ALTER TABLE aca.aca_prsn_assmnt_col_vals
    DROP COLUMN is_value_charctr;
ALTER TABLE aca.aca_prsn_assmnt_col_vals
    ADD COLUMN is_val_a_number character varying(1) NOT NULL DEFAULT '1';

ALTER TABLE aca.aca_prsn_assmnt_col_vals
    DROP COLUMN col_value;

ALTER TABLE aca.aca_prsn_assmnt_col_vals
    ADD COLUMN assess_sheet_hdr_id BIGINT NOT NULL DEFAULT -1;

ALTER TABLE aca.aca_crsrs_n_thr_sbjcts
    ADD COLUMN period_type   character varying(100) COLLATE pg_catalog."default",
    ADD COLUMN period_number integer NOT NULL DEFAULT 1;

ALTER TABLE inv.inv_consgmt_rcpt_hdr
    ADD COLUMN doc_curr_id integer NOT NULL DEFAULT '-1'::integer,
    ADD COLUMN exchng_rate numeric NOT NULL DEFAULT 1;

ALTER TABLE inv.inv_consgmt_rcpt_rtns_hdr
    ADD COLUMN doc_curr_id integer NOT NULL DEFAULT '-1'::integer,
    ADD COLUMN exchng_rate numeric NOT NULL DEFAULT 1;

ALTER TABLE aca.aca_assessment_columns
    ADD COLUMN section_located character varying(100);
ALTER TABLE aca.aca_assessment_columns
    ADD COLUMN data_type character varying(100);
ALTER TABLE aca.aca_assessment_columns
    ADD COLUMN data_length integer;
ALTER TABLE aca.aca_assessment_columns
    ADD COLUMN col_min_val numeric;
ALTER TABLE aca.aca_assessment_columns
    ADD COLUMN col_max_val numeric;
ALTER TABLE aca.aca_assessment_columns
    ADD COLUMN data_length integer;
ALTER TABLE aca.aca_assessment_columns
    ADD COLUMN is_enabled character varying(1);
ALTER TABLE aca.aca_assessment_columns
    ADD COLUMN is_dsplyd character varying(1) NOT NULL DEFAULT '1';
--ALTER TABLE aca.aca_assessment_columns DROP COLUMN html_css_style;
ALTER TABLE aca.aca_assessment_columns
    ADD COLUMN html_css_style TEXT NOT NULL DEFAULT '<span style="color:black;font-weight:normal;">{:p_col_value}</span>';
ALTER TABLE aca.aca_assessment_periods
    ADD COLUMN period_type character varying(100);
ALTER TABLE aca.aca_assessment_periods
    ALTER COLUMN period_status TYPE character varying(50) COLLATE pg_catalog."default";
ALTER TABLE aca.aca_assessment_periods
    ADD COLUMN period_number integer NOT NULL Default 1;
ALTER TABLE aca.aca_classes
    ADD COLUMN lnkd_div_id integer NOT NULL Default -1;
ALTER TABLE aca.aca_classes
    ADD COLUMN group_type character varying(200) COLLATE pg_catalog."default";
ALTER TABLE aca.aca_classes
    ADD COLUMN org_id integer;
ALTER TABLE aca.aca_classes
    ADD COLUMN next_class_id integer NOT NULL Default -1;
ALTER TABLE aca.aca_classes
    ADD COLUMN group_fcltr_pos_name character varying(200) NOT NULL DEFAULT 'Group Facilitator';
ALTER TABLE aca.aca_classes
    ADD COLUMN group_rep_pos_name character varying(200) NOT NULL DEFAULT 'Group Representative';
ALTER TABLE aca.aca_classes
    ADD COLUMN sbjct_rep_pos_name character varying(200) NOT NULL DEFAULT 'Subject/Target Facilitator';
ALTER TABLE aca.aca_classes
    RENAME sbjct_rep_pos_name TO sbjct_fcltr_pos_name;
ALTER TABLE sec.sec_users
    ADD COLUMN user_mail_verified character varying(1) NOT NULL DEFAULT '0';
ALTER TABLE sec.sec_users
    ADD COLUMN user_phone_verified character varying(1) NOT NULL DEFAULT '0';
/*ALTER TABLE aca.aca_crsrs_n_thr_sbjcts
    ADD COLUMN record_type character varying(100);*/
ALTER TABLE aca.aca_crsrs_n_thr_sbjcts
    ADD COLUMN class_id integer;

ALTER TABLE aca.aca_classes_n_thr_crses
    ADD COLUMN max_weight_crdt_hrs numeric;
ALTER TABLE aca.aca_classes_n_thr_crses
    ADD COLUMN min_weight_crdt_hrs numeric;

ALTER TABLE aca.aca_crsrs_n_thr_sbjcts
    ALTER COLUMN weight_or_credit_hrs TYPE numeric;

ALTER TABLE aca.aca_courses
    ADD COLUMN record_type character varying(100);
ALTER TABLE aca.aca_subjects
    ADD COLUMN record_type character varying(100);
ALTER TABLE aca.aca_courses
    ADD COLUMN is_enabled character varying(1);
ALTER TABLE aca.aca_subjects
    ADD COLUMN is_enabled character varying(1);
ALTER TABLE aca.aca_courses
    ADD COLUMN org_id integer;
ALTER TABLE aca.aca_subjects
    ADD COLUMN org_id integer;

ALTER TABLE aca.aca_assessment_types
    ADD COLUMN assmnt_type character varying(200);
ALTER TABLE aca.aca_assessment_types
    ADD COLUMN assmnt_level character varying(200);
ALTER TABLE aca.aca_assessment_types
    ADD COLUMN lnkd_assmnt_typ_id integer;
ALTER TABLE aca.aca_assessment_types
    ADD COLUMN org_id integer;
ALTER TABLE aca.aca_assessment_types
    ADD COLUMN dflt_grade_scale_id integer;

COMMENT ON COLUMN aca.aca_assessment_types.assmnt_level IS 'Course/Subject level';
COMMENT ON COLUMN aca.aca_assessment_types.assmnt_type IS 'Summary or Continuous Assessment';
COMMENT ON COLUMN aca.aca_assessment_types.lnkd_assmnt_typ_id IS 'Base Continuous Assessment for summary Reports';

ALTER TABLE prs.hr_accrual_plan_exctns
    ALTER COLUMN rqst_status TYPE character varying(50) COLLATE pg_catalog."default";

-- Table: prs.prsn_extra_data

-- DROP TABLE prs.prsn_extra_data;
ALTER TABLE aca.aca_assessment_columns
    ADD COLUMN column_no integer NOT NULL DEFAULT 1;
--DROP TABLE aca.aca_prsn_assmnt_col_vals;
CREATE TABLE aca.aca_assmnt_col_vals
(
    ass_col_val_id      bigserial                                          NOT NULL,
    acdmc_sttngs_id     bigint                                             NOT NULL,
    assess_sheet_hdr_id bigint                                             NOT NULL,
    data_col1           text COLLATE pg_catalog."default",
    data_col2           text COLLATE pg_catalog."default",
    data_col3           text COLLATE pg_catalog."default",
    data_col4           text COLLATE pg_catalog."default",
    data_col5           text COLLATE pg_catalog."default",
    data_col6           text COLLATE pg_catalog."default",
    data_col7           text COLLATE pg_catalog."default",
    data_col8           text COLLATE pg_catalog."default",
    data_col9           text COLLATE pg_catalog."default",
    data_col10          text COLLATE pg_catalog."default",
    data_col11          text COLLATE pg_catalog."default",
    data_col12          text COLLATE pg_catalog."default",
    data_col13          text COLLATE pg_catalog."default",
    data_col14          text COLLATE pg_catalog."default",
    data_col15          text COLLATE pg_catalog."default",
    data_col16          text COLLATE pg_catalog."default",
    data_col17          text COLLATE pg_catalog."default",
    data_col18          text COLLATE pg_catalog."default",
    data_col19          text COLLATE pg_catalog."default",
    data_col20          text COLLATE pg_catalog."default",
    data_col21          text COLLATE pg_catalog."default",
    data_col22          text COLLATE pg_catalog."default",
    data_col23          text COLLATE pg_catalog."default",
    data_col24          text COLLATE pg_catalog."default",
    data_col25          text COLLATE pg_catalog."default",
    data_col26          text COLLATE pg_catalog."default",
    data_col27          text COLLATE pg_catalog."default",
    data_col28          text COLLATE pg_catalog."default",
    data_col29          text COLLATE pg_catalog."default",
    data_col30          text COLLATE pg_catalog."default",
    data_col31          text COLLATE pg_catalog."default",
    data_col32          text COLLATE pg_catalog."default",
    data_col33          text COLLATE pg_catalog."default",
    data_col34          text COLLATE pg_catalog."default",
    data_col35          text COLLATE pg_catalog."default",
    data_col36          text COLLATE pg_catalog."default",
    data_col37          text COLLATE pg_catalog."default",
    data_col38          text COLLATE pg_catalog."default",
    data_col39          text COLLATE pg_catalog."default",
    data_col40          text COLLATE pg_catalog."default",
    data_col41          text COLLATE pg_catalog."default",
    data_col42          text COLLATE pg_catalog."default",
    data_col43          text COLLATE pg_catalog."default",
    data_col44          text COLLATE pg_catalog."default",
    data_col45          text COLLATE pg_catalog."default",
    data_col46          text COLLATE pg_catalog."default",
    data_col47          text COLLATE pg_catalog."default",
    data_col48          text COLLATE pg_catalog."default",
    data_col49          text COLLATE pg_catalog."default",
    data_col50          text COLLATE pg_catalog."default",
    created_by          bigint                                             NOT NULL,
    creation_date       character varying(21) COLLATE pg_catalog."default" NOT NULL,
    last_update_by      bigint                                             NOT NULL,
    last_update_date    character varying(21) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT pk_ass_col_val_id PRIMARY KEY (ass_col_val_id)
)
    WITH (
        OIDS = FALSE
    )
    TABLESPACE pg_default;
CREATE UNIQUE INDEX idx_ass_col_val_id
    ON aca.aca_assmnt_col_vals USING btree
        (ass_col_val_id ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: idx_extra_data_id

DROP INDEX aca.idx_col_acdmc_sttngs_id;
DROP INDEX aca.idx_col_assess_sheet_hdr_id;
/*
CREATE UNIQUE INDEX idx_col_assess_sheet_hdr_id
    ON aca.aca_assmnt_col_vals USING btree
        (assess_sheet_hdr_id ASC NULLS LAST)
    TABLESPACE pg_default;*/

ALTER TABLE aca.aca_assmnt_col_vals
    DROP COLUMN is_val_a_number;

ALTER TABLE aca.aca_assmnt_col_vals
    ADD COLUMN course_id integer NOT NULL DEFAULT -1;
ALTER TABLE aca.aca_assmnt_col_vals
    ADD COLUMN subject_id integer NOT NULL DEFAULT -1;

CREATE TABLE aca.aca_grade_scales
(
    scale_line_id    serial                                              NOT NULL,
    scale_id         integer                                             NOT NULL,
    scale_name       character varying(300) COLLATE pg_catalog."default",
    scale_desc       character varying(500) COLLATE pg_catalog."default",
    is_enabled       character varying(1) COLLATE pg_catalog."default",
    org_id           integer,
    grade_code       character varying(100) COLLATE pg_catalog."default" NOT NULL,
    grade_gpa_value  integer                                             NOT NULL,
    band_min_value   numeric                                             NOT NULL,
    band_max_value   numeric                                             NOT NULL,
    created_by       bigint                                              NOT NULL,
    creation_date    character varying(21) COLLATE pg_catalog."default"  NOT NULL,
    last_update_by   bigint                                              NOT NULL,
    last_update_date character varying(21) COLLATE pg_catalog."default",
    CONSTRAINT pk_scale_line_id PRIMARY KEY (scale_line_id)
)
    WITH (
        OIDS = FALSE
    )
    TABLESPACE pg_default;

ALTER TABLE aca.aca_grade_scales
    ADD COLUMN grade_description character varying(300);

CREATE SEQUENCE aca.aca_grade_scale_id_seq
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE aca.aca_grade_scale_id_seq
    OWNER TO postgres;

CREATE OR REPLACE FUNCTION pay.auto_execute_leave_plns(p_for_prsn_id bigint,
                                                       p_who_rn bigint,
                                                       p_run_date character varying,
                                                       p_orgidno integer,
                                                       p_msgid bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    v_IsTimeOK      BOOLEAN;
    tday_dte        CHARACTER VARYING(12);
    v_Start_dte     CHARACTER VARYING(12);
    v_End_dte       CHARACTER VARYING(12);
    v_Old_Start_dte CHARACTER VARYING(12);
    v_Old_End_dte   CHARACTER VARYING(12);
    recs_dte        CHARACTER VARYING(21);
    v_Remarks       CHARACTER VARYING(200);
    v_Intrvl        CHARACTER VARYING(50) := '';
    v_ExctnIntrvl   CHARACTER VARYING(50) := '';
    v_PrsnID        BIGINT;
    v_OrgID         INTEGER;
    v_AddItmID      INTEGER;
    v_PlanID        BIGINT;
    v_PlanExctnID   BIGINT;
    v_DaysEntld     NUMERIC               := 0;
    v_row_data      RECORD;
    v_row_data1     RECORD;
    v_msgs          TEXT                  := chr(10) || 'Leave Plan Execution About to Start...';
    v_cntr          INTEGER               := 0;
    v_updtMsg       BIGINT                := 0;
BEGIN
    /*
    STEPS
    1. GET ALL ACCRUAL PLANS
    2. FOR EACH ACCRUAL PLAN LOOP THROUGH ALL PERSONS HAVING THE ADD ITEM ASSIGNED
    3. CHECK IF INTERVAL IS FAVORABLE AND CREATE APPROPRIATE EXECUTION PLAN
    ELSE UPDATE EXISTING VALID ACTIVE PLAN
    4. NO NEED TO MAKE USE OF BALANCE ITEM AND SUBTRACT ITEM-HIDE THEM IN ACCRUAL PLAN FOR NOW
    */

    SELECT to_char(now(), 'YYYY-MM-DD')
    INTO tday_dte;
    SELECT to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
    INTO recs_dte;
    RAISE NOTICE 'Before First Select tday_dte:%', tday_dte;
    FOR v_row_data IN SELECT b.person_id,
                             b.org_id
                      FROM prs.prsn_names_nos b
                      WHERE b.org_id = p_orgidno
                        AND b.person_id = (CASE WHEN p_for_prsn_id <= 0 THEN b.person_id ELSE p_for_prsn_id END)
        LOOP
            v_PrsnID := v_row_data.person_id;
            v_OrgID := v_row_data.org_id;
            FOR v_row_data1 IN SELECT accrual_plan_id,
                                      accrual_plan_name,
                                      accrual_plan_desc,
                                      plan_execution_intrvls,
                                      accrual_start_date,
                                      accrual_end_date,
                                      lnkd_balance_item_id,
                                      lnkd_balnc_add_item_id,
                                      lnkd_balnc_sbtrct_item_id,
                                      pay.get_prsn_actv_itmvalid(a.lnkd_balnc_add_item_id, v_PrsnID) itmvalid
                               FROM prs.hr_accrual_plans a
                               WHERE pay.get_prsn_actv_itmvalid(a.lnkd_balnc_add_item_id, v_PrsnID) > 0
                LOOP
                    v_PlanID := v_row_data1.accrual_plan_id;
                    v_AddItmID := v_row_data1.lnkd_balnc_add_item_id;
                    v_Remarks := v_row_data1.accrual_plan_name;
                    v_Old_Start_dte := v_row_data1.accrual_start_date;
                    v_ExctnIntrvl := v_row_data1.plan_execution_intrvls;
                    SELECT COALESCE(MAX(execution_end_dte), '')
                    INTO v_Old_End_dte
                    FROM prs.hr_accrual_plan_exctns
                    WHERE person_id = v_PrsnID
                      AND accrual_plan_id = v_PlanID;
                    IF COALESCE(v_Old_End_dte, '') = ''
                    THEN
                        v_Start_dte := v_Old_Start_dte;
                    ELSE
                        v_Start_dte :=
                                to_char(to_timestamp(v_Old_End_dte, 'YYYY-MM-DD') + INTERVAL '1 day', 'YYYY-MM-DD');
                    END IF;
                    v_IsTimeOK := pay.is_pln_exctn_time_ok(v_PlanID, v_PrsnID, v_Start_dte);
                    IF v_IsTimeOK = FALSE
                    THEN
                        v_msgs := v_msgs || chr(10) || ' Cannot Process this Leave Plan Execution!' || chr(10) ||
                                  'Date Specified (' || v_Start_dte || ') does not agree with Plan Interval (' ||
                                  v_ExctnIntrvl || ')!';
                        v_updtMsg := rpt.updaterptlogmsg($5, v_msgs, $3, $2);
                        v_msgs := rpt.getLogMsg($5);
                        RETURN v_msgs;
                    END IF;
                    IF age(now(), to_timestamp(v_Start_dte, 'YYYY-MM-DD')) <
                       '-5 day' :: INTERVAL
                    THEN
                        v_msgs := v_msgs || chr(10) || ' Cannot Process this Leave Plan Execution!' || chr(10) ||
                                  'Date Specified (' || v_Start_dte || ') is too far away (more than 5 days) from now!';
                        v_updtMsg := rpt.updaterptlogmsg($5, v_msgs, $3, $2);
                        v_msgs := rpt.getLogMsg($5);
                        RETURN v_msgs;
                    END IF;
                    IF v_ExctnIntrvl = 'Ad hoc'
                    THEN
                        v_Intrvl := '1 day';
                    ELSIF v_ExctnIntrvl = 'Yearly'
                    THEN
                        v_Intrvl := '1 year';
                    ELSIF v_ExctnIntrvl = 'Half-Yearly'
                    THEN
                        v_Intrvl := '6 month';
                    ELSIF v_ExctnIntrvl = 'Quarterly'
                    THEN
                        v_Intrvl := '3 month';
                    ELSIF v_ExctnIntrvl = 'Monthly'
                    THEN
                        v_Intrvl := '1 month';
                    ELSIF v_ExctnIntrvl = 'Semi-Monthly'
                    THEN
                        v_Intrvl := '2 week';
                    ELSIF v_ExctnIntrvl = 'Weekly'
                    THEN
                        v_Intrvl := '1 week';
                    ELSIF v_ExctnIntrvl = 'Daily'
                    THEN
                        v_Intrvl := '1 day';
                    ELSE
                        v_Intrvl := '4000 year';
                    END IF;
                    v_DaysEntld := pay.get_payitm_expctd_amnt(v_AddItmID, v_PrsnID, v_OrgID, tday_dte);
                    v_PlanExctnID := nextval('prs.hr_accrual_plan_exctns_plan_execution_id_seq' :: REGCLASS);
                    v_End_dte :=
                            to_char(to_timestamp(v_Start_dte, 'YYYY-MM-DD') + (v_Intrvl) :: INTERVAL - INTERVAL '1 day',
                                    'YYYY-MM-DD');
                    INSERT INTO prs.hr_accrual_plan_exctns (plan_execution_id, person_id, accrual_plan_id,
                                                            execution_strt_dte,
                                                            execution_end_dte, days_entitled, cmmnt_remark, rqst_status,
                                                            org_id, created_by, creation_date, last_update_by,
                                                            last_update_date)
                    VALUES (v_PlanExctnID, v_PrsnID, v_PlanID, v_Start_dte, v_End_dte,
                            v_DaysEntld, v_Remarks, 'Not Submitted',
                            v_OrgID, p_who_rn, recs_dte, p_who_rn, recs_dte);
                    /*INSERT INTO prs.hr_person_absences (
                      absence_id, plan_execution_id, person_id, absence_start_date,
                      no_of_days, absence_end_date, absence_reason, absence_status,
                      created_by, creation_date, last_update_by, last_update_date)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);*/
                    v_cntr := v_cntr + 1;
                END LOOP;
            v_updtMsg := rpt.updaterptlogmsg($5, v_msgs, $3, $2);
        END LOOP;

    v_msgs := v_msgs || chr(10) || 'Successfully Created a Total of ' ||
              trim(to_char(v_cntr, '99999999999999999999999999999999999')) ||
              ' Leave Plan Executions!';
    RETURN v_msgs;
EXCEPTION
    WHEN OTHERS
        THEN
            v_msgs := v_msgs || chr(10) || '' || SQLSTATE || chr(10) || SQLERRM;
            v_updtMsg := rpt.updaterptlogmsg($5, v_msgs, $3, $2);
            --v_msgs:=rpt.getLogMsg($5);

            RAISE NOTICE 'ERRORS:%', v_msgs;
            RAISE EXCEPTION 'ERRORS:%', v_msgs
                USING HINT = 'Please check your System Setup or Contact Vendor';
            RETURN v_msgs;
END;
$BODY$;

ALTER FUNCTION pay.auto_execute_leave_plns(bigint, bigint, character varying, integer, bigint)
    OWNER TO postgres;


-- Table: scm.scm_cnsmr_credit_items

-- DROP TABLE scm.scm_cnsmr_credit_items;

CREATE TABLE scm.scm_cnsmr_credit_items
(
    credit_itm_id         bigserial NOT NULL,
    cnsmr_credit_id       bigint,
    item_id               bigint,
    vendor_id             bigint,
    itm_pymnt_plan_id     bigint,
    qty                   numeric,
    unit_selling_price    numeric,
    created_by            bigint,
    creation_date         character varying(21) COLLATE pg_catalog."default",
    last_update_by        bigint,
    last_update_date      character varying(21) COLLATE pg_catalog."default",
    itm_plan_init_deposit numeric,
    CONSTRAINT pk_credit_itm_id PRIMARY KEY (credit_itm_id)
)
    WITH (
        OIDS = FALSE
    )
    TABLESPACE pg_default;

ALTER TABLE scm.scm_cnsmr_credit_items
    OWNER to postgres;

ALTER TABLE scm.scm_cnsmr_credit_items
    ADD COLUMN src_invc_det_ln_id bigint NOT NULL DEFAULT '-1'::integer;
-- Table: scm.scm_cnsmr_credit_analys

-- DROP TABLE scm.scm_cnsmr_credit_analys;

CREATE TABLE scm.scm_cnsmr_credit_analys
(
    cnsmr_credit_id         bigserial NOT NULL,
    cust_sup_id             bigint,
    salary_income           numeric,
    fuel_allowance          numeric,
    rent_allowance          numeric,
    clothing_allowance      numeric,
    other_allowances        numeric,
    debt_service_ratio      numeric,
    loan_deductions         numeric,
    affordability_amnt      numeric,
    created_by              bigint,
    creation_date           character varying(21) COLLATE pg_catalog."default",
    last_update_by          bigint,
    last_update_date        character varying(21) COLLATE pg_catalog."default",
    trns_date               character varying(21) COLLATE pg_catalog."default",
    marketer_person_id      bigint,
    pymnt_option            character varying(30) COLLATE pg_catalog."default",
    guarantor_name          character varying(300) COLLATE pg_catalog."default",
    guarantor_contact_nos   character varying(50) COLLATE pg_catalog."default",
    guarantor_occupation    character varying(30) COLLATE pg_catalog."default",
    guarantor_place_of_work character varying(50) COLLATE pg_catalog."default",
    period_at_workplace     numeric,
    period_uom_at_workplace character varying(10) COLLATE pg_catalog."default",
    guarantor_email         character varying(50) COLLATE pg_catalog."default",
    ttl_prdt_price          numeric,
    no_of_pymnts            numeric,
    ttl_initial_deposit     numeric,
    mnthly_rpymnts          numeric,
    init_dpst_type          character varying(20) COLLATE pg_catalog."default",
    transaction_no          character varying(100) COLLATE pg_catalog."default",
    org_id                  integer,
    CONSTRAINT pk_cnsmr_credit_id PRIMARY KEY (cnsmr_credit_id)
)
    WITH (
        OIDS = FALSE
    )
    TABLESPACE pg_default;

ALTER TABLE scm.scm_cnsmr_credit_analys
    OWNER to postgres;

COMMENT ON COLUMN scm.scm_cnsmr_credit_analys.init_dpst_type
    IS 'Auto
Manual';

ALTER TABLE scm.scm_cnsmr_credit_analys
    ADD COLUMN status          character varying(15) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Incomplete'::character varying,
    ADD COLUMN src_invc_hdr_id bigint                                             NOT NULL DEFAULT '-1'::integer,
    ADD COLUMN src_store_id    bigint                                             NOT NULL DEFAULT '-1'::integer;
-- Table: inv.inv_itm_payment_plans

-- DROP TABLE inv.inv_itm_payment_plans;

CREATE TABLE inv.inv_itm_payment_plans
(
    itm_pymnt_plan_id  bigserial NOT NULL,
    item_id            bigint,
    plan_name          character varying(50) COLLATE pg_catalog."default",
    no_of_pymnts       numeric,
    plan_price         numeric,
    created_by         bigint,
    creation_date      character varying(21) COLLATE pg_catalog."default",
    last_update_by     bigint,
    last_update_date   character varying(21) COLLATE pg_catalog."default",
    item_selling_price numeric,
    initial_deposit    numeric,
    is_enabled         character varying(3) COLLATE pg_catalog."default",
    org_id             integer,
    CONSTRAINT pk_itm_pymnt_plan_id PRIMARY KEY (itm_pymnt_plan_id)
)
    WITH (
        OIDS = FALSE
    )
    TABLESPACE pg_default;

-- Table: inv.inv_itm_payment_plans_setup

-- DROP TABLE inv.inv_itm_payment_plans_setup;

CREATE TABLE inv.inv_itm_payment_plans_setup
(
    itm_pymnt_plan_setup_id bigserial NOT NULL,
    plan_name               character varying(50) COLLATE pg_catalog."default",
    no_of_pymnts            numeric,
    plan_price_type         character varying(50) COLLATE pg_catalog."default",
    plan_price              numeric,
    created_by              bigint,
    creation_date           character varying(21) COLLATE pg_catalog."default",
    last_update_by          bigint,
    last_update_date        character varying(21) COLLATE pg_catalog."default",
    initial_deposit_type    character varying(50) COLLATE pg_catalog."default",
    initial_deposit         numeric,
    is_enabled              character varying(3) COLLATE pg_catalog."default",
    org_id                  integer,
    order_no                integer,
    CONSTRAINT pk_itm_pymnt_plan_setup_id PRIMARY KEY (itm_pymnt_plan_setup_id)
)
    WITH (
        OIDS = FALSE
    )
    TABLESPACE pg_default;


-- Table: scm.scm_post_dated_cheques

-- DROP TABLE scm.scm_post_dated_cheques;

CREATE TABLE scm.scm_post_dated_cheques
(
    postdated_chq_id bigserial NOT NULL,
    cnsmr_credit_id  bigint,
    chq_no           character varying(10) COLLATE pg_catalog."default",
    chq_issuer_name  character varying(300) COLLATE pg_catalog."default",
    created_by       bigint,
    creation_date    character varying(21) COLLATE pg_catalog."default",
    last_update_by   bigint,
    last_update_date character varying(21) COLLATE pg_catalog."default",
    chq_bank         character varying(100) COLLATE pg_catalog."default",
    amount           numeric,
    CONSTRAINT pk_postdated_chq_id PRIMARY KEY (postdated_chq_id)
)
    WITH (
        OIDS = FALSE
    )
    TABLESPACE pg_default;

-- Trigger: insert_new_item_payment_plan_trggr

-- DROP TRIGGER insert_new_item_payment_plan_trggr ON inv.inv_itm_list;
-- FUNCTION: inv.insert_new_item_payment_plan()

-- DROP FUNCTION inv.insert_new_item_payment_plan();

CREATE FUNCTION inv.insert_new_item_payment_plan()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS
$BODY$
DECLARE
    x integer;
BEGIN
    IF TG_OP = 'INSERT'
    THEN
        x := inv.loadItemsPaymentPlan(NEW.org_id, NEW.created_by, NEW.item_id, NEW.selling_price::numeric);
    END IF;
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION '% %',SQLERRM,SQLSTATE;
        RETURN NEW;
END;
$BODY$;

ALTER FUNCTION inv.insert_new_item_payment_plan()
    OWNER TO postgres;


CREATE FUNCTION inv.reload_item_payment_plan_chckr()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS
$BODY$
DECLARE
    x integer;
BEGIN
    IF TG_OP = 'UPDATE' AND (NEW.selling_price != OLD.selling_price)
    THEN
        x := inv.loadItemsPaymentPlan(OLD.org_id, NEW.last_update_by, OLD.item_id, NEW.selling_price::numeric);
    END IF;
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION '% %',SQLERRM,SQLSTATE;
        RETURN NEW;
END;
$BODY$;


CREATE TRIGGER insert_new_item_payment_plan_trggr
    AFTER INSERT
    ON inv.inv_itm_list
    FOR EACH ROW
EXECUTE PROCEDURE inv.insert_new_item_payment_plan();

CREATE TRIGGER reload_item_payment_plan_trggr
    BEFORE UPDATE
    ON inv.inv_itm_list
    FOR EACH ROW
EXECUTE PROCEDURE inv.reload_item_payment_plan_chckr();

-- FUNCTION: inv.loadallitemspaymentplans(integer, bigint)

-- DROP FUNCTION inv.loadallitemspaymentplans(integer, bigint);

CREATE OR REPLACE FUNCTION inv.loadallitemspaymentplans(p_org_id integer,
                                                        p_usr_id bigint)
    RETURNS void
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS
$BODY$
DECLARE
    cnta              bigint                := 0;
    v_plan_price      numeric               := 0;
    v_initial_deposit numeric               := 0;
    i                 RECORD;
    j                 RECORD;
    v_dte             character varying(21) := NULL;

BEGIN

    select to_char(now(), 'yyyy-mm-dd hh24:mi:ss') INTO v_dte;

    FOR i IN (SELECT distinct item_id, selling_price
              FROM inv.inv_itm_list
              WHERE item_type = 'Merchandise Inventory'
                AND enabled_flag = '1'
                AND org_id = p_org_id
              ORDER BY 1)
        LOOP

            FOR j IN (SELECT plan_name, no_of_pymnts, plan_price_type, plan_price, initial_deposit_type, initial_deposit
                      FROM inv.inv_itm_payment_plans_setup
                      WHERE is_enabled = 'Yes'
                        AND org_id = p_org_id
                      ORDER BY order_no ASC)
                LOOP
                    --CHECK IF PLAN EXIST FOR ITEM
                    SELECT count(*)
                    INTO cnta
                    FROM inv.inv_itm_payment_plans
                    WHERE item_id = i.item_id
                      AND UPPER(plan_name) = UPPER(j.plan_name)
                      AND org_id = p_org_id;

                    IF j.plan_price_type = 'Percentage' THEN
                        v_plan_price := (j.plan_price * i.selling_price) / 100;
                    ELSIF j.plan_price_type = 'Absolute' THEN
                        v_plan_price := j.plan_price;
                    ELSE
                        v_plan_price := 0.00;
                    END IF;

                    IF j.initial_deposit_type = 'Percentage' THEN
                        v_initial_deposit := (j.initial_deposit * v_plan_price) / 100;
                    ELSIF j.initial_deposit_type = 'Absolute' THEN
                        v_initial_deposit := j.initial_deposit;
                    ELSE
                        v_initial_deposit := 0.00;
                    END IF;


                    IF cnta > 0 THEN
                        UPDATE inv.inv_itm_payment_plans
                        SET no_of_pymnts=j.no_of_pymnts,
                            plan_price=ROUND(v_plan_price, 2),
                            last_update_by=p_usr_id,
                            last_update_date=v_dte,
                            item_selling_price=i.selling_price,
                            initial_deposit=ROUND(v_initial_deposit, 2)
                        WHERE item_id = i.item_id
                          AND UPPER(plan_name) = UPPER(j.plan_name)
                          AND org_id = p_org_id;
                    ELSE
                        INSERT INTO inv.inv_itm_payment_plans(item_id, plan_name, no_of_pymnts, plan_price,
                                                              created_by, creation_date, last_update_by,
                                                              last_update_date,
                                                              item_selling_price, initial_deposit, is_enabled, org_id)
                        VALUES (i.item_id, j.plan_name, j.no_of_pymnts, ROUND(v_plan_price, 2),
                                p_usr_id, v_dte, p_usr_id, v_dte,
                                i.selling_price, ROUND(v_initial_deposit, 2), 'Yes', p_org_id);
                    END IF;

                    v_plan_price := 0;
                    v_initial_deposit := 0;
                END LOOP;
        END LOOP;

END
$BODY$;



-- FUNCTION: inv.loaditemspaymentplan(integer, bigint, bigint, numeric)

-- DROP FUNCTION inv.loaditemspaymentplan(integer, bigint, bigint, numeric);

CREATE OR REPLACE FUNCTION inv.loaditemspaymentplan(p_org_id integer,
                                                    p_usr_id bigint,
                                                    p_itm_id bigint,
                                                    p_selling_price numeric)
    RETURNS integer
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS
$BODY$
DECLARE
    cnta              bigint                := 0;
    v_plan_price      numeric               := 0;
    v_initial_deposit numeric               := 0;
    i                 RECORD;
    j                 RECORD;
    v_dte             character varying(21) := NULL;

BEGIN
    select to_char(now(), 'yyyy-mm-dd hh24:mi:ss') INTO v_dte;

    FOR i IN (SELECT distinct item_id, $4 selling_price
              FROM inv.inv_itm_list
              WHERE item_type = 'Merchandise Inventory'
                AND enabled_flag = '1'
                AND org_id = p_org_id
                AND item_id = p_itm_id
              ORDER BY 1)
        LOOP

            FOR j IN (SELECT plan_name, no_of_pymnts, plan_price_type, plan_price, initial_deposit_type, initial_deposit
                      FROM inv.inv_itm_payment_plans_setup
                      WHERE is_enabled = 'Yes'
                        AND org_id = p_org_id
                      ORDER BY order_no ASC)
                LOOP
                    --CHECK IF PLAN EXIST FOR ITEM
                    SELECT count(*)
                    INTO cnta
                    FROM inv.inv_itm_payment_plans
                    WHERE item_id = i.item_id
                      AND UPPER(plan_name) = UPPER(j.plan_name)
                      AND org_id = p_org_id;

                    IF j.plan_price_type = 'Percentage' THEN
                        v_plan_price := (j.plan_price * i.selling_price) / 100;
                    ELSIF j.plan_price_type = 'Absolute' THEN
                        v_plan_price := j.plan_price;
                    ELSE
                        v_plan_price := 0.00;
                    END IF;

                    IF j.initial_deposit_type = 'Percentage' THEN
                        v_initial_deposit := (j.initial_deposit * v_plan_price) / 100;
                    ELSIF j.initial_deposit_type = 'Absolute' THEN
                        v_initial_deposit := j.initial_deposit;
                    ELSE
                        v_initial_deposit := 0.00;
                    END IF;


                    IF cnta > 0 THEN
                        UPDATE inv.inv_itm_payment_plans
                        SET no_of_pymnts=j.no_of_pymnts,
                            plan_price=ROUND(v_plan_price, 2),
                            last_update_by=p_usr_id,
                            last_update_date=v_dte,
                            item_selling_price=i.selling_price,
                            initial_deposit=ROUND(v_initial_deposit, 2)
                        WHERE item_id = i.item_id
                          AND UPPER(plan_name) = UPPER(j.plan_name)
                          AND org_id = p_org_id;
                    ELSE
                        INSERT INTO inv.inv_itm_payment_plans(item_id, plan_name, no_of_pymnts, plan_price,
                                                              created_by, creation_date, last_update_by,
                                                              last_update_date,
                                                              item_selling_price, initial_deposit, is_enabled, org_id)
                        VALUES (i.item_id, j.plan_name, j.no_of_pymnts, ROUND(v_plan_price, 2),
                                p_usr_id, v_dte, p_usr_id, v_dte,
                                i.selling_price, ROUND(v_initial_deposit, 2), 'Yes', p_org_id);
                    END IF;

                    v_plan_price := 0;
                    v_initial_deposit := 0;
                END LOOP;
            NULL;
        END LOOP;
    return 1;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION '% %', SQLERRM, SQLSTATE;
        RETURN 0;
END
$BODY$;

ALTER TABLE scm.scm_post_dated_cheques
    ADD COLUMN chq_due_date character varying(10);