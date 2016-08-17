function [minpkx,maxpkx,x_zero] = DE_SwiStaDet_X(preX,frames)

    for j=1:4 % For each paw...
        
        %X-Data Interpolation and Smoothing
        Xs(:,j)=smooth(inpaint_nans(preX(:,j),4),1); % Filtering and Interpolation of NaNs values
            
        %Define linear regression of X-Trajectory
        [min_value, min_value_frame] = min(Xs(:,j));
        [max_value, max_value_frame] = max(Xs(:,j));
               
        %Linear Regression (Find Slope (m) and Interception of the linear predict(b))
        m = (max_value-min_value)/(max_value_frame-min_value_frame); %Slope
        b= max_value-m*(max_value_frame); % Intercept of the linear predict
        
        for v=1:size(Xs(:,j),1)
            linear_points(v) = (frames(v)*m)+b; %Find Row
        end
        linear_points = linear_points.';
        
        %Conversion of X-Trajectory into peaks
        for p=1:size(Xs(:,j),1)
            new_x_values(p) = Xs(p,j)-linear_points(p); %Subtract each value to the X-Trajectory
        end
        
        %Remove offset(zero mean)
        mean_new_x = nanmean(new_x_values);
        for w=1:size(Xs(:,j),1)
            x_zero{j}(w,1)= new_x_values(w)-mean_new_x;
            x_zero{j}(w,2)= w;
        end
        
        %Smoothing Data Points
        x_zero{j}(:,1)=smooth(x_zero{j}(:,1),10);
        
        %Calculate peaks for data points (data: x-trajectory converted into peaks)
        [maxpkx{j}, minpkx{j}]=peakdet(x_zero{j}(:,1),3);% Define Threshold
        
        %Do not considered first peak if frame of first peak < 1
        if maxpkx{j}(1,1)<=5
            maxpkx{j}=cat(2,maxpkx{j}(2:end,1),maxpkx{j}(2:end,2));
        end
        
        if minpkx{j}(1,1)<=5
            minpkx{j}=cat(2,minpkx{j}(2:end,1),minpkx{j}(2:end,2));
        end
    end
    
end