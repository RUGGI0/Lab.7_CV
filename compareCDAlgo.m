function [] = compareCDAlgo(videoFile, tau1, alpha, tau2) 
% This function compares the output of the change detection algorithm when
% using two possible background models:
% 1. A static model, e.g. a single frame or the average of N frames.
% In this case, the background is computed once and for all
% 2. A running average to update the model. In this case the background is
% updated, if needed, at each time instant
% You must visualize the original video, the background and binary map
% obtained with 1., the background and binary map
% obtained with 2.
% tau1 is the threshold for the change detection
% alpha is the parameter to weight the contribution of current image and
% previous background in the running average
% tau2 is the threshold for the image differencing in the running average


% Default parameters
if nargin < 1
    videoFile = 'luce_vp.mp4';
    tau1 = 30;    % Threshold for Static
    alpha = 0.05; % Learning Rate
    tau2 = 30;    % Threshold for Running Average
    fprintf('No inputs provided. Using defaults: File=%s, Tau1=%d, Alpha=%.2f\n', ...
        videoFile, tau1, alpha);
end

% Create a VideoReader object
videoReader = VideoReader(videoFile);

%% Part1: Inisialization 
Number_of_Frames = 10;

% 1. Read the very first frame to get the size
firstFrame = readFrame(videoReader);
grayFirst = rgb2gray(firstFrame);

% Initialize the sum using DOUBLE precision 
sumFrames = double(grayFirst);

% Loop to remaining N-1 frames
for i = 2:Number_of_Frames
    if hasFrame(videoReader)
        frame = readFrame(videoReader);
        grayFrame = rgb2gray(frame);
        sumFrames = sumFrames + double(grayFrame);
    end
end

% Calculate the average to get static_background
staticBackground = sumFrames / Number_of_Frames; 

% Initialize Running background (Start with the static model)
runningBackground = staticBackground; 

% Rewind the video to start visualizing from frame 1
videoReader.CurrentTime = 0;

% Prepare Figure Window 
% We create the figure handle HERE so we can check it inside the loop
hFigure = figure(1); 

%% PART 2: Main loop
while hasFrame(videoReader)
    % Check if the user has closed the figure window
    if ~isvalid(hFigure)
        disp('Playback interrupted by user.');
        break;
    end
    
    % 1. Read Frame
    frame = readFrame(videoReader); 
    
    % 2. Pre-processing
    % Convert to grayscale first
    grayFrame = rgb2gray(frame);
    % Convert to double 
    currentFrameDouble = double(grayFrame);
    
    % 3. Method 1: Static Background
    % Calculate absolute difference
    diffStatic = abs(currentFrameDouble - staticBackground);
    % Apply threshold tau1 to create Binary Map 1
    binaryMap1 = diffStatic > tau1;
    
    % 4. Method 2: Running Average
    % Calculate difference with the *current* running background
    diffRunning = abs(currentFrameDouble - runningBackground);
    % Apply threshold tau2 to create Binary Map 2
    binaryMap2 = diffRunning > tau2;
    
    % Update the running background for the next frame
    % Formula: NewBG = (1-alpha)*OldBG + alpha*CurrentFrame 
    runningBackground = (1 - alpha) * runningBackground + alpha * currentFrameDouble;
    
    % 5. Visualization
    % (We use hFigure to ensure we draw in the right window)
    figure(hFigure); 
    
    % Display the original frame
    subplot(2, 3, 1), imshow(frame, 'Border', 'tight');
    title(sprintf('Frame %d', round(videoReader.CurrentTime * videoReader.FrameRate)));
    
    % Display the static background (Convert back to UINT8 for display)
    subplot(2, 3, 2), imshow(uint8(staticBackground), 'Border', 'tight');
    title('Static background');
    
    % Display Binary Map 1 (Logical map, no need for uint8)
    subplot(2, 3, 3), imshow(binaryMap1, 'Border', 'tight');
    title('Binary map 1 (Static)');
    
    % Display the running average background (Convert back to UINT8)
    subplot(2, 3, 5), imshow(uint8(runningBackground), 'Border', 'tight');
    title('Running average');
    
    % Display Binary Map 2
    subplot(2, 3, 6), imshow(binaryMap2, 'Border', 'tight');
    title('Binary map 2 (Running)');
    
    % Force Matlab to draw the updates immediately
    drawnow;
end

% Close the figure when playback is finished
if isvalid(hFigure)
    close(hFigure);
end
fprintf('Finished displaying video: %s\n', videoFile);

end