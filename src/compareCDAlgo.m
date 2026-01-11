function [] = compareCDAlgo(videoFile, tau1, alpha, tau2)

videoReader = VideoReader(videoFile);

% --- Static background (average of first N frames)
N = 30;
videoReader.CurrentTime = 0;
k = 0;
bg_static = [];

while hasFrame(videoReader) && k < N
    fr = readFrame(videoReader);
    g  = toGrayDouble(fr);
    if k == 0
        bg_static = g;
    else
        bg_static = bg_static + g;
    end
    k = k + 1;
end
bg_static = bg_static / max(k,1);

% --- Running average init
bg_run = bg_static;

videoReader.CurrentTime = 0;
hFigure = figure(1);

while hasFrame(videoReader)

    if ~isvalid(hFigure)
        disp('Playback interrupted by user.');
        break;
    end

    frame = readFrame(videoReader);
    g = toGrayDouble(frame);

    diff_static = g - bg_static;
    bin1 = abs(diff_static) > tau1;

    diff_run = g - bg_run;
    bin2 = abs(diff_run) > tau2;

    bg_run = (1 - alpha) * bg_run + alpha * g;

    figure(1);
    subplot(2,3,1), imshow(toUInt8Vis(g)), title('Frame');
    subplot(2,3,2), imshow(toUInt8Vis(bg_static)), title('Static BG');
    subplot(2,3,3), imshow(uint8(255*bin1)), title('Binary 1');
    subplot(2,3,5), imshow(toUInt8Vis(bg_run)), title('Running BG');
    subplot(2,3,6), imshow(uint8(255*bin2)), title('Binary 2');

    drawnow;
end

close all;
end

function g = toGrayDouble(fr)
    if size(fr,3) == 3, fr = rgb2gray(fr); end
    g = im2double(fr);
end

function u = toUInt8Vis(x)
    u = im2uint8(mat2gray(x));
end
