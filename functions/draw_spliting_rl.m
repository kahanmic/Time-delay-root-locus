function tmpLines = draw_spliting_rl(sections, sectionHeighs, sectionWidths)
    tmpLines = zeros(sum(sectionHeighs), max(sectionWidths));
    tmpLines(1:sectionHeighs(1),1:sectionWidths(1)) = sections{1};
    endPrev = sectionHeighs(1);
    prevWidth = sectionWidths(1);

    for i = 2:length(sections)    
        currSection = sections{i};
        endCurr = endPrev + sectionHeighs(i);
        prevSection = tmpLines(1:endPrev,1:prevWidth);
   
        if length(currSection(end,:)) < length(prevSection(end,:)) % good
            numJoins = length(prevSection(end,:)) - length(currSection(end,:));
            prevPoles = prevSection(end,:);
            nearRealIdxs = find(imag(prevPoles) < 0.2);
            
            % find two closest poles near rela axis
            for k = 0.1:0.1:3
                potIdxs = find(abs(diff(prevPoles)) < k);
                if sum(ismember(potIdxs, nearRealIdxs)) >= numJoins
                    idxs = potIdxs(ismember(potIdxs, nearRealIdxs));
                    break
                end
            end
       
            for idx = idxs(end:-1:1)
                currSection = [currSection(:,1:idx), currSection(:,idx), currSection(:,idx+1:end)];
            end
            tmpLines(endPrev+1:endCurr, 1:size(currSection, 2)) = currSection;

        elseif length(currSection(end,:)) > length(prevSection(end,:)) % splitting, hasn't been tested yet
            numSplits = length(currSection(end,:)) - length(prevSection(end,:));
            diffs = abs(currSection(1,1:end-1) - currSection(1,2:end));
            k = 0.1;
            while length(diffs(diffs < k)) < numSplits && k < 1
                k = k+0.1;
            end        
            idxs = find(diffs < k);
            for idx = idxs(end:-1:1)
                tmpLines = [tmpLines(:,1:idx), tmpLines(:,idx+1), tmpLines(:,idx+1:end)];
            end
            prevWidth = prevWidth + numSplits;
            tmpLines(endPrev+1:endCurr, 1:size(currSection, 2)) = currSection;
        end
        tmpLines(endPrev+1:endCurr, 1:size(currSection, 2)) = currSection;
        endPrev = endCurr;
    end
end