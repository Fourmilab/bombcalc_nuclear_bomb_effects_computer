
    /*  Validate arguments in calculation request form.  */

    function checkCalc(f) {
    
    	/* Check yield within limits. */
    	var yield = f.yield.value;
	for (var i = 0; i < f.yunit.length; i++) {
	    if (f.yunit[1].checked) {
		yield *= f.yunit[1].value;
		break;
	    }
	}
	if ((yield < 1) || (yield > 20000)) {
	    alert("Yield out of bounds.  Must be between 1 kiloton and 20 megatons.");
	    return false;
    	}
	
	/* Check range within limits. */
	var range = f.range.value;
	for (var i = 0; i < f.runit.length; i++) {
	    if (f.runit[1].checked) {
		range *= f.runit[1].value;
		break;
	    }
	}
	if ((range < 0.05) || (range > 100)) {
	    alert("Range out of bounds.  Must be between 0.05 and 100 miles.");
	    return false;
    	}
	
    	return true;
    }

    function checkFallout(f) {
    
    	/* Check time after detonation within limits. */
    	var ftime = f.ftime.value;
	for (var i = 0; i < f.ftunit.length; i++) {
	    if (f.ftunit[i].checked) {
		ftime *= f.ftunit[i].value;
		break;
	    }
	}
	if ((ftime < 0.2) || (ftime > (30 * 24))) {
	    alert("Time after detonation out of bounds.  Must be between 0.2 hours and 30 days.");
	    return false;
    	}
	
	/* Check dose rate within limits. */
	var doserate = f.doserate.value;
	if ((doserate < 1) || (doserate > 10000)) {
	    alert("Dose rate out of bounds.  Must be between 1 and 10000.");
	    return false;
    	}
	
    	return true;
    }
