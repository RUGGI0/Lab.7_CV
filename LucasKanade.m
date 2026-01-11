function [u, v] = LucasKanade(im1, im2, windowSize)
    % Optical Flow - Lucas Kanade algorithm
    % INPUT: im1, im2 two adjacent image frames (instants t and t+1)
    %        windowSize the size of a local neighbourhood
    % OUTPUT: two maps (double) encoding the two components of OF
    %---------------------------------------------------------------------
    
    
    % images check
    if (size(im1,1)~=size(im2,1)) | (size(im1,2)~=size(im2,2))
        error('the two frames have different sizes');
    end
    
    if (size(im1,3) ~= 1) | (size(im2, 3) ~= 1)
        error('images must be gray level');
    end
    
    % compute space and time derivatives
    [fx, fy, ft] = ComputeDerivatives(im1, im2);
    
    u = zeros(size(im1));
    v = zeros(size(im1));
    
    halfW = floor(windowSize/2);
    eigen_threshold = 0.01;

    %  for each pixel of an image I build a least square system 
    for i = halfW+1 : size(fx,1)-halfW
       for j = halfW+1:size(fx,2)-halfW
          
          Ix_w = fx(i-halfW:i+halfW, j-halfW:j+halfW);
          Iy_w = fy(i-halfW:i+halfW, j-halfW:j+halfW);
          It_w = ft(i-halfW:i+halfW, j-halfW:j+halfW);
           
          A = [Ix_w(:), Iy_w(:)];
          b = -It_w(:);

          G = A' * A;
          e = eig(G);
          if min(e) >= eigen_threshold
              U = A \ b;
              
              u(i,j)=U(1);
              v(i,j)=U(2);
          else
              u(i,j) = 0;
              v(i,j) = 0;
          end 
          
       end
    end
    
    % adjust NaN
     u(isnan(u))=0;
     v(isnan(v))=0;
 
end
      
%--------------------------------------------------------------------------
function [fx, fy, ft] = ComputeDerivatives(im1, im2)

    if (size(im1,1) ~= size(im2,1)) | (size(im1,2) ~= size(im2,2))
       error('the two frames have different sizes');
    end
    
    if (size(im1,3)~=1) | (size(im2,3)~=1)
       error('images must be gray level');
    end
    
    % derivative estimation through convolution
    fx = conv2(double(im1),0.25* [-1 1; -1 1]) + conv2(double(im2), 0.25*[-1 1; -1 1]);
    fy = conv2(double(im1), 0.25*[-1 -1; 1 1]) + conv2(double(im2), 0.25*[-1 -1; 1 1]);
    ft = conv2(double(im1), 0.25*ones(2)) + conv2(double(im2), -0.25*ones(2));
    
    % adjusting the images size
    fx=fx(1:size(fx,1)-1, 1:size(fx,2)-1);
    fy=fy(1:size(fy,1)-1, 1:size(fy,2)-1);
    ft=ft(1:size(ft,1)-1, 1:size(ft,2)-1);

end





























