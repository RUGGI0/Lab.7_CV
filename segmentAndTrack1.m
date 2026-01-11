function [] = segmentAndTrack(videoFile, tau1, alpha, tau2) 
% This function ...
% tau1 is the threshold for the change detection
% alpha is the parameter to weight the contribution of current image and
% previous background in the running average
% tau2 is the threshold for the image differencing in the running average
% Add here input parameters to control the tracking procedure if you need...

% 0. DEFAULT PARAMETERS
if nargin < 1
    videoFile = 'DibrisHall.mp4';
    tau1 = 30;
    alpha = 0.05;
    tau2 = 30;
    fprintf('No inputs. Using defaults: File=%s, Alpha=%.2f, Tau2=%d\n', videoFile, alpha, tau2);
end

% Create a VideoReader object
videoReader = VideoReader(videoFile);

%% 1.Initialization
% Read the first frame to initialize the background model
firstFrame = readFrame(videoReader);
grayFirst = rgb2gray(firstFrame);

% Initialize Running Background (Double precision)
runningBackground = double(grayFirst);

% Variables for Tracking
trajectory = [];       % To store [x, y] history
targetPosition = [];   % Current [x, y] of the target
isTracking = false;    % Flag to start tracking after selection

% Reset video to start from frame 1
videoReader.CurrentTime = 0;
i = 0;

% Initialize Figure
hFigure = figure(1);

%% Loop
while hasFrame(videoReader)
    
    % Safety check to stop if window is closed
    if ~isvalid(hFigure)
        disp('Playback interrupted by user.');
        break;
    end

    % Read frame
    frame = readFrame(videoReader);
    i = i + 1; % Increment frame counter

    % 1 . Pre-processing
    grayFrame = rgb2gray(frame);
    currentFrameDouble = double(grayFrame);

    % A. Detection 
    diffRunning = abs(currentFrameDouble - runningBackground);
    binaryMap = diffRunning > tau2;

    % B. Clean the noise 
    % we remove small white dots so tracking doesn't get confused
    binaryMap = bwareaopen(binaryMap, 50); 

    % C. Update Background
    runningBackground = (1 - alpha) * runningBackground + alpha * currentFrameDouble;

    %% Visualization set up 
    figure(1);
    imshow(uint8(frame), 'Border', 'tight');
    hold on; % Allow drawing graphics on top of the video
    title(sprintf('Frame %d', i));

    % Selection Logic(Use farme 1380)
    if(i == 1380)
        disp('Frame 1380 Reached. Please CLICK on the target (Person in White).');
        title('PAUSED: Click on the target (White Shirt)');
        
        % 1. Get user click
        [x_click, y_click] = ginput(1); 
        
        % 2. Find the blob closest to the click
        % Get properties of all blobs in the binary map
        props = regionprops(binaryMap, 'Centroid', 'BoundingBox');
        
        minDist = inf;
        bestIdx = -1;
        
        for k = 1:length(props)
            centroid = props(k).Centroid;
            % Calculate distance between Click and Blob Centroid
            dist = sqrt((centroid(1) - x_click)^2 + (centroid(2) - y_click)^2);
            
            if dist < minDist
                minDist = dist;
                bestIdx = k;
            end
        end
        
        % 3. Initialize Trajectory
        if bestIdx ~= -1
            targetPosition = props(bestIdx).Centroid;
            trajectory = [trajectory; targetPosition]; % Append
            isTracking = true;
            
            % Draw the initial selection
            plot(targetPosition(1), targetPosition(2), 'ro', 'MarkerSize', 10, 'LineWidth', 2);
            rectangle('Position', props(bestIdx).BoundingBox, 'EdgeColor', 'g', 'LineWidth', 2);
            disp('Target Acquired!');
        else
            disp('Warning: No object found near click!');
        end

    %% 4.Tracking Logic  (Frames > 1380)
    elseif(i > 1380 && isTracking)
        
        % Get all moving objects in current frame
        props = regionprops(binaryMap, 'Centroid', 'BoundingBox');
        
        if isempty(props)
            % Target lost (stopped moving or occlusion)
            % We keep the last known position
        else
            % Find the blob closest to the LAST known target position
            minDist = inf;
            bestIdx = -1;
            
            for k = 1:length(props)
                centroid = props(k).Centroid;
                % Distance from PREVIOUS target position
                dist = sqrt((centroid(1) - targetPosition(1))^2 + (centroid(2) - targetPosition(2))^2);
                
                if dist < minDist
                    minDist = dist;
                    bestIdx = k;
                end
            end
            
            % Update position if a close match is found (Threshold e.g., 50 pixels)
            if bestIdx ~= -1 && minDist < 100 
                targetPosition = props(bestIdx).Centroid;
                trajectory = [trajectory; targetPosition]; % Append new position
                
                % Draw Bounding Box around current target
                rectangle('Position', props(bestIdx).BoundingBox, 'EdgeColor', 'g', 'LineWidth', 2);
            end
        end
    end
    
    %% 5. Draw Trajectory  
    if ~isempty(trajectory)
        % Plot the entire path as a red line
        plot(trajectory(:,1), trajectory(:,2), 'r-', 'LineWidth', 2);
    end
    
    hold off; % Release drawing
    drawnow;  % Force update
end

% Close the figure when playback is finished
if isvalid(hFigure)
    close(hFigure);
end

fprintf('Finished displaying video: %s\n', videoFile);
close(hFigure);
end