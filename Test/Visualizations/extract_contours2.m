function contours = extract_contours2(contour_data)
    % Returns contour points and length of each contour from contour matrix

    contours = {};
    lens = [];
    points = [];
    idx = 1;
    
    while idx < size(contour_data, 2)
        level = contour_data(1, idx); 
        numPoints = contour_data(2, idx); 
        x = contour_data(1, idx+1 : idx+numPoints); 
        y = contour_data(2, idx+1 : idx+numPoints); 
        points = [points, x + y.*1i];
        lens = [lens, numPoints];
        contours{end+1} = struct('level', level, 'x', x, 'y', y);
        idx = idx + numPoints + 1; 
    end
end