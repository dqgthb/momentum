function y = prepareMomentumColumn(crsp)
    len = length(crsp.PERMNO);
    rankVariable = NaN(len, 1);
    for i=1 : len;
        rankVariable(i) = getMomentum(crsp.PERMNO(i), crsp.year(i), crsp.month(i), crsp);
    end
    crsp.rankVariable = rankVariable;
    y = crsp;
end
