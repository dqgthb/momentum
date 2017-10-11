function vecWithoutNan = removeNan(vecWithNan)
    vecWithoutNan = vecWithNan;
    vecWithoutNan(isnan(vecWithoutNan))=[];
end
