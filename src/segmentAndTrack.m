function [] = segmentAndTrack(videoFile, tau1, alpha, tau2)
% Fast Toolbox-based tracker:
% - running average CD
% - after manual init, process ONLY a ROI around the target (huge speed-up)
% - visualize every N frames with drawnow limitrate to avoid freezing

videoReader = VideoReader(videoFile);

% ---- speed knobs ----
initFrame = 1380;     % as template
roiRadius = 140;      % ROI half-size in pixels (increase if target jumps)
visEvery  = 5;        % visualize 1 frame every N
minArea   = 250;      % remove tiny blobs
maxJump   = 120;      % max centroid jump allowed

i = 0;
hFigure = figure(1);

% init background
if ~hasFrame(videoReader)
    fprintf('Empty video: %s\n', videoFile);
    return;
end
frame0 = readFrame(videoReader);
g0 = toGrayDouble(frame0);
bg = g0;

% restart from beginning
videoReader.CurrentTime = 0;

targetInit = false;
targetPos = [NaN NaN];   % [x y]
traj = [];

while hasFrame(videoReader)

    if ~isvalid(hFigure)
        disp('Playback interrupted by user.');
        break;
    end

    frame = readFrame(videoReader);
    g = toGrayDouble(frame);

    % running average CD (double keeps negatives)
    diff = g - bg;
    binFull = abs(diff) > tau2;
    binFull = binFull & (abs(diff) > tau1);
    bg = (1-alpha)*bg + alpha*g;

    % --- choose ROI (full frame only before init)
    if ~targetInit
        x1 = 1; y1 = 1;
        x2 = size(g,2); y2 = size(g,1);
    else
        cx = round(targetPos(1)); cy = round(targetPos(2));
        x1 = max(1, cx - roiRadius); x2 = min(size(g,2), cx + roiRadius);
        y1 = max(1, cy - roiRadius); y2 = min(size(g,1), cy + roiRadius);
    end

    bin = binFull(y1:y2, x1:x2);

    % cleanup (Toolbox, but only on ROI => fast)
    bin = bwareaopen(bin, minArea);
    bin = imclose(bin, strel('disk', 2));

    % --- init
    if i == initFrame
        if mod(i,visEvery)==0
            imshow(im2uint8(g), 'Border','tight');
            title(sprintf('Frame %d (init: click target)', i));
            drawnow;
        end
        pause; % let user prepare
        figure(1);
        imshow(im2uint8(g), 'Border','tight');
        title(sprintf('Frame %d (click target)', i));
        [x0,y0] = ginput(1);

        targetInit = true;
        targetPos = [x0 y0];
        traj = targetPos;

    elseif i > initFrame && targetInit
        % components in ROI
        CC = bwconncomp(bin);
        stats = regionprops(CC, 'Centroid', 'Area', 'BoundingBox');

        if ~isempty(stats)
            centroids = cat(1, stats.Centroid);
            areas = cat(1, stats.Area);

            valid = areas >= minArea;
            centroids = centroids(valid,:);
            stats = stats(valid);

            if ~isempty(centroids)
                % convert ROI centroids to full-frame coordinates
                centroids(:,1) = centroids(:,1) + (x1-1);
                centroids(:,2) = centroids(:,2) + (y1-1);

                d = sqrt(sum((centroids - targetPos).^2, 2));
                [dmin, idx] = min(d);

                if dmin <= maxJump
                    targetPos = centroids(idx,:);
                    traj = [traj; targetPos]; %#ok<AGROW>
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

    % --- visualization throttled (avoid freezing)
    if mod(i,visEvery)==0
        figure(1);
        imshow(im2uint8(g), 'Border','tight'); hold on;
        title(sprintf('Frame %d', i));

        if targetInit
            % draw ROI box
            rectangle('Position',[x1 y1 (x2-x1+1) (y2-y1+1)], 'EdgeColor','c','LineWidth',1);
        end

        if targetInit && all(isfinite(targetPos))
            plot(targetPos(1), targetPos(2), 'go', 'MarkerSize', 6, 'LineWidth', 2);
        end

        if size(traj,1) > 1
            plot(traj(:,1), traj(:,2), 'y-', 'LineWidth', 2);
        end

        hold off;
        drawnow limitrate;
    end

    i = i + 1;
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
