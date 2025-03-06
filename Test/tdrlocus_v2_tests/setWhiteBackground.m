function newImg = setWhiteBackground(img, alpha)
    bgcolor = [1 1 1]; 
    img = im2double(img);
    alpha = im2double(alpha);
    newImg = img.*alpha + permute(bgcolor,[1 3 2]).*(1-alpha);
end