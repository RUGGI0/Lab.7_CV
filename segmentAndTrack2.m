function [] = segmentAndTrack2(videoFile, alpha, tau2) 
% This function ...
% alpha is the parameter to weight the contribution of current image and
% previous background in the running average
% tau2 is the threshold for the image differencing in the running average
% Add here input parameters to control the tracking procedure if you need...

% Default parameters
if nargin < 1
    videoFile = 'luce_vp.mp4';    
    alpha = 0.001; 
    tau2 = 35;
end

% Create a VideoReader object
videoReader = VideoReader(videoFile);

% Initialize variables
i = 0;
trajectory = []; 
background = []; 

% Kalman filter structure
kfState = [];

% Parametri per il filtro (dal tuo codice esempio)
meas_noise = 2.0;   % Measures noise
proc_noise = 0.5;   % Who trust more? Model or measure?

hFigure = figure(1);

while hasFrame(videoReader)

    % Check if the user has closed the figure
    if ~isvalid(hFigure)
    disp('Playback interrupted by user.');
    break;
    end

    frame = readFrame(videoReader);
    doubleFrame = double(rgb2gray(frame));
    if isempty(background)
        background = doubleFrame;
    end

    % Change Detection
    diffFrame = abs(doubleFrame - background);
    binaryMap = diffFrame > tau2;
    
    % Cleaning
    binaryMap = imfill(binaryMap, 'holes');
    binaryMap = imopen(binaryMap, strel('disk', 3));  
    binaryMap = imclose(binaryMap, strel('disk', 8));

    % Update background
    background = alpha * doubleFrame + (1 - alpha) * background;

    %% Plot
    figure(hFigure);
    subplot(2, 2, 1); imshow(rgb2gray(frame)); title(sprintf('Frame %d', i)); hold on;
    
    if ~isempty(trajectory)
        plot(trajectory(:,1), trajectory(:,2), 'y-', 'LineWidth', 1);
        plot(trajectory(end,1), trajectory(end,2), 'r+', 'MarkerSize', 10, 'LineWidth', 2);
    end

    if ~isempty(kfState)
        predState = kfState.PHI * kfState.xhat;
        predictedPos = predState(1:2)'; 
        plot(predictedPos(1), predictedPos(2), 'gx', 'MarkerSize', 10, 'LineWidth', 2);
    end
    
    subplot(2, 2, 2); imshow(binaryMap); title('Binary Map'); hold on;
    
    hold off;

    subplot(2, 2, 3); imshow(uint8(background), 'Border', 'tight');
    title('Dinamic background');

    %% Tracking
    if(i == 1380)
        subplot(2, 2, 1); title('PAUSED: click on the subject');
        [x_click, y_click] = ginput(1);
        
        % Blob nearest to the click
        cc = bwconncomp(binaryMap);
        props = regionprops(cc, 'Centroid');
        
        startPos = [x_click, y_click];
        if ~isempty(props)
            centroids = vertcat(props.Centroid);
            dists = sum((centroids - startPos).^2, 2);
            [~, idx] = min(dists);
            startPos = centroids(idx, :);
        end
        
        % Inizialize Kalman structure with velocity = 0
        x_init = [startPos(1); startPos(2); 0; 0]; 
        
        kfState.xhat = x_init;
        kfState.PHI = [1 0 1 0; 0 1 0 1; 0 0 1 0; 0 0 0 1]; %transition matrix
        kfState.H = [1 0 0 0; 0 1 0 0];                     %measurement matrix
        kfState.Q1 = proc_noise^2 * eye(4);                 %process noise correlation
        kfState.Q2 = meas_noise^2 * eye(2);                 %autocorrelation of the measure noise
        %kfState.kn = 10 * eye(4);                           %error estimate covariance
        kfState.kn=100*meas_noise^2*eye(4);

        trajectory = [trajectory; startPos];
        disp('Kalman Filter Inizialized.');

    elseif(i > 1380 && ~isempty(kfState))
        
        x_pred = kfState.PHI * kfState.xhat;
        predPos = x_pred(1:2)';
        
        % Nearest blob
        cc = bwconncomp(binaryMap);
        props = regionprops(cc, 'Centroid', 'Area');
        
        measurement = []; % If empty == No measure
        
        if ~isempty(props)
            % Minimal dimension filter
            props = props([props.Area] > 30);
            if ~isempty(props)
                centroids = vertcat(props.Centroid);
                
                % Calculate distance from prodiction
                dists = sum((centroids - predPos).^2, 2);
                [minDist, idx] = min(dists);
                
                % Accept the measure only if it is near
                if minDist < (40^2)
                    measurement = centroids(idx, :)'; % Vettore colonna [x; y]
                end
            end
        end
        
        kfState = KalmanFilter(kfState, measurement);
        
        % Saving a posteriori estimation
        currentPos = kfState.xhat(1:2)';
        trajectory = [trajectory; currentPos];
        
        if isempty(measurement)
            disp('Occlusion/Miss: Only prediction');
        end
    end
    
    subplot(2, 2, 1); hold off;
    drawnow;
    i = i + 1;
end

close all;
end