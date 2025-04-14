function [branchNums, K] = get_num_branches(reg, numP, denP, D, ds)
    gains = [linspace(0, 9.9, 1000), linspace(10, 99, 90), logspace(2, 8, 7)];
    numBranchesArray = zeros(size(gains));
    
    for i = 1:length(gains)
        Kcurr = gains(i);
        P = denP + Kcurr*numP;
        numBranchesArray(i) = argp_integral(reg, P, D, ds);
    end
    
    [maxNumBranches, maxIdx] = max(numBranchesArray);
    numSteps = maxNumBranches - numBranchesArray(1);
    branchMin = numBranchesArray(1);
    branchNums = [branchMin];
    K = [0];

    nBranchCurr = branchNums(end);
    if numSteps > 0
        for step = 1:numSteps
            nBranchCurr = branchMin + step;
            idx = find(numBranchesArray == nBranchCurr, 1);
            if ~isempty(idx) && idx <= maxIdx
                K(end+1) = gains(idx);
                branchNums(end+1) = nBranchCurr;
            end
        end
    end
end
%function [numBranches, K] = get_num_branches(reg, numP, denP, D, ds)
%    gains = [0, 1, logspace(1, 8, 8)];
%    numBranchesArray = zeros(size(gains));
%    for i = 1:length(gains)
%        K = gains(i);
%        P = denP + K*numP;
%        numBranchesArray(i) = argp_integral(reg, P, D, ds);
%    end
%    [numBranches, maxIdx] = max(numBranchesArray);
%    if maxIdx > 1
%        currBranches = 0;
%        minK = gains(maxIdx-1);
%        maxK = gains(maxIdx);
%        currK = 0;
%        for i = 1:10
%            currK = (maxK + minK)/2;
%            P = denP + currK*numP;
%            currBranches = argp_integral(reg, P, D, ds);
%            if currBranches < numBranches
%                minK = currK;
%            else
%                maxK = currK;
%            end
%        end
%        if currBranches < numBranches
%            K = maxK;
%        else
%            K = currK;
%        end
%    else
%        K = 0;
%    end

%end