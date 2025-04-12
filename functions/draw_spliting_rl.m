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
            prevPoles = prevSection(end,:);

            for k1 = 0.1:0.1:2
                if ~isempty(find(imag(prevPoles) < k1))
                    nearRealIdxs = find(imag(prevPoles) < k1);
                    for k2 = 0.1:0.1:2
                        diffs = diff(currSection(1,:));
                        potIdxs = find(diffs < k2);
                        if sum(ismember(potIdxs, nearRealIdxs)) >= numSplits
                            idxs = potIdxs(ismember(potIdxs, nearRealIdxs));
                            break
                        end
                    end
                end
            end
            
            for idx = idxs(end:-1:1)
                tmpLines = [tmpLines(:,1:idx), tmpLines(:,idx), tmpLines(:,idx+1:end)];
            end
            prevWidth = prevWidth + numSplits;
            tmpLines(endPrev+1:endCurr, 1:size(currSection, 2)) = currSection;
        end
        tmpLines(endPrev+1:endCurr, 1:size(currSection, 2)) = currSection;
        endPrev = endCurr;
    end
end