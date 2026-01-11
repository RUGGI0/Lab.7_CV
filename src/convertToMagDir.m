function [rgbImage] = convertToMagDir(u, v)
% This function produces a visualization of the optical flow based on
% magnitude and direction of each vector
% u and v are the matrices with the two components of the optical flow

magnitude = sqrt(u.^2 + v.^2);
direction = atan2(v, u);

den = max(magnitude(:));
if den == 0
    den = 1;
end
magnitudeNorm = magnitude / den;

hue = (direction + pi) / (2 * pi);
saturation = ones(size(hue));
value = magnitudeNorm;

hsvImage = cat(3, hue, saturation, value);
rgbImage = hsv2rgb(hsvImage);
end
