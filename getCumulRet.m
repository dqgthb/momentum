function y = getCumulRet(rets)
    len = length(rets);
    cumulrets = zeros(len, 1);
    % NaN to zero
    rets(isnan(rets)) = 0;
    cumulrets(1) = rets(1);

    for i = 2:len
        cumulrets(i) = (1+cumulrets(i-1))*(1+rets(i))-1;
    end

    y = cumulrets;
end


