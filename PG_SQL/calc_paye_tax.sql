
CREATE OR REPLACE FUNCTION org.does_prsn_hv_crtria_id(
	prsn_id bigint,
	crtriaid bigint,
	crtriatype character varying)
    RETURNS integer
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS $BODY$
<< outerblock >>
DECLARE
bid integer := -1;
BEGIN
    IF crtriatype IN ('Everyone','Public') THEN
	SELECT 1 INTO bid;
    ELSIF crtriatype = 'Divisions/Groups' THEN
	SELECT count(1) INTO bid FROM pasn.prsn_divs_groups a
	WHERE  a.div_id= crtriaid and a.person_id=prsn_id  and (now() between to_timestamp(a.valid_start_date, 'YYYY-MM-DD 00:00:00') AND to_timestamp(a.valid_end_date, 'YYYY-MM-DD 23:59:59'));
    ELSIF crtriatype = 'Grade' THEN
    SELECT count(1) INTO bid FROM pasn.prsn_grades a
	WHERE  a.grade_id= crtriaid and a.person_id=prsn_id  and (now() between to_timestamp(a.valid_start_date, 'YYYY-MM-DD 00:00:00') AND to_timestamp(a.valid_end_date, 'YYYY-MM-DD 23:59:59'));
    ELSIF crtriatype = 'Job' THEN
	SELECT count(1) INTO bid FROM pasn.prsn_jobs a
	WHERE  a.job_id= crtriaid and a.person_id=prsn_id  and (now() between to_timestamp(a.valid_start_date, 'YYYY-MM-DD 00:00:00') AND to_timestamp(a.valid_end_date, 'YYYY-MM-DD 23:59:59'));
    ELSIF crtriatype = 'Position' THEN
	SELECT count(1) INTO bid FROM pasn.prsn_positions a
	WHERE  a.position_id= crtriaid and a.person_id=prsn_id  and (now() between to_timestamp(a.valid_start_date, 'YYYY-MM-DD 00:00:00') AND to_timestamp(a.valid_end_date, 'YYYY-MM-DD 23:59:59'));
    ELSIF crtriatype = 'Site/Location' THEN
	SELECT count(1) INTO bid FROM pasn.prsn_locations a
	WHERE  a.location_id= crtriaid and a.person_id=prsn_id  and (now() between to_timestamp(a.valid_start_date, 'YYYY-MM-DD 00:00:00') AND to_timestamp(a.valid_end_date, 'YYYY-MM-DD 23:59:59'));
    ELSIF crtriatype = 'Single Person' THEN
	SELECT count(1) INTO bid FROM prs.prsn_names_nos a
	WHERE  a.person_id=prsn_id and prsn_id=crtriaid;
    ELSIF crtriatype = 'Person Type' THEN
	SELECT count(1) INTO bid
	FROM pasn.prsn_prsntyps a
	WHERE ((a.person_id = prsn_id) and gst.get_pssbl_val_id(a.prsn_type,gst.get_lov_id('Person Types')) = crtriaid and
	(now() between to_timestamp(a.valid_start_date,'YYYY-MM-DD 00:00:00') AND to_timestamp(a.valid_end_date,'YYYY-MM-DD 23:59:59')));
    ELSE
        SELECT 1 INTO bid;
    END IF;
    RETURN COALESCE(bid,1);
END;
$BODY$;

CREATE OR REPLACE FUNCTION public.get_frmtd_number(
    p_in_amnt numeric)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    bid character varying(500) := '';
BEGIN
    select trim(to_char(p_in_amnt, '999G999G999G999G999G999G990D00')) into bid;
    RETURN coalesce(bid, '');
END;
$BODY$;

CREATE OR REPLACE FUNCTION mcf.get_crncy_iso_code(
    p_crncy_id bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    bid character varying(5) := '';
BEGIN
    select iso_code into bid from mcf.mcf_currencies where crncy_id = p_crncy_id;
    RETURN coalesce(bid, '');
END;
$BODY$;

CREATE OR REPLACE FUNCTION vms.get_denom_unit_val(p_itemID bigint
)
    RETURNS numeric
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    bid numeric := 0.00;
BEGIN
    SELECT orgnl_selling_price
    INTO bid
    FROM inv.inv_itm_list
    WHERE item_id = p_itemID;
    RETURN coalesce(bid, 0.00);
END ;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_next_prd_start(p_period_id bigint
)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    bid           character varying(21) := '';
    v_cur_prd_end character varying(21) := '';
BEGIN
    v_cur_prd_end := aca.get_period_end(p_period_id);
    bid := aca.get_next_period_start(v_cur_prd_end);
    RETURN coalesce(bid, '');
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_next_period_start(
    p_cur_prd_end character varying)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    bid character varying(21) := '';
BEGIN
    select min(period_start_date) into bid from aca.aca_assessment_periods where period_start_date >= p_cur_prd_end;
    RETURN coalesce(bid, '');
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_period_end(
    periodid bigint)
    RETURNS character varying
    LANGUAGE 'sql'

    COST 100
    VOLATILE
AS
$BODY$
SELECT period_end_date
FROM aca.aca_assessment_periods
WHERE assmnt_period_id = $1
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_period_start(
    periodid bigint)
    RETURNS character varying
    LANGUAGE 'sql'

    COST 100
    VOLATILE
AS
$BODY$
SELECT period_start_date
FROM aca.aca_assessment_periods
WHERE assmnt_period_id = $1
$BODY$;
--to_char(to_timestamp(period_start_date, 'YYYY-MM-DD'), 'DD-Mon-YYYY')
CREATE OR REPLACE FUNCTION prs.get_prsn_gender(
    prsnid bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    bid character varying := '';
BEGIN
    select gender into bid from prs.prsn_names_nos where person_id = $1;
    RETURN bid;
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_max_courseid(p_sht_hdr_id bigint)
    RETURNS INTEGER
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    bid INTEGER := -1;
BEGIN
    SELECT max(course_id)
    INTO bid
    FROM aca.aca_assmnt_col_vals
    WHERE assess_sheet_hdr_id = p_sht_hdr_id;
    RETURN coalesce(bid, -1);
END;
$BODY$;

CREATE OR REPLACE FUNCTION org.get_org_pos_id(posname character varying, p_orgid integer)
    RETURNS integer
    LANGUAGE 'sql'

    COST 100
    VOLATILE
AS
$BODY$
select position_id
from org.org_positions
where position_code_name ilike $1
  and org_id = $2
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_pos_hldr_prs_id(p_period_id BIGINT, p_group_id integer, p_course_id integer
                                                  , p_subject_id integer, p_position_code character varying)
    RETURNS BIGINT
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    bid         BIGINT := -1;
    v_period_id BIGINT := -1;
BEGIN
    v_period_id := p_period_id;
    if (v_period_id <= 0) then
        select assmnt_period_id
        into v_period_id
        from aca.aca_assessment_periods
        order by period_start_date DESC
        LIMIT 1 OFFSET 0;
    end if;
    select MAX(b.person_id)
    into bid
    from aca.aca_assessment_periods a,
         pasn.prsn_positions b
    where (a.assmnt_period_id = v_period_id or (v_period_id <= 0 and
                                                to_char(now(), 'YYYY-MM-DD') between a.period_start_date and a.period_end_date))
      and a.period_end_date >= b.valid_start_date
      and (a.period_end_date <= b.valid_end_date or coalesce(b.valid_end_date, '') = '')
      and b.position_id = org.get_org_pos_id(p_position_code, a.org_id)
      and b.div_id = p_group_id
      and (b.div_sub_cat_id1 = p_course_id or p_course_id <= 0)
      and (b.div_sub_cat_id2 = p_subject_id or (coalesce(b.div_sub_cat_id2, -1) <= 0 and p_subject_id <= 0));
    RETURN coalesce(bid, -1);
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_pos_hldr_prs_nm(p_period_id BIGINT, p_group_id integer, p_course_id integer
                                                  , p_subject_id integer, p_position_code character varying)
    RETURNS TEXT
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    bid         BIGINT := -1;
    v_Res       TEXT   := '';
    v_period_id BIGINT := -1;
BEGIN
    v_period_id := p_period_id;
    if (v_period_id <= 0) then
        select assmnt_period_id
        into v_period_id
        from aca.aca_assessment_periods
        order by period_start_date DESC
        LIMIT 1 OFFSET 0;
    end if;
    select MAX(b.person_id)
    into bid
    from aca.aca_assessment_periods a,
         pasn.prsn_positions b
    where (a.assmnt_period_id = v_period_id or (v_period_id <= 0 and
                                                to_char(now(), 'YYYY-MM-DD') between a.period_start_date and a.period_end_date))
      and a.period_end_date >= b.valid_start_date
      and (a.period_end_date <= b.valid_end_date or coalesce(b.valid_end_date, '') = '')
      and b.position_id = org.get_org_pos_id(p_position_code, a.org_id)
      and b.div_id = p_group_id
      and (b.div_sub_cat_id1 = p_course_id or p_course_id <= 0)
      and (b.div_sub_cat_id2 = p_subject_id or (coalesce(b.div_sub_cat_id2, -1) <= 0 and p_subject_id <= 0));
    v_Res := prs.get_prsn_name(coalesce(bid, -1)) || ' (' || prs.get_prsn_loc_id(coalesce(bid, -1)) || ')';
    RETURN coalesce(v_Res, '');
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.compute_all_rpt_cards(p_period_id bigint,
                                                     p_class_id integer,
                                                     p_assess_typ_id integer,
                                                     p_shd_close_sht character varying,
                                                     p_create_hdrs character varying,
                                                     p_who_rn bigint,
                                                     p_msgid BIGINT)
    RETURNS TEXT
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    v_dataCols       TEXT[]                 := '{"data_col1", "data_col2", "data_col3", "data_col4",
        "data_col5", "data_col6", "data_col7", "data_col8", "data_col9", "data_col10",
        "data_col11", "data_col12", "data_col13", "data_col14", "data_col15", "data_col16",
        "data_col17", "data_col18", "data_col19", "data_col20", "data_col21", "data_col22",
        "data_col23", "data_col24", "data_col25", "data_col26", "data_col27", "data_col28",
        "data_col29", "data_col30", "data_col31", "data_col32", "data_col33", "data_col34",
        "data_col35", "data_col36", "data_col37", "data_col38", "data_col39", "data_col40",
        "data_col41", "data_col42", "data_col43", "data_col44", "data_col45", "data_col46",
        "data_col47", "data_col48", "data_col49", "data_col50"}';
    rd1              RECORD;
    rd2              RECORD;
    rd3              RECORD;
    v_PrsnID         BIGINT;
    v_OrgID          INTEGER;
    v_Sht_Nm         CHARACTER VARYING(200) := '';
    v_PValID         INTEGER                := -1;
    v_PVal           CHARACTER VARYING(300) := '';
    v_assess_sht_lvl CHARACTER VARYING(300) := '';
    v_Result         TEXT                   := '';
    bid              TEXT                   := 'Report Card Computed Successfully!';
    v_msgs           TEXT                   := chr(10) || 'Report Card Computations About to Start...';
    v_cntr           integer                := 0;
    v_updtMsg        BIGINT                 := 0;
    v_SheetType      CHARACTER VARYING(200) := '';
BEGIN
    v_SheetType := gst.getGnrlRecNm('aca.aca_assessment_types', 'assmnt_typ_id', 'assmnt_type', p_assess_typ_id);
    if (v_SheetType <> 'Summary Report Per Person') then
        RAISE EXCEPTION 'WRONG ASSESSMENT TYPE:%', v_SheetType
            USING HINT = 'WRONG ASSESSMENT TYPE:' || v_SheetType;
    end if;
    v_PrsnID := sec.get_usr_prsn_id(p_who_rn);
    /*v_PValID := COALESCE(gst.getEnbldPssblValID('Default Assessment Sheet Level',
                                                gst.getenbldlovid('All Other Performance Setups')), -1);
    v_PVal := COALESCE(gst.get_pssbl_val_desc(v_PValID), '');
    v_assess_sht_lvl := v_PVal;*/
    if upper(p_create_hdrs) = 'YES' then
        for rd2 in SELECT distinct a.person_id,
                                   prs.get_prsn_loc_id(a.person_id)     prsn_loc_id,
                                   a.class_id,
                                   a.acdmc_period_id,
                                   aca.get_period_nm(a.acdmc_period_id) period_nm,
                                   aca.get_class_nm(a.class_id)         class_nm,
                                   c.org_id,
                                   d.group_fcltr_pos_name,
                                   d.group_rep_pos_name,
                                   d.sbjct_fcltr_pos_name,
                                   d.lnkd_div_id
                   FROM aca.aca_prsns_acdmc_sttngs a,
                        aca.aca_assessment_periods c,
                        aca.aca_classes d
                   WHERE a.acdmc_period_id = p_period_id
                     and c.assmnt_period_id = a.acdmc_period_id
                     and a.class_id = d.class_id
                     and (a.class_id = p_class_id or p_class_id <= 0)
                     and (Select count(y.assess_sheet_hdr_id)
                          from aca.aca_assess_sheet_hdr y
                          where y.class_id = a.class_id
                            and y.assessed_person_id = a.person_id
                            and y.academic_period_id = a.acdmc_period_id
                            and y.assessment_type_id = p_assess_typ_id) <= 0
            loop
                v_Sht_Nm := rd2.prsn_loc_id || '-' || rd2.class_nm || '-' || rd2.period_nm;
                Select count(y.assess_sheet_hdr_id)
                into v_cntr
                from aca.aca_assess_sheet_hdr y
                where upper(y.assess_sheet_name) = upper(v_Sht_Nm);
                v_PrsnID := aca.get_pos_hldr_prs_id(p_period_id, rd2.lnkd_div_id, -1, -1,
                                                    rd2.group_fcltr_pos_name);
                if coalesce(v_PrsnID, -1) <= 0 THEN
                    v_PrsnID := sec.get_usr_prsn_id(p_who_rn);
                end if;
                if (coalesce(v_cntr, 0) <= 0) then
                    v_Result := aca.createAssessShtHdr(rd2.org_id,
                                                       v_Sht_Nm,
                                                       v_Sht_Nm,
                                                       rd2.class_id,
                                                       p_assess_typ_id,
                                                       -1,
                                                       -1,
                                                       v_PrsnID,
                                                       rd2.acdmc_period_id,
                                                       'Open for Editing',
                                                       rd2.person_id,
                                                       p_who_rn);
                end if;
            end loop;
    end if;
    --Loop and Pick all Relevant Values form Header Table
    --Loop through all rows in the sheet including the one with negative sttngs ID
    --Loop though all the columns defined in the linked Assessment Type
    --Get SQL Formula and Execute
    --Update Corresponding Data Column with Result

    FOR rd1 IN SELECT a.class_id,
                      a.assessment_type_id,
                      a.course_id,
                      a.subject_id,
                      a.tutor_person_id,
                      a.academic_period_id,
                      a.org_id,
                      b.dflt_grade_scale_id,
                      b.assmnt_type,
                      b.assmnt_level,
                      b.lnkd_assmnt_typ_id,
                      a.assess_sheet_hdr_id,
                      a.assessed_person_id
               FROM aca.aca_assess_sheet_hdr a,
                    aca.aca_assessment_types b
               WHERE a.assessment_type_id = b.assmnt_typ_id
                 and a.org_id = b.org_id
                 and (a.class_id = p_class_id or p_class_id <= 0)
                 and a.academic_period_id = p_period_id
        LOOP
            v_Result := aca.compute_one_assess_sht(rd1.assess_sheet_hdr_id,
                                                   p_who_rn);
        end loop;

    FOR rd3 IN SELECT a.class_id,
                      a.assessment_type_id,
                      a.course_id,
                      a.subject_id,
                      a.tutor_person_id,
                      a.academic_period_id,
                      a.org_id,
                      b.dflt_grade_scale_id,
                      b.assmnt_type,
                      b.assmnt_level,
                      b.lnkd_assmnt_typ_id,
                      a.assess_sheet_hdr_id,
                      a.assessed_person_id
               FROM aca.aca_assess_sheet_hdr a,
                    aca.aca_assessment_types b
               WHERE a.assessment_type_id = b.assmnt_typ_id
                 and a.org_id = b.org_id
                 and (a.class_id = p_class_id or p_class_id <= 0)
                 and a.academic_period_id = p_period_id
        LOOP
            v_Result := aca.auto_compute_ltc_flds(rd3.assess_sheet_hdr_id,
                                                  p_who_rn);
            if upper(p_shd_close_sht) = 'YES' and UPPER(v_Result) LIKE '%SUCCESS%' then
                UPDATE aca.aca_assess_sheet_hdr
                SET assess_sheet_status='Closed'
                WHERE assess_sheet_hdr_id = rd1.assess_sheet_hdr_id;
            end if;
        end loop;
    RETURN COALESCE('SUCCESS:' || bid, '');
EXCEPTION
    WHEN OTHERS
        THEN
            v_msgs := v_msgs || chr(10) || '' || SQLSTATE || chr(10) || SQLERRM;
            v_updtMsg := rpt.updaterptlogmsg(p_msgid, v_msgs, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn);
            RETURN v_msgs;
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.chckNcreateOrgDivGrp(p_orgid integer,
                                                    p_DivGrp_Nm character varying,
                                                    p_DivGrp_Desc character varying,
                                                    p_DivGrp_Type character varying,
                                                    p_class_id integer,
                                                    p_nxt_class_id integer,
                                                    p_who_rn bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    v_DivTyp_id        integer := -1;
    v_Div_id           integer := -1;
    v_Lnkd_Div_id      integer := -1;
    v_Lnkd_prnt_Div_id integer := -1;
    v_Div_idChck       integer := -1;
BEGIN
    v_Lnkd_Div_id :=
            public.chartonumeric(gst.getGnrlRecNm('aca.aca_classes', 'class_id', 'lnkd_div_id', p_class_id))::INTEGER;
    --v_Lnkd_Div_id :=1/0;
    v_Lnkd_prnt_Div_id := public.chartonumeric(
            gst.getGnrlRecNm('aca.aca_classes', 'class_id', 'lnkd_div_id', p_nxt_class_id))::INTEGER;
    v_Div_idChck := gst.getgnrlrecid1('org.org_divs_groups', 'div_code_name', 'div_id', p_DivGrp_Nm, p_orgid);
    IF v_Div_idChck <= 0 and v_Lnkd_Div_id <= 0 then
        v_Div_id := nextval('org.org_divs_groups_div_id_seq');
        v_DivTyp_id := gst.get_pssbl_val_id(p_DivGrp_Type, gst.get_lov_id('Divisions or Group Types'));
        INSERT INTO org.org_divs_groups(div_id, org_id, div_code_name, div_logo, prnt_div_id, div_typ_id, is_enabled,
                                        created_by, creation_date, last_update_by, last_update_date, div_desc,
                                        extrnl_grp_id, extrnl_grp_type)
        VALUES (v_Div_id, p_orgid, p_DivGrp_Nm, '', v_Lnkd_prnt_Div_id, v_DivTyp_id, '1', p_who_rn,
                to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'),
                p_DivGrp_Desc, p_class_id, 'ACA Class');
        UPDATE aca.aca_classes SET lnkd_div_id = v_Div_id WHERE class_id = p_class_id;
    ELSIF v_Div_idChck > 0 and v_Lnkd_Div_id <= 0 then
        UPDATE aca.aca_classes SET lnkd_div_id = v_Div_idChck WHERE class_id = p_class_id;
    END IF;
    RETURN 'SUCCESS:';
/*EXCEPTION
    WHEN OTHERS
        THEN
            RETURN 'ERROR:' || SQLERRM;*/
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.chckNcreateOrgPosition(p_orgid integer,
                                                      p_Pos_Nm character varying,
                                                      p_Pos_Cmmnts character varying,
                                                      p_prnt_pos_id integer,
                                                      p_who_rn bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    v_Pos_id     integer := -1;
    v_Pos_idChck integer := -1;
BEGIN
    v_Pos_idChck := gst.getgnrlrecid1('org.org_positions', 'position_code_name', 'position_id', p_Pos_Nm, p_orgid);
    IF v_Pos_idChck <= 0 then
        v_Pos_id := nextval('org.org_positions_position_id_seq');
        INSERT INTO org.org_positions(position_id, position_code_name, prnt_position_id, position_comments, is_enabled,
                                      created_by, creation_date, last_update_by, last_update_date, org_id)
        VALUES (v_Pos_id, p_Pos_Nm, p_prnt_pos_id, p_Pos_Cmmnts, '1', p_who_rn,
                to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_orgid);
    end if;
    RETURN 'SUCCESS:';
/*EXCEPTION
    WHEN OTHERS
        THEN
            RETURN 'ERROR:' || SQLERRM;*/
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.createAssessShtHdr(p_orgid integer,
                                                  p_Sht_Nm character varying,
                                                  p_Sht_Desc character varying,
                                                  p_class_id integer,
                                                  p_assess_typ_id integer,
                                                  p_course_id integer,
                                                  p_subject_id integer,
                                                  p_admin_prsn_id bigint,
                                                  p_period_id bigint,
                                                  p_status character varying,
                                                  p_prs_assessed_id bigint,
                                                  p_who_rn bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    v_res        NUMERIC                := 0;
    v_sht_hdr_id BIGINT                 := -1;
    v_SheetType  CHARACTER VARYING(200) := '';
BEGIN
    v_sht_hdr_id := nextval('aca.aca_assess_sheet_hdr_assess_sheet_hdr_id_seq');
    v_SheetType := gst.getGnrlRecNm('aca.aca_assessment_types', 'assmnt_typ_id', 'assmnt_type', p_assess_typ_id);
    INSERT INTO aca.aca_assess_sheet_hdr(assess_sheet_hdr_id, assess_sheet_name, class_id, assessment_type_id,
                                         course_id, subject_id, tutor_person_id, created_by, creation_date,
                                         last_update_by, last_update_date, academic_period_id, org_id,
                                         assess_sheet_desc, assess_sheet_status, assessed_person_id)
    VALUES (v_sht_hdr_id, p_Sht_Nm, p_class_id, p_assess_typ_id, p_course_id, p_subject_id,
            p_admin_prsn_id, p_who_rn,
            to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'),
            p_period_id, p_orgid, p_Sht_Desc, p_status, p_prs_assessed_id);
    if (v_SheetType = 'Assessment Sheet Per Group') then
        INSERT INTO aca.aca_assmnt_col_vals(acdmc_sttngs_id, assess_sheet_hdr_id, data_col1,
                                            data_col2, data_col3, data_col4, data_col5, data_col6, data_col7, data_col8,
                                            data_col9, data_col10, data_col11, data_col12, data_col13, data_col14,
                                            data_col15,
                                            data_col16, data_col17, data_col18, data_col19, data_col20, data_col21,
                                            data_col22,
                                            data_col23, data_col24, data_col25, data_col26, data_col27, data_col28,
                                            data_col29,
                                            data_col30, data_col31, data_col32, data_col33, data_col34, data_col35,
                                            data_col36,
                                            data_col37, data_col38, data_col39, data_col40, data_col41, data_col42,
                                            data_col43,
                                            data_col44, data_col45, data_col46, data_col47, data_col48, data_col49,
                                            data_col50,
                                            created_by, creation_date, last_update_by, last_update_date)
        select tbl1.acdmc_sttngs_id
             , tbl1.assess_sheet_hdr_id
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , p_who_rn
             , to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
             , p_who_rn
             , to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
        from (SELECT a.assess_sheet_hdr_id,
                     a.assess_sheet_name,
                     a.assess_sheet_desc,
                     b.acdmc_sttngs_id,
                     b.person_id,
                     a.class_id,
                     a.assessment_type_id,
                     a.course_id,
                     a.subject_id,
                     a.tutor_person_id,
                     a.academic_period_id,
                     a.org_id
              FROM aca.aca_assess_sheet_hdr a,
                   aca.aca_prsns_acdmc_sttngs b,
                   aca.aca_prsns_ac_sttngs_sbjcts c
              where a.class_id = b.class_id
                and a.academic_period_id = b.acdmc_period_id
                and a.course_id = b.course_id
                and c.acdmc_sttngs_id = b.acdmc_sttngs_id
                and c.subject_id = a.subject_id
                and a.assess_sheet_hdr_id = v_sht_hdr_id) tbl1
        where tbl1.acdmc_sttngs_id NOT IN
              (Select z.acdmc_sttngs_id
               from aca.aca_assmnt_col_vals z
               where z.assess_sheet_hdr_id = tbl1.assess_sheet_hdr_id);

        INSERT INTO aca.aca_assmnt_col_vals(acdmc_sttngs_id, assess_sheet_hdr_id, data_col1,
                                            data_col2, data_col3, data_col4, data_col5, data_col6, data_col7, data_col8,
                                            data_col9, data_col10, data_col11, data_col12, data_col13, data_col14,
                                            data_col15,
                                            data_col16, data_col17, data_col18, data_col19, data_col20, data_col21,
                                            data_col22,
                                            data_col23, data_col24, data_col25, data_col26, data_col27, data_col28,
                                            data_col29,
                                            data_col30, data_col31, data_col32, data_col33, data_col34, data_col35,
                                            data_col36,
                                            data_col37, data_col38, data_col39, data_col40, data_col41, data_col42,
                                            data_col43,
                                            data_col44, data_col45, data_col46, data_col47, data_col48, data_col49,
                                            data_col50,
                                            created_by, creation_date, last_update_by, last_update_date)
        select -1
             , tbl1.assess_sheet_hdr_id
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , p_who_rn
             , to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
             , p_who_rn
             , to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
        from (SELECT a.assess_sheet_hdr_id
              FROM aca.aca_assess_sheet_hdr a
              where a.assess_sheet_hdr_id = v_sht_hdr_id) tbl1
        where -1 NOT IN
              (Select z.acdmc_sttngs_id
               from aca.aca_assmnt_col_vals z
               where z.assess_sheet_hdr_id = tbl1.assess_sheet_hdr_id);

        DELETE
        FROM aca.aca_assmnt_col_vals
        WHERE acdmc_sttngs_id > 0
          and assess_sheet_hdr_id = v_sht_hdr_id
          and acdmc_sttngs_id NOT IN (
            select tbl1.acdmc_sttngs_id
            from (SELECT a.assess_sheet_hdr_id,
                         a.assess_sheet_name,
                         a.assess_sheet_desc,
                         b.acdmc_sttngs_id,
                         b.person_id,
                         a.class_id,
                         a.assessment_type_id,
                         a.course_id,
                         a.subject_id,
                         a.tutor_person_id,
                         a.academic_period_id,
                         a.org_id
                  FROM aca.aca_assess_sheet_hdr a,
                       aca.aca_prsns_acdmc_sttngs b,
                       aca.aca_prsns_ac_sttngs_sbjcts c
                  where a.class_id = b.class_id
                    and a.academic_period_id = b.acdmc_period_id
                    and a.course_id = b.course_id
                    and c.acdmc_sttngs_id = b.acdmc_sttngs_id
                    and c.subject_id = a.subject_id
                    and a.assess_sheet_hdr_id = v_sht_hdr_id) tbl1);
    elsif (v_SheetType = 'Summary Report Per Person') then
        INSERT INTO aca.aca_assmnt_col_vals(acdmc_sttngs_id, assess_sheet_hdr_id, data_col1,
                                            data_col2, data_col3, data_col4, data_col5, data_col6, data_col7, data_col8,
                                            data_col9, data_col10, data_col11, data_col12, data_col13, data_col14,
                                            data_col15,
                                            data_col16, data_col17, data_col18, data_col19, data_col20, data_col21,
                                            data_col22,
                                            data_col23, data_col24, data_col25, data_col26, data_col27, data_col28,
                                            data_col29,
                                            data_col30, data_col31, data_col32, data_col33, data_col34, data_col35,
                                            data_col36,
                                            data_col37, data_col38, data_col39, data_col40, data_col41, data_col42,
                                            data_col43,
                                            data_col44, data_col45, data_col46, data_col47, data_col48, data_col49,
                                            data_col50,
                                            created_by, creation_date, last_update_by, last_update_date, course_id,
                                            subject_id)
        select distinct tbl1.acdmc_sttngs_id
                      , tbl1.assess_sheet_hdr_id
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , p_who_rn
                      , to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
                      , p_who_rn
                      , to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
                      , tbl1.course_id
                      , -1
        from (SELECT a.assess_sheet_hdr_id,
                     a.assess_sheet_name,
                     a.assess_sheet_desc,
                     b.acdmc_sttngs_id,
                     b.person_id,
                     a.class_id,
                     a.assessment_type_id,
                     b.course_id,
                     c.subject_id,
                     a.tutor_person_id,
                     a.academic_period_id,
                     a.org_id
              FROM aca.aca_assess_sheet_hdr a,
                   aca.aca_prsns_acdmc_sttngs b,
                   aca.aca_prsns_ac_sttngs_sbjcts c
              where a.class_id = b.class_id
                and a.academic_period_id = b.acdmc_period_id
                and (a.course_id = b.course_id or a.course_id <= 0)
                and (b.course_id = p_course_id or p_course_id <= 0)
                and c.acdmc_sttngs_id = b.acdmc_sttngs_id
                and (c.subject_id = a.subject_id or a.subject_id <= 0)
                and (c.subject_id = p_subject_id or p_subject_id <= 0)
                and a.assessed_person_id = b.person_id
                and a.assess_sheet_hdr_id = v_sht_hdr_id) tbl1
        where tbl1.acdmc_sttngs_id || '_' || tbl1.course_id || '_-1' NOT IN
              (Select z.acdmc_sttngs_id || '_' || z.course_id || '_' || z.subject_id
               from aca.aca_assmnt_col_vals z
               where z.assess_sheet_hdr_id = tbl1.assess_sheet_hdr_id);

        INSERT INTO aca.aca_assmnt_col_vals(acdmc_sttngs_id, assess_sheet_hdr_id, data_col1,
                                            data_col2, data_col3, data_col4, data_col5, data_col6, data_col7, data_col8,
                                            data_col9, data_col10, data_col11, data_col12, data_col13, data_col14,
                                            data_col15,
                                            data_col16, data_col17, data_col18, data_col19, data_col20, data_col21,
                                            data_col22,
                                            data_col23, data_col24, data_col25, data_col26, data_col27, data_col28,
                                            data_col29,
                                            data_col30, data_col31, data_col32, data_col33, data_col34, data_col35,
                                            data_col36,
                                            data_col37, data_col38, data_col39, data_col40, data_col41, data_col42,
                                            data_col43,
                                            data_col44, data_col45, data_col46, data_col47, data_col48, data_col49,
                                            data_col50,
                                            created_by, creation_date, last_update_by, last_update_date, course_id,
                                            subject_id)
        select distinct tbl1.acdmc_sttngs_id
                      , tbl1.assess_sheet_hdr_id
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , p_who_rn
                      , to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
                      , p_who_rn
                      , to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
                      , tbl1.course_id
                      , tbl1.subject_id
        from (SELECT a.assess_sheet_hdr_id,
                     a.assess_sheet_name,
                     a.assess_sheet_desc,
                     b.acdmc_sttngs_id,
                     b.person_id,
                     a.class_id,
                     a.assessment_type_id,
                     b.course_id,
                     c.subject_id,
                     a.tutor_person_id,
                     a.academic_period_id,
                     a.org_id
              FROM aca.aca_assess_sheet_hdr a,
                   aca.aca_prsns_acdmc_sttngs b,
                   aca.aca_prsns_ac_sttngs_sbjcts c
              where a.class_id = b.class_id
                and a.academic_period_id = b.acdmc_period_id
                and (a.course_id = b.course_id or a.course_id <= 0)
                and (b.course_id = p_course_id or p_course_id <= 0)
                and c.acdmc_sttngs_id = b.acdmc_sttngs_id
                and (c.subject_id = a.subject_id or a.subject_id <= 0)
                and (c.subject_id = p_subject_id or p_subject_id <= 0)
                and a.assessed_person_id = b.person_id
                and a.assess_sheet_hdr_id = v_sht_hdr_id) tbl1
        where tbl1.acdmc_sttngs_id || '_' || tbl1.course_id || '_' || tbl1.subject_id NOT IN
              (Select z.acdmc_sttngs_id || '_' || z.course_id || '_' || z.subject_id
               from aca.aca_assmnt_col_vals z
               where z.assess_sheet_hdr_id = tbl1.assess_sheet_hdr_id);
--Create Header Footer
        INSERT INTO aca.aca_assmnt_col_vals(acdmc_sttngs_id, assess_sheet_hdr_id, data_col1,
                                            data_col2, data_col3, data_col4, data_col5, data_col6, data_col7, data_col8,
                                            data_col9, data_col10, data_col11, data_col12, data_col13, data_col14,
                                            data_col15,
                                            data_col16, data_col17, data_col18, data_col19, data_col20, data_col21,
                                            data_col22,
                                            data_col23, data_col24, data_col25, data_col26, data_col27, data_col28,
                                            data_col29,
                                            data_col30, data_col31, data_col32, data_col33, data_col34, data_col35,
                                            data_col36,
                                            data_col37, data_col38, data_col39, data_col40, data_col41, data_col42,
                                            data_col43,
                                            data_col44, data_col45, data_col46, data_col47, data_col48, data_col49,
                                            data_col50,
                                            created_by, creation_date, last_update_by, last_update_date)
        select -1
             , tbl1.assess_sheet_hdr_id
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , p_who_rn
             , to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
             , p_who_rn
             , to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
        from (SELECT a.assess_sheet_hdr_id
              FROM aca.aca_assess_sheet_hdr a
              where a.assess_sheet_hdr_id = v_sht_hdr_id) tbl1
        where -1 NOT IN
              (Select z.acdmc_sttngs_id
               from aca.aca_assmnt_col_vals z
               where z.assess_sheet_hdr_id = tbl1.assess_sheet_hdr_id);
--Delete Unqualified Records
        DELETE
        FROM aca.aca_assmnt_col_vals
        WHERE acdmc_sttngs_id > 0
          and subject_id > 0
          and assess_sheet_hdr_id = v_sht_hdr_id
          and acdmc_sttngs_id || '_' || course_id || '_' || subject_id NOT IN (
            select tbl1.acdmc_sttngs_id || '_' || tbl1.course_id || '_' || tbl1.subject_id
            from (SELECT a.assess_sheet_hdr_id,
                         a.assess_sheet_name,
                         a.assess_sheet_desc,
                         b.acdmc_sttngs_id,
                         b.person_id,
                         a.class_id,
                         a.assessment_type_id,
                         b.course_id,
                         c.subject_id,
                         a.tutor_person_id,
                         a.academic_period_id,
                         a.org_id
                  FROM aca.aca_assess_sheet_hdr a,
                       aca.aca_prsns_acdmc_sttngs b,
                       aca.aca_prsns_ac_sttngs_sbjcts c
                  where a.class_id = b.class_id
                    and a.academic_period_id = b.acdmc_period_id
                    and (a.course_id = b.course_id or a.course_id <= 0)
                    and (b.course_id = p_course_id or p_course_id <= 0)
                    and c.acdmc_sttngs_id = b.acdmc_sttngs_id
                    and (c.subject_id = a.subject_id or a.subject_id <= 0)
                    and (c.subject_id = p_subject_id or p_subject_id <= 0)
                    and a.assessed_person_id = b.person_id
                    and a.assess_sheet_hdr_id = v_sht_hdr_id) tbl1);

        DELETE
        FROM aca.aca_assmnt_col_vals
        WHERE acdmc_sttngs_id > 0
          and subject_id <= 0
          and assess_sheet_hdr_id = v_sht_hdr_id
          and acdmc_sttngs_id || '_' || course_id || '_-1' NOT IN (
            select tbl1.acdmc_sttngs_id || '_' || tbl1.course_id || '_-1'
            from (SELECT a.assess_sheet_hdr_id,
                         a.assess_sheet_name,
                         a.assess_sheet_desc,
                         b.acdmc_sttngs_id,
                         b.person_id,
                         a.class_id,
                         a.assessment_type_id,
                         b.course_id,
                         c.subject_id,
                         a.tutor_person_id,
                         a.academic_period_id,
                         a.org_id
                  FROM aca.aca_assess_sheet_hdr a,
                       aca.aca_prsns_acdmc_sttngs b,
                       aca.aca_prsns_ac_sttngs_sbjcts c
                  where a.class_id = b.class_id
                    and a.academic_period_id = b.acdmc_period_id
                    and (a.course_id = b.course_id or a.course_id <= 0)
                    and (b.course_id = p_course_id or p_course_id <= 0)
                    and c.acdmc_sttngs_id = b.acdmc_sttngs_id
                    and (c.subject_id = a.subject_id or a.subject_id <= 0)
                    and (c.subject_id = p_subject_id or p_subject_id <= 0)
                    and a.assessed_person_id = b.person_id
                    and a.assess_sheet_hdr_id = v_sht_hdr_id) tbl1);
    end if;
    RETURN 'SUCCESS:';
EXCEPTION
    WHEN OTHERS
        THEN
            RETURN 'ERROR:' || SQLERRM;
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.updtAssessShtHdr(p_sht_hdr_id bigint,
                                                p_Sht_Nm character varying,
                                                p_Sht_Desc character varying,
                                                p_class_id integer,
                                                p_assess_typ_id integer,
                                                p_course_id integer,
                                                p_subject_id integer,
                                                p_admin_prsn_id bigint,
                                                p_period_id bigint,
                                                p_status character varying,
                                                p_prs_assessed_id bigint,
                                                p_who_rn bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    v_res        NUMERIC                := 0;
    v_sht_hdr_id BIGINT                 := -1;
    v_SheetType  CHARACTER VARYING(200) := '';
BEGIN
    v_sht_hdr_id := p_sht_hdr_id;
    v_SheetType := gst.getGnrlRecNm('aca.aca_assessment_types', 'assmnt_typ_id', 'assmnt_type', p_assess_typ_id);
    UPDATE aca.aca_assess_sheet_hdr
    SET assess_sheet_name  = p_Sht_Nm,
        assess_sheet_desc=p_Sht_Desc,
        class_id=p_class_id,
        assessment_type_id=p_assess_typ_id,
        course_id=p_course_id,
        subject_id=p_subject_id,
        tutor_person_id=p_admin_prsn_id,
        academic_period_id=p_period_id,
        last_update_by     = p_who_rn,
        last_update_date   = to_char(now(), 'YYYY-MM-DD HH24:MI:SS'),
        assess_sheet_status=p_status,
        assessed_person_id=p_prs_assessed_id
    WHERE assess_sheet_hdr_id = v_sht_hdr_id;
    if (v_SheetType = 'Assessment Sheet Per Group') then
        INSERT INTO aca.aca_assmnt_col_vals(acdmc_sttngs_id, assess_sheet_hdr_id, data_col1,
                                            data_col2, data_col3, data_col4, data_col5, data_col6, data_col7, data_col8,
                                            data_col9, data_col10, data_col11, data_col12, data_col13, data_col14,
                                            data_col15,
                                            data_col16, data_col17, data_col18, data_col19, data_col20, data_col21,
                                            data_col22,
                                            data_col23, data_col24, data_col25, data_col26, data_col27, data_col28,
                                            data_col29,
                                            data_col30, data_col31, data_col32, data_col33, data_col34, data_col35,
                                            data_col36,
                                            data_col37, data_col38, data_col39, data_col40, data_col41, data_col42,
                                            data_col43,
                                            data_col44, data_col45, data_col46, data_col47, data_col48, data_col49,
                                            data_col50,
                                            created_by, creation_date, last_update_by, last_update_date)
        select tbl1.acdmc_sttngs_id
             , tbl1.assess_sheet_hdr_id
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , p_who_rn
             , to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
             , p_who_rn
             , to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
        from (SELECT a.assess_sheet_hdr_id,
                     a.assess_sheet_name,
                     a.assess_sheet_desc,
                     b.acdmc_sttngs_id,
                     b.person_id,
                     a.class_id,
                     a.assessment_type_id,
                     a.course_id,
                     a.subject_id,
                     a.tutor_person_id,
                     a.academic_period_id,
                     a.org_id
              FROM aca.aca_assess_sheet_hdr a,
                   aca.aca_prsns_acdmc_sttngs b,
                   aca.aca_prsns_ac_sttngs_sbjcts c
              where a.class_id = b.class_id
                and a.academic_period_id = b.acdmc_period_id
                and a.course_id = b.course_id
                and c.acdmc_sttngs_id = b.acdmc_sttngs_id
                and c.subject_id = a.subject_id
                and a.assess_sheet_hdr_id = v_sht_hdr_id) tbl1
        where tbl1.acdmc_sttngs_id NOT IN
              (Select z.acdmc_sttngs_id
               from aca.aca_assmnt_col_vals z
               where z.assess_sheet_hdr_id = tbl1.assess_sheet_hdr_id);

        INSERT INTO aca.aca_assmnt_col_vals(acdmc_sttngs_id, assess_sheet_hdr_id, data_col1,
                                            data_col2, data_col3, data_col4, data_col5, data_col6, data_col7, data_col8,
                                            data_col9, data_col10, data_col11, data_col12, data_col13, data_col14,
                                            data_col15,
                                            data_col16, data_col17, data_col18, data_col19, data_col20, data_col21,
                                            data_col22,
                                            data_col23, data_col24, data_col25, data_col26, data_col27, data_col28,
                                            data_col29,
                                            data_col30, data_col31, data_col32, data_col33, data_col34, data_col35,
                                            data_col36,
                                            data_col37, data_col38, data_col39, data_col40, data_col41, data_col42,
                                            data_col43,
                                            data_col44, data_col45, data_col46, data_col47, data_col48, data_col49,
                                            data_col50,
                                            created_by, creation_date, last_update_by, last_update_date)
        select -1
             , tbl1.assess_sheet_hdr_id
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , p_who_rn
             , to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
             , p_who_rn
             , to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
        from (SELECT a.assess_sheet_hdr_id
              FROM aca.aca_assess_sheet_hdr a
              where a.assess_sheet_hdr_id = v_sht_hdr_id) tbl1
        where -1 NOT IN
              (Select z.acdmc_sttngs_id
               from aca.aca_assmnt_col_vals z
               where z.assess_sheet_hdr_id = tbl1.assess_sheet_hdr_id);

        DELETE
        FROM aca.aca_assmnt_col_vals
        WHERE acdmc_sttngs_id > 0
          and assess_sheet_hdr_id = v_sht_hdr_id
          and acdmc_sttngs_id NOT IN (
            select tbl1.acdmc_sttngs_id
            from (SELECT a.assess_sheet_hdr_id,
                         a.assess_sheet_name,
                         a.assess_sheet_desc,
                         b.acdmc_sttngs_id,
                         b.person_id,
                         a.class_id,
                         a.assessment_type_id,
                         a.course_id,
                         a.subject_id,
                         a.tutor_person_id,
                         a.academic_period_id,
                         a.org_id
                  FROM aca.aca_assess_sheet_hdr a,
                       aca.aca_prsns_acdmc_sttngs b,
                       aca.aca_prsns_ac_sttngs_sbjcts c
                  where a.class_id = b.class_id
                    and a.academic_period_id = b.acdmc_period_id
                    and a.course_id = b.course_id
                    and c.acdmc_sttngs_id = b.acdmc_sttngs_id
                    and c.subject_id = a.subject_id
                    and a.assess_sheet_hdr_id = v_sht_hdr_id) tbl1);
    elsif (v_SheetType = 'Summary Report Per Person') then
        INSERT INTO aca.aca_assmnt_col_vals(acdmc_sttngs_id, assess_sheet_hdr_id, data_col1,
                                            data_col2, data_col3, data_col4, data_col5, data_col6, data_col7, data_col8,
                                            data_col9, data_col10, data_col11, data_col12, data_col13, data_col14,
                                            data_col15,
                                            data_col16, data_col17, data_col18, data_col19, data_col20, data_col21,
                                            data_col22,
                                            data_col23, data_col24, data_col25, data_col26, data_col27, data_col28,
                                            data_col29,
                                            data_col30, data_col31, data_col32, data_col33, data_col34, data_col35,
                                            data_col36,
                                            data_col37, data_col38, data_col39, data_col40, data_col41, data_col42,
                                            data_col43,
                                            data_col44, data_col45, data_col46, data_col47, data_col48, data_col49,
                                            data_col50,
                                            created_by, creation_date, last_update_by, last_update_date, course_id,
                                            subject_id)
        select distinct tbl1.acdmc_sttngs_id
                      , tbl1.assess_sheet_hdr_id
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , p_who_rn
                      , to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
                      , p_who_rn
                      , to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
                      , tbl1.course_id
                      , -1
        from (SELECT a.assess_sheet_hdr_id,
                     a.assess_sheet_name,
                     a.assess_sheet_desc,
                     b.acdmc_sttngs_id,
                     b.person_id,
                     a.class_id,
                     a.assessment_type_id,
                     b.course_id,
                     c.subject_id,
                     a.tutor_person_id,
                     a.academic_period_id,
                     a.org_id
              FROM aca.aca_assess_sheet_hdr a,
                   aca.aca_prsns_acdmc_sttngs b,
                   aca.aca_prsns_ac_sttngs_sbjcts c
              where a.class_id = b.class_id
                and a.academic_period_id = b.acdmc_period_id
                and (a.course_id = b.course_id or a.course_id <= 0)
                and (b.course_id = p_course_id or p_course_id <= 0)
                and c.acdmc_sttngs_id = b.acdmc_sttngs_id
                and (c.subject_id = a.subject_id or a.subject_id <= 0)
                and (c.subject_id = p_subject_id or p_subject_id <= 0)
                and a.assessed_person_id = b.person_id
                and a.assess_sheet_hdr_id = v_sht_hdr_id) tbl1
        where tbl1.acdmc_sttngs_id || '_' || tbl1.course_id || '_-1' NOT IN
              (Select z.acdmc_sttngs_id || '_' || z.course_id || '_' || z.subject_id
               from aca.aca_assmnt_col_vals z
               where z.assess_sheet_hdr_id = tbl1.assess_sheet_hdr_id);

        INSERT INTO aca.aca_assmnt_col_vals(acdmc_sttngs_id, assess_sheet_hdr_id, data_col1,
                                            data_col2, data_col3, data_col4, data_col5, data_col6, data_col7, data_col8,
                                            data_col9, data_col10, data_col11, data_col12, data_col13, data_col14,
                                            data_col15,
                                            data_col16, data_col17, data_col18, data_col19, data_col20, data_col21,
                                            data_col22,
                                            data_col23, data_col24, data_col25, data_col26, data_col27, data_col28,
                                            data_col29,
                                            data_col30, data_col31, data_col32, data_col33, data_col34, data_col35,
                                            data_col36,
                                            data_col37, data_col38, data_col39, data_col40, data_col41, data_col42,
                                            data_col43,
                                            data_col44, data_col45, data_col46, data_col47, data_col48, data_col49,
                                            data_col50,
                                            created_by, creation_date, last_update_by, last_update_date, course_id,
                                            subject_id)
        select distinct tbl1.acdmc_sttngs_id
                      , tbl1.assess_sheet_hdr_id
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , ''
                      , p_who_rn
                      , to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
                      , p_who_rn
                      , to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
                      , tbl1.course_id
                      , tbl1.subject_id
        from (SELECT a.assess_sheet_hdr_id,
                     a.assess_sheet_name,
                     a.assess_sheet_desc,
                     b.acdmc_sttngs_id,
                     b.person_id,
                     a.class_id,
                     a.assessment_type_id,
                     b.course_id,
                     c.subject_id,
                     a.tutor_person_id,
                     a.academic_period_id,
                     a.org_id
              FROM aca.aca_assess_sheet_hdr a,
                   aca.aca_prsns_acdmc_sttngs b,
                   aca.aca_prsns_ac_sttngs_sbjcts c
              where a.class_id = b.class_id
                and a.academic_period_id = b.acdmc_period_id
                and (a.course_id = b.course_id or a.course_id <= 0)
                and (b.course_id = p_course_id or p_course_id <= 0)
                and c.acdmc_sttngs_id = b.acdmc_sttngs_id
                and (c.subject_id = a.subject_id or a.subject_id <= 0)
                and (c.subject_id = p_subject_id or p_subject_id <= 0)
                and a.assessed_person_id = b.person_id
                and a.assess_sheet_hdr_id = v_sht_hdr_id) tbl1
        where tbl1.acdmc_sttngs_id || '_' || tbl1.course_id || '_' || tbl1.subject_id NOT IN
              (Select z.acdmc_sttngs_id || '_' || z.course_id || '_' || z.subject_id
               from aca.aca_assmnt_col_vals z
               where z.assess_sheet_hdr_id = tbl1.assess_sheet_hdr_id);
--Create Header Footer
        INSERT INTO aca.aca_assmnt_col_vals(acdmc_sttngs_id, assess_sheet_hdr_id, data_col1,
                                            data_col2, data_col3, data_col4, data_col5, data_col6, data_col7, data_col8,
                                            data_col9, data_col10, data_col11, data_col12, data_col13, data_col14,
                                            data_col15,
                                            data_col16, data_col17, data_col18, data_col19, data_col20, data_col21,
                                            data_col22,
                                            data_col23, data_col24, data_col25, data_col26, data_col27, data_col28,
                                            data_col29,
                                            data_col30, data_col31, data_col32, data_col33, data_col34, data_col35,
                                            data_col36,
                                            data_col37, data_col38, data_col39, data_col40, data_col41, data_col42,
                                            data_col43,
                                            data_col44, data_col45, data_col46, data_col47, data_col48, data_col49,
                                            data_col50,
                                            created_by, creation_date, last_update_by, last_update_date)
        select -1
             , tbl1.assess_sheet_hdr_id
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , ''
             , p_who_rn
             , to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
             , p_who_rn
             , to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
        from (SELECT a.assess_sheet_hdr_id
              FROM aca.aca_assess_sheet_hdr a
              where a.assess_sheet_hdr_id = v_sht_hdr_id) tbl1
        where -1 NOT IN
              (Select z.acdmc_sttngs_id
               from aca.aca_assmnt_col_vals z
               where z.assess_sheet_hdr_id = tbl1.assess_sheet_hdr_id);
--Delete Unqualified Records
        DELETE
        FROM aca.aca_assmnt_col_vals
        WHERE acdmc_sttngs_id > 0
          and subject_id > 0
          and assess_sheet_hdr_id = v_sht_hdr_id
          and acdmc_sttngs_id || '_' || course_id || '_' || subject_id NOT IN (
            select tbl1.acdmc_sttngs_id || '_' || tbl1.course_id || '_' || tbl1.subject_id
            from (SELECT a.assess_sheet_hdr_id,
                         a.assess_sheet_name,
                         a.assess_sheet_desc,
                         b.acdmc_sttngs_id,
                         b.person_id,
                         a.class_id,
                         a.assessment_type_id,
                         b.course_id,
                         c.subject_id,
                         a.tutor_person_id,
                         a.academic_period_id,
                         a.org_id
                  FROM aca.aca_assess_sheet_hdr a,
                       aca.aca_prsns_acdmc_sttngs b,
                       aca.aca_prsns_ac_sttngs_sbjcts c
                  where a.class_id = b.class_id
                    and a.academic_period_id = b.acdmc_period_id
                    and (a.course_id = b.course_id or a.course_id <= 0)
                    and (b.course_id = p_course_id or p_course_id <= 0)
                    and c.acdmc_sttngs_id = b.acdmc_sttngs_id
                    and (c.subject_id = a.subject_id or a.subject_id <= 0)
                    and (c.subject_id = p_subject_id or p_subject_id <= 0)
                    and a.assessed_person_id = b.person_id
                    and a.assess_sheet_hdr_id = v_sht_hdr_id) tbl1);

        DELETE
        FROM aca.aca_assmnt_col_vals
        WHERE acdmc_sttngs_id > 0
          and subject_id <= 0
          and assess_sheet_hdr_id = v_sht_hdr_id
          and acdmc_sttngs_id || '_' || course_id || '_-1' NOT IN (
            select tbl1.acdmc_sttngs_id || '_' || tbl1.course_id || '_-1'
            from (SELECT a.assess_sheet_hdr_id,
                         a.assess_sheet_name,
                         a.assess_sheet_desc,
                         b.acdmc_sttngs_id,
                         b.person_id,
                         a.class_id,
                         a.assessment_type_id,
                         b.course_id,
                         c.subject_id,
                         a.tutor_person_id,
                         a.academic_period_id,
                         a.org_id
                  FROM aca.aca_assess_sheet_hdr a,
                       aca.aca_prsns_acdmc_sttngs b,
                       aca.aca_prsns_ac_sttngs_sbjcts c
                  where a.class_id = b.class_id
                    and a.academic_period_id = b.acdmc_period_id
                    and (a.course_id = b.course_id or a.course_id <= 0)
                    and (b.course_id = p_course_id or p_course_id <= 0)
                    and c.acdmc_sttngs_id = b.acdmc_sttngs_id
                    and (c.subject_id = a.subject_id or a.subject_id <= 0)
                    and (c.subject_id = p_subject_id or p_subject_id <= 0)
                    and a.assessed_person_id = b.person_id
                    and a.assess_sheet_hdr_id = v_sht_hdr_id) tbl1);
    end if;
    RETURN 'SUCCESS:';
EXCEPTION
    WHEN OTHERS
        THEN
            RETURN 'ERROR:' || SQLERRM;
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.compute_all_assess_shts(p_period_id bigint,
                                                       p_class_id integer,
                                                       p_assess_typ_id integer,
                                                       p_shd_close_sht character varying,
                                                       p_create_hdrs character varying,
                                                       p_who_rn bigint,
                                                       p_msgid BIGINT)
    RETURNS TEXT
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    v_dataCols       TEXT[]                 := '{"data_col1", "data_col2", "data_col3", "data_col4",
        "data_col5", "data_col6", "data_col7", "data_col8", "data_col9", "data_col10",
        "data_col11", "data_col12", "data_col13", "data_col14", "data_col15", "data_col16",
        "data_col17", "data_col18", "data_col19", "data_col20", "data_col21", "data_col22",
        "data_col23", "data_col24", "data_col25", "data_col26", "data_col27", "data_col28",
        "data_col29", "data_col30", "data_col31", "data_col32", "data_col33", "data_col34",
        "data_col35", "data_col36", "data_col37", "data_col38", "data_col39", "data_col40",
        "data_col41", "data_col42", "data_col43", "data_col44", "data_col45", "data_col46",
        "data_col47", "data_col48", "data_col49", "data_col50"}';
    rd1              RECORD;
    rd2              RECORD;
    rd3              RECORD;
    rd4              RECORD;
    v_PrsnID         BIGINT;
    v_Sht_Nm         CHARACTER VARYING(200) := '';
    v_PValID         INTEGER                := -1;
    v_PVal           CHARACTER VARYING(300) := '';
    v_assess_sht_lvl CHARACTER VARYING(300) := '';
    v_OrgID          INTEGER;
    v_Result         TEXT                   := '';
    bid              TEXT                   := 'Assessment Sheet Computed Successfully!';
    v_msgs           TEXT                   := chr(10) || 'Assessment Sheet Computations About to Start...';
    v_cntr           integer                := 0;
    v_updtMsg        BIGINT                 := 0;
    v_SheetType      CHARACTER VARYING(200) := '';
BEGIN
    v_SheetType := gst.getGnrlRecNm('aca.aca_assessment_types', 'assmnt_typ_id', 'assmnt_type', p_assess_typ_id);
    if (v_SheetType <> 'Assessment Sheet Per Group') then
        RAISE EXCEPTION 'WRONG ASSESSMENT TYPE:%', v_SheetType
            USING HINT = 'WRONG ASSESSMENT TYPE:' || v_SheetType;
    end if;
    /*v_PValID := COALESCE(gst.getEnbldPssblValID('Default Assessment Sheet Level',
                                                gst.getenbldlovid('All Other Performance Setups')), -1);
    v_PVal := COALESCE(gst.get_pssbl_val_desc(v_PValID), '');*/
    v_assess_sht_lvl := COALESCE(aca.get_assesstypLevel(p_assess_typ_id), '');
    if upper(v_assess_sht_lvl) = upper('Subject/Target')
        and upper(p_create_hdrs) = upper('Yes') then
        for rd2 in SELECT distinct a.class_id,
                                   a.acdmc_period_id,
                                   a.course_id,
                                   b.subject_id,
                                   aca.get_subjectnm(b.subject_id)      subjectnm,
                                   aca.get_coursenm(a.course_id)        coursenm,
                                   aca.get_period_nm(a.acdmc_period_id) period_nm,
                                   aca.get_class_nm(a.class_id)         class_nm,
                                   c.org_id,
                                   d.group_fcltr_pos_name,
                                   d.group_rep_pos_name,
                                   d.sbjct_fcltr_pos_name,
                                   d.lnkd_div_id
                   FROM aca.aca_prsns_acdmc_sttngs a,
                        aca.aca_prsns_ac_sttngs_sbjcts b,
                        aca.aca_assessment_periods c,
                        aca.aca_classes d
                   WHERE a.acdmc_sttngs_id = b.acdmc_sttngs_id
                     and a.acdmc_period_id = p_period_id
                     and c.assmnt_period_id = a.acdmc_period_id
                     and b.subject_id > 0
                     and a.class_id = d.class_id
                     and (a.class_id = p_class_id or p_class_id <= 0)
                     and (Select count(y.assess_sheet_hdr_id)
                          from aca.aca_assess_sheet_hdr y
                          where y.class_id = a.class_id
                            and y.course_id = a.course_id
                            and y.subject_id = b.subject_id
                            and y.academic_period_id = a.acdmc_period_id
                            and y.assessment_type_id = p_assess_typ_id) <= 0
                     and (Select count(z.assess_sheet_hdr_id)
                          from aca.aca_assess_sheet_hdr z
                          where z.class_id = a.class_id
                            and z.course_id = a.course_id
                            and z.subject_id <= 0
                            and z.academic_period_id = a.acdmc_period_id
                            and z.assessment_type_id = p_assess_typ_id) <= 0
            loop
                v_Sht_Nm := rd2.subjectnm || '-' || rd2.class_nm || '-' || rd2.period_nm;
                Select count(y.assess_sheet_hdr_id)
                into v_cntr
                from aca.aca_assess_sheet_hdr y
                where upper(y.assess_sheet_name) = upper(v_Sht_Nm);
                v_PrsnID := aca.get_pos_hldr_prs_id(p_period_id, rd2.lnkd_div_id, -1, rd2.subject_id,
                                                    rd2.sbjct_fcltr_pos_name);
                if coalesce(v_PrsnID, -1) <= 0 THEN
                    v_PrsnID := sec.get_usr_prsn_id(p_who_rn);
                end if;
                if (coalesce(v_cntr, 0) <= 0) then
                    v_Result := aca.createAssessShtHdr(rd2.org_id,
                                                       v_Sht_Nm,
                                                       v_Sht_Nm,
                                                       rd2.class_id,
                                                       p_assess_typ_id,
                                                       rd2.course_id,
                                                       rd2.subject_id,
                                                       v_PrsnID,
                                                       rd2.acdmc_period_id,
                                                       'Open for Editing',
                                                       -1,
                                                       p_who_rn);
                end if;
            end loop;
    elsif upper(v_assess_sht_lvl) = upper('Course/Objective')
        and upper(p_create_hdrs) = upper('Yes') then
        for rd2 in SELECT distinct a.class_id,
                                   a.acdmc_period_id,
                                   a.course_id,
                                   aca.get_coursenm(a.course_id)        coursenm,
                                   aca.get_period_nm(a.acdmc_period_id) period_nm,
                                   aca.get_class_nm(a.class_id)         class_nm,
                                   c.org_id,
                                   d.group_fcltr_pos_name,
                                   d.group_rep_pos_name,
                                   d.sbjct_fcltr_pos_name,
                                   d.lnkd_div_id
                   FROM aca.aca_prsns_acdmc_sttngs a,
                        aca.aca_assessment_periods c,
                        aca.aca_classes d
                   WHERE a.acdmc_period_id = p_period_id
                     and c.assmnt_period_id = a.acdmc_period_id
                     and a.class_id = d.class_id
                     and (a.class_id = p_class_id or p_class_id <= 0)
                     and (Select count(y.assess_sheet_hdr_id)
                          from aca.aca_assess_sheet_hdr y
                          where y.class_id = a.class_id
                            and y.course_id = a.course_id
                            and y.academic_period_id = a.acdmc_period_id
                            and y.assessment_type_id = p_assess_typ_id) <= 0
            loop
                v_Sht_Nm := rd2.coursenm || '-' || rd2.class_nm || '-' || rd2.period_nm;
                Select count(y.assess_sheet_hdr_id)
                into v_cntr
                from aca.aca_assess_sheet_hdr y
                where upper(y.assess_sheet_name) = upper(v_Sht_Nm);
                v_PrsnID := aca.get_pos_hldr_prs_id(p_period_id, rd2.lnkd_div_id, -1, -1,
                                                    rd2.group_fcltr_pos_name);
                if coalesce(v_PrsnID, -1) <= 0 THEN
                    v_PrsnID := sec.get_usr_prsn_id(p_who_rn);
                end if;

                if (coalesce(v_cntr, 0) <= 0) then
                    v_Result := aca.createAssessShtHdr(rd2.org_id,
                                                       v_Sht_Nm,
                                                       v_Sht_Nm,
                                                       rd2.class_id,
                                                       p_assess_typ_id,
                                                       rd2.course_id,
                                                       -1,
                                                       v_PrsnID,
                                                       rd2.acdmc_period_id,
                                                       'Open for Editing',
                                                       -1,
                                                       p_who_rn);
                end if;
            end loop;
    end if;
    --Loop and Pick all Relevant Values form Header Table
    --Loop through all rows in the sheet including the one with negative sttngs ID
    --Loop though all the columns defined in the linked Assessment Type
    --Get SQL Formula and Execute
    --Update Corresponding Data Column with Result

    FOR rd1 IN SELECT a.class_id,
                      a.assessment_type_id,
                      a.course_id,
                      a.subject_id,
                      a.tutor_person_id,
                      a.academic_period_id,
                      a.org_id,
                      b.dflt_grade_scale_id,
                      b.assmnt_type,
                      b.assmnt_level,
                      b.lnkd_assmnt_typ_id,
                      a.assess_sheet_hdr_id,
                      a.assessed_person_id
               FROM aca.aca_assess_sheet_hdr a,
                    aca.aca_assessment_types b
               WHERE a.assessment_type_id = b.assmnt_typ_id
                 and a.org_id = b.org_id
                 and (a.class_id = p_class_id or p_class_id <= 0)
                 and a.academic_period_id = p_period_id
        LOOP
            v_Result := aca.compute_one_assess_sht(rd1.assess_sheet_hdr_id,
                                                   p_who_rn);
        end loop;

    FOR rd3 IN SELECT a.class_id,
                      a.assessment_type_id,
                      a.course_id,
                      a.subject_id,
                      a.tutor_person_id,
                      a.academic_period_id,
                      a.org_id,
                      b.dflt_grade_scale_id,
                      b.assmnt_type,
                      b.assmnt_level,
                      b.lnkd_assmnt_typ_id,
                      a.assess_sheet_hdr_id,
                      a.assessed_person_id
               FROM aca.aca_assess_sheet_hdr a,
                    aca.aca_assessment_types b
               WHERE a.assessment_type_id = b.assmnt_typ_id
                 and a.org_id = b.org_id
                 and (a.class_id = p_class_id or p_class_id <= 0)
                 and a.academic_period_id = p_period_id
        LOOP
            v_Result := aca.auto_compute_ltc_flds(rd3.assess_sheet_hdr_id,
                                                  p_who_rn);
            if upper(p_shd_close_sht) = 'YES' and UPPER(v_Result) LIKE '%SUCCESS%' then
                UPDATE aca.aca_assess_sheet_hdr
                SET assess_sheet_status='Closed'
                WHERE assess_sheet_hdr_id = rd1.assess_sheet_hdr_id;
            end if;
        end loop;
    RETURN COALESCE('SUCCESS:' || bid, '');
EXCEPTION
    WHEN OTHERS
        THEN
            v_msgs := v_msgs || chr(10) || '' || SQLSTATE || chr(10) || SQLERRM;
            v_updtMsg := rpt.updaterptlogmsg(p_msgid, v_msgs, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn);
            --v_msgs := rpt.getLogMsg(p_msgid);
            RETURN v_msgs;
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.compute_one_assess_sht(p_assess_hdrid bigint,
                                                      p_who_rn bigint)
    RETURNS TEXT
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    bid        TEXT   := 'Assessment Sheet Computed Successfully!';
    v_Tmp_Val  TEXT   := '';
    nwSQL      TEXT   := '';
    v_msgs     TEXT   := '';
    v_dataCols TEXT[] := '{"data_col1", "data_col2", "data_col3", "data_col4",
        "data_col5", "data_col6", "data_col7", "data_col8", "data_col9", "data_col10",
        "data_col11", "data_col12", "data_col13", "data_col14", "data_col15", "data_col16",
        "data_col17", "data_col18", "data_col19", "data_col20", "data_col21", "data_col22",
        "data_col23", "data_col24", "data_col25", "data_col26", "data_col27", "data_col28",
        "data_col29", "data_col30", "data_col31", "data_col32", "data_col33", "data_col34",
        "data_col35", "data_col36", "data_col37", "data_col38", "data_col39", "data_col40",
        "data_col41", "data_col42", "data_col43", "data_col44", "data_col45", "data_col46",
        "data_col47", "data_col48", "data_col49", "data_col50"}';
    rd1        RECORD;
    rd2        RECORD;
    rd3        RECORD;
    rd4        RECORD;
    rd5        RECORD;
BEGIN
    --Loop and Pick and Relevant Values form Header Table
    --Loop through all rows in the sheet including the one with negative sttngs ID
    --Loop though all the columns defined in the linked Assessment Type
    --Get SQL Formula and Execute
    --Update Corresponding Data Column with Result

    FOR rd1 IN SELECT a.class_id,
                      a.assessment_type_id,
                      a.course_id,
                      a.subject_id,
                      a.tutor_person_id,
                      a.academic_period_id,
                      a.org_id,
                      b.dflt_grade_scale_id,
                      b.assmnt_type,
                      b.assmnt_level,
                      b.lnkd_assmnt_typ_id,
                      a.assess_sheet_hdr_id,
                      a.assessed_person_id
               FROM aca.aca_assess_sheet_hdr a,
                    aca.aca_assessment_types b
               WHERE a.assessment_type_id = b.assmnt_typ_id
                 and a.org_id = b.org_id
                 and a.assess_sheet_hdr_id = p_assess_hdrid
        LOOP
            for rd3 in select d.column_no, d.is_formula_column, d.column_formular
                       from aca.aca_assessment_columns d
                       where d.assmnt_typ_id = rd1.assessment_type_id
                         and d.section_located In ('02-Detail')
                         and d.data_type NOT IN ('LastToCompute')
                         and d.is_formula_column = '1'
                       order by d.column_name
                loop
                    for rd2 IN select c.ass_col_val_id, c.acdmc_sttngs_id, c.course_id, c.subject_id
                               from aca.aca_assmnt_col_vals c
                               where c.assess_sheet_hdr_id = rd1.assess_sheet_hdr_id
                                 and c.acdmc_sttngs_id > 0
                               order by acdmc_sttngs_id ASC
                        loop
                            v_Tmp_Val := aca.exct_col_valsql(rd3.column_formular,
                                                             rd1.assess_sheet_hdr_id,
                                                             rd2.acdmc_sttngs_id,
                                                             rd3.column_no,
                                                             rd1.dflt_grade_scale_id,
                                                             rd2.course_id,
                                                             rd2.subject_id,
                                                             rd1.class_id,
                                                             rd1.academic_period_id);
                            nwSQL := 'UPDATE aca.aca_assmnt_col_vals ' ||
                                     ' SET ' || v_dataCols[rd3.column_no] ||
                                     ' = ''' || v_Tmp_Val || ''', last_update_by=' || p_who_rn ||
                                     ', last_update_date = to_char(now(),''YYYY-MM-DD HH24:MI:SS'') where ass_col_val_id=' ||
                                     rd2.ass_col_val_id;
                            EXECUTE nwSQL;
                        end loop;
                end loop;

            for rd5 IN select c.ass_col_val_id, c.acdmc_sttngs_id, c.course_id, c.subject_id
                       from aca.aca_assmnt_col_vals c
                       where c.assess_sheet_hdr_id = rd1.assess_sheet_hdr_id
                         and c.acdmc_sttngs_id <= 0
                loop
                    for rd4 in select d.column_no, d.is_formula_column, d.column_formular
                               from aca.aca_assessment_columns d
                               where d.assmnt_typ_id = rd1.assessment_type_id
                                 and d.section_located In ('01-Header', '03-Footer')
                                 and d.data_type NOT IN ('LastToCompute')
                                 and d.is_formula_column = '1'
                               order by d.section_located, d.column_name
                        loop
                            v_Tmp_Val := aca.exct_col_valsql(rd4.column_formular,
                                                             rd1.assess_sheet_hdr_id,
                                                             rd5.acdmc_sttngs_id,
                                                             rd4.column_no,
                                                             rd1.dflt_grade_scale_id,
                                                             rd5.course_id,
                                                             rd5.subject_id,
                                                             rd1.class_id,
                                                             rd1.academic_period_id);
                            nwSQL := 'UPDATE aca.aca_assmnt_col_vals ' ||
                                     ' SET ' || v_dataCols[rd4.column_no] ||
                                     ' = ''' || v_Tmp_Val || ''', last_update_by=' || p_who_rn ||
                                     ', last_update_date = to_char(now(),''YYYY-MM-DD HH24:MI:SS'') where ass_col_val_id=' ||
                                     rd5.ass_col_val_id;
                            /*RAISE EXCEPTION 'MIN-MAX ERROR:%', nwSQL
                                USING HINT = nwSQL;*/
                            EXECUTE nwSQL;
                        end loop;
                end loop;
        end loop;
    RETURN COALESCE('SUCCESS:' || bid, '');
EXCEPTION
    WHEN OTHERS
        THEN
            v_msgs := v_msgs || chr(10) || '' || SQLSTATE || chr(10) || SQLERRM;
            RETURN v_msgs;
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.auto_compute_ltc_flds(p_assess_hdrid bigint,
                                                     p_who_rn bigint)
    RETURNS TEXT
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    bid        TEXT   := 'Last-To-Compute Fields Computed Successfully!';
    v_Tmp_Val  TEXT   := '';
    nwSQL      TEXT   := '';
    v_msgs     TEXT   := '';
    v_dataCols TEXT[] := '{"data_col1", "data_col2", "data_col3", "data_col4",
        "data_col5", "data_col6", "data_col7", "data_col8", "data_col9", "data_col10",
        "data_col11", "data_col12", "data_col13", "data_col14", "data_col15", "data_col16",
        "data_col17", "data_col18", "data_col19", "data_col20", "data_col21", "data_col22",
        "data_col23", "data_col24", "data_col25", "data_col26", "data_col27", "data_col28",
        "data_col29", "data_col30", "data_col31", "data_col32", "data_col33", "data_col34",
        "data_col35", "data_col36", "data_col37", "data_col38", "data_col39", "data_col40",
        "data_col41", "data_col42", "data_col43", "data_col44", "data_col45", "data_col46",
        "data_col47", "data_col48", "data_col49", "data_col50"}';
    rd1        RECORD;
    rd2        RECORD;
    rd3        RECORD;
    rd4        RECORD;
    rd5        RECORD;
BEGIN
    --Loop and Pick and Relevant Values form Header Table
    --Loop through all rows in the sheet including the one with negative sttngs ID
    --Loop though all the columns defined in the linked Assessment Type
    --Get SQL Formula and Execute
    --Update Corresponding Data Column with Result

    FOR rd1 IN SELECT a.class_id,
                      a.assessment_type_id,
                      a.course_id,
                      a.subject_id,
                      a.tutor_person_id,
                      a.academic_period_id,
                      a.org_id,
                      b.dflt_grade_scale_id,
                      b.assmnt_type,
                      b.assmnt_level,
                      b.lnkd_assmnt_typ_id,
                      a.assess_sheet_hdr_id,
                      a.assessed_person_id
               FROM aca.aca_assess_sheet_hdr a,
                    aca.aca_assessment_types b
               WHERE a.assessment_type_id = b.assmnt_typ_id
                 and a.org_id = b.org_id
                 and a.assess_sheet_hdr_id = p_assess_hdrid
        LOOP
            for rd3 in select d.column_no, d.is_formula_column, d.column_formular
                       from aca.aca_assessment_columns d
                       where d.assmnt_typ_id = rd1.assessment_type_id
                         and d.section_located In ('02-Detail')
                         and d.data_type = 'LastToCompute'
                         and d.is_formula_column = '1'
                       order by d.column_name
                loop
                    for rd2 IN select c.ass_col_val_id, c.acdmc_sttngs_id, c.course_id, c.subject_id
                               from aca.aca_assmnt_col_vals c
                               where c.assess_sheet_hdr_id = rd1.assess_sheet_hdr_id
                                 and c.acdmc_sttngs_id > 0
                               order by acdmc_sttngs_id ASC
                        loop
                            v_Tmp_Val := aca.exct_col_valsql(rd3.column_formular,
                                                             rd1.assess_sheet_hdr_id,
                                                             rd2.acdmc_sttngs_id,
                                                             rd3.column_no,
                                                             rd1.dflt_grade_scale_id,
                                                             rd2.course_id,
                                                             rd2.subject_id,
                                                             rd1.class_id,
                                                             rd1.academic_period_id);
                            nwSQL := 'UPDATE aca.aca_assmnt_col_vals ' ||
                                     ' SET ' || v_dataCols[rd3.column_no] ||
                                     ' = ''' || v_Tmp_Val || ''', last_update_by=' || p_who_rn ||
                                     ', last_update_date = to_char(now(),''YYYY-MM-DD HH24:MI:SS'') where ass_col_val_id=' ||
                                     rd2.ass_col_val_id;
                            EXECUTE nwSQL;
                        end loop;
                end loop;

            for rd5 IN select c.ass_col_val_id, c.acdmc_sttngs_id, c.course_id, c.subject_id
                       from aca.aca_assmnt_col_vals c
                       where c.assess_sheet_hdr_id = rd1.assess_sheet_hdr_id
                         and c.acdmc_sttngs_id <= 0
                loop
                    for rd4 in select d.column_no, d.is_formula_column, d.column_formular
                               from aca.aca_assessment_columns d
                               where d.assmnt_typ_id = rd1.assessment_type_id
                                 and d.section_located In ('01-Header', '03-Footer')
                                 and d.data_type = 'LastToCompute'
                                 and d.is_formula_column = '1'
                               order by d.section_located, d.column_name
                        loop
                            v_Tmp_Val := aca.exct_col_valsql(rd4.column_formular,
                                                             rd1.assess_sheet_hdr_id,
                                                             rd5.acdmc_sttngs_id,
                                                             rd4.column_no,
                                                             rd1.dflt_grade_scale_id,
                                                             rd5.course_id,
                                                             rd5.subject_id,
                                                             rd1.class_id,
                                                             rd1.academic_period_id);
                            nwSQL := 'UPDATE aca.aca_assmnt_col_vals ' ||
                                     ' SET ' || v_dataCols[rd4.column_no] ||
                                     ' = ''' || v_Tmp_Val || ''', last_update_by=' || p_who_rn ||
                                     ', last_update_date = to_char(now(),''YYYY-MM-DD HH24:MI:SS'') where ass_col_val_id=' ||
                                     rd5.ass_col_val_id;
                            /*RAISE EXCEPTION 'MIN-MAX ERROR:%', nwSQL
                                USING HINT = nwSQL;*/
                            EXECUTE nwSQL;
                        end loop;
                end loop;
        end loop;
    RETURN COALESCE('SUCCESS:' || bid, '');
EXCEPTION
    WHEN OTHERS
        THEN
            v_msgs := v_msgs || chr(10) || '' || SQLSTATE || chr(10) || SQLERRM;
            RETURN v_msgs;
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.exct_col_valsql(p_colsql TEXT,
                                               p_assess_hdrid bigint,
                                               p_aca_sttng_id bigint,
                                               p_columnNo integer,
                                               p_grade_scale_id integer,
                                               p_prgrme_objctv_id integer,
                                               p_subject_task_id integer,
                                               p_class_id integer,
                                               p_period_id bigint)
    RETURNS TEXT
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    bid   TEXT := '';
    nwSQL TEXT := '';
BEGIN
    nwSQL := REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                                                                     REPLACE(p_colsql, '{:p_assess_sht_hdr_id}', '' || p_assess_hdrid),
                                                                     '{:p_aca_sttng_id}', '' || p_aca_sttng_id),
                                                             '{:p_data_col_number}', '' || p_columnNo),
                                                     '{:p_grade_scale_id}', '' || p_grade_scale_id),
                                             '{:p_prgrme_objctv_id}', '' || p_prgrme_objctv_id),
                                     '{:p_subject_task_id}', '' || p_subject_task_id),
                             '{:p_class_id}', '' || p_class_id),
                     '{:p_period_id}', '' || p_period_id);
    --RAISE NOTICE 'Query SQL = "%"', nwSQL;
    --RAISE NOTICE 'Query itemSQL = "%"', itemSQL;
    EXECUTE nwSQL
        INTO bid;
    RETURN REPLACE(COALESCE(bid, ''), '''', '''''');
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_assess_sht_vals(p_assess_hdrid bigint,
                                                   p_columnNo integer)
    RETURNS TABLE
            (
                assess_col_id     bigint,
                assess_sht_hdr_id bigint,
                acdmc_sttngs_id   bigint,
                assess_score      numeric
            )
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
    ROWS 1000
AS
$BODY$
<< outerblock >>
    DECLARE
    v_SQL      TEXT   := '';
    v_dataCols TEXT[] := '{"data_col1", "data_col2", "data_col3", "data_col4",
        "data_col5", "data_col6", "data_col7", "data_col8", "data_col9", "data_col10",
        "data_col11", "data_col12", "data_col13", "data_col14", "data_col15", "data_col16",
        "data_col17", "data_col18", "data_col19", "data_col20", "data_col21", "data_col22",
        "data_col23", "data_col24", "data_col25", "data_col26", "data_col27", "data_col28",
        "data_col29", "data_col30", "data_col31", "data_col32", "data_col33", "data_col34",
        "data_col35", "data_col36", "data_col37", "data_col38", "data_col39", "data_col40",
        "data_col41", "data_col42", "data_col43", "data_col44", "data_col45", "data_col46",
        "data_col47", "data_col48", "data_col49", "data_col50"}';
BEGIN
    v_SQL :=
                            'SELECT ass_col_val_id assess_col_id, assess_sheet_hdr_id assess_sht_hdr_id, acdmc_sttngs_id, public.chartonumeric(' ||
                            v_dataCols[p_columnNo] ||
                            ') assess_score FROM aca.aca_assmnt_col_vals a WHERE ((assess_sheet_hdr_id = ' ||
                            p_assess_hdrid || ' and acdmc_sttngs_id >0))';
    RETURN QUERY
        EXECUTE v_SQL;
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_rpt_card_vals(p_class_id integer,
                                                 p_period_id bigint,
                                                 p_columnNo integer)
    RETURNS TABLE
            (
                assess_col_id     bigint,
                assess_sht_hdr_id bigint,
                acdmc_sttngs_id   bigint,
                assess_score      numeric
            )
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
    ROWS 1000
AS
$BODY$
<< outerblock >>
    DECLARE
    v_SQL      TEXT   := '';
    v_dataCols TEXT[] := '{"data_col1", "data_col2", "data_col3", "data_col4",
        "data_col5", "data_col6", "data_col7", "data_col8", "data_col9", "data_col10",
        "data_col11", "data_col12", "data_col13", "data_col14", "data_col15", "data_col16",
        "data_col17", "data_col18", "data_col19", "data_col20", "data_col21", "data_col22",
        "data_col23", "data_col24", "data_col25", "data_col26", "data_col27", "data_col28",
        "data_col29", "data_col30", "data_col31", "data_col32", "data_col33", "data_col34",
        "data_col35", "data_col36", "data_col37", "data_col38", "data_col39", "data_col40",
        "data_col41", "data_col42", "data_col43", "data_col44", "data_col45", "data_col46",
        "data_col47", "data_col48", "data_col49", "data_col50"}';
BEGIN
    v_SQL :=
                                        'SELECT a.ass_col_val_id assess_col_id, a.assess_sheet_hdr_id assess_sht_hdr_id, a.acdmc_sttngs_id, public.chartonumeric(a.' ||
                                        v_dataCols[p_columnNo] ||
                                        ') assess_score FROM aca.aca_assmnt_col_vals a, aca.aca_assess_sheet_hdr b ' ||
                                        'WHERE ((a.assess_sheet_hdr_id = b.assess_sheet_hdr_id and b.class_id=' ||
                                        p_class_id || ' and b.academic_period_id=' ||
                                        p_period_id || ' and a.acdmc_sttngs_id <=0))';
    RETURN QUERY
        EXECUTE v_SQL;
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_sheet_value(p_acdmc_sttngs_id bigint,
                                               p_course_id integer,
                                               p_subject_id integer,
                                               p_columnNo integer)
    RETURNS TEXT
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    bid        TEXT   := '';
    v_SQL      TEXT   := '';
    v_dataCols TEXT[] := '{"data_col1", "data_col2", "data_col3", "data_col4",
        "data_col5", "data_col6", "data_col7", "data_col8", "data_col9", "data_col10",
        "data_col11", "data_col12", "data_col13", "data_col14", "data_col15", "data_col16",
        "data_col17", "data_col18", "data_col19", "data_col20", "data_col21", "data_col22",
        "data_col23", "data_col24", "data_col25", "data_col26", "data_col27", "data_col28",
        "data_col29", "data_col30", "data_col31", "data_col32", "data_col33", "data_col34",
        "data_col35", "data_col36", "data_col37", "data_col38", "data_col39", "data_col40",
        "data_col41", "data_col42", "data_col43", "data_col44", "data_col45", "data_col46",
        "data_col47", "data_col48", "data_col49", "data_col50"}';
BEGIN
    v_SQL := 'SELECT ' || v_dataCols[p_columnNo] ||
             ' FROM aca.aca_assmnt_col_vals a, ' ||
             'aca.aca_assess_sheet_hdr b, ' ||
             'aca.aca_prsns_acdmc_sttngs c ' ||
             'WHERE (a.assess_sheet_hdr_id=b.assess_sheet_hdr_id and a.acdmc_sttngs_id=c.acdmc_sttngs_id' ||
             ' and c.acdmc_period_id = b.academic_period_id' ||
             ' and c.class_id = b.class_id' ||
             ' and b.course_id =' || p_course_id ||
             ' and b.subject_id =' || p_subject_id ||
             ' and a.acdmc_sttngs_id = ' || p_acdmc_sttngs_id || ')';
    EXECUTE v_SQL
        INTO bid;
    RETURN coalesce(bid, '');
END ;
$BODY$;


CREATE OR REPLACE FUNCTION aca.get_sheet_hdr_value(p_acdmc_sttngs_id bigint,
                                                   p_course_id integer,
                                                   p_subject_id integer,
                                                   p_columnNo integer)
    RETURNS TEXT
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    bid        TEXT   := '';
    v_SQL      TEXT   := '';
    v_dataCols TEXT[] := '{"data_col1", "data_col2", "data_col3", "data_col4",
        "data_col5", "data_col6", "data_col7", "data_col8", "data_col9", "data_col10",
        "data_col11", "data_col12", "data_col13", "data_col14", "data_col15", "data_col16",
        "data_col17", "data_col18", "data_col19", "data_col20", "data_col21", "data_col22",
        "data_col23", "data_col24", "data_col25", "data_col26", "data_col27", "data_col28",
        "data_col29", "data_col30", "data_col31", "data_col32", "data_col33", "data_col34",
        "data_col35", "data_col36", "data_col37", "data_col38", "data_col39", "data_col40",
        "data_col41", "data_col42", "data_col43", "data_col44", "data_col45", "data_col46",
        "data_col47", "data_col48", "data_col49", "data_col50"}';
BEGIN
    v_SQL := 'SELECT ' || v_dataCols[p_columnNo] ||
             ' FROM aca.aca_assmnt_col_vals a, ' ||
             'aca.aca_assess_sheet_hdr b, ' ||
             'aca.aca_prsns_acdmc_sttngs c ' ||
             'WHERE (a.assess_sheet_hdr_id=b.assess_sheet_hdr_id' ||
             ' and c.acdmc_period_id = b.academic_period_id' ||
             ' and c.class_id = b.class_id' ||
             ' and a.acdmc_sttngs_id <=0' ||
             ' and b.course_id =' || p_course_id ||
             ' and b.subject_id =' || p_subject_id ||
             ' and c.acdmc_sttngs_id = ' || p_acdmc_sttngs_id || ')';
    EXECUTE v_SQL
        INTO bid;
    RETURN coalesce(bid, '');
END ;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_postn_per_sheet(p_sht_hdr_id BIGINT, p_col_num integer, p_sttng_id BIGINT)
    RETURNS BIGINT
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    v_Pos   bigint  := 0;
    v_score numeric := 0;
BEGIN
    v_score := aca.get_assess_col_val1(p_sht_hdr_id, p_sttng_id, p_col_num);
    SELECT tbl1.postn::BIGINT
    into v_Pos
    from (WITH assess_scores as (Select distinct a.assess_score
                                 from aca.get_assess_sht_vals(p_sht_hdr_id, p_col_num) a)
          SELECT assess_score, ROW_NUMBER() OVER (ORDER BY assess_score DESC) postn
          from assess_scores) tbl1
    where tbl1.assess_score = v_score;
    RETURN coalesce(v_Pos, 0);
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_postn_per_group(p_sht_hdr_id BIGINT, p_col_num integer)
    RETURNS BIGINT
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    v_Pos       bigint  := 0;
    v_score     numeric := 0;
    v_class_id  integer := -1;
    v_period_id bigint  := -1;
BEGIN
    begin
        select class_id, academic_period_id
        into v_class_id,v_period_id
        from aca.aca_assess_sheet_hdr
        where assess_sheet_hdr_id = p_sht_hdr_id;
    exception
        when others then
            v_class_id := -1;
            v_period_id := -1;
    end;
    v_score := aca.get_assess_col_val1(p_sht_hdr_id, -1, p_col_num);
    SELECT tbl1.postn::BIGINT
    into v_Pos
    from (WITH assess_scores as (Select distinct a.assess_score
                                 from aca.get_rpt_card_vals(v_class_id, v_period_id, p_col_num) a)
          SELECT assess_score, ROW_NUMBER() OVER (ORDER BY assess_score DESC) postn
          from assess_scores) tbl1
    where tbl1.assess_score = v_score;
    RETURN coalesce(v_Pos, 0);
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.sum_cols_per_rpt(p_sht_hdr_id BIGINT, p_col_num integer)
    RETURNS NUMERIC
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    v_Ttl NUMERIC := 0;
    rd1   RECORD;
BEGIN
    FOR rd1 IN SELECT acdmc_sttngs_id, course_id, subject_id
               FROM aca.aca_assmnt_col_vals
               WHERE acdmc_sttngs_id > 0
                 and assess_sheet_hdr_id = p_sht_hdr_id
        LOOP
            v_Ttl := v_Ttl + aca.get_assess_col_val3(p_sht_hdr_id,
                                                     rd1.acdmc_sttngs_id, rd1.course_id,
                                                     rd1.subject_id,
                                                     p_col_num);
        END LOOP;
    RETURN coalesce(v_Ttl, 0.00);
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.sum_cols_per_sheet(p_sht_hdr_id BIGINT, p_col_num integer)
    RETURNS NUMERIC
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    v_Ttl NUMERIC := 0;
    rd1   RECORD;
BEGIN
    FOR rd1 IN SELECT acdmc_sttngs_id
               FROM aca.aca_assmnt_col_vals
               WHERE acdmc_sttngs_id > 0
                 and assess_sheet_hdr_id = p_sht_hdr_id
        LOOP
            v_Ttl := v_Ttl + aca.get_assess_col_val1(p_sht_hdr_id,
                                                     rd1.acdmc_sttngs_id, p_col_num);
        END LOOP;
    RETURN coalesce(v_Ttl, 0.00);
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.sum_cols_per_row(p_sht_hdr_id BIGINT, p_sttng_id BIGINT, p_col_nums character varying)
    RETURNS NUMERIC
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    v_Ttl        NUMERIC                 := 0;
    v_Tmp_Val    NUMERIC                 := 0;
    v_col_nums   character varying(4000) := '';
    v_cols_array TEXT[];
BEGIN
    v_col_nums := TRIM(BOTH ',' FROM REPLACE(REPLACE(REPLACE(p_col_nums, ',,', ','), ',,', ','), ',,', ','));
    v_cols_array := string_to_array(v_col_nums, ',');
    FOR j IN 1.. array_length(v_cols_array, 1)
        LOOP
            IF ((v_cols_array[j]::INTEGER) > 0) THEN
                v_Tmp_Val := coalesce(aca.get_assess_col_val1(p_sht_hdr_id,
                                                              p_sttng_id, (v_cols_array[j]::INTEGER)), 0);

                v_Ttl := v_Ttl + v_Tmp_Val;
            END IF;
        END LOOP;
    RETURN coalesce(v_Ttl, 0.00);
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_score_grade_code(p_score NUMERIC, p_grade_scale_id integer)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    bid CHARACTER VARYING(300) := '';
BEGIN
    SELECT a.grade_code
    INTO bid
    FROM aca.aca_grade_scales a
    WHERE a.scale_id = p_grade_scale_id
      and a.band_min_value <= p_score
      and a.band_max_value >= p_score;
    RETURN coalesce(bid, '');
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_score_grade_txt(p_score NUMERIC, p_grade_scale_id integer)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    bid CHARACTER VARYING(300) := '';
BEGIN
    SELECT a.grade_description
    INTO bid
    FROM aca.aca_grade_scales a
    WHERE a.scale_id = p_grade_scale_id
      and a.band_min_value <= p_score
      and a.band_max_value >= p_score;
    RETURN coalesce(bid, '');
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_score_gpa_value(p_score NUMERIC, p_grade_scale_id integer)
    RETURNS NUMERIC
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    bid NUMERIC := 0.00;
BEGIN
    SELECT a.grade_gpa_value
    INTO bid
    FROM aca.aca_grade_scales a
    WHERE a.scale_id = p_grade_scale_id
      and a.band_min_value <= p_score
      and a.band_max_value >= p_score;
    RETURN coalesce(bid, 0.00);
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_grade_gpa_value(p_grade_code CHARACTER VARYING, p_grade_scale_id integer)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    bid NUMERIC := 0.00;
BEGIN
    SELECT a.grade_gpa_value
    INTO bid
    FROM aca.aca_grade_scales a
    WHERE a.scale_id = p_grade_scale_id
      and lower(a.grade_code) = lower(p_grade_code);
    RETURN coalesce(bid, 0.00);
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_col_data_type(p_sht_hdr_id BIGINT, p_col_num integer)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    bid CHARACTER VARYING(300) := '';
BEGIN
    SELECT c.data_type
    INTO bid
    FROM aca.aca_assess_sheet_hdr a,
         aca.aca_assessment_types b,
         aca.aca_assessment_columns c
    WHERE a.assessment_type_id = b.assmnt_typ_id
      and c.assmnt_typ_id = b.assmnt_typ_id
      and c.column_no = p_col_num
      and a.assess_sheet_hdr_id = p_sht_hdr_id;
    RETURN coalesce(bid, '');
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_col_hdr_txt(p_sht_hdr_id BIGINT, p_col_num integer)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    bid CHARACTER VARYING(300) := '';
BEGIN
    SELECT c.column_header_text
    INTO bid
    FROM aca.aca_assess_sheet_hdr a,
         aca.aca_assessment_types b,
         aca.aca_assessment_columns c
    WHERE a.assessment_type_id = b.assmnt_typ_id
      and c.assmnt_typ_id = b.assmnt_typ_id
      and c.column_no = p_col_num
      and a.assess_sheet_hdr_id = p_sht_hdr_id;
    RETURN coalesce(bid, '');
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_assess_col_val2(p_assess_hdrid BIGINT,
                                                   p_sttng_id BIGINT, p_columnNo integer)
    RETURNS TEXT
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    bid        TEXT   := '';
    nwSQL      TEXT   := '';
    v_dataCols TEXT[] := '{"data_col1", "data_col2", "data_col3", "data_col4",
        "data_col5", "data_col6", "data_col7", "data_col8", "data_col9", "data_col10",
        "data_col11", "data_col12", "data_col13", "data_col14", "data_col15", "data_col16",
        "data_col17", "data_col18", "data_col19", "data_col20", "data_col21", "data_col22",
        "data_col23", "data_col24", "data_col25", "data_col26", "data_col27", "data_col28",
        "data_col29", "data_col30", "data_col31", "data_col32", "data_col33", "data_col34",
        "data_col35", "data_col36", "data_col37", "data_col38", "data_col39", "data_col40",
        "data_col41", "data_col42", "data_col43", "data_col44", "data_col45", "data_col46",
        "data_col47", "data_col48", "data_col49", "data_col50"}';
BEGIN
    nwSQL := 'SELECT ' || v_dataCols[p_columnNo] ||
             ' FROM aca.aca_assmnt_col_vals a WHERE ((assess_sheet_hdr_id = ' ||
             p_assess_hdrid || ' and acdmc_sttngs_id = ' || p_sttng_id || '))';
    --RAISE NOTICE 'Query SQL = "%"', nwSQL;
    --RAISE NOTICE 'Query itemSQL = "%"', itemSQL;
    EXECUTE nwSQL
        INTO bid;
    RETURN coalesce(bid, '');
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_assess_col_val1(p_assess_hdrid BIGINT,
                                                   p_sttng_id BIGINT, p_columnNo integer)
    RETURNS NUMERIC
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    v_col_pkey_id BIGINT                 := -1;
    bid           NUMERIC                := 0.00;
    v_Tmp_Val     NUMERIC                := 0;
    v_msgs        TEXT                   := '';
    v_hdr_txt     CHARACTER VARYING(200) := '';
    nwSQL         TEXT                   := '';
    v_dataCols    TEXT[]                 := '{"data_col1", "data_col2", "data_col3", "data_col4",
        "data_col5", "data_col6", "data_col7", "data_col8", "data_col9", "data_col10",
        "data_col11", "data_col12", "data_col13", "data_col14", "data_col15", "data_col16",
        "data_col17", "data_col18", "data_col19", "data_col20", "data_col21", "data_col22",
        "data_col23", "data_col24", "data_col25", "data_col26", "data_col27", "data_col28",
        "data_col29", "data_col30", "data_col31", "data_col32", "data_col33", "data_col34",
        "data_col35", "data_col36", "data_col37", "data_col38", "data_col39", "data_col40",
        "data_col41", "data_col42", "data_col43", "data_col44", "data_col45", "data_col46",
        "data_col47", "data_col48", "data_col49", "data_col50"}';
    v_Min_Value   NUMERIC                := 0;
    v_Max_Value   NUMERIC                := 0;
BEGIN
    BEGIN
        SELECT coalesce(col_min_val, 0), coalesce(col_max_val, 0)
        INTO v_Min_Value, v_Max_Value
        FROM aca.aca_assessment_columns a,
             aca.aca_assess_sheet_hdr b
        WHERE a.assmnt_typ_id = b.assessment_type_id
          and a.assess_sheet_hdr_id = p_sht_hdr_id
          and a.column_no = p_columnNo;
    EXCEPTION
        WHEN OTHERS THEN
            v_Min_Value := 0;
            v_Max_Value := 0;
    END;
    nwSQL := 'SELECT public.chartonumeric(' || v_dataCols[p_columnNo] ||
             '), a.ass_col_val_id FROM aca.aca_assmnt_col_vals a WHERE ((assess_sheet_hdr_id = ' ||
             p_assess_hdrid || ' and acdmc_sttngs_id = ' || p_sttng_id || '))';
    --RAISE NOTICE 'Query SQL = "%"', nwSQL;
    --RAISE NOTICE 'Query itemSQL = "%"', itemSQL;
    EXECUTE nwSQL
        INTO bid, v_col_pkey_id;
    v_Tmp_Val := COALESCE(bid, 0.00);
    IF ((v_Max_Value != 0 and v_Min_Value != 0) AND
        (v_Tmp_Val > v_Max_Value or v_Tmp_Val < v_Min_Value)) then
        v_hdr_txt := aca.get_col_hdr_txt(p_assess_hdrid, p_columnNo);
        v_msgs := 'Please ensure that the value of Column (' || p_columnNo ||
                  '-' || v_hdr_txt || ') in Rec. ID [' || v_col_pkey_id ||
                  '] is within the defined Maximum and Minimum Values!';
        RAISE EXCEPTION 'MIN-MAX ERROR:%', v_msgs
            USING HINT = 'Please ensure that the value of Column (' || p_columnNo ||
                         '-' || v_hdr_txt || ') in Rec. ID [' || v_col_pkey_id ||
                         '] is within the defined Maximum and Minimum Values!';
    End IF;
    RETURN v_Tmp_Val;
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_assess_col_val3(p_assess_hdrid BIGINT,
                                                   p_sttng_id BIGINT, p_course_id integer, p_subject_id integer,
                                                   p_columnNo integer)
    RETURNS NUMERIC
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    v_col_pkey_id BIGINT                 := -1;
    bid           NUMERIC                := 0.00;
    v_Tmp_Val     NUMERIC                := 0;
    v_msgs        TEXT                   := '';
    v_hdr_txt     CHARACTER VARYING(200) := '';
    nwSQL         TEXT                   := '';
    v_dataCols    TEXT[]                 := '{"data_col1", "data_col2", "data_col3", "data_col4",
        "data_col5", "data_col6", "data_col7", "data_col8", "data_col9", "data_col10",
        "data_col11", "data_col12", "data_col13", "data_col14", "data_col15", "data_col16",
        "data_col17", "data_col18", "data_col19", "data_col20", "data_col21", "data_col22",
        "data_col23", "data_col24", "data_col25", "data_col26", "data_col27", "data_col28",
        "data_col29", "data_col30", "data_col31", "data_col32", "data_col33", "data_col34",
        "data_col35", "data_col36", "data_col37", "data_col38", "data_col39", "data_col40",
        "data_col41", "data_col42", "data_col43", "data_col44", "data_col45", "data_col46",
        "data_col47", "data_col48", "data_col49", "data_col50"}';
    v_Min_Value   NUMERIC                := 0;
    v_Max_Value   NUMERIC                := 0;
BEGIN
    BEGIN
        SELECT coalesce(col_min_val, 0), coalesce(col_max_val, 0)
        INTO v_Min_Value, v_Max_Value
        FROM aca.aca_assessment_columns a,
             aca.aca_assess_sheet_hdr b
        WHERE a.assmnt_typ_id = b.assessment_type_id
          and a.assess_sheet_hdr_id = p_sht_hdr_id
          and a.column_no = p_columnNo;
    EXCEPTION
        WHEN OTHERS THEN
            v_Min_Value := 0;
            v_Max_Value := 0;
    END;
    nwSQL := 'SELECT public.chartonumeric(' || v_dataCols[p_columnNo] ||
             '), a.ass_col_val_id FROM aca.aca_assmnt_col_vals a WHERE ((assess_sheet_hdr_id = ' ||
             p_assess_hdrid || ' and acdmc_sttngs_id = ' || p_sttng_id ||
             ' and course_id = ' || p_course_id ||
             ' and subject_id = ' || p_subject_id || '))';
    --RAISE NOTICE 'Query SQL = "%"', nwSQL;
    --RAISE NOTICE 'Query itemSQL = "%"', itemSQL;
    EXECUTE nwSQL
        INTO bid, v_col_pkey_id;
    v_Tmp_Val := COALESCE(bid, 0.00);
    IF ((v_Max_Value != 0 and v_Min_Value != 0) AND
        (v_Tmp_Val > v_Max_Value or v_Tmp_Val < v_Min_Value)) then
        v_hdr_txt := aca.get_col_hdr_txt(p_assess_hdrid, p_columnNo);
        v_msgs := 'Please ensure that the value of Column (' || p_columnNo ||
                  '-' || v_hdr_txt || ') in Rec. ID [' || v_col_pkey_id ||
                  '] is within the defined Maximum and Minimum Values!';
        RAISE EXCEPTION 'MIN-MAX ERROR:%', v_msgs
            USING HINT = 'Please ensure that the value of Column (' || p_columnNo ||
                         '-' || v_hdr_txt || ') in Rec. ID [' || v_col_pkey_id ||
                         '] is within the defined Maximum and Minimum Values!';
    End IF;
    RETURN v_Tmp_Val;
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_assess_prsn_cnt(p_assess_hdrid BIGINT)
    RETURNS BIGINT
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    bid BIGINT := 0;
BEGIN
    select count(b.person_id)
    into bid
    from aca.aca_assess_sheet_hdr a,
         aca.aca_prsns_acdmc_sttngs b
    where a.assess_sheet_hdr_id = p_assess_hdrid
      and (a.class_id = b.class_id or a.class_id <= 0)
      and (a.academic_period_id = b.acdmc_period_id or a.academic_period_id <= 0)
      and (a.course_id = b.course_id or a.course_id <= 0)
      and (select count(c.ac_sttngs_sbjcts_id)
           from aca.aca_prsns_ac_sttngs_sbjcts c
           where c.subject_id = a.subject_id
             and c.acdmc_sttngs_id = b.acdmc_sttngs_id) >= (CASE WHEN a.subject_id > 0 THEN 1 ELSE 0 END);
    RETURN coalesce(bid, 0);
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_assess_sbjct_cnt(p_assess_hdrid BIGINT)
    RETURNS BIGINT
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    bid BIGINT := 0;
BEGIN
    select count(distinct c.subject_id)
    into bid
    from aca.aca_assess_sheet_hdr a,
         aca.aca_prsns_acdmc_sttngs b,
         aca.aca_prsns_ac_sttngs_sbjcts c
    where a.assess_sheet_hdr_id = p_assess_hdrid
      and (a.class_id = b.class_id)
      and (a.academic_period_id = b.acdmc_period_id)
      and b.person_id = a.assessed_person_id
      and c.acdmc_sttngs_id = b.acdmc_sttngs_id
      and (a.course_id = b.course_id or a.course_id <= 0)
      and (a.subject_id = c.subject_id or a.subject_id <= 0);

    RETURN coalesce(bid, 0);
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_group_prsn_cnt(p_class_id integer, p_period_id bigint)
    RETURNS BIGINT
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    bid BIGINT := 0;
BEGIN
    select count(b.person_id)
    into bid
    from aca.aca_prsns_acdmc_sttngs b
    where b.class_id = p_class_id
      and b.acdmc_period_id = p_period_id;

    RETURN coalesce(bid, 0);
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_assess_rec_cnt(p_assess_hdrid BIGINT)
    RETURNS BIGINT
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    bid BIGINT := 0;
BEGIN
    select count(a.ass_col_val_id)
    into bid
    from aca.aca_assmnt_col_vals a
    where a.assess_sheet_hdr_id = p_assess_hdrid
      and a.acdmc_sttngs_id > 0;
    RETURN coalesce(bid, 0);
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_period_nm(periodid BIGINT)
    RETURNS CHARACTER VARYING
    LANGUAGE 'sql'
    COST 100
    VOLATILE
AS
$BODY$
SELECT assmnt_period_name
FROM aca.aca_assessment_periods
WHERE assmnt_period_id = $1
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_class_nm(classid INTEGER)
    RETURNS CHARACTER VARYING
    LANGUAGE 'sql'
    COST 100
    VOLATILE
AS
$BODY$
SELECT class_name
FROM aca.aca_classes
WHERE class_id = $1
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_subjectnm(p_sbjctid integer)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    bid CHARACTER VARYING(300) := '';
BEGIN
    SELECT REPLACE(subject_code || ' (' || subject_name || ')', ' (' || subject_code || ')', '')
    INTO bid
    FROM aca.aca_subjects
    WHERE subject_id = p_sbjctid;
    RETURN coalesce(bid, '');
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_subjectcode(p_sbjctid integer)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    bid CHARACTER VARYING(300) := '';
BEGIN
    SELECT subject_code
    INTO bid
    FROM aca.aca_subjects
    WHERE subject_id = p_sbjctid;
    RETURN coalesce(bid, '');
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_coursenm(p_course_id integer)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    bid CHARACTER VARYING(300) := '';
BEGIN
    SELECT REPLACE(course_code || ' (' || course_name || ')', ' (' || course_code || ')', '')
    INTO bid
    FROM aca.aca_courses
    WHERE course_id = p_course_id;
    RETURN coalesce(bid, '');
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_coursecode(p_course_id integer)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    bid CHARACTER VARYING(300) := '';
BEGIN
    SELECT course_code
    INTO bid
    FROM aca.aca_courses
    WHERE course_id = p_course_id;
    RETURN coalesce(bid, '');
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_grade_scalenm(scaleid INTEGER)
    RETURNS CHARACTER VARYING
    LANGUAGE 'sql'
    COST 100
    VOLATILE
AS
$BODY$
SELECT max(scale_name)
FROM aca.aca_grade_scales
WHERE scale_id = $1
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_assesstypnm(assesstypid INTEGER)
    RETURNS CHARACTER VARYING
    LANGUAGE 'sql'
    COST 100
    VOLATILE
AS
$BODY$
SELECT assmnt_typ_nm
FROM aca.aca_assessment_types
WHERE assmnt_typ_id = $1
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_assesstyp(assesstypid INTEGER)
    RETURNS CHARACTER VARYING
    LANGUAGE 'sql'
    COST 100
    VOLATILE
AS
$BODY$
SELECT assmnt_type
FROM aca.aca_assessment_types
WHERE assmnt_typ_id = $1
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_assesstypLevel(assesstypid INTEGER)
    RETURNS CHARACTER VARYING
    LANGUAGE 'sql'
    COST 100
    VOLATILE
AS
$BODY$
SELECT assmnt_level
FROM aca.aca_assessment_types
WHERE assmnt_typ_id = $1
$BODY$;

DROP FUNCTION gst.cnvrtAllToDMYTm(p_inptdte CHARACTER VARYING);
CREATE OR REPLACE FUNCTION gst.cnvrtAllToDMYTm(p_inptdte CHARACTER VARYING)
    RETURNS CHARACTER VARYING
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    v_outptdte   CHARACTER VARYING(100) := '';
    v_timeformat CHARACTER VARYING(100) := '';
BEGIN
    BEGIN
        v_outptdte :=
                TO_CHAR(p_inptdte::TIMESTAMP, 'DD-Mon-YYYY HH24:MI:SS');
    EXCEPTION
        WHEN OTHERS THEN
            IF coalesce(p_inptdte, '') LIKE '%:%' THEN
                v_timeformat := ' HH24:MI:SS';
            END IF;
            BEGIN
                IF coalesce(p_inptdte, '') LIKE '%-%' AND trim(substr(coalesce(p_inptdte, ''), 1, 4)) NOT LIKE '%-%'
                    AND char_length(trim(substr(coalesce(p_inptdte, ''), 1, 11))) = 11 THEN
                    v_outptdte :=
                            TO_CHAR(to_timestamp(p_inptdte, 'YYYY-DD-Mon' || v_timeformat),
                                    'DD-Mon-YYYY HH24:MI:SS');
                ELSIF coalesce(p_inptdte, '') LIKE '%/%' AND trim(substr(coalesce(p_inptdte, ''), 1, 4)) NOT LIKE '%/%'
                    AND char_length(trim(substr(coalesce(p_inptdte, ''), 1, 11))) = 11 THEN
                    --RAISE NOTICE 'YYYY/DD/Mon=%',p_inptdte;
                    v_outptdte :=
                            TO_CHAR(to_timestamp(p_inptdte, 'YYYY/DD/Mon' || v_timeformat),
                                    'DD-Mon-YYYY HH24:MI:SS');
                    --RAISE NOTICE 'YYYY/DD/Mon=%',v_outptdte;
                ELSIF coalesce(p_inptdte, '') LIKE '%/%'
                    AND char_length(trim(substr(coalesce(p_inptdte, ''), 1, 9))) = 8
                THEN
                    v_outptdte :=
                            TO_CHAR(to_timestamp(p_inptdte, 'DD/MM/YY' || v_timeformat),
                                    'DD-Mon-YYYY HH24:MI:SS');
                ELSIF coalesce(p_inptdte, '') LIKE '%/%'
                    AND char_length(trim(substr(coalesce(p_inptdte, ''), 1, 9))) = 9
                THEN
                    v_outptdte :=
                            TO_CHAR(to_timestamp(p_inptdte, 'DD/Mon/YY' || v_timeformat),
                                    'DD-Mon-YYYY HH24:MI:SS');
                ELSIF coalesce(p_inptdte, '') LIKE '%/%'
                    AND char_length(trim(substr(coalesce(p_inptdte, ''), 1, 11))) = 10
                THEN
                    v_outptdte :=
                            TO_CHAR(to_timestamp(p_inptdte, 'DD/MM/YYYY' || v_timeformat),
                                    'DD-Mon-YYYY HH24:MI:SS');
                ELSIF coalesce(p_inptdte, '') LIKE '%/%'
                    AND char_length(trim(substr(coalesce(p_inptdte, ''), 1, 11))) = 11
                THEN
                    v_outptdte :=
                            TO_CHAR(to_timestamp(p_inptdte, 'DD/Mon/YYYY' || v_timeformat),
                                    'DD-Mon-YYYY HH24:MI:SS');
                ELSIF coalesce(p_inptdte, '') LIKE '%-%'
                    AND char_length(trim(substr(coalesce(p_inptdte, ''), 1, 9))) = 8
                THEN
                    v_outptdte :=
                            TO_CHAR(to_timestamp(p_inptdte, 'DD-MM-YY' || v_timeformat),
                                    'DD-Mon-YYYY HH24:MI:SS');
                ELSIF coalesce(p_inptdte, '') LIKE '%-%'
                    AND char_length(trim(substr(coalesce(p_inptdte, ''), 1, 9))) = 9
                THEN
                    v_outptdte :=
                            TO_CHAR(to_timestamp(p_inptdte, 'DD-Mon-YY' || v_timeformat),
                                    'DD-Mon-YYYY HH24:MI:SS');
                ELSIF coalesce(p_inptdte, '') LIKE '%-%'
                    AND char_length(trim(substr(coalesce(p_inptdte, ''), 1, 11))) = 10
                THEN
                    v_outptdte :=
                            TO_CHAR(to_timestamp(p_inptdte, 'DD-MM-YYYY' || v_timeformat),
                                    'DD-Mon-YYYY HH24:MI:SS');
                ELSIF coalesce(p_inptdte, '') LIKE '%-%'
                    AND char_length(trim(substr(coalesce(p_inptdte, ''), 1, 11))) = 11
                THEN
                    v_outptdte :=
                            TO_CHAR(to_timestamp(p_inptdte, 'DD-Mon-YYYY' || v_timeformat),
                                    'DD-Mon-YYYY HH24:MI:SS');

                ELSE
                    v_outptdte := '';
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    IF coalesce(p_inptdte, '') LIKE '%:%' THEN
                        v_timeformat := ' HH24:MI:SS';
                    END IF;
                    IF coalesce(p_inptdte, '') LIKE '%-%' AND trim(substr(coalesce(p_inptdte, ''), 1, 4)) NOT LIKE '%-%'
                        AND char_length(trim(substr(coalesce(p_inptdte, ''), 1, 11))) = 10 THEN
                        v_outptdte :=
                                TO_CHAR(to_timestamp(p_inptdte, 'YYYY-DD-MM' || v_timeformat),
                                        'DD-Mon-YYYY HH24:MI:SS');
                    ELSIF coalesce(p_inptdte, '') LIKE '%/%' AND
                          trim(substr(coalesce(p_inptdte, ''), 1, 4)) NOT LIKE '%/%'
                        AND char_length(trim(substr(coalesce(p_inptdte, ''), 1, 11))) = 10 THEN
                        v_outptdte :=
                                TO_CHAR(to_timestamp(p_inptdte, 'YYYY/DD/MM' || v_timeformat),
                                        'DD-Mon-YYYY HH24:MI:SS');
                    ELSIF coalesce(p_inptdte, '') LIKE '%/%'
                        AND char_length(trim(substr(coalesce(p_inptdte, ''), 1, 9))) = 8
                    THEN
                        v_outptdte :=
                                TO_CHAR(to_timestamp(p_inptdte, 'MM/DD/YY' || v_timeformat),
                                        'DD-Mon-YYYY HH24:MI:SS');
                    ELSIF coalesce(p_inptdte, '') LIKE '%/%'
                        AND char_length(trim(substr(coalesce(p_inptdte, ''), 1, 9))) = 9
                    THEN
                        v_outptdte :=
                                TO_CHAR(to_timestamp(p_inptdte, 'Mon/DD/YY' || v_timeformat),
                                        'DD-Mon-YYYY HH24:MI:SS');
                    ELSIF coalesce(p_inptdte, '') LIKE '%/%'
                        AND char_length(trim(substr(coalesce(p_inptdte, ''), 1, 11))) = 10
                    THEN
                        v_outptdte :=
                                TO_CHAR(to_timestamp(p_inptdte, 'MM/DD/YYYY' || v_timeformat),
                                        'DD-Mon-YYYY HH24:MI:SS');
                    ELSIF coalesce(p_inptdte, '') LIKE '%/%'
                        AND char_length(trim(substr(coalesce(p_inptdte, ''), 1, 11))) = 11
                    THEN
                        v_outptdte :=
                                TO_CHAR(to_timestamp(p_inptdte, 'Mon/DD/YYYY' || v_timeformat),
                                        'DD-Mon-YYYY HH24:MI:SS');
                    ELSIF coalesce(p_inptdte, '') LIKE '%-%'
                        AND char_length(trim(substr(coalesce(p_inptdte, ''), 1, 9))) = 8
                    THEN
                        v_outptdte :=
                                TO_CHAR(to_timestamp(p_inptdte, 'MM-DD-YY' || v_timeformat),
                                        'DD-Mon-YYYY HH24:MI:SS');
                    ELSIF coalesce(p_inptdte, '') LIKE '%-%'
                        AND char_length(trim(substr(coalesce(p_inptdte, ''), 1, 9))) = 9
                    THEN
                        v_outptdte :=
                                TO_CHAR(to_timestamp(p_inptdte, 'Mon-DD-YY' || v_timeformat),
                                        'DD-Mon-YYYY HH24:MI:SS');
                    ELSIF coalesce(p_inptdte, '') LIKE '%-%'
                        AND char_length(trim(substr(coalesce(p_inptdte, ''), 1, 11))) = 10
                    THEN
                        v_outptdte :=
                                TO_CHAR(to_timestamp(p_inptdte, 'MM-DD-YYYY' || v_timeformat),
                                        'DD-Mon-YYYY HH24:MI:SS');
                    ELSIF coalesce(p_inptdte, '') LIKE '%-%'
                        AND char_length(trim(substr(coalesce(p_inptdte, ''), 1, 11))) = 11
                    THEN
                        v_outptdte :=
                                TO_CHAR(to_timestamp(p_inptdte, 'Mon-DD-YYYY' || v_timeformat),
                                        'DD-Mon-YYYY HH24:MI:SS');

                    ELSE
                        v_outptdte := '';
                    END IF;
            END;
    END;
    RETURN v_outptdte;
EXCEPTION
    WHEN OTHERS THEN
        v_outptdte := '';
END;
$BODY$;

CREATE OR REPLACE FUNCTION scm.get_sllng_price_inctax(p_txid BIGINT,
                                                      p_price_lstax NUMERIC)
    RETURNS NUMERIC
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    v_txAmnts     NUMERIC                := 0;
    v_txAmnts1    NUMERIC                := 0;
    v_isParnt     CHARACTER VARYING(1)   := '0';
    v_codeIDs     CHARACTER VARYING(100) := ',';
    v_codeIDArrys TEXT[];
BEGIN
    v_txAmnts := 0;
    v_txAmnts1 := 0;
    IF
        (p_txID > 0)
    THEN
        v_isParnt := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'is_parent', p_txID);
        IF
            (v_isParnt = '1')
        THEN
            v_codeIDs := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'child_code_ids', p_txID);
            v_codeIDArrys := string_to_array(BTRIM(v_codeIDs, ','), ',');
            FOR j IN 1.. array_char_length(v_codeIDArrys, 1)
                LOOP
                    IF ((v_codeIDArrys[j]::INTEGER) > 0) THEN
                        v_txAmnts1 := v_txAmnts1 + scm.getSalesDocCodesAmnt((v_codeIDArrys[j]::INTEGER), 1, 1);
                    END IF;
                END LOOP;
            v_txAmnts1 := p_price_lstax * (1.0 + v_txAmnts1);
            v_txAmnts := v_txAmnts + v_txAmnts1;
        ELSE
            v_txAmnts1 := scm.getSalesDocCodesAmnt(p_txID, 1, 1);
            v_txAmnts1 := p_price_lstax * (1.0 + v_txAmnts1);
            v_txAmnts := v_txAmnts + v_txAmnts1;
        END IF;
    ELSE
        v_txAmnts := p_price_lstax;
    END IF;
    RETURN v_txAmnts;
END;
$BODY$;

CREATE OR REPLACE FUNCTION org.get_payitm_createsAccntng(
    itmid BIGINT)
    RETURNS CHARACTER VARYING
    LANGUAGE 'sql'
    COST 100
    VOLATILE
AS
$BODY$
SELECT creates_accounting
FROM org.org_pay_items
WHERE item_id = $1
$BODY$;

CREATE OR REPLACE FUNCTION pay.get_blsitem_bals(personid BIGINT,
                                                bals_itm_id BIGINT,
                                                bals_date CHARACTER VARYING)
    RETURNS NUMERIC
    LANGUAGE 'sql'
    COST 100
    VOLATILE
AS
$BODY$
SELECT a.bals_amount
FROM pay.pay_balsitm_bals a
WHERE a.person_id = $1
  AND a.bals_itm_id = $2
  AND a.bals_date = substr($3, 1, 10)
$BODY$;
CREATE OR REPLACE FUNCTION pay.get_blsitem_bals_retro(personid BIGINT,
                                                      bals_itm_id BIGINT,
                                                      bals_date CHARACTER VARYING)
    RETURNS NUMERIC
    LANGUAGE 'sql'
    COST 100
    VOLATILE
AS
$BODY$
SELECT a.bals_amount
FROM pay.pay_balsitm_bals_retro a
WHERE a.person_id = $1
  AND a.bals_itm_id = $2
  AND a.bals_date = substr($3, 1, 10)
$BODY$;

CREATE OR REPLACE FUNCTION pay.calc_irs_paye_mnthly_tax(
    txabl_incme NUMERIC)
    RETURNS NUMERIC
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    tax_ans        NUMERIC   := 0;
    rmng_txbl_incm NUMERIC   := 0;
    cur_incm       NUMERIC   := 0;
    ttl_rates      INTEGER   := 0;
    loop_cntr      INTEGER   := 0;
    i              RECORD;
    rates          NUMERIC[] := '{0.0,0.05,0.10,0.175,0.25}';
    bounds         NUMERIC[] := '{216,108,151,2765,0}';
BEGIN
    rmng_txbl_incm := txabl_incme;
    cur_incm := 0;
    SELECT count(1) INTO ttl_rates FROM pay.pay_paye_rates;
    IF ttl_rates <= 0 THEN
        FOR a IN 1..5
            LOOP
                INSERT INTO pay.pay_paye_rates(rates_amount, tax_percent, level_order, created_by,
                                               creation_date, last_update_by, last_update_date)
                VALUES (bounds[a], rates[a], a, -1, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'),
                        -1, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'));

            END LOOP;
        SELECT count(1) INTO ttl_rates FROM pay.pay_paye_rates;
    END IF;
    loop_cntr := 1;
    FOR i IN (SELECT rates_amount, tax_percent FROM pay.pay_paye_rates ORDER BY level_order ASC, rates_id ASC)
        LOOP
        -- i will take on the values 1,2,3,4,5 within the loop
        --1=0% 2=5% 3=10% 4=17.5% 5=25%
        --RAISE NOTICE 'loop:%rmng_txbl_incm:%', loop_cntr,rmng_txbl_incm;
            IF loop_cntr <= ttl_rates - 1 THEN
                IF (rmng_txbl_incm >= i.rates_amount) THEN
                    cur_incm := i.rates_amount;
                ELSE
                    cur_incm := rmng_txbl_incm;
                END IF;
                tax_ans := tax_ans + (cur_incm * i.tax_percent);
                rmng_txbl_incm := rmng_txbl_incm - cur_incm;
            ELSIF loop_cntr = ttl_rates THEN
                cur_incm := rmng_txbl_incm;
                tax_ans := tax_ans + (cur_incm * i.tax_percent);
            END IF;
            --RAISE NOTICE 'tax_ans:%cur_incm:%', tax_ans, cur_incm;

            loop_cntr := loop_cntr + 1;
            IF (loop_cntr > ttl_rates)
            THEN
                RETURN tax_ans;
            END IF;
        END LOOP;

    RETURN tax_ans;
END;
$BODY$;

-- FUNCTION: pay.get_gbv_mnthly_sal_usedte(bigint, character varying)

-- DROP FUNCTION pay.get_gbv_mnthly_sal_usedte(bigint, character varying);

CREATE OR REPLACE FUNCTION pay.get_gbv_mnthly_sal_usedte(personid BIGINT,
                                                         paytrnsdte CHARACTER VARYING)
    RETURNS DOUBLE PRECISION
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    sal_val     DOUBLE PRECISION  := 0;
    prsnenddte  CHARACTER VARYING := '';
    prsnstrtdte CHARACTER VARYING := '';
    nwpaydte    CHARACTER VARYING := '';
    initchar    CHARACTER VARYING := '31';
BEGIN
    nwpaydte := to_char(to_timestamp(paytrnsdte || ' 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS');
    IF chartonumeric(upper(substr(nwpaydte, 8, 4))) % 100 = 0 THEN
        IF chartonumeric(upper(substr(nwpaydte, 8, 4))) % 400 = 0 AND upper(substr(nwpaydte, 4, 3)) = 'FEB' THEN
            initchar := '29';
        END IF;
    ELSIF upper(substr(nwpaydte, 4, 3)) = 'FEB' THEN
        IF chartonumeric(upper(substr(nwpaydte, 8, 4))) % 4 = 0 THEN
            initchar := '29';
        ELSE
            initchar := '28';
        END IF;
    ELSIF upper(substr(nwpaydte, 4, 3)) IN ('SEP', 'APR', 'JUN', 'NOV') THEN
        initchar := '30';
    ELSE
        initchar := '31';
    END IF;
    --RAISE NOTICE 'Init Char is %', initchar;
    SELECT CASE
               WHEN to_timestamp('01' || substr(nwpaydte, 3), 'DD-Mon-YYYY HH24:MI:SS') >=
                    to_timestamp(valid_start_date || ' 00:00:00', 'YYYY-MM-DD HH24:MI:SS') THEN
                   '01' || substr(nwpaydte, 3)
               ELSE
                   to_char(to_timestamp(valid_start_date || ' 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),
                           'DD-Mon-YYYY HH24:MI:SS') END,
           CASE
               WHEN to_timestamp(initchar || substr(nwpaydte, 3), 'DD-Mon-YYYY HH24:MI:SS') <=
                    to_timestamp(valid_end_date || ' 23:59:59', 'YYYY-MM-DD HH24:MI:SS') THEN
                   initchar || substr(nwpaydte, 3)
               ELSE
                   to_char(to_timestamp(valid_end_date || ' 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),
                           'DD-Mon-YYYY HH24:MI:SS') END
    INTO
        prsnstrtdte, prsnenddte
    FROM pasn.prsn_prsntyps
    WHERE person_id = $1
      AND to_timestamp(valid_start_date, 'YYYY-MM-DD HH24:MI:SS') <=
          to_timestamp(initchar || substr(nwpaydte, 3), 'DD-Mon-YYYY HH24:MI:SS')
      AND to_timestamp(valid_end_date, 'YYYY-MM-DD HH24:MI:SS') >=
          to_timestamp('01' || substr(nwpaydte, 3), 'DD-Mon-YYYY HH24:MI:SS')
      AND prsn_type = 'Employee'
    ORDER BY valid_end_date DESC, valid_start_date DESC
    LIMIT 1 OFFSET 0;

    --RAISE NOTICE 'Prsn Dates are % and %', prsnstrtdte, prsnenddte;
    --RAISE NOTICE 'Pay Dates are % and %', '01'||substr(nwpaydte,3), initchar ||substr(nwpaydte,3);
    SELECT num_value * (extract('days' FROM age(to_timestamp(prsnenddte, 'DD-Mon-YYYY HH24:MI:SS'),
                                                to_timestamp(prsnstrtdte, 'DD-Mon-YYYY HH24:MI:SS')))
        / extract('days' FROM age(to_timestamp(initchar || substr(nwpaydte, 3), 'DD-Mon-YYYY HH24:MI:SS'),
                                  to_timestamp('01' || substr(nwpaydte, 3), 'DD-Mon-YYYY HH24:MI:SS'))))
    INTO sal_val
    FROM pay.pay_global_values_det
    WHERE global_value_hdr_id =
          (SELECT global_val_id FROM pay.pay_global_values_hdr WHERE global_value_name = 'Monthly Salary')
      AND criteria_type = 'Divisions/Groups'
      AND criteria_val_id = org.get_div_id(org.get_div_name(
            pasn.get_prsn_divid_of_spctype1($1, 'Pay/Remuneration', '01' || substr(nwpaydte, 3),
                                            initchar || substr(nwpaydte, 3))));

    RETURN COALESCE(sal_val, 0);
END;
$BODY$;

CREATE OR REPLACE FUNCTION pay.get_gbv_sal_usedte_gnrl(personid BIGINT,
                                                       paytrnsdte CHARACTER VARYING,
                                                       crtriatyp CHARACTER VARYING,
                                                       gbvhdrname CHARACTER VARYING,
                                                       prsntypes CHARACTER VARYING)
    RETURNS DOUBLE PRECISION
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    sal_val     DOUBLE PRECISION  := 0;
    prsnenddte  CHARACTER VARYING := '';
    prsnstrtdte CHARACTER VARYING := '';
    nwpaydte    CHARACTER VARYING := '';
    initchar    CHARACTER VARYING := '31';
    --prsnTypes character varying := '';
    crtriaID    INTEGER           := -1;
BEGIN
    nwpaydte := to_char(to_timestamp(paytrnsdte || ' 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS');

    IF chartonumeric(upper(substr(nwpaydte, 8, 4))) % 100 = 0 THEN
        IF chartonumeric(upper(substr(nwpaydte, 8, 4))) % 400 = 0 AND upper(substr(nwpaydte, 4, 3)) = 'FEB' THEN
            initchar := '29';
        END IF;
    ELSIF upper(substr(nwpaydte, 4, 3)) = 'FEB' THEN
        IF chartonumeric(upper(substr(nwpaydte, 8, 4))) % 4 = 0 THEN
            initchar := '29';
        ELSE
            initchar := '28';
        END IF;
    ELSIF upper(substr(nwpaydte, 4, 3)) IN ('SEP', 'APR', 'JUN', 'NOV') THEN
        initchar := '30';
    ELSE
        initchar := '31';
    END IF;
    --RAISE NOTICE 'Init Char is %', initchar;

    --prsnTypes := '''Staff'',''Member.Staff'',''National Service Personnel'',''Employee''';
    SELECT a.prsnstrtdte,
           a.prsnenddte
    INTO
        prsnstrtdte, prsnenddte
    FROM pay.get_prsntyp_dates(personid, prsnTypes, initchar, nwpaydte) a;

    /*SELECT CASE WHEN to_timestamp('01' ||substr(nwpaydte,3),'DD-Mon-YYYY HH24:MI:SS') >=
    to_timestamp(valid_start_date ||' 00:00:00','YYYY-MM-DD HH24:MI:SS') THEN
    '01' ||substr(nwpaydte,3)
    ELSE
    to_char(to_timestamp(valid_start_date ||' 00:00:00','YYYY-MM-DD HH24:MI:SS'),'DD-Mon-YYYY HH24:MI:SS') END,
    CASE WHEN to_timestamp(initchar ||substr(nwpaydte,3),'DD-Mon-YYYY HH24:MI:SS') <=
    to_timestamp(valid_end_date ||' 23:59:59','YYYY-MM-DD HH24:MI:SS') THEN
    initchar ||substr(nwpaydte,3)
    ELSE
    to_char(to_timestamp(valid_end_date ||' 00:00:00','YYYY-MM-DD HH24:MI:SS'),'DD-Mon-YYYY HH24:MI:SS') END
    FROM pasn.prsn_prsntyps
    WHERE person_id = $1 and
     to_timestamp(valid_start_date,'YYYY-MM-DD HH24:MI:SS') <= to_timestamp(initchar ||substr(nwpaydte,3),'DD-Mon-YYYY HH24:MI:SS')
      and to_timestamp(valid_end_date,'YYYY-MM-DD HH24:MI:SS') >= to_timestamp('01' ||substr(nwpaydte,3),'DD-Mon-YYYY HH24:MI:SS')
      and prsn_type IN ()
      ORDER BY valid_end_date DESC, valid_start_date DESC LIMIT 1 OFFSET 0;*/

    IF crtriatyp = 'Position' THEN
        crtriaID := pasn.get_prsn_posid($1);
    ELSIF crtriatyp = 'Divisions/Groups' THEN
        crtriaID := pasn.get_prsn_divid($1);
    ELSIF crtriatyp = 'Grade' THEN
        crtriaID := pasn.get_prsn_grdid($1);
    ELSIF crtriatyp = 'Job' THEN
        crtriaID := pasn.get_prsn_jobid($1);
    ELSIF crtriatyp = 'Site/Location' THEN
        crtriaID := pasn.get_prsn_siteid($1);
    ELSIF crtriatyp = 'Person Type' THEN
        crtriaID := pasn.get_prsn_typid($1);
    END IF;

    --RAISE NOTICE 'Prsn Dates are % and %', prsnstrtdte, prsnenddte;
    --RAISE NOTICE 'Pay Dates are % and %', '01'||substr(nwpaydte,3), initchar ||substr(nwpaydte,3);

    SELECT num_value * (extract('days' FROM age(to_timestamp(prsnenddte, 'DD-Mon-YYYY HH24:MI:SS'),
                                                to_timestamp(prsnstrtdte, 'DD-Mon-YYYY HH24:MI:SS')))
        / extract('days' FROM age(to_timestamp(initchar || substr(nwpaydte, 3), 'DD-Mon-YYYY HH24:MI:SS'),
                                  to_timestamp('01' || substr(nwpaydte, 3), 'DD-Mon-YYYY HH24:MI:SS'))))
    INTO sal_val
    FROM pay.pay_global_values_det
    WHERE global_value_hdr_id =
          (SELECT global_val_id FROM pay.pay_global_values_hdr WHERE global_value_name = gbvhdrname)
      AND criteria_type = crtriatyp
      AND criteria_val_id = crtriaID;

    RETURN COALESCE(sal_val, 0);
END;
$BODY$;

CREATE OR REPLACE FUNCTION pay.get_gbv_sal_usedte_grd(personid BIGINT,
                                                      paytrnsdte CHARACTER VARYING)
    RETURNS DOUBLE PRECISION
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    sal_val     DOUBLE PRECISION  := 0;
    prsnenddte  CHARACTER VARYING := '';
    prsnstrtdte CHARACTER VARYING := '';
    nwpaydte    CHARACTER VARYING := '';
    initchar    CHARACTER VARYING := '31';
BEGIN
    nwpaydte := to_char(to_timestamp(paytrnsdte || ' 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS');
    IF chartonumeric(upper(substr(nwpaydte, 8, 4))) % 100 = 0 THEN
        IF chartonumeric(upper(substr(nwpaydte, 8, 4))) % 400 = 0 AND upper(substr(nwpaydte, 4, 3)) = 'FEB' THEN
            initchar := '29';
        END IF;
    ELSIF upper(substr(nwpaydte, 4, 3)) = 'FEB' THEN
        IF chartonumeric(upper(substr(nwpaydte, 8, 4))) % 4 = 0 THEN
            initchar := '29';
        ELSE
            initchar := '28';
        END IF;
    ELSIF upper(substr(nwpaydte, 4, 3)) IN ('SEP', 'APR', 'JUN', 'NOV') THEN
        initchar := '30';
    ELSE
        initchar := '31';
    END IF;
    --RAISE NOTICE 'Init Char is %', initchar;
    SELECT CASE
               WHEN to_timestamp('01' || substr(nwpaydte, 3), 'DD-Mon-YYYY HH24:MI:SS') >=
                    to_timestamp(valid_start_date || ' 00:00:00', 'YYYY-MM-DD HH24:MI:SS') THEN
                   '01' || substr(nwpaydte, 3)
               ELSE
                   to_char(to_timestamp(valid_start_date || ' 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),
                           'DD-Mon-YYYY HH24:MI:SS') END,
           CASE
               WHEN to_timestamp(initchar || substr(nwpaydte, 3), 'DD-Mon-YYYY HH24:MI:SS') <=
                    to_timestamp(valid_end_date || ' 23:59:59', 'YYYY-MM-DD HH24:MI:SS') THEN
                   initchar || substr(nwpaydte, 3)
               ELSE
                   to_char(to_timestamp(valid_end_date || ' 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),
                           'DD-Mon-YYYY HH24:MI:SS') END
    INTO
        prsnstrtdte, prsnenddte
    FROM pasn.prsn_prsntyps
    WHERE person_id = $1
      AND to_timestamp(valid_start_date, 'YYYY-MM-DD HH24:MI:SS') <=
          to_timestamp(initchar || substr(nwpaydte, 3), 'DD-Mon-YYYY HH24:MI:SS')
      AND to_timestamp(valid_end_date, 'YYYY-MM-DD HH24:MI:SS') >=
          to_timestamp('01' || substr(nwpaydte, 3), 'DD-Mon-YYYY HH24:MI:SS')
      AND prsn_type IN ('Member', 'Member.Staff')
    ORDER BY valid_end_date DESC, valid_start_date DESC
    LIMIT 1 OFFSET 0;

    --RAISE NOTICE 'Prsn Dates are % and %', prsnstrtdte, prsnenddte;
    --RAISE NOTICE 'Pay Dates are % and %', '01' || substr(nwpaydte, 3), initchar || substr(nwpaydte, 3);
    SELECT num_value * (extract('days' FROM age(to_timestamp(prsnenddte, 'DD-Mon-YYYY HH24:MI:SS'),
                                                to_timestamp(prsnstrtdte, 'DD-Mon-YYYY HH24:MI:SS')))
        / extract('days' FROM age(to_timestamp(initchar || substr(nwpaydte, 3), 'DD-Mon-YYYY HH24:MI:SS'),
                                  to_timestamp('01' || substr(nwpaydte, 3), 'DD-Mon-YYYY HH24:MI:SS'))))
    INTO sal_val
    FROM pay.pay_global_values_det
    WHERE global_value_hdr_id =
          (SELECT global_val_id FROM pay.pay_global_values_hdr WHERE global_value_name = '2015 Membership Dues Amounts')
      AND criteria_type = 'Grade'
      AND criteria_val_id = pasn.get_prsn_grdid($1);

    RETURN COALESCE(sal_val, 0);
END;
$BODY$;

CREATE OR REPLACE FUNCTION pay.get_gbv_sal_usedte_pos(personid BIGINT,
                                                      paytrnsdte CHARACTER VARYING)
    RETURNS DOUBLE PRECISION
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    sal_val     DOUBLE PRECISION  := 0;
    prsnenddte  CHARACTER VARYING := '';
    prsnstrtdte CHARACTER VARYING := '';
    nwpaydte    CHARACTER VARYING := '';
    initchar    CHARACTER VARYING := '31';
BEGIN
    nwpaydte := to_char(to_timestamp(paytrnsdte || ' 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS');
    IF chartonumeric(upper(substr(nwpaydte, 8, 4))) % 100 = 0 THEN
        IF chartonumeric(upper(substr(nwpaydte, 8, 4))) % 400 = 0 AND upper(substr(nwpaydte, 4, 3)) = 'FEB' THEN
            initchar := '29';
        END IF;
    ELSIF upper(substr(nwpaydte, 4, 3)) = 'FEB' THEN
        IF chartonumeric(upper(substr(nwpaydte, 8, 4))) % 4 = 0 THEN
            initchar := '29';
        ELSE
            initchar := '28';
        END IF;
    ELSIF upper(substr(nwpaydte, 4, 3)) IN ('SEP', 'APR', 'JUN', 'NOV') THEN
        initchar := '30';
    ELSE
        initchar := '31';
    END IF;
    --RAISE NOTICE 'Init Char is %', initchar;
    SELECT CASE
               WHEN to_timestamp('01' || substr(nwpaydte, 3), 'DD-Mon-YYYY HH24:MI:SS') >=
                    to_timestamp(valid_start_date || ' 00:00:00', 'YYYY-MM-DD HH24:MI:SS') THEN
                   '01' || substr(nwpaydte, 3)
               ELSE
                   to_char(to_timestamp(valid_start_date || ' 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),
                           'DD-Mon-YYYY HH24:MI:SS') END,
           CASE
               WHEN to_timestamp(initchar || substr(nwpaydte, 3), 'DD-Mon-YYYY HH24:MI:SS') <=
                    to_timestamp(valid_end_date || ' 23:59:59', 'YYYY-MM-DD HH24:MI:SS') THEN
                   initchar || substr(nwpaydte, 3)
               ELSE
                   to_char(to_timestamp(valid_end_date || ' 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),
                           'DD-Mon-YYYY HH24:MI:SS') END
    INTO
        prsnstrtdte, prsnenddte
    FROM pasn.prsn_prsntyps
    WHERE person_id = $1
      AND to_timestamp(valid_start_date, 'YYYY-MM-DD HH24:MI:SS') <=
          to_timestamp(initchar || substr(nwpaydte, 3), 'DD-Mon-YYYY HH24:MI:SS')
      AND to_timestamp(valid_end_date, 'YYYY-MM-DD HH24:MI:SS') >=
          to_timestamp('01' || substr(nwpaydte, 3), 'DD-Mon-YYYY HH24:MI:SS')
      AND prsn_type IN ('Staff', 'Member.Staff', 'National Service Personnel', 'Employee')
    ORDER BY valid_end_date DESC, valid_start_date DESC
    LIMIT 1 OFFSET 0;

    --RAISE NOTICE 'Prsn Dates are % and %', prsnstrtdte, prsnenddte;
    --RAISE NOTICE 'Pay Dates are % and %', '01' || substr(nwpaydte, 3), initchar || substr(nwpaydte, 3);
    SELECT num_value * (extract('days' FROM age(to_timestamp(prsnenddte, 'DD-Mon-YYYY HH24:MI:SS'),
                                                to_timestamp(prsnstrtdte, 'DD-Mon-YYYY HH24:MI:SS')))
        / extract('days' FROM age(to_timestamp(initchar || substr(nwpaydte, 3), 'DD-Mon-YYYY HH24:MI:SS'),
                                  to_timestamp('01' || substr(nwpaydte, 3), 'DD-Mon-YYYY HH24:MI:SS'))))
    INTO sal_val
    FROM pay.pay_global_values_det
    WHERE global_value_hdr_id =
          (SELECT global_val_id FROM pay.pay_global_values_hdr WHERE global_value_name = 'Staff Salaries')
      AND criteria_type = 'Position'
      AND criteria_val_id = pasn.get_prsn_posid($1);

    RETURN COALESCE(sal_val, 0);
END;
$BODY$;

CREATE OR REPLACE FUNCTION pay.get_gbv_salary(
    personid BIGINT)
    RETURNS NUMERIC
    LANGUAGE 'sql'
    COST 100
    VOLATILE
AS
$BODY$
SELECT num_value
FROM pay.pay_global_values_det
WHERE global_value_hdr_id =
      (SELECT global_val_id FROM pay.pay_global_values_hdr WHERE global_value_name = 'Monthly Salary')
  AND criteria_type = 'Divisions/Groups'
  AND criteria_val_id = org.get_div_id(org.get_div_name(pasn.get_prsn_divid_of_spctype($1, 'Pay/Remuneration')))
$BODY$;

CREATE OR REPLACE FUNCTION pay.get_gbv_val_gnrl(personid BIGINT,
                                                paytrnsdte CHARACTER VARYING,
                                                crtriatyp CHARACTER VARYING,
                                                gbvhdrname CHARACTER VARYING,
                                                prsntypes CHARACTER VARYING)
    RETURNS DOUBLE PRECISION
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    sal_val     DOUBLE PRECISION  := 0;
    prsnenddte  CHARACTER VARYING := '';
    prsnstrtdte CHARACTER VARYING := '';
    nwpaydte    CHARACTER VARYING := '';
    initchar    CHARACTER VARYING := '31';
    --prsnTypes character varying := '';
    crtriaID    INTEGER           := -1;
BEGIN
    nwpaydte := to_char(to_timestamp(paytrnsdte || ' 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS');

    IF chartonumeric(upper(substr(nwpaydte, 8, 4))) % 100 = 0 THEN
        IF chartonumeric(upper(substr(nwpaydte, 8, 4))) % 400 = 0 AND upper(substr(nwpaydte, 4, 3)) = 'FEB' THEN
            initchar := '29';
        END IF;
    ELSIF upper(substr(nwpaydte, 4, 3)) = 'FEB' THEN
        IF chartonumeric(upper(substr(nwpaydte, 8, 4))) % 4 = 0 THEN
            initchar := '29';
        ELSE
            initchar := '28';
        END IF;
    ELSIF upper(substr(nwpaydte, 4, 3)) IN ('SEP', 'APR', 'JUN', 'NOV') THEN
        initchar := '30';
    ELSE
        initchar := '31';
    END IF;
    --RAISE NOTICE 'Init Char is %', initchar;

    --prsnTypes := '''Staff'',''Member.Staff'',''National Service Personnel'',''Employee''';
    SELECT a.prsnstrtdte,
           a.prsnenddte
    INTO
        prsnstrtdte, prsnenddte
    FROM pay.get_prsntyp_dates(personid, prsnTypes, initchar, nwpaydte) a;

    /*SELECT CASE WHEN to_timestamp('01' ||substr(nwpaydte,3),'DD-Mon-YYYY HH24:MI:SS') >=
    to_timestamp(valid_start_date ||' 00:00:00','YYYY-MM-DD HH24:MI:SS') THEN
    '01' ||substr(nwpaydte,3)
    ELSE
    to_char(to_timestamp(valid_start_date ||' 00:00:00','YYYY-MM-DD HH24:MI:SS'),'DD-Mon-YYYY HH24:MI:SS') END,
    CASE WHEN to_timestamp(initchar ||substr(nwpaydte,3),'DD-Mon-YYYY HH24:MI:SS') <=
    to_timestamp(valid_end_date ||' 23:59:59','YYYY-MM-DD HH24:MI:SS') THEN
    initchar ||substr(nwpaydte,3)
    ELSE
    to_char(to_timestamp(valid_end_date ||' 00:00:00','YYYY-MM-DD HH24:MI:SS'),'DD-Mon-YYYY HH24:MI:SS') END
    FROM pasn.prsn_prsntyps
    WHERE person_id = $1 and
     to_timestamp(valid_start_date,'YYYY-MM-DD HH24:MI:SS') <= to_timestamp(initchar ||substr(nwpaydte,3),'DD-Mon-YYYY HH24:MI:SS')
      and to_timestamp(valid_end_date,'YYYY-MM-DD HH24:MI:SS') >= to_timestamp('01' ||substr(nwpaydte,3),'DD-Mon-YYYY HH24:MI:SS')
      and prsn_type IN ()
      ORDER BY valid_end_date DESC, valid_start_date DESC LIMIT 1 OFFSET 0;*/

    IF crtriatyp = 'Position' THEN
        crtriaID := pasn.get_prsn_posid($1);
    ELSIF crtriatyp = 'Divisions/Groups' THEN
        crtriaID := pasn.get_prsn_divid($1);
    ELSIF crtriatyp = 'Grade' THEN
        crtriaID := pasn.get_prsn_grdid($1);
    ELSIF crtriatyp = 'Job' THEN
        crtriaID := pasn.get_prsn_jobid($1);
    ELSIF crtriatyp = 'Site/Location' THEN
        crtriaID := pasn.get_prsn_siteid($1);
    ELSIF crtriatyp = 'Person Type' THEN
        crtriaID := pasn.get_prsn_typid($1);
    END IF;

    --RAISE NOTICE 'Prsn Dates are % and %', prsnstrtdte, prsnenddte;
    --RAISE NOTICE 'Pay Dates are % and %', '01' || substr(nwpaydte, 3), initchar || substr(nwpaydte, 3);

    SELECT num_value
    INTO sal_val
    FROM pay.pay_global_values_det
    WHERE global_value_hdr_id =
          (SELECT global_val_id FROM pay.pay_global_values_hdr WHERE global_value_name = gbvhdrname)
      AND criteria_type = crtriatyp
      AND criteria_val_id = crtriaID;

    RETURN COALESCE(sal_val, 0);
END;
$BODY$;

CREATE OR REPLACE FUNCTION pay.get_prsntyp_dates(prsnid BIGINT,
                                                 prsntypes CHARACTER VARYING,
                                                 initchar CHARACTER VARYING,
                                                 nwpaydte CHARACTER VARYING)
    RETURNS TABLE
            (
                prsnstrtdte TEXT,
                prsnenddte  TEXT
            )
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
    ROWS 1000
AS
$BODY$
DECLARE
    whereclause TEXT;
    fullsql     TEXT;
    records     RECORD;
    exeQuery    TEXT;
    --'Staff','Member.Staff','National Service Personnel','Employee'
BEGIN

    fullsql := 'SELECT CASE WHEN to_timestamp(''01'' ||substr(''' || nwpaydte || ''',3),''DD-Mon-YYYY HH24:MI:SS'') >=
to_timestamp(valid_start_date ||'' 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') THEN
''01'' ||substr(''' || nwpaydte || ''',3)
ELSE
to_char(to_timestamp(valid_start_date ||'' 00:00:00'',''YYYY-MM-DD HH24:MI:SS''),''DD-Mon-YYYY HH24:MI:SS'') END prsnstrtdte,
CASE WHEN to_timestamp(''' || initchar || ''' ||substr(''' || nwpaydte || ''',3),''DD-Mon-YYYY HH24:MI:SS'') <=
to_timestamp(valid_end_date ||'' 23:59:59'',''YYYY-MM-DD HH24:MI:SS'') THEN
' || initchar || ' ||substr(''' || nwpaydte || ''',3)
ELSE
to_char(to_timestamp(valid_end_date ||'' 00:00:00'',''YYYY-MM-DD HH24:MI:SS''),''DD-Mon-YYYY HH24:MI:SS'') END prsnenddte
FROM pasn.prsn_prsntyps
WHERE person_id = ' || prsnid || ' and
 to_timestamp(valid_start_date,''YYYY-MM-DD HH24:MI:SS'') <= to_timestamp(''' || initchar || ''' ||substr(''' ||
               nwpaydte || ''',3),''DD-Mon-YYYY HH24:MI:SS'')
  and to_timestamp(valid_end_date,''YYYY-MM-DD HH24:MI:SS'') >= to_timestamp(''01'' ||substr(''' || nwpaydte || ''',3),''DD-Mon-YYYY HH24:MI:SS'')
  and prsn_type IN (' || prsntypes || ')
  ORDER BY valid_end_date DESC, valid_start_date DESC LIMIT 1 OFFSET 0';

    --RAISE NOTICE 'FULL Query = "%"', fullsql;
    exeQuery := '' || fullsql || '';
    RETURN QUERY EXECUTE exeQuery;
END;
$BODY$;

-- FUNCTION: inv.approve_cnsgn_rcpt(bigint, character varying, integer, bigint)

-- DROP FUNCTION inv.approve_cnsgn_rcpt(bigint, character varying, integer, bigint);

CREATE OR REPLACE FUNCTION inv.approve_cnsgn_rcpt(p_dochdrid bigint,
                                                  p_dockind character varying,
                                                  p_orgid integer,
                                                  p_who_rn bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    rd1                 RECORD;
    rd2                 RECORD;
    rd3                 RECORD;
    msgs                TEXT                    := 'ERROR:';
    v_reslt_1           TEXT                    := '';
    v_funcCurrID        INTEGER                 := -1;
    v_dfltRcvblAcntID   INTEGER                 := -1;
    v_parAcctInvAcrlID  INTEGER                 := -1;
    v_parAcctInvAcrlID1 INTEGER                 := -1;
    v_dfltBadDbtAcntID  INTEGER                 := -1;
    v_dfltLbltyAccnt    INTEGER                 := -1;
    v_dfltInvAcntID     INTEGER                 := -1;
    v_dfltCGSAcntID     INTEGER                 := -1;
    v_dfltExpnsAcntID   INTEGER                 := -1;
    v_dfltRvnuAcntID    INTEGER                 := -1;
    v_dfltSRAcntID      INTEGER                 := -1;
    v_dfltCashAcntID    INTEGER                 := -1;
    v_dfltCheckAcntID   INTEGER                 := -1;
    v_orgid             INTEGER                 := -1;
    v_clientID          BIGINT                  := -1;
    v_clientSiteID      BIGINT                  := -1;
    v_docDte            CHARACTER VARYING(21)   := '';
    v_DocType           CHARACTER VARYING(200)  := '';
    v_srcDocType        CHARACTER VARYING(200)  := '';
    v_apprvlStatus      CHARACTER VARYING(100)  := '';
    v_entrdCurrID       INTEGER                 := -1;
    v_invcAmnt          NUMERIC                 := 0;
    v_itmID             BIGINT                  := -1;
    v_storeID           BIGINT                  := -1;
    v_nwlnID            BIGINT                  := -1;
    v_curid             INTEGER                 := -1;
    v_stckID            BIGINT                  := -1;
    v_cnsgmntID         BIGINT                  := -1;
    v_slctdAccntIDs     CHARACTER VARYING(4000) := '';
    v_AcntArrys         TEXT[];
    v_itmInvAcntID      INTEGER                 := -1;
    v_cogsID            INTEGER                 := -1;
    v_salesRevID        INTEGER                 := -1;
    v_salesRetID        INTEGER                 := -1;
    v_purcRetID         INTEGER                 := -1;
    v_expnsID           INTEGER                 := -1;
    v_itmInvAcntID1     INTEGER                 := -1;
    v_cogsID1           INTEGER                 := -1;
    v_salesRevID1       INTEGER                 := -1;
    v_salesRetID1       INTEGER                 := -1;
    v_purcRetID1        INTEGER                 := -1;
    v_expnsID1          INTEGER                 := -1;
    v_srclnID           BIGINT                  := -1;
    v_qty               NUMERIC                 := 0;
    v_price             NUMERIC                 := 0;
    v_lineid            BIGINT                  := -1;
    v_pyblHdrID         BIGINT                  := -1;
    v_pyblDocNum        CHARACTER VARYING(200)  := '';
    v_inCurCde          CHARACTER VARYING(200)  := '';
    v_exchRate          NUMERIC                 := 1;
    v_srcDocID          BIGINT                  := -1;
    v_dateStr           CHARACTER VARYING(21)   := '';
    v_cstmrNm           CHARACTER VARYING(200)  := '';
    v_docDesc           CHARACTER VARYING(300)  := '';
    v_itmDesc           CHARACTER VARYING(200)  := '';
    v_itmType           CHARACTER VARYING(200)  := '';
    v_PrsnID            BIGINT                  := -1;
    v_BranchID          INTEGER                 := -1;
    v_PrsnBrnchID       INTEGER                 := -1;
BEGIN
    /* 1. Update Item Balances
     * 2. checkNCreateSalesPyblsHdr
     */
    v_PrsnID := sec.get_usr_prsn_id(p_who_rn);
    v_PrsnBrnchID := pasn.get_prsn_siteid(v_PrsnID);
    v_orgid := p_orgid;
    IF p_DocKind = 'Receipt'
    THEN
        FOR rd2 IN (SELECT to_char(to_timestamp(date_received || ' 12:00:00', 'YYYY-MM-DD HH24:MI:SS'),
                                   'DD-Mon-YYYY HH24:MI:SS')             invc_date,
                           rcpt_number,
                           (CASE
                                WHEN coalesce(a.po_id, -1) > 0 THEN 'Purchase Order Receipt'
                                ELSE 'Miscellaneous Receipt' END)        rcpt_type,
                           description,
                           po_id,
                           supplier_id,
                           scm.get_cstmr_splr_name(a.supplier_id)        cstmr_splr_name,
                           site_id,
                           approval_status,
                           next_approval_status,
                           org_id,
                           payables_accnt_id,
                           'Purchase Order'                              src_doc_type,
                           round(scm.getcnsgnrcptgrndamnt(a.rcpt_id), 2) invoice_amount,
                           doc_curr_id,
                           exchng_rate
                    FROM inv.inv_consgmt_rcpt_hdr a
                    WHERE a.rcpt_id = p_dochdrid)
            LOOP
                v_clientID := rd2.supplier_id;
                v_clientSiteID := rd2.site_id;
                v_docDte := rd2.invc_date;
                v_DocType := rd2.rcpt_type;
                v_srcDocType := rd2.src_doc_type;
                v_apprvlStatus := rd2.approval_status;
                v_invcAmnt := rd2.invoice_amount;
                v_orgid := rd2.org_id;
                v_dateStr := rd2.invc_date;
                v_cstmrNm := rd2.cstmr_splr_name;
                v_docDesc := substring(rd2.description, 1, 299);
                v_srcDocID := rd2.po_id;
                v_exchRate := rd2.exchng_rate;
                v_entrdCurrID := rd2.doc_curr_id;
            END LOOP;
        v_funcCurrID := org.get_orgfunc_crncy_id(v_orgid);
        IF v_entrdCurrID <= 0 THEN
            v_entrdCurrID := v_funcCurrID;
        END IF;
        IF (v_srcDocID > 0)
        THEN
            v_exchRate :=
                    gst.getGnrlRecNm('scm.scm_prchs_docs_hdr', 'prchs_doc_hdr_id', 'exchng_rate',
                                     v_srcDocID) :: NUMERIC;
            v_entrdCurrID :=
                    gst.getGnrlRecNm('scm.scm_prchs_docs_hdr', 'prchs_doc_hdr_id', 'prntd_doc_curr_id',
                                     v_srcDocID) :: INTEGER;
            IF v_exchRate = 0 THEN
                v_exchRate := round(accb.get_ltst_exchrate(v_entrdCurrID, v_funcCurrID, v_dateStr, v_orgid), 15);
            END IF;
        END IF;

        IF v_exchRate = 0 THEN
            v_exchRate := round(accb.get_ltst_exchrate(v_entrdCurrID, v_funcCurrID, v_dateStr, v_orgid), 15);
        END IF;

        v_inCurCde := gst.get_pssbl_val(v_entrdCurrID);
        FOR rd3 IN (SELECT itm_inv_asst_acnt_id,
                           cost_of_goods_acnt_id,
                           expense_acnt_id,
                           prchs_rtrns_acnt_id,
                           rvnu_acnt_id,
                           sales_rtrns_acnt_id,
                           sales_cash_acnt_id,
                           sales_check_acnt_id,
                           sales_rcvbl_acnt_id,
                           rcpt_cash_acnt_id,
                           rcpt_lblty_acnt_id,
                           inv_adjstmnts_lblty_acnt_id,
                           sales_dscnt_accnt,
                           prchs_dscnt_accnt,
                           sales_lblty_acnt_id,
                           bad_debt_acnt_id,
                           rcpt_rcvbl_acnt_id,
                           petty_cash_acnt_id
                    FROM scm.scm_dflt_accnts
                    WHERE org_id = v_orgid)
            LOOP
                v_dfltRcvblAcntID := rd3.sales_rcvbl_acnt_id;
                v_dfltBadDbtAcntID := rd3.bad_debt_acnt_id;
                v_dfltLbltyAccnt := rd3.rcpt_lblty_acnt_id;
                v_parAcctInvAcrlID1 := rd3.inv_adjstmnts_lblty_acnt_id;
                v_dfltInvAcntID := rd3.itm_inv_asst_acnt_id;
                v_dfltCGSAcntID := rd3.cost_of_goods_acnt_id;
                v_dfltExpnsAcntID := rd3.expense_acnt_id;
                v_dfltRvnuAcntID := rd3.rvnu_acnt_id;
                v_dfltSRAcntID := rd3.sales_rtrns_acnt_id;
                v_dfltCashAcntID := rd3.sales_cash_acnt_id;
                v_dfltCheckAcntID := rd3.sales_check_acnt_id;
            END LOOP;
        v_parAcctInvAcrlID := org.get_accnt_id_brnch_eqv(v_BranchID, v_parAcctInvAcrlID1);
        IF (v_apprvlStatus = 'Incomplete')
        THEN
            FOR rd1 IN (SELECT a.s_line_id,
                               a.s_itm_id,
                               a.s_quantity_rcvd,
                               a.s_cost_price,
                               (a.s_quantity_rcvd * a.s_cost_price)                              amnt,
                               a.s_subinv_id,
                               a.s_po_line_id,
                               b.base_uom_id,
                               b.item_code,
                               b.item_desc,
                               c.uom_name,
                               d.cat_name,
                               (b.cogs_acct_id || ',' || b.sales_rev_accnt_id || ',' || b.sales_ret_accnt_id || ',' ||
                                b.purch_ret_accnt_id || ',' || b.expense_accnt_id || ',' ||
                                b.inv_asset_acct_id)                                             itm_accnts,
                               b.item_type,
                               to_char(to_timestamp(s_expiry_date, 'YYYY-MM-DD'), 'DD-Mon-YYYY') n_expiry_date,
                               a.s_expiry_date,
                               a.s_manfct_date,
                               a.s_lifespan,
                               a.s_tag_number,
                               a.s_serial_number,
                               a.s_consignmt_condition,
                               a.s_remarks
                        FROM inv.inv_svd_consgmt_rcpt_det a,
                             inv.inv_itm_list b,
                             inv.unit_of_measure c,
                             inv.inv_product_categories d
                        WHERE (a.s_rcpt_id = p_dochdrid AND a.s_rcpt_id > 0
                            AND a.s_itm_id = b.item_id AND b.base_uom_id = c.uom_id AND
                               d.cat_id = b.category_id)
                        ORDER BY a.s_line_id)
                LOOP
                    v_itmID := rd1.s_itm_id;
                    v_storeID := rd1.s_subinv_id;
                    v_BranchID := coalesce(inv.get_store_brnch_id(v_storeID), -1);
                    IF v_BranchID <= 0 AND v_PrsnBrnchID > 0 THEN
                        v_BranchID := v_PrsnBrnchID;
                    END IF;
                    v_curid := v_entrdCurrID;
                    v_itmDesc := rd1.item_desc;
                    v_itmType := rd1.item_type;

                    v_stckID := inv.getItemStockID(v_itmID, v_storeID);

                    IF coalesce(v_stckID, -1) <= 0 AND v_storeID > 0 AND v_itmID > 0 AND (v_itmType ILIKE '%Inventory%'
                        OR v_itmType ILIKE '%Fixed Assets%') THEN
                        INSERT INTO inv.inv_stock(itm_id, subinv_id, created_by, creation_date, last_update_by,
                                                  last_update_date,
                                                  shelves, start_date, end_date, org_id, shelves_ids)
                        VALUES (v_itmID, v_storeID, p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn,
                                to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), '',
                                to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), '4000-12-31 23:59:59', v_orgid, '');
                        v_stckID := inv.getItemStockID(v_itmID, v_storeID);
                    END IF;
                    v_slctdAccntIDs := BTRIM(rd1.itm_accnts, ',');
                    v_AcntArrys := string_to_array(v_slctdAccntIDs, ',');

                    v_itmInvAcntID1 := -1;
                    v_cogsID1 := -1;
                    v_salesRevID1 := -1;
                    v_salesRetID1 := -1;
                    v_purcRetID1 := -1;
                    v_expnsID1 := -1;

                    FOR z IN 1..array_length(v_AcntArrys, 1)
                        LOOP
                            IF z = 1 THEN
                                v_cogsID1 := v_AcntArrys[z];
                            ELSIF z = 2 THEN
                                v_salesRevID1 := v_AcntArrys[z];
                            ELSIF z = 3 THEN
                                v_salesRetID1 := v_AcntArrys[z];
                            ELSIF z = 4 THEN
                                v_purcRetID1 := v_AcntArrys[z];
                            ELSIF z = 5 THEN
                                v_expnsID1 := v_AcntArrys[z];
                            ELSE
                                v_itmInvAcntID1 := v_AcntArrys[z];
                            END IF;
                        END LOOP;
                    IF (v_itmInvAcntID1 <= 0) THEN
                        v_itmInvAcntID1 := v_dfltInvAcntID;
                    END IF;
                    IF (v_cogsID1 <= 0) THEN
                        v_cogsID1 := v_dfltCGSAcntID;
                    END IF;
                    IF (v_salesRevID1 <= 0) THEN
                        v_salesRevID1 := v_dfltRvnuAcntID;
                    END IF;
                    IF (v_salesRetID1 <= 0) THEN
                        v_salesRetID1 := v_dfltSRAcntID;
                    END IF;
                    IF (v_expnsID1 <= 0) THEN
                        v_expnsID1 := v_dfltExpnsAcntID;
                    END IF;
                    v_itmInvAcntID := org.get_accnt_id_brnch_eqv(v_BranchID, v_itmInvAcntID1);
                    v_cogsID := org.get_accnt_id_brnch_eqv(v_BranchID, v_cogsID1);
                    v_salesRevID := org.get_accnt_id_brnch_eqv(v_BranchID, v_salesRevID1);
                    v_salesRetID := org.get_accnt_id_brnch_eqv(v_BranchID, v_salesRetID1);
                    v_expnsID := org.get_accnt_id_brnch_eqv(v_BranchID, v_expnsID1);
                    v_purcRetID := org.get_accnt_id_brnch_eqv(v_BranchID, v_purcRetID1);

                    v_srclnID := rd1.s_po_line_id;
                    v_qty := rd1.s_quantity_rcvd;
                    v_price := rd1.s_cost_price * v_exchRate;
                    v_lineid := rd1.s_line_id;
                    v_reslt_1 := 'SUCCESS:';
                    --msgs := 'item_desc:' || rd1.item_desc || '::' || v_cnsgmntIDs || '::Cnt::' || array_length(v_AcntArrys, 1);
                    v_cnsgmntID := inv.getConsignmentID(v_itmID, v_storeID, rd1.n_expiry_date, v_price);
                    IF (v_itmID > 0 AND v_storeID > 0 AND v_stckID > 0 AND v_cnsgmntID > 0)
                    THEN
                        v_nwlnID := nextval('inv.inv_consgmt_rcpt_det_line_id_seq'::REGCLASS);
                        INSERT INTO inv.inv_consgmt_rcpt_det(consgmt_id, stock_id, quantity_rcvd, cost_price, rcpt_id,
                                                             created_by,
                                                             creation_date, last_update_by, last_update_date,
                                                             expiry_date,
                                                             manfct_date, lifespan, tag_number,
                                                             serial_number, po_line_id, consignmt_condition, remarks,
                                                             itm_id,
                                                             subinv_id, line_id, qty_rtrnd, qty_to_b_rtrnd)
                        VALUES (v_cnsgmntID, v_stckID, v_qty, v_price, p_dochdrid, p_who_rn,
                                to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn,
                                to_char(now(), 'YYYY-MM-DD HH24:MI:SS'),
                                rd1.s_expiry_date, rd1.s_manfct_date, rd1.s_lifespan, rd1.s_tag_number,
                                rd1.s_serial_number,
                                v_srclnID, rd1.s_consignmt_condition, rd1.s_remarks,
                                v_itmID, v_storeID, v_nwlnID, 0, 0);
                        v_reslt_1 := inv.postCnsgnmntQty(v_cnsgmntID, v_qty, 0, v_qty, v_docDte, 'RCPT' || v_nwlnID,
                                                         p_who_rn);
                        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
                        THEN
                            RAISE EXCEPTION USING
                                ERRCODE = 'RHERR',
                                MESSAGE = v_reslt_1,
                                HINT = v_reslt_1;
                        END IF;
                        v_reslt_1 := inv.postStockQty(v_stckID, v_qty, 0, v_qty, v_docDte, 'RCPT' || v_nwlnID,
                                                      p_who_rn);
                        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
                        THEN
                            RAISE EXCEPTION USING
                                ERRCODE = 'RHERR',
                                MESSAGE = v_reslt_1,
                                HINT = v_reslt_1;
                        END IF;
                    ELSIF NOT (v_itmType ILIKE '%Inventory%'
                        OR v_itmType ILIKE '%Fixed Assets%') THEN
                        v_nwlnID := nextval('inv.inv_consgmt_rcpt_det_line_id_seq'::REGCLASS);
                        INSERT INTO inv.inv_consgmt_rcpt_det(consgmt_id, stock_id, quantity_rcvd, cost_price, rcpt_id,
                                                             created_by,
                                                             creation_date, last_update_by, last_update_date,
                                                             expiry_date,
                                                             manfct_date, lifespan, tag_number,
                                                             serial_number, po_line_id, consignmt_condition, remarks,
                                                             itm_id,
                                                             subinv_id, line_id, qty_rtrnd, qty_to_b_rtrnd)
                        VALUES (v_cnsgmntID, v_stckID, v_qty, v_price, p_dochdrid, p_who_rn,
                                to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn,
                                to_char(now(), 'YYYY-MM-DD HH24:MI:SS'),
                                rd1.s_expiry_date, rd1.s_manfct_date, rd1.s_lifespan, rd1.s_tag_number,
                                rd1.s_serial_number,
                                v_srclnID, rd1.s_consignmt_condition, rd1.s_remarks,
                                v_itmID, v_storeID, v_nwlnID, 0, 0);
                    END IF;
                    IF v_reslt_1 LIKE 'SUCCESS:%'
                    THEN
                        IF (rd1.s_po_line_id > 0)
                        THEN
                            v_reslt_1 := scm.updtPrchsDocTrnsctdQty(rd1.s_po_line_id, rd1.s_quantity_rcvd::NUMERIC,
                                                                    p_who_rn);
                            IF v_reslt_1 NOT LIKE 'SUCCESS:%'
                            THEN
                                RAISE EXCEPTION USING
                                    ERRCODE = 'RHERR',
                                    MESSAGE = v_reslt_1,
                                    HINT = v_reslt_1;
                            END IF;
                        END IF;
                    END IF;
                    IF v_itmID > 0 AND coalesce(v_stckID, -1) > 0 AND v_storeID > 0 AND (v_itmType ILIKE '%Inventory%'
                        OR v_itmType ILIKE '%Fixed Assets%') THEN
                        v_reslt_1 :=
                                inv.accountForStockableConsgmtRcpt('Unpaid', (rd1.amnt * v_exchRate)::NUMERIC,
                                                                   v_itmInvAcntID,
                                                                   v_parAcctInvAcrlID,
                                                                   v_dfltCashAcntID,
                                                                   v_DocType, p_dochdrid, v_nwlnID, v_funcCurrID,
                                                                   v_docDte, v_itmDesc,
                                                                   p_who_rn);
                        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
                        THEN
                            RAISE EXCEPTION USING
                                ERRCODE = 'RHERR',
                                MESSAGE = v_reslt_1,
                                HINT = v_reslt_1;
                            RETURN msgs;
                        END IF;
                    ELSIF v_itmID > 0 AND NOT (v_itmType ILIKE '%Inventory%'
                        OR v_itmType ILIKE '%Fixed Assets%') THEN
                        v_reslt_1 := inv.accountForNonStockableItemRcpt('Unpaid', (rd1.amnt * v_exchRate)::NUMERIC,
                                                                        v_expnsID,
                                                                        v_parAcctInvAcrlID,
                                                                        v_dfltCashAcntID,
                                                                        v_DocType, p_dochdrid, v_nwlnID, v_funcCurrID,
                                                                        v_docDte,
                                                                        v_itmDesc,
                                                                        p_who_rn);
                        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
                        THEN
                            RAISE EXCEPTION USING
                                ERRCODE = 'RHERR',
                                MESSAGE = v_reslt_1,
                                HINT = v_reslt_1;
                            RETURN msgs;
                        END IF;
                    END IF;
                END LOOP;
            v_reslt_1 := accb.checkNCreateRcptPyblsHdr(v_clientID,
                                                       v_clientSiteID,
                                                       v_invcAmnt, 'Goods/Services Receipt',
                                                       p_dochdrid, v_docDte, v_inCurCde,
                                                       v_entrdCurrID,
                                                       v_srcDocID, v_orgid,
                                                       p_who_rn);
            v_pyblHdrID := accb.get_ScmPyblsDocHdrID(p_dochdrid, 'Goods/Services Receipt', v_orgid);
            v_pyblDocNum :=
                    gst.getGnrlRecNm('accb.accb_pybls_invc_hdr', 'pybls_invc_hdr_id', 'pybls_invc_number', v_pyblHdrID);
            --v_reslt_1 := accb.approve_pyblrcvbldoc(v_rcvblHdrID, v_rcvblDocNum, 'Receivables', v_orgid, p_who_rn);

            IF v_reslt_1 NOT LIKE 'SUCCESS:%'
            THEN
                RAISE EXCEPTION USING
                    ERRCODE = 'RHERR',
                    MESSAGE = v_reslt_1,
                    HINT = v_reslt_1;
                RETURN msgs;
            END IF;
            DELETE FROM inv.inv_svd_consgmt_rcpt_det a WHERE (a.s_rcpt_id = p_dochdrid AND a.s_rcpt_id > 0);
        END IF;
    ELSIF p_DocKind = 'Return'
    THEN
        FOR rd2 IN (SELECT to_char(to_timestamp(date_returned || ' 12:00:00', 'YYYY-MM-DD HH24:MI:SS'),
                                   'DD-Mon-YYYY HH24:MI:SS')                  invc_date,
                           rcpt_number,
                           'Receipt Returns'                                  rcpt_type,
                           description,
                           rcpt_id                                            po_id,
                           supplier_id,
                           scm.get_cstmr_splr_name(a.supplier_id)             cstmr_splr_name,
                           site_id,
                           approval_status,
                           next_approval_status,
                           org_id,
                           payables_accnt_id,
                           'Receipt'                                          src_doc_type,
                           round(scm.getcnsgnrtrngrndamnt(a.rcpt_rtns_id), 2) invoice_amount,
                           doc_curr_id,
                           exchng_rate
                    FROM inv.inv_consgmt_rcpt_rtns_hdr a
                    WHERE a.rcpt_rtns_id = p_dochdrid)
            LOOP
                v_clientID := rd2.supplier_id;
                v_clientSiteID := rd2.site_id;
                v_docDte := rd2.invc_date;
                v_DocType := rd2.rcpt_type;
                v_srcDocType := rd2.src_doc_type;
                v_apprvlStatus := rd2.approval_status;
                v_invcAmnt := rd2.invoice_amount;
                v_orgid := rd2.org_id;
                v_dateStr := rd2.invc_date;
                v_cstmrNm := rd2.cstmr_splr_name;
                v_docDesc := substring(rd2.description, 1, 299);
                v_srcDocID := rd2.po_id;
                v_exchRate := rd2.exchng_rate;
                v_entrdCurrID := rd2.doc_curr_id;
            END LOOP;
        v_funcCurrID := org.get_orgfunc_crncy_id(v_orgid);
        IF v_entrdCurrID <= 0 THEN
            v_entrdCurrID := v_funcCurrID;
        END IF;
        IF v_exchRate = 0 THEN
            v_exchRate := round(accb.get_ltst_exchrate(v_entrdCurrID, v_funcCurrID, v_dateStr, v_orgid), 15);
        END IF;
        /*IF (v_srcDocID > 0)
        THEN
          v_exchRate :=
              gst.getGnrlRecNm('scm.scm_prchs_docs_hdr', 'prchs_doc_hdr_id', 'exchng_rate', v_srcDocID) :: NUMERIC;
          v_entrdCurrID :=
              gst.getGnrlRecNm('scm.scm_prchs_docs_hdr', 'prchs_doc_hdr_id', 'prntd_doc_curr_id', v_srcDocID) :: INTEGER;
          IF v_exchRate = 0 THEN
            v_exchRate := round(accb.get_ltst_exchrate(v_entrdCurrID, v_funcCurrID, v_dateStr, v_orgid), 15);
          END IF;
        END IF;*/
        v_inCurCde := gst.get_pssbl_val(v_entrdCurrID);
        FOR rd3 IN (SELECT itm_inv_asst_acnt_id,
                           cost_of_goods_acnt_id,
                           expense_acnt_id,
                           prchs_rtrns_acnt_id,
                           rvnu_acnt_id,
                           sales_rtrns_acnt_id,
                           sales_cash_acnt_id,
                           sales_check_acnt_id,
                           sales_rcvbl_acnt_id,
                           rcpt_cash_acnt_id,
                           rcpt_lblty_acnt_id,
                           inv_adjstmnts_lblty_acnt_id,
                           sales_dscnt_accnt,
                           prchs_dscnt_accnt,
                           sales_lblty_acnt_id,
                           bad_debt_acnt_id,
                           rcpt_rcvbl_acnt_id,
                           petty_cash_acnt_id
                    FROM scm.scm_dflt_accnts
                    WHERE org_id = v_orgid)
            LOOP
                v_dfltRcvblAcntID := rd3.sales_rcvbl_acnt_id;
                v_dfltBadDbtAcntID := rd3.bad_debt_acnt_id;
                v_dfltLbltyAccnt := rd3.rcpt_lblty_acnt_id;
                v_parAcctInvAcrlID1 := rd3.inv_adjstmnts_lblty_acnt_id;
                v_dfltInvAcntID := rd3.itm_inv_asst_acnt_id;
                v_dfltCGSAcntID := rd3.cost_of_goods_acnt_id;
                v_dfltExpnsAcntID := rd3.expense_acnt_id;
                v_dfltRvnuAcntID := rd3.rvnu_acnt_id;
                v_dfltSRAcntID := rd3.sales_rtrns_acnt_id;
                v_dfltCashAcntID := rd3.sales_cash_acnt_id;
                v_dfltCheckAcntID := rd3.sales_check_acnt_id;
            END LOOP;
        v_parAcctInvAcrlID := org.get_accnt_id_brnch_eqv(v_BranchID, v_parAcctInvAcrlID1);
        IF (v_apprvlStatus = 'Incomplete')
        THEN
            FOR rd1 IN (SELECT a.s_line_id,
                               a.s_itm_id,
                               a.s_qty_rtnd                                 s_quantity_rcvd,
                               (e.cost_price / v_exchRate)                  s_cost_price,
                               (a.s_qty_rtnd * (e.cost_price / v_exchRate)) amnt,
                               a.s_subinv_id,
                               b.base_uom_id,
                               b.item_code,
                               b.item_desc,
                               c.uom_name,
                               d.cat_name,
                               (b.cogs_acct_id || ',' || b.sales_rev_accnt_id || ',' || b.sales_ret_accnt_id || ',' ||
                                b.purch_ret_accnt_id || ',' || b.expense_accnt_id || ',' ||
                                b.inv_asset_acct_id)                        itm_accnts,
                               b.item_type,
                               a.s_rtnd_reason                              s_consignmt_condition,
                               a.s_remarks,
                               a.s_rcpt_line_id,
                               a.s_consgmt_id
                        FROM inv.inv_svd_consgmt_rcpt_rtns_det a,
                             inv.inv_consgmt_rcpt_det e,
                             inv.inv_itm_list b,
                             inv.unit_of_measure c,
                             inv.inv_product_categories d
                        WHERE (a.s_rcpt_line_id = e.line_id AND a.s_rtns_hdr_id = p_dochdrid AND a.s_rtns_hdr_id > 0
                            AND a.s_itm_id = b.item_id AND b.base_uom_id = c.uom_id AND
                               d.cat_id = b.category_id)
                        ORDER BY a.s_line_id)
                LOOP
                    v_itmID := rd1.s_itm_id;
                    v_storeID := rd1.s_subinv_id;
                    v_BranchID := coalesce(inv.get_store_brnch_id(v_storeID), -1);
                    IF v_BranchID <= 0 AND v_PrsnBrnchID > 0 THEN
                        v_BranchID := v_PrsnBrnchID;
                    END IF;
                    v_curid := v_entrdCurrID;
                    v_itmDesc := rd1.item_desc;
                    v_itmType := rd1.item_type;

                    v_stckID := inv.getItemStockID(v_itmID, v_storeID);

                    IF coalesce(v_stckID, -1) <= 0 AND v_storeID > 0 AND v_itmID > 0 AND (v_itmType ILIKE '%Inventory%'
                        OR v_itmType ILIKE '%Fixed Assets%') THEN
                        RAISE EXCEPTION USING
                            ERRCODE = 'RHERR',
                            MESSAGE = 'Stock does not Exist Item::' || v_itmDesc,
                            HINT = 'Stock does not Exist Item::' || v_itmDesc;
                    END IF;
                    v_slctdAccntIDs := BTRIM(rd1.itm_accnts, ',');
                    v_AcntArrys := string_to_array(v_slctdAccntIDs, ',');

                    v_itmInvAcntID1 := -1;
                    v_cogsID1 := -1;
                    v_salesRevID1 := -1;
                    v_salesRetID1 := -1;
                    v_purcRetID1 := -1;
                    v_expnsID1 := -1;

                    FOR z IN 1..array_length(v_AcntArrys, 1)
                        LOOP
                            IF z = 1 THEN
                                v_cogsID1 := v_AcntArrys[z];
                            ELSIF z = 2 THEN
                                v_salesRevID1 := v_AcntArrys[z];
                            ELSIF z = 3 THEN
                                v_salesRetID1 := v_AcntArrys[z];
                            ELSIF z = 4 THEN
                                v_purcRetID1 := v_AcntArrys[z];
                            ELSIF z = 5 THEN
                                v_expnsID1 := v_AcntArrys[z];
                            ELSE
                                v_itmInvAcntID1 := v_AcntArrys[z];
                            END IF;
                        END LOOP;
                    IF (v_itmInvAcntID1 <= 0) THEN
                        v_itmInvAcntID1 := v_dfltInvAcntID;
                    END IF;
                    IF (v_cogsID1 <= 0) THEN
                        v_cogsID1 := v_dfltCGSAcntID;
                    END IF;
                    IF (v_salesRevID1 <= 0) THEN
                        v_salesRevID1 := v_dfltRvnuAcntID;
                    END IF;
                    IF (v_salesRetID1 <= 0) THEN
                        v_salesRetID1 := v_dfltSRAcntID;
                    END IF;
                    IF (v_expnsID1 <= 0) THEN
                        v_expnsID1 := v_dfltExpnsAcntID;
                    END IF;
                    v_itmInvAcntID := org.get_accnt_id_brnch_eqv(v_BranchID, v_itmInvAcntID1);
                    v_cogsID := org.get_accnt_id_brnch_eqv(v_BranchID, v_cogsID1);
                    v_salesRevID := org.get_accnt_id_brnch_eqv(v_BranchID, v_salesRevID1);
                    v_salesRetID := org.get_accnt_id_brnch_eqv(v_BranchID, v_salesRetID1);
                    v_expnsID := org.get_accnt_id_brnch_eqv(v_BranchID, v_expnsID1);
                    v_purcRetID := org.get_accnt_id_brnch_eqv(v_BranchID, v_purcRetID1);

                    v_srclnID := rd1.s_rcpt_line_id;
                    v_qty := rd1.s_quantity_rcvd;
                    v_price := rd1.s_cost_price * v_exchRate;
                    v_lineid := rd1.s_line_id;
                    v_reslt_1 := 'SUCCESS:';
                    --msgs := 'item_desc:' || rd1.item_desc || '::' || v_cnsgmntIDs || '::Cnt::' || array_length(v_AcntArrys, 1);
                    v_cnsgmntID := rd1.s_consgmt_id;
                    IF (v_itmID > 0 AND v_storeID > 0 AND v_stckID > 0 AND v_cnsgmntID > 0)
                    THEN
                        v_nwlnID := nextval('inv.inv_consgmt_rcpt_rtns_det_line_id_seq'::REGCLASS);
                        INSERT INTO inv.inv_consgmt_rcpt_rtns_det(line_id, consgmt_id, rtns_hdr_id, qty_rtnd,
                                                                  created_by,
                                                                  creation_date,
                                                                  last_update_by, last_update_date, rtnd_reason,
                                                                  remarks,
                                                                  rcpt_line_id, itm_id,
                                                                  subinv_id, stock_id)
                        VALUES (v_nwlnID, v_cnsgmntID, p_dochdrid, v_qty, p_who_rn,
                                to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn,
                                to_char(now(), 'YYYY-MM-DD HH24:MI:SS'),
                                rd1.s_consignmt_condition, rd1.s_remarks, v_srclnID,
                                v_itmID, v_storeID, v_stckID);
                        v_reslt_1 :=
                                inv.postCnsgnmntQty(v_cnsgmntID, -1 * v_qty, 0, -1 * v_qty, v_docDte,
                                                    'RTRN' || v_nwlnID, p_who_rn);
                        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
                        THEN
                            RAISE EXCEPTION USING
                                ERRCODE = 'RHERR',
                                MESSAGE = v_reslt_1,
                                HINT = v_reslt_1;
                        END IF;
                        v_reslt_1 := inv.postStockQty(v_stckID, -1 * v_qty, 0, -1 * v_qty, v_docDte, 'RTRN' || v_nwlnID,
                                                      p_who_rn);
                        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
                        THEN
                            RAISE EXCEPTION USING
                                ERRCODE = 'RHERR',
                                MESSAGE = v_reslt_1,
                                HINT = v_reslt_1;
                        END IF;
                    ELSIF NOT (v_itmType ILIKE '%Inventory%'
                        OR v_itmType ILIKE '%Fixed Assets%') THEN
                        v_nwlnID := nextval('inv.inv_consgmt_rcpt_rtns_det_line_id_seq'::REGCLASS);
                        INSERT INTO inv.inv_consgmt_rcpt_rtns_det(line_id, consgmt_id, rtns_hdr_id, qty_rtnd,
                                                                  created_by,
                                                                  creation_date,
                                                                  last_update_by, last_update_date, rtnd_reason,
                                                                  remarks,
                                                                  rcpt_line_id, itm_id,
                                                                  subinv_id, stock_id)
                        VALUES (v_nwlnID, v_cnsgmntID, p_dochdrid, v_qty, p_who_rn,
                                to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn,
                                to_char(now(), 'YYYY-MM-DD HH24:MI:SS'),
                                rd1.s_consignmt_condition, rd1.s_remarks, v_srclnID,
                                v_itmID, v_storeID, v_stckID);
                    END IF;
                    IF v_reslt_1 LIKE 'SUCCESS:%'
                    THEN
                        IF (rd1.s_rcpt_line_id > 0)
                        THEN
                            v_reslt_1 :=
                                    scm.updtrcptdocRtrndqty(rd1.s_rcpt_line_id, rd1.s_quantity_rcvd::NUMERIC, p_who_rn);
                            IF v_reslt_1 NOT LIKE 'SUCCESS:%'
                            THEN
                                RAISE EXCEPTION USING
                                    ERRCODE = 'RHERR',
                                    MESSAGE = v_reslt_1,
                                    HINT = v_reslt_1;
                            END IF;
                        END IF;
                    END IF;
                    IF v_itmID > 0 AND coalesce(v_stckID, -1) > 0 AND v_storeID > 0 AND (v_itmType ILIKE '%Inventory%'
                        OR v_itmType ILIKE '%Fixed Assets%') THEN
                        v_reslt_1 :=
                                inv.accountForStockableConsgmtRtrn('Unpaid', (rd1.amnt * v_exchRate)::NUMERIC,
                                                                   v_itmInvAcntID,
                                                                   v_parAcctInvAcrlID,
                                                                   v_dfltCashAcntID,
                                                                   v_DocType, p_dochdrid, v_nwlnID, v_funcCurrID,
                                                                   v_itmDesc,
                                                                   p_who_rn);
                        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
                        THEN
                            RAISE EXCEPTION USING
                                ERRCODE = 'RHERR',
                                MESSAGE = v_reslt_1,
                                HINT = v_reslt_1;
                            RETURN msgs;
                        END IF;
                    ELSIF v_itmID > 0 AND NOT (v_itmType ILIKE '%Inventory%'
                        OR v_itmType ILIKE '%Fixed Assets%') THEN
                        v_reslt_1 :=
                                inv.accountForNonStockableRtrn('Unpaid', (rd1.amnt * v_exchRate)::NUMERIC, v_expnsID,
                                                               v_parAcctInvAcrlID,
                                                               v_dfltCashAcntID,
                                                               v_DocType, p_dochdrid, v_nwlnID, v_funcCurrID,
                                                               v_itmDesc,
                                                               p_who_rn);
                        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
                        THEN
                            RAISE EXCEPTION USING
                                ERRCODE = 'RHERR',
                                MESSAGE = v_reslt_1,
                                HINT = v_reslt_1;
                            RETURN msgs;
                        END IF;
                    END IF;
                END LOOP;
            v_reslt_1 := accb.checkNCreateRcptPyblsHdr(v_clientID,
                                                       v_clientSiteID,
                                                       v_invcAmnt, 'Goods/Services Receipt Return',
                                                       p_dochdrid, v_docDte, v_inCurCde,
                                                       v_entrdCurrID,
                                                       v_srcDocID, v_orgid,
                                                       p_who_rn);
            v_pyblHdrID := accb.get_ScmPyblsDocHdrID(p_dochdrid, 'Goods/Services Receipt Return', v_orgid);
            v_pyblDocNum :=
                    gst.getGnrlRecNm('accb.accb_pybls_invc_hdr', 'pybls_invc_hdr_id', 'pybls_invc_number', v_pyblHdrID);
            --v_reslt_1 := accb.approve_pyblrcvbldoc(v_rcvblHdrID, v_rcvblDocNum, 'Receivables', v_orgid, p_who_rn);

            IF v_reslt_1 NOT LIKE 'SUCCESS:%'
            THEN
                RAISE EXCEPTION USING
                    ERRCODE = 'RHERR',
                    MESSAGE = v_reslt_1,
                    HINT = v_reslt_1;
                RETURN msgs;
            END IF;
            DELETE
            FROM inv.inv_svd_consgmt_rcpt_rtns_det a
            WHERE (a.s_rtns_hdr_id = p_dochdrid AND a.s_rtns_hdr_id > 0);
        END IF;
    END IF;

    IF v_reslt_1 LIKE 'SUCCESS:%'
    THEN
        IF p_DocKind = 'Receipt'
        THEN
            UPDATE inv.inv_consgmt_rcpt_hdr
            SET approval_status     = 'Received',
                next_approval_status='Cancel',
                last_update_by=p_who_rn,
                last_update_date    = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
            WHERE rcpt_id = p_dochdrid;
        ELSIF p_DocKind = 'Return'
        THEN
            UPDATE inv.inv_consgmt_rcpt_rtns_hdr
            SET approval_status     = 'Returned',
                next_approval_status='Cancel',
                last_update_by=p_who_rn,
                last_update_date    = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
            WHERE rcpt_rtns_id = p_dochdrid;
        END IF;
    END IF;
    RETURN 'SUCCESS: Consignment ' || p_DocKind || ' DOCUMENT Finalized!';
EXCEPTION
    WHEN OTHERS
        THEN
            RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;

-- FUNCTION: accb.checkncreatercptpyblshdr(bigint, bigint, numeric, character varying, bigint, character varying, character varying, integer, bigint, integer, bigint)

-- DROP FUNCTION accb.checkncreatercptpyblshdr(bigint, bigint, numeric, character varying, bigint, character varying, character varying, integer, bigint, integer, bigint);

CREATE OR REPLACE FUNCTION accb.checkncreatercptpyblshdr(p_spplrid bigint,
                                                         p_spplrsiteid bigint,
                                                         p_invcamnt numeric,
                                                         p_srcdoctype character varying,
                                                         p_rcptno bigint,
                                                         p_trnxdte character varying,
                                                         p_curcode character varying,
                                                         p_curid integer,
                                                         p_hdrpoid bigint,
                                                         p_orgid integer,
                                                         p_who_rn bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    v_curlnID           BIGINT                 := -1;
    v_reslt_1           TEXT                   := '';
    rd1                 RECORD;
    v_funcCurrID        INTEGER                := -1;
    v_exhRate           NUMERIC                := 1;
    v_inCurCde          CHARACTER VARYING(20)  := '';
    v_crid              INTEGER                := -1;
    v_spplrID           BIGINT                 := -1;
    v_parAcctInvAcrlID  INTEGER                := -1;
    v_parAcctInvAcrlID1 INTEGER                := -1;
    v_poid              BIGINT                 := -1;
    v_trnxdte           CHARACTER VARYING(21)  := '';
    v_spplLblty         INTEGER                := -1;
    v_spplRcvbl         INTEGER                := -1;
    v_dfltLbltyAccnt    INTEGER                := -1;
    v_dfltRcvblAcntID   INTEGER                := -1;
    v_dfltLbltyAccnt1   INTEGER                := -1;
    v_dfltRcvblAcntID1  INTEGER                := -1;
    v_pyblDocNum        CHARACTER VARYING(200) := '';
    v_pyblDocType       CHARACTER VARYING(200) := '';
    v_pyblHdrID         BIGINT                 := -1;
    v_pay_remarks       CHARACTER VARYING(200) := '';
    v_usrTrnsCode       CHARACTER VARYING(200) := '';
    v_dte               CHARACTER VARYING(21)  := '';
    v_gnrtdTrnsNo1      CHARACTER VARYING(200) := '';
    v_accntCurrID       INTEGER                := -1;
    v_funcCurrRate      NUMERIC                := 1;
    v_accntCurrRate     NUMERIC                := 1;
    v_funcCurrAmnt      NUMERIC                := 0;
    v_accntCurrAmnt     NUMERIC                := 0;
    v_PrsnID            BIGINT                 := -1;
    v_PrsnBrnchID       INTEGER                := -1;
BEGIN
    v_funcCurrID := org.get_orgfunc_crncy_id(p_orgid);
    v_PrsnID := sec.get_usr_prsn_id(p_who_rn);
    v_PrsnBrnchID := pasn.get_prsn_siteid(v_PrsnID);
    v_inCurCde := p_curCode;
    v_crid := p_curid;
    v_spplrID := p_spplrID;
    v_parAcctInvAcrlID1 := accb.get_DfltAdjstLbltyAcnt(p_orgid);
    v_trnxdte := p_trnxdte;
    --to_char(to_timestamp(p_trnxdte, 'YYYY-MM-DD'), 'DD-Mon-YYYY');
    v_spplLblty := -1;
    v_spplRcvbl := -1;
    IF (v_spplrID > 0)
    THEN
        v_spplLblty :=
                gst.getGnrlRecNm('scm.scm_cstmr_suplr', 'cust_sup_id', 'dflt_pybl_accnt_id', v_spplrID) :: INTEGER;
        v_spplRcvbl =
                gst.getGnrlRecNm('scm.scm_cstmr_suplr', 'cust_sup_id', 'dflt_rcvbl_accnt_id', v_spplrID) :: INTEGER;
    END IF;

    IF (v_spplLblty > 0)
    THEN
        v_dfltLbltyAccnt1 := v_spplLblty;
    END IF;

    IF (v_spplRcvbl > 0)
    THEN
        v_dfltRcvblAcntID1 := v_spplRcvbl;
    END IF;
    v_dfltLbltyAccnt := org.get_accnt_id_brnch_eqv(v_PrsnBrnchID, v_dfltLbltyAccnt1);
    v_dfltRcvblAcntID := org.get_accnt_id_brnch_eqv(v_PrsnBrnchID, v_dfltRcvblAcntID1);
    v_parAcctInvAcrlID := org.get_accnt_id_brnch_eqv(v_PrsnBrnchID, v_parAcctInvAcrlID1);
    v_pyblDocNum := '';
    v_pyblDocType := '';
    v_pyblHdrID := accb.get_ScmPyblsDocHdrID(p_rcptNo, p_srcDocType, p_orgid);
    v_usrTrnsCode := gst.getGnrlRecNm('sec.sec_users', 'user_id', 'code_for_trns_nums', p_who_rn);
    IF (char_length(v_usrTrnsCode) <= 0)
    THEN
        v_usrTrnsCode := 'XX';
    END IF;
    v_dte := to_char(now(), 'YYMMDD');
    IF (p_srcDocType = 'Goods/Services Receipt')
    THEN
        v_exhRate := gst.getGnrlRecNm('inv.inv_consgmt_rcpt_hdr', 'rcpt_id', 'exchng_rate', p_rcptno) :: NUMERIC;
        IF (p_hdrPOID > 0)
        THEN
            v_poid := p_hdrPOID;
            IF (v_poid > 0)
            THEN
                v_exhRate :=
                        gst.getGnrlRecNm('scm.scm_prchs_docs_hdr', 'prchs_doc_hdr_id', 'exchng_rate',
                                         v_poid) :: NUMERIC;
                v_crid := gst.getGnrlRecNm('scm.scm_prchs_docs_hdr', 'prchs_doc_hdr_id', 'prntd_doc_curr_id',
                                           v_poid) :: INTEGER;
                v_inCurCde := gst.get_pssbl_val(v_crid);
            END IF;
        END IF;
        IF v_exhRate = 0 THEN
            v_exhRate := round(accb.get_ltst_exchrate(v_crid, v_funcCurrID, p_trnxdte, p_orgid), 15);
        END IF;
        v_exhRate := coalesce(v_exhRate, 1);
        v_funcCurrRate := v_exhRate;
        v_pay_remarks := gst.getGnrlRecNm('inv.inv_consgmt_rcpt_hdr', 'rcpt_id', 'description', p_rcptNo);
        IF (v_pyblHdrID <= 0)
        THEN
            v_gnrtdTrnsNo1 := 'SSP-' || v_usrTrnsCode || '-' || v_dte || '-';
            v_pyblDocNum := v_gnrtdTrnsNo1 || lpad(
                    ((gst.getRecCount_LstNum('accb.accb_pybls_invc_hdr', 'pybls_invc_number', 'pybls_invc_hdr_id',
                                             v_gnrtdTrnsNo1 || '%') + 1) || ''), 3, '0');
            v_pyblDocType := 'Supplier Standard Payment';
            v_reslt_1 := accb.createPyblsDocHdr(p_orgid, v_trnxdte,
                                                v_pyblDocNum, v_pyblDocType, v_pay_remarks,
                                                p_rcptNo, v_spplrID, p_spplrSiteID, 'Not Validated', 'Approve',
                                                p_invcAmnt, '', p_srcDocType,
                                                accb.getPymntMthdID(p_orgid, 'Supplier Cash'), 0, -1, '',
                                                'Goods Received Payment', v_crid, 0, -1, '', 'None', v_dfltLbltyAccnt,
                                                0, '',
                                                p_who_rn, v_funcCurrRate);
            IF v_reslt_1 NOT LIKE 'SUCCESS:%'
            THEN
                RAISE EXCEPTION USING
                    ERRCODE = 'RHERR',
                    MESSAGE = v_reslt_1,
                    HINT = v_reslt_1;
            END IF;
            v_pyblHdrID := accb.get_ScmPyblsDocHdrID(p_rcptNo, p_srcDocType, p_orgid);
        ELSE
            v_pyblDocNum := gst.getGnrlRecNm('accb.accb_pybls_invc_hdr', 'pybls_invc_hdr_id', 'pybls_invc_number',
                                             v_pyblHdrID);
            v_pyblDocType := 'Supplier Standard Payment';
            v_reslt_1 := accb.updtPyblsDocHdr(v_pyblHdrID, v_trnxdte,
                                              v_pyblDocNum, v_pyblDocType, v_pay_remarks,
                                              p_rcptNo, v_spplrID, p_spplrSiteID, 'Not Validated', 'Approve',
                                              p_invcAmnt, '', p_srcDocType,
                                              accb.getPymntMthdID(p_orgid, 'Supplier Cash'), 0, -1, '',
                                              'Goods Received Payment', v_crid, 0, -1, '', 'None', v_dfltLbltyAccnt, 0,
                                              '',
                                              p_who_rn, v_funcCurrRate);
            IF v_reslt_1 NOT LIKE 'SUCCESS:%'
            THEN
                RAISE EXCEPTION USING
                    ERRCODE = 'RHERR',
                    MESSAGE = v_reslt_1,
                    HINT = v_reslt_1;
            END IF;
        END IF;
        IF (v_pyblHdrID > 0 AND char_length(v_pyblDocType) > 0)
        THEN
            FOR rd1 IN SELECT c.itm_id,
                              c.quantity_rcvd,
                              (c.cost_price / v_exhRate)                   cost_price,
                              c.po_line_id,
                              c.subinv_id,
                              c.stock_id,
                              CASE
                                  WHEN c.expiry_date = ''
                                      THEN c.expiry_date
                                  ELSE to_char(to_timestamp(c.expiry_date, 'YYYY-MM-DD'), 'DD-Mon-YYYY') END,
                              CASE
                                  WHEN c.manfct_date = ''
                                      THEN c.manfct_date
                                  ELSE to_char(to_timestamp(c.manfct_date, 'YYYY-MM-DD'), 'DD-Mon-YYYY') END,
                              c.lifespan,
                              c.tag_number,
                              c.serial_number,
                              c.consignmt_condition,
                              c.remarks,
                              c.consgmt_id,
                              c.line_id,
                              c.quantity_rcvd * (c.cost_price / v_exhRate) ttlcost,
                              inv.get_invitm_name(c.itm_id)                itmnm
                       FROM inv.inv_consgmt_rcpt_det c
                       WHERE c.rcpt_id = p_rcptNo
                       ORDER BY 1
                LOOP
                    v_curlnID := nextval('accb.accb_pybls_amnt_smmrys_pybls_smmry_id_seq');
                    v_accntCurrID := accb.get_accnt_crncy_id(v_dfltLbltyAccnt);
                    --v_funcCurrRate := accb.get_ltst_exchrate(p_curid, v_funcCurrID, v_trnxdte, p_orgid);
                    v_accntCurrRate := accb.get_ltst_exchrate(p_curid, v_accntCurrID, v_trnxdte, p_orgid);

                    v_funcCurrAmnt := rd1.ttlcost * v_funcCurrRate;
                    v_accntCurrAmnt := rd1.ttlcost * v_accntCurrRate;

                    v_reslt_1 := accb.createPyblsDocDet(v_curlnID, v_pyblHdrID, '1Initial Amount',
                                                        ('Initial Cost of Goods/Services Received (RCPT No.:' || p_rcptNo ||
                                                         ') ITEM::' || rd1.itmnm || ' ' ||
                                                         rd1.remarks)::CHARACTER VARYING,
                                                        (rd1.ttlcost)::NUMERIC, v_crid, -1, v_pyblDocType,
                                                        '0',
                                                        'Decrease',
                                                        v_parAcctInvAcrlID, 'Increase',
                                                        v_dfltLbltyAccnt, -1, 'VALID', -1, v_funcCurrID, v_accntCurrID,
                                                        v_funcCurrRate, v_accntCurrRate, v_funcCurrAmnt,
                                                        v_accntCurrAmnt, -1, '', ',', -1, -1, -1, p_who_rn);
                    IF v_reslt_1 NOT LIKE 'SUCCESS:%'
                    THEN
                        RAISE EXCEPTION USING
                            ERRCODE = 'RHERR',
                            MESSAGE = v_reslt_1,
                            HINT = v_reslt_1;
                    END IF;
                END LOOP;
            v_reslt_1 := accb.reCalcPyblsSmmrys(v_pyblHdrID, v_pyblDocType, p_who_rn);
            IF v_reslt_1 NOT LIKE 'SUCCESS:%'
            THEN
                RAISE EXCEPTION USING
                    ERRCODE = 'RHERR',
                    MESSAGE = v_reslt_1,
                    HINT = v_reslt_1;
            END IF;
        END IF;
    ELSIF (p_srcDocType = 'Goods/Services Receipt Return')
    THEN
        v_exhRate :=
                gst.getGnrlRecNm('inv.inv_consgmt_rcpt_rtns_hdr', 'rcpt_rtns_id', 'exchng_rate', p_rcptno) :: NUMERIC;
        /*IF (p_hdrPOID > 0)
        THEN
            v_poid := p_hdrPOID;
            IF (v_poid > 0)
            THEN
                v_exhRate :=
                        gst.getGnrlRecNm('inv.inv_consgmt_rcpt_hdr', 'rcpt_id', 'exchng_rate', p_rcptno) :: NUMERIC;
                v_crid := gst.getGnrlRecNm('inv.inv_consgmt_rcpt_hdr', 'rcpt_id', 'doc_curr_id', v_poid) :: INTEGER;
                v_inCurCde := gst.get_pssbl_val(v_crid);
            END IF;
        END IF;*/
        IF v_exhRate = 0 THEN
            v_exhRate := round(accb.get_ltst_exchrate(v_crid, v_funcCurrID, p_trnxdte, p_orgid), 15);
        END IF;
        v_exhRate := coalesce(v_exhRate, 1);
        v_funcCurrRate := v_exhRate;
        v_pay_remarks := gst.getGnrlRecNm('inv.inv_consgmt_rcpt_rtns_hdr', 'rcpt_rtns_id', 'description', p_rcptNo);
        IF (v_pyblHdrID <= 0)
        THEN
            v_gnrtdTrnsNo1 := 'SCM-IR-' || v_usrTrnsCode || '-' || v_dte || '-';
            v_pyblDocNum := v_gnrtdTrnsNo1 || lpad(
                    ((gst.getRecCount_LstNum('accb.accb_pybls_invc_hdr', 'pybls_invc_number', 'pybls_invc_hdr_id',
                                             v_gnrtdTrnsNo1 || '%') + 1) || ''), 3, '0');
            v_pyblDocType := 'Supplier Credit Memo (InDirect Refund)';
            v_reslt_1 := accb.createPyblsDocHdr(p_orgid, v_trnxdte,
                                                v_pyblDocNum, v_pyblDocType, v_pay_remarks,
                                                p_rcptNo, v_spplrID, p_spplrSiteID, 'Not Validated', 'Approve',
                                                p_invcAmnt, '', p_srcDocType,
                                                accb.getPymntMthdID(p_orgid, 'Supplier Cash'), 0, -1, '',
                                                'Refund-Supplier''s Goods/Services Returned', v_crid, 0, -1, '', 'None',
                                                v_dfltLbltyAccnt, 0, ',', p_who_rn, v_funcCurrRate);
            IF v_reslt_1 NOT LIKE 'SUCCESS:%'
            THEN
                RAISE EXCEPTION USING
                    ERRCODE = 'RHERR',
                    MESSAGE = v_reslt_1,
                    HINT = v_reslt_1;
            END IF;
            v_pyblHdrID := accb.get_ScmPyblsDocHdrID(p_rcptNo, p_srcDocType, p_orgid);
        ELSE
            v_pyblDocNum :=
                    gst.getGnrlRecNm('accb.accb_pybls_invc_hdr', 'pybls_invc_hdr_id', 'pybls_invc_number', v_pyblHdrID);
            v_pyblDocType := 'Supplier Credit Memo (InDirect Refund)';
            v_reslt_1 := accb.updtPyblsDocHdr(v_pyblHdrID, v_trnxdte,
                                              v_pyblDocNum, v_pyblDocType, v_pay_remarks,
                                              p_rcptNo, v_spplrID, p_spplrSiteID, ' Not Validated', 'Approve',
                                              p_invcAmnt, '', p_srcDocType,
                                              accb.getPymntMthdID(p_orgid, 'Supplier Cash'), 0, -1, '',
                                              'Refund - Supplier''s Goods/Services Returned', v_crid, 0, -1, '', 'None',
                                              v_dfltLbltyAccnt, 0, ',', p_who_rn, v_funcCurrRate);
            IF v_reslt_1 NOT LIKE 'SUCCESS:%'
            THEN
                RAISE EXCEPTION USING
                    ERRCODE = 'RHERR',
                    MESSAGE = v_reslt_1,
                    HINT = v_reslt_1;
            END IF;
        END IF;
        IF (v_pyblHdrID > 0 AND char_length(v_pyblDocType) > 0)
        THEN
            FOR rd1 IN SELECT a.itm_id,
                              a.quantity_rcvd,
                              c.qty_rtnd                              qty_to_b_rtrnd,
                              a.rcpt_id,
                              a.subinv_id,
                              a.stock_id,
                              c.rtnd_reason,
                              c.remarks,
                              a.consgmt_id,
                              a.line_id,
                              inv.get_invitm_name(a.itm_id)           itmnm,
                              c.qty_rtnd * (a.cost_price / v_exhRate) ttlcost
                       FROM inv.inv_consgmt_rcpt_det a
                                INNER JOIN inv.inv_itm_list b ON a.itm_id = b.item_id
                                LEFT OUTER JOIN inv.inv_consgmt_rcpt_rtns_det c ON a.line_id = c.rcpt_line_id
                       WHERE c.rtns_hdr_id = p_rcptNo
                         AND b.org_id = p_orgid
                       ORDER BY 1
                LOOP
                --v_reslt_1 := ':v_pyblHdrID:' || v_pyblHdrID || ':p_rcptNo:' || p_rcptNo;
                --v_curlnID := 1 / 0;
                    v_curlnID := nextval('accb.accb_pybls_amnt_smmrys_pybls_smmry_id_seq');
                    v_accntCurrID := accb.get_accnt_crncy_id(v_dfltRcvblAcntID);
                    --v_funcCurrRate := accb.get_ltst_exchrate(p_curid, v_funcCurrID, v_trnxdte, p_orgid);
                    v_accntCurrRate := accb.get_ltst_exchrate(p_curid, v_accntCurrID, v_trnxdte, p_orgid);
                    v_funcCurrAmnt := rd1.ttlcost * v_funcCurrRate;
                    v_accntCurrAmnt := rd1.ttlcost * v_accntCurrRate;

                    v_reslt_1 := accb.createPyblsDocDet(v_curlnID, v_pyblHdrID, '1Initial Amount',
                                                        'Initial Cost of Goods/Services Returned (RCPT RTRN No.:' || p_rcptNo ||
                                                        ')  ITEM::' || rd1.itmnm || ' ' ||
                                                        rd1.remarks::CHARACTER VARYING,
                                                        (rd1.ttlcost)::NUMERIC, v_crid, -1, v_pyblDocType,
                                                        '0',
                                                        'Increase', v_parAcctInvAcrlID, 'Decrease', v_dfltLbltyAccnt,
                                                        -1, 'VALID',
                                                        -1, v_funcCurrID, v_accntCurrID,
                                                        v_funcCurrRate, v_accntCurrRate, v_funcCurrAmnt,
                                                        v_accntCurrAmnt, -1, '',
                                                        ',', -1, -1, -1, p_who_rn);

                    IF v_reslt_1 NOT LIKE 'SUCCESS:%'
                    THEN
                        RAISE EXCEPTION USING
                            ERRCODE = 'RHERR',
                            MESSAGE = v_reslt_1,
                            HINT = v_reslt_1;
                    END IF;

                END LOOP;
        END IF;
    END IF;
    RETURN 'SUCCESS:';
EXCEPTION
    WHEN OTHERS
        THEN
            RETURN 'PYBL_ERROR:' || SQLERRM || v_reslt_1;
END;
$BODY$;

-- FUNCTION: scm.getcnsgnrcptgrndamnt(bigint)

-- DROP FUNCTION scm.getcnsgnrcptgrndamnt(bigint);

CREATE OR REPLACE FUNCTION scm.getcnsgnrcptgrndamnt(
    p_dochdrid bigint)
    RETURNS numeric
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    v_res       NUMERIC                := 0;
    v_docStatus CHARACTER VARYING(100) := '';
    v_exhRate   NUMERIC                := 0;
BEGIN
    v_exhRate := gst.getGnrlRecNm('inv.inv_consgmt_rcpt_hdr', 'rcpt_id', 'exchng_rate', p_dochdrid) :: NUMERIC;
    IF v_exhRate = 0 THEN
        v_exhRate := 1;
    end if;
    v_docStatus := gst.getGnrlRecNm('inv.inv_consgmt_rcpt_hdr', 'rcpt_id', 'approval_status', p_dochdrid);
    IF v_docStatus = 'Received' THEN
        SELECT SUM(y.quantity_rcvd * (y.cost_price / v_exhRate))
        INTO v_res
        FROM inv.inv_consgmt_rcpt_det y
        WHERE y.rcpt_id = p_dochdrID;
    ELSE
        SELECT SUM(y.s_quantity_rcvd * y.s_cost_price)
        INTO v_res
        FROM inv.inv_svd_consgmt_rcpt_det y
        WHERE y.s_rcpt_id = p_dochdrID;
    END IF;
    RETURN COALESCE(v_res, 0);
EXCEPTION
    WHEN OTHERS
        THEN
            RETURN COALESCE(v_res, 0);
END;
$BODY$;

-- FUNCTION: scm.getcnsgnrtrngrndamnt(bigint)

-- DROP FUNCTION scm.getcnsgnrtrngrndamnt(bigint);

CREATE OR REPLACE FUNCTION scm.getcnsgnrtrngrndamnt(
    p_dochdrid bigint)
    RETURNS numeric
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    v_res       NUMERIC                := 0;
    v_docStatus CHARACTER VARYING(100) := '';
    v_exhRate   NUMERIC                := 0;
BEGIN
    v_exhRate :=
            gst.getGnrlRecNm('inv.inv_consgmt_rcpt_rtns_hdr', 'rcpt_rtns_id', 'exchng_rate', p_dochdrid) :: NUMERIC;
    IF v_exhRate = 0 THEN
        v_exhRate := 1;
    end if;
    v_docStatus := gst.getGnrlRecNm('inv.inv_consgmt_rcpt_rtns_hdr', 'rcpt_rtns_id', 'approval_status', p_dochdrid);
    IF v_docStatus = 'Returned' THEN
        SELECT SUM(y.qty_rtnd * coalesce((z.cost_price / v_exhRate), 0))
        INTO v_res
        FROM inv.inv_consgmt_rcpt_rtns_det y
                 LEFT OUTER JOIN inv.inv_consgmt_rcpt_det z ON (y.rcpt_line_id = z.line_id)
        WHERE y.rtns_hdr_id = p_dochdrID;
    ELSE
        SELECT SUM(y.s_qty_rtnd * coalesce((z.cost_price / v_exhRate), 0))
        INTO v_res
        FROM inv.inv_svd_consgmt_rcpt_rtns_det y
                 LEFT OUTER JOIN inv.inv_consgmt_rcpt_det z ON (y.s_rcpt_line_id = z.line_id)
        WHERE y.s_rtns_hdr_id = p_dochdrID;
    END IF;
    RETURN COALESCE(v_res, 0);
    /*EXCEPTION
    WHEN OTHERS
      THEN
        RETURN coalesce(v_res, 0);*/
END;
$BODY$;

CREATE OR REPLACE FUNCTION inv.get_cnsgrcpt_rate(p_dochdrid bigint)
    RETURNS numeric
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    bid numeric := 1;
BEGIN
    SELECT exchng_rate
    INTO bid
    FROM inv.inv_consgmt_rcpt_hdr
    WHERE rcpt_id = p_dochdrid;
    RETURN coalesce(bid, 1);
END;
$BODY$;

CREATE OR REPLACE FUNCTION inv.get_cnsgrtrn_rate(p_dochdrid bigint)
    RETURNS numeric
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE
AS
$BODY$
<<outerblock>>
    DECLARE
    bid numeric := 1;
BEGIN
    SELECT exchng_rate
    INTO bid
    FROM inv.inv_consgmt_rcpt_rtns_hdr
    WHERE rcpt_rtns_id = p_dochdrid;
    RETURN coalesce(bid, 1);
END;
$BODY$;

-- FUNCTION: inv.accountfornonstockableitemrcpt(character varying, numeric, integer, integer, integer, integer, integer, integer, integer, character varying, character varying, bigint)

--DROP FUNCTION inv.accountfornonstockableitemrcpt(character varying, numeric, integer, integer, integer, integer, integer, integer, integer, character varying, character varying, bigint);

CREATE OR REPLACE FUNCTION inv.accountfornonstockableitemrcpt(p_parpaymtstatus character varying,
                                                              p_parttlcost numeric,
                                                              p_parexpacctid integer,
                                                              p_paracctinvacrlid integer,
                                                              p_parcashaccid integer,
                                                              p_pardoctype character varying,
                                                              p_parDocID bigint,
                                                              p_parlineid bigint,
                                                              p_parcurncyid integer,
                                                              p_transdte character varying,
                                                              p_itmdesc character varying,
                                                              p_who_rn bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    v_curCode        CHARACTER VARYING(200) := '';
    v_inCurCde       CHARACTER VARYING(200) := '';
    v_nwfrmt         CHARACTER VARYING(21)  := '';
    v_transDte       CHARACTER VARYING(21)  := '';
    v_dateStr        CHARACTER VARYING(21)  := '';
    v_dfltLbltyAccnt INTEGER                := -1;
    v_curid          INTEGER                := -1;
    v_crid           INTEGER                := -1;
    v_poid           BIGINT                 := -1;
    v_succs          BOOLEAN                := FALSE;
    v_exhRate        NUMERIC                := 1;
    v_reslt_1        TEXT                   := '';
    v_org_id         INTEGER                := -1;
BEGIN
    v_curCode := '';
    v_curid := -1;
    IF (p_parExpAcctID <= 0 OR p_parAcctInvAcrlID <= 0)
    THEN
        RETURN 'ERROR:';
    END IF;
    v_org_id := gst.getGnrlRecNm('accb.accb_chart_of_accnts', 'accnt_id', 'org_id', p_parExpAcctID) :: INTEGER;
    v_curid := org.get_orgfunc_crncy_id(v_org_id);
    v_curCode := gst.get_pssbl_val(v_curid);
    /*v_dfltLbltyAccnt := scm.get_dflt_pybl_accid(v_org_id);
    IF (v_dfltLbltyAccnt <= 0)
    THEN
      RETURN 'ERROR:';
    END IF;*/
    v_dateStr := to_char(now(), 'DD-Mon-YYYY HH24:MI:SS');
    v_nwfrmt := p_transDte;--to_char(to_timestamp(p_transDte || ' 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS');
    v_transDte := p_transDte;--to_char(to_timestamp(p_transDte || ' 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS');

    v_succs := TRUE;

    IF (p_parPaymtStatus = 'Unpaid')
    THEN
        v_succs := scm.sendToGLInterfaceMnl(p_parExpAcctID, 'I', p_parTtlCost, v_transDte,
                                            'Receipt of Expense Item/Service (RCPT No.:' || p_parDocID || ') ' ||
                                            p_itmDesc, p_parCurncyID, v_dateStr,
                                            p_parDocType, p_parDocID, p_parLineID, p_who_rn);
        IF (v_succs = FALSE)
        THEN
            RETURN 'ERROR:';
        END IF;

        v_succs := scm.sendToGLInterfaceMnl(p_parAcctInvAcrlID, 'I', p_parTtlCost, v_transDte,
                                            'Receipt of Expense Item/Service (RCPT No.:' || p_parDocID || ') ' ||
                                            p_itmDesc, p_parCurncyID, v_dateStr,
                                            p_parDocType, p_parDocID, p_parLineID, p_who_rn);
        IF (v_succs = FALSE)
        THEN
            RETURN 'ERROR:';
        END IF;
    END IF;
    RETURN 'SUCCESS:';
EXCEPTION
    WHEN OTHERS
        THEN
            RETURN 'ERROR:' || SQLERRM;
END;
$BODY$;

CREATE OR REPLACE FUNCTION inv.accountfornonstockablertrn(p_parpaymtstatus character varying,
                                                          p_parttlcost numeric,
                                                          p_parpurchrtnid integer,
                                                          p_parinvaccrlid integer,
                                                          p_parcashaccid integer,
                                                          p_pardoctype character varying,
                                                          p_pardocid bigint,
                                                          p_parlineid bigint,
                                                          p_parcurncyid integer,
                                                          p_itmdesc character varying,
                                                          p_who_rn bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    v_curCode         CHARACTER VARYING(200) := '';
    v_inCurCde        CHARACTER VARYING(200) := '';
    v_nwfrmt          CHARACTER VARYING(21)  := '';
    v_transDte        CHARACTER VARYING(21)  := '';
    v_dateStr         CHARACTER VARYING(21)  := '';
    v_dfltRcvblAcntID INTEGER                := -1;
    v_curid           INTEGER                := -1;
    v_crid            INTEGER                := -1;
    v_poid            BIGINT                 := -1;
    v_succs           BOOLEAN                := FALSE;
    v_exhRate         NUMERIC                := 1;
    v_reslt_1         TEXT                   := '';
    v_org_id          INTEGER                := -1;
    v_RcptID          BIGINT                 := -1;
    v_msgs            TEXT                   := '';
BEGIN
    IF (p_parPurchRtnID <= 0 OR p_parInvAccrlID <= 0)
    THEN
        RETURN 'ERROR:Default Non-Stockable Return Accounts Not Set Up!';
    END IF;
    v_org_id := gst.getGnrlRecNm('accb.accb_chart_of_accnts', 'accnt_id', 'org_id', p_parInvAccrlID) :: INTEGER;
    v_curid := org.get_orgfunc_crncy_id(v_org_id);
    v_curCode := gst.get_pssbl_val(v_curid);
    /*v_dfltRcvblAcntID := scm.get_dflt_pybl_accid(v_org_id);
    IF (v_dfltRcvblAcntID <= 0)
    THEN
      RETURN 'ERROR:';
    END IF;*/
    v_succs := TRUE;
    v_dateStr := to_char(now(), 'DD-Mon-YYYY HH24:MI:SS');
    v_transDte := gst.getGnrlRecNm('inv.inv_consgmt_rcpt_rtns_hdr', 'rcpt_rtns_id', 'date_returned', p_parDocID);
    v_transDte := v_transDte || ' 12:00:00';
    v_RcptID := gst.getGnrlRecNm('inv.inv_consgmt_rcpt_rtns_hdr', 'rcpt_rtns_id', 'rcpt_id', p_parDocID)::BIGINT;

    v_nwfrmt := to_char(to_timestamp(v_transDte, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS');

    IF (p_parPaymtStatus = 'Unpaid') THEN
        v_succs := scm.sendToGLInterfaceMnl(p_parPurchRtnID, 'I', p_parTtlCost, v_nwfrmt,
                                            'Return of Expense Item/Service (RCPT RTRN No.:' || p_parDocID || ') ' ||
                                            p_itmDesc, p_parCurncyID, v_dateStr,
                                            p_parDocType, p_parDocID, p_parLineID, p_who_rn);
        IF (v_succs = FALSE) THEN
            RETURN 'ERROR:';
        END IF;
        v_succs := scm.sendToGLInterfaceMnl(p_parInvAccrlID, 'D', p_parTtlCost, v_nwfrmt,
                                            'Reeturn of Expense Item/Service (RCPT RTRN No.:' || p_parDocID || ') ' ||
                                            p_itmDesc, p_parCurncyID, v_dateStr,
                                            p_parDocType, p_parDocID, p_parLineID, p_who_rn);
        IF (v_succs = FALSE) THEN
            RETURN 'ERROR:';
        END IF;
    END IF;
    RETURN 'SUCCESS:';
EXCEPTION
    WHEN OTHERS
        THEN
            v_msgs := v_reslt_1;
            RETURN 'ERROR:' || SQLERRM || '::MSGs::' || v_msgs;
END;
$BODY$;

CREATE OR REPLACE FUNCTION inv.accountfornonstockabletrnsfr(p_parpaymtstatus character varying,
                                                            p_parttlcost numeric,
                                                            p_parpurchrtnid integer,
                                                            p_parinvaccrlid integer,
                                                            p_parcashaccid integer,
                                                            p_pardoctype character varying,
                                                            p_pardocid bigint,
                                                            p_parlineid bigint,
                                                            p_parcurncyid integer,
                                                            p_itmdesc character varying,
                                                            p_who_rn bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    v_curCode         CHARACTER VARYING(200) := '';
    v_inCurCde        CHARACTER VARYING(200) := '';
    v_nwfrmt          CHARACTER VARYING(21)  := '';
    v_transDte        CHARACTER VARYING(21)  := '';
    v_dateStr         CHARACTER VARYING(21)  := '';
    v_dfltRcvblAcntID INTEGER                := -1;
    v_curid           INTEGER                := -1;
    v_crid            INTEGER                := -1;
    v_poid            BIGINT                 := -1;
    v_succs           BOOLEAN                := FALSE;
    v_exhRate         NUMERIC                := 1;
    v_reslt_1         TEXT                   := '';
    v_org_id          INTEGER                := -1;
    v_RcptID          BIGINT                 := -1;
    v_msgs            TEXT                   := '';
BEGIN
    IF (p_parPurchRtnID <= 0 OR p_parInvAccrlID <= 0)
    THEN
        RETURN 'ERROR:Default Non-Stockable Return Accounts Not Set Up!';
    END IF;
    v_org_id := gst.getGnrlRecNm('accb.accb_chart_of_accnts', 'accnt_id', 'org_id', p_parInvAccrlID) :: INTEGER;
    v_curid := org.get_orgfunc_crncy_id(v_org_id);
    v_curCode := gst.get_pssbl_val(v_curid);
    /*v_dfltRcvblAcntID := scm.get_dflt_pybl_accid(v_org_id);
    IF (v_dfltRcvblAcntID <= 0)
    THEN
      RETURN 'ERROR:';
    END IF;*/
    v_succs := TRUE;
    v_dateStr := to_char(now(), 'DD-Mon-YYYY HH24:MI:SS');
    v_transDte := gst.getGnrlRecNm('inv.inv_stock_transfer_hdr', 'transfer_hdr_id', 'transfer_date', p_parDocID);
    v_transDte := v_transDte || ' 12:00:00';

    v_nwfrmt := to_char(to_timestamp(v_transDte, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS');

    IF (p_parPaymtStatus = 'Unpaid') THEN
        v_succs := scm.sendToGLInterfaceMnl(p_parPurchRtnID, 'I', p_parTtlCost, v_nwfrmt,
                                            'Transfer of Expense Item/Service (TRNSFR No.:' || p_parDocID || ') ' ||
                                            p_itmDesc, p_parCurncyID, v_dateStr,
                                            p_parDocType, p_parDocID, p_parLineID, p_who_rn);
        IF (v_succs = FALSE) THEN
            RETURN 'ERROR:';
        END IF;
        v_succs := scm.sendToGLInterfaceMnl(p_parInvAccrlID, 'D', p_parTtlCost, v_nwfrmt,
                                            'Transfer of Expense Item/Service (TRNSFR No.:' || p_parDocID || ') ' ||
                                            p_itmDesc, p_parCurncyID, v_dateStr,
                                            p_parDocType, p_parDocID, p_parLineID, p_who_rn);
        IF (v_succs = FALSE) THEN
            RETURN 'ERROR:';
        END IF;
    END IF;
    RETURN 'SUCCESS:';
EXCEPTION
    WHEN OTHERS
        THEN
            v_msgs := v_reslt_1;
            RETURN 'ERROR:' || SQLERRM || '::MSGs::' || v_msgs;
END;
$BODY$;

CREATE OR REPLACE FUNCTION inv.accountforstockabletrnsfr(p_parpaymtstatus character varying,
                                                         p_parttlcost numeric,
                                                         p_parinvacctid integer,
                                                         p_paracctinvaccrlid integer,
                                                         p_parcashaccid integer,
                                                         p_pardoctype character varying,
                                                         p_pardocid bigint,
                                                         p_parlineid bigint,
                                                         p_parcurncyid integer,
                                                         p_itmdesc character varying,
                                                         p_who_rn bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    v_curCode         CHARACTER VARYING(200) := '';
    v_inCurCde        CHARACTER VARYING(200) := '';
    v_nwfrmt          CHARACTER VARYING(21)  := '';
    v_transDte        CHARACTER VARYING(21)  := '';
    v_dateStr         CHARACTER VARYING(21)  := '';
    v_dfltRcvblAcntID INTEGER                := -1;
    v_curid           INTEGER                := -1;
    v_crid            INTEGER                := -1;
    v_poid            BIGINT                 := -1;
    v_succs           BOOLEAN                := FALSE;
    v_exhRate         NUMERIC                := 1;
    v_reslt_1         TEXT                   := '';
    v_org_id          INTEGER                := -1;
    v_RcptID          BIGINT                 := -1;
BEGIN
    IF (p_parInvAcctID <= 0 OR p_parAcctInvAccrlID <= 0)
    THEN
        RETURN 'ERROR:Default Stockable Return Accounts Not Set Up!';
    END IF;
    v_org_id := gst.getGnrlRecNm('accb.accb_chart_of_accnts', 'accnt_id', 'org_id', p_parInvAcctID) :: INTEGER;
    v_curid := org.get_orgfunc_crncy_id(v_org_id);
    v_curCode := gst.get_pssbl_val(v_curid);
    v_succs := TRUE;
    v_dateStr := to_char(now(), 'DD-Mon-YYYY HH24:MI:SS');
    v_transDte := gst.getGnrlRecNm('inv.inv_stock_transfer_hdr', 'transfer_hdr_id', 'transfer_date', p_parDocID);
    v_transDte := v_transDte || ' 12:00:00';
    v_nwfrmt := to_char(to_timestamp(v_transDte, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS');

    IF (p_parPaymtStatus = 'Unpaid') THEN
        v_succs := scm.sendToGLInterfaceMnl(p_parInvAcctID, 'D', p_parTtlCost, v_nwfrmt,
                                            'Transfer of Consignment (TRNSFR No.:' || p_parDocID || ') ' || p_itmDesc,
                                            p_parCurncyID, v_dateStr,
                                            p_parDocType, p_parDocID, p_parLineID, p_who_rn);
        IF (v_succs = FALSE) THEN
            RETURN 'ERROR:';
        END IF;
        v_succs := scm.sendToGLInterfaceMnl(p_parAcctInvAccrlID, 'D', p_parTtlCost, v_nwfrmt,
                                            'Transfer of Consignment (TRNSFR No.:' || p_parDocID || ') ' || p_itmDesc,
                                            p_parCurncyID, v_dateStr,
                                            p_parDocType, p_parDocID, p_parLineID, p_who_rn);
        IF (v_succs = FALSE) THEN
            RETURN 'ERROR:';
        END IF;
    END IF;
    RETURN 'SUCCESS:';
EXCEPTION
    WHEN OTHERS
        THEN
            RETURN 'ERROR:TRNSFR:' || SQLERRM;
END;
$BODY$;

CREATE OR REPLACE FUNCTION inv.accountforstockableconsgmtrtrn(p_parpaymtstatus character varying,
                                                              p_parttlcost numeric,
                                                              p_parinvacctid integer,
                                                              p_paracctinvaccrlid integer,
                                                              p_parcashaccid integer,
                                                              p_pardoctype character varying,
                                                              p_pardocid bigint,
                                                              p_parlineid bigint,
                                                              p_parcurncyid integer,
                                                              p_itmdesc character varying,
                                                              p_who_rn bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    v_curCode         CHARACTER VARYING(200) := '';
    v_inCurCde        CHARACTER VARYING(200) := '';
    v_nwfrmt          CHARACTER VARYING(21)  := '';
    v_transDte        CHARACTER VARYING(21)  := '';
    v_dateStr         CHARACTER VARYING(21)  := '';
    v_dfltRcvblAcntID INTEGER                := -1;
    v_curid           INTEGER                := -1;
    v_crid            INTEGER                := -1;
    v_poid            BIGINT                 := -1;
    v_succs           BOOLEAN                := FALSE;
    v_exhRate         NUMERIC                := 1;
    v_reslt_1         TEXT                   := '';
    v_org_id          INTEGER                := -1;
    v_RcptID          BIGINT                 := -1;
BEGIN
    IF (p_parInvAcctID <= 0 OR p_parAcctInvAccrlID <= 0)
    THEN
        RETURN 'ERROR:Default Stockable Return Accounts Not Set Up!';
    END IF;
    v_org_id := gst.getGnrlRecNm('accb.accb_chart_of_accnts', 'accnt_id', 'org_id', p_parInvAcctID) :: INTEGER;
    v_curid := org.get_orgfunc_crncy_id(v_org_id);
    v_curCode := gst.get_pssbl_val(v_curid);
    /*v_dfltRcvblAcntID := scm.get_dflt_pybl_accid(v_org_id);
    IF (v_dfltRcvblAcntID <= 0)
    THEN
      RETURN 'ERROR:';
    END IF;*/
    v_succs := TRUE;
    v_dateStr := to_char(now(), 'DD-Mon-YYYY HH24:MI:SS');
    v_transDte := gst.getGnrlRecNm('inv.inv_consgmt_rcpt_rtns_hdr', 'rcpt_rtns_id', 'date_returned', p_parDocID);
    v_transDte := v_transDte || ' 12:00:00';
    v_RcptID := gst.getGnrlRecNm('inv.inv_consgmt_rcpt_rtns_hdr', 'rcpt_rtns_id', 'rcpt_id', p_parDocID)::BIGINT;

    v_nwfrmt := to_char(to_timestamp(v_transDte, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS');

    IF (p_parPaymtStatus = 'Unpaid') THEN
        v_succs := scm.sendToGLInterfaceMnl(p_parInvAcctID, 'D', p_parTtlCost, v_nwfrmt,
                                            'Return of Consignment (RCPT RTRN No.:' || p_parDocID || ') ' || p_itmDesc,
                                            p_parCurncyID, v_dateStr,
                                            p_parDocType, p_parDocID, p_parLineID, p_who_rn);
        IF (v_succs = FALSE) THEN
            RETURN 'ERROR:';
        END IF;
        v_succs := scm.sendToGLInterfaceMnl(p_parAcctInvAccrlID, 'D', p_parTtlCost, v_nwfrmt,
                                            'Return of Consignment (RCPT RTRN No.:' || p_parDocID || ') ' || p_itmDesc,
                                            p_parCurncyID, v_dateStr,
                                            p_parDocType, p_parDocID, p_parLineID, p_who_rn);
        IF (v_succs = FALSE) THEN
            RETURN 'ERROR:';
        END IF;
    END IF;
    RETURN 'SUCCESS:';
EXCEPTION
    WHEN OTHERS
        THEN
            RETURN 'ERROR:SCRT:' || SQLERRM;
END;
$BODY$;

CREATE OR REPLACE FUNCTION inv.accountforstockableconsgmtrcpt(p_parpaymtstatus character varying,
                                                              p_parttlcost numeric,
                                                              p_parinvacctid integer,
                                                              p_paracctinvacrlid integer,
                                                              p_parcashaccid integer,
                                                              p_pardoctype character varying,
                                                              p_pardocid bigint,
                                                              p_parlineid bigint,
                                                              p_parcurncyid integer,
                                                              p_transdte character varying,
                                                              p_itmdesc character varying,
                                                              p_who_rn bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    v_curCode        CHARACTER VARYING(200) := '';
    v_inCurCde       CHARACTER VARYING(200) := '';
    v_nwfrmt         CHARACTER VARYING(21)  := '';
    v_transDte       CHARACTER VARYING(21)  := '';
    v_dateStr        CHARACTER VARYING(21)  := '';
    v_dfltLbltyAccnt INTEGER                := -1;
    v_curid          INTEGER                := -1;
    v_crid           INTEGER                := -1;
    v_poid           BIGINT                 := -1;
    v_succs          BOOLEAN                := FALSE;
    v_exhRate        NUMERIC                := 1;
    v_reslt_1        TEXT                   := '';
    v_org_id         INTEGER                := -1;
BEGIN
    v_curCode := '';
    v_curid := -1;
    IF (p_parInvAcctID <= 0 OR p_parAcctInvAcrlID <= 0)
    THEN
        RETURN 'ERROR:Default Accounts not Setup';
    END IF;
    v_org_id := gst.getGnrlRecNm('accb.accb_chart_of_accnts', 'accnt_id', 'org_id', p_parInvAcctID) :: INTEGER;
    v_curid := org.get_orgfunc_crncy_id(v_org_id);
    v_curCode := gst.get_pssbl_val(v_curid);
    /*v_dfltLbltyAccnt := scm.get_dflt_pybl_accid(v_org_id);
    IF (v_dfltLbltyAccnt <= 0)
    THEN
      RETURN 'ERROR:';
    END IF;*/

    v_dateStr := to_char(now(), 'DD-Mon-YYYY HH24:MI:SS');
    v_nwfrmt := p_transDte;--to_char(to_timestamp(p_transDte || ' 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS');
    v_transDte := p_transDte;--to_char(to_timestamp(p_transDte || ' 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS');

    v_succs := TRUE;
    IF (p_parPaymtStatus = 'Unpaid')
    THEN
        v_succs := scm.sendToGLInterfaceMnl(p_parInvAcctID, 'I', p_parTtlCost, v_transDte,
                                            'Receipt of Consignment (RCPT No.:' || p_parDocID || ') ' || p_itmDesc,
                                            p_parCurncyID, v_dateStr,
                                            p_parDocType, p_parDocID, p_parLineID, p_who_rn);
        IF (v_succs = FALSE)
        THEN
            RETURN 'ERROR8:';
        END IF;

        v_succs := scm.sendToGLInterfaceMnl(p_parAcctInvAcrlID, 'I', p_parTtlCost, v_transDte,
                                            'Receipt of Consignment (RCPT No.:' || p_parDocID || ') ' || p_itmDesc,
                                            p_parCurncyID, v_dateStr,
                                            p_parDocType, p_parDocID, p_parLineID, p_who_rn);
        IF (v_succs = FALSE)
        THEN
            RETURN 'ERROR7:';
        END IF;
    END IF;
    RETURN 'SUCCESS:';
EXCEPTION
    WHEN OTHERS
        THEN
            RETURN 'ERROR:' || SQLERRM;
END;
$BODY$;

-- FUNCTION: accb.approve_pyblrcvbldoc(bigint, character varying, character varying, integer, bigint)

-- DROP FUNCTION accb.approve_pyblrcvbldoc(bigint, character varying, character varying, integer, bigint);

CREATE OR REPLACE FUNCTION accb.approve_pyblrcvbldoc(p_dochdrid bigint,
                                                     p_docnum character varying,
                                                     p_dockind character varying,
                                                     p_orgid integer,
                                                     p_who_rn bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS
$BODY$
<< outerblock >>
    DECLARE
    v_sameprepayCnt  BIGINT                 := 0;
    rd1              RECORD;
    msgs             TEXT                   := '';
    v_reslt_1        TEXT                   := '';
    v_usrTrnsCode    CHARACTER VARYING(50)  := '';
    v_dte            CHARACTER VARYING(21)  := '';
    v_lnDte          CHARACTER VARYING(21)  := '';
    v_docHdrDesc     CHARACTER VARYING(300) := '';
    v_docNum         CHARACTER VARYING(100) := '';
    v_gnrtdTrnsNo1   CHARACTER VARYING(100) := '';
    v_frstChqNum     CHARACTER VARYING(100) := '';
    v_ref_doc_number CHARACTER VARYING(100) := '';
    v_glBatchName    CHARACTER VARYING(100) := '';
    v_glBatchID      BIGINT                 := -1;
    v_balcngAccntID  INTEGER                := -1;
    v_lineTypeNm     CHARACTER VARYING(50)  := '';
    v_codeBhndID     INTEGER                := -1;
    v_incrDcrs1      CHARACTER VARYING(50)  := '';
    v_accntID1       INTEGER                := -1;
    v_incrDcrs2      CHARACTER VARYING(50)  := '';
    v_accntID2       INTEGER                := -1;
    v_isdbtCrdt1     CHARACTER VARYING(50)  := '';
    v_isdbtCrdt2     CHARACTER VARYING(50)  := '';
    v_accntID3       INTEGER                := -1;
    v_incrDcrs3      CHARACTER VARYING(50)  := '';
    v_netAmnt        NUMERIC                := 0;
    v_lnAmnt         NUMERIC                := 0;
    v_acntAmnt       NUMERIC                := 0;
    v_entrdAmnt      NUMERIC                := 0;
    v_funcCurrRate   NUMERIC                := 1;
    v_accntCurrRate  NUMERIC                := 1;
    v_lneDesc        CHARACTER VARYING(300) := '';
    v_entrdCurrID    INTEGER                := -1;
    v_funcCurrID     INTEGER                := -1;
    v_accntCurrID    INTEGER                := -1;
    v_grndAmnt       NUMERIC                := 0;
    v_funcCurrAmnt   NUMERIC                := 0;
    v_accntCurrAmnt  NUMERIC                := 0;
    v_accntCurrRate1 NUMERIC                := 1;
    v_doctype        CHARACTER VARYING(300) := '';
BEGIN
    /* 1. Create a GL Batch and get all doc lines
     * 2. for each line create costing account transaction
     * 3. create one balancing account transaction using the grand total amount
     * 4. Check if created gl_batch is balanced.
     * 5. if balanced update docHdr else delete the gl batch created and throw error message
     */

    v_usrTrnsCode := gst.getGnrlRecNm('sec.sec_users', 'user_id', 'code_for_trns_nums', p_who_rn);
    IF (char_length(v_usrTrnsCode) <= 0)
    THEN
        v_usrTrnsCode := 'XX';
    END IF;
    v_dte := to_char(now(), 'YYMMDD');
    IF p_DocHdrID <= 0 THEN
        RAISE EXCEPTION USING
            ERRCODE = 'RHERR',
            MESSAGE = 'No Document to Approve!',
            HINT = 'No Document to Approve!';
    END IF;
    IF p_DocKind = 'Receivables'
    THEN
        v_lnDte := gst.getGnrlRecNm('accb.accb_rcvbls_invc_hdr', 'rcvbls_invc_hdr_id', 'rcvbls_invc_date', p_DocHdrID);
        --msgs := ':' || coalesce(v_lnDte, 'X') || ':'||p_DocHdrID;
        v_lnDte :=
                to_char(to_timestamp(substring(v_lnDte, 1, 10) || to_char(now(), ' HH24:MI:SS'),
                                     'YYYY-MM-DD HH24:MI:SS'),
                        'DD-Mon-YYYY HH24:MI:SS');
        --v_accntID1 := 1 / 0;
        v_docHdrDesc :=
                gst.getGnrlRecNm('accb.accb_rcvbls_invc_hdr', 'rcvbls_invc_hdr_id', 'comments_desc', p_DocHdrID);
        v_docNum :=
                gst.getGnrlRecNm('accb.accb_rcvbls_invc_hdr', 'rcvbls_invc_hdr_id', 'rcvbls_invc_number', p_DocHdrID);
        v_doctype :=
                gst.getGnrlRecNm('accb.accb_rcvbls_invc_hdr', 'rcvbls_invc_hdr_id', 'rcvbls_invc_type', p_DocHdrID);
        v_gnrtdTrnsNo1 := 'RCVBL-' || v_usrTrnsCode || '-' || v_dte || '-';
        v_reslt_1 := accb.recalcrcvblssmmrys(p_docHdrID, v_doctype, p_who_rn);
        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
        THEN
            RAISE EXCEPTION USING
                ERRCODE = 'RHERR',
                MESSAGE = v_reslt_1,
                HINT = v_reslt_1;
            RETURN msgs;
        END IF;
        UPDATE accb.accb_rcvbls_invc_hdr
        SET invoice_amount=accb.getRcvblsDocGrndAmnt(p_DocHdrID)
        WHERE (rcvbls_invc_hdr_id = p_DocHdrID);
        v_sameprepayCnt := accb.getRcvblsPrepayDocCnt(p_DocHdrID);
        IF (v_sameprepayCnt > 1) THEN
            msgs := 'ERROR: Same Prepayment Cannot be Applied More than Once!';
            RAISE EXCEPTION USING
                ERRCODE = 'RHERR',
                MESSAGE = msgs,
                HINT = msgs;
            RETURN msgs;
        END IF;
    ELSIF p_DocKind = 'Payables'
    THEN
        v_lnDte := gst.getGnrlRecNm('accb.accb_pybls_invc_hdr', 'pybls_invc_hdr_id', 'pybls_invc_date', p_DocHdrID);
        v_lnDte := to_char(to_timestamp(v_lnDte || to_char(now(), ' HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS'),
                           'DD-Mon-YYYY HH24:MI:SS');
        v_docHdrDesc := gst.getGnrlRecNm('accb.accb_pybls_invc_hdr', 'pybls_invc_hdr_id', 'comments_desc', p_DocHdrID);
        v_docNum := gst.getGnrlRecNm('accb.accb_pybls_invc_hdr', 'pybls_invc_hdr_id', 'pybls_invc_number', p_DocHdrID);
        v_doctype := gst.getGnrlRecNm('accb.accb_pybls_invc_hdr', 'pybls_invc_hdr_id', 'pybls_invc_type', p_DocHdrID);
        v_gnrtdTrnsNo1 := 'PYBL-' || v_usrTrnsCode || '-' || v_dte || '-';
        v_frstChqNum :=
                gst.getGnrlRecNm('accb.accb_pybls_invc_hdr', 'pybls_invc_hdr_id', 'firts_cheque_num', p_DocHdrID);
        v_reslt_1 := accb.recalcpyblssmmrys(p_docHdrID, v_doctype, p_who_rn);
        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
        THEN
            RAISE EXCEPTION USING
                ERRCODE = 'RHERR',
                MESSAGE = v_reslt_1 || 'RECLACL',
                HINT = v_reslt_1 || 'RECLACL';
            RETURN msgs;
        END IF;
        UPDATE accb.accb_pybls_invc_hdr
        SET invoice_amount=accb.getPyblsDocGrndAmnt(p_DocHdrID)
        WHERE (pybls_invc_hdr_id = p_DocHdrID);
        v_sameprepayCnt := accb.getPyblsPrepayDocCnt(p_DocHdrID);
        IF (v_sameprepayCnt > 1) THEN
            msgs := 'ERROR: Same Prepayment Cannot be Applied More than Once!';
            RAISE EXCEPTION USING
                ERRCODE = 'RHERR',
                MESSAGE = msgs,
                HINT = msgs;
            RETURN msgs;
        END IF;
    END IF;

    v_glBatchName := v_gnrtdTrnsNo1 || lpad(
            ((gst.getRecCount_LstNum('accb.accb_trnsctn_batches', 'batch_name', 'batch_id',
                                     v_gnrtdTrnsNo1 || '%') + 1) || ''), 3, '0');

    v_glBatchID := gst.getGnrlRecID1('accb.accb_trnsctn_batches', 'batch_name', 'batch_id', v_glBatchName, p_orgid);

    IF (v_glBatchID <= 0)
    THEN
        v_reslt_1 := accb.createBatch(p_orgid, v_glBatchName,
                                      v_docHdrDesc || ' (' || v_docNum || ')',
                                      p_DocKind || ' Invoice Document', 'VALID', -1, '0', p_who_rn);
        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
        THEN
            RAISE EXCEPTION USING
                ERRCODE = 'RHERR',
                MESSAGE = 'BATCH CREATION FAILED',
                HINT = 'Journal Batch could not be created!';
            RETURN msgs;
        END IF;
    ELSE
        RETURN 'ERROR:New GL Batch Number Exists! Try Again Later!';
    END IF;

    v_glBatchID := gst.getGnrlRecID1('accb.accb_trnsctn_batches', 'batch_name', 'batch_id', v_glBatchName, p_orgid);
    v_balcngAccntID := -1;
    IF p_DocKind = 'Receivables'
    THEN
        FOR rd1 IN SELECT rcvbl_smmry_id,
                          rcvbl_smmry_type,
                          rcvbl_smmry_desc,
                          rcvbl_smmry_amnt,
                          code_id_behind,
                          auto_calc,
                          incrs_dcrs1,
                          rvnu_acnt_id,
                          incrs_dcrs2,
                          rcvbl_acnt_id,
                          appld_prepymnt_doc_id,
                          entrd_curr_id,
                          gst.get_pssbl_val(a.entrd_curr_id),
                          func_curr_id,
                          gst.get_pssbl_val(a.func_curr_id),
                          accnt_curr_id,
                          gst.get_pssbl_val(a.accnt_curr_id),
                          func_curr_rate,
                          accnt_curr_rate,
                          rcvbl_smmry_amnt * func_curr_rate  func_curr_amount,
                          rcvbl_smmry_amnt * accnt_curr_rate accnt_curr_amnt,
                          ref_doc_number
                   FROM accb.accb_rcvbl_amnt_smmrys a
                   WHERE ((a.src_rcvbl_hdr_id = p_DocHdrID) AND (a.rcvbl_smmry_type != '6Grand Total' AND
                                                                 a.rcvbl_smmry_type != '7Total Payments Made' AND
                                                                 a.rcvbl_smmry_type != '8Outstanding Balance'))
                   ORDER BY rcvbl_smmry_type ASC
            LOOP
                v_lineTypeNm := rd1.rcvbl_smmry_type;
                v_codeBhndID := rd1.code_id_behind;
                v_incrDcrs1 := substr(rd1.incrs_dcrs1, 1, 1);
                v_accntID1 := rd1.rvnu_acnt_id;
                v_isdbtCrdt1 := accb.dbt_or_crdt_accnt(v_accntID1, v_incrDcrs1);

                v_incrDcrs2 := substr(rd1.incrs_dcrs2, 1, 1);
                v_accntID2 := rd1.rcvbl_acnt_id;
                v_balcngAccntID := v_accntID2;
                v_entrdAmnt := rd1.rcvbl_smmry_amnt;
                IF v_lineTypeNm = '1Initial Amount' THEN
                    v_incrDcrs3 := v_incrDcrs2;
                    v_accntID3 := v_accntID2;
                end if;
                v_lnAmnt := rd1.func_curr_amount;

                v_acntAmnt := rd1.accnt_curr_amnt;

                v_lneDesc := rd1.rcvbl_smmry_desc;
                v_entrdCurrID := rd1.entrd_curr_id;
                v_funcCurrID := rd1.func_curr_id;
                v_accntCurrID := rd1.accnt_curr_id;
                v_funcCurrRate := rd1.func_curr_rate;
                v_accntCurrRate := rd1.accnt_curr_rate;
                v_ref_doc_number := rd1.ref_doc_number;
                IF char_length(v_ref_doc_number) <= 0 AND char_length(v_frstChqNum) > 0
                THEN
                    v_ref_doc_number := v_frstChqNum;
                END IF;
                IF (v_accntID1 > 0 AND (v_lnAmnt != 0 OR v_acntAmnt != 0) AND char_length(v_incrDcrs1) > 0 AND
                    char_length(v_lneDesc) > 0)
                THEN
                    v_netAmnt := accb.dbt_or_crdt_accnt_multiplier(v_accntID1, v_incrDcrs1) * v_lnAmnt;
                    IF (v_isdbtCrdt1 = 'Debit')
                    THEN
                        v_reslt_1 := accb.createTransaction(v_accntID1,
                                                            v_lneDesc, v_lnAmnt,
                                                            v_lnDte, v_funcCurrID, v_glBatchID, 0.00,
                                                            v_netAmnt, ',', v_entrdAmnt, v_entrdCurrID, v_acntAmnt,
                                                            v_accntCurrID, v_funcCurrRate, v_accntCurrRate, 'D', '',
                                                            p_DocKind || ' Invoice', rd1.rcvbl_smmry_id, p_who_rn);
                    ELSE
                        v_reslt_1 := accb.createTransaction(v_accntID1,
                                                            v_lneDesc, 0.00,
                                                            v_lnDte, v_funcCurrID,
                                                            v_glBatchID, v_lnAmnt, v_netAmnt, ',',
                                                            v_entrdAmnt, v_entrdCurrID, v_acntAmnt, v_accntCurrID,
                                                            v_funcCurrRate, v_accntCurrRate, 'C', '',
                                                            p_DocKind || ' Invoice',
                                                            rd1.rcvbl_smmry_id, p_who_rn);
                    END IF;
                    v_funcCurrAmnt := v_funcCurrAmnt + v_lnAmnt;
                    v_grndAmnt := v_grndAmnt + v_entrdAmnt;
                    IF v_reslt_1 NOT LIKE 'SUCCESS:%'
                    THEN
                        RAISE EXCEPTION USING
                            ERRCODE = 'RHERR',
                            MESSAGE = 'BATCH TRANSACTION CREATION FAILED',
                            HINT = 'Journal Batch Transaction could not be created!';
                        RETURN msgs;
                    END IF;
                END IF;
            END LOOP;
    ELSIF p_DocKind = 'Payables'
    THEN
        FOR rd1 IN SELECT pybls_smmry_id,
                          pybls_smmry_type,
                          pybls_smmry_desc,
                          pybls_smmry_amnt,
                          code_id_behind,
                          auto_calc,
                          incrs_dcrs1,
                          asset_expns_acnt_id,
                          incrs_dcrs2,
                          liability_acnt_id,
                          appld_prepymnt_doc_id,
                          entrd_curr_id,
                          gst.get_pssbl_val(a.entrd_curr_id),
                          func_curr_id,
                          gst.get_pssbl_val(a.func_curr_id),
                          accnt_curr_id,
                          gst.get_pssbl_val(a.accnt_curr_id),
                          func_curr_rate,
                          accnt_curr_rate,
                          pybls_smmry_amnt * func_curr_rate  func_curr_amount,
                          pybls_smmry_amnt * accnt_curr_rate accnt_curr_amnt,
                          ref_doc_number
                   FROM accb.accb_pybls_amnt_smmrys a
                   WHERE ((a.src_pybls_hdr_id = p_DocHdrID) AND (a.pybls_smmry_type != '6Grand Total' AND
                                                                 a.pybls_smmry_type != '7Total Payments Made' AND
                                                                 a.pybls_smmry_type != '8Outstanding Balance'))
                   ORDER BY pybls_smmry_type ASC
            LOOP
                v_lineTypeNm := rd1.pybls_smmry_type;
                v_codeBhndID := rd1.code_id_behind;
                v_incrDcrs1 := substr(rd1.incrs_dcrs1, 1, 1);
                v_accntID1 := rd1.asset_expns_acnt_id;
                v_isdbtCrdt1 := accb.dbt_or_crdt_accnt(v_accntID1, v_incrDcrs1);

                v_incrDcrs2 := substr(rd1.incrs_dcrs2, 1, 1);
                v_accntID2 := rd1.liability_acnt_id;
                v_balcngAccntID := v_accntID2;
                IF v_lineTypeNm = '1Initial Amount' THEN
                    v_incrDcrs3 := v_incrDcrs2;
                    v_accntID3 := v_accntID2;
                end if;
                v_isdbtCrdt2 := accb.dbt_or_crdt_accnt(v_accntID2, v_incrDcrs2);
                v_lnAmnt := rd1.func_curr_amount;
                v_acntAmnt := rd1.accnt_curr_amnt;
                v_entrdAmnt := rd1.pybls_smmry_amnt;

                v_lneDesc := rd1.pybls_smmry_desc;
                v_entrdCurrID := rd1.entrd_curr_id;
                v_funcCurrID := rd1.func_curr_id;
                v_accntCurrID := rd1.accnt_curr_id;
                v_funcCurrRate := rd1.func_curr_rate;
                v_accntCurrRate := rd1.accnt_curr_rate;
                v_ref_doc_number := rd1.ref_doc_number;
                IF char_length(v_ref_doc_number) <= 0 AND char_length(v_frstChqNum) > 0
                THEN
                    v_ref_doc_number := v_frstChqNum;
                END IF;
                IF (v_accntID1 > 0 AND (v_lnAmnt != 0 OR v_acntAmnt != 0) AND char_length(v_incrDcrs1) > 0 AND
                    char_length(v_lneDesc) > 0)
                THEN
                    v_netAmnt := accb.dbt_or_crdt_accnt_multiplier(v_accntID1, v_incrDcrs1) * v_lnAmnt;

                    IF (v_isdbtCrdt1 = 'Debit')
                    THEN
                        v_reslt_1 := accb.createTransaction(v_accntID1,
                                                            v_lneDesc, v_lnAmnt,
                                                            v_lnDte, v_funcCurrID, v_glBatchID, 0.00,
                                                            v_netAmnt, ',', v_entrdAmnt, v_entrdCurrID, v_acntAmnt,
                                                            v_accntCurrID, v_funcCurrRate, v_accntCurrRate, 'D', '',
                                                            p_DocKind || ' Invoice', rd1.pybls_smmry_id, p_who_rn);
                    ELSE
                        v_reslt_1 := accb.createTransaction(v_accntID1,
                                                            v_lneDesc, 0.00,
                                                            v_lnDte, v_funcCurrID,
                                                            v_glBatchID, v_lnAmnt, v_netAmnt, ',',
                                                            v_entrdAmnt, v_entrdCurrID, v_acntAmnt, v_accntCurrID,
                                                            v_funcCurrRate, v_accntCurrRate, 'C', '',
                                                            p_DocKind || ' Invoice',
                                                            rd1.pybls_smmry_id, p_who_rn);
                    END IF;
                    v_funcCurrAmnt := v_funcCurrAmnt + v_lnAmnt;
                    v_grndAmnt := v_grndAmnt + v_entrdAmnt;
                    IF v_reslt_1 NOT LIKE 'SUCCESS:%'
                    THEN
                        RAISE EXCEPTION USING
                            ERRCODE = 'RHERR',
                            MESSAGE = 'BATCH TRANSACTION CREATION FAILED ' || v_reslt_1,
                            HINT = 'Journal Batch Transaction could not be created! ' || v_reslt_1;
                        RETURN msgs;
                    END IF;
                END IF;
            END LOOP;
    END IF;

    --Balancing Leg

    v_accntCurrID := gst.getGnrlRecNm('accb.accb_chart_of_accnts', 'accnt_id', 'crncy_id', v_balcngAccntID) :: INTEGER;
    v_funcCurrRate := accb.get_ltst_exchrate(v_entrdCurrID, v_funcCurrID, v_lnDte, p_orgid);
    v_accntCurrRate := accb.get_ltst_exchrate(v_entrdCurrID, v_accntCurrID, v_lnDte, p_orgid);
    v_accntID2 := v_accntID3;
    IF p_DocKind = 'Receivables'
    THEN
        v_isdbtCrdt2 := 'I';
        v_isdbtCrdt2 := v_incrDcrs3;
        v_grndAmnt := accb.getRcvblsDocGrndAmnt(p_DocHdrID);
        v_funcCurrAmnt := accb.getRcvblsDocFuncAmnt(p_DocHdrID);
    ELSIF p_DocKind = 'Payables'
    THEN
        v_isdbtCrdt2 := 'I';
        v_isdbtCrdt2 := v_incrDcrs3;
        v_grndAmnt := accb.getPyblsDocGrndAmnt(p_DocHdrID);
        v_funcCurrAmnt = accb.getPyblsDocFuncAmnt(p_DocHdrID);
    END IF;
    v_accntCurrAmnt := (v_accntCurrRate1 * v_grndAmnt);
    v_netAmnt := accb.dbt_or_crdt_accnt_multiplier(v_accntID2, v_isdbtCrdt2) * v_funcCurrAmnt;
    v_isdbtCrdt2 := accb.dbt_or_crdt_accnt(v_accntID2, v_isdbtCrdt2);
    IF (v_isdbtCrdt2 = 'Debit')
    THEN
        v_reslt_1 := accb.createTransaction(v_balcngAccntID,
                                            v_docHdrDesc ||
                                            ' (Balacing Leg for ' || p_DocKind || ' Doc:-' ||
                                            v_docNum || ')', v_funcCurrAmnt,
                                            v_lnDte, v_funcCurrID, v_glBatchID, 0.00,
                                            v_netAmnt, ',', v_grndAmnt, v_entrdCurrID,
                                            v_accntCurrAmnt, v_accntCurrID, v_funcCurrRate, v_accntCurrRate, 'D', '',
                                            p_DocKind || ' Invoice', -1, p_who_rn);
    ELSE
        v_reslt_1 := accb.createTransaction(v_balcngAccntID,
                                            v_docHdrDesc ||
                                            ' (Balacing Leg for ' || p_DocKind || ' Doc:-' ||
                                            v_docNum || ')', 0.00,
                                            v_lnDte, v_funcCurrID,
                                            v_glBatchID, v_funcCurrAmnt, v_netAmnt, ',',
                                            v_grndAmnt, v_entrdCurrID, v_accntCurrAmnt,
                                            v_accntCurrID, v_funcCurrRate, v_accntCurrRate, 'C', '',
                                            p_DocKind || ' Invoice', -1, p_who_rn);
    END IF;
    IF v_reslt_1 NOT LIKE 'SUCCESS:%'
    THEN
        RAISE EXCEPTION USING
            ERRCODE = 'RHERR',
            MESSAGE = 'BALANCING TRANSACTION CREATION FAILED ' || v_reslt_1,
            HINT = 'BALANCING Transaction could not be created! ' || v_reslt_1;
        RETURN msgs;
    END IF;
    msgs := 'CR:' || accb.get_Batch_CrdtSum(v_glBatchID) || ':DR:' || accb.get_Batch_DbtSum(v_glBatchID);
    --v_balcngAccntID := 1 / 0;
    IF (accb.get_Batch_CrdtSum(v_glBatchID) = accb.get_Batch_DbtSum(v_glBatchID))
    THEN
        IF p_DocKind = 'Receivables'
        THEN
            UPDATE accb.accb_rcvbls_invc_hdr
            SET gl_batch_id      = v_glBatchID,
                last_update_by   = p_who_rn,
                last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
            WHERE (rcvbls_invc_hdr_id = p_DocHdrID);

            UPDATE accb.accb_trnsctn_batches
            SET avlbl_for_postng = '1',
                last_update_by   = p_who_rn,
                last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
            WHERE batch_id = v_glBatchID;

            UPDATE accb.accb_rcvbls_invc_hdr
            SET approval_status     = 'Approved',
                last_update_by      = p_who_rn,
                last_update_date    = to_char(now(), 'YYYY-MM-DD HH24:MI:SS'),
                next_aproval_action = 'Cancel'
            WHERE (rcvbls_invc_hdr_id = p_DocHdrID);
        ELSIF p_DocKind = 'Payables'
        THEN
            UPDATE accb.accb_pybls_invc_hdr
            SET gl_batch_id      = v_glBatchID,
                last_update_by   = p_who_rn,
                last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
            WHERE (pybls_invc_hdr_id = p_DocHdrID);

            UPDATE accb.accb_trnsctn_batches
            SET avlbl_for_postng = '1',
                last_update_by   = p_who_rn,
                last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
            WHERE batch_id = v_glBatchID;

            UPDATE accb.accb_pybls_invc_hdr
            SET approval_status     = 'Approved',
                last_update_by      = p_who_rn,
                last_update_date    = to_char(now(), 'YYYY-MM-DD HH24:MI:SS'),
                next_aproval_action = 'Cancel'
            WHERE (pybls_invc_hdr_id = p_DocHdrID);
        END IF;
    ELSE
        msgs := 'ERROR:The GL Batch created is not Balanced!Transactions created will be reversed and deleted! ' ||
                msgs;
        DELETE FROM accb.accb_trnsctn_details WHERE (batch_id = v_glBatchID);
        DELETE FROM accb.accb_trnsctn_batches WHERE (batch_id = v_glBatchID);
        UPDATE accb.accb_trnsctn_batches
        SET batch_vldty_status = 'VALID'
        WHERE batch_id IN (SELECT h.batch_id
                           FROM accb.accb_trnsctn_batches h
                           WHERE batch_vldty_status = 'VOID'
                             AND NOT EXISTS(SELECT g.batch_id
                                            FROM accb.accb_trnsctn_batches g
                                            WHERE h.batch_id = g.src_batch_id));
        RAISE EXCEPTION USING
            ERRCODE = 'RHERR',
            MESSAGE = msgs,
            HINT = msgs;
        RETURN msgs;
    END IF;
    RETURN 'SUCCESS: ' || p_DocKind || ' Document Approved!';
EXCEPTION
    WHEN OTHERS
        THEN
            msgs := msgs || v_reslt_1;
            RETURN 'ERROR:' || p_DocKind || 'APPROVAL:' || SQLERRM || ' [' || msgs || ']';
END;
$BODY$;
