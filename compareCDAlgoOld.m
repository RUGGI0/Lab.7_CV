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

% Create a VideoReader object
videoReader = VideoReader(videoFile);

% Loop through each frame of the video
while hasFrame(videoReader)
    % Read the next frame
    frame = readFrame(videoReader);

    % Display the frame
    figure(1), subplot(2, 3, 1), imshow(frame, 'Border', 'tight');
    title(sprintf('Frame %d', round(videoReader.CurrentTime * videoReader.FrameRate)));

    % Fake image, just for the sake of running --> In the visualization
    % below replace with the appropriate image
    fake_img = uint8(128*ones(size(frame)));

    % Display the static background
    figure(1), subplot(2, 3, 2), imshow(fake_img, 'Border', 'tight');
    title('Static background');

    % Display the binary map obtained with the static background
    figure(1), subplot(2, 3, 3), imshow(fake_img, 'Border', 'tight');
    title('Binary map 1');

    % Display the running average
    figure(1), subplot(2, 3, 5), imshow(fake_img, 'Border', 'tight');
    title('Running average');

    % Display the binary map obtained with the running average
    figure(1), subplot(2, 3, 6), imshow(fake_img, 'Border', 'tight');
    title('Binary map 2');

end

% Close the figure when playback is finished
close all;

fprintf('Finished displaying video: %s\n', videoFile);
end