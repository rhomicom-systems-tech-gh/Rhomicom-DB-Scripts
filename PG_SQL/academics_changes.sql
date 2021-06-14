CREATE OR REPLACE FUNCTION aca.auto_compute_ltc_flds (p_assess_hdrid bigint , p_who_rn bigint)
	RETURNS text
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE PARALLEL UNSAFE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid text := 'Last-To-Compute Fields Computed Successfully!';
	v_Tmp_Val text := '';
	nwSQL text := '';
	v_msgs text := '';
	v_dataCols text[] := '{"data_col1", "data_col2", "data_col3", "data_col4",
        "data_col5", "data_col6", "data_col7", "data_col8", "data_col9", "data_col10",
        "data_col11", "data_col12", "data_col13", "data_col14", "data_col15", "data_col16",
        "data_col17", "data_col18", "data_col19", "data_col20", "data_col21", "data_col22",
        "data_col23", "data_col24", "data_col25", "data_col26", "data_col27", "data_col28",
        "data_col29", "data_col30", "data_col31", "data_col32", "data_col33", "data_col34",
        "data_col35", "data_col36", "data_col37", "data_col38", "data_col39", "data_col40",
        "data_col41", "data_col42", "data_col43", "data_col44", "data_col45", "data_col46",
        "data_col47", "data_col48", "data_col49", "data_col50"}';
	rd1 RECORD;
	rd2 RECORD;
	rd3 RECORD;
	rd4 RECORD;
	rd5 RECORD;
BEGIN
	--Loop and Pick and Relevant Values form Header Table
	--Loop through all rows in the sheet including the one with negative sttngs ID
	--Loop though all the columns defined in the linked Assessment Type
	--Get SQL Formula and Execute
	--Update Corresponding Data Column with Result
	FOR rd1 IN
	SELECT
		a.class_id
		, a.assessment_type_id
		, a.course_id
		, a.subject_id
		, a.tutor_person_id
		, a.academic_period_id
		, a.org_id
		, b.dflt_grade_scale_id
		, b.assmnt_type
		, b.assmnt_level
		, b.lnkd_assmnt_typ_id
		, a.assess_sheet_hdr_id
		, a.assessed_person_id
	FROM
		aca.aca_assess_sheet_hdr a
		, aca.aca_assessment_types b
	WHERE
		a.assessment_type_id = b.assmnt_typ_id
		AND a.org_id = b.org_id
		AND a.assess_sheet_hdr_id = p_assess_hdrid LOOP
			FOR rd3 IN
			SELECT
				d.column_no
				, d.is_formula_column
				, d.column_formular
			FROM
				aca.aca_assessment_columns d
			WHERE
				d.assmnt_typ_id = rd1.assessment_type_id
				AND d.section_located IN ('02-Detail')
				AND d.data_type = 'LastToCompute'
				AND d.is_formula_column = '1'
			ORDER BY
				d.column_name LOOP
					FOR rd2 IN
					SELECT
						c.ass_col_val_id
						, c.acdmc_sttngs_id
						, c.course_id
						, c.subject_id
					FROM
						aca.aca_assmnt_col_vals c
					WHERE
						c.assess_sheet_hdr_id = rd1.assess_sheet_hdr_id
						AND c.acdmc_sttngs_id > 0
					ORDER BY
						acdmc_sttngs_id ASC LOOP
							v_Tmp_Val := aca.exct_col_valsql (rd3.column_formular , rd1.assess_sheet_hdr_id , rd2.acdmc_sttngs_id , rd3.column_no , rd1.dflt_grade_scale_id , rd2.course_id , rd2.subject_id , rd1.class_id , rd1.academic_period_id);
							nwSQL := 'UPDATE aca.aca_assmnt_col_vals ' || ' SET ' || v_dataCols[rd3.column_no] || ' = ''' || v_Tmp_Val || ''', last_update_by=' || p_who_rn || ', last_update_date = to_char(now(),''YYYY-MM-DD HH24:MI:SS'') where ass_col_val_id=' || rd2.ass_col_val_id;
							EXECUTE nwSQL;
						END LOOP;
				END LOOP;
			FOR rd5 IN
			SELECT
				c.ass_col_val_id
				, c.acdmc_sttngs_id
				, c.course_id
				, c.subject_id
			FROM
				aca.aca_assmnt_col_vals c
			WHERE
				c.assess_sheet_hdr_id = rd1.assess_sheet_hdr_id
				AND c.acdmc_sttngs_id <= 0 LOOP
					FOR rd4 IN
					SELECT
						d.column_no
						, d.is_formula_column
						, d.column_formular
					FROM
						aca.aca_assessment_columns d
					WHERE
						d.assmnt_typ_id = rd1.assessment_type_id
						AND d.section_located IN ('01-Header' , '03-Footer')
						AND d.data_type = 'LastToCompute'
						AND d.is_formula_column = '1'
					ORDER BY
						d.section_located
						, d.column_name LOOP
							v_Tmp_Val := aca.exct_col_valsql (rd4.column_formular , rd1.assess_sheet_hdr_id , rd5.acdmc_sttngs_id , rd4.column_no , rd1.dflt_grade_scale_id , rd5.course_id , rd5.subject_id , rd1.class_id , rd1.academic_period_id);
							nwSQL := 'UPDATE aca.aca_assmnt_col_vals ' || ' SET ' || v_dataCols[rd4.column_no] || ' = ''' || v_Tmp_Val || ''', last_update_by=' || p_who_rn || ', last_update_date = to_char(now(),''YYYY-MM-DD HH24:MI:SS'') where ass_col_val_id=' || rd5.ass_col_val_id;

							/*RAISE EXCEPTION 'MIN-MAX ERROR:%', nwSQL
							 USING HINT = nwSQL;*/
							EXECUTE nwSQL;
						END LOOP;
				END LOOP;
		END LOOP;
	RETURN COALESCE('SUCCESS:' || bid , '');

	/* EXCEPTION
	 WHEN OTHERS THEN
	 v_msgs := v_msgs || CHR(10) || '' || SQLSTATE || CHR(10) || SQLERRM;
	 RETURN v_msgs; */
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.compute_all_assess_shts (p_period_id bigint , p_class_id integer , p_assess_typ_id integer , p_shd_close_sht character varying , p_create_hdrs character varying , p_who_rn bigint , p_msgid bigint)
	RETURNS text
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE PARALLEL UNSAFE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_dataCols text[] := '{"data_col1", "data_col2", "data_col3", "data_col4",
        "data_col5", "data_col6", "data_col7", "data_col8", "data_col9", "data_col10",
        "data_col11", "data_col12", "data_col13", "data_col14", "data_col15", "data_col16",
        "data_col17", "data_col18", "data_col19", "data_col20", "data_col21", "data_col22",
        "data_col23", "data_col24", "data_col25", "data_col26", "data_col27", "data_col28",
        "data_col29", "data_col30", "data_col31", "data_col32", "data_col33", "data_col34",
        "data_col35", "data_col36", "data_col37", "data_col38", "data_col39", "data_col40",
        "data_col41", "data_col42", "data_col43", "data_col44", "data_col45", "data_col46",
        "data_col47", "data_col48", "data_col49", "data_col50"}';
	rd1 RECORD;
	rd2 RECORD;
	rd3 RECORD;
	rd4 RECORD;
	v_PrsnID bigint;
	v_Sht_Nm character varying(200) := '';
	v_PValID integer := - 1;
	v_PVal character varying(300) := '';
	v_assess_sht_lvl character varying(300) := '';
	v_OrgID integer;
	v_Result text := '';
	bid text := 'Assessment Sheet Computed Successfully!';
	v_msgs text := CHR(10) || 'Assessment Sheet Computations About to Start...';
	v_cntr integer := 0;
	v_updtMsg bigint := 0;
	v_SheetType character varying(200) := '';
BEGIN
	v_SheetType := gst.getGnrlRecNm ('aca.aca_assessment_types' , 'assmnt_typ_id' , 'assmnt_type' , p_assess_typ_id);
	IF (v_SheetType <> 'Assessment Sheet Per Group') THEN
		RAISE EXCEPTION 'WRONG ASSESSMENT TYPE:%' , v_SheetType
			USING HINT = 'WRONG ASSESSMENT TYPE:' || v_SheetType;
		END IF;

		/*v_PValID := COALESCE(gst.getEnbldPssblValID('Default Assessment Sheet Level',
		 gst.getenbldlovid('All Other Performance Setups')), -1);
		 v_PVal := COALESCE(gst.get_pssbl_val_desc(v_PValID), '');*/
		v_assess_sht_lvl := COALESCE(aca.get_assesstypLevel (p_assess_typ_id) , '');
		IF UPPER(v_assess_sht_lvl) = UPPER('Subject/Target') AND UPPER(p_create_hdrs) = UPPER('Yes') THEN
			FOR rd2 IN SELECT DISTINCT
				a.class_id
				, a.acdmc_period_id
				, a.course_id
				, b.subject_id
				, aca.get_subjectnm (b.subject_id) subjectnm
				, aca.get_coursenm (a.course_id) coursenm
				, aca.get_period_nm (a.acdmc_period_id) period_nm
				, aca.get_class_nm (a.class_id) class_nm
				, c.org_id
				, d.group_fcltr_pos_name
				, d.group_rep_pos_name
				, d.sbjct_fcltr_pos_name
				, d.lnkd_div_id
			FROM
				aca.aca_prsns_acdmc_sttngs a
				, aca.aca_prsns_ac_sttngs_sbjcts b
				, aca.aca_assessment_periods c
				, aca.aca_classes d
			WHERE
				a.acdmc_sttngs_id = b.acdmc_sttngs_id
				AND (a.acdmc_period_id = p_period_id
					OR p_period_id <= 0)
				AND c.assmnt_period_id = a.acdmc_period_id
				AND b.subject_id > 0
				AND a.class_id = d.class_id
				AND (a.class_id = p_class_id
					OR p_class_id <= 0)
				AND (
					SELECT
						COUNT(y.assess_sheet_hdr_id)
					FROM
						aca.aca_assess_sheet_hdr y
					WHERE
						y.class_id = a.class_id
						AND y.course_id = a.course_id
						AND y.subject_id = b.subject_id
						AND y.academic_period_id = a.acdmc_period_id
						AND y.assessment_type_id = p_assess_typ_id) <= 0
				AND (
					SELECT
						COUNT(z.assess_sheet_hdr_id)
					FROM
						aca.aca_assess_sheet_hdr z
					WHERE
						z.class_id = a.class_id
						AND z.course_id = a.course_id
						AND z.subject_id <= 0
						AND z.academic_period_id = a.acdmc_period_id
						AND z.assessment_type_id = p_assess_typ_id) <= 0 LOOP
					v_Sht_Nm := rd2.subjectnm || '-' || rd2.class_nm || '-' || rd2.period_nm;
					SELECT
						COUNT(y.assess_sheet_hdr_id) INTO v_cntr
					FROM
						aca.aca_assess_sheet_hdr y
					WHERE
						UPPER(y.assess_sheet_name) = UPPER(v_Sht_Nm);
					v_PrsnID := aca.get_pos_hldr_prs_id (rd2.acdmc_period_id , rd2.lnkd_div_id , - 1 , rd2.subject_id , rd2.sbjct_fcltr_pos_name);
					IF COALESCE(v_PrsnID , - 1) <= 0 THEN
						v_PrsnID := sec.get_usr_prsn_id (p_who_rn);
					END IF;
					IF (COALESCE(v_cntr , 0) <= 0) THEN
						v_Result := aca.createAssessShtHdr (rd2.org_id , v_Sht_Nm , v_Sht_Nm , rd2.class_id , p_assess_typ_id , rd2.course_id , rd2.subject_id , v_PrsnID , rd2.acdmc_period_id , 'Open for Editing' , - 1 , p_who_rn);
					END IF;
				END LOOP;
		ELSIF UPPER(v_assess_sht_lvl) = UPPER('Course/Objective')
				AND UPPER(p_create_hdrs) = UPPER('Yes') THEN
				FOR rd2 IN SELECT DISTINCT
					a.class_id
					, a.acdmc_period_id
					, a.course_id
					, aca.get_coursenm (a.course_id) coursenm
					, aca.get_period_nm (a.acdmc_period_id) period_nm
					, aca.get_class_nm (a.class_id) class_nm
					, c.org_id
					, d.group_fcltr_pos_name
					, d.group_rep_pos_name
					, d.sbjct_fcltr_pos_name
					, d.lnkd_div_id
				FROM
					aca.aca_prsns_acdmc_sttngs a
					, aca.aca_assessment_periods c
					, aca.aca_classes d
				WHERE (a.acdmc_period_id = p_period_id
					OR p_period_id <= 0)
				AND c.assmnt_period_id = a.acdmc_period_id
				AND a.class_id = d.class_id
				AND (a.class_id = p_class_id
					OR p_class_id <= 0)
				AND (
					SELECT
						COUNT(y.assess_sheet_hdr_id)
					FROM
						aca.aca_assess_sheet_hdr y
					WHERE
						y.class_id = a.class_id
						AND y.course_id = a.course_id
						AND y.academic_period_id = a.acdmc_period_id
						AND y.assessment_type_id = p_assess_typ_id) <= 0 LOOP
					v_Sht_Nm := rd2.coursenm || '-' || rd2.class_nm || '-' || rd2.period_nm;
					SELECT
						COUNT(y.assess_sheet_hdr_id) INTO v_cntr
					FROM
						aca.aca_assess_sheet_hdr y
					WHERE
						UPPER(y.assess_sheet_name) = UPPER(v_Sht_Nm);
					v_PrsnID := aca.get_pos_hldr_prs_id (rd2.acdmc_period_id , rd2.lnkd_div_id , - 1 , - 1 , rd2.group_fcltr_pos_name);
					IF COALESCE(v_PrsnID , - 1) <= 0 THEN
						v_PrsnID := sec.get_usr_prsn_id (p_who_rn);
					END IF;
					IF (COALESCE(v_cntr , 0) <= 0) THEN
						v_Result := aca.createAssessShtHdr (rd2.org_id , v_Sht_Nm , v_Sht_Nm , rd2.class_id , p_assess_typ_id , rd2.course_id , - 1 , v_PrsnID , rd2.acdmc_period_id , 'Open for Editing' , - 1 , p_who_rn);
					END IF;
				END LOOP;
		END IF;
		--Loop and Pick all Relevant Values form Header Table
		--Loop through all rows in the sheet including the one with negative sttngs ID
		--Loop though all the columns defined in the linked Assessment Type
		--Get SQL Formula and Execute
		--Update Corresponding Data Column with Result
		FOR rd1 IN
		SELECT
			a.class_id
			, a.assessment_type_id
			, a.course_id
			, a.subject_id
			, a.tutor_person_id
			, a.academic_period_id
			, a.org_id
			, b.dflt_grade_scale_id
			, b.assmnt_type
			, b.assmnt_level
			, b.lnkd_assmnt_typ_id
			, a.assess_sheet_hdr_id
			, a.assessed_person_id
		FROM
			aca.aca_assess_sheet_hdr a
			, aca.aca_assessment_types b
		WHERE
			a.assessment_type_id = b.assmnt_typ_id
			AND a.org_id = b.org_id
			AND (a.class_id = p_class_id
				OR p_class_id <= 0)
			AND (a.academic_period_id = p_period_id
				OR p_period_id <= 0)
			AND a.assessment_type_id = p_assess_typ_id LOOP
				v_Result := aca.compute_one_assess_sht (rd1.assess_sheet_hdr_id , p_who_rn);
			END LOOP;
		RETURN COALESCE('SUCCESS:' || bid , '');
		FOR rd3 IN
		SELECT
			a.class_id
			, a.assessment_type_id
			, a.course_id
			, a.subject_id
			, a.tutor_person_id
			, a.academic_period_id
			, a.org_id
			, b.dflt_grade_scale_id
			, b.assmnt_type
			, b.assmnt_level
			, b.lnkd_assmnt_typ_id
			, a.assess_sheet_hdr_id
			, a.assessed_person_id
		FROM
			aca.aca_assess_sheet_hdr a
			, aca.aca_assessment_types b
		WHERE
			a.assessment_type_id = b.assmnt_typ_id
			AND a.org_id = b.org_id
			AND (a.class_id = p_class_id
				OR p_class_id <= 0)
			AND (a.academic_period_id = p_period_id
				OR p_period_id <= 0)
			AND a.assessment_type_id = p_assess_typ_id LOOP
				v_Result := aca.auto_compute_ltc_flds (rd3.assess_sheet_hdr_id , p_who_rn);
				IF (v_Result NOT LIKE 'SUCCESS:%') THEN
					v_msgs := v_msgs || CHR(10) || v_Result;
					RAISE EXCEPTION
						USING ERRCODE = 'RHERR' , MESSAGE = v_Result , HINT = v_Result;
					END IF;
					IF UPPER(p_shd_close_sht) = 'YES' THEN
						UPDATE
							aca.aca_assess_sheet_hdr
						SET
							assess_sheet_status = 'Closed'
						WHERE
							assess_sheet_hdr_id = rd3.assess_sheet_hdr_id;
					ELSIF UPPER(p_shd_close_sht) = 'NO' THEN
						UPDATE
							aca.aca_assess_sheet_hdr
						SET
							assess_sheet_status = 'Open for Editing'
						WHERE
							assess_sheet_hdr_id = rd3.assess_sheet_hdr_id;
					END IF;
				END LOOP;

				/*
				 EXCEPTION
				 WHEN OTHERS THEN
				 v_msgs := v_msgs || CHR(10) || '' || SQLSTATE || CHR(10) || SQLERRM;
				 v_updtMsg := rpt.updaterptlogmsg (p_msgid , v_msgs , TO_CHAR(NOW() , 'YYYY-MM-DD HH24:MI:SS') , p_who_rn);
				 --v_msgs := rpt.getLogMsg(p_msgid);
				 RETURN v_msgs; */
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.compute_all_rpt_cards (p_period_id bigint , p_class_id integer , p_assess_typ_id integer , p_shd_close_sht character varying , p_create_hdrs character varying , p_who_rn bigint , p_msgid bigint)
	RETURNS text
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE PARALLEL UNSAFE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_dataCols text[] := '{"data_col1", "data_col2", "data_col3", "data_col4",
        "data_col5", "data_col6", "data_col7", "data_col8", "data_col9", "data_col10",
        "data_col11", "data_col12", "data_col13", "data_col14", "data_col15", "data_col16",
        "data_col17", "data_col18", "data_col19", "data_col20", "data_col21", "data_col22",
        "data_col23", "data_col24", "data_col25", "data_col26", "data_col27", "data_col28",
        "data_col29", "data_col30", "data_col31", "data_col32", "data_col33", "data_col34",
        "data_col35", "data_col36", "data_col37", "data_col38", "data_col39", "data_col40",
        "data_col41", "data_col42", "data_col43", "data_col44", "data_col45", "data_col46",
        "data_col47", "data_col48", "data_col49", "data_col50"}';
	rd1 RECORD;
	rd2 RECORD;
	rd3 RECORD;
	v_PrsnID bigint;
	v_OrgID integer;
	v_Sht_Nm character varying(200) := '';
	v_PValID integer := - 1;
	v_PVal character varying(300) := '';
	v_assess_sht_lvl character varying(300) := '';
	v_Result text := '';
	bid text := 'Report Card Computed Successfully!';
	v_msgs text := CHR(10) || 'Report Card Computations About to Start...';
	v_cntr integer := 0;
	v_updtMsg bigint := 0;
	v_SheetType character varying(200) := '';
BEGIN
	v_SheetType := gst.getGnrlRecNm ('aca.aca_assessment_types' , 'assmnt_typ_id' , 'assmnt_type' , p_assess_typ_id);
	IF (v_SheetType <> 'Summary Report Per Person') THEN
		RAISE EXCEPTION 'WRONG ASSESSMENT TYPE:%' , v_SheetType
			USING HINT = 'WRONG ASSESSMENT TYPE:' || v_SheetType;
		END IF;
		v_PrsnID := sec.get_usr_prsn_id (p_who_rn);

		/*v_PValID := COALESCE(gst.getEnbldPssblValID('Default Assessment Sheet Level',
		 gst.getenbldlovid('All Other Performance Setups')), -1);
		 v_PVal := COALESCE(gst.get_pssbl_val_desc(v_PValID), '');
		 v_assess_sht_lvl := v_PVal;*/
		IF UPPER(p_create_hdrs) = 'YES' THEN
			FOR rd2 IN SELECT DISTINCT
				a.person_id
				, prs.get_prsn_loc_id (a.person_id) prsn_loc_id
				, a.class_id
				, a.acdmc_period_id
				, aca.get_period_nm (a.acdmc_period_id) period_nm
				, aca.get_class_nm (a.class_id) class_nm
				, c.org_id
				, d.group_fcltr_pos_name
				, d.group_rep_pos_name
				, d.sbjct_fcltr_pos_name
				, d.lnkd_div_id
			FROM
				aca.aca_prsns_acdmc_sttngs a
				, aca.aca_assessment_periods c
				, aca.aca_classes d
			WHERE (a.acdmc_period_id = p_period_id
				OR p_period_id <= 0)
				AND c.assmnt_period_id = a.acdmc_period_id
				AND a.class_id = d.class_id
				AND (a.class_id = p_class_id
					OR p_class_id <= 0)
				AND (
					SELECT
						COUNT(y.assess_sheet_hdr_id)
					FROM
						aca.aca_assess_sheet_hdr y
					WHERE
						y.class_id = a.class_id
						AND y.assessed_person_id = a.person_id
						AND y.academic_period_id = a.acdmc_period_id
						AND y.assessment_type_id = p_assess_typ_id) <= 0 LOOP
					v_Sht_Nm := rd2.prsn_loc_id || '-' || rd2.class_nm || '-' || rd2.period_nm;
					SELECT
						COUNT(y.assess_sheet_hdr_id) INTO v_cntr
					FROM
						aca.aca_assess_sheet_hdr y
					WHERE
						UPPER(y.assess_sheet_name) = UPPER(v_Sht_Nm);
					v_PrsnID := aca.get_pos_hldr_prs_id (rd2.acdmc_period_id , rd2.lnkd_div_id , - 1 , - 1 , rd2.group_fcltr_pos_name);
					IF COALESCE(v_PrsnID , - 1) <= 0 THEN
						v_PrsnID := sec.get_usr_prsn_id (p_who_rn);
					END IF;
					IF (COALESCE(v_cntr , 0) <= 0) THEN
						v_Result := aca.createAssessShtHdr (rd2.org_id , v_Sht_Nm , v_Sht_Nm , rd2.class_id , p_assess_typ_id , - 1 , - 1 , v_PrsnID , rd2.acdmc_period_id , 'Open for Editing' , rd2.person_id , p_who_rn);
					END IF;
				END LOOP;
		END IF;
		--Loop and Pick all Relevant Values form Header Table
		--Loop through all rows in the sheet including the one with negative sttngs ID
		--Loop though all the columns defined in the linked Assessment Type
		--Get SQL Formula and Execute
		--Update Corresponding Data Column with Result
		FOR rd1 IN
		SELECT
			a.class_id
			, a.assessment_type_id
			, a.course_id
			, a.subject_id
			, a.tutor_person_id
			, a.academic_period_id
			, a.org_id
			, b.dflt_grade_scale_id
			, b.assmnt_type
			, b.assmnt_level
			, b.lnkd_assmnt_typ_id
			, a.assess_sheet_hdr_id
			, a.assessed_person_id
		FROM
			aca.aca_assess_sheet_hdr a
			, aca.aca_assessment_types b
		WHERE
			a.assessment_type_id = b.assmnt_typ_id
			AND a.org_id = b.org_id
			AND (a.class_id = p_class_id
				OR p_class_id <= 0)
			AND (a.academic_period_id = p_period_id
				OR p_period_id <= 0)
			AND a.assessment_type_id = p_assess_typ_id LOOP
				v_Result := aca.compute_one_assess_sht (rd1.assess_sheet_hdr_id , p_who_rn);
			END LOOP;
		FOR rd3 IN
		SELECT
			a.class_id
			, a.assessment_type_id
			, a.course_id
			, a.subject_id
			, a.tutor_person_id
			, a.academic_period_id
			, a.org_id
			, b.dflt_grade_scale_id
			, b.assmnt_type
			, b.assmnt_level
			, b.lnkd_assmnt_typ_id
			, a.assess_sheet_hdr_id
			, a.assessed_person_id
		FROM
			aca.aca_assess_sheet_hdr a
			, aca.aca_assessment_types b
		WHERE
			a.assessment_type_id = b.assmnt_typ_id
			AND a.org_id = b.org_id
			AND (a.class_id = p_class_id
				OR p_class_id <= 0)
			AND (a.academic_period_id = p_period_id
				OR p_period_id <= 0)
			AND a.assessment_type_id = p_assess_typ_id LOOP
				v_Result := aca.auto_compute_ltc_flds (rd3.assess_sheet_hdr_id , p_who_rn);
				IF (v_Result NOT LIKE 'SUCCESS:%') THEN
					v_msgs := v_msgs || CHR(10) || v_Result;
					RAISE EXCEPTION
						USING ERRCODE = 'RHERR' , MESSAGE = v_Result , HINT = v_Result;
					END IF;
					IF UPPER(p_shd_close_sht) = 'YES' THEN
						UPDATE
							aca.aca_assess_sheet_hdr
						SET
							assess_sheet_status = 'Closed'
						WHERE
							assess_sheet_hdr_id = rd3.assess_sheet_hdr_id;
					ELSIF UPPER(p_shd_close_sht) = 'NO' THEN
						UPDATE
							aca.aca_assess_sheet_hdr
						SET
							assess_sheet_status = 'Open for Editing'
						WHERE
							assess_sheet_hdr_id = rd3.assess_sheet_hdr_id;
					END IF;
				END LOOP;
				RETURN COALESCE('SUCCESS:' || bid , '');

				/* EXCEPTION
				 WHEN OTHERS THEN
				 v_msgs := v_msgs || CHR(10) || '' || SQLSTATE || CHR(10) || SQLERRM;
				 v_updtMsg := rpt.updaterptlogmsg (p_msgid , v_msgs , TO_CHAR(NOW() , 'YYYY-MM-DD HH24:MI:SS') , p_who_rn);
				 RETURN v_msgs; */
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.compute_one_assess_sht (p_assess_hdrid bigint , p_who_rn bigint)
	RETURNS text
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE PARALLEL UNSAFE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid text := 'Assessment Sheet Computed Successfully!';
	v_Tmp_Val text := '';
	nwSQL text := '';
	v_msgs text := '';
	v_dataCols text[] := '{"data_col1", "data_col2", "data_col3", "data_col4",
        "data_col5", "data_col6", "data_col7", "data_col8", "data_col9", "data_col10",
        "data_col11", "data_col12", "data_col13", "data_col14", "data_col15", "data_col16",
        "data_col17", "data_col18", "data_col19", "data_col20", "data_col21", "data_col22",
        "data_col23", "data_col24", "data_col25", "data_col26", "data_col27", "data_col28",
        "data_col29", "data_col30", "data_col31", "data_col32", "data_col33", "data_col34",
        "data_col35", "data_col36", "data_col37", "data_col38", "data_col39", "data_col40",
        "data_col41", "data_col42", "data_col43", "data_col44", "data_col45", "data_col46",
        "data_col47", "data_col48", "data_col49", "data_col50"}';
	rd1 RECORD;
	rd2 RECORD;
	rd3 RECORD;
	rd4 RECORD;
	rd5 RECORD;
BEGIN
	--Loop and Pick and Relevant Values form Header Table
	--Loop through all rows in the sheet including the one with negative sttngs ID
	--Loop though all the columns defined in the linked Assessment Type
	--Get SQL Formula and Execute
	--Update Corresponding Data Column with Result
	FOR rd1 IN
	SELECT
		a.class_id
		, a.assessment_type_id
		, a.course_id
		, a.subject_id
		, a.tutor_person_id
		, a.academic_period_id
		, a.org_id
		, b.dflt_grade_scale_id
		, b.assmnt_type
		, b.assmnt_level
		, b.lnkd_assmnt_typ_id
		, a.assess_sheet_hdr_id
		, a.assessed_person_id
	FROM
		aca.aca_assess_sheet_hdr a
		, aca.aca_assessment_types b
	WHERE
		a.assessment_type_id = b.assmnt_typ_id
		AND a.org_id = b.org_id
		AND a.assess_sheet_hdr_id = p_assess_hdrid LOOP
			FOR rd3 IN
			SELECT
				d.column_no
				, d.is_formula_column
				, d.column_formular
			FROM
				aca.aca_assessment_columns d
			WHERE
				d.assmnt_typ_id = rd1.assessment_type_id
				AND d.section_located IN ('02-Detail')
				AND d.data_type NOT IN ('LastToCompute')
				AND d.is_formula_column = '1'
			ORDER BY
				d.column_name LOOP
					FOR rd2 IN
					SELECT
						c.ass_col_val_id
						, c.acdmc_sttngs_id
						, c.course_id
						, c.subject_id
					FROM
						aca.aca_assmnt_col_vals c
					WHERE
						c.assess_sheet_hdr_id = rd1.assess_sheet_hdr_id
						AND c.acdmc_sttngs_id > 0
					ORDER BY
						acdmc_sttngs_id ASC LOOP
							v_Tmp_Val := aca.exct_col_valsql (rd3.column_formular , rd1.assess_sheet_hdr_id , rd2.acdmc_sttngs_id , rd3.column_no , rd1.dflt_grade_scale_id , (
									CASE WHEN rd1.course_id > 0 THEN
										rd1.course_id
									ELSE
										rd2.course_id
									END) , (
									CASE WHEN rd1.subject_id > 0 THEN
										rd1.subject_id
									ELSE
										rd2.subject_id
									END) , rd1.class_id , rd1.academic_period_id);
							nwSQL := 'UPDATE aca.aca_assmnt_col_vals ' || ' SET ' || v_dataCols[rd3.column_no] || ' = ''' || v_Tmp_Val || ''', last_update_by=' || p_who_rn || ', last_update_date = to_char(now(),''YYYY-MM-DD HH24:MI:SS'') where ass_col_val_id=' || rd2.ass_col_val_id;
							EXECUTE nwSQL;
						END LOOP;
				END LOOP;
			FOR rd5 IN
			SELECT
				c.ass_col_val_id
				, c.acdmc_sttngs_id
				, c.course_id
				, c.subject_id
			FROM
				aca.aca_assmnt_col_vals c
			WHERE
				c.assess_sheet_hdr_id = rd1.assess_sheet_hdr_id
				AND c.acdmc_sttngs_id <= 0 LOOP
					FOR rd4 IN
					SELECT
						d.column_no
						, d.is_formula_column
						, d.column_formular
					FROM
						aca.aca_assessment_columns d
					WHERE
						d.assmnt_typ_id = rd1.assessment_type_id
						AND d.section_located IN ('01-Header' , '03-Footer')
						AND d.data_type NOT IN ('LastToCompute')
						AND d.is_formula_column = '1'
					ORDER BY
						d.section_located
						, d.column_name LOOP
							v_Tmp_Val := aca.exct_col_valsql (rd4.column_formular , rd1.assess_sheet_hdr_id , rd5.acdmc_sttngs_id , rd4.column_no , rd1.dflt_grade_scale_id , (
									CASE WHEN rd1.course_id > 0 THEN
										rd1.course_id
									ELSE
										rd5.course_id
									END) , (
									CASE WHEN rd1.subject_id > 0 THEN
										rd1.subject_id
									ELSE
										rd5.subject_id
									END) , rd1.class_id , rd1.academic_period_id);
							nwSQL := 'UPDATE aca.aca_assmnt_col_vals ' || ' SET ' || v_dataCols[rd4.column_no] || ' = ''' || v_Tmp_Val || ''', last_update_by=' || p_who_rn || ', last_update_date = to_char(now(),''YYYY-MM-DD HH24:MI:SS'') where ass_col_val_id=' || rd5.ass_col_val_id;

							/*RAISE EXCEPTION 'MIN-MAX ERROR:%', nwSQL
							 USING HINT = nwSQL;*/
							EXECUTE nwSQL;
						END LOOP;
				END LOOP;
		END LOOP;
	RETURN COALESCE('SUCCESS:' || bid , '');

	/* EXCEPTION
	 WHEN OTHERS THEN
	 v_msgs := v_msgs || CHR(10) || '' || SQLSTATE || CHR(10) || SQLERRM;
	 RETURN v_msgs; */
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_sbjct_weight (p_acdmc_sttngs_id bigint , p_course_id integer , p_subject_id integer)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE PARALLEL UNSAFE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid numeric := 0.00;
BEGIN
	SELECT
		c.weight_or_credit_hrs INTO bid
	FROM
		aca.aca_prsns_ac_sttngs_sbjcts a
		, aca.aca_prsns_acdmc_sttngs b
		, aca.aca_crsrs_n_thr_sbjcts c
		, aca.aca_assessment_periods d
	WHERE
		a.acdmc_sttngs_id = b.acdmc_sttngs_id
		AND b.class_id = c.class_id
		AND b.course_id = c.course_id
		AND a.subject_id = c.subject_id
		AND b.acdmc_period_id = d.assmnt_period_id
		AND c.course_id = p_course_id
		AND c.subject_id = p_subject_id
		AND a.acdmc_sttngs_id = p_acdmc_sttngs_id;

	/* RAISE EXCEPTION 'MIN-MAX ERROR:%' , (p_course_id || '-' || p_subject_id || '-' || p_acdmc_sttngs_id)
	 USING HINT = (p_course_id || '-' || p_subject_id || '-' || p_acdmc_sttngs_id); */
	RETURN COALESCE(bid , 0.00);
END;
$BODY$;

CREATE OR REPLACE FUNCTION public.isnumeric (text)
	RETURNS boolean
	AS $$
DECLARE
	x numeric;
BEGIN
	x = $1::numeric;
	RETURN TRUE;
EXCEPTION
	WHEN OTHERS THEN
		RETURN FALSE;
END;

$$ STRICT
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION public.isnumeric (text)
	RETURNS boolean
	AS $$
DECLARE
	x numeric;
BEGIN
	x = $1::numeric;
	RETURN TRUE;
EXCEPTION
	WHEN OTHERS THEN
		RETURN FALSE;
END;

$$ STRICT
LANGUAGE plpgsql
IMMUTABLE;

SELECT DISTINCT
	data_col15
FROM
	aca.aca_assmnt_col_vals
WHERE
	public.isnumeric (data_col15) = FALSE
UNION
SELECT DISTINCT
	data_col16
FROM
	aca.aca_assmnt_col_vals
WHERE
	public.isnumeric (data_col16) = FALSE;

CREATE OR REPLACE FUNCTION pay.get_itm_st_id (p_itm_st_nm character varying , p_org_id integer)
	RETURNS integer
	LANGUAGE 'sql'
	COST 100 VOLATILE PARALLEL UNSAFE
	AS $BODY$
	SELECT
		hdr_id
	FROM
		pay.pay_itm_sets_hdr
	WHERE
		itm_set_name ILIKE '%' || p_itm_st_nm || '%'
		AND org_id = p_org_id;

$BODY$;

CREATE OR REPLACE FUNCTION aca.isprsnelgbltorgstr (p_prsnid bigint , p_allwd_prsn_typs character varying , p_fees_prcnt numeric , p_ttl_pymnts_itm_st_nm character varying , p_ttl_bills_itm_st_nm character varying , p_ttl_bals_itm_st_nm character varying)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE PARALLEL UNSAFE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res character varying(4000) := 'YES:You can Register!';
	v_ttl_pymnts_itm_st_id bigint := - 1;
	v_ttl_bills_itm_st_id bigint := - 1;
	v_ttl_bals_itm_st_id bigint := - 1;
	v_ttl_pymnts_itm_st_sum numeric := 0;
	v_ttl_bills_itm_st_sum numeric := 0;
	v_ttl_bals_itm_st_sum numeric := 0;
	v_ltst_bill_dte character varying(21) := '';
	v_org_id integer := - 1;
BEGIN
	v_org_id := prs.get_prsn_org_id (p_prsnid);

	/*Work with latest figures from each itm set*/
	v_ttl_pymnts_itm_st_id := pay.get_itm_st_id (p_ttl_pymnts_itm_st_nm , v_org_id);
	--org.get_payitm_id (p_ttl_pymnts_itm_st_nm);
	v_ttl_bills_itm_st_id := pay.get_itm_st_id (p_ttl_bills_itm_st_nm , v_org_id);
	--org.get_payitm_id (p_ttl_bills_itm_st_nm);
	v_ttl_bals_itm_st_id := pay.get_itm_st_id (p_ttl_bals_itm_st_nm , v_org_id);
	--org.get_payitm_id (p_ttl_bals_itm_st_nm);
	IF COALESCE(v_ttl_bills_itm_st_id , - 1) > 0 THEN
		SELECT
			SUM(COALESCE(pay.get_ttl_paiditem_val_b4 (p_prsnid , item_id , TO_CHAR(NOW() , 'YYYY-MM-DD')) , 0))
			, MAX(pay.get_ltst_paiditem_dte (p_prsnid , item_id)) INTO v_ttl_bills_itm_st_sum
			, v_ltst_bill_dte
		FROM
			pay.get_AllItmStDet (v_ttl_bills_itm_st_id::integer);
	END IF;
	IF COALESCE(v_ltst_bill_dte , '') = '' THEN
		v_ltst_bill_dte := TO_CHAR(NOW() , 'YYYY-MM-DD');
	END IF;
	IF COALESCE(v_ttl_pymnts_itm_st_id , - 1) > 0 THEN
		SELECT
			SUM(COALESCE(pay.get_ttl_paiditem_val_afta (p_prsnid , item_id , v_ltst_bill_dte) , 0)) INTO v_ttl_pymnts_itm_st_sum
		FROM
			pay.get_AllItmStDet (v_ttl_pymnts_itm_st_id::integer);
	END IF;
	IF COALESCE(v_ttl_bals_itm_st_id , - 1) > 0 THEN
		SELECT
			SUM(COALESCE(pay.get_ltst_blsitm_bals (p_prsnid , item_id , TO_CHAR(NOW() , 'YYYY-MM-DD')) , 0)) INTO v_ttl_bals_itm_st_sum
		FROM
			pay.get_AllItmStDet (v_ttl_bals_itm_st_id::integer);
	END IF;
	IF COALESCE(v_ttl_bills_itm_st_sum , 0) = 0 THEN
		v_ttl_bills_itm_st_sum := 1;
	END IF;
	IF NOT (p_allwd_prsn_typs ILIKE '%;' || pasn.get_prsn_type (p_prsnid) || ';%') THEN
		v_res := 'NO:Sorry you cannot Register until you are defined in the ff Person Types! - ' || BTRIM(p_allwd_prsn_typs , ';');
	END IF;
	IF ((ROUND((v_ttl_pymnts_itm_st_sum / v_ttl_bills_itm_st_sum) , 2) < (p_fees_prcnt / 100)) AND v_ttl_bals_itm_st_sum != 0) THEN
		v_res := 'NO:Sorry you cannot Register until you have paid ' || p_fees_prcnt || '% of your Total Bills/Charges!<br/>Total Bill:' || v_ttl_bills_itm_st_sum || '<br/>Total Payments Made:' || v_ttl_pymnts_itm_st_sum || '<br/>Outstanding Balance: ' || v_ttl_bals_itm_st_sum;
	END IF;
	RETURN COALESCE(v_res , 'YES:You can Register!');
EXCEPTION
	WHEN OTHERS THEN
		v_res := 'NO:' || SQLERRM;
	RETURN v_res;
END;

$BODY$;

CREATE OR REPLACE FUNCTION aca.get_pos_hldr_prs_id (p_period_id bigint , p_group_id integer , p_course_id integer , p_subject_id integer , p_position_code character varying)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE PARALLEL UNSAFE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid bigint := - 1;
	v_period_id bigint := - 1;
BEGIN
	v_period_id := p_period_id;
	IF (COALESCE(v_period_id , - 1) <= 0) THEN
		SELECT
			assmnt_period_id INTO v_period_id
		FROM
			aca.aca_assessment_periods a
		WHERE
			TO_CHAR(NOW() , 'YYYY-MM-DD') BETWEEN a.period_start_date
			AND a.period_end_date
		ORDER BY
			period_start_date DESC
		LIMIT 1 OFFSET 0;
	END IF;
	IF (COALESCE(v_period_id , - 1) <= 0) THEN
		SELECT
			assmnt_period_id INTO v_period_id
		FROM
			aca.aca_assessment_periods
		ORDER BY
			period_start_date DESC
		LIMIT 1 OFFSET 0;
	END IF;
	SELECT
		MAX(b.person_id) INTO bid
	FROM
		aca.aca_assessment_periods a
		, pasn.prsn_positions b
	WHERE (a.assmnt_period_id = v_period_id
		OR (v_period_id <= 0
			AND TO_CHAR(NOW() , 'YYYY-MM-DD') BETWEEN a.period_start_date
			AND a.period_end_date))
		AND a.period_end_date >= b.valid_start_date
		AND (a.period_start_date <= b.valid_end_date
			OR COALESCE(b.valid_end_date , '') = '')
			AND b.position_id = org.get_org_pos_id (p_position_code , a.org_id)
			AND b.div_id = p_group_id
			AND (b.div_sub_cat_id1 = p_course_id
				OR p_course_id <= 0)
			AND (b.div_sub_cat_id2 = p_subject_id
				OR (COALESCE(b.div_sub_cat_id2 , - 1) <= 0
					AND p_subject_id <= 0));
	RETURN COALESCE(bid , - 1);
END;
$BODY$;

CREATE OR REPLACE FUNCTION aca.get_pos_hldr_prs_nm (p_period_id bigint , p_group_id integer , p_course_id integer , p_subject_id integer , p_position_code character varying)
	RETURNS text
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE PARALLEL UNSAFE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid bigint := - 1;
	v_Res text := '';
	v_period_id bigint := - 1;
BEGIN
	v_period_id := p_period_id;
	IF (COALESCE(v_period_id , - 1) <= 0) THEN
		SELECT
			assmnt_period_id INTO v_period_id
		FROM
			aca.aca_assessment_periods a
		WHERE
			TO_CHAR(NOW() , 'YYYY-MM-DD') BETWEEN a.period_start_date
			AND a.period_end_date
		ORDER BY
			period_start_date DESC
		LIMIT 1 OFFSET 0;
	END IF;
	IF (COALESCE(v_period_id , - 1) <= 0) THEN
		SELECT
			assmnt_period_id INTO v_period_id
		FROM
			aca.aca_assessment_periods
		ORDER BY
			period_start_date DESC
		LIMIT 1 OFFSET 0;
	END IF;
	SELECT
		MAX(b.person_id) INTO bid
	FROM
		aca.aca_assessment_periods a
		, pasn.prsn_positions b
	WHERE (a.assmnt_period_id = v_period_id
		OR (v_period_id <= 0
			AND TO_CHAR(NOW() , 'YYYY-MM-DD') BETWEEN a.period_start_date
			AND a.period_end_date))
		AND a.period_end_date >= b.valid_start_date
		AND (a.period_start_date <= b.valid_end_date
			OR COALESCE(b.valid_end_date , '') = '')
			AND b.position_id = org.get_org_pos_id (p_position_code , a.org_id)
			AND b.div_id = p_group_id
			AND (b.div_sub_cat_id1 = p_course_id
				OR p_course_id <= 0)
			AND (b.div_sub_cat_id2 = p_subject_id
				OR (COALESCE(b.div_sub_cat_id2 , - 1) <= 0
					AND p_subject_id <= 0));
	v_Res := prs.get_prsn_name (COALESCE(bid , - 1)) || ' (' || prs.get_prsn_loc_id (COALESCE(bid , - 1)) || ')';
	RETURN COALESCE(v_Res , '');
END;
$BODY$;

