function [poles, splits] = drawRLbranches(initPoles, KmaxBranches, breakpoints, gainLim, numP, denP, D, dendP, numdP, precisionQPmR, maxStep, reg)
    poles = initPoles;
    maxStep = min([maxStep, 1]);
    joinLines = {};
    s = cellfun(@(x) x(end), initPoles);
    cnt = 0;
    maxCnt = 1e5;   % While loop limit
    thresholds = sort([KmaxBranches(2:end), breakpoints, gainLim+1]);
    isBreakpoint = ismember(thresholds, breakpoints);
    K = 0;

    idxThreshold = 1;
    nextK = thresholds(idxThreshold);

    currPoleMat = [s];

    while K < gainLim && cnt < maxCnt
        num = evaluate_poly(s, numP, D, NaN, false);
        den = evaluate_poly(s, dendP+K*numdP, D, NaN, false);
        
        C = -(num./den);

        dK = maxStep/max(abs(C));
        K = K + dK;
        if K < gainLim 
            if K >= nextK % Pole appeared
                if isBreakpoint(idxThreshold)
                    K = nextK;
                    [joinLines, poles, currPoleMat] = breakpointPoles(joinLines, poles, currPoleMat, ...
                        K, reg, denP, numP, D, precisionQPmR);
                    s = currPoleMat(end,:);
                else
                    dK = K-nextK;
                    K = nextK;
        
                    ds = C*dK;
                    currP = denP+K*numP;
                    s = s+ds;
                    s = newton_method(s, currP, D, 1e-6); % Approx
                    [~, rts] = compute_roots(reg, denP+K*numP, D, precisionQPmR, 1); %QPmR
                    newRts = rearange(s, rts); % Match previous approx 
                    poles = addNewPoles(poles, currPoleMat); % Add previous points to branches
                    currPoleMat = newRts;
                    
                    s = newRts;
                end
                idxThreshold = idxThreshold + 1;
                nextK = thresholds(idxThreshold); % next threshold
            else % Approx
                ds = C*dK;
                currP = denP+K*numP;
                s = s+ds;
                s = newton_method(s, currP, D, 1e-6);
                
                currPoleMat = [currPoleMat; s];
            end
        end
        cnt = cnt + 1;
    end

    poles = addNewPoles(poles, currPoleMat);
    splits = joinLines;
    
    % -------------------------------------------------------
    % Rearange so it matches previous pole position
    function newOrder = rearange(prevPoles, nextPoles)
        newOrder = zeros(size(nextPoles));
        usedIdx = false(size(nextPoles)); 
        
        i1 = 1;
        for i = 1:length(prevPoles)
            checkedPole = prevPoles(i);
            [~, minIdxs] = sort(abs(nextPoles - checkedPole));
            for minI = minIdxs
                if ~usedIdx(minI)
                    newOrder(i1) = nextPoles(minI);
                    usedIdx(minI) = true;
                    break
                end
            end
            i1 = i1 + 1;
        end
        unusedPoles = nextPoles(~usedIdx);
        newOrder(i1:end) = unusedPoles;
    end
    
    % -------------------------------------------------------
    % Add different number of poles
    function newPoles = addNewPoles(oldPoles, addedPolesMat)
        i = 1;
        while i <= length(oldPoles)
            oldPoles{i}(end+1:end+size(addedPolesMat, 1)) = addedPolesMat(:,i);
            i = i+1;
        end

        while i <= size(addedPolesMat, 2)
            oldPoles{i} = addedPolesMat(:,i);
            i = i+1;
        end
        newPoles = oldPoles;
    end
    % -------------------------------------------------------
    function [joinLinesOut, polesOut, currPoleMatOut] = ...
            breakpointPoles(joinLinesIn, polesIn, currPoleMatIn, K, reg, ...
            denP, numP, D, precisionQPmR)
        lastPoles = currPoleMatIn(end,:);
        numPolesBP = argp_integral(reg, denP+K*numP, D, 0.01);
        [~, breakpointPoles] = compute_roots(reg, denP+K*numP, D, precisionQPmR, 1);
        
        % correction
        while length(breakpointPoles) ~= length(lastPoles)
            K = K - 0.01;
            [~, breakpointPoles] = compute_roots(reg, denP+(K-0.01)*numP, D, precisionQPmR, 1);
        end
        breakpointPoles = rearange(lastPoles, breakpointPoles);
        dk = 0.01;
        
        % find gain after split
        while argp_integral(reg, denP+(K+dk)*numP, D, 0.01) == numPolesBP && dk < 2
            dk = dk+0.01;
        end
        [~, nextBreakpointPoles] = compute_roots(reg, denP+(K+dk)*numP, D, precisionQPmR, 1);
        
        % Splitting from imaginary to real
        if length(nextBreakpointPoles) > length(breakpointPoles)
            breakpointPoles = rearange(currPoleMatIn(end,:), breakpointPoles);
            currPoleMatIn(end+1, :) = breakpointPoles;
            nearRealIdxs = find(imag(nextBreakpointPoles) < 0.3);
            realVals = nextBreakpointPoles(nearRealIdxs);
            idxs = [1, 2];
            minDiff = 100;
            for k = 0.1:0.1:3
                for i1 = 1:length(realVals)-1
                    for i2 = i1+1:length(realVals)
                        rdiff = abs(realVals(i1) - realVals(i2));
                        if rdiff < k && rdiff < minDiff
                            minDiff = rdiff;
                            idxs = [i1, i2];
                        end
                    end
                end
            end
            splitedVals = realVals(idxs);
            nextPoles = rearange(currPoleMatIn(end,:), nextBreakpointPoles);
            polesIn = addNewPoles(polesIn, currPoleMatIn);
            splitIdxs = [find(nextPoles == splitedVals(1)), find(nextPoles == splitedVals(2))];
            currPoleMatIn = [nextPoles ; nextPoles];
            currPoleMatIn(1, splitIdxs) = sum(splitedVals)/2;
            joinLinesOut = joinLinesIn; 
            polesOut = polesIn;
            currPoleMatOut = currPoleMatIn;
           
        else % Splitting from real to imaginary
            nearRealIdxs = find(imag(breakpointPoles) < 0.1);
            realVals = breakpointPoles(nearRealIdxs);
            idxs = [1, 2];
            minDiff = 100;
            for k = 0.1:0.1:3
                for i1 = 1:length(realVals)-1
                    for i2 = i1+1:length(realVals)
                        rdiff = abs(realVals(i1) - realVals(i2));
                        if rdiff < k && rdiff < minDiff
                            minDiff = rdiff;
                            idxs = [i1, i2];
                        end
                    end
                end
            end
            
            newVal = (breakpointPoles(idxs(1)) + breakpointPoles(idxs(2)))/2;
            currPoleMatIn(end+1,:) = currPoleMatIn(end,:);
            currPoleMatIn(end, idxs) = newVal;
            polesIn = addNewPoles(polesIn, currPoleMatIn);
            joinLinesIn(end+1) = polesIn(idxs(2));
            polesIn(idxs(2)) = [];   
            currPoleMatOut = rearange(cellfun(@(x) x(end), polesIn),nextBreakpointPoles);
            polesOut = polesIn;
            joinLinesOut = joinLinesIn;
        end
    end

    function newCell = sortCell(oldCell)
        % Extract last elements
        lastElements = cellfun(@(x) x(end), oldCell);
        
        % Extract imaginary and real parts
        imagParts = imag(lastElements);
        realParts = real(lastElements);
        
        % Combine into a matrix for sorting
        sortKeys = [imagParts(:), realParts(:)];
        
        % Get sorting indices
        [~, sortIdx] = sortrows(sortKeys);
        
        % Apply sorting to the cell array
        newCell = oldCell(sortIdx);
    end
end