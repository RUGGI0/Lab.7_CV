function [] = segmentAndTrack(videoFile, tau1, alpha, tau2)

videoReader = VideoReader(videoFile);

minArea=200; maxJump=90; lambda=80;
i=0; hFigure=figure(1);

frame0 = readFrame(videoReader);
bg_run = toGrayDouble(frame0);
videoReader.CurrentTime=0;

targetInit=false; targetPos=[NaN NaN]; traj=[]; whiteRef=NaN;

while hasFrame(videoReader)

    if ~isvalid(hFigure), break; end

    frame=readFrame(videoReader);
    g=toGrayDouble(frame);

    diff=g-bg_run;
    bin=abs(diff)>tau2 & abs(diff)>tau1;
    bin=bwareaopen(bin,minArea);
    bg_run=(1-alpha)*bg_run+alpha*g;

    imshow(toUInt8Vis(g)); hold on;

    if i==1380
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
        targetInit=true;

    elseif i>1380 && targetInit
        CC=bwconncomp(bin);
        S=regionprops(CC,'Centroid','Area','PixelIdxList');
        best=inf; idx=-1;
        for k=1:numel(S)
            d=norm(S(k).Centroid-targetPos);
            if d>maxJump, continue; end
            w=mean(g(S(k).PixelIdxList));
            score=d+lambda*abs(w-whiteRef);
            if score<best, best=score; idx=k; end
        end
        if idx>0
            targetPos=S(idx).Centroid;
            traj=[traj;targetPos];
            plot(targetPos(1),targetPos(2),'go','LineWidth',2);
        end
    end

    if size(traj,1)>1
        plot(traj(:,1),traj(:,2),'y-','LineWidth',2);
    end

    hold off; drawnow;
    i=i+1;
end
end

function g=toGrayDouble(fr)
if size(fr,3)==3, fr=rgb2gray(fr); end
g=im2double(fr);
end

function u=toUInt8Vis(x)
u=im2uint8(mat2gray(x));
end
