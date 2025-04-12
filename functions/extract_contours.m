function [lens, points, contours] = extract_contours(contour_data)
% Returns contour points and length of each contour from contour matrix

    lens = [];
    points = [];
    idx = 1;
    contours = {};

    while idx < size(contour_data, 2)
        level = contour_data(1, idx); 
        numPoints = contour_data(2, idx); 
        x = contour_data(1, idx+1 : idx+numPoints); 
        y = contour_data(2, idx+1 : idx+numPoints); 
        points = [points, x + y.*1i];
        contours{end+1} = x + y.*1i;
        lens = [lens, numPoints];
        idx = idx + numPoints + 1; 
    end
end