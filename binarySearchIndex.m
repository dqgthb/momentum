function index = binarySearchIndex(thisPERMNO, sortedVector, beginI, endI)
% assume 'weights' is sorted

    % if thisPERMNO does not exist in sortedVecter, return -1
    if beginI == endI & sortedVector(beginI)~=thisPERMNO
        index = int32(-1);
        return
    end

    midI = idivide(int32(beginI+endI), int32(2), 'floor');
    if sortedVector(midI) > thisPERMNO
        index = binarySearchIndex(thisPERMNO, sortedVector, beginI, midI);
    elseif sortedVector(midI) < thisPERMNO
        index = binarySearchIndex(thisPERMNO, sortedVector, midI+1, endI);
    elseif sortedVector(midI) == thisPERMNO
        index = midI;
    else
        disp("there is a bug");
        index = -2;
    end
end

