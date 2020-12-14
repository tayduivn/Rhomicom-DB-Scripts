
UPDATE accb.accb_chart_of_accnts f SET debit_balance=0,
credit_balance=0, net_balance=0 
WHERE (debit_balance != 0 OR credit_balance != 0)
AND f.is_net_income!='1'
AND f.accnt_id NOT IN (Select y.accnt_id 
					   FROM accb.accb_trnsctn_details y,
					  		accb.accb_trnsctn_batches x
					  WHERE x.batch_id = y.batch_id 
					   AND x.org_id = f.org_id);
					   
Select f.accnt_id from accb.accb_chart_of_accnts f
WHERE (debit_balance != 0 OR credit_balance != 0)
AND f.is_net_income!='1'
AND f.accnt_id NOT IN (Select y.accnt_id 
					   FROM accb.accb_trnsctn_details y,
					  		accb.accb_trnsctn_batches x
					  WHERE x.batch_id = y.batch_id 
					   AND x.org_id = f.org_id);