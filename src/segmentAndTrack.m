function [] = segmentAndTrack(videoFile, tau1, alpha, tau2) 
% Optional part: segment + track a fixed target (white person), manually initialized.
% Uses Image Processing Toolbox functions (bwconncomp, regionprops, bwareaopen, etc.)

videoReader = VideoReader(videoFile);

i = 0;

% Parameters you may tune
minArea = 200;     % remove tiny blobs
maxJump = 90;      % max centroid movement
useMorph = true;

targetInitialized = false;
targetPos = [NaN NaN];     % [x y]
traj = [];

% Init background
if ~hasFrame(videoReader)
    fprintf('Empty video: %s\n', videoFile);
    return;
end
frame0 = readFrame(videoReader);
g0 = toGrayDouble(frame0);
bg_run = g0;

% restart from beginning
videoReader.CurrentTime = 0;

hFigure = figure(1);

while hasFrame(videoReader)

    % Required: stop if window closed
    if ~isvalid(hFigure)
        disp('Playback interrupted by user.');
        break;
    end

    frame = readFrame(videoReader);
    g = toGrayDouble(frame);

    % Change detection
    diff_run = g - bg_run;
    bin = abs(diff_run) > tau2;

    % optional stricter threshold
    bin = bin & (abs(diff_run) > tau1);

    % Cleanup (Toolbox)
    if useMorph
        bin = bwareaopen(bin, minArea);
        bin = imclose(bin, strel('disk', 3));
        bin = imfill(bin, 'holes');
    else
        bin = bwareaopen(bin, minArea);
    end

    % Update background
    bg_run = (1 - alpha) * bg_run + alpha * g;

    % Display frame
    figure(1), imshow(im2uint8(g), 'Border', 'tight');
    title(sprintf('Frame %d', round(videoReader.CurrentTime * videoReader.FrameRate)));
    hold on;

    if (i == 1380)
        pause;

        % Pick a point manually on the person to initialize
        [x0, y0] = ginput(1);

        targetInitialized = true;
        targetPos = [x0 y0];
        traj = targetPos;

        plot(targetPos(1), targetPos(2), 'ro', 'MarkerSize', 8, 'LineWidth', 2);
        text(targetPos(1)+5, targetPos(2), 'init', 'Color', 'r');

    elseif (i > 1380) && targetInitialized

        % Connected components + regionprops
        CC = bwconncomp(bin);
        stats = regionprops(CC, 'Centroid', 'Area', 'BoundingBox');

        if ~isempty(stats)
            centroids = cat(1, stats.Centroid);
            areas = cat(1, stats.Area);

            valid = areas >= minArea;
            centroids = centroids(valid,:);
            stats = stats(valid);

            if ~isempty(centroids)
                d = sqrt(sum((centroids - targetPos).^2, 2));
                [dmin, idx] = min(d);

                if dmin <= maxJump
                    targetPos = centroids(idx,:);
                    traj = [traj; targetPos]; %#ok<AGROW>

                    bb = stats(idx).BoundingBox;
                    rectangle('Position', bb, 'EdgeColor', 'g', 'LineWidth', 2);
                    plot(targetPos(1), targetPos(2), 'go', 'MarkerSize', 6, 'LineWidth', 2);
                else
                    traj = [traj; [NaN NaN]]; %#ok<AGROW>
                end
            else
                traj = [traj; [NaN NaN]]; %#ok<AGROW>
            end
        else
            traj = [traj; [NaN NaN]]; %#ok<AGROW>
        end
    end

    if size(traj,1) >= 2
        plot(traj(:,1), traj(:,2), 'y-', 'LineWidth', 2);
    end

    hold off;
    drawnow;

    i = i + 1;
end

% Final trajectory (optional)
if isvalid(hFigure)
    figure(1); hold on;
    if size(traj,1) >= 2
        plot(traj(:,1), traj(:,2), 'y-', 'LineWidth', 2);
    end
    hold off;
end

close all;
fprintf('Finished displaying video: %s\n', videoFile);
end

function g = toGrayDouble(fr)
    if size(fr,3) == 3
        fr = rgb2gray(fr);
    end
    g = im2double(fr);
end
