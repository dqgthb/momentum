disp("start!")
disp(datestr(now, 'HH:MM:SS'));

format bank
if exist('crsp_w_mom.mat', 'file')
    disp("found mat file! opening...");
    disp(datestr(now, 'HH:MM:SS'));
    load('crsp_w_mom.mat', 'crsp');

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
mc1000                          = table(unique(crsp.datenum), 'VariableNames', {'datenum'});
len                             = length(mc1000.datenum);
mc1000.month                    = month(mc1000.datenum);
mc1000.year                     = year(mc1000.datenum);
mc1000.mom1                     = NaN(len, 1);
mc1000.mom10                    = NaN(len, 1);
% equal weighted
mc1000.mom                      = NaN(len, 1);
mc1000.equalWeightedMomLongOnly = NaN(len, 1);
mc1000.equalWeightedIndex       = NaN(len, 1);
mc1000.equalWeightedShadow      = NaN(len, 1);
% value weighted
mc1000.valueWeightedMom         = NaN(len,1);
mc1000.valueWeightedMomLongOnly = NaN(len,1);
mc1000.valueWeightedIndex       = NaN(len, 1);
mc1000.valueWeightedShadow      = NaN(len, 1);


%
disp("progress... creating momenum table done")
disp(datestr(now, 'HH:MM:SS'));

% PERMNO-weight dictionary
%wdic = table(NaN(1000, 1), NaN(1000,1), 'VariableNames', {'weights', 'PERMNO'});

for i = 1 : len
    this_month   = momentum.month(i);
    this_year    = momentum.year(i);
    isInvestible = crsp.year == this_year ...
        & crsp.month == this_month ...
        & ~isnan(crsp.Returns);

    % Prepare tables
    investibles  = crsp(isInvestible,:);
    loserCutoff  = quantile(investibles.rankVariable, 0.1);
    winnerCutoff = quantile(investibles.rankVariable, 0.9);
    winners      = investibles(investibles.rankVariable >= winnerCutoff, :);
    losers       = investibles(investibles.rankVariable <= loserCutoff, :);

    %%%%% Equal Weighted Returns %%%%%
    % EWR stands for Equal Weighted Returns
    InvestiblesEWR = mean(investibles.Returns);
    WinnersEWR     = mean(winners.Returns);
    LosersEWR      = mean(losers.Returns);

    % logging for each portfolio strategy
    momentum.mom10(i)                    = WinnersEWR;
    momentum.mom1(i)                     = LosersEWR;
    momentum.mom(i)                      = WinnersEWR - LosersEWR;
    momentum.equalWeightedMomLongOnly(i) = WinnersEWR;
    momentum.equalWeightedIndex(i)       = InvestiblesEWR;
    momentum.equalWeightedShadow(i)      = WinnersEWR + LosersEWR + InvestiblesEWR;

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
    [sorted_MC, ix] = sort(investibles.marketCap, 'descend');
    FirmNumberLimit = 1000;
    if length(investibles.marketCap) < FirmNumberLimit
        disp("i = " + i + " : There are less sample firms than the limit.");
    else
        MCCutoff     = sorted_MC(FirmNumberLimit);
        investibles  = investibles(investibles.marketCap >= MCCutoff, :);
    end
    % Prepare tables
    loserCutoff      = quantile(investibles.rankVariable, 0.1);
    winnerCutoff     = quantile(investibles.rankVariable, 0.9);
    winners          = investibles(investibles.rankVariable >= winnerCutoff, :);
    losers           = investibles(investibles.rankVariable <= loserCutoff, :);

    %%%%% Equal Weighted Returns %%%%%
    % EWR stands for Equal Weighted Returns
    InvestiblesEWR = mean(investibles.Returns);
    WinnersEWR     = mean(winners.Returns);
    LosersEWR      = mean(losers.Returns);

    % logging for each portfolio strategy
    mc1000.mom10(i)                    = WinnersEWR;
    mc1000.mom1(i)                     = LosersEWR;
    mc1000.mom(i)                      = WinnersEWR - LosersEWR;
    mc1000.equalWeightedMomLongOnly(i) = WinnersEWR;
    mc1000.equalWeightedIndex(i)       = InvestiblesEWR;
    mc1000.equalWeightedShadow(i)      = WinnersEWR + LosersEWR + InvestiblesEWR;

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

    mc1000.valueWeightedMom(i)         = winnersVWR - losersVWR;
    mc1000.valueWeightedMomLongOnly(i) = winnersVWR;
    mc1000.valueWeightedIndex(i)       = investiblesVWR;
    mc1000.valueWeightedShadow(i)      = winnersVWR + losersVWR + investiblesVWR;
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
cumulRets1000.mom                      = getCumulRet(mc1000.mom                     );
cumulRets1000.equalWeightedMomLongOnly = getCumulRet(mc1000.equalWeightedMomLongOnly);
cumulRets1000.equalWeightedIndex       = getCumulRet(mc1000.equalWeightedIndex      );
cumulRets1000.equalWeightedShadow      = getCumulRet(mc1000.equalWeightedShadow     );
cumulRets1000.valueWeightedMom         = getCumulRet(mc1000.valueWeightedMom        );
cumulRets1000.valueWeightedMomLongOnly = getCumulRet(mc1000.valueWeightedMomLongOnly);
cumulRets1000.valueWeightedIndex       = getCumulRet(mc1000.valueWeightedIndex      );
cumulRets1000.valueWeightedShadow      = getCumulRet(mc1000.valueWeightedShadow     );

disp("progress... get cumulative returns ... done")
disp(datestr(now, 'HH:MM:SS'));

%{
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

disp("finished!")
disp(datestr(now, 'HH:MM:SS'));
