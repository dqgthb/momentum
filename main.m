disp("start!")
disp(datestr(now, 'HH:MM:SS'));

format bank
if exist('crspWithMomentum.mat', 'file')
    disp("found mat file! opening...");
    disp(datestr(now, 'HH:MM:SS'));
    load('crspWithMomentum.mat', 'crsp');

else
    disp("mat file does not exist. Creating one...");
    if exist('dump.mat', 'file')
        disp("dump.mat found. Try renaming it to 'crspWithMomentum.mat' and this will run faster.")
    end
    crsp = readtable("crsp20042008.csv");

    disp("progress... reading csv done")
    disp(datestr(now, 'HH:MM:SS'));

    crsp.datenum = datenum(num2str(crsp.DateOfObservation), 'yyyymmdd');
    disp("progress... datenum num2str done")
    disp(datestr(now, 'HH:MM:SS'));

    crsp.year  = year(crsp.datenum);
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

momentum       = table(unique(crsp.datenum), 'VariableNames', {'datenum'});
len            = length(momentum.datenum);
momentum.month = month(momentum.datenum);
momentum.year  = year(momentum.datenum);
momentum.mom1  = NaN(len, 1);
momentum.mom10 = NaN(len, 1);

% equal weighted
momentum.mom                      = NaN(len, 1);
momentum.equalWeightedMomLongOnly = NaN(len, 1);
momentum.equalWeightedIndex       = NaN(len, 1);
momentum.equalWeightedShadow      = NaN(len, 1);

% value weighted
momentum.valueWeightedMom         = NaN(len,1);
momentum.valueWeightedMomLongOnly = NaN(len,1);
momentum.valueWeightedIndex       = NaN(len, 1);
momentum.valueWeightedShadow      = NaN(len, 1);

% creating a similar table as momentum but only with Top 1000 Market Cap firms
momentum1000                          = table(unique(crsp.datenum), 'VariableNames', {'datenum'});
len                                   = length(momentum1000.datenum);
momentum1000.month                    = month(momentum1000.datenum);
momentum1000.year                     = year(momentum1000.datenum);
momentum1000.mom1                     = NaN(len, 1);
momentum1000.mom10                    = NaN(len, 1);
% equal weighted
momentum1000.mom                      = NaN(len, 1);
momentum1000.equalWeightedMomLongOnly = NaN(len, 1);
momentum1000.equalWeightedIndex       = NaN(len, 1);
momentum1000.equalWeightedShadow      = NaN(len, 1);
% value weighted
momentum1000.valueWeightedMom         = NaN(len,1);
momentum1000.valueWeightedMomLongOnly = NaN(len,1);
momentum1000.valueWeightedIndex       = NaN(len, 1);
momentum1000.valueWeightedShadow      = NaN(len, 1);


%
disp("progress... creating momenum table done")
disp(datestr(now, 'HH:MM:SS'));

% PERMNO-weight dictionary
%wdic = table(NaN(1000, 1), NaN(1000,1), 'VariableNames', {'weights', 'PERMNO'});

for i = 1 : len
    thisMonth   = momentum.month(i);
    thisYear    = momentum.year(i);
    isInvestible = crsp.year == thisYear ...
        & crsp.month == thisMonth ...
        & ~isnan(crsp.Returns);

    % Prepare tables
    investibles  = crsp(isInvestible,:);
    loserCutoff  = quantile(investibles.rankVariable, 0.1);
    winnerCutoff = quantile(investibles.rankVariable, 0.9);
    winners      = investibles(investibles.rankVariable >= winnerCutoff, :);
    losers       = investibles(investibles.rankVariable <= loserCutoff, :);

    %%%%% Equal Weighted Returns %%%%%
    % EWR stands for Equal Weighted Returns
    investiblesEWR = mean(investibles.Returns);
    winnersEWR     = mean(winners.Returns);
    losersEWR      = mean(losers.Returns);

    % logging for each portfolio strategy
    momentum.mom10(i)                    = winnersEWR;
    momentum.mom1(i)                     = losersEWR;
    momentum.mom(i)                      = winnersEWR - losersEWR;
    momentum.equalWeightedMomLongOnly(i) = winnersEWR;
    momentum.equalWeightedIndex(i)       = investiblesEWR;
    momentum.equalWeightedShadow(i)      = winnersEWR + losersEWR + investiblesEWR;

    %%%%% Value Weighted Returns %%%%%
    % use valueWeight function and store the result as additional columns
    investibles.valueW = valueWeight(investibles.marketCap);
    winners.valueW     = valueWeight(winners.marketCap);
    losers.valueW      = valueWeight(losers.marketCap);

    %% value weighted returns
    % VWR stands for Value Weighted Return
    investiblesVWR = sum(investibles.valueW .* investibles.Returns);
    winnersVWR     = sum(winners.valueW     .* winners.Returns);
    losersVWR      = sum(losers.valueW      .* losers.Returns);

    momentum.valueWeightedMom(i)         = winnersVWR - losersVWR;
    momentum.valueWeightedMomLongOnly(i) = winnersVWR;
    momentum.valueWeightedIndex(i)       = investiblesVWR;
    momentum.valueWeightedShadow(i)      = winnersVWR + losersVWR + investiblesVWR;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% MARKET CAP LIMIT 1000 %%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Same strategies are preformed only with the firms with top 1000 market caps
    [sortedMC, ix] = sort(investibles.marketCap, 'descend');
    firmNumberLimit = 1000;
    if length(investibles.marketCap) < firmNumberLimit
        disp("i = " + i + " : There are less sample firms than the limit.");
    else
        MCCutoff     = sortedMC(firmNumberLimit);
        investibles  = investibles(investibles.marketCap >= MCCutoff, :);
    end
    % Prepare tables
    loserCutoff      = quantile(investibles.rankVariable, 0.1);
    winnerCutoff     = quantile(investibles.rankVariable, 0.9);
    winners          = investibles(investibles.rankVariable >= winnerCutoff, :);
    losers           = investibles(investibles.rankVariable <= loserCutoff, :);

    %%%%% Equal Weighted Returns %%%%%
    % EWR stands for Equal Weighted Returns
    investiblesEWR = mean(investibles.Returns);
    winnersEWR     = mean(winners.Returns);
    losersEWR      = mean(losers.Returns);

    % logging for each portfolio strategy
    momentum1000.mom10(i)                    = winnersEWR;
    momentum1000.mom1(i)                     = losersEWR;
    momentum1000.mom(i)                      = winnersEWR - losersEWR;
    momentum1000.equalWeightedMomLongOnly(i) = winnersEWR;
    momentum1000.equalWeightedIndex(i)       = investiblesEWR;
    momentum1000.equalWeightedShadow(i)      = winnersEWR + losersEWR + investiblesEWR;

    %%%%% Value Weighted Returns %%%%%
    % use valueWeight function and store the result as additional columns
    investibles.valueW = valueWeight(investibles.marketCap);
    winners.valueW     = valueWeight(winners.marketCap);
    losers.valueW      = valueWeight(losers.marketCap);

    %% value weighted returns
    % VWR stands for Value Weighted Return
    investiblesVWR = sum(investibles.valueW .* investibles.Returns);
    winnersVWR     = sum(winners.valueW     .* winners.Returns);
    losersVWR      = sum(losers.valueW      .* losers.Returns);

    momentum1000.valueWeightedMom(i)         = winnersVWR - losersVWR;
    momentum1000.valueWeightedMomLongOnly(i) = winnersVWR;
    momentum1000.valueWeightedIndex(i)       = investiblesVWR;
    momentum1000.valueWeightedShadow(i)      = winnersVWR + losersVWR + investiblesVWR;
end

disp("progress... logging portfolio strategy returns ... done");
disp(datestr(now, 'HH:MM:SS'));


%%%%% Data Analysis part

cumulRets = table(unique(crsp.datenum), 'VariableNames', {'datenum'});
cumulRets.month = month(cumulRets.datenum);
cumulRets.year  = year(cumulRets.datenum);
cumulRets.mom                      = getCumulRet(momentum.mom                     );
cumulRets.equalWeightedMomLongOnly = getCumulRet(momentum.equalWeightedMomLongOnly);
cumulRets.equalWeightedIndex       = getCumulRet(momentum.equalWeightedIndex      );
cumulRets.equalWeightedShadow      = getCumulRet(momentum.equalWeightedShadow     );
cumulRets.valueWeightedMom         = getCumulRet(momentum.valueWeightedMom        );
cumulRets.valueWeightedMomLongOnly = getCumulRet(momentum.valueWeightedMomLongOnly);
cumulRets.valueWeightedIndex       = getCumulRet(momentum.valueWeightedIndex      );
cumulRets.valueWeightedShadow      = getCumulRet(momentum.valueWeightedShadow     );

cumulRets1000 = table(unique(crsp.datenum), 'VariableNames', {'datenum'});
cumulRets1000.month = month(cumulRets1000.datenum);
cumulRets1000.year  = year(cumulRets1000.datenum);
cumulRets1000.mom                      = getCumulRet(momentum1000.mom                     );
cumulRets1000.equalWeightedMomLongOnly = getCumulRet(momentum1000.equalWeightedMomLongOnly);
cumulRets1000.equalWeightedIndex       = getCumulRet(momentum1000.equalWeightedIndex      );
cumulRets1000.equalWeightedShadow      = getCumulRet(momentum1000.equalWeightedShadow     );
cumulRets1000.valueWeightedMom         = getCumulRet(momentum1000.valueWeightedMom        );
cumulRets1000.valueWeightedMomLongOnly = getCumulRet(momentum1000.valueWeightedMomLongOnly);
cumulRets1000.valueWeightedIndex       = getCumulRet(momentum1000.valueWeightedIndex      );
cumulRets1000.valueWeightedShadow      = getCumulRet(momentum1000.valueWeightedShadow     );

disp("progress... get cumulative returns ... done")
disp(datestr(now, 'HH:MM:SS'));

stats = table();

riskFree = 0.03;
benchMark = momentum.valueWeightedIndex;
stats.alpha = NaN(16,1);
for i=1:8
    stats.alpha(i) = portalpha(momentum{:, 5+i}, benchMark, riskFree);
end
for i=9:16
    stats.alpha(i) = portalpha(momentum1000{:, i-3}, benchMark, riskFree);
end

stats.arithMean = NaN(16,1);
for i=1:8
    stats.arithMean(i) = mean(removenan(momentum{:, 5+i}));
end
for i=9:16
    stats.arithMean(i) = mean(removenan(momentum1000{:, i-3}));
end

stats.STD = NaN(16,1);
for i=1:8
    stats.STD(i) = std(removenan(momentum{:, 5+i}));
end
for i=9:16
    stats.STD(i) = std(removenan(momentum1000{:, i-3}));
end

stats.sharpe = NaN(16,1);
riskFreeMonthly = riskFree / 12;
stats.sharpe = (stats.arithMean - riskFreeMonthly) ./ stats.STD;

% Add row names for stats table
portfolioNames = {'EWMom', 'EWLongOnly', 'EWIndex', 'EWShadow', 'VWMom', 'VWLongOnly', 'VWIndex', 'VWShadow', 'EWMom1000', 'EWLongOnly1000', 'EWIndex1000', 'EWShadow1000', 'VWMom1000', 'VWLongOnly1000', 'VWIndex1000', 'VWShadow1000'};
stats.Properties.RowNames = portfolioNames;

% Delete unnecessary variables
clear i isInvestible ix len thisMonth thisYear winnerCutoff loserCutoff sortedMC losers winners investibles losersEWR winnersEWR losersVWR winnersVWR investiblesEWR investiblesVWR MCCutoff firmNumberLimit riskFree benchMark riskFreeMonthly portfolioNames

disp("finished!")
disp(datestr(now, 'HH:MM:SS'));
