function [] = compareCDOF(videoFile, tau1, alpha, tau2, W)

videoReader = VideoReader(videoFile);

frame0 = readFrame(videoReader);
g_prev = toGrayDouble(frame0);
bg_run = g_prev;

hFigure = figure(1);

while hasFrame(videoReader)

    if ~isvalid(hFigure)
        disp('Playback interrupted by user.');
        break;
    end

    frame = readFrame(videoReader);
    g = toGrayDouble(frame);

    diff_run = g - bg_run;
    bin = abs(diff_run) > tau2 & abs(diff_run) > tau1;

    bg_run = (1 - alpha) * bg_run + alpha * g;

    [U,V] = lucasKanadeFlow(g_prev, g, W);
    of_map = convertToMagDir(U,V);

    figure(1);
    subplot(2,2,1), imshow(toUInt8Vis(g)), title('Frame');
    subplot(2,2,2), imshow(of_map), title('Optical Flow');
    subplot(2,2,3), imshow(uint8(255*bin)), title('Binary map');
    subplot(2,2,4), imshow(toUInt8Vis(bg_run)), title('Running BG');

    drawnow;
    g_prev = g;
end
end

function g = toGrayDouble(fr)
    if size(fr,3) == 3, fr = rgb2gray(fr); end
    g = im2double(fr);
end

function u = toUInt8Vis(x)
    u = im2uint8(mat2gray(x));
end

function [U,V] = lucasKanadeFlow(I1,I2,W)
if mod(W,2)==0, W=W+1; end
r=floor(W/2);
[H,L]=size(I1);
U=zeros(H,L); V=zeros(H,L);
[Ix,Iy]=imgradientxy(I2);
It=I2-I1;
step=max(1,r);
for y=1+r:step:H-r
for x=1+r:step:L-r
px=Ix(y-r:y+r,x-r:x+r);
py=Iy(y-r:y+r,x-r:x+r);
pt=It(y-r:y+r,x-r:x+r);
A=[px(:) py(:)];
b=-pt(:);
if rcond(A'*A)<1e-6, continue; end
nu=(A'*A)\(A'*b);
U(y,x)=nu(1); V(y,x)=nu(2);
end,end
end
