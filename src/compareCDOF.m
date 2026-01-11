function [] = compareCDOF(videoFile, tau1, alpha, tau2, W)

videoReader = VideoReader(videoFile);

frame0 = readFrame(videoReader);
g_prev = toGrayDouble(frame0);
bg_run = g_prev;

hFigure = figure(1);
frameCount = 0;

while hasFrame(videoReader)

    if ~isvalid(hFigure)
        break;
    end

    frame = readFrame(videoReader);
    g = toGrayDouble(frame);

    % --- Change detection (running average)
    diff_run = g - bg_run;
    bin = abs(diff_run) > tau2;
    bg_run = (1 - alpha) * bg_run + alpha * g;

    % --- Optical flow (FAST, sparse)
    [U,V] = lucasKanadeFlow(g_prev, g, W);
    of_map = convertToMagDir(U,V);

    % --- Visualization (lightweight)
    frameCount = frameCount + 1;
    if mod(frameCount, 3) == 0
        figure(1);
        subplot(2,2,1), imshow(uint8(255*g)), title('Frame');
        subplot(2,2,2), imshow(of_map), title('Optical Flow');
        subplot(2,2,3), imshow(uint8(255*bin)), title('Binary map');
        subplot(2,2,4), imshow(uint8(255*bg_run)), title('Running BG');
        drawnow;
    end

    g_prev = g;
end
end

% -------- Helpers (NO TOOLBOX) --------
function g = toGrayDouble(fr)
    if size(fr,3) == 3
        fr = 0.2989*fr(:,:,1) + 0.5870*fr(:,:,2) + 0.1140*fr(:,:,3);
    end
    g = double(fr) / 255;
end

function [U,V] = lucasKanadeFlow(I1,I2,W)

if mod(W,2)==0, W=W+1; end
r=floor(W/2);
[H,L]=size(I1);
U=zeros(H,L); V=zeros(H,L);

% Sobel gradients (NO toolbox)
Kx = 0.25 * [-1 0 1; -2 0 2; -1 0 1];
Ky = 0.25 * [-1 -2 -1; 0 0 0; 1 2 1];
Ix = conv2(I2,Kx,'same');
Iy = conv2(I2,Ky,'same');
It = I2 - I1;

step = 2*r;   % <<< VELOCITÀ

for y=1+r:step:H-r
for x=1+r:step:L-r
    px=Ix(y-r:y+r,x-r:x+r);
    py=Iy(y-r:y+r,x-r:x+r);
    pt=It(y-r:y+r,x-r:x+r);

    A=[px(:) py(:)];
    b=-pt(:);

    if rcond(A'*A)<1e-4, continue; end
    nu=(A'*A)\(A'*b);

    % densify for visualization
    U(y-1:y+1,x-1:x+1)=nu(1);
    V(y-1:y+1,x-1:x+1)=nu(2);
end,end
end
