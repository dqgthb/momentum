disp("start!")
disp(datestr(now, 'HH:MM:SS'));

format bank
if exist('crsp_w_mom.mat', 'file')
    disp("found mat file! opening...");
    %crsp = readtable('crsp_w_momentum.csv');
    load('crsp_w_mom.mat', 'crsp');
    disp("progress... adding rankVariable:momentum column done");
    disp(datestr(now, 'HH:MM:SS'));

else
    disp("mat file does not exist. Creating one...");
    if exist('dump.mat', 'file')
        disp("dump.mat found. Try renaming it to 'crsp_w_mom.mat' and this will run faster.")
    end
    crsp = readtable("crsp20042008.csv");
    %change FirmNumberLimit to 1000!
    %crsp = readtable("testData.csv");
    %crsp = readtable("testData_w_mc.csv");

    disp("progress... reading csv done")
    disp(datestr(now, 'HH:MM:SS'));

    crsp.datenum = datenum(num2str(crsp.DateOfObservation), 'yyyymmdd');
    disp("progress... datenum num2str done")
    disp(datestr(now, 'HH:MM:SS'));

    crsp.year = year(crsp.datenum);
    crsp.month = month(crsp.datenum);
    disp("progress... add column year and month done")
    disp(datestr(now, 'HH:MM:SS'));

    % get momentum, prepare rankVariable
    len = length(crsp.PERMNO);
    rankVariable = NaN(len,1);

    n = 0;
    for i=1 : len
        rankVariable(i) = getMomentum(crsp.PERMNO(i), crsp.year(i), crsp.month(i), crsp);
        % nice progress status code from
        % https://stackoverflow.com/questions/8825796/how-to-clear-the-last-line-in-the-command-window
        msg = sprintf('Processed %d/%d', i, len);
        fprintf(repmat('\b', 1, n));
        fprintf(msg);
        n=numel(msg);
    end
    crsp.rankVariable = rankVariable;
    disp("progress... adding rankVariable:momentum column done");
    disp(datestr(now, 'HH:MM:SS'));
    save('dump.mat','crsp')


end

% question 5
momentum = table(unique(crsp.datenum), 'VariableNames', {'datenum'});
len = length(momentum.datenum);
momentum.month = month(momentum.datenum);
momentum.year = year(momentum.datenum);
momentum.mom1 = NaN(len, 1);
momentum.mom10 = NaN(len, 1);
momentum.mom = NaN(len, 1);
momentum.shadow = NaN(len, 1);
momentum.index = NaN(len, 1);
momentum.longonly = NaN(len, 1);
momentum.momMC = NaN(len,1);
momentum.mcw = NaN(len,1);

%
disp("progress... creating momenum table done")
disp(datestr(now, 'HH:MM:SS'));

% PERMNO-weight dictionary
wdic = table(NaN(1000, 1), NaN(1000,1), 'VariableNames', {'weights', 'PERMNO'});

for i = 1 : len
    this_month = momentum.month(i);
    this_year = momentum.year(i);
    isInvestible = crsp.year == this_year ...
        & crsp.month == this_month ...
        & ~isnan(crsp.Returns);

    investibles = crsp(isInvestible,:);

    [sorted_MC, ix] = sort(investibles.marketCap, 'descend');
    FirmNumberLimit = 1000; % just change this to 1000 or whatever in the actual data
    MCCutoff = sorted_MC(FirmNumberLimit); % bug alert. If there are less firms than FirmNumberLimit, may crash. We make an assumption that investible firms are always larger than FirmNumberLimit.
    investibles_MC = investibles(investibles.marketCap >= MCCutoff, :);

    loserCutoff_MC = quantile(investibles_MC.rankVariable, 0.1);
    winnerCutoff_MC = quantile(investibles_MC.rankVariable, 0.9);

    winners_MC = investibles_MC(investibles_MC.rankVariable >= winnerCutoff_MC, :);
    losers_MC = investibles_MC(investibles_MC.rankVariable <= loserCutoff_MC, :);
    normals_MC = investibles_MC(investibles_MC.rankVariable < winnerCutoff_MC & investibles_MC.rankVariable > loserCutoff_MC, :);

    momentum.momMC(i) = mean(winners_MC.Returns) - mean(losers_MC.Returns);

    loserCutoff = quantile(investibles.rankVariable, 0.1);
    winnerCutoff = quantile(investibles.rankVariable, 0.9);

    winners = investibles(investibles.rankVariable >= winnerCutoff, :);
    losers = investibles(investibles.rankVariable <= loserCutoff, :);
    normals = investibles(investibles.rankVariable < winnerCutoff & investibles.rankVariable > loserCutoff, :);

    winners.weight = mcWeight(winners);

    % update weight dic
    %wdic = add_winners_to_weight(winners, wdic);

    meanwinret = mean(winners.Returns);
    meanloseret = mean(losers.Returns);
    meannormret = mean(normals.Returns);

    momentum.mom10(i) = meanwinret;
    momentum.mom1(i) = meanloseret;
    momentum.mom(i) = meanwinret - meanloseret;
    momentum.index(i) = mean(investibles.Returns);
    momentum.shadow(i) = 2*meanwinret + meannormret;
    momentum.longonly(i) = meanwinret;

end

disp("progress... portfolio weighting done")
disp(datestr(now, 'HH:MM:SS'));

% cumulative
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

disp("progress... getting cumuls done")
disp(datestr(now, 'HH:MM:SS'));

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

disp("finished!")
disp(datestr(now, 'HH:MM:SS'));
