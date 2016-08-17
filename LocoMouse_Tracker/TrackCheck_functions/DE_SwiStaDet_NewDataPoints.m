function [new_swings, new_stances]= DE_SwiStaDet_NewDataPoints(x_zero, minpkx, maxpkx)

    for j=1:4 % For each paw...
        
	%% Swings
        %Diff Data Points
        x_zero_diff{j} = diff(x_zero{j}(:,1)); %Derivative of the X-Trajectory converted into peaks, with zero mean.
        x_zero_diff{j}(:,2)=1:size(x_zero{j},1)-1;
        
        %Find positive values in derivative (Approach 1)
        positive_frames=find(x_zero_diff{j}(:,1)>0);
        pos_diff=x_zero_diff{j}(positive_frames,1);
        swing_slope=nanmax(pos_diff);  %Slope of Approach 1
        
        %Goes to the end of the data points
        mins= minpkx{j}(:,1);
        diff_data=cat(1,mins,length(x_zero_diff{j}));  %Goes to the end of the data points
        new_swing_points{j}=NaN(size(diff_data-1,1));
        
        for n=1:size(diff_data)-1
            
            for m=diff_data(n):diff_data(n+1)
                range_threshold=m:m+10; %Search the number of frames until find a big slope
                first=m(1);
                
                if (x_zero_diff{j}(first)>swing_slope & x_zero_diff{j}(range_threshold)> swing_slope)
                    new_swing_points{j}(n)=first;
                    break;
                else
                    new_swing_points{j}(n)=minpkx{j}(n,1);
                end
                
            end
        end
        
        mean_swing_distribution=0; %Mean Value Swing Bias
        del_nan{j}=find(~isnan(new_swing_points{j})); %Remove NaN Values
        del{j}=new_swing_points{j}(del_nan{j}); %New vector without NaN Values
        new_swings{j}= del{j}+mean_swing_distribution; %Frames
        
        
	%% Stances
        
        %Diff Data Points
        x_zero_diff{j}= diff(x_zero{j}(:,1));
        x_zero_diff{j}(:,2)=1:size(x_zero{j},1)-1;
        
        %Find positive values in derivative (Approach 1)
        negative_frames=find(x_zero_diff{j}(:,1)<0);
        neg_diff=x_zero_diff{j}(negative_frames,1);
        stance_slope=nanmax(neg_diff);  %Slope of Approach 1
        
        %Goes to the end of the data points
        maxs= maxpkx{j}(:,1); %Stance Peaks (Max Values)
        diff_data=cat(1,maxs,length(x_zero_diff{j})); %Goes to the end of the data points (Stance Points)
        new_stance_points{j}=NaN(size(diff_data-1,1));
        
        for n=1:size(diff_data)-1
            
            %Search the number of frames until find a big slope
            for m=diff_data(n):diff_data(n+1) %Interval between two stance points
                range_threshold=m:m+10;
                first=m(1);
                
                if (x_zero_diff{j}(first)<stance_slope & x_zero_diff{j}(range_threshold)<stance_slope)
                    new_stance_points{j}(n)=range_threshold(5);
                    break;
                else
                    new_stance_points{j}(n)=maxpkx{j}(n,1);
                end
            end
        end
        mean_stance_distribution=0; %Mean Value Stance Bias
        del_nan{j}=find(~isnan(new_stance_points{j}));  %Remove NaN Values
        del{j}=new_stance_points{j}(del_nan{j}); %New vector without NaN Values
        new_stances{j}= del{j}+mean_stance_distribution;
    end
end