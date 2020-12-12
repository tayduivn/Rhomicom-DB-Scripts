CREATE OR REPLACE FUNCTION aca.get_pos_hldr_prs_id(
	p_period_id bigint,
	p_group_id integer,
	p_course_id integer,
	p_subject_id integer,
	p_position_code character varying)
    RETURNS bigint
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
<<outerblock>>
    DECLARE
    bid         BIGINT := -1;
    v_period_id BIGINT := -1;
BEGIN
    v_period_id := p_period_id;
    if (coalesce(v_period_id,-1) <= 0) then
        select assmnt_period_id
        into v_period_id
        from aca.aca_assessment_periods a
        WHERE to_char(now(), 'YYYY-MM-DD') between a.period_start_date and a.period_end_date
        order by period_start_date DESC
        LIMIT 1 OFFSET 0;
    end if;
    
    if (coalesce(v_period_id,-1) <= 0) then
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
      and (a.period_start_date <= b.valid_end_date or coalesce(b.valid_end_date, '') = '')
      and b.position_id = org.get_org_pos_id(p_position_code, a.org_id)
      and b.div_id = p_group_id
      and (b.div_sub_cat_id1 = p_course_id or p_course_id <= 0)
      and (b.div_sub_cat_id2 = p_subject_id or (coalesce(b.div_sub_cat_id2, -1) <= 0 and p_subject_id <= 0));
    RETURN coalesce(bid, -1);
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_pos_hldr_prs_nm(
	p_period_id bigint,
	p_group_id integer,
	p_course_id integer,
	p_subject_id integer,
	p_position_code character varying)
    RETURNS text
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
<<outerblock>>
    DECLARE
    bid         BIGINT := -1;
    v_Res       TEXT   := '';
    v_period_id BIGINT := -1;
BEGIN
    v_period_id := p_period_id;
    if (coalesce(v_period_id,-1) <= 0) then
        select assmnt_period_id
        into v_period_id
        from aca.aca_assessment_periods a
        WHERE to_char(now(), 'YYYY-MM-DD') between a.period_start_date and a.period_end_date
        order by period_start_date DESC
        LIMIT 1 OFFSET 0;
    end if;
    
    if (coalesce(v_period_id,-1) <= 0) then
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
      and (a.period_start_date <= b.valid_end_date or coalesce(b.valid_end_date, '') = '')
      and b.position_id = org.get_org_pos_id(p_position_code, a.org_id)
      and b.div_id = p_group_id
      and (b.div_sub_cat_id1 = p_course_id or p_course_id <= 0)
      and (b.div_sub_cat_id2 = p_subject_id or (coalesce(b.div_sub_cat_id2, -1) <= 0 and p_subject_id <= 0));
    v_Res := prs.get_prsn_name(coalesce(bid, -1)) || ' (' || prs.get_prsn_loc_id(coalesce(bid, -1)) || ')';
    RETURN coalesce(v_Res, '');
END;
$BODY$;