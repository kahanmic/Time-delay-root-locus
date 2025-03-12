function cursMat = holdCursorMat
% Cursor matrix for appearance

    cursMat = [ones(1,16)*NaN;
        ones(1,16)*NaN;
        ones(1,16)*NaN;
        ones(1,16)*NaN; 
        ones(1,7)*NaN, ones(1,3), ones(1, 6)*NaN;
        ones(1,5)*NaN, 1, 1, 1, 2, 1, 1, 1, ones(1, 4)*NaN;
        ones(1,5)*NaN, 1, 2, 1, 2, 1, 2, 1, 1, ones(1, 3)*NaN;
        ones(1,5)*NaN, 1, 2, 1, 2, 1, 2, 1, 2, 1, ones(1, 2)*NaN;
        ones(1,4)*NaN, 1, 1, 2*ones(1,7), 1, ones(1, 2)*NaN;
        ones(1,4)*NaN, 1,  2*ones(1,8), 1, ones(1, 2)*NaN;
        ones(1,3)*NaN, 1, 1, 2*ones(1,8), 1, ones(1, 2)*NaN; 
        ones(1,3)*NaN, 1, 2*ones(1,9), 1, ones(1, 2)*NaN;
        ones(1,4)*NaN, 1, 2*ones(1,7), 1, ones(1, 3)*NaN;
        ones(1,5)*NaN, 1, 2*ones(1,6), 1, ones(1, 3)*NaN;
        ones(1,5)*NaN, ones(1,7), ones(1, 4)*NaN;
        ones(1, 16)*NaN;];
end