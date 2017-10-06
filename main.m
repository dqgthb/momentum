format bank

%crsp = readtable("crsp20042008.csv");
%crsp = readtable("testData.csv");
crsp = readtable("testData_w_mc.csv");
%crsp = readtable("crsp_real_w_datenum.csv");

%{
%}
crsp.datenum = datenum(num2str(crsp.DateOfObservation), 'yyyymmdd');
crsp.year = year(crsp.datenum);
crsp.month = month(crsp.datenum);
%}

% get momentum, prepare rankVariable
len = length(crsp.PERMNO);
rankVariable = NaN(len, 1);
for i=1 : len;
    rankVariable(i) = getMomentum(crsp.PERMNO(i), crsp.year(i), crsp.month(i), crsp);
end
crsp.rankVariable = rankVariable;

%{
len = length(crsp.PERMNO);
rankVariable = NaN(len, 1);
for i=1 : len;
    rankVariable(i) = getMomentum(crsp.PERMNO(i), crsp.year(i), crsp.month(i), crsp);
end
crsp.rankVariable = rankVariable;
%}


crsp(1:5,:)

% question 5
momentum = table(unique(crsp.datenum), 'VariableNames', {'datenum'});
len = length(momentum.datenum);
momentum.month = month(momentum.datenum);
momentum.year = year(momentum.datenum);
momentum.mom1 = NaN(len, 1);
momentum.mom10 = NaN(len, 1);
momentum.mom = NaN(len, 1);
%{
momentum.shadow = NaN(len, 1);
momentum.index = NaN(len, 1);
momentum.longonly = NaN(len, 1);
momentum.mcw = NaN(len,1);
%}

% PERMNO-weight dictionary
wdic = table([], [], 'VariableNames', {'weights', 'PERMNO'});

for i = 1 : len
    this_month = momentum.month(i);
    this_year = momentum.year(i);
    isInvestible = crsp.year == this_year ...
        & crsp.month == this_month ...
        & ~isnan(crsp.Returns);

    investibles = crsp(isInvestible, :);
    %investibles = table(crsp.PERMNO(isInvestible), crsp.Returns(isInvestible), crsp.rankVariable(isInvestible), 'VariableNames', {'PERMNO', 'Returns', 'rankVariable'});

    loserCutoff = quantile(investibles.rankVariable, 0.1);
    winnerCutoff = quantile(investibles.rankVariable, 0.9);
    winners = investibles(investibles.rankVariable >= winnerCutoff, :);
    losers = investibles(investibles.rankVariable <= loserCutoff, :);
    normals = investibles(investibles.rankVariable < winnerCutoff & investibles.rankVariable > loserCutoff, :);

    winners.weight = mcWeight(winners);


    % update weight dic
    %wdic = add_winners_to_weight(winners, wdic);

    % losersrets = crsp.Returns(isInvestible & crsp.rankVariable <= loserCutoff);
    % winnersrets = crsp.Returns(isInvestible & crsp.rankVariable >= winnerCutoff);
    % normalsrets = crsp.Returns(isInvestible & crsp.rankVariable < winnerCutoff & crsp.rankVariable > loserCutoff);
    losersrets = losers.Returns;
    winnersrets = winners.Returns;
    normalsrets = normals.Returns;

    %momentum.mom10(i) = mean(winnersrets);
    %momentum.mom10(i) = mean(3monthret(winnersrets);
    meanwinret = mean(winnersrets);
    %momentum.mom1(i) = mean(losersrets);
    meanloseret = mean(losersrets);
    meannormret = mean(normalsrets);

    momentum.mom(i) = meanwinret - meanloseret;
    %{
    momentum.index(i) = mean(investibles.Returns);
    momentum.shadow(i) = 2*meanwinret + meannormret;
    momentum.longonly(i) = meanwinret;
    %}

end

% cumulative
%{
momentum.cumulativeRet = getCumulRet(momentum.mom);
momentum.cumulindex = getCumulRet(momentum.index);
momentum.cumulshadow = getCumulRet (momentum.shadow);
momentum.cumullongonly = getCumulRet(momentum.longonly);

cumuls = [
momentum.cumulativeRet(end);
momentum.cumulindex(end);
momentum.cumulshadow(end);
momentum.cumullongonly(end);
];

alphas = ...
[
getAlpha(momentum.mom, momentum.index);
getAlpha(momentum.index, momentum.index);
getAlpha(momentum.shadow, momentum.index);
getAlpha(momentum.longonly, momentum.index);
];

stds = ...
    [
std(removenan(momentum.mom));
std(removenan(momentum.index));
std(removenan(momentum.shadow));
std(removenan(momentum.longonly));
];

means = ...
    [
mean(removenan(momentum.mom));
mean(removenan(momentum.index));
mean(removenan(momentum.shadow));
mean(removenan(momentum.longonly));
];


rf_yearly = 0.0422;
rf_monthly = rf_yearly/12;

sharpes = (means - rf_monthly)./stds;
%}
