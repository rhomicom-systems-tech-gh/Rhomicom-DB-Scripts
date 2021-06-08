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

-- FUNCTION: accb.populate_bog_rpt1(bigint, character varying, character varying, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, bigint, character varying, integer, bigint)
-- DROP FUNCTION accb.populate_bog_rpt1(bigint, character varying, character varying, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, bigint, character varying, integer, bigint);
CREATE OR REPLACE FUNCTION accb.populate_bog_rptv2 (p_rpt_run_id bigint , p_as_at_date character varying , p_schdl_type character varying , p_sgmnt1_val integer , p_sgmnt2_val integer , p_sgmnt3_val integer , p_sgmnt4_val integer , p_sgmnt5_val integer , p_sgmnt6_val integer , p_sgmnt7_val integer , p_sgmnt8_val integer , p_sgmnt9_val integer , p_sgmnt10_val integer , p_who_rn bigint , p_run_date character varying , p_orgidno integer , p_msgid bigint)
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
	v_as_at_date1 character varying(21);
	v_as_at_date2 character varying(21);
	v_as_at_date3 character varying(21);
	v_as_at_date4 character varying(21);
	v_as_at_date5 character varying(21);
	v_as_at_date6 character varying(21);
	v_as_at_date7 character varying(21);
	v_ttlSgmnts text := '';
	v_amnt1 numeric := 0;
	v_amnt2 numeric := 0;
	v_amnt3 numeric := 0;
	v_amnt4 numeric := 0;
	v_amnt5 numeric := 0;
	v_amnt6 numeric := 0;
	v_amnt7 numeric := 0;
	v_amnt8 numeric := 0;
	v_amnt9 numeric := 0;
	v_amnt10 numeric := 0;
	vCntr integer := 0;
	v_aClmFntBlds character varying(5)[];
	v_aClmVals character varying(5)[];
	v_bClmVals character varying(300)[];
	v_cClmVals character varying(300)[];
	v_dClmVals character varying(300)[];
	v_aClmFntBldsS character varying(5)[];
	v_aClmValsS character varying(5)[];
	v_bClmValsS character varying(300)[];
	v_bClmValsMj character varying(300)[];
	v_dClmValsS character varying(300)[];
	v_cClmVals1 character varying(300)[];
	v_cClmVals2 character varying(300)[];
	v_cClmVals3 character varying(300)[];
	v_cClmVals4 character varying(300)[];
	v_cClmVals5 character varying(300)[];
	v_cClmVals6 character varying(300)[];
	v_cClmVals7 character varying(300)[];
	v_cClmVals1S character varying(300)[];
	v_cClmVals2S character varying(300)[];
	v_MajCtgry character varying(300);
BEGIN
	SELECT
		TO_CHAR(NOW() , 'YYYY-MM-DD HH24:MI:SS') INTO vRecsDate;
	DELETE FROM rpt.rpt_gnrl_data_storage
	WHERE AGE(NOW() , TO_TIMESTAMP(rpt_run_date , 'YYYY-MM-DD HH24:MI:SS')) > INTERVAL '1 days'
		OR rpt_run_id = p_rpt_run_id;
	v_msgs := 'Before Query vRecsDate:' || vRecsDate;
	v_ttlSgmnts := '' || p_sgmnt1_val || p_sgmnt2_val || p_sgmnt3_val || p_sgmnt4_val || p_sgmnt5_val || p_sgmnt6_val || p_sgmnt7_val || p_sgmnt8_val || p_sgmnt9_val || p_sgmnt10_val || '';
	IF p_schdl_type = 'MF2A' OR p_schdl_type = 'MNB100' THEN
		v_aClmFntBlds := '{ "1", "1.1", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "1", "1", "1", "1", "0", "0", "0", "0", "1", "0", "0", "0", "0", "0", "0", "0", "1", "1", "1", "0", "0", "1" }';
		v_aClmVals := '{ "A", "1", "1.1", "1.2", "1.3", "1.4", "1.5", "1.6", "1.7", "2", "3", "4","5","6","7","8","9","", "B","", "1", "1.1", "1.2", "1.3", "1.4", "2", "2.1", "2.2", "2.3","2.4","2.5","2.6","2.7","","","C","1","2","" }';
		v_bClmVals := '{ "ASSETS",
		            "Cash and Short Term Funds",
                    "Cash on Hand (MNB107)",
                    "Balances in Current Accounts With Bank/Fin Inst",
                    "Balances in Savings Account With Banks/Fin Inst",
					"Cheques for Clearing Presented to Other Banks(MNB300)",
                    "Money On Call With Banks/Fin Inst ",
                    "Placement With Banks/Fin Inst (MNB102)",
                    "GoG /BOG Securities (MNB102)",
                    "Loans and Advances (net) (MNB103)",
					"Shares and Other Equity Investments (Net) (MNB102)",
                    "Other Assets (MNB104)",
					"Non-Current Assets Held for Sale (MAFI500)",
					"Right-Of-Used Lease Assets (MAFI500)",
                    "Property, Plant and Equipment (net) (MAFI500)",
					"Intangible Assets (MAFI500)",
					"Goodwill",
                    "Total Assets",
                    "Shareholder''s Funds And Liabilities",
					"Shareholder''s Funds",
					"Capital + Reserves",
                    "Paid up Capital (Equity Shares)",
					"Non Cumulative Irredeemable Preference Shares",
					"Reserves (MNB105)",
                    "Deposit for Shares",
                    "Liabilities",
					"Cheques for Clearing Presented from Other Banks (MNB300)",
                    "Borrowings - Domestic (MNB108)",
                    "Borrowings - Foreign (MNB108)",
                    "Deposits From The Public (MNB106)",
                    "Lease Liabilities",
					"Subordinated Liabilities Due After Five Years",
					"Other Liabilities (MNB104)",
                    "Total Liabilities",
                    "Shareholders'' Funds and Total Liabilities",
					"Off-Balance Sheet Liabilities",
					"Guarantees Issued",
					"Other Commitments",
					"Total" }';
		v_cClmVals := '{ "AMOUNT (GHS)", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00" }';
		v_dClmVals := '{ "% TO TOTAL ASSETS", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00" }';
		FOR a IN 1..39 LOOP
			IF a NOT IN (2 , 18 , 19 , 20 , 21 , 26 , 34 , 35 , 36 , 39) THEN
				v_amnt1 := accb.get_acnt_rpt_ctgry_sum11 (v_bClmVals[a] , p_as_at_date , 'net_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
				v_cClmVals[a] := '' || v_amnt1;
			END IF;
		END LOOP;
		FOR a IN 1..39 LOOP
			IF a IN (2 , 18 , 20 , 34 , 35 , 39) THEN
				IF a = 2 THEN
					v_amnt1 := v_cClmVals[3]::numeric + v_cClmVals[4]::numeric + v_cClmVals[5]::numeric + v_cClmVals[6]::numeric + v_cClmVals[7]::numeric + v_cClmVals[8]::numeric + v_cClmVals[9]::numeric;
				ELSIF a = 18 THEN
					v_amnt1 := v_cClmVals[2]::numeric + v_cClmVals[10]::numeric + v_cClmVals[11]::numeric + v_cClmVals[12]::numeric + v_cClmVals[13]::numeric + v_cClmVals[14]::numeric + v_cClmVals[15]::numeric + v_cClmVals[16]::numeric + v_cClmVals[17]::numeric;
				ELSIF a = 20 THEN
					v_amnt1 := v_cClmVals[22]::numeric + v_cClmVals[23]::numeric + v_cClmVals[24]::numeric + v_cClmVals[25]::numeric;
				ELSIF a = 34 THEN
					v_amnt1 := v_cClmVals[27]::numeric + v_cClmVals[28]::numeric + v_cClmVals[29]::numeric + v_cClmVals[30]::numeric + v_cClmVals[31]::numeric + v_cClmVals[32]::numeric + v_cClmVals[33]::numeric;
				ELSIF a = 35 THEN
					v_amnt1 := v_cClmVals[20]::numeric + v_cClmVals[34]::numeric;
				ELSIF a = 39 THEN
					v_amnt1 := v_cClmVals[37]::numeric + v_cClmVals[38]::numeric;
				END IF;
				v_cClmVals[a] := '' || v_amnt1;
			END IF;
		END LOOP;
		FOR a IN 1..39 LOOP
			IF v_cClmVals[18]::numeric = 0 THEN
				v_cClmVals[18] := '1';
			END IF;
			IF v_cClmVals[35]::numeric = 0 THEN
				v_cClmVals[35] := '1';
			END IF;
			IF a <= 18 AND a NOT IN (1) THEN
				v_amnt1 := ROUND((v_cClmVals[a]::numeric / v_cClmVals[18]::numeric) * 1.00 , 5);
				v_dClmVals[a] := '' || v_amnt1;
				vCntr := vCntr + 1;
				INSERT INTO rpt.rpt_gnrl_data_storage (rpt_run_id , rpt_run_date , gnrl_data1 , gnrl_data2 , gnrl_data3 , gnrl_data4 , gnrl_data5 , gnrl_data6 , gnrl_data7 , gnrl_data8 , gnrl_data9 , gnrl_data10 , gnrl_data11 , gnrl_data12 , gnrl_data13 , gnrl_data14 , gnrl_data15 , gnrl_data16 , gnrl_data17 , gnrl_data18 , gnrl_data19 , gnrl_data20 , gnrl_data21 , gnrl_data22 , gnrl_data23 , gnrl_data24 , gnrl_data25 , gnrl_data26 , gnrl_data27 , gnrl_data28 , gnrl_data29 , gnrl_data30)
					VALUES (p_rpt_run_id , vRecsDate , '' || a , v_aClmVals[a] , v_bClmVals[a] , v_cClmVals[a] , v_dClmVals[a] , v_aClmFntBlds[a] , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '');
			ELSIF a >= 19
					AND a <= 35
					AND a NOT IN (19 , 21 , 26) THEN
					v_amnt1 := ROUND((v_cClmVals[a]::numeric / v_cClmVals[35]::numeric) * 1.00 , 5);
				v_dClmVals[a] := '' || v_amnt1;
				vCntr := vCntr + 1;
				INSERT INTO rpt.rpt_gnrl_data_storage (rpt_run_id , rpt_run_date , gnrl_data1 , gnrl_data2 , gnrl_data3 , gnrl_data4 , gnrl_data5 , gnrl_data6 , gnrl_data7 , gnrl_data8 , gnrl_data9 , gnrl_data10 , gnrl_data11 , gnrl_data12 , gnrl_data13 , gnrl_data14 , gnrl_data15 , gnrl_data16 , gnrl_data17 , gnrl_data18 , gnrl_data19 , gnrl_data20 , gnrl_data21 , gnrl_data22 , gnrl_data23 , gnrl_data24 , gnrl_data25 , gnrl_data26 , gnrl_data27 , gnrl_data28 , gnrl_data29 , gnrl_data30)
					VALUES (p_rpt_run_id , vRecsDate , '' || a , v_aClmVals[a] , v_bClmVals[a] , v_cClmVals[a] , v_dClmVals[a] , v_aClmFntBlds[a] , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '');
			ELSIF a IN (1 , 19 , 21 , 26) THEN
				v_cClmVals[a] := '';
				v_dClmVals[a] := '';
				vCntr := vCntr + 1;
				INSERT INTO rpt.rpt_gnrl_data_storage (rpt_run_id , rpt_run_date , gnrl_data1 , gnrl_data2 , gnrl_data3 , gnrl_data4 , gnrl_data5 , gnrl_data6 , gnrl_data7 , gnrl_data8 , gnrl_data9 , gnrl_data10 , gnrl_data11 , gnrl_data12 , gnrl_data13 , gnrl_data14 , gnrl_data15 , gnrl_data16 , gnrl_data17 , gnrl_data18 , gnrl_data19 , gnrl_data20 , gnrl_data21 , gnrl_data22 , gnrl_data23 , gnrl_data24 , gnrl_data25 , gnrl_data26 , gnrl_data27 , gnrl_data28 , gnrl_data29 , gnrl_data30)
					VALUES (p_rpt_run_id , vRecsDate , '' || a , v_aClmVals[a] , v_bClmVals[a] , v_cClmVals[a] , v_dClmVals[a] , v_aClmFntBlds[a] , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '');
			END IF;
		END LOOP;
	ELSIF p_schdl_type = 'MF1' THEN
		v_aClmFntBlds := '{ "1", "0", "0", "0", "1", "1", "0", "0", "0", "0", "1", "1", "0", "0", "0", "0", "0", "1"}';
		v_aClmVals := '{ "A", "1", "2", "3", "4", "B", "i", "ii", "iii", "iv"," ", "C", "i", "ii", "iii", "iv", "v", " "}';
		v_bClmVals := '{ "DEPOSIT LIABILITIES",
                    "Savings accounts",
                    "Term deposits",
                    "Other deposits",
                    "Total deposits(1+2+3)",
                    "PRIMARY RESERVE ASSETS",
                    "Cash on hand",
                    "Balances at banks(current accounts)",
                    "Call deposits at banks/fin institution",
                    "Any other designated reserve eligible asset",
                    "Total Primary Reserve (sum i to iv)",
                    "SECONDARY RESERVE ASSETS",
                    "Treasury bills/Notes",
                    "BOG bills",
                    "BOG Notes/Bonds",
                    "Govt loan stock/bonds",
                    "Other investment with Class One Banks",
                    "Total Secondary Reserves (sum i to v)"}';
		v_cClmVals1 := '{ "Thursday", "0.00", "0.00", "0.00", "0.00", " ", "0.00", "0.00", "0.00", "0.00", "0.00", " ", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00"}';
		v_cClmVals2 := '{ "Friday", "0.00", "0.00", "0.00", "0.00", " ", "0.00", "0.00", "0.00", "0.00", "0.00", " ", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00" }';
		v_cClmVals3 := '{ "Saturday*", "0.00", "0.00", "0.00", "0.00", " ", "0.00", "0.00", "0.00", "0.00", "0.00", " ", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00" }';
		v_cClmVals4 := '{ "Sunday*", "0.00", "0.00", "0.00", "0.00", " ", "0.00", "0.00", "0.00", "0.00", "0.00", " ", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00" }';
		v_cClmVals5 := '{ "Monday", "0.00", "0.00", "0.00", "0.00", " ", "0.00", "0.00", "0.00", "0.00", "0.00", " ", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00" }';
		v_cClmVals6 := '{ "Tuesday", "0.00", "0.00", "0.00", "0.00", " ", "0.00", "0.00", "0.00", "0.00", "0.00", " ", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00" }';
		v_cClmVals7 := '{ "Wednesday", "0.00", "0.00", "0.00", "0.00", " ", "0.00", "0.00", "0.00", "0.00", "0.00", " ", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00" }';
		v_dClmVals := '{ "Weekly Average", "0.00", "0.00", "0.00", "0.00", " ", "0.00", "0.00", "0.00", "0.00", "0.00", " ", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00" }';
		v_aClmFntBldsS := '{ "1", "0", "0", "0", "1", "0", "0", "0", "1", "0", "0", "0","1","1"}';
		v_aClmValsS := '{ "A", "1", "2", "3", "4", "5", "6", "7", "8", "9","10", "11"," ", " "}';
		v_bClmValsS := '{ "SUMMARIZED RETURN ON LIQUIDITY RESERVES",
                    "Liquidity Reserves (average held during the week)",
                    "Deposit Liabilities (Average)",
                    "Primary Reserve Assets",
                    "Required Primary Reserves (10% of deposit liabilities)",
                    "Actual Primary reserves (Primary reserve/Deposit liabilities)",
                    "Excess/Deficit",
                    "Secondary Reserve Assets",
                    "Required Secondary Reserves (20% of deposit liabilities)",
                    "Actual Secondary reserves (Secondary reserve/Deposit liabilities)",
                    "Excess/Deficit",
                    "Total Loan Principal Outstanding",
                    " ",
                    "WEEKLY BREAKDOWN OF RETURNS"}';
		v_dClmValsS := '{ "Amount (GHS)", "0.00", "0.00", "0.00", "0.00", "0.00%", "0.00", "0.00", "0.00", "0.00$", "0.00", "0.00"," ", " "}';
		IF EXTRACT(DOW FROM TO_DATE(p_as_at_date , 'YYYY-MM-DD'))::int >= 3 THEN
			v_as_at_date1 := TO_CHAR(TO_DATE(p_as_at_date , 'YYYY-MM-DD') - 3 - CAST(EXTRACT(DOW FROM TO_DATE(p_as_at_date , 'YYYY-MM-DD')) AS int) + 0 , 'YYYY-MM-DD');
			v_as_at_date2 := TO_CHAR(TO_DATE(p_as_at_date , 'YYYY-MM-DD') - 3 - CAST(EXTRACT(DOW FROM TO_DATE(p_as_at_date , 'YYYY-MM-DD')) AS int) + 1 , 'YYYY-MM-DD');
			v_as_at_date3 := TO_CHAR(TO_DATE(p_as_at_date , 'YYYY-MM-DD') - 3 - CAST(EXTRACT(DOW FROM TO_DATE(p_as_at_date , 'YYYY-MM-DD')) AS int) + 2 , 'YYYY-MM-DD');
			v_as_at_date4 := TO_CHAR(TO_DATE(p_as_at_date , 'YYYY-MM-DD') - 3 - CAST(EXTRACT(DOW FROM TO_DATE(p_as_at_date , 'YYYY-MM-DD')) AS int) + 3 , 'YYYY-MM-DD');
			v_as_at_date5 := TO_CHAR(TO_DATE(p_as_at_date , 'YYYY-MM-DD') - 3 - CAST(EXTRACT(DOW FROM TO_DATE(p_as_at_date , 'YYYY-MM-DD')) AS int) + 4 , 'YYYY-MM-DD');
			v_as_at_date6 := TO_CHAR(TO_DATE(p_as_at_date , 'YYYY-MM-DD') - 3 - CAST(EXTRACT(DOW FROM TO_DATE(p_as_at_date , 'YYYY-MM-DD')) AS int) + 5 , 'YYYY-MM-DD');
			v_as_at_date7 := TO_CHAR(TO_DATE(p_as_at_date , 'YYYY-MM-DD') - 3 - CAST(EXTRACT(DOW FROM TO_DATE(p_as_at_date , 'YYYY-MM-DD')) AS int) + 6 , 'YYYY-MM-DD');
		ELSE
			v_as_at_date1 := TO_CHAR(TO_DATE(p_as_at_date , 'YYYY-MM-DD') - 10 - CAST(EXTRACT(DOW FROM TO_DATE(p_as_at_date , 'YYYY-MM-DD')) AS int) + 0 , 'YYYY-MM-DD');
			v_as_at_date2 := TO_CHAR(TO_DATE(p_as_at_date , 'YYYY-MM-DD') - 10 - CAST(EXTRACT(DOW FROM TO_DATE(p_as_at_date , 'YYYY-MM-DD')) AS int) + 1 , 'YYYY-MM-DD');
			v_as_at_date3 := TO_CHAR(TO_DATE(p_as_at_date , 'YYYY-MM-DD') - 10 - CAST(EXTRACT(DOW FROM TO_DATE(p_as_at_date , 'YYYY-MM-DD')) AS int) + 2 , 'YYYY-MM-DD');
			v_as_at_date4 := TO_CHAR(TO_DATE(p_as_at_date , 'YYYY-MM-DD') - 10 - CAST(EXTRACT(DOW FROM TO_DATE(p_as_at_date , 'YYYY-MM-DD')) AS int) + 3 , 'YYYY-MM-DD');
			v_as_at_date5 := TO_CHAR(TO_DATE(p_as_at_date , 'YYYY-MM-DD') - 10 - CAST(EXTRACT(DOW FROM TO_DATE(p_as_at_date , 'YYYY-MM-DD')) AS int) + 4 , 'YYYY-MM-DD');
			v_as_at_date6 := TO_CHAR(TO_DATE(p_as_at_date , 'YYYY-MM-DD') - 10 - CAST(EXTRACT(DOW FROM TO_DATE(p_as_at_date , 'YYYY-MM-DD')) AS int) + 5 , 'YYYY-MM-DD');
			v_as_at_date7 := TO_CHAR(TO_DATE(p_as_at_date , 'YYYY-MM-DD') - 10 - CAST(EXTRACT(DOW FROM TO_DATE(p_as_at_date , 'YYYY-MM-DD')) AS int) + 6 , 'YYYY-MM-DD');
		END IF;
		FOR a IN 1..18 LOOP
			IF a != 1 AND a != 6 AND a != 12 THEN
				IF a = 5 THEN
					v_amnt1 := REPLACE(v_cClmVals1[2] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals1 [3], ',', '')::numeric + REPLACE(v_cClmVals1[4] , ',' , '')::numeric;
					v_amnt2 := REPLACE(v_cClmVals2[2] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals2 [3], ',', '')::numeric + REPLACE(v_cClmVals2[4] , ',' , '')::numeric;
					v_amnt3 := REPLACE(v_cClmVals3[2] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals3 [3], ',', '')::numeric + REPLACE(v_cClmVals3[4] , ',' , '')::numeric;
					v_amnt4 := REPLACE(v_cClmVals4[2] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals4 [3], ',', '')::numeric + REPLACE(v_cClmVals4[4] , ',' , '')::numeric;
					v_amnt5 := REPLACE(v_cClmVals5[2] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals5 [3], ',', '')::numeric + REPLACE(v_cClmVals5[4] , ',' , '')::numeric;
					v_amnt6 := REPLACE(v_cClmVals6[2] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals6 [3], ',', '')::numeric + REPLACE(v_cClmVals6[4] , ',' , '')::numeric;
					v_amnt7 := REPLACE(v_cClmVals7[2] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals7 [3], ',', '')::numeric + REPLACE(v_cClmVals7[4] , ',' , '')::numeric;
					v_amnt8 := (v_amnt1 + v_amnt2 + v_amnt3 + v_amnt4 + v_amnt5 + v_amnt6 + v_amnt7) / 7.00;
				ELSIF a = 11 THEN
					v_amnt1 := REPLACE(v_cClmVals1[7] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals1 [8], ',', '')::numeric + REPLACE(v_cClmVals1[9] , ',' , '')::NUMERIC + REPLACE(v_cClmVals1[10] , ',' , '')::numeric;
					v_amnt2 := REPLACE(v_cClmVals2[7] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals2 [8], ',', '')::numeric + REPLACE(v_cClmVals2[9] , ',' , '')::NUMERIC + REPLACE(v_cClmVals2[10] , ',' , '')::numeric;
					v_amnt3 := REPLACE(v_cClmVals3[7] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals3 [8], ',', '')::numeric + REPLACE(v_cClmVals3[9] , ',' , '')::NUMERIC + REPLACE(v_cClmVals3[10] , ',' , '')::numeric;
					v_amnt4 := REPLACE(v_cClmVals4[7] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals4 [8], ',', '')::numeric + REPLACE(v_cClmVals4[9] , ',' , '')::NUMERIC + REPLACE(v_cClmVals4[10] , ',' , '')::numeric;
					v_amnt5 := REPLACE(v_cClmVals5[7] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals5 [8], ',', '')::numeric + REPLACE(v_cClmVals5[9] , ',' , '')::NUMERIC + REPLACE(v_cClmVals5[10] , ',' , '')::numeric;
					v_amnt6 := REPLACE(v_cClmVals6[7] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals6 [8], ',', '')::numeric + REPLACE(v_cClmVals6[9] , ',' , '')::NUMERIC + REPLACE(v_cClmVals6[10] , ',' , '')::numeric;
					v_amnt7 := REPLACE(v_cClmVals7[7] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals7 [8], ',', '')::numeric + REPLACE(v_cClmVals7[9] , ',' , '')::NUMERIC + REPLACE(v_cClmVals7[10] , ',' , '')::numeric;
					v_amnt8 := (v_amnt1 + v_amnt2 + v_amnt3 + v_amnt4 + v_amnt5 + v_amnt6 + v_amnt7) / 7.00;
				ELSIF a = 18 THEN
					v_amnt1 := REPLACE(v_cClmVals1[13] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals1 [14], ',', '')::numeric + REPLACE(v_cClmVals1[15] , ',' , '')::NUMERIC + REPLACE(v_cClmVals1[16] , ',' , '')::numeric + REPLACE(v_cClmVals1[17] , ',' , '')::numeric;
					v_amnt2 := REPLACE(v_cClmVals2[13] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals2 [14], ',', '')::numeric + REPLACE(v_cClmVals2[15] , ',' , '')::NUMERIC + REPLACE(v_cClmVals2[16] , ',' , '')::numeric + REPLACE(v_cClmVals2[17] , ',' , '')::numeric;
					v_amnt3 := REPLACE(v_cClmVals3[13] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals3 [14], ',', '')::numeric + REPLACE(v_cClmVals3[15] , ',' , '')::NUMERIC + REPLACE(v_cClmVals3[16] , ',' , '')::numeric + REPLACE(v_cClmVals3[17] , ',' , '')::numeric;
					v_amnt4 := REPLACE(v_cClmVals4[13] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals4 [14], ',', '')::numeric + REPLACE(v_cClmVals4[15] , ',' , '')::NUMERIC + REPLACE(v_cClmVals4[16] , ',' , '')::numeric + REPLACE(v_cClmVals4[17] , ',' , '')::numeric;
					v_amnt5 := REPLACE(v_cClmVals5[13] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals5 [14], ',', '')::numeric + REPLACE(v_cClmVals5[15] , ',' , '')::NUMERIC + REPLACE(v_cClmVals5[16] , ',' , '')::numeric + REPLACE(v_cClmVals5[17] , ',' , '')::numeric;
					v_amnt6 := REPLACE(v_cClmVals6[13] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals6 [14], ',', '')::numeric + REPLACE(v_cClmVals6[15] , ',' , '')::NUMERIC + REPLACE(v_cClmVals6[16] , ',' , '')::numeric + REPLACE(v_cClmVals6[17] , ',' , '')::numeric;
					v_amnt7 := REPLACE(v_cClmVals7[13] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals7 [14], ',', '')::numeric + REPLACE(v_cClmVals7[15] , ',' , '')::NUMERIC + REPLACE(v_cClmVals7[16] , ',' , '')::numeric + REPLACE(v_cClmVals7[17] , ',' , '')::numeric;
					v_amnt8 := (v_amnt1 + v_amnt2 + v_amnt3 + v_amnt4 + v_amnt5 + v_amnt6 + v_amnt7) / 7.00;
				ELSE
					v_amnt1 := accb.get_acnt_rpt_ctgry_sum11 (v_bClmVals[a] , v_as_at_date1 , 'net_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
					v_amnt2 := accb.get_acnt_rpt_ctgry_sum11 (v_bClmVals[a] , v_as_at_date2 , 'net_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
					v_amnt3 := accb.get_acnt_rpt_ctgry_sum11 (v_bClmVals[a] , v_as_at_date3 , 'net_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
					v_amnt4 := accb.get_acnt_rpt_ctgry_sum11 (v_bClmVals[a] , v_as_at_date4 , 'net_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
					v_amnt5 := accb.get_acnt_rpt_ctgry_sum11 (v_bClmVals[a] , v_as_at_date5 , 'net_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
					v_amnt6 := accb.get_acnt_rpt_ctgry_sum11 (v_bClmVals[a] , v_as_at_date6 , 'net_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
					v_amnt7 := accb.get_acnt_rpt_ctgry_sum11 (v_bClmVals[a] , v_as_at_date7 , 'net_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
					v_amnt8 := (v_amnt1 + v_amnt2 + v_amnt3 + v_amnt4 + v_amnt5 + v_amnt6 + v_amnt7) / 7.00;
				END IF;
				v_cClmVals1[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
				v_cClmVals2[a] := TRIM(TO_CHAR(v_amnt2 , '999G999G999G999G999G999G990D00'));
				v_cClmVals3[a] := TRIM(TO_CHAR(v_amnt3 , '999G999G999G999G999G999G990D00'));
				v_cClmVals4[a] := TRIM(TO_CHAR(v_amnt4 , '999G999G999G999G999G999G990D00'));
				v_cClmVals5[a] := TRIM(TO_CHAR(v_amnt5 , '999G999G999G999G999G999G990D00'));
				v_cClmVals6[a] := TRIM(TO_CHAR(v_amnt6 , '999G999G999G999G999G999G990D00'));
				v_cClmVals7[a] := TRIM(TO_CHAR(v_amnt7 , '999G999G999G999G999G999G990D00'));
				v_dClmVals[a] := TRIM(TO_CHAR(v_amnt8 , '999G999G999G999G999G999G990D00'));
			END IF;
		END LOOP;
		--SUMMARY RETURN
		FOR a IN 1..12 LOOP
			IF a != 1 THEN
				IF a = 2 OR a = 4 THEN
					v_amnt1 := REPLACE(v_dClmVals[11] , ',' , '')::numeric;
					v_dClmValsS[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 3 THEN
					v_amnt1 := REPLACE(v_dClmVals[5] , ',' , '')::numeric;
					v_dClmValsS[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 5 THEN
					v_amnt1 := (REPLACE(v_dClmVals[5] , ',' , '')::numeric) * 0.10;
					v_dClmValsS[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 6 THEN
					v_amnt1 := ((REPLACE(v_dClmValsS[4] , ',' , '')::NUMERIC) / COALESCE(NULLIF ((REPLACE(v_dClmValsS[3] , ',' , '')::numeric)
						, 0)
					, 1)) * 100.00;
					v_dClmValsS[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00')) || '%';
				ELSIF a = 7 THEN
					v_amnt1 := (REPLACE(v_dClmValsS[4] , ',' , '')::NUMERIC) - (REPLACE(v_dClmValsS[5] , ',' , '')::numeric);
					v_dClmValsS[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 8 THEN
					v_amnt1 := REPLACE(v_dClmVals[18] , ',' , '')::numeric;
					v_dClmValsS[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 9 THEN
					v_amnt1 := (REPLACE(v_dClmVals[5] , ',' , '')::numeric) * 0.20;
					v_dClmValsS[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 10 THEN
					v_amnt1 := ((REPLACE(v_dClmValsS[8] , ',' , '')::NUMERIC) / COALESCE(NULLIF ((REPLACE(v_dClmValsS[3] , ',' , '')::numeric)
						, 0)
					, 1)) * 100.00;
					v_dClmValsS[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00')) || '%';
				ELSIF a = 11 THEN
					v_amnt1 := (REPLACE(v_dClmValsS[8] , ',' , '')::NUMERIC) - (REPLACE(v_dClmValsS[9] , ',' , '')::numeric);
					v_dClmValsS[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 12 THEN
					v_amnt1 := accb.get_acnt_rpt_ctgry_sum11 (v_bClmValsS[a] , v_as_at_date7 , 'net_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
					v_dClmValsS[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
				END IF;
			END IF;
		END LOOP;
		vCntr := 0;
		FOR a IN 1..14 LOOP
			vCntr := vCntr + 1;
			INSERT INTO rpt.rpt_gnrl_data_storage (rpt_run_id , rpt_run_date , gnrl_data1 , gnrl_data2 , gnrl_data3 , gnrl_data4 , gnrl_data5 , gnrl_data6 , gnrl_data7 , gnrl_data8 , gnrl_data9 , gnrl_data10 , gnrl_data11 , gnrl_data12 , gnrl_data13 , gnrl_data14 , gnrl_data15 , gnrl_data16 , gnrl_data17 , gnrl_data18 , gnrl_data19 , gnrl_data20 , gnrl_data21 , gnrl_data22 , gnrl_data23 , gnrl_data24 , gnrl_data25 , gnrl_data26 , gnrl_data27 , gnrl_data28 , gnrl_data29 , gnrl_data30)
				VALUES (p_rpt_run_id , vRecsDate , '' || vCntr , v_aClmValsS[a] , v_bClmValsS[a] , v_dClmValsS[a] , v_aClmFntBldsS[a] , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '');
		END LOOP;
		FOR a IN 1..18 LOOP
			vCntr := vCntr + 1;
			INSERT INTO rpt.rpt_gnrl_data_storage (rpt_run_id , rpt_run_date , gnrl_data1 , gnrl_data2 , gnrl_data3 , gnrl_data4 , gnrl_data5 , gnrl_data6 , gnrl_data7 , gnrl_data8 , gnrl_data9 , gnrl_data10 , gnrl_data11 , gnrl_data12 , gnrl_data13 , gnrl_data14 , gnrl_data15 , gnrl_data16 , gnrl_data17 , gnrl_data18 , gnrl_data19 , gnrl_data20 , gnrl_data21 , gnrl_data22 , gnrl_data23 , gnrl_data24 , gnrl_data25 , gnrl_data26 , gnrl_data27 , gnrl_data28 , gnrl_data29 , gnrl_data30)
				VALUES (p_rpt_run_id , vRecsDate , '' || vCntr , v_aClmVals[a] , v_bClmVals[a] , v_dClmVals[a] , v_aClmFntBlds[a] , v_cClmVals1[a] , v_cClmVals2[a] , v_cClmVals3[a] , v_cClmVals4[a] , v_cClmVals5[a] , v_cClmVals6[a] , v_cClmVals7[a] , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '');
		END LOOP;
	ELSIF p_schdl_type = 'MF2B' THEN
		v_aClmFntBlds := '{ "1", "0", "0", "0", "0", "1", "0", "0", "1", "0", "0", "0", "0", "1", "0", "0", "0", "0", "1", "0", "0", "0", "1", "0", "0", "0", "0", "0","1", "0", "0"}';
		v_aClmVals := '{ " ", "1", "2", "3", "4", " ", "1", "2", " ", "1","2", "3", "4", " ", "1", "2", "3", "4"," ","1","2","3"," ","1","2","3","4","5"," ","1","2"}';
		v_bClmValsMj := '{ "Schedule A: Interest revenue on loans",
                    "Schedule A: Interest revenue on loans",
                    "Schedule A: Interest revenue on loans",
                    "Schedule A: Interest revenue on loans",
                    "Schedule A: Interest revenue on loans",
                    "SCHEDULE B Interest Revenue on investments (Deposit/placements)",
                    "SCHEDULE B Interest Revenue on investments (Deposit/placements)",
                    "SCHEDULE B Interest Revenue on investments (Deposit/placements)",
                    "SCHEDULE B Interest Revenue on investments (Deposit/placements)",
                    "SCHEDULE B Interest Revenue on investments (Deposit/placements)",
                    "SCHEDULE B Interest Revenue on investments (Deposit/placements)",
                    "SCHEDULE B Interest Revenue on investments (Deposit/placements)",
                    "SCHEDULE B Interest Revenue on investments (Deposit/placements)",
                    "SCHEDULE C Interest Expense",
                    "SCHEDULE C Interest Expense",
                    "SCHEDULE C Interest Expense",
                    "SCHEDULE C Interest Expense",
                    "SCHEDULE C Interest Expense",
                    "SCHEDULE D Other Operating income",
                    "SCHEDULE D Other Operating income",
                    "SCHEDULE D Other Operating income",
                    "SCHEDULE D Other Operating income",
                    "SCHEDULE E Operating Cost",
                    "SCHEDULE E Operating Cost",
                    "SCHEDULE E Operating Cost",
                    "SCHEDULE E Operating Cost",
                    "SCHEDULE E Operating Cost",
                    "SCHEDULE E Operating Cost",
                    "SCHEDULE F Non Operating Income / Non operating Expense",
                    "SCHEDULE F Non Operating Income / Non operating Expense",
                    "SCHEDULE F Non Operating Income / Non operating Expense"}';
		v_bClmVals := '{ "Schedule A: Interest revenue on loans",
                    "Small business loans",
                    "Group loans",
                    "Personal loans",
                    "Others",
                    "SCHEDULE B Interest Revenue on investments (Deposit/placements)",
                    "Interest bearing accounts and deposits with banks/fin institutions",
                    "Certificates of deposits with banks/Fin. Insti",
                    "SECURITIES",
                    "Treasury and BOG bills",
                    "GOG and BOG debt securities",
                    "Corporate debt securities",
                    "Others",
                    "SCHEDULE C Interest Expense",
                    "Savings Accounts",
                    "Fixed Deposits",
                    "Borrowings",
                    "Others",
                    "SCHEDULE D Other Operating income",
                    "Processing fees",
                    "Administrative fees",
                    "Other income",
                    "SCHEDULE E Operating Cost",
                    "Staff Expense",
                    "Administrative expense",
                    "Training and development",
                    "Depreciation Charge on PPE",
                    "Other operating expenses",
                    "SCHEDULE F Non Operating Income / Non operating Expense",
                    "Gain (loss) on sale of capital",
                    "Others"}';
		v_cClmVals1 := '{ "CURRENT MONTH (GHS)", "0.00", "0.00", "0.00", "0.00", " ", "0.00", "0.00", " ", "0.00", "0.00", "0.00", "0.00", " ", "0.00", "0.00", "0.00", "0.00"," ", "0.00", "0.00", "0.00"," ", "0.00", "0.00", "0.00", "0.00", "0.00"," ", "0.00", "0.00"}';
		v_cClmVals2 := '{ "FINANCIAL YEAR TO DATE (CUMULATIVE - GHS)", "0.00", "0.00", "0.00", "0.00", " ", "0.00", "0.00", " ", "0.00", "0.00", "0.00", "0.00", " ", "0.00", "0.00", "0.00", "0.00"," ", "0.00", "0.00", "0.00"," ", "0.00", "0.00", "0.00", "0.00", "0.00"," ", "0.00", "0.00" }';
		v_dClmVals := '{ "% OF TOTAL INCOME", "0.00%", "0.00%", "0.00%", "0.00%", " ", "0.00%", "0.00%", " ", "0.00%", "0.00%", "0.00%", "0.00%", " ", "0.00%", "0.00%", "0.00%", "0.00%"," ", "0.00%", "0.00%", "0.00%"," ", "0.00%", "0.00%", "0.00%", "0.00%", "0.00%"," ", "0.00%", "0.00%"}';
		v_aClmFntBldsS := '{ "1", "0", "0", "1", "0", "1", "0", "1", "0", "1", "0", "1","0","1","0","0","1","0","0"}';
		v_aClmValsS := '{ " ", "1", "2", "3", "4", "5", "6", "7", "8", "9","10", "11","12", "13","14","15","16"," "," "}';
		v_bClmValsS := '{ "INCOME / EXPENSE",
                    "  Interest on loans assets received (Schedule A)",
                    "  Interest on investments received (Schedule B)",
                    "Interest income (1+2)",
                    "  Interest expense (Schedule C)",
                    "Net interest income (3-4)",
                    "  Other operating income (Schedule D)",
                    "Total Operating Income (5+6)",
                    "  Operating cost (Schedule E)",
                    "Net Operating Income (7-8)",
                    "  Risk provisions (including charge offs)",
                    "Operating profit/loss (9-10)",
                    "  Non-operating income/loss (Schedule F)",
                    "Total income (7+12)",
                    "  Profit before tax/operating loss (11+12)",
                    "  Provision for tax",
                    "Net Income (14-15)"," "," "}';
		v_cClmVals1S := '{ "CURRENT MONTH (GHS)", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00"," "," "}';
		v_cClmVals2S := '{ "FINANCIAL YEAR TO DATE (CUMULATIVE - GHS)", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00"," "," " }';
		v_dClmValsS := '{ "% OF TOTAL INCOME", "0.00%", "0.00%", "0.00%", "0.00%", "0.00%", "0.00%", "0.00%", "0.00%", "0.00%", "0.00%", "0.00%","0.00%", "0.00%", "0.00%", "0.00%", "0.00%"," "," "}';
		v_as_at_date1 := TO_CHAR(TO_DATE(p_as_at_date , 'YYYY-MM-DD') , 'YYYY-MM-01');
		v_as_at_date2 := TO_CHAR(TO_DATE(p_as_at_date , 'YYYY-MM-DD') , 'YYYY-01-01');
		FOR a IN 1..31 LOOP
			IF a NOT IN (1 , 6 , 9 , 14 , 19 , 23 , 29) THEN
				v_amnt1 := accb.get_acnt_rptctgry_utrnssum0 (v_bClmValsMj[a] , v_bClmVals[a] , v_as_at_date1 , p_as_at_date , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
				v_amnt2 := accb.get_acnt_rptctgry_utrnssum0 (v_bClmValsMj[a] , v_bClmVals[a] , v_as_at_date2 , p_as_at_date , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
				v_cClmVals1[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
				v_cClmVals2[a] := TRIM(TO_CHAR(v_amnt2 , '999G999G999G999G999G999G990D00'));
			END IF;
		END LOOP;
		--SUMMARY RETURN
		FOR a IN 1..17 LOOP
			IF a != 1 THEN
				IF a = 2 THEN
					v_amnt1 := REPLACE(v_cClmVals1[2] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals1 [3], ',', '')::numeric + REPLACE(v_cClmVals1[4] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals1 [5], ',', '')::numeric;
					v_amnt2 := REPLACE(v_cClmVals2[2] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals2 [3], ',', '')::numeric + REPLACE(v_cClmVals2[4] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals2 [5], ',', '')::numeric;
					v_cClmVals1S[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
					v_cClmVals2S[a] := TRIM(TO_CHAR(v_amnt2 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 3 THEN
					v_amnt1 := REPLACE(v_cClmVals1[7] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals1 [8], ',', '')::numeric + REPLACE(v_cClmVals1[10] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals1 [11], ',', '')::numeric + REPLACE(v_cClmVals1[12] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals1 [13], ',', '')::numeric;
					v_amnt2 := REPLACE(v_cClmVals2[7] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals2 [8], ',', '')::numeric + REPLACE(v_cClmVals2[10] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals2 [11], ',', '')::numeric + REPLACE(v_cClmVals2[12] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals2 [13], ',', '')::numeric;
					v_cClmVals1S[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
					v_cClmVals2S[a] := TRIM(TO_CHAR(v_amnt2 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 4 THEN
					v_amnt1 := REPLACE(v_cClmVals1S[2] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals1S [3], ',', '')::numeric;
					v_amnt2 := REPLACE(v_cClmVals2S[2] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals2S [3], ',', '')::numeric;
					v_cClmVals1S[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
					v_cClmVals2S[a] := TRIM(TO_CHAR(v_amnt2 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 5 THEN
					v_amnt1 := REPLACE(v_cClmVals1[15] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals1 [16], ',', '')::numeric + REPLACE(v_cClmVals1[17] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals1 [18], ',', '')::numeric;
					v_amnt2 := REPLACE(v_cClmVals2[15] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals2 [16], ',', '')::numeric + REPLACE(v_cClmVals2[17] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals2 [18], ',', '')::numeric;
					v_cClmVals1S[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
					v_cClmVals2S[a] := TRIM(TO_CHAR(v_amnt2 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 6 THEN
					v_amnt1 := REPLACE(v_cClmVals1S[4] , ',' , '') :: NUMERIC - REPLACE(v_cClmVals1S [5], ',', '')::numeric;
					v_amnt2 := REPLACE(v_cClmVals2S[4] , ',' , '') :: NUMERIC - REPLACE(v_cClmVals2S [5], ',', '')::numeric;
					v_cClmVals1S[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
					v_cClmVals2S[a] := TRIM(TO_CHAR(v_amnt2 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 7 THEN
					v_amnt1 := REPLACE(v_cClmVals1[20] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals1 [21], ',', '')::numeric + REPLACE(v_cClmVals1[22] , ',' , '')::numeric;
					v_amnt2 := REPLACE(v_cClmVals2[20] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals2 [21], ',', '')::numeric + REPLACE(v_cClmVals2[22] , ',' , '')::numeric;
					v_cClmVals1S[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
					v_cClmVals2S[a] := TRIM(TO_CHAR(v_amnt2 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 8 THEN
					v_amnt1 := REPLACE(v_cClmVals1S[6] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals1S [7], ',', '')::numeric;
					v_amnt2 := REPLACE(v_cClmVals2S[6] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals2S [7], ',', '')::numeric;
					v_cClmVals1S[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
					v_cClmVals2S[a] := TRIM(TO_CHAR(v_amnt2 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 9 THEN
					v_amnt1 := REPLACE(v_cClmVals1[24] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals1 [25], ',', '')::numeric + REPLACE(v_cClmVals1[26] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals1 [27], ',', '')::numeric + REPLACE(v_cClmVals1[28] , ',' , '')::numeric;
					v_amnt2 := REPLACE(v_cClmVals2[24] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals2 [25], ',', '')::numeric + REPLACE(v_cClmVals2[26] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals2 [27], ',', '')::numeric + REPLACE(v_cClmVals2[28] , ',' , '')::numeric;
					v_cClmVals1S[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
					v_cClmVals2S[a] := TRIM(TO_CHAR(v_amnt2 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 10 THEN
					v_amnt1 := REPLACE(v_cClmVals1S[8] , ',' , '') :: NUMERIC - REPLACE(v_cClmVals1S [9], ',', '')::numeric;
					v_amnt2 := REPLACE(v_cClmVals2S[8] , ',' , '') :: NUMERIC - REPLACE(v_cClmVals2S [9], ',', '')::numeric;
					v_cClmVals1S[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
					v_cClmVals2S[a] := TRIM(TO_CHAR(v_amnt2 , '999G999G999G999G999G999G990D00'));
				ELSIF a IN (11 , 16) THEN
					v_amnt1 := accb.get_acnt_rptctgry_utrnssum1 (v_bClmValsS[a] , v_as_at_date1 , p_as_at_date , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
					v_amnt2 := accb.get_acnt_rptctgry_utrnssum1 (v_bClmValsS[a] , v_as_at_date2 , p_as_at_date , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
					v_cClmVals1S[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
					v_cClmVals2S[a] := TRIM(TO_CHAR(v_amnt2 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 12 THEN
					v_amnt1 := REPLACE(v_cClmVals1S[10] , ',' , '')::NUMERIC - REPLACE(v_cClmVals1S[11] , ',' , '')::numeric;
					v_amnt2 := REPLACE(v_cClmVals2S[10] , ',' , '')::NUMERIC - REPLACE(v_cClmVals2S[11] , ',' , '')::numeric;
					v_cClmVals1S[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
					v_cClmVals2S[a] := TRIM(TO_CHAR(v_amnt2 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 13 THEN
					v_amnt1 := REPLACE(v_cClmVals1[30] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals1 [31], ',', '')::numeric;
					v_amnt2 := REPLACE(v_cClmVals2[30] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals2 [31], ',', '')::numeric;
					v_cClmVals1S[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
					v_cClmVals2S[a] := TRIM(TO_CHAR(v_amnt2 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 14 THEN
					v_amnt1 := REPLACE(v_cClmVals1S[8] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals1S [13], ',', '')::numeric;
					v_amnt2 := REPLACE(v_cClmVals2S[8] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals2S [13], ',', '')::numeric;
					v_cClmVals1S[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
					v_cClmVals2S[a] := TRIM(TO_CHAR(v_amnt2 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 15 THEN
					v_amnt1 := REPLACE(v_cClmVals1S[12] , ',' , '')::NUMERIC + REPLACE(v_cClmVals1S[13] , ',' , '')::numeric;
					v_amnt2 := REPLACE(v_cClmVals2S[12] , ',' , '')::NUMERIC + REPLACE(v_cClmVals2S[13] , ',' , '')::numeric;
					v_cClmVals1S[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
					v_cClmVals2S[a] := TRIM(TO_CHAR(v_amnt2 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 17 THEN
					v_amnt1 := REPLACE(v_cClmVals1S[15] , ',' , '')::NUMERIC - REPLACE(v_cClmVals1S[16] , ',' , '')::numeric;
					v_amnt2 := REPLACE(v_cClmVals2S[15] , ',' , '')::NUMERIC - REPLACE(v_cClmVals2S[16] , ',' , '')::numeric;
					v_cClmVals1S[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
					v_cClmVals2S[a] := TRIM(TO_CHAR(v_amnt2 , '999G999G999G999G999G999G990D00'));
				END IF;
			END IF;
		END LOOP;
		vCntr := 0;
		FOR a IN 1..19 LOOP
			vCntr := vCntr + 1;
			IF a > 1 AND a <= 17 THEN
				IF REPLACE(v_cClmVals1S[14] , ',' , '')::numeric = 0 THEN
					v_cClmVals1S[14] := '1';
				END IF;
				v_amnt3 := (REPLACE(v_cClmVals1S[a] , ',' , '')::NUMERIC / REPLACE(v_cClmVals1S[14] , ',' , '')::numeric) * 100.00;
				v_dClmValsS[a] := TRIM(TO_CHAR(v_amnt3 , '999G999G999G999G999G999G990D00')) || '%';
			END IF;
			INSERT INTO rpt.rpt_gnrl_data_storage (rpt_run_id , rpt_run_date , gnrl_data1 , gnrl_data2 , gnrl_data3 , gnrl_data4 , gnrl_data5 , gnrl_data6 , gnrl_data7 , gnrl_data8 , gnrl_data9 , gnrl_data10 , gnrl_data11 , gnrl_data12 , gnrl_data13 , gnrl_data14 , gnrl_data15 , gnrl_data16 , gnrl_data17 , gnrl_data18 , gnrl_data19 , gnrl_data20 , gnrl_data21 , gnrl_data22 , gnrl_data23 , gnrl_data24 , gnrl_data25 , gnrl_data26 , gnrl_data27 , gnrl_data28 , gnrl_data29 , gnrl_data30)
				VALUES (p_rpt_run_id , vRecsDate , '' || vCntr , v_aClmValsS[a] , v_bClmValsS[a] , v_cClmVals1S[a] , v_cClmVals2S[a] , v_dClmValsS[a] , v_aClmFntBldsS[a] , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '');
		END LOOP;
		FOR a IN 1..31 LOOP
			vCntr := vCntr + 1;
			IF a NOT IN (1 , 6 , 9 , 14 , 19 , 23 , 29) THEN
				IF REPLACE(v_cClmVals1S[14] , ',' , '')::numeric = 0 THEN
					v_cClmVals1S[14] := '1';
				END IF;
				v_amnt3 := (REPLACE(v_cClmVals1[a] , ',' , '')::NUMERIC / REPLACE(v_cClmVals1S[14] , ',' , '')::numeric) * 100.00;
				v_dClmVals[a] := TRIM(TO_CHAR(v_amnt3 , '999G999G999G999G999G999G990D00')) || '%';
			END IF;
			INSERT INTO rpt.rpt_gnrl_data_storage (rpt_run_id , rpt_run_date , gnrl_data1 , gnrl_data2 , gnrl_data3 , gnrl_data4 , gnrl_data5 , gnrl_data6 , gnrl_data7 , gnrl_data8 , gnrl_data9 , gnrl_data10 , gnrl_data11 , gnrl_data12 , gnrl_data13 , gnrl_data14 , gnrl_data15 , gnrl_data16 , gnrl_data17 , gnrl_data18 , gnrl_data19 , gnrl_data20 , gnrl_data21 , gnrl_data22 , gnrl_data23 , gnrl_data24 , gnrl_data25 , gnrl_data26 , gnrl_data27 , gnrl_data28 , gnrl_data29 , gnrl_data30)
				VALUES (p_rpt_run_id , vRecsDate , '' || vCntr , v_aClmVals[a] , v_bClmVals[a] , v_cClmVals1[a] , v_cClmVals2[a] , v_dClmVals[a] , v_aClmFntBlds[a] , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '');
		END LOOP;
	ELSIF p_schdl_type = 'MF4' THEN
		v_aClmFntBlds := '{ "0", "0", "0", "1", "2", "0", "0", "0", "0", "0", "1", "0", "0", "0", "1", "1", "1", "2", "0", "2", "0", "0","0","0","0","1","2","0","1","1","1" }';
		v_aClmVals := '{ "1", "2", "3", "4", " ", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", " ", "17", " ", "18", "19", "20", "21", "22", "23"," ", "24","25","26","27" }';
		v_cClmVals := '{"0.00", "0.00", "0.00", "0.00"," ", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00",' || '" ", "0.00"," ", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00"," ", "0.00", "0.00", "0.00%", "0.00" }';
		v_bClmVals := '{ "Paid-up Capital",
                    "Disclosed Reserves",
                    "Permanent Preference Shares",
                    "Tier 1 Capital (1+2+3)",
                    "Less:",
                    "Goodwill/Intangibles",
                    "Losses not Provided For",
                    "Investments in Unconsolidated Subsidiaries",
                    "Investments in the capital of Other Banks & Fin Insts.",
                    "Connected Lending of Long Term Nature",
                    "Net Tier 1 Capital(4-5-6-7-8-9)",
                    "Undisclosed Reserves",
                    "Revaluation Reserves",
                    "Subordinated Term Debt (Limited to 50% of 4)",
                    "Tier 2 Capital (11+12+13) (Limited to 100% of 4)",
                    "ADJUSTED CAPITAL BASE (10+14)",
                    "TOTAL ASSETS",
                    "Less:",
                    "Cash on Hand (Cedis)",
                    "Claims on Government / BOG",
                    "  Treasury Securities (Bills and Bonds)",
                    "Goodwill / Intangibles",
                    "Investments in Unconsolidated Subsidiaries",
                    "Investments in the Capital of Other Banks & Fin Institutions",
                    "Claims on Other Banks and Fin inst",
                    "Adjusted Total Assets (16-17-18-19-20-21-22)",
                    "Add:",
                    "100% of 3yrs Average Annual Gross Income",
                    "ADJUSTED ASSET BASE (23+24)",
                    "Adjusted Capital Base as percentage of Adjusted Asset Base:(15/25)*100",
                    "CAPITAL SURPLUS/DEFICIT {15 - (10% of 25)}" }';
		v_as_at_date1 := TO_CHAR(TO_TIMESTAMP(p_as_at_date , 'YYYY-MM-DD') - INTERVAL '3 years' , 'YYYY-MM-DD');
		FOR a IN 1..31 LOOP
			IF a NOT IN (5 , 18 , 20 , 27) THEN
				IF a = 1 THEN
					v_amnt1 := accb.get_acnt_rpt_ctgry_sum11 ('Paid up capital' , p_as_at_date , 'net_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
					v_cClmVals[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 4 THEN
					v_amnt1 := REPLACE(v_cClmVals[1] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals [2], ',', '')::numeric + REPLACE(v_cClmVals[3] , ',' , '')::numeric;
					v_cClmVals[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 11 THEN
					v_amnt1 := REPLACE(v_cClmVals[4] , ',' , '') :: NUMERIC - REPLACE(v_cClmVals [6], ',', '')::numeric - REPLACE(v_cClmVals[7] , ',' , '') :: NUMERIC - REPLACE(v_cClmVals [8], ',', '')::numeric - REPLACE(v_cClmVals[9] , ',' , '') :: NUMERIC - REPLACE(v_cClmVals [10], ',', '')::numeric;
					v_cClmVals[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 15 THEN
					v_amnt1 := REPLACE(v_cClmVals[12] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals [13], ',', '')::numeric + REPLACE(v_cClmVals[14] , ',' , '')::numeric;
					v_cClmVals[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 16 THEN
					v_amnt1 := REPLACE(v_cClmVals[11] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals [15], ',', '')::numeric;
					v_cClmVals[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 17 THEN
					v_amnt1 := accb.get_acnt_type_sum00 (p_as_at_date , 'A' , 'net_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
					v_cClmVals[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 19 THEN
					v_amnt1 := accb.get_acnt_rpt_ctgry_sum11 ('Cash on hand' , p_as_at_date , 'net_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
					v_cClmVals[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 21 THEN
					v_amnt1 := accb.get_acnt_rpt_ctgry_sum11 ('Treasury bills/Notes' , p_as_at_date , 'net_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
					v_cClmVals[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 26 THEN
					v_amnt1 := REPLACE(v_cClmVals[17] , ',' , '') :: NUMERIC - REPLACE(v_cClmVals [19], ',', '')::numeric - REPLACE(v_cClmVals[21] , ',' , '') :: NUMERIC - REPLACE(v_cClmVals [22], ',', '')::numeric - REPLACE(v_cClmVals[23] , ',' , '') :: NUMERIC - REPLACE(v_cClmVals [24], ',', '')::numeric - REPLACE(v_cClmVals[25] , ',' , '')::numeric;
					v_cClmVals[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 28 THEN
					v_amnt1 := accb.get_acnt_typ_utrnssum1 ('R' , v_as_at_date1 , p_as_at_date , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val) / 3.00;
					v_cClmVals[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 29 THEN
					v_amnt1 := REPLACE(v_cClmVals[26] , ',' , '') :: NUMERIC + REPLACE(v_cClmVals [28], ',', '')::numeric;
					v_cClmVals[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
				ELSIF a = 30 THEN
					v_amnt1 := (REPLACE(v_cClmVals[16] , ',' , '') :: NUMERIC / REPLACE(v_cClmVals [29], ',', '')::numeric) * 100.00;
					v_cClmVals[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00')) || '%';
				ELSIF a = 31 THEN
					v_amnt1 := REPLACE(v_cClmVals[16] , ',' , '')::NUMERIC - (REPLACE(v_cClmVals[29] , ',' , '')::numeric) * 0.10;
					v_cClmVals[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
				ELSE
					v_amnt1 := accb.get_acnt_rpt_ctgry_sum11 (v_bClmVals[a] , p_as_at_date , 'net_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
					v_cClmVals[a] := TRIM(TO_CHAR(v_amnt1 , '999G999G999G999G999G999G990D00'));
				END IF;
			END IF;
		END LOOP;
		FOR a IN 1..31 LOOP
			vCntr := vCntr + 1;
			INSERT INTO rpt.rpt_gnrl_data_storage (rpt_run_id , rpt_run_date , gnrl_data1 , gnrl_data2 , gnrl_data3 , gnrl_data4 , gnrl_data5 , gnrl_data6 , gnrl_data7 , gnrl_data8 , gnrl_data9 , gnrl_data10 , gnrl_data11 , gnrl_data12 , gnrl_data13 , gnrl_data14 , gnrl_data15 , gnrl_data16 , gnrl_data17 , gnrl_data18 , gnrl_data19 , gnrl_data20 , gnrl_data21 , gnrl_data22 , gnrl_data23 , gnrl_data24 , gnrl_data25 , gnrl_data26 , gnrl_data27 , gnrl_data28 , gnrl_data29 , gnrl_data30)
				VALUES (p_rpt_run_id , vRecsDate , '' || a , v_aClmVals[a] , v_bClmVals[a] , v_cClmVals[a] , '', v_aClmFntBlds [a], '' , '', '' , '', '' , '', '' , '', '' , '', '' , '', '' , '', '' , '', '' , '', '' , '', '' , '', '' , '');
		END LOOP;
	ELSIF p_schdl_type = 'SCHEDULE-B' THEN
		v_aClmFntBlds := '{ "0", "0", "0", "0", "0" }';
		v_aClmVals := '{ "1", "2", "3", "4", "5"}';
		v_MajCtgry := 'Placement with banks/fin inst (Schedule B)';
		v_bClmVals := '{ "Class one Banks",
                    "Savings and Loans / Finance House Institutions",
                    "Rural/Community Banks",
                    "SEC Regulated Financial Institutions",
                    "Microfinance (Tier 2&3) Institutions" }';
		v_cClmVals := '{ "0.00", "0.00", "0.00", "0.00", "0.00"}';
		v_dClmVals := '{ "0.00", "0.00", "0.00", "0.00", "0.00"}';
		FOR a IN 1..5 LOOP
			v_amnt1 := accb.get_acnt_rpt_ctgry_sum00 (v_MajCtgry , v_bClmVals[a] , p_as_at_date , 'net_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
			v_cClmVals[a] := '' || v_amnt1;
		END LOOP;
		FOR a IN 1..5 LOOP
			vCntr := vCntr + 1;
			INSERT INTO rpt.rpt_gnrl_data_storage (rpt_run_id , rpt_run_date , gnrl_data1 , gnrl_data2 , gnrl_data3 , gnrl_data4 , gnrl_data5 , gnrl_data6 , gnrl_data7 , gnrl_data8 , gnrl_data9 , gnrl_data10 , gnrl_data11 , gnrl_data12 , gnrl_data13 , gnrl_data14 , gnrl_data15 , gnrl_data16 , gnrl_data17 , gnrl_data18 , gnrl_data19 , gnrl_data20 , gnrl_data21 , gnrl_data22 , gnrl_data23 , gnrl_data24 , gnrl_data25 , gnrl_data26 , gnrl_data27 , gnrl_data28 , gnrl_data29 , gnrl_data30)
				VALUES (p_rpt_run_id , vRecsDate , '' || a , v_aClmVals[a] , v_bClmVals[a] , v_cClmVals[a] , v_dClmVals[a] , v_aClmFntBlds[a] , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '');
		END LOOP;
	ELSIF p_schdl_type = 'SCHEDULE-C' THEN
		v_aClmFntBlds := '{ "0", "0", "0", "0", "0" }';
		v_aClmVals := '{ "1", "2", "3", "4", "5"}';
		v_MajCtgry := 'GoG /BOG Securities ( Schedule C)';
		v_bClmVals := '{ "GoG Securities (GHS) - 91 day",
                    "GoG Securities (GHS) - 182 day",
                    "GoG Securities (GHS) - 1year",
                    "GoG Securities (GHS) - 2 yrs",
                    "GoG Securities (GHS) - 3yrs" }';
		v_cClmVals := '{ "0.00", "0.00", "0.00", "0.00", "0.00"}';
		v_dClmVals := '{ "0.00", "0.00", "0.00", "0.00", "0.00"}';
		FOR a IN 1..5 LOOP
			v_amnt1 := accb.get_acnt_rpt_ctgry_sum00 (v_MajCtgry , v_bClmVals[a] , p_as_at_date , 'net_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
			v_cClmVals[a] := '' || v_amnt1;
		END LOOP;
		FOR a IN 1..5 LOOP
			vCntr := vCntr + 1;
			INSERT INTO rpt.rpt_gnrl_data_storage (rpt_run_id , rpt_run_date , gnrl_data1 , gnrl_data2 , gnrl_data3 , gnrl_data4 , gnrl_data5 , gnrl_data6 , gnrl_data7 , gnrl_data8 , gnrl_data9 , gnrl_data10 , gnrl_data11 , gnrl_data12 , gnrl_data13 , gnrl_data14 , gnrl_data15 , gnrl_data16 , gnrl_data17 , gnrl_data18 , gnrl_data19 , gnrl_data20 , gnrl_data21 , gnrl_data22 , gnrl_data23 , gnrl_data24 , gnrl_data25 , gnrl_data26 , gnrl_data27 , gnrl_data28 , gnrl_data29 , gnrl_data30)
				VALUES (p_rpt_run_id , vRecsDate , '' || a , v_aClmVals[a] , v_bClmVals[a] , v_cClmVals[a] , v_dClmVals[a] , v_aClmFntBlds[a] , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '');
		END LOOP;
	ELSIF p_schdl_type = 'SCHEDULE-E' THEN
		v_aClmFntBlds := '{ "0", "0", "0", "0", "0", "0", "0", "0" }';
		v_aClmVals := '{ "1", "2", "3", "4", "5","6","7","8"}';
		v_MajCtgry := 'Other Assets (Schedule E)';
		v_bClmVals := '{ "PREPAYMENTS",
                    "STOCK OF STATIONERY",
                    "WORK IN PROGRESS",
                    "DUE FROM REPS",
                    "ACCOUNT RECEIVABLE",
                    "OTHER ASSETS",
                    "LEASEHOLD PROPERTY",
                    "BUSINESS DEVELOPMENT" }';
		v_cClmVals := '{ "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00"}';
		v_dClmVals := '{ "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00"}';
		FOR a IN 1..8 LOOP
			v_amnt1 := accb.get_acnt_rpt_ctgry_sum00 (v_MajCtgry , v_bClmVals[a] , p_as_at_date , 'net_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
			v_cClmVals[a] := '' || v_amnt1;
			v_amnt2 := v_amnt2 + v_amnt1;
		END LOOP;
		FOR a IN 1..8 LOOP
			IF v_amnt2 = 0 THEN
				v_amnt2 := 1;
			END IF;
			v_amnt1 := ROUND((v_cClmVals[a]::numeric / v_amnt2) * 1.00 , 5);
			v_dClmVals[a] := '' || v_amnt1;
			vCntr := vCntr + 1;
			INSERT INTO rpt.rpt_gnrl_data_storage (rpt_run_id , rpt_run_date , gnrl_data1 , gnrl_data2 , gnrl_data3 , gnrl_data4 , gnrl_data5 , gnrl_data6 , gnrl_data7 , gnrl_data8 , gnrl_data9 , gnrl_data10 , gnrl_data11 , gnrl_data12 , gnrl_data13 , gnrl_data14 , gnrl_data15 , gnrl_data16 , gnrl_data17 , gnrl_data18 , gnrl_data19 , gnrl_data20 , gnrl_data21 , gnrl_data22 , gnrl_data23 , gnrl_data24 , gnrl_data25 , gnrl_data26 , gnrl_data27 , gnrl_data28 , gnrl_data29 , gnrl_data30)
				VALUES (p_rpt_run_id , vRecsDate , '' || a , v_aClmVals[a] , v_bClmVals[a] , v_cClmVals[a] , v_dClmVals[a] , v_aClmFntBlds[a] , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '');
		END LOOP;
	ELSIF p_schdl_type = 'SCHEDULE-F' THEN
		v_aClmFntBlds := '{ "0", "0", "0", "0" }';
		v_aClmVals := '{ "1", "2", "3", "4"}';
		v_MajCtgry := 'Reserves (Schedule F)';
		v_bClmVals := '{ "Statutory Reserve Fund",
                    "Income Surplus (retained earnings / accumulated loses)",
                    "Profit/Loss Year to date",
                    "Other Reserves" }';
		v_cClmVals := '{ "0.00", "0.00", "0.00", "0.00"}';
		v_dClmVals := '{ "0.00", "0.00", "0.00", "0.00"}';
		FOR a IN 1..4 LOOP
			v_amnt1 := accb.get_acnt_rpt_ctgry_sum00 (v_MajCtgry , v_bClmVals[a] , p_as_at_date , 'net_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
			v_cClmVals[a] := '' || v_amnt1;
		END LOOP;
		FOR a IN 1..4 LOOP
			vCntr := vCntr + 1;
			INSERT INTO rpt.rpt_gnrl_data_storage (rpt_run_id , rpt_run_date , gnrl_data1 , gnrl_data2 , gnrl_data3 , gnrl_data4 , gnrl_data5 , gnrl_data6 , gnrl_data7 , gnrl_data8 , gnrl_data9 , gnrl_data10 , gnrl_data11 , gnrl_data12 , gnrl_data13 , gnrl_data14 , gnrl_data15 , gnrl_data16 , gnrl_data17 , gnrl_data18 , gnrl_data19 , gnrl_data20 , gnrl_data21 , gnrl_data22 , gnrl_data23 , gnrl_data24 , gnrl_data25 , gnrl_data26 , gnrl_data27 , gnrl_data28 , gnrl_data29 , gnrl_data30)
				VALUES (p_rpt_run_id , vRecsDate , '' || a , v_aClmVals[a] , v_bClmVals[a] , v_cClmVals[a] , v_dClmVals[a] , v_aClmFntBlds[a] , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '');
		END LOOP;
	ELSIF p_schdl_type = 'SCHEDULE-H' THEN
		v_aClmFntBlds := '{ "0", "0", "0" }';
		v_aClmVals := '{ "1", "2", "3"}';
		v_MajCtgry := 'Deposits from the public ( Schedule H)';
		v_bClmVals := '{ "Savings",
                    "Fixed (Time) Deposit",
                    "Susu"}';
		v_cClmVals := '{ "0.00", "0.00", "0.00"}';
		v_dClmVals := '{ "0.00", "0.00", "0.00"}';
		FOR a IN 1..3 LOOP
			v_amnt1 := accb.get_acnt_rpt_ctgry_sum00 (v_MajCtgry , v_bClmVals[a] , p_as_at_date , 'net_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
			v_cClmVals[a] := '' || v_amnt1;
			IF a = 1 THEN
				--No of Accounts
				SELECT
					COUNT(a.account_id) INTO v_amnt2
				FROM
					mcf.mcf_accounts a
				WHERE
					account_type IN ('Savings')
					AND mcf.get_ac_prdt_name (account_type , product_type_id)
					NOT ILIKE ('%SUSU%');
				--No of Male Account Holders
				SELECT
					COUNT(DISTINCT a.cust_id) INTO v_amnt3
				FROM
					mcf.mcf_accounts a
				WHERE
					account_type IN ('Savings')
					AND mcf.get_ac_prdt_name (account_type , product_type_id)
					NOT ILIKE ('%SUSU%')
					AND mcf.get_cstmr_gender (a.cust_id)
					ILIKE 'Male';
				--No of FeMale Account Holders
				SELECT
					COUNT(DISTINCT a.cust_id) INTO v_amnt4
				FROM
					mcf.mcf_accounts a
				WHERE
					account_type IN ('Savings')
					AND mcf.get_ac_prdt_name (account_type , product_type_id)
					NOT ILIKE ('%SUSU%')
					AND mcf.get_cstmr_gender (a.cust_id)
					ILIKE 'Female';
			ELSIF a = 2 THEN
				--No of Accounts
				SELECT
					COUNT(a.account_id) INTO v_amnt2
				FROM
					mcf.mcf_accounts a
				WHERE
					account_type IN ('Investment')
					AND mcf.get_ac_prdt_name (account_type , product_type_id)
					ILIKE ('%FIXED%');
				--No of Male Account Holders
				SELECT
					COUNT(DISTINCT a.cust_id) INTO v_amnt3
				FROM
					mcf.mcf_accounts a
				WHERE
					account_type IN ('Investment')
					AND mcf.get_ac_prdt_name (account_type , product_type_id)
					ILIKE ('%FIXED%')
					AND mcf.get_cstmr_gender (a.cust_id)
					ILIKE 'Male';
				--No of FeMale Account Holders
				SELECT
					COUNT(DISTINCT a.cust_id) INTO v_amnt4
				FROM
					mcf.mcf_accounts a
				WHERE
					account_type IN ('Investment')
					AND mcf.get_ac_prdt_name (account_type , product_type_id)
					ILIKE ('%FIXED%')
					AND mcf.get_cstmr_gender (a.cust_id)
					ILIKE 'Female';
			ELSE
				--No of Accounts
				SELECT
					COUNT(a.account_id) INTO v_amnt2
				FROM
					mcf.mcf_accounts a
				WHERE
					account_type IN ('Savings' , 'Susu')
					AND mcf.get_ac_prdt_name (account_type , product_type_id)
					ILIKE ('%SUSU%');
				--No of Male Account Holders
				SELECT
					COUNT(DISTINCT a.cust_id) INTO v_amnt3
				FROM
					mcf.mcf_accounts a
				WHERE
					account_type IN ('Savings' , 'Susu')
					AND mcf.get_ac_prdt_name (account_type , product_type_id)
					ILIKE ('%SUSU%')
					AND mcf.get_cstmr_gender (a.cust_id)
					ILIKE 'Male';
				--No of FeMale Account Holders
				SELECT
					COUNT(DISTINCT a.cust_id) INTO v_amnt4
				FROM
					mcf.mcf_accounts a
				WHERE
					account_type IN ('Savings' , 'Susu')
					AND mcf.get_ac_prdt_name (account_type , product_type_id)
					ILIKE ('%SUSU%')
					AND mcf.get_cstmr_gender (a.cust_id)
					ILIKE 'Female';
			END IF;
			vCntr := vCntr + 1;
			INSERT INTO rpt.rpt_gnrl_data_storage (rpt_run_id , rpt_run_date , gnrl_data1 , gnrl_data2 , gnrl_data3 , gnrl_data4 , gnrl_data5 , gnrl_data6 , gnrl_data7 , gnrl_data8 , gnrl_data9 , gnrl_data10 , gnrl_data11 , gnrl_data12 , gnrl_data13 , gnrl_data14 , gnrl_data15 , gnrl_data16 , gnrl_data17 , gnrl_data18 , gnrl_data19 , gnrl_data20 , gnrl_data21 , gnrl_data22 , gnrl_data23 , gnrl_data24 , gnrl_data25 , gnrl_data26 , gnrl_data27 , gnrl_data28 , gnrl_data29 , gnrl_data30)
				VALUES (p_rpt_run_id , vRecsDate , '' || a , v_aClmVals[a] , v_bClmVals[a] , v_cClmVals[a] , v_dClmVals[a] , v_aClmFntBlds[a] , '' || v_amnt2 , '' || v_amnt3 , '' || v_amnt4 , '', '' , '', '' , '', '' , '', '' , '', '' , '', '' , '', '' , '' , '' , '' , '' , '' , '' , '');
		END LOOP;
	ELSIF p_schdl_type = 'SCHEDULE-I' THEN
		v_aClmFntBlds := '{ "0", "0", "0", "0", "0", "0", "0", "0","0" }';
		v_aClmVals := '{ "1", "2", "3", "4", "5","6","7","8","9"}';
		v_MajCtgry := 'Other Liabilities ( Schedule I)';
		v_bClmVals := '{ "Account Payable",
                    "Risk Management Fund (Main)",
                    "Risk Management Fund (CDWE)",
                    "NHIS CDWE",
                    "Accrued Expenses",
                    "Due to Directors",
                    "50-year lease Payable to YKMA",
                    "CDWE Loan Account",
                    "Deposit for shares and equity" }';
		v_cClmVals := '{ "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00"}';
		v_dClmVals := '{ "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00", "0.00"}';
		FOR a IN 1..9 LOOP
			v_amnt1 := accb.get_acnt_rpt_ctgry_sum00 (v_MajCtgry , v_bClmVals[a] , p_as_at_date , 'net_amount' , p_sgmnt1_val , p_sgmnt2_val , p_sgmnt3_val , p_sgmnt4_val , p_sgmnt5_val , p_sgmnt6_val , p_sgmnt7_val , p_sgmnt8_val , p_sgmnt9_val , p_sgmnt10_val);
			v_cClmVals[a] := '' || v_amnt1;
			v_amnt2 := v_amnt2 + v_amnt1;
		END LOOP;
		FOR a IN 1..9 LOOP
			IF v_amnt2 = 0 THEN
				v_amnt2 := 1;
			END IF;
			v_amnt1 := ROUND((v_cClmVals[a]::numeric / v_amnt2) * 1.00 , 5);
			v_dClmVals[a] := '' || v_amnt1;
			vCntr := vCntr + 1;
			INSERT INTO rpt.rpt_gnrl_data_storage (rpt_run_id , rpt_run_date , gnrl_data1 , gnrl_data2 , gnrl_data3 , gnrl_data4 , gnrl_data5 , gnrl_data6 , gnrl_data7 , gnrl_data8 , gnrl_data9 , gnrl_data10 , gnrl_data11 , gnrl_data12 , gnrl_data13 , gnrl_data14 , gnrl_data15 , gnrl_data16 , gnrl_data17 , gnrl_data18 , gnrl_data19 , gnrl_data20 , gnrl_data21 , gnrl_data22 , gnrl_data23 , gnrl_data24 , gnrl_data25 , gnrl_data26 , gnrl_data27 , gnrl_data28 , gnrl_data29 , gnrl_data30)
				VALUES (p_rpt_run_id , vRecsDate , '' || a , v_aClmVals[a] , v_bClmVals[a] , v_cClmVals[a] , v_dClmVals[a] , v_aClmFntBlds[a] , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '' , '');
		END LOOP;
	END IF;
	v_msgs := v_msgs || CHR(10) || 'Successfully Populated BOG Report into General Data Table!';
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

