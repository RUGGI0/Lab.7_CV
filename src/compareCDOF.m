function [] = compareCDOF(videoFile, tau1, alpha, tau2, W) 
% This function compares the output of the change detection algorithm based
% on a running average, and of the optical flow estimated with the
% Lucas-Kanade algorithm.
% You must visualize the original video, the background and binary map
% obtained with the change detection, the magnitude and direction of the
% optical flow.
% tau1 is the threshold for the change detection (optional extra)
% alpha is the running average parameter
% tau2 is the threshold for differencing in the running average
% W is the side of the square patch to compute the optical flow

videoReader = VideoReader(videoFile);

if ~hasFrame(videoReader)
    fprintf('Empty video: %s\n', videoFile);
    return;
end

% Init
frame0 = readFrame(videoReader);
g_prev = toGrayDouble(frame0);
bg_run = g_prev;

hFigure = figure(1);

while hasFrame(videoReader)

    % Required: stop if window closed
    if ~isvalid(hFigure)
        disp('Playback interrupted by user.');
        break;
    end

    frame = readFrame(videoReader);
    g = toGrayDouble(frame);

    % Running average CD
    diff_run = g - bg_run;                 % double keeps negatives
    bin_cd = abs(diff_run) > tau2;

    % (Optional) use tau1 as stricter filter
    bin_cd = bin_cd & (abs(diff_run) > tau1);

    % Update background
    bg_run = (1 - alpha) * bg_run + alpha * g;

    % Lucas–Kanade flow
    [U, V] = lucasKanadeFlow(g_prev, g, W);

    % Visualization map from provided auxiliary function
    of_map = convertToMagDir(U, V);  % RGB double [0,1]

    % Visualize (UINT8 where needed)
    figure(1);
    subplot(2,2,1), imshow(toUInt8Vis(g), 'Border','tight'); title('Frame');
    subplot(2,2,2), imshow(of_map, 'Border','tight');        title('Optical Flow');
    subplot(2,2,3), imshow(uint8(255*bin_cd), 'Border','tight'); title('Binary map');
    subplot(2,2,4), imshow(toUInt8Vis(bg_run), 'Border','tight'); title('Running BG');

    drawnow;

    g_prev = g;
end

fprintf('Finished displaying video: %s\n', videoFile);
end

% ---- Helpers (Toolbox) ----
function g = toGrayDouble(fr)
    if size(fr,3) == 3
        fr = rgb2gray(fr);
    end
    g = im2double(fr);
end

function u = toUInt8Vis(x)
    u = im2uint8(mat2gray(x));
end

function [U,V] = lucasKanadeFlow(I1,I2,W)
    if mod(W,2)==0, W=W+1; end
    r = floor(W/2);

    [H,L] = size(I1);
    U = zeros(H,L);
    V = zeros(H,L);

    % Toolbox gradient
    [Ix, Iy] = imgradientxy(I2, 'CentralDifference');
    It = I2 - I1;

    step = max(1, r);

    for y = 1+r:step:H-r
        for x = 1+r:step:L-r
            px = Ix(y-r:y+r, x-r:x+r);
            py = Iy(y-r:y+r, x-r:x+r);
            pt = It(y-r:y+r, x-r:x+r);

            A = [px(:) py(:)];
            b = -pt(:);

            ATA = A'*A;
            if rcond(ATA) < 1e-6
                continue;
            end

            nu = ATA \ (A'*b);
            U(y,x) = nu(1);
            V(y,x) = nu(2);
        end
    end
end
