CREATE OR REPLACE FUNCTION pay.get_itm_st_id(
	p_itm_st_nm character varying, p_org_id integer)
    RETURNS integer
    LANGUAGE 'sql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
select hdr_id from pay.pay_itm_sets_hdr where itm_set_name ilike '%'||p_itm_st_nm||'%' 
and org_id = p_org_id;
$BODY$;

CREATE OR REPLACE FUNCTION aca.isprsnelgbltorgstr(
	p_prsnid bigint,
	p_allwd_prsn_typs character varying,
	p_fees_prcnt numeric,
	p_ttl_pymnts_itm_st_nm character varying,
	p_ttl_bills_itm_st_nm character varying,
	p_ttl_bals_itm_st_nm character varying)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
<< outerblock >>
DECLARE
	v_res character varying(4000) := '';
	v_ttl_pymnts_itm_st_id bigint := - 1;
	v_ttl_bills_itm_st_id bigint := - 1;
	v_ttl_bals_itm_st_id bigint := - 1;
	v_ttl_pymnts_itm_st_sum numeric := 0;
	v_ttl_bills_itm_st_sum numeric := 0;
	v_ttl_bals_itm_st_sum numeric := 0;
	v_ltst_bill_dte character varying(21) := '';
    v_org_id integer :=-1;
BEGIN
    v_org_id := prs.get_prsn_org_id(p_prsnid);
	/*Work with latest figures from each itm set*/
	v_ttl_pymnts_itm_st_id := pay.get_itm_st_id(p_ttl_pymnts_itm_st_nm, v_org_id);
    --org.get_payitm_id (p_ttl_pymnts_itm_st_nm);
	v_ttl_bills_itm_st_id := pay.get_itm_st_id(p_ttl_bills_itm_st_nm, v_org_id);
    --org.get_payitm_id (p_ttl_bills_itm_st_nm);
	v_ttl_bals_itm_st_id := pay.get_itm_st_id(p_ttl_bals_itm_st_nm, v_org_id);
    --org.get_payitm_id (p_ttl_bals_itm_st_nm);
	IF coalesce(v_ttl_bills_itm_st_id, - 1) > 0 THEN
		SELECT
			SUM(coalesce(pay.get_ltst_paiditem_val_b4 (p_prsnid, item_id, to_char(now(), 'YYYY-MM-DD')), 0)),
			MAX(pay.get_ltst_paiditem_dte (p_prsnid, item_id)) INTO v_ttl_bills_itm_st_sum,
			v_ltst_bill_dte
		FROM
			pay.get_AllItmStDet (v_ttl_bills_itm_st_id::integer);
	END IF;
	IF coalesce(v_ltst_bill_dte, '') = '' THEN
		v_ltst_bill_dte := to_char(now(), 'YYYY-MM-DD');
	END IF;
	IF coalesce(v_ttl_pymnts_itm_st_id, - 1) > 0 THEN
		SELECT
			SUM(coalesce(pay.get_ltst_paiditem_val_afta (p_prsnid, item_id, v_ltst_bill_dte), 0)) INTO v_ttl_pymnts_itm_st_sum
		FROM
			pay.get_AllItmStDet (v_ttl_pymnts_itm_st_id::integer);
	END IF;
	IF coalesce(v_ttl_bals_itm_st_id, - 1) > 0 THEN
		SELECT
			SUM(coalesce(pay.get_ltst_blsitm_bals (p_prsnid, item_id, to_char(now(), 'YYYY-MM-DD')), 0)) INTO v_ttl_bals_itm_st_sum
		FROM
			pay.get_AllItmStDet (v_ttl_bals_itm_st_id::integer);
	END IF;
	IF coalesce(v_ttl_bills_itm_st_sum, 0) = 0 THEN
		v_ttl_bills_itm_st_sum := 1;
	END IF;
	IF NOT (p_allwd_prsn_typs ILIKE '%;' || pasn.get_prsn_type (p_prsnid) || ';%') THEN
		v_res := 'NO:Sorry you cannot Register until you are defined in the ff Person Types! - ' || BTRIM(p_allwd_prsn_typs, ';');
	END IF;
	IF ((round((v_ttl_pymnts_itm_st_sum / v_ttl_bills_itm_st_sum),2) < (p_fees_prcnt / 100)) AND v_ttl_bals_itm_st_sum !=0) THEN
		v_res := 'NO:Sorry you cannot Register until you have paid ' || p_fees_prcnt || '% of your Total Bills/Charges!<br/>Total Bill:'|| v_ttl_bills_itm_st_sum|| '<br/>Total Payments Made:'||v_ttl_pymnts_itm_st_sum||'<br/>Outstanding Balance: ' || v_ttl_bals_itm_st_sum;
	END IF;
	RETURN COALESCE(v_res, 'YES:You can Register!');
EXCEPTION
	WHEN OTHERS THEN
		v_res := 'NO:' || SQLERRM;
	RETURN v_res;
END;
$BODY$;

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