function finalRoots = findDuplicates(oldRoots, P, D)
    finalRoots = [];
    sortedRoots = sortrows([imag(oldRoots).' real(oldRoots).'], [1 2]);
    polyRoots = sortedRoots(:,2).' + sortedRoots(:,1).'*1i;
    closeRoots = [0, abs(diff(polyRoots)) < 1e-2, 0];
    startEndIdxs = diff(closeRoots);
    startIdxs = find(startEndIdxs == 1);
    endIdxs = find(startEndIdxs == -1);
    i1 = 1;
    i2 = 1;
    while i1 <= length(oldRoots)
        if ismember(i1, startIdxs)
            idxStart = startIdxs(i2);
            idxEnd = endIdxs(i2);

            currPole = polyRoots(idxStart);
            multiplicity = argp_integral([real(currPole), real(currPole), imag(currPole), imag(currPole)], P, D, 0.01);
            finalRoots(end+1:end+multiplicity) = currPole;

            i2 = i2 + 1;
            i1 = idxEnd + 1;
        else
            finalRoots(end+1) = oldRoots(i1);
            i1 = i1 + 1;
        end
    end
    
end
