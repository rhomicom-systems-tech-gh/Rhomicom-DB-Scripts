CREATE OR REPLACE FUNCTION accb.populate_conso_trial_bals (p_rpt_run_id bigint , p_use_net_pos character varying , p_as_at_date character varying , p_max_acnt_level integer , p_start_accnt_id integer , p_shw_varncs character varying , p_sgmnt1_val integer , p_sgmnt2_val integer , p_sgmnt3_val integer , p_sgmnt4_val integer , p_sgmnt5_val integer , p_sgmnt6_val integer , p_sgmnt7_val integer , p_sgmnt8_val integer , p_sgmnt9_val integer , p_sgmnt10_val integer , p_who_rn bigint , p_run_date character varying , p_orgidno integer , p_msgid bigint)
	RETURNS text
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE PARALLEL UNSAFE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_msgs text;
	v_UpdtMsgs text;
	vRD RECORD;
	vRecsDate character varying(21);
	v_ttlSgmnts text := '';
	v_amnt1 numeric := 0;
	v_amnt2 numeric := 0;
	v_amnt3 numeric := 0;
	v_amnt4 numeric := 0;
	v_amnt5 numeric := 0;
	v_amnt6 numeric := 0;
	v_amnt7 numeric := 0;
	vCntr integer := 0;
BEGIN
	SELECT
		TO_CHAR(NOW() , 'YYYY-MM-DD HH24:MI:SS') INTO vRecsDate;
	DELETE FROM rpt.rpt_accb_data_storage
	WHERE AGE(NOW() , TO_TIMESTAMP(rpt_run_date , 'YYYY-MM-DD HH24:MI:SS')) > INTERVAL '1 day';
	v_msgs := 'Before Query vRecsDate:' || vRecsDate;
	v_ttlSgmnts := '' || p_sgmnt1_val || p_sgmnt2_val || p_sgmnt3_val || p_sgmnt4_val || p_sgmnt5_val || p_sgmnt6_val || p_sgmnt7_val || p_sgmnt8_val || p_sgmnt9_val || p_sgmnt10_val || '';
	--mapped_grp_accnt_id
	FOR vRD IN WITH RECURSIVE suborg (
		accnt_id
		, accnt_num
		, accnt_name
		, dbt_bal
		, crdt_bal
		, net_balance
		, as_at_date
		, is_prnt_accnt
		, mapped_grp_accnt_id
		, accnt_type
		, accnt_typ_id
		, depth
		, path
		, CYCLE
		, space
) AS (
		WITH RECURSIVE subsuborg (
			accnt_id
			, accnt_num
			, accnt_name
			, dbt_bal
			, crdt_bal
			, net_balance
			, as_at_date
			, is_prnt_accnt
			, mapped_grp_accnt_id
			, accnt_type
			, accnt_typ_id
			, depth
			, path
			, CYCLE
			, space
) AS (
			SELECT
				a.accnt_id
				, a.accnt_num
				, a.accnt_name
				, (
					SELECT
						c.dbt_bal
					FROM
						accb.accb_accnt_daily_bals c
					WHERE (TO_TIMESTAMP(c.as_at_date
							, 'YYYY-MM-DD') <= TO_TIMESTAMP(p_as_at_date || ' 23:59:59'
							, 'YYYY-MM-DD')
						AND a.accnt_id = c.accnt_id)
				ORDER BY
					TO_TIMESTAMP(c.as_at_date
						, 'YYYY-MM-DD') DESC
				LIMIT 1 OFFSET 0)
			, (
				SELECT
					d.crdt_bal
				FROM
					accb.accb_accnt_daily_bals d
				WHERE (TO_TIMESTAMP(d.as_at_date
						, 'YYYY-MM-DD') <= TO_TIMESTAMP(p_as_at_date || ' 23:59:59'
						, 'YYYY-MM-DD')
					AND a.accnt_id = d.accnt_id)
			ORDER BY
				TO_TIMESTAMP(d.as_at_date
					, 'YYYY-MM-DD') DESC
			LIMIT 1 OFFSET 0)
		, (
			SELECT
				e.net_balance
			FROM
				accb.accb_accnt_daily_bals e
			WHERE (TO_TIMESTAMP(e.as_at_date
					, 'YYYY-MM-DD') <= TO_TIMESTAMP(p_as_at_date || ' 23:59:59'
					, 'YYYY-MM-DD')
				AND a.accnt_id = e.accnt_id)
		ORDER BY
			TO_TIMESTAMP(e.as_at_date
				, 'YYYY-MM-DD') DESC
		LIMIT 1 OFFSET 0)
	, TO_TIMESTAMP(b.as_at_date
		, 'YYYY-MM-DD')
	, a.is_prnt_accnt
	, a.mapped_grp_accnt_id
	, a.accnt_type
	, a.accnt_typ_id
	, 1
	, ARRAY[a.accnt_num || '']::character VARYING[]
	, FALSE
	, '' opad
FROM
	accb.accb_chart_of_accnts a
	LEFT OUTER JOIN accb.accb_accnt_daily_bals b ON (a.accnt_id = b.accnt_id)
WHERE ((
		CASE WHEN p_start_accnt_id > 0 THEN
			a.accnt_id
		WHEN a.prnt_accnt_id <= 0 THEN
			a.control_account_id
		ELSE
			a.prnt_accnt_id
		END) = p_start_accnt_id
		AND (a.org_id = p_orgidno)
		AND (a.control_account_id <= 0)
		AND (a.is_net_income = '0')
		AND (a.is_prnt_accnt = '1'
			OR (TO_TIMESTAMP(b.as_at_date
					, 'YYYY-MM-DD') = (
					SELECT
						MAX(TO_TIMESTAMP(f.as_at_date
								, 'YYYY-MM-DD'))
					FROM
						accb.accb_accnt_daily_bals f
					WHERE
						f.accnt_id = a.accnt_id
						AND TO_TIMESTAMP(f.as_at_date
							, 'YYYY-MM-DD') <= TO_TIMESTAMP(p_as_at_date || ' 23:59:59'
							, 'YYYY-MM-DD')))))
	UNION ALL
	SELECT
		a.accnt_id
		, a.accnt_num
		, a.accnt_name
		, (
			SELECT
				c.dbt_bal
			FROM
				accb.accb_accnt_daily_bals c
			WHERE (TO_TIMESTAMP(c.as_at_date
					, 'YYYY-MM-DD') <= TO_TIMESTAMP(p_as_at_date || ' 23:59:59'
					, 'YYYY-MM-DD')
				AND a.accnt_id = c.accnt_id)
		ORDER BY
			TO_TIMESTAMP(c.as_at_date
				, 'YYYY-MM-DD') DESC
		LIMIT 1 OFFSET 0)
	, (
		SELECT
			d.crdt_bal
		FROM
			accb.accb_accnt_daily_bals d
		WHERE (TO_TIMESTAMP(d.as_at_date
				, 'YYYY-MM-DD') <= TO_TIMESTAMP(p_as_at_date || ' 23:59:59'
				, 'YYYY-MM-DD')
			AND a.accnt_id = d.accnt_id)
	ORDER BY
		TO_TIMESTAMP(d.as_at_date
			, 'YYYY-MM-DD') DESC
	LIMIT 1 OFFSET 0)
, (
	SELECT
		e.net_balance
	FROM
		accb.accb_accnt_daily_bals e
	WHERE (TO_TIMESTAMP(e.as_at_date
			, 'YYYY-MM-DD') <= TO_TIMESTAMP(p_as_at_date || ' 23:59:59'
			, 'YYYY-MM-DD')
		AND a.accnt_id = e.accnt_id)
ORDER BY
	TO_TIMESTAMP(e.as_at_date
		, 'YYYY-MM-DD') DESC
LIMIT 1 OFFSET 0)
, TO_TIMESTAMP((
	SELECT
		MAX(d.as_at_date)
		FROM accb.accb_accnt_daily_bals d
	WHERE (TO_TIMESTAMP(d.as_at_date
			, 'YYYY-MM-DD') <= TO_TIMESTAMP(p_as_at_date || ' 23:59:59'
			, 'YYYY-MM-DD')
		AND a.accnt_id = d.accnt_id))
, 'YYYY-MM-DD')
, a.is_prnt_accnt
, a.mapped_grp_accnt_id
, a.accnt_type
, a.accnt_typ_id
, sd.depth + 1
, path || a.accnt_num
, a.accnt_num = ANY (path)
, space || '           '
FROM
	accb.accb_chart_of_accnts a
	, subsuborg AS sd
	WHERE ((
			CASE WHEN a.prnt_accnt_id <= 0 THEN
				a.control_account_id
			ELSE
				a.prnt_accnt_id
			END) = sd.accnt_id
		AND NOT CYCLE)
		AND (v_ttlSgmnts = '-1-1-1-1-1-1-1-1-1-1'
			OR a.is_prnt_accnt = '1'
			OR (a.accnt_seg1_val_id = p_sgmnt1_val
				AND p_sgmnt1_val > 0)
			OR (a.accnt_seg2_val_id = p_sgmnt2_val
				AND p_sgmnt2_val > 0)
			OR (a.accnt_seg3_val_id = p_sgmnt3_val
				AND p_sgmnt3_val > 0)
			OR (a.accnt_seg4_val_id = p_sgmnt4_val
				AND p_sgmnt4_val > 0)
			OR (a.accnt_seg5_val_id = p_sgmnt5_val
				AND p_sgmnt5_val > 0)
			OR (a.accnt_seg6_val_id = p_sgmnt6_val
				AND p_sgmnt6_val > 0)
			OR (a.accnt_seg7_val_id = p_sgmnt7_val
				AND p_sgmnt7_val > 0)
			OR (a.accnt_seg8_val_id = p_sgmnt8_val
				AND p_sgmnt8_val > 0)
			OR (a.accnt_seg9_val_id = p_sgmnt9_val
				AND p_sgmnt9_val > 0)
			OR (a.accnt_seg10_val_id = p_sgmnt10_val
				AND p_sgmnt10_val > 0))
		AND ((a.org_id = p_orgidno)
			AND (a.control_account_id <= 0)
			AND (a.is_net_income = '0')))
	SELECT
		accnt_id
		, accnt_num
		, accnt_name
		, dbt_bal
		, crdt_bal
		, net_balance
		, as_at_date
		, is_prnt_accnt
		, mapped_grp_accnt_id
		, accnt_type
		, accnt_typ_id
		, depth
		, path
		, CYCLE
		, space
	FROM
		subsuborg
	UNION ALL
	SELECT
		a.accnt_id
		, a.accnt_num
		, a.accnt_name
		, (
			SELECT
				c.dbt_bal
			FROM
				accb.accb_accnt_daily_bals c
			WHERE (TO_TIMESTAMP(c.as_at_date
					, 'YYYY-MM-DD') <= TO_TIMESTAMP(p_as_at_date || ' 23:59:59'
					, 'YYYY-MM-DD')
				AND a.accnt_id = c.accnt_id)
		ORDER BY
			TO_TIMESTAMP(c.as_at_date
				, 'YYYY-MM-DD') DESC
		LIMIT 1 OFFSET 0)
	, (
		SELECT
			d.crdt_bal
		FROM
			accb.accb_accnt_daily_bals d
		WHERE (TO_TIMESTAMP(d.as_at_date
				, 'YYYY-MM-DD') <= TO_TIMESTAMP(p_as_at_date || ' 23:59:59'
				, 'YYYY-MM-DD')
			AND a.accnt_id = d.accnt_id)
	ORDER BY
		TO_TIMESTAMP(d.as_at_date
			, 'YYYY-MM-DD') DESC
	LIMIT 1 OFFSET 0)
, (
	SELECT
		e.net_balance
	FROM
		accb.accb_accnt_daily_bals e
	WHERE (TO_TIMESTAMP(e.as_at_date
			, 'YYYY-MM-DD') <= TO_TIMESTAMP(p_as_at_date || ' 23:59:59'
			, 'YYYY-MM-DD')
		AND a.accnt_id = e.accnt_id)
ORDER BY
	TO_TIMESTAMP(e.as_at_date
		, 'YYYY-MM-DD') DESC
LIMIT 1 OFFSET 0)
, TO_TIMESTAMP((
	SELECT
		MAX(d.as_at_date)
		FROM accb.accb_accnt_daily_bals d
	WHERE (TO_TIMESTAMP(d.as_at_date
			, 'YYYY-MM-DD') <= TO_TIMESTAMP(p_as_at_date || ' 23:59:59'
			, 'YYYY-MM-DD')
		AND a.accnt_id = d.accnt_id))
, 'YYYY-MM-DD')
, a.is_prnt_accnt
, a.mapped_grp_accnt_id
, a.accnt_type
, a.accnt_typ_id
, sd.depth + 1
, path || a.accnt_num
, a.accnt_num = ANY (path)
, space || '                      '
FROM
	accb.accb_chart_of_accnts a
	, suborg AS sd
	WHERE (a.mapped_grp_accnt_id = sd.accnt_id
		AND NOT CYCLE))
SELECT
	ROW_NUMBER() OVER (ORDER BY accnt_typ_id , path) rownumbr
, accnt_id
, space || '' lftpaddng
, accnt_num account_number
, accnt_name
, dbt_bal
, crdt_bal
, net_balance
, as_at_date
, is_prnt_accnt
, accnt_type
, accnt_typ_id
, depth
, path
, CYCLE
FROM
	suborg
WHERE
	depth <= p_max_acnt_level
ORDER BY
	accnt_typ_id
	, path LOOP
		v_amnt1 := vRD.dbt_bal;
		v_amnt2 := vRD.crdt_bal;
		v_amnt3 := vRD.net_balance;
		IF (p_use_net_pos ILIKE 'Yes') THEN
			IF (v_amnt2 > v_amnt1) THEN
				v_amnt2 := v_amnt2 - v_amnt1;
				v_amnt1 := 0;
			ELSE
				v_amnt1 := v_amnt1 - v_amnt2;
				v_amnt2 := 0;
			END IF;
		END IF;
		IF vRD.is_prnt_accnt = '1' THEN
			--For Parent Accounts
			IF p_shw_varncs = 'Yes' THEN
				v_amnt1 := accb.get_ltst_prnt_accnt_tbals3 (vrd.accnt_id , p_as_at_date , 'dbt_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
				v_amnt2 := accb.get_ltst_prnt_accnt_tbals3 (vrd.accnt_id , p_as_at_date , 'crdt_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
				v_amnt3 := accb.get_ltst_prnt_accnt_tbals3 (vrd.accnt_id , p_as_at_date , 'net_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
				v_amnt4 := 0;
				v_amnt1 := v_amnt1 - accb.get_prnt_trns_sum_rcsv (vrd.accnt_id , 'dbt_amount' , p_as_at_date);
				v_amnt2 := v_amnt2 - accb.get_prnt_trns_sum_rcsv (vrd.accnt_id , 'crdt_amount' , p_as_at_date);
				v_amnt3 := v_amnt3 - accb.get_prnt_trns_sum_rcsv (vrd.accnt_id , 'net_amount' , p_as_at_date);
			ELSE
				IF (p_use_net_pos ILIKE 'Yes') THEN
					v_amnt1 := accb.get_ltst_prnt_accnt_tbals2 (vrd.accnt_id , p_as_at_date , 'dbt_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
					v_amnt2 := accb.get_ltst_prnt_accnt_tbals2 (vrd.accnt_id , p_as_at_date , 'crdt_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
					v_amnt3 := accb.get_ltst_prnt_accnt_tbals2 (vrd.accnt_id , p_as_at_date , 'net_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
					IF (v_amnt2 > v_amnt1) THEN
						v_amnt2 := v_amnt2 - v_amnt1;
						v_amnt4 := v_amnt1;
						v_amnt1 := 0;
					ELSE
						v_amnt1 := v_amnt1 - v_amnt2;
						v_amnt4 := v_amnt2;
						v_amnt2 := 0;
					END IF;
				ELSE
					v_amnt1 := accb.get_ltst_prnt_accnt_tbals3 (vrd.accnt_id , p_as_at_date , 'dbt_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
					v_amnt2 := accb.get_ltst_prnt_accnt_tbals3 (vrd.accnt_id , p_as_at_date , 'crdt_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
					v_amnt3 := accb.get_ltst_prnt_accnt_tbals3 (vrd.accnt_id , p_as_at_date , 'net_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
					v_amnt4 := 0;
				END IF;
			END IF;
			IF vRD.depth = 1 THEN
				v_amnt5 := COALESCE((v_amnt1 + v_amnt4) , 0);
				v_amnt6 := COALESCE((v_amnt2 + v_amnt4) , 0);
			ELSE
				v_amnt5 := 0;
				v_amnt6 := 0;
			END IF;
			vCntr := vCntr + 1;
			INSERT INTO rpt.rpt_accb_data_storage (accb_rpt_runid , rpt_run_date , gnrl_data1 , gnrl_data2 , gnrl_data3 , gnrl_data4 , gnrl_data5 , gnrl_data6 , gnrl_data7 , gnrl_data8 , gnrl_data9 , gnrl_data10 , gnrl_data11 , gnrl_data12 , gnrl_data13 , gnrl_data14 , gnrl_data15 , gnrl_data16 , gnrl_data17 , gnrl_data18 , gnrl_data19 , gnrl_data20 , gnrl_data21 , gnrl_data22 , gnrl_data23 , gnrl_data24 , gnrl_data25 , gnrl_data26 , gnrl_data27 , gnrl_data28 , gnrl_data29 , gnrl_data30 , gnrl_data31 , gnrl_data32 , gnrl_data33 , gnrl_data34 , gnrl_data35 , gnrl_data36 , gnrl_data37 , gnrl_data38 , gnrl_data39 , gnrl_data40 , gnrl_data41 , gnrl_data42 , gnrl_data43 , gnrl_data44 , gnrl_data45 , gnrl_data46 , gnrl_data47 , gnrl_data48 , gnrl_data49 , gnrl_data50)
				VALUES (p_rpt_run_id , vRecsDate , '' || vCntr , vRD.account_number , vRD.accnt_name , '' || COALESCE((v_amnt1 + v_amnt4) , 0) , '' || COALESCE((v_amnt2 + v_amnt4) , 0) , '' || COALESCE(v_amnt3 , 0) , CASE WHEN vRD.as_at_date IS NULL THEN
						''
					ELSE
						TO_CHAR(vRD.as_at_date , 'DD-Mon-YYYY')
					END , vRD.accnt_id , vRD.is_prnt_accnt , '' || COALESCE(v_amnt5 , 0) , '' || COALESCE(v_amnt6 , 0) , '' || vRD.depth , vRD.path , vRD.lftpaddng || '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '');
		ELSE
			--For Non-Parent Accounts
			IF p_shw_varncs = 'Yes' THEN
				v_amnt4 := 0;
				v_amnt3 := 0;
				v_amnt1 := vRD.dbt_bal - accb.get_accnt_trnssum1 (vrd.accnt_id , 'dbt_amount' , p_as_at_date);
				v_amnt2 := vRD.crdt_bal - accb.get_accnt_trnssum1 (vrd.accnt_id , 'crdt_amount' , p_as_at_date);
				v_amnt3 := vRD.net_balance - accb.get_accnt_trnssum1 (vrd.accnt_id , 'net_amount' , p_as_at_date);
			END IF;
			IF (COALESCE(v_amnt1 , 0) != 0 OR COALESCE(v_amnt2 , 0) != 0) THEN
				v_amnt5 := 0;
				v_amnt6 := 0;
				vCntr := vCntr + 1;
				INSERT INTO rpt.rpt_accb_data_storage (accb_rpt_runid , rpt_run_date , gnrl_data1 , gnrl_data2 , gnrl_data3 , gnrl_data4 , gnrl_data5 , gnrl_data6 , gnrl_data7 , gnrl_data8 , gnrl_data9 , gnrl_data10 , gnrl_data11 , gnrl_data12 , gnrl_data13 , gnrl_data14 , gnrl_data15 , gnrl_data16 , gnrl_data17 , gnrl_data18 , gnrl_data19 , gnrl_data20 , gnrl_data21 , gnrl_data22 , gnrl_data23 , gnrl_data24 , gnrl_data25 , gnrl_data26 , gnrl_data27 , gnrl_data28 , gnrl_data29 , gnrl_data30 , gnrl_data31 , gnrl_data32 , gnrl_data33 , gnrl_data34 , gnrl_data35 , gnrl_data36 , gnrl_data37 , gnrl_data38 , gnrl_data39 , gnrl_data40 , gnrl_data41 , gnrl_data42 , gnrl_data43 , gnrl_data44 , gnrl_data45 , gnrl_data46 , gnrl_data47 , gnrl_data48 , gnrl_data49 , gnrl_data50)
					VALUES (p_rpt_run_id , vRecsDate , '' || vCntr , vRD.account_number , vRD.accnt_name , '' || COALESCE(v_amnt1 , 0) , '' || COALESCE(v_amnt2 , 0) , '' || COALESCE(v_amnt3 , 0) , CASE WHEN vRD.as_at_date IS NULL THEN
							''
						ELSE
							TO_CHAR(vRD.as_at_date , 'DD-Mon-YYYY')
						END , vRD.accnt_id , vRD.is_prnt_accnt , '' || COALESCE(v_amnt5 , 0) , '' || COALESCE(v_amnt6 , 0) , '' || vRD.depth , vRD.path , vRD.lftpaddng || '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '');
			END IF;
		END IF;
	END LOOP;
	v_msgs := v_msgs || CHR(10) || 'Successfully Populated Trial Balance into General Data Table!';
	v_UpdtMsgs := rpt.updaterptlogmsg (p_msgid , v_msgs , p_run_date , p_who_rn);
	RETURN v_msgs;
EXCEPTION
	WHEN OTHERS THEN
		v_msgs := v_msgs || CHR(10) || '' || SQLSTATE || CHR(10) || SQLERRM;
	v_UpdtMsgs := rpt.updaterptlogmsg (p_msgid , v_msgs , p_run_date , p_who_rn);
	RAISE NOTICE 'ERRORS:%' , v_msgs;
	RAISE EXCEPTION 'ERRORS:%' , v_msgs USING HINT = 'Please check your System Setup or Contact Vendor' || v_msgs;
RETURN v_msgs;
END;

$BODY$;

CREATE OR REPLACE FUNCTION accb.check_n_update_clsfctns (p_who_rn bigint , p_run_date character varying , orgidno integer , p_msgid bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE PARALLEL UNSAFE
	AS $BODY$
	<< outerblock >>
DECLARE
	rd3 RECORD;
	rd2 RECORD;
	rd1 RECORD;
	msgs text := CHR(10) || '';
	v_Cntr integer := 0;
	batchCntr integer := 0;
	v_reslt_1 character varying(200) := '';
	dateStr character varying(21) := '';
BEGIN
	/*
	 1. Get all Natural Account Classifications
	 2. For each Natural Account get all such Combinations from Chart of Accounts
	 3. If it has classification skip if not insert
	 */
	FOR rd1 IN
	SELECT
		account_clsfctn_id
		, account_id
		, maj_rpt_ctgry
		, min_rpt_ctgry
	FROM
		org.org_account_clsfctns
	WHERE
		COALESCE(maj_rpt_ctgry , '') != ''
			OR COALESCE(min_rpt_ctgry , '') != '' LOOP
					msgs := '';
					FOR rd2 IN
					SELECT
						accnt_id
						, accnt_num
						, accnt_name
						, accnt_desc
					FROM
						accb.accb_chart_of_accnts
					WHERE
						accnt_seg1_val_id = rd1.account_id LOOP
							--Check if Classification exists
							SELECT
								COUNT(account_clsfctn_id) INTO v_Cntr
							FROM
								accb.accb_account_clsfctns
							WHERE
								account_id = rd2.accnt_id
								AND maj_rpt_ctgry = rd1.maj_rpt_ctgry
								AND min_rpt_ctgry = rd1.min_rpt_ctgry;
							IF v_Cntr <= 0 THEN
								--Absent so Insert Record
								INSERT INTO accb.accb_account_clsfctns (account_id , maj_rpt_ctgry , min_rpt_ctgry , created_by , creation_date , last_update_by , last_update_date)
									VALUES (rd2.accnt_id , rd1.maj_rpt_ctgry , rd1.min_rpt_ctgry , p_who_rn , TO_CHAR(NOW() , 'YYYY-MM-DD HH24:MI:SS') , p_who_rn , TO_CHAR(NOW() , 'YYYY-MM-DD HH24:MI:SS'));
							END IF;
						END LOOP;
				END LOOP;
	msgs := 'SUCCESS:Account Classifications Successfully Imported!';
	RETURN REPLACE(msgs , CHR(10) , '<br/>');
EXCEPTION
	WHEN OTHERS THEN
		msgs := msgs || CHR(10) || '' || SQLSTATE || CHR(10) || SQLERRM;
	msgs := REPLACE(msgs , CHR(10) , '<br/>');
	RETURN msgs;
END;

$BODY$;

