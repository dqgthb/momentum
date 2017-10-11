% main.m
% Group - Dexter: Deon Kim, Jaskrit Singh, Pegah Ehsani
% Due on October 10th, 2017
% Course: Applied Quantitative Finance 452
% Project: Assignment 1 - momentum strategy with tweaks
% Purpose: This program calculates the monthly returns, cumulative monthly returns, alphas, volatilities and sharpe ratios of 16 different individual portfolio strategies implemented from 2004 to 2008.

% Inputs:
% - crsp20042008.csv (for the first run)
% - crspWithMomentum.mat (for the second run and after)

%  Parameters and Variables:
%           * crsp - a table containing pertinent information for various stocks. It is comprised of columns such as PERMNO, DateOfObservation, Returns, adjustedPrice, year, month, and momentum.
%           * momentum - a table containing rows of unique datenum from 2004 January to 2008 December, and 8 different individual portfolio returns at each corresponding date.
%           * momentum1000 - a table equal to momentum table described above, except for that this only deals with 1000 firms with the highest market capitalization. It also contains information of returns of 8 different invididual portfolio returns.
%           * cumulRets - a table containing cumulative returns of 8 different portfolio strategies from momentum table.
%           * cumulRets1000 - a table containing cumulative returns of 8 different portfolio strategies from momentum1000 table.
%           * stats - a table containing statistics of 16 individual portfolio strategies including their alphas, expected returns, standard deviations and sharpe ratios.
%           * investible - a logical vector used for cherrypicking investible firms at a given unique date.
%           * each unique date has its unique isInvestible vector.
%           * investibles - a table extracted directly from crsp table using logical vector 'isInvestible' as logical indexing. Each unique date has its unique investibles table.
%           * winners - a table with firms of which momentums ranked top 10%, directly extracted from investibles table. Each unique date has its unique winners table.
%           * losers - a table with firms of which momentums ranked bottom 10%, directly extracted from investibles table. Each unique date has its unique losers table.
%           * firmNumberLimit - a scalar variable (e.g. 1000) which sets a limit on the number of tradable firms. Firms are sorted by their market capitalizations in a descending order (that is, highest to lowest) and only top n-th firms are tradable where n = firmNumberLimit.
%           * EqualWeighted (EW) - each firm is given equal weight = 1/(number of firms included in the portfolio)
%           * ValueWeighted (VW) - each firm is given weight according to its market capitalization relative to the total market capitalization of the firms included in the portfolio. This weight is derived using 'valueWeight' function.
%           * valueWeight - a function described in its own file valueWeight.m. It receives a vector of market capitalizations as its input, sum up to calculate the total market capitalization and returns a vector of weights derived from dividing the input (market cap vector) by the total market capitalization.
%           getCumulRet - a function described in its own file getCumulRet.m. It receives a vector of returns as its input, convert NaNs to zeros, returns a vector of subsequent cumulative returns of equal length as the input.

% Output:
%           * crspWithMomentum.mat (for the first run only) - a matlab workspace archive file containing crsp table with momentum column added. The code takes most of the time (usually about 5-20 mins depending on the speed of computer) in calculating the momentum of stocks. By saving them for the later use, we can ruduce its execution time.

% List of other files used:
%           * crspWithMomentum.mat (explained above)
%           * getCumulRet.m (explained above)
%           * valueWeight.m (explained above)
%           * getMomentum.m : a function used to achieve momentum of a stock at a given date.
%

disp("Program begins!")
disp(datestr(now, 'HH:MM:SS')); % displays time

format bank % format two decimal digit

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% Read or create data %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist('crspWithMomentum.mat', 'file') %  check if mat file exists. If not, create a new one.
    load('crspWithMomentum.mat', 'crsp'); % mat file reads pre-made data thus run faster

else
    disp("mat file does not exist. Creating one...");
    % read data from crsp20042008.csv
    crsp = readtable("crsp20042008.csv");
    % Convert date column into matlab compatible datenum variables.
    crsp.datenum = datenum(num2str(crsp.DateOfObservation), 'yyyymmdd');
    crsp.year  = year(crsp.datenum);
    crsp.month = month(crsp.datenum);

    len = length(crsp.PERMNO);
    rankVariable = NaN(len,1); % create empty column
    % This forloop iterates and fill in the empty rankVariable vectors with momentum of a stock at a given date.
    n = 0;
    for i=1 : len
        rankVariable(i) = getMomentum(crsp.PERMNO(i), crsp.year(i), crsp.month(i), crsp);
        % shows progress of forloop
        % code obtained from https://stackoverflow.com/questions/8825796/how-to-clear-the-last-line-in-the-command-window
        msg = sprintf('Processed: %d/%d', i, len);
        fprintf(repmat('\b', 1, n));
        fprintf(msg);
        n=numel(msg);
    end

    crsp.rankVariable = rankVariable;
    save('crspWithMomentum.mat','crsp')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% Prepare momentum and momentum1000 table %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create momentum table
momentum       = table(unique(crsp.datenum), 'VariableNames', {'datenum'});
len            = length(momentum.datenum);
momentum.month = month(momentum.datenum);
momentum.year  = year(momentum.datenum);
momentum.mom1  = NaN(len, 1);
momentum.mom10 = NaN(len, 1);

% add columns for logging returns of equal weighted portfolios
momentum.mom                      = NaN(len, 1); % winner - loser
momentum.equalWeightedMomLongOnly = NaN(len, 1); % winner
momentum.equalWeightedIndex       = NaN(len, 1); % buy all firms
momentum.equalWeightedShadow      = NaN(len, 1); % index + mom

% add columns for logging returns of value weighted portfolios
momentum.valueWeightedMom         = NaN(len, 1); % winner - loser
momentum.valueWeightedMomLongOnly = NaN(len, 1); % winner
momentum.valueWeightedIndex       = NaN(len, 1); % buy all firms
momentum.valueWeightedShadow      = NaN(len, 1); % index + mom

% Prepare momentum1000 table
% Unlike momentum table, momentum1000 table is comprised of firms with top 1000 large Market Capitalization.
momentum1000                          = table(unique(crsp.datenum), 'VariableNames', {'datenum'});
len                                   = length(momentum1000.datenum);
momentum1000.month                    = month(momentum1000.datenum);
momentum1000.year                     = year(momentum1000.datenum);
momentum1000.mom1                     = NaN(len, 1);
momentum1000.mom10                    = NaN(len, 1);

% add columns for logging returns of value equal portfolios
momentum1000.mom                      = NaN(len, 1); % winner - loser
momentum1000.equalWeightedMomLongOnly = NaN(len, 1); % winner
momentum1000.equalWeightedIndex       = NaN(len, 1); % buy all 1000 firms
momentum1000.equalWeightedShadow      = NaN(len, 1); % index + mom

% add columns for logging returns of value weighted portfolios
momentum1000.valueWeightedMom         = NaN(len, 1); % winner - loser
momentum1000.valueWeightedMomLongOnly = NaN(len, 1); % winner
momentum1000.valueWeightedIndex       = NaN(len, 1); % buy all firms
momentum1000.valueWeightedShadow      = NaN(len, 1); % index + mom

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% Calculate returns of each portfolio %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1 : len
    thisMonth   = momentum.month(i);
    thisYear    = momentum.year(i);
    isInvestible = crsp.year == thisYear ...
        & crsp.month == thisMonth ...
        & ~isnan(crsp.Returns);

    % Create new tables with firms which satisfies the conditions.
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
    momentum.equalWeightedShadow(i)      = winnersEWR - losersEWR + investiblesEWR;

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
    momentum.valueWeightedShadow(i)      = winnersVWR - losersVWR + investiblesVWR;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% MARKET CAP LIMIT 1000 %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Firms with top 1000 market caps
    sortedMC = sort(investibles.marketCap, 'descend'); % sorted marketCap
    firmNumberLimit = 1000;

    % If firmNumberLimit is higher than the number of investible firms, the code crashs.
    % This if statement handles the particular occasion.
    if length(investibles.marketCap) < firmNumberLimit
        disp("i = " + i + " : There are less sample firms than the limit.");
    else
        MCCutoff     = sortedMC(firmNumberLimit); % This is the market cap of 1000th firm.
        investibles  = investibles(investibles.marketCap >= MCCutoff, :); % Collects firms which have higher or equal market cap to that of 1000th firm.
    end
    % Prepare tables
    loserCutoff      = quantile(investibles.rankVariable, 0.1);
    winnerCutoff     = quantile(investibles.rankVariable, 0.9);
    winners          = investibles(investibles.rankVariable >= winnerCutoff, :); % top 10% winners
    losers           = investibles(investibles.rankVariable <= loserCutoff,  :); % bottom 10% losers

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
    momentum1000.equalWeightedShadow(i)      = winnersEWR - losersEWR + investiblesEWR;

    %%%%% Value Weighted Returns %%%%%
    % use valueWeight function and store the result as additional columns
    % todo: what value weight function does
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
    momentum1000.valueWeightedShadow(i)      = winnersVWR - losersVWR + investiblesVWR;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% Data Analysis %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Obtain Cumulative Returns of 16 different portfolio strategies.
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
%}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Create stats table %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% stats table contains individual information of
% - alpha
% - arithematic mean
% - standard deviation
% - sharpe ratios
% of 16 different portfolios.
stats = table();
riskFree = readtable("riskFree20042008.csv"); % data from https://datahub.io/core/bond-yields-us-10y
riskFree.rates = riskFree.rates ./ 12 ./100; % data conversion: 1) annual -> monthly 2) percent -> decimal
benchMark = momentum.valueWeightedIndex; % theoretical market portfolio for CAPM

% calculate alphas of 16 portfolios
stats.alpha = NaN(16,1);
for i=1:8
    stats.alpha(i) = portalpha(momentum{:, 5+i}, benchMark, riskFree.rates);
end
for i=9:16
    stats.alpha(i) = portalpha(momentum1000{:, i-3}, benchMark, riskFree.rates);
end
stats.alpha = stats.alpha * 12; % annulize alpha

% calculate arithematic means of 16 portfolios.
stats.arithMean = NaN(16,1);
for i=1:8
    stats.arithMean(i) = mean(removeNan(momentum{:, 5+i}));
end
for i=9:16
    stats.arithMean(i) = mean(removeNan(momentum1000{:, i-3}));
end

% calculate standard deviations of 16 portfolios.
stats.STD = NaN(16,1);
for i=1:8
    stats.STD(i) = std(removeNan(momentum{:, 5+i}));
end
for i=9:16
    stats.STD(i) = std(removeNan(momentum1000{:, i-3}));
end

% calculate sharpe ratios of 16 portfolios.
stats.sharpe = (stats.arithMean - mean(riskFree.rates)) ./ stats.STD;
stats.sharpe = stats.sharpe * sqrt(12); % annualize sharpe

% Add row names for stats table
portfolioNames = {'EWMom', 'EWLongOnly', 'EWIndex', 'EWShadow', 'VWMom', 'VWLongOnly', 'VWIndex', 'VWShadow', 'EWMom1000', 'EWLongOnly1000', 'EWIndex1000', 'EWShadow1000', 'VWMom1000', 'VWLongOnly1000', 'VWIndex1000', 'VWShadow1000'};
stats.Properties.RowNames = portfolioNames;

% Delete unnecessary variables
clear i isInvestible ix len thisMonth thisYear winnerCutoff loserCutoff sortedMC losers winners investibles losersEWR winnersEWR losersVWR winnersVWR investiblesEWR investiblesVWR MCCutoff firmNumberLimit benchMark portfolioNames riskFree

% create a 2x2 subplots with 4 portfolios plotted in each subplots.
portCumulRets = array2table([cumulRets{:, 4:11}, cumulRets1000{:, 4:11}]);
portCumulRets.Properties.VariableNames = portfolioNames;
for i=1:4
    for j=1:4
        subplot(2,2,i)
        plot(cumulRets.datenum, portCumulRets{:,j+4*(i-1)});
        datetick('x','yyyy-mm-dd');
        hold on;
    end
    legend(portfolioNames((i-1)*4+1:(i-1)*4+4));
end

disp("Finished!")
disp(datestr(now, 'HH:MM:SS'));
