-- FUNCTION: accb.invoice_payment_frm_btch(boolean, bigint, bigint, bigint, bigint, boolean, character varying, integer, character varying, character varying, numeric, bigint, character varying, character varying, character varying, character varying, bigint, character varying, integer, bigint)
-- DROP FUNCTION accb.invoice_payment_frm_btch(boolean, bigint, bigint, bigint, bigint, boolean, character varying, integer, character varying, character varying, numeric, bigint, character varying, character varying, character varying, character varying, bigint, character varying, integer, bigint);
CREATE OR REPLACE FUNCTION accb.invoice_payment_frm_btch (p_is_a_rvrsal boolean , p_orgnlpymntid bigint , p_newpymntbatchid bigint , p_invoice_id bigint , p_mspyid bigint , p_createprepay boolean , p_doc_types character varying , p_pay_mthd_id integer , p_pay_remarks character varying , p_pay_date character varying , p_pay_amt_rcvd numeric , p_appld_prpay_docid bigint , p_cheque_card_name character varying , p_cheque_card_num character varying , p_cheque_card_code character varying , p_cheque_card_expdate character varying , p_who_rn bigint , p_run_date character varying , orgidno integer , p_msgid bigint)
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
	errCntr integer := 0;
	batchCntr integer := 0;
	v_reslt_1 character varying(200) := '';
	dateStr character varying(21) := '';
	v_dte character varying(21) := '';
	v_pay_date timestamp;
	v_usrTrnsCode character varying(100) := '';
	v_drCrdt1 character varying(100) := '';
	v_drCrdt2 character varying(100) := '';
	v_PrsnID bigint := - 1;
	v_PrsnBrnchID integer := - 1;
	v_dfltCashAccntID integer := - 1;
	v_dfltCashAccntID1 integer := - 1;
	v_dfltPyblAccntID integer := - 1;
	v_dfltRcvblAccntID integer := - 1;
	v_docStatus character varying(200) := '';
	p_orgidno integer := - 1;
	v_prcsngPay boolean := FALSE;
	v_dsablPayments boolean := FALSE;
	v_createPrepay boolean := FALSE;
	v_prepayDocType character varying(200) := '';
	v_pymntNthdName character varying(200) := '';
	v_pay_remarks character varying(300) := '';
	v_actvtyDocName character varying(200) := '';
	v_prepayAvlblAmnt numeric := 0;
	v_amntToPay numeric := 0;
	v_amntBeingPaid numeric := 0;
	v_changeBals numeric := 0;
	v_spplrID bigint := - 1;
	v_spplrSiteID bigint := - 1;
	v_srcDocID bigint := - 1;
	v_srcDocType character varying(200) := '';
	v_currID integer := - 1;
	v_funcCurrID integer := - 1;
	v_IncrsDcrs1 character varying(1) := '';
	v_AccntID1 integer := - 1;
	v_IncrsDcrs2 character varying(1) := '';
	v_AccntID2 integer := - 1;
	v_pymntBatchName character varying(200) := '';
	v_docClsftn character varying(200) := '';
	v_docNum character varying(200) := '';
	v_gnrtdTrnsNo1 character varying(200) := '';
	v_glBatchName character varying(200) := '';
	v_glBatchID bigint := - 1;
	v_orgnlGLBatchID bigint := - 1;
	v_pymntBatchID bigint := - 1;
	v_orgnlPymntBatchID bigint := - 1;
	v_glBatchPrfx character varying(100) := '';
	v_glBatchSrc character varying(200) := '';
	v_pymntID bigint := - 1;
	v_accntCurrID integer := - 1;
	v_funcCurrRate numeric := 1;
	v_accntCurrRate numeric := 1;
	v_funcCurrAmnt numeric := 0;
	v_accntCurrAmnt numeric := 0;
	v_prepayDocID bigint := - 1;
	v_otherinfo character varying(200) := '';
	v_AllwDues character varying(1) := '0';
	v_msPyID bigint := - 1;
	v_invoice_id bigint := - 1;
	v_invoice_type character varying(200) := '';
BEGIN
	/*
	 1. Determine amount to pay, change/balance, available amnt on prepay doc id
	 2. Once valid, create payment batch and lines
	 3. Create Journal Batch and Entries
	 4. Update various src, dest tables with amount paid
	 */
	v_msPyID := p_msPyID;
	v_prepayDocID := p_appld_prpay_docid;
	v_pymntBatchID := p_NewPymntBatchID;
	v_pay_date := TO_TIMESTAMP(p_pay_date , 'DD-Mon-YYYY HH24:MI:SS');
	v_createPrepay := p_createPrepay;
	v_pay_remarks := p_pay_remarks;
	errCntr := 0;
	batchCntr := 0;
	dateStr := TO_CHAR(NOW() , 'YYYY-MM-DD HH24:MI:SS');
	p_orgidno := orgidno;
	v_pymntNthdName := accb.get_pymnt_mthd_name (p_pay_mthd_id);
	v_srcDocID := p_invoice_id;
	v_srcDocType := '';
	v_usrTrnsCode := gst.getGnrlRecNm ('sec.sec_users' , 'user_id' , 'code_for_trns_nums' , p_who_rn);
	IF (CHAR_LENGTH(v_usrTrnsCode) <= 0) THEN
		v_usrTrnsCode := 'XX';
	END IF;
	v_dte := TO_CHAR(NOW() , 'YYMMDD');
	v_pymntBatchName := '';
	v_docClsftn := '';
	v_docNum := '';
	v_orgnlPymntBatchID := - 1;
	v_glBatchPrfx := '';
	v_glBatchSrc := '';
	IF p_doc_types = 'Supplier Payments' THEN
		FOR rd2 IN
		SELECT
			pybls_invc_hdr_id
			, pybls_invc_number
			, pybls_invc_type
			, comments_desc
			, src_doc_hdr_id
			, supplier_id
			, supplier_site_id
			, approval_status
			, next_aproval_action
			, org_id
			, invoice_amount
			, src_doc_type
			, pymny_method_id
			, amnt_paid
			, invc_curr_id
			, invc_amnt_appld_elswhr
			, debt_gl_batch_id
			, balancing_accnt_id
			, advc_pay_ifo_doc_id
			, advc_pay_ifo_doc_typ
			, next_part_payment
			, firts_cheque_num
		FROM
			accb.accb_pybls_invc_hdr
		WHERE
			pybls_invc_hdr_id = v_srcDocID LOOP
				p_orgidno := rd2.org_id;
				v_docStatus := rd2.approval_status;
				v_amntToPay := rd2.invoice_amount - rd2.amnt_paid;
				v_spplrID := rd2.supplier_id;
				v_srcDocType := rd2.pybls_invc_type;
				v_spplrSiteID := rd2.supplier_site_id;
				v_currID := rd2.invc_curr_id;
			END LOOP;
	ELSE
		FOR rd2 IN
		SELECT
			rcvbls_invc_hdr_id
			, rcvbls_invc_date
			, rcvbls_invc_number
			, rcvbls_invc_type
			, comments_desc
			, src_doc_hdr_id
			, customer_id
			, customer_site_id
			, approval_status
			, next_aproval_action
			, org_id
			, invoice_amount
			, src_doc_type
			, pymny_method_id
			, amnt_paid
			, invc_curr_id
			, invc_amnt_appld_elswhr
			, balancing_accnt_id
			, debt_gl_batch_id
			, advc_pay_ifo_doc_id
			, advc_pay_ifo_doc_typ
		FROM
			accb.accb_rcvbls_invc_hdr
		WHERE
			rcvbls_invc_hdr_id = v_srcDocID LOOP
				p_orgidno := rd2.org_id;
				v_docStatus := rd2.approval_status;
				v_amntToPay := rd2.invoice_amount - rd2.amnt_paid;
				v_spplrID := rd2.customer_id;
				v_srcDocType := rd2.rcvbls_invc_type;
				v_spplrSiteID := rd2.customer_site_id;
				v_currID := rd2.invc_curr_id;
				v_invoice_id := rd2.src_doc_hdr_id;
				v_invoice_type := rd2.src_doc_type;
			END LOOP;
	END IF;
	IF (p_is_a_rvrsal = FALSE) THEN
		v_funcCurrID := COALESCE(org.get_Orgfunc_Crncy_id (p_orgidno) , - 1);
		IF v_amntToPay >= p_pay_amt_rcvd THEN
			v_amntBeingPaid := p_pay_amt_rcvd;
			v_changeBals := v_amntBeingPaid - p_pay_amt_rcvd;
		ELSIF v_amntToPay > 0 THEN
			v_amntBeingPaid := v_amntToPay;
			v_changeBals := v_amntBeingPaid - p_pay_amt_rcvd;
		ELSE
			v_amntBeingPaid := p_pay_amt_rcvd;
			v_changeBals := 0;
		END IF;
	ELSE
		FOR rd3 IN
		SELECT
			a.pymnt_id
			, a.pymnt_mthd_id
			, accb.get_pymnt_mthd_name (a.pymnt_mthd_id)
			, a.amount_paid
			, a.change_or_balance
			, a.pymnt_remark
			, a.src_doc_typ
			, a.src_doc_id
			, accb.get_src_doc_num (a.src_doc_id , a.src_doc_typ)
			, TO_CHAR(TO_TIMESTAMP(a.pymnt_date , 'YYYY-MM-DD HH24:MI:SS') , 'DD-Mon-YYYY HH24:MI:SS')
			, a.incrs_dcrs1
			, a.rcvbl_lblty_accnt_id
			, accb.get_accnt_num (a.rcvbl_lblty_accnt_id) || '.' || accb.get_accnt_name (a.rcvbl_lblty_accnt_id) rcvbl_lblty_accnt
			, a.incrs_dcrs2
			, a.cash_or_suspns_acnt_id
			, accb.get_accnt_num (a.cash_or_suspns_acnt_id) || '.' || accb.get_accnt_name (a.cash_or_suspns_acnt_id) cash_or_suspns_acnt
			, a.gl_batch_id
			, accb.get_gl_batch_name (a.gl_batch_id)
			, a.orgnl_pymnt_id
			, a.pymnt_vldty_status
			, a.entrd_curr_id
			, gst.get_pssbl_val (a.entrd_curr_id)
			, a.func_curr_id
			, gst.get_pssbl_val (a.func_curr_id)
			, a.accnt_curr_id
			, gst.get_pssbl_val (a.accnt_curr_id)
			, a.func_curr_rate
			, a.accnt_curr_rate
			, a.func_curr_amount
			, a.accnt_curr_amnt
			, a.pymnt_batch_id
			, a.is_removed
			, a.amount_given
			, a.prepay_doc_id
			, accb.get_src_doc_num (a.prepay_doc_id , a.prepay_doc_type)
			, a.pay_means_other_info
			, a.cheque_card_name
			, a.expiry_date
			, a.cheque_card_num
			, a.sign_code
			, a.bkgrd_actvty_status
			, a.bkgrd_actvty_gen_doc_name
			, b.cust_spplr_id
		FROM
			accb.accb_payments a
			, accb.accb_payments_batches b
		WHERE ((a.pymnt_batch_id = b.pymnt_batch_id)
			AND (a.pymnt_id = p_orgnlPymntID))
			LOOP
				v_funcCurrID := rd3.func_curr_id;
				v_amntBeingPaid := - 1 * rd3.amount_paid;
				v_changeBals := - 1 * rd3.change_or_balance;
				v_amntToPay := - 1 * rd3.amount_paid;
				v_currID := rd3.entrd_curr_id;
				v_IncrsDcrs1 := rd3.incrs_dcrs1;
				v_AccntID1 := rd3.rcvbl_lblty_accnt_id;
				v_drCrdt1 := accb.dbt_or_crdt_accnt (v_AccntID1 , v_IncrsDcrs1);
				v_IncrsDcrs2 := rd3.incrs_dcrs2;
				v_AccntID2 := rd3.cash_or_suspns_acnt_id;
				v_actvtyDocName := rd3.bkgrd_actvty_gen_doc_name;
				v_drCrdt2 := accb.dbt_or_crdt_accnt (v_AccntID2 , v_IncrsDcrs2);
				v_accntCurrID := rd3.accnt_curr_id;
				v_funcCurrRate := rd3.func_curr_rate;
				v_accntCurrRate := rd3.accnt_curr_rate;
				v_funcCurrAmnt := - 1 * rd3.func_curr_amount;
				v_accntCurrAmnt := - 1 * rd3.accnt_curr_amnt;
			END LOOP;
	END IF;
	v_PrsnID := sec.get_usr_prsn_id (p_who_rn);
	v_PrsnBrnchID := pasn.get_prsn_siteid (v_PrsnID);
	v_dfltCashAccntID1 := accb.get_DfltCashAcnt (v_PrsnID , p_orgidno);
	v_dfltCashAccntID := org.get_accnt_id_brnch_eqv (v_PrsnBrnchID , v_dfltCashAccntID1);
	v_dfltPyblAccntID := org.get_accnt_id_brnch_eqv (v_PrsnBrnchID , scm.get_dflt_pybl_accid (p_orgidno));
	v_dfltRcvblAccntID := org.get_accnt_id_brnch_eqv (v_PrsnBrnchID , scm.get_dflt_rcvbl_accid (p_orgidno));
	v_reslt_1 := accb.isTransPrmttd (p_orgidno , v_dfltCashAccntID , p_pay_date , 200);
	IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
		msgs := msgs || CHR(10) || v_reslt_1;
		msgs := REPLACE(msgs , CHR(10) , '<br/>');
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR' , MESSAGE = msgs , HINT = msgs;
		END IF;
		IF (v_docStatus = 'Cancelled') THEN
			msgs := msgs || CHR(10) || 'Cannot Process Payments on Cancelled Documents!';
			RAISE EXCEPTION
				USING ERRCODE = 'RHERR' , MESSAGE = msgs , HINT = msgs;
			END IF;
			v_prcsngPay := TRUE;
			IF (p_pay_mthd_id <= 0) THEN
				msgs := msgs || CHR(10) || 'Please indicate the Payment Method!';
				RAISE EXCEPTION
					USING ERRCODE = 'RHERR' , MESSAGE = msgs , HINT = msgs;
				END IF;
				IF (CHAR_LENGTH(p_pay_remarks) <= 0) THEN
					msgs := msgs || CHR(10) || 'Please indicate the Payment Remark/Comment!';
					RAISE EXCEPTION
						USING ERRCODE = 'RHERR' , MESSAGE = msgs , HINT = msgs;
					END IF;
					IF (p_orgnlPymntID <= 0) THEN
						IF ((v_pymntNthdName ILIKE '%Check%' OR v_pymntNthdName ILIKE '%Cheque%') AND (CHAR_LENGTH(p_cheque_card_num) <= 0 OR CHAR_LENGTH(p_cheque_card_name) <= 0)) THEN
							msgs := msgs || CHR(10) || 'Please Indicate the Card/Cheque Name and No. if Payment Type is Cheque!';
							RAISE EXCEPTION
								USING ERRCODE = 'RHERR' , MESSAGE = msgs , HINT = msgs;
							END IF;
							IF (CHAR_LENGTH(p_pay_date) <= 0) THEN
								msgs := msgs || CHR(10) || 'Please indicate the Payment Date!';
								RAISE EXCEPTION
									USING ERRCODE = 'RHERR' , MESSAGE = msgs , HINT = msgs;
								END IF;
								IF (p_pay_amt_rcvd = 0) THEN
									msgs := msgs || CHR(10) || 'Please indicate the amount Given!';
									RAISE EXCEPTION
										USING ERRCODE = 'RHERR' , MESSAGE = msgs , HINT = msgs;
									END IF;
									IF ((v_pymntNthdName ILIKE '%Prepayment%' OR v_pymntNthdName ILIKE '%Advance%')) THEN
										IF (p_appld_prpay_docid <= 0) THEN
											msgs := msgs || CHR(10) || 'Please select the Prepayment you want to Apply First!';
											RAISE EXCEPTION
												USING ERRCODE = 'RHERR' , MESSAGE = msgs , HINT = msgs;
											ELSE
												v_prepayDocID := p_appld_prpay_docid;
												IF (p_doc_types = 'Supplier Payments') THEN
													v_prepayAvlblAmnt := gst.getgnrlrecnm ('accb.accb_pybls_invc_hdr' , 'pybls_invc_hdr_id' , 'amnt_paid-invc_amnt_appld_elswhr' , p_appld_prpay_docid)::numeric;
													v_prepayDocType := gst.getgnrlrecnm ('accb.accb_pybls_invc_hdr' , 'pybls_invc_hdr_id' , 'pybls_invc_type' , p_appld_prpay_docid);
												ELSE
													v_prepayAvlblAmnt := gst.getgnrlrecnm ('accb.accb_rcvbls_invc_hdr' , 'rcvbls_invc_hdr_id' , 'amnt_paid-invc_amnt_appld_elswhr' , p_appld_prpay_docid)::numeric;
													v_prepayDocType := gst.getgnrlrecnm ('accb.accb_rcvbls_invc_hdr' , 'rcvbls_invc_hdr_id' , 'rcvbls_invc_type' , p_appld_prpay_docid);
												END IF;
												IF (p_pay_amt_rcvd > v_prepayAvlblAmnt) THEN
													msgs := msgs || CHR(10) || 'Applied Prepayment Amount Exceeds the Available Amount on the selected Prepayment Document!';
													RAISE EXCEPTION
														USING ERRCODE = 'RHERR' , MESSAGE = msgs , HINT = msgs;
													END IF;
												END IF;
											END IF;
										END IF;
										IF (v_amntToPay = 0 AND v_createPrepay = FALSE) THEN
											msgs := msgs || CHR(10) || 'Cannot Repay a Fully Paid Document!';
											RAISE EXCEPTION
												USING ERRCODE = 'RHERR' , MESSAGE = msgs , HINT = msgs;
											END IF;
											IF (v_amntToPay < 0 AND p_pay_amt_rcvd > 0) THEN
												msgs := msgs || CHR(10) || 'Amount Given Must be Negative(Refund) if Amount to Pay is Negative(Refund)!';
												RAISE EXCEPTION
													USING ERRCODE = 'RHERR' , MESSAGE = msgs , HINT = msgs;
												END IF;
												IF (p_is_a_rvrsal = TRUE) THEN
													IF (accb.isPymntRvrsdB4 (p_orgnlPymntID) > 0) THEN
														msgs := 'SUCCESS:This Payment has been Reversed Already or is the Reversal of Another Payment!';
														RETURN REPLACE(msgs , CHR(10) , '<br/>');
													END IF;
												END IF;
												IF (v_createPrepay = TRUE AND v_spplrID <= 0) THEN
													msgs := msgs || CHR(10) || 'Cannot Create Advance Payment when Customer/Supplier is not Specified!';
													RAISE EXCEPTION
														USING ERRCODE = 'RHERR' , MESSAGE = msgs , HINT = msgs;
													END IF;
													IF (p_is_a_rvrsal = TRUE AND p_msPyID > 0) THEN
														v_reslt_1 := pay.rollBackMsPay (p_msPyID , p_orgidno , p_who_rn);
														IF (v_reslt_1 NOT LIKE 'SUCCESS:%') THEN
															msgs := msgs || CHR(10) || v_reslt_1;
															RAISE EXCEPTION
																USING ERRCODE = 'RHERR' , MESSAGE = msgs , HINT = msgs;
															END IF;
														END IF;
														IF (v_createPrepay = TRUE AND v_spplrID > 0 AND p_is_a_rvrsal = FALSE) THEN
															IF (p_doc_types = 'Supplier Payments') THEN
																v_srcDocID := accb.checkNCreatePyblsHdr (p_orgidno , v_spplrID , v_spplrSiteID , SUBSTR(p_pay_date , 1 , 11) , 'Supplier Advance Payment' , v_currID , v_amntBeingPaid , p_pay_mthd_id , v_funcCurrID , p_pay_date , - 1 , p_who_rn);
																v_srcDocType := gst.getgnrlrecnm ('accb.accb_pybls_invc_hdr' , 'pybls_invc_hdr_id' , 'pybls_invc_type' , v_srcDocID);
															ELSE
																v_srcDocID := accb.checkNCreateRcvblsHdr (p_orgidno , v_spplrID , v_spplrSiteID , SUBSTR(p_pay_date , 1 , 11) , 'Customer Advance Payment' , v_currID , v_amntBeingPaid , p_pay_mthd_id , v_funcCurrID , p_pay_date , - 1 , p_who_rn);
																v_srcDocType := gst.getgnrlrecnm ('accb.accb_rcvbls_invc_hdr' , 'rcvbls_invc_hdr_id' , 'rcvbls_invc_type' , v_srcDocID);
															END IF;
															v_dsablPayments := FALSE;
															v_createPrepay := FALSE;
														END IF;
														IF p_doc_types = 'Supplier Payments' THEN
															FOR rd2 IN
															SELECT
																pybls_invc_hdr_id
																, pybls_invc_number
																, pybls_invc_type
																, comments_desc
																, src_doc_hdr_id
																, supplier_id
																, supplier_site_id
																, approval_status
																, next_aproval_action
																, org_id
																, invoice_amount
																, src_doc_type
																, pymny_method_id
																, amnt_paid
																, invc_curr_id
																, invc_amnt_appld_elswhr
																, debt_gl_batch_id
																, balancing_accnt_id
																, advc_pay_ifo_doc_id
																, advc_pay_ifo_doc_typ
																, next_part_payment
																, firts_cheque_num
															FROM
																accb.accb_pybls_invc_hdr
															WHERE
																pybls_invc_hdr_id = v_srcDocID LOOP
																	p_orgidno := rd2.org_id;
																	v_docStatus := rd2.approval_status;
																	v_spplrID := rd2.supplier_id;
																	v_srcDocType := rd2.pybls_invc_type;
																	v_spplrSiteID := rd2.supplier_site_id;
																	IF (p_is_a_rvrsal = FALSE) THEN
																		v_currID := rd2.invc_curr_id;
																		v_amntToPay := rd2.invoice_amount - rd2.amnt_paid;
																		v_IncrsDcrs1 := 'D';
																		v_AccntID1 := rd2.balancing_accnt_id;
																		IF COALESCE(v_AccntID1 , - 1) <= 0 THEN
																			v_AccntID1 := v_dfltPyblAccntID;
																		END IF;
																		v_drCrdt1 := accb.dbt_or_crdt_accnt (v_AccntID1 , v_IncrsDcrs1);
																		FOR rd1 IN
																		SELECT
																			current_asst_acnt_id
																			, bckgrnd_process_name
																		FROM
																			accb.accb_paymnt_mthds
																		WHERE
																			paymnt_mthd_id = p_pay_mthd_id LOOP
																				v_IncrsDcrs2 := 'D';
																				--v_AccntID2 := rd1.current_asst_acnt_id;
																				v_AccntID2 := org.get_accnt_id_brnch_eqv (v_PrsnBrnchID , rd1.current_asst_acnt_id);
																				IF COALESCE(v_AccntID2 , - 1) <= 0 THEN
																					v_AccntID2 := v_dfltCashAccntID;
																				END IF;
																				v_actvtyDocName := rd1.bckgrnd_process_name;
																				IF (v_drCrdt1 = 'Debit') THEN
																					v_IncrsDcrs2 := SUBSTR(accb.incrs_or_dcrs_accnt (v_AccntID2 , 'Credit') , 1 , 1);
																				ELSE
																					v_IncrsDcrs2 := SUBSTR(accb.incrs_or_dcrs_accnt (v_AccntID2 , 'Debit') , 1 , 1);
																				END IF;
																				v_drCrdt2 := accb.dbt_or_crdt_accnt (v_AccntID2 , v_IncrsDcrs2);
																			END LOOP;
																	END IF;
																END LOOP;
														ELSE
															FOR rd2 IN
															SELECT
																rcvbls_invc_hdr_id
																, rcvbls_invc_date
																, rcvbls_invc_number
																, rcvbls_invc_type
																, comments_desc
																, src_doc_hdr_id
																, customer_id
																, customer_site_id
																, approval_status
																, next_aproval_action
																, org_id
																, invoice_amount
																, src_doc_type
																, pymny_method_id
																, amnt_paid
																, invc_curr_id
																, invc_amnt_appld_elswhr
																, balancing_accnt_id
																, debt_gl_batch_id
																, advc_pay_ifo_doc_id
																, advc_pay_ifo_doc_typ
															FROM
																accb.accb_rcvbls_invc_hdr
															WHERE
																rcvbls_invc_hdr_id = v_srcDocID LOOP
																	p_orgidno := rd2.org_id;
																	v_docStatus := rd2.approval_status;
																	v_spplrID := rd2.customer_id;
																	v_srcDocType := rd2.rcvbls_invc_type;
																	v_spplrSiteID := rd2.customer_site_id;
																	v_invoice_id := rd2.src_doc_hdr_id;
																	v_invoice_type := rd2.src_doc_type;
																	IF (p_is_a_rvrsal = FALSE) THEN
																		v_amntToPay := rd2.invoice_amount - rd2.amnt_paid;
																		v_currID := rd2.invc_curr_id;
																		v_IncrsDcrs1 := 'D';
																		v_AccntID1 := rd2.balancing_accnt_id;
																		IF COALESCE(v_AccntID1 , - 1) <= 0 THEN
																			v_AccntID1 := v_dfltRcvblAccntID;
																		END IF;
																		v_drCrdt1 := accb.dbt_or_crdt_accnt (v_AccntID1 , v_IncrsDcrs1);
																		FOR rd1 IN
																		SELECT
																			current_asst_acnt_id
																			, bckgrnd_process_name
																		FROM
																			accb.accb_paymnt_mthds
																		WHERE
																			paymnt_mthd_id = p_pay_mthd_id LOOP
																				v_IncrsDcrs2 := 'I';
																				--v_AccntID2 := rd1.current_asst_acnt_id;
																				v_AccntID2 := org.get_accnt_id_brnch_eqv (v_PrsnBrnchID , rd1.current_asst_acnt_id);
																				IF COALESCE(v_AccntID2 , - 1) <= 0 THEN
																					v_AccntID2 := v_dfltCashAccntID;
																				END IF;
																				v_actvtyDocName := rd1.bckgrnd_process_name;
																				IF (v_drCrdt1 = 'Debit') THEN
																					v_IncrsDcrs2 := SUBSTR(accb.incrs_or_dcrs_accnt (v_AccntID2 , 'Credit') , 1 , 1);
																				ELSE
																					v_IncrsDcrs2 := SUBSTR(accb.incrs_or_dcrs_accnt (v_AccntID2 , 'Debit') , 1 , 1);
																				END IF;
																				v_drCrdt2 := accb.dbt_or_crdt_accnt (v_AccntID2 , v_IncrsDcrs2);
																			END LOOP;
																	END IF;
																END LOOP;
														END IF;
														IF (v_srcDocID <= 0) THEN
															msgs := msgs || CHR(10) || 'No Source Receivable or Payable Document Available! Please check your document and try again!';
															RAISE EXCEPTION
																USING ERRCODE = 'RHERR' , MESSAGE = msgs , HINT = msgs;
															END IF;
															IF (v_docStatus != 'Approved') THEN
																msgs := msgs || CHR(10) || 'Only Approved Documents can be paid!';
																RAISE EXCEPTION
																	USING ERRCODE = 'RHERR' , MESSAGE = msgs , HINT = msgs;
																END IF;
																IF (p_doc_types = 'Supplier Payments') THEN
																	v_glBatchPrfx := 'PYMT-SPLR-';
																	v_glBatchSrc := 'Payment for Payables Invoice';
																	v_gnrtdTrnsNo1 := 'PYMT-SPLR-' || v_usrTrnsCode || '-' || v_dte || '-';
																	v_pymntBatchName := v_gnrtdTrnsNo1 || LPAD(((gst.getRecCount_LstNum ('accb.accb_payments_batches' , 'pymnt_batch_name' , 'pymnt_batch_id' , v_gnrtdTrnsNo1 || '%') + 1) || '') , 3 , '0');
																	v_docClsftn := gst.getGnrlRecNm ('accb.accb_pybls_invc_hdr' , 'pybls_invc_hdr_id' , 'doc_tmplt_clsfctn' , v_srcDocID);
																	v_docNum := gst.getGnrlRecNm ('accb.accb_pybls_invc_hdr' , 'pybls_invc_hdr_id' , 'pybls_invc_number' , v_srcDocID);
																ELSE
																	v_glBatchPrfx := 'RCPT-CSTMR-';
																	v_glBatchSrc := 'Receipt of Payment on Receivables Invoice';
																	v_gnrtdTrnsNo1 := 'RCPT-CSTMR-' || v_usrTrnsCode || '-' || v_dte || '-';
																	v_pymntBatchName := v_gnrtdTrnsNo1 || LPAD(((gst.getRecCount_LstNum ('accb.accb_payments_batches' , 'pymnt_batch_name' , 'pymnt_batch_id' , v_gnrtdTrnsNo1 || '%') + 1) || '') , 3 , '0');
																	v_docClsftn := gst.getGnrlRecNm ('accb.accb_rcvbls_invc_hdr' , 'rcvbls_invc_hdr_id' , 'doc_tmplt_clsfctn' , v_srcDocID);
																	v_docNum := gst.getGnrlRecNm ('accb.accb_rcvbls_invc_hdr' , 'rcvbls_invc_hdr_id' , 'rcvbls_invc_number' , v_srcDocID);
																END IF;
																IF p_NewPymntBatchID <= 0 THEN
																	v_pymntBatchID := gst.getGnrlRecID1 ('accb.accb_payments_batches' , 'pymnt_batch_name' , 'pymnt_batch_id' , v_pymntBatchName , p_orgidno);
																END IF;
																IF (p_is_a_rvrsal = FALSE) THEN
																	v_accntCurrID := accb.get_accnt_crncy_id (v_AccntID2);
																	v_funcCurrRate := accb.get_ltst_exchrate (v_currID , v_funcCurrID , p_pay_date , p_orgidno);
																	v_accntCurrRate := accb.get_ltst_exchrate (v_currID , v_accntCurrID , p_pay_date , p_orgidno);
																	v_funcCurrAmnt := v_amntBeingPaid * v_funcCurrRate;
																	v_accntCurrAmnt := v_amntBeingPaid * v_accntCurrRate;
																END IF;
																IF (v_pymntBatchID <= 0) THEN
																	msgs := msgs || CHR(10) || 'No Payment Batch Supplied!';
																	RAISE EXCEPTION
																		USING ERRCODE = 'RHERR' , MESSAGE = msgs , HINT = msgs;
																	END IF;
																	v_gnrtdTrnsNo1 := v_glBatchPrfx || v_usrTrnsCode || '-' || v_dte || '-';
																	v_glBatchName := v_gnrtdTrnsNo1 || LPAD(((gst.getRecCount_LstNum ('accb.accb_trnsctn_batches' , 'batch_name' , 'batch_id' , v_gnrtdTrnsNo1 || '%') + 1) || '') , 3 , '0');
																	v_glBatchID := gst.getGnrlRecID1 ('accb.accb_trnsctn_batches' , 'batch_name' , 'batch_id' , v_glBatchName , p_orgidno);
																	v_pay_remarks := p_pay_remarks || ' (' || v_docNum || ')';
																	IF (v_glBatchID <= 0) THEN
																		INSERT INTO accb.accb_trnsctn_batches (batch_name , batch_description , created_by , creation_date , org_id , batch_status , last_update_by , last_update_date , batch_source , batch_vldty_status , src_batch_id , avlbl_for_postng)
																			VALUES (v_glBatchName , v_pay_remarks , p_who_rn , TO_CHAR(NOW() , 'YYYY-MM-DD HH24:MI:SS') , p_orgidno , '0' , p_who_rn , TO_CHAR(NOW() , 'YYYY-MM-DD HH24:MI:SS') , v_glBatchSrc , 'VALID' , v_orgnlGLBatchID , '0');
																		v_glBatchID := gst.getGnrlRecID1 ('accb.accb_trnsctn_batches' , 'batch_name' , 'batch_id' , v_glBatchName , p_orgidno);
																		IF (v_orgnlGLBatchID > 0 AND p_is_a_rvrsal = TRUE) THEN
																			UPDATE
																				accb.accb_trnsctn_batches
																			SET
																				batch_vldty_status = 'VOID'
																				, last_update_by = p_who_rn
																				, last_update_date = TO_CHAR(NOW() , 'YYYY-MM-DD HH24:MI:SS')
																			WHERE
																				batch_id = v_orgnlGLBatchID;
																		END IF;
																	ELSE
																		msgs := msgs || CHR(10) || ' GL Batch Could not be Created! Try Again Later!';
																		RAISE EXCEPTION
																			USING ERRCODE = 'RHERR' , MESSAGE = msgs , HINT = msgs;
																		END IF;
																		v_glBatchID := gst.getGnrlRecID1 ('accb.accb_trnsctn_batches' , 'batch_name' , 'batch_id' , v_glBatchName , p_orgidno);
																		v_pymntID = - 1;
																		IF (v_pymntBatchID > 0 AND v_glBatchID > 0) THEN
																			IF p_is_a_rvrsal = FALSE THEN
																				/*Check and Run Payroll be4 continuing*/
																				IF v_invoice_id > 0 AND v_invoice_type = 'Sales Invoice' AND (p_orgnlPymntID > 0 AND p_msPyID <= 0) THEN
																					v_AllwDues := gst.getGnrlRecNm ('scm.scm_sales_invc_hdr' , 'invc_hdr_id' , 'allow_dues' , v_invoice_id);
																					IF v_AllwDues = '1' THEN
																						SELECT
																							*
																						FROM
																							pay.createNRunMassPayInvc (v_invoice_id , TO_CHAR(v_pay_date , 'DD-Mon-YYYY HH24:MI:SS') , v_amntBeingPaid , p_who_rn) INTO v_msPyID
	, v_reslt_1;
																						IF (v_reslt_1 NOT LIKE 'SUCCESS:%') THEN
																							msgs := msgs || CHR(10) || v_reslt_1;
																							RAISE EXCEPTION
																								USING ERRCODE = 'RHERR' , MESSAGE = msgs , HINT = msgs;
																							END IF;
																						END IF;
																					END IF;
																					v_pymntID = p_orgnlPymntID;
																					UPDATE
																						accb.accb_payments
																					SET
																						pymnt_mthd_id = p_pay_mthd_id
																						, amount_paid = v_amntBeingPaid
																						, change_or_balance = v_changeBals
																						, pymnt_remark = v_pay_remarks
																						, src_doc_typ = v_srcDocType
																						, src_doc_id = v_srcDocID
																						, last_update_by = p_who_rn
																						, last_update_date = TO_CHAR(NOW() , 'YYYY-MM-DD HH24:MI:SS')
																						, pymnt_date = TO_CHAR(v_pay_date , 'YYYY-MM-DD HH24:MI:SS')
																						, incrs_dcrs1 = v_IncrsDcrs1
																						, rcvbl_lblty_accnt_id = v_AccntID1
																						, incrs_dcrs2 = v_IncrsDcrs2
																						, cash_or_suspns_acnt_id = v_AccntID2
																						, gl_batch_id = v_glBatchID
																						, orgnl_pymnt_id = - 1
																						, pymnt_vldty_status = 'VALID'
																						, entrd_curr_id = v_currID
																						, func_curr_id = v_funcCurrID
																						, accnt_curr_id = v_accntCurrID
																						, func_curr_rate = v_funcCurrRate
																						, accnt_curr_rate = v_accntCurrRate
																						, func_curr_amount = v_funcCurrAmnt
																						, accnt_curr_amnt = v_accntCurrAmnt
																						, pymnt_batch_id = v_pymntBatchID
																						, prepay_doc_id = v_prepayDocID
																						, prepay_doc_type = v_prepayDocType
																						, pay_means_other_info = v_otherinfo
																						, cheque_card_name = p_cheque_card_name
																						, expiry_date = p_cheque_card_expdate
																						, cheque_card_num = p_cheque_card_num
																						, sign_code = p_cheque_card_code
																						, bkgrd_actvty_status = ''
																						, bkgrd_actvty_gen_doc_name = v_actvtyDocName
																						, intnl_pay_trns_id = v_msPyID
																						, is_cheque_printed = '0'
																						, is_removed = '0'
																						, amount_given = p_pay_amt_rcvd
																					WHERE
																						pymnt_id = v_pymntID;
																				ELSE
																					v_pymntID := NEXTVAL('accb.accb_payments_pymnt_id_seq');
																					INSERT INTO accb.accb_payments (pymnt_id , pymnt_mthd_id , amount_paid , change_or_balance , pymnt_remark , src_doc_typ , src_doc_id , created_by , creation_date , last_update_by , last_update_date , pymnt_date , incrs_dcrs1 , rcvbl_lblty_accnt_id , incrs_dcrs2 , cash_or_suspns_acnt_id , gl_batch_id , orgnl_pymnt_id , pymnt_vldty_status , entrd_curr_id , func_curr_id , accnt_curr_id , func_curr_rate , accnt_curr_rate , func_curr_amount , accnt_curr_amnt , pymnt_batch_id , prepay_doc_id , prepay_doc_type , pay_means_other_info , cheque_card_name , expiry_date , cheque_card_num , sign_code , bkgrd_actvty_status , bkgrd_actvty_gen_doc_name , intnl_pay_trns_id , is_cheque_printed , is_removed , amount_given)
																						VALUES (v_pymntID , p_pay_mthd_id , v_amntBeingPaid , v_changeBals , v_pay_remarks , v_srcDocType , v_srcDocID , p_who_rn , TO_CHAR(NOW() , 'YYYY-MM-DD HH24:MI:SS') , p_who_rn , TO_CHAR(NOW() , 'YYYY-MM-DD HH24:MI:SS') , TO_CHAR(v_pay_date , 'YYYY-MM-DD HH24:MI:SS') , v_IncrsDcrs1 , v_AccntID1 , v_IncrsDcrs2 , v_AccntID2 , v_glBatchID , p_orgnlPymntID , 'VALID' , v_currID , v_funcCurrID , v_accntCurrID , v_funcCurrRate , v_accntCurrRate , v_funcCurrAmnt , v_accntCurrAmnt , v_pymntBatchID , v_prepayDocID , v_prepayDocType , v_otherinfo , p_cheque_card_name , p_cheque_card_expdate , p_cheque_card_num , p_cheque_card_code , '' , v_actvtyDocName , v_msPyID , '0' , '0' , p_pay_amt_rcvd);
																					IF (p_orgnlPymntID > 0 AND p_is_a_rvrsal = TRUE) THEN
																						UPDATE
																							accb.accb_payments
																						SET
																							last_update_by = p_who_rn
																							, last_update_date = TO_CHAR(NOW() , 'YYYY-MM-DD HH24:MI:SS')
																							, pymnt_vldty_status = 'VOID'
																						WHERE
																							pymnt_id = p_orgnlPymntID;
																					END IF;
																				END IF;
																				v_reslt_1 := accb.CreatePymntAccntngTrns (v_AccntID2 , v_glBatchID , v_IncrsDcrs2 , v_funcCurrAmnt , p_orgidno , p_pay_date , v_pay_remarks , v_funcCurrID , v_amntBeingPaid , v_currID , v_accntCurrAmnt , v_accntCurrID , v_funcCurrRate , v_accntCurrRate , p_cheque_card_num , v_pymntID , p_who_rn);
																				IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
																					RAISE EXCEPTION
																						USING ERRCODE = 'RHERR' , MESSAGE = 'PAYMENT ACCOUNTING TRANSACTION FAILED' || v_reslt_1 , HINT = 'Payment Accounting Transaction could not be created!' || v_reslt_1;
																						RETURN msgs;
																					END IF;
																					v_reslt_1 := accb.CreatePymntAccntngTrns (v_AccntID1 , v_glBatchID , v_IncrsDcrs1 , v_funcCurrAmnt , p_orgidno , p_pay_date , v_pay_remarks , v_funcCurrID , v_amntBeingPaid , v_currID , v_accntCurrAmnt , v_accntCurrID , v_funcCurrRate , v_accntCurrRate , p_cheque_card_num , v_pymntID , p_who_rn);
																					IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
																						RAISE EXCEPTION
																							USING ERRCODE = 'RHERR' , MESSAGE = 'PAYMENT ACCOUNTING TRANSACTION FAILED' || v_reslt_1 , HINT = 'Payment Accounting Transaction could not be created!' || v_reslt_1;
																							RETURN msgs;
																						END IF;
																					END IF;
																					IF (accb.get_Batch_CrdtSum (v_glBatchID) = accb.get_Batch_DbtSum (v_glBatchID)) THEN
																						IF (p_doc_types = 'Supplier Payments') THEN
																							UPDATE
																								accb.accb_pybls_invc_hdr
																							SET
																								amnt_paid = amnt_paid + v_amntBeingPaid
																								, next_part_payment = next_part_payment - v_amntBeingPaid
																								, last_update_by = p_who_rn
																								, last_update_date = TO_CHAR(NOW() , 'YYYY-MM-DD HH24:MI:SS')
																							WHERE (pybls_invc_hdr_id = v_srcDocID);
																							UPDATE
																								accb.accb_pybls_invc_hdr
																							SET
																								next_part_payment = 0
																							WHERE (next_part_payment < 0);
																							IF (v_prepayDocID > 0) THEN
																								UPDATE
																									accb.accb_pybls_invc_hdr
																								SET
																									invc_amnt_appld_elswhr = invc_amnt_appld_elswhr + v_amntBeingPaid
																									, last_update_by = p_who_rn
																									, last_update_date = TO_CHAR(NOW() , 'YYYY-MM-DD HH24:MI:SS')
																								WHERE (pybls_invc_hdr_id = v_prepayDocID);
																								v_prepayDocType := gst.getGnrlRecNm ('accb.accb_pybls_invc_hdr' , 'pybls_invc_hdr_id' , 'pybls_invc_type' , v_prepayDocID);
																								IF (v_prepayDocType = 'Supplier Credit Memo (InDirect Refund)' OR v_prepayDocType = 'Supplier Debit Memo (InDirect Topup)') THEN
																									UPDATE
																										accb.accb_pybls_invc_hdr
																									SET
																										amnt_paid = amnt_paid + v_amntBeingPaid
																										, next_part_payment = next_part_payment - v_amntBeingPaid
																										, last_update_by = p_who_rn
																										, last_update_date = TO_CHAR(NOW() , 'YYYY-MM-DD HH24:MI:SS')
																									WHERE (pybls_invc_hdr_id = v_prepayDocID);
																									UPDATE
																										accb.accb_pybls_invc_hdr
																									SET
																										next_part_payment = 0
																									WHERE (next_part_payment < 0);
																								END IF;
																							END IF;
																							v_reslt_1 := accb.reCalcPyblsSmmrys (v_srcDocID , v_srcDocType , p_who_rn);
																						ELSE
																							UPDATE
																								accb.accb_rcvbls_invc_hdr
																							SET
																								amnt_paid = amnt_paid + v_amntBeingPaid
																								, last_update_by = p_who_rn
																								, last_update_date = TO_CHAR(NOW() , 'YYYY-MM-DD HH24:MI:SS')
																							WHERE (rcvbls_invc_hdr_id = v_srcDocID);
																							IF (v_prepayDocID > 0) THEN
																								UPDATE
																									accb.accb_rcvbls_invc_hdr
																								SET
																									invc_amnt_appld_elswhr = invc_amnt_appld_elswhr + v_amntBeingPaid
																									, last_update_by = p_who_rn
																									, last_update_date = TO_CHAR(NOW() , 'YYYY-MM-DD HH24:MI:SS')
																								WHERE (rcvbls_invc_hdr_id = v_prepayDocID);
																								v_prepayDocType := gst.getGnrlRecNm ('accb.accb_rcvbls_invc_hdr' , 'rcvbls_invc_hdr_id' , 'rcvbls_invc_type' , v_prepayDocID);
																								IF (v_prepayDocType = 'Customer Credit Memo (InDirect Topup)' OR v_prepayDocType = 'Customer Debit Memo (InDirect Refund)') THEN
																									UPDATE
																										accb.accb_rcvbls_invc_hdr
																									SET
																										amnt_paid = amnt_paid + v_amntBeingPaid
																										, last_update_by = p_who_rn
																										, last_update_date = TO_CHAR(NOW() , 'YYYY-MM-DD HH24:MI:SS')
																									WHERE (rcvbls_invc_hdr_id = v_prepayDocID);
																								END IF;
																							END IF;
																							v_reslt_1 := accb.reCalcRcvblsSmmrys (v_srcDocID , v_srcDocType , p_who_rn);
																						END IF;
																						IF (v_srcDocType = 'Supplier Credit Memo (InDirect Refund)' OR v_srcDocType = 'Supplier Debit Memo (InDirect Topup)') THEN
																							UPDATE
																								accb.accb_pybls_invc_hdr
																							SET
																								invc_amnt_appld_elswhr = invc_amnt_appld_elswhr + v_amntBeingPaid
																								, last_update_by = p_who_rn
																								, last_update_date = TO_CHAR(NOW() , 'YYYY-MM-DD HH24:MI:SS')
																							WHERE (pybls_invc_hdr_id = v_srcDocID);
																							UPDATE
																								accb.accb_pybls_invc_hdr
																							SET
																								next_part_payment = 0
																							WHERE (next_part_payment < 0);
																						ELSIF (v_srcDocType = 'Customer Credit Memo (InDirect Topup)'
																								OR v_srcDocType = 'Customer Debit Memo (InDirect Refund)') THEN
																							UPDATE
																								accb.accb_rcvbls_invc_hdr
																							SET
																								invc_amnt_appld_elswhr = invc_amnt_appld_elswhr + v_amntBeingPaid
																								, last_update_by = p_who_rn
																								, last_update_date = TO_CHAR(NOW() , 'YYYY-MM-DD HH24:MI:SS')
																							WHERE (rcvbls_invc_hdr_id = v_srcDocID);
																						END IF;
																						UPDATE
																							accb.accb_payments_batches
																						SET
																							batch_status = 'Processed'
																							, last_update_by = p_who_rn
																							, last_update_date = TO_CHAR(NOW() , 'YYYY-MM-DD HH24:MI:SS')
																						WHERE (pymnt_batch_id = v_pymntBatchID);
																						UPDATE
																							accb.accb_trnsctn_batches
																						SET
																							avlbl_for_postng = '1'
																							, last_update_by = p_who_rn
																							, last_update_date = TO_CHAR(NOW() , 'YYYY-MM-DD HH24:MI:SS')
																						WHERE
																							batch_id = v_glBatchID;
																						IF (p_doc_types = 'Supplier Payments') THEN
																							IF (v_srcDocType ILIKE '%Advance%' AND p_orgnlPymntID > 0 AND p_is_a_rvrsal = TRUE AND accb.shdPyblsDocBeCancelled (v_srcDocID) = TRUE) THEN
																								v_reslt_1 := accb.docCanclltnProcess (v_srcDocID , v_srcDocType , 'Payables' , p_orgidno , p_who_rn);
																								IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
																									RAISE EXCEPTION
																										USING ERRCODE = 'RHERR' , MESSAGE = 'PAYMENT ACCOUNTING TRANSACTION FAILED' || v_reslt_1 , HINT = 'Payment Accounting Transaction could not be created!' || v_reslt_1;
																									END IF;
																								END IF;
																							ELSE
																								IF (v_srcDocType ILIKE '%Advance%' AND p_orgnlPymntID > 0 AND p_is_a_rvrsal = TRUE AND accb.shdRcvblsDocBeCancelled (v_srcDocID) = TRUE) THEN
																									v_reslt_1 := accb.docCanclltnProcess (v_srcDocID , v_srcDocType , 'Receivables' , p_orgidno , p_who_rn);
																									IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
																										RAISE EXCEPTION
																											USING ERRCODE = 'RHERR' , MESSAGE = 'PAYMENT ACCOUNTING TRANSACTION FAILED' || v_reslt_1 , HINT = 'Payment Accounting Transaction could not be created!' || v_reslt_1;
																										END IF;
																									END IF;
																								END IF;
																							ELSE
																								msgs := msgs || CHR(10) || 'The GL Batch created IS NOT Balanced!Transactions created will be reversed AND deleted!';
																								DELETE FROM accb.accb_trnsctn_details
																								WHERE (batch_id = v_glBatchID);
																								DELETE FROM accb.accb_trnsctn_batches
																								WHERE (batch_id = v_glBatchID);
																								UPDATE
																									accb.accb_trnsctn_batches
																								SET
																									batch_vldty_status = 'VALID'
																								WHERE
																									batch_id IN (
																										SELECT
																											h.batch_id
																										FROM
																											accb.accb_trnsctn_batches h
																										WHERE
																											batch_vldty_status = 'VOID'
																											AND NOT EXISTS (
																												SELECT
																													g.batch_id
																												FROM
																													accb.accb_trnsctn_batches g
																												WHERE
																													h.batch_id = g.src_batch_id));
																								DELETE FROM accb.accb_payments
																								WHERE pymnt_batch_id = v_pymntBatchID;
																								DELETE FROM accb.accb_payments_batches
																								WHERE pymnt_batch_id = v_pymntBatchID;
																								RAISE EXCEPTION
																									USING ERRCODE = 'RHERR' , MESSAGE = msgs , HINT = msgs;
																									RETURN msgs;
																								END IF;
																								msgs := 'SUCCESS:Payment Successfully Made!';
																								RETURN REPLACE(msgs , CHR(10) , '<br/>');
EXCEPTION
	WHEN OTHERS THEN
		msgs := msgs || CHR(10) || '' || SQLSTATE || CHR(10) || SQLERRM;
																							msgs := REPLACE(msgs , CHR(10) , '<br/>');
																							RETURN msgs;
END;

$BODY$;

