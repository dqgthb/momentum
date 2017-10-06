function alpha = getAlpha(ret, index)
    cumulret = getCumulRet(ret);
    cumulindex = getCumulRet(index);
    alpha = cumulret(end) - cumulindex(end);
end
