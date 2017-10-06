function w = mcWeight(vector)
    mcSum = sum(vector.marketCap);
    w = vector.marketCap/mcSum;
end
