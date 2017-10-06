function y=getMomentum(thisPermno, thisYear,thisMonth,crsp)

    startyear = thisYear - 1;
    startmonth = thisMonth;
    startprice = crsp.adjustedPrice(crsp.PERMNO == thisPermno & crsp.year == startyear & crsp.month == startmonth);
    endyear = thisYear;
    endmonth = thisMonth - 1;
    if endmonth == 0
        endmonth = 12;
        endyear = thisYear - 1;
    end
    endprice = crsp.adjustedPrice(crsp.PERMNO == thisPermno & crsp.year == endyear & crsp.month == endmonth);

    if isempty(startprice) | isempty(endprice)
        y = NaN;
    else y = endprice / startprice;
    end
end

