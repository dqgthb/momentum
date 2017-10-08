function w = valueWeight(marketCapVector)
    mcSum = sum(marketCapVector);
    w = marketCapVector./mcSum;
end
